export const runtime = "nodejs";
export const dynamic = "force-dynamic";

import { NextRequest, NextResponse } from "next/server";

import { dbManagerBaseUrl, dbManagerHeaders } from "@/app/api/db-manager/_dbManager";

async function proxy(req: NextRequest, method: string, params: { path?: string[] }) {
  const path = (params.path || []).join("/");
  const url = new URL(req.url);
  const upstreamUrl = `${dbManagerBaseUrl()}/${path}${url.search}`;
  const init: RequestInit = {
    method,
    headers: dbManagerHeaders(req.headers),
    cache: "no-store",
  };
  if (method !== "GET") {
    const rawBody = await req.text();
    let normalizedBody = rawBody;
    if (rawBody) {
      try {
        normalizedBody = JSON.stringify(JSON.parse(rawBody));
      } catch {
        normalizedBody = rawBody;
      }
    }
    init.body = normalizedBody || undefined;
    init.headers = dbManagerHeaders({ ...Object.fromEntries(req.headers.entries()), "Content-Type": "application/json" });
  }

  const upstream = await fetch(upstreamUrl, init).catch((e) => ({ ok: false, status: 502, text: async () => String(e) }) as const);
  if (!upstream.ok) {
    const text = await upstream.text().catch(() => "");
    return NextResponse.json({ error: "db_manager_error", detail: text }, { status: upstream.status || 502 });
  }
  const text = await upstream.text().catch(() => "");
  if (!text) return NextResponse.json({ ok: true });
  try {
    return NextResponse.json(JSON.parse(text));
  } catch {
    return new NextResponse(text, { status: 200 });
  }
}

export async function GET(req: NextRequest, context: { params: Promise<{ path?: string[] }> }) {
  return proxy(req, "GET", await context.params);
}

export async function POST(req: NextRequest, context: { params: Promise<{ path?: string[] }> }) {
  return proxy(req, "POST", await context.params);
}
