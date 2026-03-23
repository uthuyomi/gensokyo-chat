export function isValidChannel(channel: string): boolean {
  const value = String(channel || "").trim();
  return /^world:[a-z0-9_]+(?::[a-z0-9_]+)?$/i.test(value);
}
