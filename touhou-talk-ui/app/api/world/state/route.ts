export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { NextRequest, NextResponse } from "next/server";
import "server-only";

import { worldEngineBaseUrl, worldEngineHeaders } from "@/app/api/world/_worldEngine";

export async function GET(req: NextRequest) {
  const url = new URL(req.url);
  const worldId = (url.searchParams.get("world_id") || "").trim();
  const locationId = (url.searchParams.get("location_id") || "").trim();
  if (!worldId) return NextResponse.json({ error: "world_id required" }, { status: 400 });

  const qs = new URLSearchParams({ world_id: worldId, location_id: locationId }).toString();
  const upstream = await fetch(`${worldEngineBaseUrl()}/world/state?${qs}`, {
    headers: worldEngineHeaders(),
    cache: "no-store",
  }).catch((e) => ({ ok: false, status: 502, text: async () => String(e) }) as any);

  if (!upstream.ok) {
    const text = await upstream.text().catch(() => "");
    return NextResponse.json({ error: "world_engine_error", detail: text }, { status: upstream.status || 502 });
  }

  const json = await upstream.json().catch(() => null);
  return NextResponse.json(json ?? { ok: true });
}

