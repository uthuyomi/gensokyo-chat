import { WebSocketServer } from "ws";

import type { GatewayEnv } from "../config/env.js";
import type { SupabaseClient } from "@supabase/supabase-js";
import type { HubRegistry } from "../subscriptions/hub.js";
import { logInfo } from "../infrastructure/logger.js";
import {
  cleanupConnection,
  createConnectionState,
  handleRawMessage,
} from "./connection.js";

export function startGatewayServer(params: {
  env: GatewayEnv;
  supabase: SupabaseClient;
  registry: HubRegistry;
}): WebSocketServer {
  const wss = new WebSocketServer({
    host: params.env.host,
    port: params.env.port,
  });

  logInfo(`[event-gateway] ws listening on ws://${params.env.host}:${params.env.port}`);

  wss.on("connection", (ws) => {
    const state = createConnectionState();

    ws.on("message", async (buffer) => {
      await handleRawMessage({
        env: params.env,
        supabase: params.supabase,
        registry: params.registry,
        ws,
        state,
        raw: String(buffer ?? ""),
      });
    });

    ws.on("close", async () => {
      await cleanupConnection({
        supabase: params.supabase,
        registry: params.registry,
        ws,
        state,
      });
    });

    ws.on("error", () => {
      try {
        ws.close();
      } catch {
        // ignore socket close errors
      }
    });
  });

  return wss;
}
