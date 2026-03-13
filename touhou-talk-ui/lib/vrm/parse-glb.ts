export type GlbJson = {
  asset?: unknown;
  scenes?: unknown;
  nodes?: Array<{ name?: string; children?: number[]; [k: string]: unknown }>;
  skins?: unknown;
  animations?: unknown;
  extensionsUsed?: string[];
  extensionsRequired?: string[];
  extensions?: Record<string, unknown>;
  [k: string]: unknown;
};

function readU32LE(buf: Uint8Array, offset: number) {
  return (
    buf[offset] |
    (buf[offset + 1] << 8) |
    (buf[offset + 2] << 16) |
    (buf[offset + 3] << 24)
  ) >>> 0;
}

/**
 * Minimal GLB/VRM (glTF binary) parser.
 * Returns the decoded glTF JSON chunk.
 */
export function parseGlbJson(buffer: ArrayBuffer): GlbJson {
  const u8 = new Uint8Array(buffer);
  if (u8.byteLength < 20) throw new Error("GLB too small");

  const magic =
    String.fromCharCode(u8[0] ?? 0) +
    String.fromCharCode(u8[1] ?? 0) +
    String.fromCharCode(u8[2] ?? 0) +
    String.fromCharCode(u8[3] ?? 0);
  if (magic !== "glTF") throw new Error("Not a GLB (bad magic)");

  const version = readU32LE(u8, 4);
  if (version !== 2) throw new Error(`Unsupported GLB version: ${version}`);

  const length = readU32LE(u8, 8);
  if (length !== u8.byteLength) {
    // tolerate mismatch but still try to parse
  }

  let offset = 12;
  let jsonText: string | null = null;

  const decoder = new TextDecoder("utf-8");
  while (offset + 8 <= u8.byteLength) {
    const chunkLen = readU32LE(u8, offset);
    const chunkType = readU32LE(u8, offset + 4);
    offset += 8;
    if (offset + chunkLen > u8.byteLength) break;

    // 0x4E4F534A = JSON
    if (chunkType === 0x4e4f534a) {
      jsonText = decoder.decode(u8.slice(offset, offset + chunkLen));
      break;
    }
    offset += chunkLen;
  }

  if (!jsonText) throw new Error("GLB JSON chunk not found");

  const json = JSON.parse(jsonText) as GlbJson;
  if (!json || typeof json !== "object") throw new Error("Invalid glTF JSON");
  return json;
}

