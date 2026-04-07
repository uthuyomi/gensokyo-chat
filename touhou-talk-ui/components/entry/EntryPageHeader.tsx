"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { LogIn, MessageSquareMore, UserRound } from "lucide-react";
import type { User } from "@supabase/supabase-js";

import { useLanguage } from "@/components/i18n/LanguageProvider";
import { supabaseBrowser } from "@/lib/supabaseClient";

export default function EntryPageHeader() {
  const { lang } = useLanguage();
  const [user, setUser] = useState<User | null>(null);
  const [checked, setChecked] = useState(false);

  useEffect(() => {
    const syncUser = async () => {
      const { data } = await supabaseBrowser().auth.getUser();
      setUser(data.user ?? null);
      setChecked(true);
    };

    void syncUser();

    const { data: listener } = supabaseBrowser().auth.onAuthStateChange(() => {
      void syncUser();
    });

    return () => {
      listener.subscription.unsubscribe();
    };
  }, []);

  const copy = useMemo(() => ({
    title: lang === "ja" ? "Gensokyo Chat" : "Gensokyo Chat",
    account: lang === "ja" ? "アカウント情報" : "Account",
    chat: lang === "ja" ? "チャットへ" : "Go to chat",
    login: lang === "ja" ? "ログイン" : "Sign in",
    guest: lang === "ja" ? "未ログイン" : "Not signed in",
  }), [lang]);

  return (
    <header className="mb-6 rounded-3xl border border-border/70 bg-background/72 px-4 py-3 shadow-lg shadow-black/10 backdrop-blur md:px-5">
      <div className="flex flex-col gap-3 md:flex-row md:items-center md:justify-between">
        <div className="min-w-0">
          <div className="font-gensou text-xl tracking-wide text-foreground md:text-2xl">
            {copy.title}
          </div>
        </div>

        <div className="flex min-w-0 items-center justify-between gap-3 rounded-2xl border border-border/60 bg-card/75 px-3 py-2 md:min-w-[22rem] md:justify-end">
          <div className="min-w-0">
            <div className="text-[11px] font-medium text-muted-foreground">{copy.account}</div>
            <div className="mt-0.5 flex items-center gap-2 text-sm text-foreground">
              <UserRound className="size-4 shrink-0 text-muted-foreground" />
              <span className="truncate">{checked ? (user?.email ?? copy.guest) : "..."}</span>
            </div>
          </div>

          {user ? (
            <Link
              href="/chat/session"
              aria-label={copy.chat}
              title={copy.chat}
              className="inline-flex shrink-0 items-center gap-2 rounded-2xl border border-border bg-card px-3 py-2 text-sm font-medium text-foreground transition hover:bg-accent hover:text-accent-foreground"
            >
              <MessageSquareMore className="size-4" />
              <span>{copy.chat}</span>
            </Link>
          ) : (
            <Link
              href="/auth/login?next=%2Fchat%2Fsession"
              className="inline-flex shrink-0 items-center gap-2 rounded-2xl border border-border bg-card px-3 py-2 text-sm font-medium text-foreground transition hover:bg-accent hover:text-accent-foreground"
            >
              <LogIn className="size-4" />
              <span>{copy.login}</span>
            </Link>
          )}
        </div>
      </div>
    </header>
  );
}
