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

export type CharacterPerformanceProfile = {
  camera: {
    yawDeg: number;
    pitchDeg: number;
    distance: number;
    fov: number;
  };
  defaultEmotion: VrmEmotion;
  speakingEmotion?: VrmEmotion;
  gestureBias: Partial<Record<VrmGesture, number>>;
  moodBias: {
    cheerful: number;
    serious: number;
    playful: number;
    aloof: number;
  };
};

const BASE_PROFILE: CharacterPerformanceProfile = {
  camera: { yawDeg: 0, pitchDeg: 6, distance: 2.05, fov: 28 },
  defaultEmotion: "neutral",
  speakingEmotion: "neutral",
  gestureBias: {
    nod: 1,
    think: 1,
    tilt_head: 0.9,
  },
  moodBias: {
    cheerful: 0,
    serious: 0,
    playful: 0,
    aloof: 0,
  },
};

export const CHARACTER_PERFORMANCE_PROFILES: Record<string, CharacterPerformanceProfile> = {
  reimu: {
    ...BASE_PROFILE,
    camera: { yawDeg: 0, pitchDeg: 5, distance: 2.1, fov: 27 },
    defaultEmotion: "neutral",
    speakingEmotion: "neutral",
    gestureBias: { nod: 1.15, think: 1.1, arms_cross: 0.9, shrug: 0.85 },
    moodBias: { cheerful: 0.05, serious: 0.3, playful: -0.1, aloof: 0.25 },
  },
  marisa: {
    ...BASE_PROFILE,
    camera: { yawDeg: -4, pitchDeg: 7, distance: 1.95, fov: 29 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { nod: 1.2, wave: 1.15, laugh: 1.1, shrug: 1.05 },
    moodBias: { cheerful: 0.4, serious: -0.1, playful: 0.35, aloof: -0.25 },
  },
  alice: {
    ...BASE_PROFILE,
    camera: { yawDeg: 3, pitchDeg: 6, distance: 2.05, fov: 28 },
    defaultEmotion: "neutral",
    speakingEmotion: "thinking",
    gestureBias: { think: 1.25, tilt_head: 1.05, bow: 0.8 },
    moodBias: { cheerful: -0.1, serious: 0.25, playful: -0.2, aloof: 0.2 },
  },
  aya: {
    ...BASE_PROFILE,
    camera: { yawDeg: -6, pitchDeg: 8, distance: 1.92, fov: 29 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { nod: 1.2, wave: 0.95, surprise: 0.95, look_side: 1.1 },
    moodBias: { cheerful: 0.25, serious: 0, playful: 0.2, aloof: -0.2 },
  },
  meiling: {
    ...BASE_PROFILE,
    camera: { yawDeg: -2, pitchDeg: 8, distance: 2.0, fov: 28 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { nod: 1.1, wave: 1.05, laugh: 0.95, shrug: 0.9 },
    moodBias: { cheerful: 0.35, serious: -0.1, playful: 0.15, aloof: -0.25 },
  },
  momiji: {
    ...BASE_PROFILE,
    camera: { yawDeg: 2, pitchDeg: 6, distance: 2.0, fov: 28 },
    defaultEmotion: "neutral",
    speakingEmotion: "neutral",
    gestureBias: { nod: 1.05, bow: 1.05, think: 1.0, look_side: 0.9 },
    moodBias: { cheerful: -0.05, serious: 0.35, playful: -0.2, aloof: 0.15 },
  },
  nitori: {
    ...BASE_PROFILE,
    camera: { yawDeg: -5, pitchDeg: 8, distance: 1.96, fov: 29 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { nod: 1.05, think: 1.2, wave: 0.85, shrug: 1.1 },
    moodBias: { cheerful: 0.25, serious: 0.05, playful: 0.25, aloof: -0.25 },
  },
  patchouli: {
    ...BASE_PROFILE,
    camera: { yawDeg: 3, pitchDeg: 5, distance: 2.12, fov: 27 },
    defaultEmotion: "thinking",
    speakingEmotion: "thinking",
    gestureBias: { think: 1.35, tilt_head: 0.9, look_side: 0.85 },
    moodBias: { cheerful: -0.25, serious: 0.45, playful: -0.25, aloof: 0.35 },
  },
  reisen: {
    ...BASE_PROFILE,
    camera: { yawDeg: -2, pitchDeg: 6, distance: 2.02, fov: 28 },
    defaultEmotion: "neutral",
    speakingEmotion: "thinking",
    gestureBias: { think: 1.05, nod: 0.95, look_side: 1.0, surprise: 0.95 },
    moodBias: { cheerful: -0.1, serious: 0.2, playful: -0.1, aloof: 0.05 },
  },
  remilia: {
    ...BASE_PROFILE,
    camera: { yawDeg: -4, pitchDeg: 8, distance: 1.96, fov: 29 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { laugh: 1.2, look_side: 1.1, nod: 0.95, wave: 0.75 },
    moodBias: { cheerful: 0.2, serious: 0, playful: 0.2, aloof: 0.35 },
  },
  sakuya: {
    ...BASE_PROFILE,
    camera: { yawDeg: 2, pitchDeg: 5, distance: 2.02, fov: 27 },
    defaultEmotion: "neutral",
    speakingEmotion: "neutral",
    gestureBias: { bow: 1.1, nod: 1.05, think: 0.95, arms_cross: 0.6 },
    moodBias: { cheerful: -0.05, serious: 0.35, playful: -0.2, aloof: 0.25 },
  },
  flandre: {
    ...BASE_PROFILE,
    camera: { yawDeg: -6, pitchDeg: 9, distance: 1.9, fov: 30 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { laugh: 1.2, surprise: 1.15, tilt_head: 1.15, wave: 0.95 },
    moodBias: { cheerful: 0.25, serious: -0.2, playful: 0.45, aloof: -0.1 },
  },
  satori: {
    ...BASE_PROFILE,
    camera: { yawDeg: 1, pitchDeg: 6, distance: 2.04, fov: 28 },
    defaultEmotion: "thinking",
    speakingEmotion: "thinking",
    gestureBias: { think: 1.3, look_side: 1.05, nod: 0.85 },
    moodBias: { cheerful: -0.2, serious: 0.35, playful: -0.25, aloof: 0.2 },
  },
  rin: {
    ...BASE_PROFILE,
    camera: { yawDeg: -4, pitchDeg: 8, distance: 1.94, fov: 29 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { shrug: 1.15, wave: 0.95, nod: 1.0, laugh: 1.05 },
    moodBias: { cheerful: 0.3, serious: -0.1, playful: 0.25, aloof: -0.2 },
  },
  okuu: {
    ...BASE_PROFILE,
    camera: { yawDeg: -3, pitchDeg: 9, distance: 1.98, fov: 29 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { nod: 1.25, surprise: 1.05, wave: 0.9, laugh: 0.95 },
    moodBias: { cheerful: 0.35, serious: -0.2, playful: 0.2, aloof: -0.3 },
  },
  sanae: {
    ...BASE_PROFILE,
    camera: { yawDeg: -3, pitchDeg: 7, distance: 1.98, fov: 28 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { nod: 1.15, wave: 0.85, bow: 0.8, think: 0.9 },
    moodBias: { cheerful: 0.2, serious: 0.05, playful: 0.1, aloof: -0.15 },
  },
  suwako: {
    ...BASE_PROFILE,
    camera: { yawDeg: 3, pitchDeg: 7, distance: 2.0, fov: 28 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { tilt_head: 1.15, look_side: 1.0, nod: 0.95, laugh: 0.85 },
    moodBias: { cheerful: 0.2, serious: -0.05, playful: 0.25, aloof: 0.05 },
  },
  koishi: {
    ...BASE_PROFILE,
    camera: { yawDeg: -7, pitchDeg: 8, distance: 1.92, fov: 30 },
    defaultEmotion: "happy",
    speakingEmotion: "happy",
    gestureBias: { tilt_head: 1.25, look_side: 1.2, surprise: 1.05, laugh: 1.0 },
    moodBias: { cheerful: 0.2, serious: -0.2, playful: 0.5, aloof: -0.05 },
  },
  yuyuko: {
    ...BASE_PROFILE,
    camera: { yawDeg: 2, pitchDeg: 6, distance: 2.12, fov: 27 },
    defaultEmotion: "happy",
    speakingEmotion: "neutral",
    gestureBias: { tilt_head: 1.1, laugh: 0.95, nod: 0.85, think: 0.9 },
    moodBias: { cheerful: 0.15, serious: -0.05, playful: 0.15, aloof: 0.25 },
  },
  youmu: {
    ...BASE_PROFILE,
    camera: { yawDeg: -1, pitchDeg: 6, distance: 2.0, fov: 28 },
    defaultEmotion: "neutral",
    speakingEmotion: "neutral",
    gestureBias: { nod: 1.1, bow: 1.0, think: 0.95, shake_head: 0.95 },
    moodBias: { cheerful: -0.05, serious: 0.35, playful: -0.15, aloof: 0.05 },
  },
};

export function getCharacterPerformanceProfile(characterId: string | null | undefined): CharacterPerformanceProfile {
  const id = String(characterId ?? "").trim().toLowerCase();
  return CHARACTER_PERFORMANCE_PROFILES[id] ?? BASE_PROFILE;
}
