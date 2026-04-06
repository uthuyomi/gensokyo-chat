"use client";

import { useEffect, useMemo, useState } from "react";

import { useLanguage } from "@/components/i18n/LanguageProvider";
import { supabaseBrowser } from "@/lib/supabaseClient";

const DEV_EMAIL = "kaiseif4e@gmail.com";
const LS_KEY = "touhou.dev.coreMode";

type CoreMode = "fly" | "local";

function readMode(): CoreMode {
  if (typeof window === "undefined") return "fly";
  const v = String(window.localStorage.getItem(LS_KEY) ?? "").trim().toLowerCase();
  return v === "local" ? "local" : "fly";
}

function writeMode(m: CoreMode) {
  if (typeof window === "undefined") return;
  window.localStorage.setItem(LS_KEY, m);
}

export function getDevCoreModeClient(): CoreMode {
  return readMode();
}

export default function DevCoreToggle() {
  const { lang } = useLanguage();
  const [allowed, setAllowed] = useState(false);
  const [mode, setMode] = useState<CoreMode>(() => readMode());

  useEffect(() => {
    let canceled = false;
    (async () => {
      try {
        const sb = supabaseBrowser();
        const { data } = await sb.auth.getUser();
        const email = String(data.user?.email ?? "").trim().toLowerCase();
        if (!canceled) setAllowed(email === DEV_EMAIL);
      } catch {
        if (!canceled) setAllowed(false);
      }
    })();
    return () => {
      canceled = true;
    };
  }, []);

  const copy = useMemo(
    () =>
      lang === "ja"
        ? {
            title: "Core 接続先（開発用）",
            description:
              "ログイン中のユーザーが開発アカウントのときだけ表示されます。デスクトップ版や検証時に、接続先を Fly とローカルで切り替えるための隠しスイッチです。",
            local: "ローカル",
            current: "現在",
          }
        : {
            title: "Core target (dev only)",
            description:
              "This section only appears for the development account. Use it to switch the core endpoint between Fly and local while testing desktop behavior.",
            local: "Local",
            current: "Current",
          },
    [lang],
  );

  const label = useMemo(
    () => (mode === "local" ? `${copy.local} (127.0.0.1:8000)` : "Fly (project-sigmaris.fly.dev)"),
    [copy.local, mode],
  );

  if (!allowed) return null;

  return (
    <section className="rounded-2xl border bg-card/60 p-5">
      <h2 className="font-medium">{copy.title}</h2>
      <p className="mt-1 text-sm text-muted-foreground">{copy.description}</p>

      <div className="mt-4 flex flex-wrap items-center gap-2">
        <button
          type="button"
          className={[
            "rounded-md border px-3 py-2 text-sm transition",
            mode === "fly" ? "border-ring bg-accent/70" : "border-border hover:bg-accent/40",
          ].join(" ")}
          onClick={() => {
            setMode("fly");
            writeMode("fly");
          }}
        >
          Fly
        </button>
        <button
          type="button"
          className={[
            "rounded-md border px-3 py-2 text-sm transition",
            mode === "local" ? "border-ring bg-accent/70" : "border-border hover:bg-accent/40",
          ].join(" ")}
          onClick={() => {
            setMode("local");
            writeMode("local");
          }}
        >
          {copy.local}
        </button>

        <div className="ml-2 text-xs text-muted-foreground">
          {copy.current}: <span className="font-mono text-foreground/80">{label}</span>
        </div>
      </div>
    </section>
  );
}
