import "jsr:@supabase/functions-js/edge-runtime.d.ts";
import { createClient } from "npm:@supabase/supabase-js@2";
import { createRemoteJWKSet, jwtVerify } from "npm:jose@6";

const githubJwks = createRemoteJWKSet(
  new URL("https://token.actions.githubusercontent.com/.well-known/jwks"),
);

const expectedIssuer = "https://token.actions.githubusercontent.com";
const expectedAudience = "snapgym-update-publisher";
const expectedRepository = "4quarenta/SnapGym";
const expectedWorkflowRef =
  "4quarenta/SnapGym/.github/workflows/publish_test_builds.yml@refs/heads/main";
const bucket = "app-updates";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: { "Content-Type": "application/json" },
  });
}

type PublishRequest = {
  action?: "prepare" | "finalize";
  version?: string;
  build?: number;
  sha256?: string;
  release_notes?: string | null;
};

async function authorize(req: Request): Promise<void> {
  const authorization = req.headers.get("authorization") ?? "";
  if (!authorization.startsWith("Bearer ")) {
    throw new Error("Missing GitHub OIDC token.");
  }

  const token = authorization.slice("Bearer ".length);
  const { payload } = await jwtVerify(token, githubJwks, {
    issuer: expectedIssuer,
    audience: expectedAudience,
  });

  if (
    payload.repository !== expectedRepository ||
    payload.ref !== "refs/heads/main" ||
    payload.workflow_ref !== expectedWorkflowRef ||
    !["push", "workflow_dispatch"].includes(String(payload.event_name))
  ) {
    throw new Error("GitHub workflow identity is not authorized.");
  }
}

function validateMetadata(data: PublishRequest) {
  const version = data.version?.trim() ?? "";
  const build = data.build;
  const sha256 = data.sha256?.trim().toLowerCase() ?? "";
  const releaseNotes = data.release_notes?.trim() || null;

  if (!/^\d+\.\d+\.\d+(?:[-+][a-zA-Z0-9.-]+)?$/.test(version)) {
    throw new Error("Invalid version name.");
  }
  if (!Number.isSafeInteger(build) || (build ?? 0) <= 0) {
    throw new Error("Invalid build number.");
  }
  if (!/^[a-f0-9]{64}$/.test(sha256)) {
    throw new Error("Invalid SHA-256.");
  }
  if (releaseNotes && releaseNotes.length > 4000) {
    throw new Error("Release notes are too long.");
  }

  const objectPath = `dev/android/${version}-${build}.apk.gz`;
  return { version, build: build as number, sha256, releaseNotes, objectPath };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed." }, 405);

  try {
    await authorize(req);
    const data = (await req.json()) as PublishRequest;
    const metadata = validateMetadata(data);

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Server configuration is incomplete." }, 500);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    if (data.action === "prepare") {
      const { data: signed, error } = await supabase.storage
        .from(bucket)
        .createSignedUploadUrl(metadata.objectPath, { upsert: true });

      if (error || !signed?.signedUrl || !signed?.token) {
        console.error("signed upload creation failed", error);
        return json({ error: "Could not authorize update upload." }, 500);
      }

      return json({
        ok: true,
        path: metadata.objectPath,
        signed_url: signed.signedUrl,
        token: signed.token,
        expires_in_seconds: 7200,
      });
    }

    if (data.action === "finalize") {
      const fileName = metadata.objectPath.split("/").pop()!;
      const { data: objects, error: listError } = await supabase.storage
        .from(bucket)
        .list("dev/android", { search: fileName, limit: 10 });

      if (listError || !objects?.some((item) => item.name === fileName)) {
        console.error("published update package not found", listError);
        return json({ error: "Uploaded update package was not found." }, 409);
      }

      const downloadUrl =
        `${supabaseUrl}/storage/v1/object/public/${bucket}/${metadata.objectPath}`;

      const { error: metadataError } = await supabase
        .from("app_versions")
        .upsert(
          {
            platform: "android",
            channel: "dev",
            version_name: metadata.version,
            build_number: metadata.build,
            download_url: downloadUrl,
            action_url: null,
            sha256: metadata.sha256,
            release_notes: metadata.releaseNotes,
            is_mandatory: false,
            is_active: true,
            published_at: new Date().toISOString(),
          },
          { onConflict: "platform,channel,build_number" },
        );

      if (metadataError) {
        console.error("update metadata failed", metadataError);
        return json({ error: "Could not publish update metadata." }, 500);
      }

      return json({
        ok: true,
        version: metadata.version,
        build: metadata.build,
        sha256: metadata.sha256,
        download_url: downloadUrl,
      });
    }

    return json({ error: "Invalid publication action." }, 400);
  } catch (error) {
    console.error("publish-app-update error", error);
    return json({ error: "Unauthorized or invalid update publication." }, 401);
  }
});
