import { NextResponse } from "next/server";
import path from "node:path";
import { promises as fs } from "node:fs";

function safeId(raw: string): string | null {
  const id = String(raw ?? "").trim();
  if (!id) return null;
  if (!/^[a-z0-9_-]+$/i.test(id)) return null;
  return id;
}

function vrmPathForId(id: string) {
  return path.join(process.cwd(), "vrm-characters", `${id}.vrm`);
}

async function unwrapParams(
  ctx: { params: unknown },
): Promise<{ id?: unknown } | null> {
  try {
    const p = (ctx as { params?: unknown } | null)?.params;
    if (!p) return null;
    // Next.js can pass params as a Promise in some runtimes / versions.
    const v = typeof (p as Promise<unknown>)?.then === "function" ? await p : p;
    return (v ?? null) as { id?: unknown } | null;
  } catch {
    return null;
  }
}

export async function HEAD(
  _req: Request,
  ctx: { params: unknown },
) {
  const params = await unwrapParams(ctx);
  const id = safeId(params?.id as string);
  if (!id) return NextResponse.json({ error: "Invalid id" }, { status: 400 });

  const filePath = vrmPathForId(id);
  try {
    const st = await fs.stat(filePath);
    if (!st.isFile()) {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }

    return new NextResponse(null, {
      status: 200,
      headers: {
        "Content-Type": "model/gltf-binary",
        "Content-Length": String(st.size),
        "Cache-Control": "no-store",
      },
    });
  } catch (e) {
    const code = (e as { code?: unknown } | null)?.code;
    if (code === "ENOENT") {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}

export async function GET(_req: Request, ctx: { params: unknown }) {
  const params = await unwrapParams(ctx);
  const id = safeId(params?.id as string);
  if (!id) return NextResponse.json({ error: "Invalid id" }, { status: 400 });

  const filePath = vrmPathForId(id);
  try {
    const buf = await fs.readFile(filePath);
    return new NextResponse(buf, {
      status: 200,
      headers: {
        "Content-Type": "model/gltf-binary",
        "Cache-Control": "no-store",
      },
    });
  } catch (e) {
    const code = (e as { code?: unknown } | null)?.code;
    if (code === "ENOENT") {
      return NextResponse.json({ error: "Not found" }, { status: 404 });
    }
    return NextResponse.json({ error: "Internal error" }, { status: 500 });
  }
}
