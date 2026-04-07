"use client";

import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";
import type { User } from "@supabase/supabase-js";

import { supabaseBrowser } from "@/lib/supabaseClient";
import TopShell from "@/components/top/TopShell";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export default function TopPage() {
  const { t, tList } = useLanguage();
  const router = useRouter();

  const [fog, setFog] = useState(false);
  const [loading, setLoading] = useState(false);
  const [user, setUser] = useState<User | null>(null);
  const [authChecked, setAuthChecked] = useState(false);

  useEffect(() => {
    const fetchUser = async () => {
      const { data } = await supabaseBrowser().auth.getUser();
      setUser(data.user ?? null);
      setAuthChecked(true);
    };

    void fetchUser();

    const { data: listener } = supabaseBrowser().auth.onAuthStateChange(() => {
      void fetchUser();
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  const lines = useMemo(() => tList("top.lines"), [tList]);
  const fullText = useMemo(() => lines.join("\n"), [lines]);
  const [typed, setTyped] = useState("");

  useEffect(() => {
    let i = 0;
    let timer: number | null = null;

    const tick = () => {
      i += 1;
      setTyped(fullText.slice(0, i));

      if (i < fullText.length) {
        const ch = fullText[i - 1];
        const delay = ch === "。" || ch === "." ? 180 : ch === "\n" ? 260 : 45;
        timer = window.setTimeout(tick, delay);
      }
    };

    timer = window.setTimeout(tick, 250);
    return () => {
      if (timer) window.clearTimeout(timer);
    };
  }, [fullText]);

  const goLogin = () => {
    if (loading) return;
    setFog(true);
    setLoading(true);
    window.setTimeout(() => {
      router.push("/auth/login");
    }, 1200);
  };

  const enter = () => {
    if (loading) return;
    setFog(true);
    setLoading(true);
    window.setTimeout(() => {
      router.push("/chat/session");
    }, 1200);
  };

  return (
    <TopShell fog={fog} loading={loading}>
      <div className="flex flex-col items-center justify-center gap-8 text-center">
        <p className="font-gensou whitespace-pre-line text-xl leading-relaxed text-white/95 drop-shadow-[0_2px_10px_rgba(0,0,0,0.65)] drop-shadow-[0_0_22px_rgba(140,100,220,0.35)] sm:text-2xl lg:text-3xl">
          {typed}
          {typed.length < fullText.length && <span className="ml-1 inline-block animate-pulse">|</span>}
        </p>

        {authChecked && (
          <div className="flex w-full max-w-xs flex-col gap-4">
            {!user && (
              <button
                onClick={goLogin}
                className="rounded-xl bg-white/85 px-8 py-4 text-lg font-medium text-black backdrop-blur transition hover:bg-white"
              >
                {t("top.login")}
              </button>
            )}

            {user && (
              <button
                onClick={enter}
                className="rounded-xl border border-white/60 px-8 py-3 text-sm text-white backdrop-blur transition hover:bg-white/20"
              >
                {t("top.enter")}
              </button>
            )}
          </div>
        )}

        <div className="mt-8 max-w-xl text-pretty text-xs leading-relaxed text-white/70 drop-shadow-[0_2px_10px_rgba(0,0,0,0.55)]">
          <p>{t("top.description1")}</p>
          <p className="mt-2">{t("top.description2")}</p>
        </div>
      </div>
    </TopShell>
  );
}
