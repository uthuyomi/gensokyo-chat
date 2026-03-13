export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { NextRequest, NextResponse } from "next/server";
import "server-only";

import { worldEngineBaseUrl, worldEngineHeaders } from "@/app/api/world/_worldEngine";

export async function POST(req: NextRequest) {
  const body = await req.json().catch(() => null);
  if (!body || typeof body !== "object") {
    return NextResponse.json({ error: "Invalid JSON body" }, { status: 400 });
  }

  const upstream = await fetch(`${worldEngineBaseUrl()}/world/tick`, {
    method: "POST",
    headers: worldEngineHeaders({ "Content-Type": "application/json" }),
    body: JSON.stringify(body),
  }).catch((e) => ({ ok: false, status: 502, text: async () => String(e) }) as any);

  if (!upstream.ok) {
    const text = await upstream.text().catch(() => "");
    return NextResponse.json({ error: "world_engine_error", detail: text }, { status: upstream.status || 502 });
  }

  const json = await upstream.json().catch(() => null);
  return NextResponse.json(json ?? { ok: true });
}

