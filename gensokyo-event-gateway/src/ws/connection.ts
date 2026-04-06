import type { SupabaseClient } from "@supabase/supabase-js";
import type WebSocket from "ws";

import type { GatewayEnv } from "../config/env.js";
import { canOpenConnection } from "../auth/access.js";
import { authenticateHello } from "../auth/hello.js";
import { releaseHubIfEmpty, type HubRegistry } from "../subscriptions/hub.js";
import { attachLiveSubscription } from "../streaming/live.js";
import { sendSnapshot } from "../streaming/snapshot.js";
import type { ClientMsg, ServerMsg } from "../protocol/messages.js";
import { safeParseClientMessage } from "../protocol/validation.js";
import { isValidChannel } from "../utils/channel.js";
import { serializeServerMessage } from "../utils/json.js";

export type ConnectionState = {
  authed: boolean;
  userId: string | null;
  subs: Set<string>;
};

function send(ws: WebSocket, message: ServerMsg) {
  ws.send(serializeServerMessage(message));
}

export function createConnectionState(): ConnectionState {
  return {
    authed: false,
    userId: null,
    subs: new Set<string>(),
  };
}

export async function handleRawMessage(params: {
  env: GatewayEnv;
  supabase: SupabaseClient;
  registry: HubRegistry;
  ws: WebSocket;
  state: ConnectionState;
  raw: string;
}): Promise<void> {
  const msg = safeParseClientMessage(params.raw);
  if (!msg) {
    send(params.ws, { type: "error", code: "bad_request", message: "Invalid JSON" });
    return;
  }
  await handleClientMessage({ ...params, msg });
}

async function handleClientMessage(params: {
  env: GatewayEnv;
  supabase: SupabaseClient;
  registry: HubRegistry;
  ws: WebSocket;
  state: ConnectionState;
  msg: ClientMsg;
}): Promise<void> {
  const { msg, state, ws } = params;

  if (msg.type === "hello") {
    const { userId } = await authenticateHello(params.supabase, msg);
    state.userId = userId;
    state.authed = canOpenConnection({ env: params.env, userId });
    if (!state.authed) {
      send(ws, { type: "error", code: "unauthorized", message: "Auth required" });
      ws.close();
      return;
    }
    send(ws, { type: "ack", hello: true });
    return;
  }

  if (!state.authed) {
    send(ws, { type: "error", code: "unauthorized", message: "Send hello first" });
    return;
  }

  if (msg.type === "subscribe") {
    const channel = String(msg.channel || "").trim();
    if (!isValidChannel(channel)) {
      send(ws, { type: "error", code: "bad_channel", message: "Invalid channel" });
      return;
    }

    state.subs.add(channel);
    const hub = attachLiveSubscription({
      env: params.env,
      supabase: params.supabase,
      registry: params.registry,
      channel,
    });
    hub.clients.add(ws);
    await sendSnapshot({
      supabase: params.supabase,
      ws,
      channel,
      lastSeq: Number(msg.lastSeq ?? 0),
    });
    return;
  }

  if (msg.type === "unsubscribe") {
    const channel = String(msg.channel || "").trim();
    state.subs.delete(channel);
    const hub = params.registry.get(channel);
    if (hub) {
      hub.clients.delete(ws);
      await releaseHubIfEmpty({
        registry: params.registry,
        channel,
        supabase: params.supabase,
      });
    }
    send(ws, { type: "ack" });
  }
}

export async function cleanupConnection(params: {
  supabase: SupabaseClient;
  registry: HubRegistry;
  ws: WebSocket;
  state: ConnectionState;
}): Promise<void> {
  for (const channel of params.state.subs) {
    const hub = params.registry.get(channel);
    if (!hub) continue;
    hub.clients.delete(params.ws);
    await releaseHubIfEmpty({
      registry: params.registry,
      channel,
      supabase: params.supabase,
    });
  }
  params.state.subs.clear();
}
