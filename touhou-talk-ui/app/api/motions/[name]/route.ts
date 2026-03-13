import { NextResponse } from "next/server";
import path from "node:path";
import { promises as fs } from "node:fs";

function safeName(raw: unknown): string | null {
  const name = String(raw ?? "").trim();
  if (!name) return null;
  if (!/^[a-z0-9][a-z0-9._-]*$/i.test(name)) return null;
  return name;
}

function motionLibraryRoot() {
  return path.join(process.cwd(), "vrm-characters", "motion-library");
}

function motionsJsonPath() {
  return path.join(motionLibraryRoot(), "motions.json");
}

async function unwrapParams(
  ctx: { params: unknown },
): Promise<{ name?: unknown } | null> {
  try {
    const p = (ctx as { params?: unknown } | null)?.params;
    if (!p) return null;
    const v = typeof (p as Promise<unknown>)?.then === "function" ? await p : p;
    return (v ?? null) as { name?: unknown } | null;
  } catch {
    return null;
  }
}

async function resolvePathByName(name: string): Promise<string | null> {
  // Primary source: motions.json mapping.
  try {
    const raw = await fs.readFile(motionsJsonPath(), "utf8");
    const parsed = JSON.parse(raw) as { motions?: unknown };
    const arr = Array.isArray(parsed?.motions) ? (parsed.motions as unknown[]) : [];
    for (const m of arr) {
      const obj = (m ?? null) as { name?: unknown; path?: unknown } | null;
      const n = safeName(obj?.name as string);
      const p = typeof obj?.path === "string" ? obj.path : "";
      if (n === name && p) return p;
    }
  } catch {
    // ignore
  }

  // Fallback: converted/glb/{name}.glb
  return path.posix.join("converted", "glb", `${name}.glb`);
}

export async function GET(_req: Request, ctx: { params: unknown }) {
  const params = await unwrapParams(ctx);
  const name = safeName(params?.name as string);
  if (!name) return NextResponse.json({ error: "Invalid name" }, { status: 400 });

  const root = motionLibraryRoot();
  const rel = await resolvePathByName(name);
  if (!rel) return NextResponse.json({ error: "Not found" }, { status: 404 });

  const abs = path.resolve(root, rel);
  if (!abs.startsWith(path.resolve(root) + path.sep)) {
    return NextResponse.json({ error: "Not found" }, { status: 404 });
  }

  try {
    const buf = await fs.readFile(abs);
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
