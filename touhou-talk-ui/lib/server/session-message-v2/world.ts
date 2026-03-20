import {
  worldEngineBaseUrl,
  worldEngineHeaders,
} from "@/app/api/world/_worldEngine";
import { isRecord } from "../session-message/meta";

type WorldPromptContext = {
  world_id: string;
  location_id: string;
  state: Record<string, unknown> | null;
  recent_events: Array<{
    event_type: string;
    summary: string;
    created_at?: string | null;
  }>;
};

export async function loadWorldPromptContextBestEffort(params: {
  worldId: string | null;
  locationId: string | null;
}): Promise<WorldPromptContext | null> {
  const worldId = String(params.worldId ?? "").trim();
  const locationId = String(params.locationId ?? "").trim();
  if (!worldId) return null;

  const base = worldEngineBaseUrl();
  const headers = worldEngineHeaders();
  const qs = new URLSearchParams({
    world_id: worldId,
    location_id: locationId,
  }).toString();

  const [stateRes, recentRes] = await Promise.all([
    fetch(`${base}/world/state?${qs}`, { headers, cache: "no-store" }).catch(
      () => null,
    ),
    fetch(`${base}/world/recent?${qs}&limit=8`, {
      headers,
      cache: "no-store",
    }).catch(() => null),
  ]);

  const state =
    stateRes && (stateRes as Response).ok
      ? await (stateRes as Response).json().catch(() => null)
      : null;
  const recentJson =
    recentRes && (recentRes as Response).ok
      ? await (recentRes as Response).json().catch(() => null)
      : null;
  const recent_events = Array.isArray((recentJson as any)?.recent_events)
    ? ((recentJson as any).recent_events as any[])
        .map((e) => ({
          event_type: String(e?.event_type ?? "event"),
          summary: String(e?.summary ?? "").trim(),
          created_at: e?.created_at ? String(e.created_at) : null,
        }))
        .filter((e) => e.summary)
    : [];

  return {
    world_id: worldId,
    location_id: locationId,
    state: isRecord(state) ? (state as Record<string, unknown>) : null,
    recent_events,
  };
}

export function buildWorldOverlay(world: WorldPromptContext | null): string | null {
  if (!world) return null;

  const lines: string[] = [];
  lines.push("# World (snapshot)");
  lines.push(`- world_id: ${world.world_id}`);
  lines.push(`- location_id: ${world.location_id || "(none)"}`);

  const s = world.state || {};
  const timeOfDay = typeof s.time_of_day === "string" ? s.time_of_day : null;
  const weather = typeof s.weather === "string" ? s.weather : null;
  const season = typeof s.season === "string" ? s.season : null;
  const moon = typeof s.moon_phase === "string" ? s.moon_phase : null;
  const anomaly = typeof s.anomaly === "string" ? s.anomaly : null;
  if (timeOfDay) lines.push(`- time_of_day: ${timeOfDay}`);
  if (weather) lines.push(`- weather: ${weather}`);
  if (season) lines.push(`- season: ${season}`);
  if (moon) lines.push(`- moon_phase: ${moon}`);
  if (anomaly) lines.push(`- anomaly: ${anomaly}`);

  if (world.recent_events.length) {
    lines.push("- recent_events:");
    for (const e of world.recent_events.slice(-8)) {
      lines.push(`  - ${e.event_type}: ${e.summary}`);
    }
  }

  lines.push(
    "- IMPORTANT: Use this as ambient context; do not dump it verbatim.",
  );
  return lines.join("\n");
}