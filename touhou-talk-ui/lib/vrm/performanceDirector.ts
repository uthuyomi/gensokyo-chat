import {
  getCharacterPerformanceProfile,
  type CharacterPerformanceProfile,
  type VrmEmotion,
  type VrmGesture,
} from "@/lib/vrm/performanceProfiles";

export type VrmPerformanceCue = {
  emotion: VrmEmotion;
  gesture: VrmGesture | null;
  gestureNonce: number;
  cameraYawDeg: number;
  cameraPitchDeg: number;
  cameraDistance: number;
  cameraFov: number;
};

export type VrmPerformanceMeta = {
  emotion: VrmEmotion;
  gesture: VrmGesture | null;
  gesture_nonce: number;
  camera_yaw_deg: number;
  camera_pitch_deg: number;
  camera_distance: number;
  camera_fov: number;
};

type Params = {
  characterId: string | null | undefined;
  text: string | null | undefined;
  messageId?: string | null | undefined;
  speaking?: boolean;
};

function hasAny(text: string, needles: string[]) {
  return needles.some((needle) => text.includes(needle));
}

function inferEmotion(text: string, profile: CharacterPerformanceProfile, speaking: boolean): VrmEmotion {
  const s = text.trim();
  if (!s) return speaking ? profile.speakingEmotion ?? profile.defaultEmotion : profile.defaultEmotion;

  if (hasAny(s, ["？", "?", "どうし", "なぜ", "どこ", "どれ", "かな", "かも", "悩", "迷"])) {
    return "thinking";
  }
  if (hasAny(s, ["怒", "違う", "だめ", "駄目", "危ない", "危険", "やめ", "許さ", "困る"])) {
    return "angry";
  }
  if (hasAny(s, ["悲", "つら", "辛", "寂", "泣", "しんど", "疲れた", "落ち込"])) {
    return "sad";
  }
  if (hasAny(s, ["！", "!", "すご", "やった", "いい", "面白", "楽しい", "笑", "ふふ", "うふふ"])) {
    return "happy";
  }

  return speaking ? profile.speakingEmotion ?? profile.defaultEmotion : profile.defaultEmotion;
}

function inferGesture(text: string, emotion: VrmEmotion, profile: CharacterPerformanceProfile): VrmGesture | null {
  const s = text.trim();
  if (!s) return null;

  const candidates: Array<[VrmGesture, boolean, number]> = [
    ["surprise", hasAny(s, ["！", "!?", "？！", "えっ", "まさか", "ほんと", "本当"]), 1.1],
    ["laugh", hasAny(s, ["笑", "あは", "ふふ", "うふ", "くす"]), 1.0],
    ["wave", hasAny(s, ["よろしく", "また", "おいで", "やっほ", "こんにちは", "こんばんは"]), 0.8],
    ["bow", hasAny(s, ["ありがとう", "助かった", "失礼", "よろしくお願いします"]), 0.78],
    ["shake_head", hasAny(s, ["違う", "だめ", "駄目", "やめ", "無理", "いや"]), 0.95],
    ["think", hasAny(s, ["どうし", "かな", "たぶん", "整理", "考え", "まず"]), 0.88],
    ["nod", hasAny(s, ["そう", "うん", "なるほど", "わかった", "じゃあ"]), 0.82],
    ["tilt_head", hasAny(s, ["？", "?", "ふーん", "へえ", "ほんと"]), 0.72],
    ["look_side", emotion === "thinking" || hasAny(s, ["思い出", "記憶", "少し待", "見てみ"]), 0.7],
    ["shrug", hasAny(s, ["仕方", "まあ", "別に", "そんなもの"]), 0.65],
    ["arms_cross", emotion === "angry" || hasAny(s, ["当然", "まったく", "面倒"]), 0.58],
  ];

  let best: { gesture: VrmGesture; score: number } | null = null;
  for (const [gesture, hit, baseScore] of candidates) {
    if (!hit) continue;
    const score = baseScore * (profile.gestureBias[gesture] ?? 1);
    if (!best || score > best.score) best = { gesture, score };
  }
  return best?.gesture ?? null;
}

function hashNonce(messageId: string, emotion: string, gesture: string | null) {
  const raw = `${messageId}::${emotion}::${gesture ?? ""}`;
  let h = 0;
  for (let i = 0; i < raw.length; i += 1) {
    h = (h * 31 + raw.charCodeAt(i)) >>> 0;
  }
  return h;
}

export function buildVrmPerformanceCue(params: Params): VrmPerformanceCue {
  const profile = getCharacterPerformanceProfile(params.characterId);
  const text = String(params.text ?? "").trim();
  const emotion = inferEmotion(text, profile, !!params.speaking);
  const gesture = inferGesture(text, emotion, profile);
  const messageId = String(params.messageId ?? "").trim();

  const cameraYawDeg = profile.camera.yawDeg + (emotion === "thinking" ? 2 : 0);
  const cameraPitchDeg = profile.camera.pitchDeg + (emotion === "sad" ? -1.2 : 0);
  const cameraDistance =
    profile.camera.distance +
    (emotion === "happy" ? -0.03 : 0) +
    (emotion === "sad" ? 0.05 : 0) +
    (profile.moodBias.aloof > 0 ? 0.04 * profile.moodBias.aloof : 0);
  const cameraFov = profile.camera.fov + (profile.moodBias.playful > 0.25 ? 1 : 0);

  return {
    emotion,
    gesture,
    gestureNonce: hashNonce(messageId || text || "idle", emotion, gesture),
    cameraYawDeg,
    cameraPitchDeg,
    cameraDistance,
    cameraFov,
  };
}

export function toVrmPerformanceMeta(cue: VrmPerformanceCue): VrmPerformanceMeta {
  return {
    emotion: cue.emotion,
    gesture: cue.gesture,
    gesture_nonce: cue.gestureNonce,
    camera_yaw_deg: cue.cameraYawDeg,
    camera_pitch_deg: cue.cameraPitchDeg,
    camera_distance: cue.cameraDistance,
    camera_fov: cue.cameraFov,
  };
}
