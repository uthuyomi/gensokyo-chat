"use client";

import Link from "next/link";

import TopShell from "@/components/top/TopShell";
import EntryTouhouBackground from "../../entry/EntryTouhouBackground";
import styles from "../../entry/entry-theme.module.css";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export const dynamic = "force-dynamic";

export default function PrivacyPage() {
  const { t, tList } = useLanguage();
  const items = tList("legal.privacy.items");

  return (
    <TopShell
      scroll
      backgroundVariant="none"
      backgroundSlot={<EntryTouhouBackground />}
      className={`${styles.entryTheme} bg-background text-foreground`}
    >
      <div className="w-full max-w-3xl">
        <div className="rounded-3xl border border-border bg-card/85 p-6 shadow-sm backdrop-blur sm:p-8">
          <h1 className="text-2xl font-semibold tracking-wide">{t("legal.privacy.title")}</h1>
          <p className="mt-4 text-sm text-muted-foreground">{t("legal.privacy.intro")}</p>

          <section className="mt-8 space-y-3 text-sm text-muted-foreground">
            {items.map((item) => (
              <p key={item}>{item}</p>
            ))}
          </section>

          <div className="mt-10">
            <Link href="/" className="text-sm font-medium text-primary hover:opacity-80">
              {t("common.back")}
            </Link>
          </div>
        </div>
      </div>
    </TopShell>
  );
}
