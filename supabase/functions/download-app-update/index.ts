import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const repository = "4quarenta/SnapGym";
const expectedAssetName = "SnapGym-Android-dev.apk";
const githubApiVersion = "2026-03-10";

function json(body: unknown, status = 200): Response {
  return new Response(JSON.stringify(body), {
    status,
    headers: {
      "Content-Type": "application/json",
      "Cache-Control": "no-store",
    },
  });
}

function githubHeaders(token: string, accept: string): HeadersInit {
  return {
    Accept: accept,
    Authorization: `Bearer ${token}`,
    "X-GitHub-Api-Version": githubApiVersion,
    "User-Agent": "SnapGym-Updater",
  };
}

Deno.serve(async (req: Request) => {
  if (req.method !== "GET") {
    return json({ error: "Method not allowed." }, 405);
  }

  const url = new URL(req.url);
  const assetId = Number(url.searchParams.get("asset_id"));
  if (!Number.isSafeInteger(assetId) || assetId <= 0) {
    return json({ error: "Invalid release asset." }, 400);
  }

  const githubToken = Deno.env.get("GITHUB_RELEASES_TOKEN");
  if (!githubToken) {
    console.error("GITHUB_RELEASES_TOKEN is not configured");
    return json({ error: "Update download is not configured." }, 503);
  }

  const assetApiUrl =
    `https://api.github.com/repos/${repository}/releases/assets/${assetId}`;

  try {
    const metadataResponse = await fetch(assetApiUrl, {
      headers: githubHeaders(githubToken, "application/vnd.github+json"),
    });

    if (!metadataResponse.ok) {
      console.error("GitHub asset metadata request failed", metadataResponse.status);
      return json({ error: "Update asset was not found." }, 404);
    }

    const asset = await metadataResponse.json() as {
      name?: string;
      state?: string;
    };

    if (asset.name !== expectedAssetName || asset.state !== "uploaded") {
      return json({ error: "Update asset is not available." }, 404);
    }

    const downloadResponse = await fetch(assetApiUrl, {
      headers: githubHeaders(githubToken, "application/octet-stream"),
      redirect: "manual",
    });

    const location = downloadResponse.headers.get("location");
    if (
      location &&
      [301, 302, 303, 307, 308].includes(downloadResponse.status)
    ) {
      return new Response(null, {
        status: 302,
        headers: {
          Location: location,
          "Cache-Control": "no-store",
        },
      });
    }

    // GitHub documents that this endpoint may return either a redirect or
    // stream the binary directly. Streaming is retained as a compatibility
    // fallback; the normal path is the redirect above, so Supabase does not
    // carry the APK payload.
    if (downloadResponse.ok && downloadResponse.body) {
      const headers = new Headers({
        "Content-Type":
          downloadResponse.headers.get("content-type") ??
            "application/vnd.android.package-archive",
        "Content-Disposition":
          `attachment; filename="${expectedAssetName}"`,
        "Cache-Control": "no-store",
      });

      const contentLength = downloadResponse.headers.get("content-length");
      if (contentLength) headers.set("Content-Length", contentLength);

      return new Response(downloadResponse.body, {
        status: 200,
        headers,
      });
    }

    console.error("GitHub asset download request failed", downloadResponse.status);
    return json({ error: "Update download is temporarily unavailable." }, 502);
  } catch (error) {
    console.error("download-app-update error", error);
    return json({ error: "Update download is temporarily unavailable." }, 502);
  }
});
