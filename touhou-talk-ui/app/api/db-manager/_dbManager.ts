import "server-only";

export function dbManagerBaseUrl(): string {
  const raw = (process.env.GENSOKYO_DB_MANAGER_URL || "").trim();
  return raw || "http://127.0.0.1:8011";
}

export function dbManagerHeaders(init?: HeadersInit): Headers {
  const headers = new Headers(init);
  headers.set("Accept", "application/json");
  const secret = (process.env.GENSOKYO_DB_MANAGER_SECRET || "").trim();
  if (secret) headers.set("x-db-manager-secret", secret);
  return headers;
}
