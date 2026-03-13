/* eslint-disable @typescript-eslint/no-explicit-any */
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { supabaseBrowser } from "@/lib/supabaseClient";
import { useTouhouUi } from "@/components/assistant-ui/touhou-ui-context";
import { cn } from "@/lib/utils";
import { useSearchParams } from "next/navigation";

type WorldEvent = {
  id: string;
  channel: string;
  seq: number;
  ts: string;
  world_id?: string;
  layer_id?: string;
  location_id?: string | null;
  type: string;
  actor?: { kind: string; id?: string | null } | null;
  payload?: Record<string, unknown> | null;
};

type CharacterMap = Record<string, { name?: string }>;

function wsUrl() {
  return (
    process.env.NEXT_PUBLIC_GENSOKYO_WS_URL ||
    (typeof window !== "undefined" ? (window as any).__TOUHOU_PUBLIC?.gensokyoWsUrl : "") ||
    "ws://127.0.0.1:8787"
  );
}

function storageKey(channel: string) {
  return `gensokyo:lastSeq:${channel}`;
}

function readLastSeq(channel: string) {
  try {
    const v = window.localStorage.getItem(storageKey(channel));
    const n = v != null ? Number(v) : 0;
    return Number.isFinite(n) ? n : 0;
  } catch {
    return 0;
  }
}

function writeLastSeq(channel: string, seq: number) {
  try {
    window.localStorage.setItem(storageKey(channel), String(seq));
  } catch {
    // ignore
  }
}

function formatEventLine(e: WorldEvent, characters: CharacterMap) {
  const payload = (e.payload ?? {}) as any;
  const text = typeof payload?.text === "string" ? payload.text.trim() : "";
  const actorId = e.actor?.id ? String(e.actor.id) : "";
  const actorName = actorId && characters[actorId]?.name ? String(characters[actorId].name) : null;
  const who =
    actorName ||
    (e.actor?.kind === "user" ? "You" : actorId ? actorId : e.actor?.kind ? String(e.actor.kind) : "system");

  if (e.type === "npc_dialogue") {
    const speakerId = typeof payload?.speaker === "string" ? payload.speaker : actorId || "";
    const listenerId = typeof payload?.listener === "string" ? payload.listener : "";
    const speakerName = speakerId && characters[speakerId]?.name ? String(characters[speakerId].name) : speakerId || who;
    const listenerName = listenerId && characters[listenerId]?.name ? String(characters[listenerId].name) : listenerId || "?";
    const line = typeof payload?.text === "string" ? String(payload.text).trim() : "";
    return `[${speakerName} → ${listenerName}] ${line || "(...)"}`;
  }
  if (e.type === "npc_say") return `${who}: ${text || "(...)"}`;
  if (e.type === "npc_action") return `${who}: ${String(payload?.action ?? "action")}`;
  if (e.type === "world_tick") return `world: ${String(payload?.summary ?? "tick")}`;
  return `${e.type}: ${text || String(payload?.summary ?? "")}`.trim();
}

export default function WorldEventLogPanel(props: { className?: string }) {
  const { characters } = useTouhouUi();
  const searchParams = useSearchParams();
  const layer = searchParams.get("layer");
  const loc = searchParams.get("loc");
  const worldFromUrl = searchParams.get("world");
  const worldId = worldFromUrl ? worldFromUrl : layer ? `${layer}_main` : "gensokyo_main";
  const channel = worldId && loc ? `world:${worldId}:${loc}` : null;

  const [connected, setConnected] = useState(false);
  const [events, setEvents] = useState<WorldEvent[]>([]);
  const wsRef = useRef<WebSocket | null>(null);
  const lastSeqRef = useRef<number>(0);

  useEffect(() => {
    if (!channel) return;

    let closed = false;
    let reconnectTimer: number | null = null;

    const connect = async () => {
      if (closed) return;

      const sb = supabaseBrowser();
      const { data } = await sb.auth.getSession();
      const token = data?.session?.access_token ? String(data.session.access_token) : "";

      const ws = new WebSocket(wsUrl());
      wsRef.current = ws;
      setConnected(false);

      ws.onopen = () => {
        if (closed) return;
        const lastSeq = readLastSeq(channel);
        lastSeqRef.current = lastSeq;
        ws.send(JSON.stringify({ type: "hello", auth: token ? { mode: "supabase_jwt", access_token: token } : undefined }));
        ws.send(JSON.stringify({ type: "subscribe", channel, lastSeq }));
      };

      ws.onmessage = (ev) => {
        if (closed) return;
        try {
          const msg = JSON.parse(String(ev.data ?? "")) as any;
          if (msg?.type === "ack" && msg.hello) setConnected(true);
          if (msg?.type === "snapshot" && msg.channel === channel && Array.isArray(msg.events)) {
            const incoming = msg.events as WorldEvent[];
            if (incoming.length === 0) return;
            setEvents((prev) => {
              const seen = new Set(prev.map((x) => `${x.channel}:${x.seq}`));
              const merged = [...prev];
              for (const e of incoming) {
                const k = `${e.channel}:${e.seq}`;
                if (seen.has(k)) continue;
                merged.push(e);
                seen.add(k);
                if (Number.isFinite(e.seq) && e.seq > lastSeqRef.current) lastSeqRef.current = e.seq;
              }
              merged.sort((a, b) => (a.seq ?? 0) - (b.seq ?? 0));
              // keep last 80
              const trimmed = merged.slice(-80);
              if (trimmed.length > 0) {
                const maxSeq = Math.max(...trimmed.map((x) => Number(x.seq ?? 0)));
                if (Number.isFinite(maxSeq) && maxSeq > 0) writeLastSeq(channel, maxSeq);
              }
              return trimmed;
            });
          }
          if (msg?.type === "event" && msg.channel === channel && msg.event) {
            const e = msg.event as WorldEvent;
            setEvents((prev) => {
              const k = `${e.channel}:${e.seq}`;
              if (prev.some((x) => `${x.channel}:${x.seq}` === k)) return prev;
              const merged = [...prev, e].sort((a, b) => (a.seq ?? 0) - (b.seq ?? 0)).slice(-80);
              if (Number.isFinite(e.seq) && e.seq > lastSeqRef.current) lastSeqRef.current = e.seq;
              if (Number.isFinite(e.seq) && e.seq > 0) writeLastSeq(channel, e.seq);
              return merged;
            });
          }
        } catch {
          // ignore
        }
      };

      ws.onclose = () => {
        if (closed) return;
        setConnected(false);
        reconnectTimer = window.setTimeout(connect, 1200);
      };

      ws.onerror = () => {
        // close triggers reconnect
        try {
          ws.close();
        } catch {
          // ignore
        }
      };
    };

    void connect();

    return () => {
      closed = true;
      if (reconnectTimer) window.clearTimeout(reconnectTimer);
      try {
        wsRef.current?.close();
      } catch {
        // ignore
      }
      wsRef.current = null;
      setConnected(false);
    };
  }, [channel]);

  if (!channel) return null;

  return (
    <div className={cn("pointer-events-auto sticky top-0 col-start-1 z-10 px-2 pt-1", props.className)}>
      <div className="rounded-2xl bg-background/60 px-3 py-2 shadow backdrop-blur-md">
        <div className="flex items-center justify-between gap-3">
          <div className="truncate text-xs text-muted-foreground">
            world log ({loc}) {connected ? "connected" : "offline"}
          </div>
        </div>
        <div className="mt-2 max-h-44 overflow-y-auto pr-1 text-xs leading-relaxed">
          {events.length === 0 ? (
            <div className="text-muted-foreground">no events yet</div>
          ) : (
            <ul className="space-y-1">
              {events.map((e) => {
                const line = formatEventLine(e, characters as CharacterMap);
                return (
                  <li key={`${e.channel}:${e.seq}`} className="truncate">
                    <span className="opacity-70">#{e.seq}</span> {line}
                  </li>
                );
              })}
            </ul>
          )}
        </div>
      </div>
    </div>
  );
}
