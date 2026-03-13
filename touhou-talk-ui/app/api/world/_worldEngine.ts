import "server-only";

export function worldEngineBaseUrl(): string {
  const raw = (process.env.GENSOKYO_WORLD_ENGINE_URL || "").trim();
  return raw || "http://127.0.0.1:8010";
}

export function worldEngineHeaders(init?: HeadersInit): Headers {
  const headers = new Headers(init);
  headers.set("Accept", "application/json");
  const secret = (process.env.GENSOKYO_WORLD_ENGINE_SECRET || "").trim();
  if (secret) headers.set("x-world-secret", secret);
  return headers;
}

