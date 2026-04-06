"use client";

import React from "react";
import type { User } from "@supabase/supabase-js";

import { supabaseBrowser } from "@/lib/supabaseClient";
import {
  LANGUAGE_COOKIE,
  LANGUAGE_STORAGE_KEY,
  t as translate,
  tList,
} from "@/lib/i18n";
import { DEFAULT_LANGUAGE, resolveLanguage, type AppLanguage } from "@/lib/i18n/types";

function persistLanguage(lang: AppLanguage) {
  try {
    window.localStorage.setItem(LANGUAGE_STORAGE_KEY, lang);
  } catch {}

  try {
    document.cookie = `${LANGUAGE_COOKIE}=${encodeURIComponent(lang)}; Path=/; Max-Age=31536000; SameSite=Lax`;
  } catch {}

  try {
    document.documentElement.lang = lang;
  } catch {}
}

type LanguageContextValue = {
  lang: AppLanguage;
  setLanguage: (lang: AppLanguage) => Promise<void>;
  t: (path: string, fallback?: string) => string;
  tList: (path: string) => string[];
};

const LanguageContext = React.createContext<LanguageContextValue | null>(null);

export function LanguageProvider({
  children,
  initialLanguage,
}: {
  children: React.ReactNode;
  initialLanguage: AppLanguage;
}) {
  const [lang, setLang] = React.useState<AppLanguage>(initialLanguage);
  const userRef = React.useRef<User | null>(null);

  React.useEffect(() => {
    persistLanguage(lang);
  }, [lang]);

  const applyUserLanguage = React.useCallback((user: User | null) => {
    userRef.current = user;
    const preferred = resolveLanguage((user?.user_metadata as Record<string, unknown> | undefined)?.preferred_language);
    const hasPreferred = !!(user?.user_metadata && typeof (user.user_metadata as any).preferred_language === "string");

    if (hasPreferred) {
      setLang(preferred);
      persistLanguage(preferred);
      return;
    }

    try {
      const local = resolveLanguage(window.localStorage.getItem(LANGUAGE_STORAGE_KEY));
      setLang(local);
      persistLanguage(local);
    } catch {
      setLang(DEFAULT_LANGUAGE);
      persistLanguage(DEFAULT_LANGUAGE);
    }
  }, []);

  React.useEffect(() => {
    let active = true;

    void (async () => {
      try {
        const { data } = await supabaseBrowser().auth.getUser();
        if (!active) return;
        applyUserLanguage(data.user ?? null);
      } catch {
        if (!active) return;
        try {
          const local = resolveLanguage(window.localStorage.getItem(LANGUAGE_STORAGE_KEY));
          setLang(local);
          persistLanguage(local);
        } catch {
          setLang(initialLanguage);
          persistLanguage(initialLanguage);
        }
      } finally {
      }
    })();

    const { data: listener } = supabaseBrowser().auth.onAuthStateChange((_event, session) => {
      applyUserLanguage(session?.user ?? null);
    });

    return () => {
      active = false;
      listener.subscription.unsubscribe();
    };
  }, [applyUserLanguage, initialLanguage]);

  const setLanguage = React.useCallback(async (next: AppLanguage) => {
    const resolved = resolveLanguage(next);
    setLang(resolved);
    persistLanguage(resolved);

    const user = userRef.current;
    if (!user) return;

    try {
      await supabaseBrowser().auth.updateUser({
        data: {
          ...(user.user_metadata ?? {}),
          preferred_language: resolved,
        },
      });
    } catch {
      // ignore profile sync errors for now
    }
  }, []);

  const value = React.useMemo<LanguageContextValue>(() => ({
    lang,
    setLanguage,
    t: (path: string, fallback?: string) => translate(path, lang, fallback),
    tList: (path: string) => tList(path, lang),
  }), [lang, setLanguage]);

  return <LanguageContext.Provider value={value}>{children}</LanguageContext.Provider>;
}

export function useLanguage() {
  const ctx = React.useContext(LanguageContext);
  if (!ctx) throw new Error("useLanguage must be used within LanguageProvider");
  return ctx;
}
