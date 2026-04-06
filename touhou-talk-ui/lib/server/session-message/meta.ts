import { createHash } from "crypto";

export function isRecord(v: unknown): v is Record<string, unknown> {
  return !!v && typeof v === "object" && !Array.isArray(v);
}

export function sha256Hex(s: string) {
  return createHash("sha256").update(s).digest("hex");
}

export function mergeMeta(
  base: unknown,
  extra: Record<string, unknown>,
): Record<string, unknown> {
  const out: Record<string, unknown> = isRecord(base) ? { ...(base as Record<string, unknown>) } : {};
  const cur = isRecord(out.touhou_ui) ? (out.touhou_ui as Record<string, unknown>) : {};
  out.touhou_ui = { ...cur, ...extra };
  return out;
}

export function withTtsReadingMeta(
  base: Record<string, unknown>,
  readingText: string | null,
  model: string | null,
): Record<string, unknown> {
  if (!readingText) return base;
  const tts = isRecord(base.tts) ? { ...(base.tts as Record<string, unknown>) } : {};
  tts.reading_text = readingText;
  if (model) tts.reading_model = model;
  return { ...base, tts };
}

export function summarizeCoreRoutingMeta(
  base: unknown,
): Record<string, unknown> {
  const meta = isRecord(base) ? base : {};
  const controllerMeta = isRecord(meta.controller_meta)
    ? (meta.controller_meta as Record<string, unknown>)
    : {};
  const webRag = isRecord(meta.web_rag)
    ? (meta.web_rag as Record<string, unknown>)
    : {};
  const webMeta = isRecord(webRag.meta)
    ? (webRag.meta as Record<string, unknown>)
    : {};

  return {
    intent_route:
      typeof meta.intent_route === "string" ? meta.intent_route : null,
    lightweight_turn:
      typeof controllerMeta.lightweight_turn === "boolean"
        ? controllerMeta.lightweight_turn
        : null,
    lightweight_reason:
      typeof controllerMeta.reason === "string" ? controllerMeta.reason : null,
    web_provider:
      typeof webMeta.provider === "string" ? webMeta.provider : null,
    web_intent:
      typeof webMeta.intent === "string" ? webMeta.intent : null,
    web_skipped_reason:
      typeof webMeta.skipped_reason === "string"
        ? webMeta.skipped_reason
        : null,
    web_sources_count:
      typeof webRag.sources_count === "number" ? webRag.sources_count : null,
  };
}
