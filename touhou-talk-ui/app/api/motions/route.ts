import { NextResponse } from "next/server";
import path from "node:path";
import { promises as fs } from "node:fs";

type MotionKind = "idle" | "talk" | "gesture";

type MotionEntry = {
  name: string;
  kind: MotionKind;
  path: string;
  source?: string;
};

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

function convertedGlbRoot() {
  return path.join(motionLibraryRoot(), "converted", "glb");
}

function kindFromFilename(baseName: string): MotionKind {
  const s = baseName.toLowerCase();
  if (s.startsWith("idle")) return "idle";
  if (s.startsWith("talk")) return "talk";
  return "gesture";
}

export async function GET() {
  const root = motionLibraryRoot();

  let motions: MotionEntry[] = [];
  try {
    const raw = await fs.readFile(motionsJsonPath(), "utf8");
    const parsed = JSON.parse(raw) as { motions?: unknown };
    const arr = Array.isArray(parsed?.motions) ? (parsed.motions as unknown[]) : [];
    motions = arr
      .map((m): MotionEntry | null => {
        const obj = (m ?? null) as Partial<MotionEntry> | null;
        const name = safeName(obj?.name);
        const kind =
          obj?.kind === "idle" || obj?.kind === "talk" || obj?.kind === "gesture"
            ? obj.kind
            : null;
        const p = typeof obj?.path === "string" ? obj.path : "";
        if (!name || !kind || !p) return null;
        return { name, kind, path: p, source: typeof obj?.source === "string" ? obj.source : undefined };
      })
      .filter((v): v is MotionEntry => !!v);
  } catch {
    motions = [];
  }

  // Fallback: if motions.json is empty/missing, auto-discover converted/glb/*.glb.
  if (motions.length === 0) {
    try {
      const files = await fs.readdir(convertedGlbRoot(), { withFileTypes: true });
      motions = files
        .filter((d) => d.isFile() && d.name.toLowerCase().endsWith(".glb"))
        .map((d) => {
          const base = d.name.replace(/\.glb$/i, "");
          const name = safeName(base) ?? base.replace(/[^a-z0-9._-]/gi, "_");
          return {
            name,
            kind: kindFromFilename(name),
            path: path.posix.join("converted", "glb", d.name),
            source: "local",
          };
        });
    } catch {
      motions = [];
    }
  }

  // Validate that referenced files stay inside the motion-library root and exist.
  const visible: Array<{ name: string; kind: MotionKind; url: string; source?: string }> = [];
  for (const m of motions) {
    try {
      const abs = path.resolve(root, m.path);
      if (!abs.startsWith(path.resolve(root) + path.sep)) continue;
      const st = await fs.stat(abs);
      if (!st.isFile()) continue;
      visible.push({
        name: m.name,
        kind: m.kind,
        url: `/api/motions/${encodeURIComponent(m.name)}`,
        source: m.source,
      });
    } catch {
      // ignore missing
    }
  }

  return NextResponse.json(
    {
      version: 1,
      motions: visible,
    },
    {
      status: 200,
      headers: {
        "Cache-Control": "no-store",
      },
    },
  );
}
