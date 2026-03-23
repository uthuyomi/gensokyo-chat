import type { ClientMsg } from "./messages.js";

export function safeParseClientMessage(raw: string): ClientMsg | null {
  try {
    const value = JSON.parse(raw) as { type?: unknown };
    if (!value || typeof value.type !== "string") return null;
    return value as ClientMsg;
  } catch {
    return null;
  }
}
