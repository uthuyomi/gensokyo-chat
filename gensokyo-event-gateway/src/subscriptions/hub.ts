import type { RealtimeChannel, SupabaseClient } from "@supabase/supabase-js";
import type WebSocket from "ws";

export type ChannelHub = {
  channel: string;
  clients: Set<WebSocket>;
  realtime: RealtimeChannel | null;
};

export type HubRegistry = Map<string, ChannelHub>;

export function getOrCreateHub(registry: HubRegistry, channel: string): ChannelHub {
  const existing = registry.get(channel);
  if (existing) return existing;

  const hub: ChannelHub = {
    channel,
    clients: new Set<WebSocket>(),
    realtime: null,
  };
  registry.set(channel, hub);
  return hub;
}

export async function releaseHubIfEmpty(params: {
  registry: HubRegistry;
  channel: string;
  supabase: SupabaseClient;
}): Promise<void> {
  const hub = params.registry.get(params.channel);
  if (!hub || hub.clients.size > 0) return;
  if (hub.realtime) {
    try {
      await params.supabase.removeChannel(hub.realtime);
    } catch {
      // ignore channel cleanup errors
    }
  }
  params.registry.delete(params.channel);
}
