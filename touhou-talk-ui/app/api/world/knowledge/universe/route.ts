export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { NextRequest, NextResponse } from "next/server";
import "server-only";

import { worldEngineBaseUrl, worldEngineHeaders } from "@/app/api/world/_worldEngine";

export async function GET(req: NextRequest) {
  const url = new URL(req.url);
  const worldId = (url.searchParams.get("world_id") || "").trim() || "gensokyo_main";
  const limit = (url.searchParams.get("limit") || "").trim() || "2000";
  const embeddingModel = (url.searchParams.get("embedding_model") || "").trim();
  const maxEdgesPerNode = (url.searchParams.get("max_edges_per_node") || "").trim() || "2";
  const similarityThreshold = (url.searchParams.get("similarity_threshold") || "").trim() || "0.32";

  const search = new URLSearchParams({
    world_id: worldId,
    limit,
    max_edges_per_node: maxEdgesPerNode,
    similarity_threshold: similarityThreshold,
  });
  if (embeddingModel) search.set("embedding_model", embeddingModel);

  const upstream = await fetch(`${worldEngineBaseUrl()}/world/knowledge/universe?${search.toString()}`, {
    headers: worldEngineHeaders(),
    cache: "no-store",
  }).catch((e) => ({ ok: false, status: 502, text: async () => String(e) }) as const);

  if (!upstream.ok) {
    const text = await upstream.text().catch(() => "");
    return NextResponse.json({ error: "world_engine_error", detail: text }, { status: upstream.status || 502 });
  }

  const json = await upstream.json().catch(() => null);
  return NextResponse.json(json ?? { world_id: worldId, node_count: 0, edge_count: 0, source_counts: {}, nodes: [], edges: [] });
}
