import type { VrmEmotion, VrmGesture } from "@/lib/vrm/performanceProfiles";
import type { VrmPerformanceCue } from "@/lib/vrm/performanceDirector";

type CueInput = VrmPerformanceCue & {
  messageKey: string;
  speaking: boolean;
};

const GESTURE_HOLD_MS: Record<VrmGesture, number> = {
  nod: 700,
  shake_head: 800,
  tilt_head: 1100,
  look_side: 1000,
  shrug: 900,
  bow: 1100,
  wave: 1300,
  think: 2200,
  surprise: 900,
  laugh: 1200,
  arms_cross: 2600,
};

const GESTURE_COOLDOWN_MS: Record<VrmGesture, number> = {
  nod: 900,
  shake_head: 1100,
  tilt_head: 1200,
  look_side: 1300,
  shrug: 1400,
  bow: 1800,
  wave: 1900,
  think: 2200,
  surprise: 2000,
  laugh: 1800,
  arms_cross: 2600,
};

const EMOTION_HOLD_MS: Record<VrmEmotion, number> = {
  neutral: 0,
  happy: 900,
  angry: 1400,
  sad: 1500,
  thinking: 1300,
};

export class VrmAnimationStateMachine {
  private lastMessageKey: string | null = null;
  private currentEmotion: VrmEmotion = "neutral";
  private emotionUntil = 0;
  private currentGesture: VrmGesture | null = null;
  private gestureUntil = 0;
  private gestureCooldownUntil = new Map<VrmGesture, number>();
  private lastGestureNonce: number | null = null;

  resolve(input: CueInput, now = Date.now()): VrmPerformanceCue {
    const isNewMessage = this.lastMessageKey !== input.messageKey;
    if (isNewMessage) {
      this.lastMessageKey = input.messageKey;
    }

    const wantedEmotion = input.emotion;
    if (
      isNewMessage ||
      now >= this.emotionUntil ||
      (this.currentEmotion === "neutral" && wantedEmotion !== "neutral")
    ) {
      this.currentEmotion = wantedEmotion;
      this.emotionUntil = now + (EMOTION_HOLD_MS[wantedEmotion] ?? 0);
    }

    if (this.currentEmotion !== "neutral" && now >= this.emotionUntil && !input.speaking) {
      this.currentEmotion = "neutral";
      this.emotionUntil = now;
    }

    const wantedGesture = input.gesture;
    const canTriggerGesture =
      !!wantedGesture &&
      (isNewMessage || this.lastGestureNonce !== input.gestureNonce) &&
      now >= (this.gestureCooldownUntil.get(wantedGesture) ?? 0);

    if (canTriggerGesture && wantedGesture) {
      this.currentGesture = wantedGesture;
      this.gestureUntil = now + (GESTURE_HOLD_MS[wantedGesture] ?? 900);
      this.gestureCooldownUntil.set(
        wantedGesture,
        now + (GESTURE_COOLDOWN_MS[wantedGesture] ?? 1400),
      );
      this.lastGestureNonce = input.gestureNonce;
    } else if (this.currentGesture && now >= this.gestureUntil) {
      this.currentGesture = null;
    }

    if (input.speaking && this.currentEmotion === "neutral" && wantedEmotion !== "neutral") {
      this.currentEmotion = wantedEmotion;
      this.emotionUntil = now + 900;
    }

    return {
      emotion: this.currentEmotion,
      gesture: this.currentGesture,
      gestureNonce: this.lastGestureNonce ?? input.gestureNonce,
      cameraYawDeg: input.cameraYawDeg,
      cameraPitchDeg: input.cameraPitchDeg,
      cameraDistance: input.cameraDistance,
      cameraFov: input.cameraFov,
    };
  }
}
