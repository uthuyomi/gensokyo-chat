export type VrmEmotion = "neutral" | "happy" | "angry" | "sad" | "thinking";

export type VrmGesture =
  | "nod"
  | "shake_head"
  | "tilt_head"
  | "look_side"
  | "shrug"
  | "bow"
  | "wave"
  | "think"
  | "surprise"
  | "laugh"
  | "arms_cross";

export type VrmDirective = {
  emotion?: VrmEmotion;
  gesture?: VrmGesture;
  intensity?: number; // 0..1 (future use)
  tempo?: number; // 0.5..2 (future use)
  holdSec?: number; // gesture hold hint (future use)
};

export type ParsedVrmDirective = {
  text: string;
  directive: VrmDirective | null;
};

function clamp(x: number, lo: number, hi: number) {
  return Math.max(lo, Math.min(hi, x));
}

function normalizeEmotion(v: unknown): VrmEmotion | null {
  const s = String(v ?? "")
    .trim()
    .toLowerCase();
  if (s === "neutral") return "neutral";
  if (s === "happy") return "happy";
  if (s === "angry") return "angry";
  if (s === "sad") return "sad";
  if (s === "thinking") return "thinking";
  // common variants
  if (s === "joy") return "happy";
  if (s === "surprised" || s === "surprise") return "thinking";
  if (s === "annoyed") return "angry";
  return null;
}

function normalizeGesture(v: unknown): VrmGesture | null {
  const s = String(v ?? "")
    .trim()
    .toLowerCase()
    .replace(/-/g, "_");
  const allowed: Record<string, VrmGesture> = {
    nod: "nod",
    shake_head: "shake_head",
    tilt_head: "tilt_head",
    look_side: "look_side",
    shrug: "shrug",
    bow: "bow",
    wave: "wave",
    think: "think",
    thinking: "think",
    surprise: "surprise",
    surprised: "surprise",
    laugh: "laugh",
    arms_cross: "arms_cross",
    armscross: "arms_cross",
  };
  return allowed[s] ?? null;
}

function parseJsonObject(s: string): Record<string, unknown> | null {
  try {
    const v = JSON.parse(s);
    if (!v || typeof v !== "object" || Array.isArray(v)) return null;
    return v as Record<string, unknown>;
  } catch {
    return null;
  }
}

// Extract a directive from a fenced code block:
// ```vrm
// { "emotion":"happy", "gesture":"nod" }
// ```
export function parseVrmDirectiveFromText(raw: string): ParsedVrmDirective {
  const text = String(raw ?? "");
  const rx = /```(?:vrm|vrm-directive)\s*([\s\S]*?)```/i;
  const m = rx.exec(text);
  if (!m) return { text, directive: null };

  const obj = parseJsonObject(m[1].trim());
  if (!obj) return { text: text.replace(rx, "").trim(), directive: null };

  const emotion = normalizeEmotion(obj.emotion);
  const gesture = normalizeGesture(obj.gesture);

  const intensity =
    typeof obj.intensity === "number" && Number.isFinite(obj.intensity)
      ? clamp(obj.intensity, 0, 1)
      : undefined;
  const tempo =
    typeof obj.tempo === "number" && Number.isFinite(obj.tempo)
      ? clamp(obj.tempo, 0.5, 2)
      : undefined;
  const holdSec =
    typeof obj.holdSec === "number" && Number.isFinite(obj.holdSec)
      ? clamp(obj.holdSec, 0, 30)
      : undefined;

  const directive: VrmDirective = {
    emotion: emotion ?? undefined,
    gesture: gesture ?? undefined,
    intensity,
    tempo,
    holdSec,
  };

  const cleaned = text.replace(rx, "").trim();
  return { text: cleaned, directive };
}

