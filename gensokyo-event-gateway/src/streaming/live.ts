import type { RealtimePostgresInsertPayload, SupabaseClient } from "@supabase/supabase-js";
import type WebSocket from "ws";

import type { GatewayEnv } from "../config/env.js";
import type { ServerMsg, WorldEventRow } from "../protocol/messages.js";
import type { ChannelHub, HubRegistry } from "../subscriptions/hub.js";
import { getOrCreateHub } from "../subscriptions/hub.js";
import { logWarn } from "../infrastructure/logger.js";
import { serializeServerMessage } from "../utils/json.js";

function send(ws: WebSocket, message: ServerMsg) {
  ws.send(serializeServerMessage(message));
}

export function attachLiveSubscription(params: {
  env: GatewayEnv;
  supabase: SupabaseClient;
  registry: HubRegistry;
  channel: string;
}): ChannelHub {
  const hub = getOrCreateHub(params.registry, params.channel);
  if (hub.realtime) return hub;

  const realtime = params.supabase
    .channel(`world_event_log:${params.channel}`)
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: params.env.supabaseSchema,
        table: "world_event_log",
        filter: `channel=eq.${params.channel}`,
      },
      (payload: RealtimePostgresInsertPayload<WorldEventRow>) => {
        const row = payload.new;
        if (!row) return;
        for (const client of hub.clients) {
          send(client, { type: "event", channel: params.channel, event: row });
        }
      },
    );

  realtime.subscribe((status, err) => {
    if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
      logWarn("[event-gateway] realtime subscribe failed:", params.channel, status, err);
    }
  });

  hub.realtime = realtime;
  return hub;
}
