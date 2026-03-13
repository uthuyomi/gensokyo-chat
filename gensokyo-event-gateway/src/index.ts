import { WebSocketServer } from "ws";
import { createClient, type SupabaseClient } from "@supabase/supabase-js";

type ClientMsg =
  | { type: "hello"; auth?: { mode: "supabase_jwt"; access_token: string } }
  | { type: "subscribe"; channel: string; lastSeq?: number }
  | { type: "unsubscribe"; channel: string };

type ServerMsg =
  | { type: "ack"; hello?: boolean }
  | { type: "snapshot"; channel: string; fromSeq: number; events: unknown[] }
  | { type: "event"; channel: string; event: unknown }
  | { type: "error"; code: string; message: string };

type ConnState = {
  authed: boolean;
  userId: string | null;
  subs: Set<string>;
};

const SUPABASE_URL = process.env.SUPABASE_URL || "";
const SUPABASE_SERVICE_ROLE_KEY = process.env.SUPABASE_SERVICE_ROLE_KEY || "";
const SUPABASE_SCHEMA = process.env.SUPABASE_SCHEMA || "public";

const PORT = Number(process.env.GENSOKYO_EVENT_GATEWAY_PORT || "8787");
const HOST = process.env.GENSOKYO_EVENT_GATEWAY_HOST || "127.0.0.1";

// Local dev shortcut. In production, set to "0" and require auth.
const ALLOW_ANON = (process.env.GENSOKYO_EVENT_GATEWAY_ALLOW_ANON || "1") === "1";

function mustEnv() {
  if (!SUPABASE_URL || !SUPABASE_SERVICE_ROLE_KEY) {
    throw new Error("[event-gateway] SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing");
  }
}

function supabaseAdmin(): SupabaseClient {
  mustEnv();
  return createClient(SUPABASE_URL, SUPABASE_SERVICE_ROLE_KEY, {
    auth: { persistSession: false, autoRefreshToken: false, detectSessionInUrl: false },
    global: {
      headers: {
        "Accept-Profile": SUPABASE_SCHEMA,
        "Content-Profile": SUPABASE_SCHEMA,
      },
    },
  });
}

const sb = supabaseAdmin();

function send(ws: any, msg: ServerMsg) {
  ws.send(JSON.stringify(msg));
}

function safeParse(raw: string): ClientMsg | null {
  try {
    const v = JSON.parse(raw) as any;
    if (!v || typeof v.type !== "string") return null;
    return v as ClientMsg;
  } catch {
    return null;
  }
}

type ChannelHub = {
  channel: string;
  clients: Set<any>;
  rt: ReturnType<SupabaseClient["channel"]> | null;
};

const hubs = new Map<string, ChannelHub>();

async function ensureHub(channel: string): Promise<ChannelHub> {
  const existing = hubs.get(channel);
  if (existing) return existing;

  const hub: ChannelHub = { channel, clients: new Set(), rt: null };
  hubs.set(channel, hub);

  // Subscribe to new inserts via Supabase Realtime (no polling).
  const rt = sb
    .channel(`world_event_log:${channel}`)
    .on(
      "postgres_changes",
      {
        event: "INSERT",
        schema: SUPABASE_SCHEMA,
        table: "world_event_log",
        filter: `channel=eq.${channel}`,
      },
      (payload) => {
        const row = (payload as any)?.new ?? null;
        if (!row) return;
        for (const c of hub.clients) {
          send(c, { type: "event", channel, event: row });
        }
      },
    );

  hub.rt = rt;
  rt.subscribe((status, err) => {
    if (status === "CHANNEL_ERROR" || status === "TIMED_OUT") {
      console.warn("[event-gateway] realtime subscribe failed:", channel, status, err);
    }
  });

  return hub;
}

async function releaseHubIfEmpty(channel: string) {
  const hub = hubs.get(channel);
  if (!hub) return;
  if (hub.clients.size > 0) return;
  if (hub.rt) {
    try {
      await sb.removeChannel(hub.rt);
    } catch {
      // ignore
    }
  }
  hubs.delete(channel);
}

async function sendSnapshot(ws: any, channel: string, lastSeq: number) {
  const fromSeq = Math.max(0, (Number.isFinite(lastSeq) ? lastSeq : 0) + 1);
  const pageSize = 250;

  let minSeq = fromSeq;
  for (;;) {
    const { data, error } = await sb
      .from("world_event_log")
      .select("*")
      .eq("channel", channel)
      .gte("seq", minSeq)
      .order("seq", { ascending: true })
      .limit(pageSize);

    if (error) {
      send(ws, { type: "error", code: "snapshot_failed", message: String(error.message || error) });
      return;
    }
    const events = (data ?? []) as any[];
    if (events.length === 0) {
      // still send an empty snapshot so the client can switch to live cleanly
      send(ws, { type: "snapshot", channel, fromSeq, events: [] });
      return;
    }

    send(ws, { type: "snapshot", channel, fromSeq: minSeq, events });

    if (events.length < pageSize) return;
    minSeq = Number(events[events.length - 1]?.seq ?? minSeq) + 1;
  }
}

async function authHello(msg: ClientMsg & { type: "hello" }): Promise<{ userId: string | null }> {
  const token = msg.auth?.access_token ? String(msg.auth.access_token) : "";
  if (!token) return { userId: null };
  try {
    const { data, error } = await sb.auth.getUser(token);
    if (error) return { userId: null };
    const id = data?.user?.id ? String(data.user.id) : null;
    return { userId: id };
  } catch {
    return { userId: null };
  }
}

function isValidChannel(ch: string) {
  const s = String(ch ?? "").trim();
  // Minimal validation to avoid abuse. Real auth rules can be added later.
  return /^world:[a-z0-9_]+(?::[a-z0-9_]+)?$/i.test(s);
}

const wss = new WebSocketServer({ host: HOST, port: PORT });
console.log(`[event-gateway] ws listening on ws://${HOST}:${PORT}`);

wss.on("connection", (ws) => {
  const state: ConnState = { authed: false, userId: null, subs: new Set() };

  ws.on("message", async (buf) => {
    const msg = safeParse(String(buf ?? ""));
    if (!msg) {
      send(ws, { type: "error", code: "bad_request", message: "Invalid JSON" });
      return;
    }

    if (msg.type === "hello") {
      const { userId } = await authHello(msg);
      state.userId = userId;
      state.authed = Boolean(userId) || ALLOW_ANON;
      if (!state.authed) {
        send(ws, { type: "error", code: "unauthorized", message: "Auth required" });
        try {
          ws.close();
        } catch {
          // ignore
        }
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
      const channel = String(msg.channel ?? "").trim();
      if (!isValidChannel(channel)) {
        send(ws, { type: "error", code: "bad_channel", message: "Invalid channel" });
        return;
      }

      state.subs.add(channel);
      const hub = await ensureHub(channel);
      hub.clients.add(ws);
      await sendSnapshot(ws, channel, Number(msg.lastSeq ?? 0));
      return;
    }

    if (msg.type === "unsubscribe") {
      const channel = String(msg.channel ?? "").trim();
      state.subs.delete(channel);
      const hub = hubs.get(channel);
      if (hub) {
        hub.clients.delete(ws);
        await releaseHubIfEmpty(channel);
      }
      send(ws, { type: "ack" });
      return;
    }
  });

  ws.on("close", async () => {
    for (const ch of state.subs) {
      const hub = hubs.get(ch);
      if (!hub) continue;
      hub.clients.delete(ws);
      await releaseHubIfEmpty(ch);
    }
    state.subs.clear();
  });
});
