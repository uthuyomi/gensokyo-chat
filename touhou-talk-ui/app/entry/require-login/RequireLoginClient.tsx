"use client";

import Link from "next/link";
import { useEffect, useMemo, useState } from "react";
import { useRouter } from "next/navigation";

import TopShell from "@/components/top/TopShell";
import { supabaseBrowser } from "@/lib/supabaseClient";
import EntryTouhouBackground from "../EntryTouhouBackground";
import styles from "../entry-theme.module.css";
import { useLanguage } from "@/components/i18n/LanguageProvider";

function safeNextPath(raw: string | null | undefined): string {
  const s = String(raw ?? "").trim();
  if (!s) return "/chat/session";
  if (!s.startsWith("/")) return "/chat/session";
  if (s.startsWith("//")) return "/chat/session";
  if (s.includes("://")) return "/chat/session";
  return s.length > 2048 ? s.slice(0, 2048) : s;
}

export default function RequireLoginClient(props: { nextPath?: string | null }) {
  const { t } = useLanguage();
  const router = useRouter();
  const nextPath = useMemo(() => safeNextPath(props.nextPath), [props.nextPath]);
  const [checking, setChecking] = useState(true);

  useEffect(() => {
    let canceled = false;
    (async () => {
      try {
        const { data } = await supabaseBrowser().auth.getSession();
        if (canceled) return;
        if (data.session) {
          router.replace(nextPath);
          return;
        }
      } catch {
        // ignore
      } finally {
        if (!canceled) setChecking(false);
      }
    })();
    return () => {
      canceled = true;
    };
  }, [nextPath, router]);

  const loginHref = `/auth/login?next=${encodeURIComponent(nextPath)}`;

  return (
    <TopShell
      scroll
      backgroundVariant="none"
      backgroundSlot={<EntryTouhouBackground />}
      className={`${styles.entryTheme} bg-background text-foreground`}
    >
      <div className="w-full max-w-sm rounded-2xl border border-border bg-card p-6 text-card-foreground shadow-sm">
        <h1 className="mb-2 text-lg font-semibold tracking-wide">{t("auth.requireTitle")}</h1>
        <p className="mb-4 text-sm text-muted-foreground">{t("auth.requireDescription")}</p>

        <div className="grid gap-2">
          <Link
            href={loginHref}
            className="w-full rounded-xl bg-primary px-4 py-3 text-center text-sm font-medium text-primary-foreground hover:opacity-90"
          >
            {t("auth.goLogin")}
          </Link>
          <Link
            href="/entry"
            className="w-full rounded-xl border border-border bg-secondary px-4 py-3 text-center text-sm font-medium text-secondary-foreground hover:bg-secondary/80"
          >
            {t("common.back")}
          </Link>
        </div>

        {checking ? <div className="mt-4 text-center text-xs text-muted-foreground">{t("common.loading")}</div> : null}
      </div>
    </TopShell>
  );
}
