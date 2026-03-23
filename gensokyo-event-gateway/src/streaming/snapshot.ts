import type WebSocket from "ws";
import type { SupabaseClient } from "@supabase/supabase-js";

import type { ServerMsg, WorldEventRow } from "../protocol/messages.js";
import { serializeServerMessage } from "../utils/json.js";

function send(ws: WebSocket, message: ServerMsg) {
  ws.send(serializeServerMessage(message));
}

export async function sendSnapshot(params: {
  supabase: SupabaseClient;
  ws: WebSocket;
  channel: string;
  lastSeq: number;
}): Promise<void> {
  const fromSeq = Math.max(0, (Number.isFinite(params.lastSeq) ? params.lastSeq : 0) + 1);
  const pageSize = 250;
  let minSeq = fromSeq;

  for (;;) {
    const { data, error } = await params.supabase
      .from("world_event_log")
      .select("*")
      .eq("channel", params.channel)
      .gte("seq", minSeq)
      .order("seq", { ascending: true })
      .limit(pageSize);

    if (error) {
      send(params.ws, {
        type: "error",
        code: "snapshot_failed",
        message: String(error.message || error),
      });
      return;
    }

    const events = (data ?? []) as WorldEventRow[];
    if (events.length === 0) {
      send(params.ws, { type: "snapshot", channel: params.channel, fromSeq, events: [] });
      return;
    }

    send(params.ws, {
      type: "snapshot",
      channel: params.channel,
      fromSeq: minSeq,
      events,
    });

    if (events.length < pageSize) return;
    minSeq = Number(events[events.length - 1]?.seq ?? minSeq) + 1;
  }
}
