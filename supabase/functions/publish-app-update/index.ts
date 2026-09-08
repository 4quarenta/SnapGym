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

function header(req: Request, name: string): string {
  const value = req.headers.get(name)?.trim();
  if (!value) throw new Error(`Missing ${name} header.`);
  return value;
}

Deno.serve(async (req: Request) => {
  if (req.method !== "POST") return json({ error: "Method not allowed." }, 405);

  try {
    const authorization = req.headers.get("authorization") ?? "";
    if (!authorization.startsWith("Bearer ")) {
      return json({ error: "Missing GitHub OIDC token." }, 401);
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
      return json({ error: "GitHub workflow identity is not authorized." }, 403);
    }

    const versionName = header(req, "x-snapgym-version");
    const buildNumber = Number.parseInt(header(req, "x-snapgym-build"), 10);
    const expectedSha256 = header(req, "x-snapgym-sha256").toLowerCase();
    const notesBase64 = req.headers.get("x-snapgym-notes-b64") ?? "";

    if (!/^\d+\.\d+\.\d+(?:[-+][a-zA-Z0-9.-]+)?$/.test(versionName)) {
      return json({ error: "Invalid version name." }, 400);
    }
    if (!Number.isSafeInteger(buildNumber) || buildNumber <= 0) {
      return json({ error: "Invalid build number." }, 400);
    }
    if (!/^[a-f0-9]{64}$/.test(expectedSha256)) {
      return json({ error: "Invalid SHA-256." }, 400);
    }

    const binary = new Uint8Array(await req.arrayBuffer());
    if (binary.length === 0 || binary.length > 250 * 1024 * 1024) {
      return json({ error: "Invalid APK size." }, 400);
    }

    const digest = new Uint8Array(await crypto.subtle.digest("SHA-256", binary));
    const actualSha256 = Array.from(digest)
      .map((byte) => byte.toString(16).padStart(2, "0"))
      .join("");

    if (actualSha256 !== expectedSha256) {
      return json({ error: "APK SHA-256 mismatch." }, 400);
    }

    let releaseNotes: string | null = null;
    if (notesBase64) {
      try {
        releaseNotes = new TextDecoder().decode(
          Uint8Array.from(atob(notesBase64), (char) => char.charCodeAt(0)),
        );
        if (releaseNotes.length > 4000) {
          return json({ error: "Release notes are too long." }, 400);
        }
      } catch {
        return json({ error: "Invalid release notes encoding." }, 400);
      }
    }

    const supabaseUrl = Deno.env.get("SUPABASE_URL");
    const serviceRoleKey = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY");
    if (!supabaseUrl || !serviceRoleKey) {
      return json({ error: "Server configuration is incomplete." }, 500);
    }

    const supabase = createClient(supabaseUrl, serviceRoleKey, {
      auth: { persistSession: false, autoRefreshToken: false },
    });

    const objectPath = `dev/android/${versionName}-${buildNumber}.apk`;
    const { error: uploadError } = await supabase.storage
      .from(bucket)
      .upload(objectPath, binary, {
        contentType: "application/vnd.android.package-archive",
        cacheControl: "3600",
        upsert: true,
      });

    if (uploadError) {
      console.error("update upload failed", uploadError);
      return json({ error: "Could not publish APK." }, 500);
    }

    const downloadUrl =
      `${supabaseUrl}/storage/v1/object/public/${bucket}/${objectPath}`;

    const { error: metadataError } = await supabase
      .from("app_versions")
      .upsert(
        {
          platform: "android",
          channel: "dev",
          version_name: versionName,
          build_number: buildNumber,
          download_url: downloadUrl,
          action_url: null,
          sha256: actualSha256,
          release_notes: releaseNotes,
          is_mandatory: false,
          is_active: true,
          published_at: new Date().toISOString(),
        },
        { onConflict: "platform,channel,build_number" },
      );

    if (metadataError) {
      console.error("update metadata failed", metadataError);
      await supabase.storage.from(bucket).remove([objectPath]);
      return json({ error: "Could not publish update metadata." }, 500);
    }

    return json({
      ok: true,
      version: versionName,
      build: buildNumber,
      sha256: actualSha256,
      download_url: downloadUrl,
    });
  } catch (error) {
    console.error("publish-app-update error", error);
    return json({ error: "Unauthorized or invalid update publication." }, 401);
  }
});
