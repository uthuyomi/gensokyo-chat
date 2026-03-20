"use client";

import { useCallback, useEffect, useMemo, useRef, useState } from "react";

type SpeakParams = {
  text: string;
  lang?: string;
  rate?: number;
  pitch?: number;
  volume?: number;
};

type SpeakResult = { ok: true } | { ok: false; reason: string };

function getSpeechSynthesis(): SpeechSynthesis | null {
  if (typeof window === "undefined") return null;
  const ss = (window as any).speechSynthesis as SpeechSynthesis | undefined;
  return ss ?? null;
}

function chooseVoice(voices: SpeechSynthesisVoice[], lang: string) {
  const wanted = String(lang ?? "").toLowerCase();
  const exact = voices.find((v) => String(v.lang ?? "").toLowerCase() === wanted);
  if (exact) return exact;
  const prefix = wanted.split("-")[0] ?? wanted;
  if (prefix) {
    const pref = voices.find((v) => String(v.lang ?? "").toLowerCase().startsWith(prefix));
    if (pref) return pref;
  }
  return voices[0] ?? null;
}

export function useBrowserTts(defaultLang = "ja-JP") {
  const ss = useMemo(() => getSpeechSynthesis(), []);
  const supported = !!ss && typeof SpeechSynthesisUtterance !== "undefined";

  const [speaking, setSpeaking] = useState(false);
  const [voices, setVoices] = useState<SpeechSynthesisVoice[]>([]);

  const utteranceRef = useRef<SpeechSynthesisUtterance | null>(null);

  const refreshVoices = useCallback(() => {
    if (!ss) return;
    try {
      const v = ss.getVoices();
      if (Array.isArray(v) && v.length) setVoices(v);
    } catch {
      // ignore
    }
  }, [ss]);

  useEffect(() => {
    if (!ss) return;
    const refreshTimer = window.setTimeout(() => refreshVoices(), 0);
    const handler = () => refreshVoices();
    try {
      (ss as any).addEventListener?.("voiceschanged", handler);
    } catch {
      // ignore
    }
    return () => {
      window.clearTimeout(refreshTimer);
      try {
        (ss as any).removeEventListener?.("voiceschanged", handler);
      } catch {
        // ignore
      }
    };
  }, [ss, refreshVoices]);

  const cancel = useCallback(() => {
    if (!ss) return;
    try {
      ss.cancel();
    } catch {
      // ignore
    }
    utteranceRef.current = null;
    setSpeaking(false);
  }, [ss]);

  const speak = useCallback(
    (params: SpeakParams): SpeakResult => {
      if (!supported || !ss) return { ok: false, reason: "SpeechSynthesis is not supported" };

      const text = String(params.text ?? "").trim();
      if (!text) return { ok: false, reason: "Empty text" };

      const lang = String(params.lang ?? defaultLang).trim() || defaultLang;
      const rate = typeof params.rate === "number" ? params.rate : 1.0;
      const pitch = typeof params.pitch === "number" ? params.pitch : 1.0;
      const volume = typeof params.volume === "number" ? params.volume : 1.0;

      try {
        ss.cancel();
      } catch {
        // ignore
      }

      const u = new SpeechSynthesisUtterance(text);
      u.lang = lang;
      u.rate = Math.max(0.1, Math.min(10, rate));
      u.pitch = Math.max(0, Math.min(2, pitch));
      u.volume = Math.max(0, Math.min(1, volume));

      const v = chooseVoice(voices, lang);
      if (v) u.voice = v;

      u.onstart = () => setSpeaking(true);
      u.onend = () => setSpeaking(false);
      u.onerror = () => setSpeaking(false);

      utteranceRef.current = u;

      try {
        ss.speak(u);
        return { ok: true };
      } catch (e) {
        utteranceRef.current = null;
        setSpeaking(false);
        return { ok: false, reason: e instanceof Error ? e.message : "Failed to speak" };
      }
    },
    [supported, ss, voices, defaultLang],
  );

  return {
    supported,
    speaking,
    voices,
    speak,
    cancel,
  };
}
