import { NextResponse } from "next/server";
import path from "node:path";
import { promises as fs } from "node:fs";
import { parseGlbJson } from "@/lib/vrm/parse-glb";
import { scanVrmGltfJson, type VrmScanResult } from "@/lib/vrm/scan-vrm";

function safeId(raw: string): string | null {
  const id = String(raw ?? "").trim();
  if (!id) return null;
  if (!/^[a-z0-9_-]+$/i.test(id)) return null;
  return id;
}

async function unwrapParams(
  ctx: { params: unknown },
): Promise<{ id?: unknown } | null> {
  try {
    const p = (ctx as { params?: unknown } | null)?.params;
    if (!p) return null;
    const v = typeof (p as any)?.then === "function" ? await (p as any) : p;
    return (v ?? null) as { id?: unknown } | null;
  } catch {
    return null;
  }
}

function vrmPathForId(id: string) {
  return path.join(process.cwd(), "vrm-characters", `${id}.vrm`);
}

function scanPathForId(id: string) {
  return path.join(process.cwd(), "vrm-characters", `${id}.scan.json`);
}

async function readVrmAndScan(id: string): Promise<VrmScanResult> {
  const buf = await fs.readFile(vrmPathForId(id));
  const json = parseGlbJson(
    buf.buffer.slice(buf.byteOffset, buf.byteOffset + buf.byteLength),
  );
  return scanVrmGltfJson(id, json);
}

export async function GET(_req: Request, ctx: { params: unknown }) {
  const params = await unwrapParams(ctx);
  const id = safeId(params?.id as string);
  if (!id) return NextResponse.json({ error: "Invalid id" }, { status: 400 });

  const p = scanPathForId(id);
  try {
    const raw = await fs.readFile(p, "utf8");
    return NextResponse.json(JSON.parse(raw), { status: 200 });
  } catch (e) {
    const code = (e as { code?: unknown } | null)?.code;
    if (code === "ENOENT") {
      return NextResponse.json({ error: "Scan not found" }, { status: 404 });
    }
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function POST(_req: Request, ctx: { params: unknown }) {
  const params = await unwrapParams(ctx);
  const id = safeId(params?.id as string);
  if (!id) return NextResponse.json({ error: "Invalid id" }, { status: 400 });

  try {
    const scan = await readVrmAndScan(id);
    const outPath = scanPathForId(id);
    await fs.writeFile(outPath, JSON.stringify(scan, null, 2), "utf8");
    console.log("[/api/vrm/:id/scan] saved:", outPath);
    return NextResponse.json(
      {
        ok: true,
        saved: path.basename(outPath),
        savedPath: outPath,
        nodeCount: scan.gltf.nodeCount,
      },
      { status: 200 },
    );
  } catch (e) {
    const msg = e instanceof Error ? e.message : "Internal error";
    return NextResponse.json({ error: msg }, { status: 500 });
  }
}
