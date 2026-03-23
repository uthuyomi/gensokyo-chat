import type { ServerMsg } from "../protocol/messages.js";

export function serializeServerMessage(message: ServerMsg): string {
  return JSON.stringify(message);
}
