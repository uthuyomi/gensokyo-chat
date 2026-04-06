import type { HubRegistry } from "./hub.js";

export function createHubRegistry(): HubRegistry {
  return new Map();
}
