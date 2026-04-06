import type { GatewayEnv } from "../config/env.js";

export function canOpenConnection(params: {
  env: GatewayEnv;
  userId: string | null;
}): boolean {
  return Boolean(params.userId) || params.env.allowAnon;
}
