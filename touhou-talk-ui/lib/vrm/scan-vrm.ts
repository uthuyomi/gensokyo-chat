import type { GlbJson } from "@/lib/vrm/parse-glb";

export type VrmScanResult = {
  id: string;
  scannedAt: string;
  gltf: {
    nodeCount: number;
    nodes: Array<{
      index: number;
      name: string | null;
      children: number[];
    }>;
  };
  humanoid?: {
    schema: "VRM0" | "VRM1" | "unknown";
    humanBones: Array<{
      humanBone: string;
      node: number | null;
      nodeName: string | null;
    }>;
  };
  expressions?: {
    schema: "VRM0" | "VRM1" | "unknown";
    names: string[];
  };
};

function nodeName(json: GlbJson, idx: number | null | undefined) {
  if (typeof idx !== "number") return null;
  const n = json.nodes?.[idx];
  const name = typeof n?.name === "string" ? n.name : null;
  return name;
}

export function scanVrmGltfJson(id: string, json: GlbJson): VrmScanResult {
  const nodesRaw = Array.isArray(json.nodes) ? json.nodes : [];
  const nodes = nodesRaw.map((n, index) => ({
    index,
    name: typeof n?.name === "string" ? n.name : null,
    children: Array.isArray(n?.children)
      ? (n.children.filter((c) => typeof c === "number") as number[])
      : [],
  }));

  const result: VrmScanResult = {
    id,
    scannedAt: new Date().toISOString(),
    gltf: { nodeCount: nodes.length, nodes },
  };

  const ext = (json.extensions ?? {}) as Record<string, unknown>;
  const vrm0 = (ext.VRM ?? null) as any;
  const vrm1 = (ext.VRMC_vrm ?? null) as any;

  // Humanoid mapping
  if (vrm0 && typeof vrm0 === "object") {
    const hb0 = vrm0?.humanoid?.humanBones;
    if (Array.isArray(hb0)) {
      result.humanoid = {
        schema: "VRM0",
        humanBones: hb0
          .map((b: any) => ({
            humanBone: typeof b?.bone === "string" ? b.bone : "unknown",
            node: typeof b?.node === "number" ? b.node : null,
            nodeName: nodeName(json, typeof b?.node === "number" ? b.node : null),
          }))
          .filter((x) => !!x.humanBone),
      };
    }

    const bsg = vrm0?.blendShapeMaster?.blendShapeGroups;
    if (Array.isArray(bsg)) {
      const names = bsg
        .map((g: any) =>
          typeof g?.presetName === "string" && g.presetName
            ? g.presetName
            : typeof g?.name === "string"
              ? g.name
              : null,
        )
        .filter((x: any): x is string => typeof x === "string" && x.trim().length > 0);
      result.expressions = { schema: "VRM0", names: Array.from(new Set(names)) };
    }
  }

  if (vrm1 && typeof vrm1 === "object") {
    const hb = vrm1?.humanoid?.humanBones;
    if (hb && typeof hb === "object" && !Array.isArray(hb)) {
      const bones = Object.entries(hb as Record<string, any>)
        .map(([humanBone, v]) => ({
          humanBone,
          node: typeof v?.node === "number" ? v.node : null,
          nodeName: nodeName(json, typeof v?.node === "number" ? v.node : null),
        }))
        .filter((x) => !!x.humanBone);

      result.humanoid = { schema: "VRM1", humanBones: bones };
    }

    const ex = vrm1?.expressions;
    if (ex && typeof ex === "object") {
      const preset =
        ex.preset && typeof ex.preset === "object" ? Object.keys(ex.preset) : [];
      const custom =
        ex.custom && typeof ex.custom === "object" ? Object.keys(ex.custom) : [];
      const names = Array.from(new Set([...preset, ...custom])).filter((s) => !!s);
      result.expressions = { schema: "VRM1", names };
    }
  }

  return result;
}
