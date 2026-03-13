const DEFAULT_MAX_DOWNLOAD_BYTES = 20_000_000;
const DEFAULT_MAX_UPLOAD_BYTES = 8_000_000;

function buildCorsHeaders(originHeader, allowedOrigin) {
  const allowOrigin = allowedOrigin || originHeader || "*";

  return {
    "Access-Control-Allow-Origin": allowOrigin,
    "Access-Control-Allow-Methods": "GET,POST,OPTIONS",
    "Access-Control-Allow-Headers": "Content-Type",
    "Access-Control-Max-Age": "86400"
  };
}

function buildBaseHeaders(request, env) {
  const corsHeaders = buildCorsHeaders(request.headers.get("Origin"), env.ALLOWED_ORIGIN);

  return {
    ...corsHeaders,
    "Cache-Control": "no-store, no-cache, must-revalidate",
    "X-Speedtest-Provider": "cloudflare-worker",
    "X-Speedtest-Region": request.cf?.colo || "unknown"
  };
}

function readBoundedBytes(url, maxBytes) {
  const requestedBytes = Number.parseInt(url.searchParams.get("bytes") || "", 10);

  if (!Number.isFinite(requestedBytes) || requestedBytes <= 0) {
    return Math.min(1_000_000, maxBytes);
  }

  return Math.min(requestedBytes, maxBytes);
}

export default {
  async fetch(request, env) {
    const url = new URL(request.url);
    const maxDownloadBytes = Number(env.MAX_DOWNLOAD_BYTES || DEFAULT_MAX_DOWNLOAD_BYTES);
    const maxUploadBytes = Number(env.MAX_UPLOAD_BYTES || DEFAULT_MAX_UPLOAD_BYTES);
    const headers = buildBaseHeaders(request, env);

    if (request.method === "OPTIONS") {
      return new Response(null, {
        status: 204,
        headers
      });
    }

    if (request.method === "GET" && url.pathname === "/ping") {
      return new Response(null, {
        status: 204,
        headers
      });
    }

    if (request.method === "GET" && url.pathname === "/download") {
      const bytes = readBoundedBytes(url, maxDownloadBytes);
      const payload = new Uint8Array(bytes);

      return new Response(payload, {
        status: 200,
        headers: {
          ...headers,
          "Content-Type": "application/octet-stream",
          "Content-Length": String(bytes)
        }
      });
    }

    if (request.method === "POST" && url.pathname === "/upload") {
      const body = await request.arrayBuffer();

      if (body.byteLength > maxUploadBytes) {
        return new Response(
          JSON.stringify({
            error: "upload_too_large",
            maxUploadBytes
          }),
          {
            status: 413,
            headers: {
              ...headers,
              "Content-Type": "application/json"
            }
          }
        );
      }

      return new Response(
        JSON.stringify({
          receivedBytes: body.byteLength,
          provider: "cloudflare-worker",
          region: request.cf?.colo || "unknown"
        }),
        {
          status: 200,
          headers: {
            ...headers,
            "Content-Type": "application/json"
          }
        }
      );
    }

    return new Response(
      JSON.stringify({
        error: "not_found"
      }),
      {
        status: 404,
        headers: {
          ...headers,
          "Content-Type": "application/json"
        }
      }
    );
  }
};
