"use client";

import { useLanguage } from "@/components/i18n/LanguageProvider";

export default function EntryInfoSection() {
  const { t, tList } = useLanguage();
  const flowItems = tList("entry.infoCards.flowItems");

  return (
    <section
      id="entry-info"
      data-entry-section="info"
      className="mx-auto mt-10 w-full max-w-6xl space-y-4"
    >
      <div className="space-y-1">
        <h2 className="text-xl font-semibold tracking-wide">{t("entry.infoTitle")}</h2>
      </div>
      <div className="grid grid-cols-1 gap-3 sm:grid-cols-2 lg:grid-cols-3">
        <div className="rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm">
          <div className="text-sm font-semibold">{t("entry.infoCards.flowTitle")}</div>
          <ol className="mt-3 space-y-2 text-sm text-muted-foreground">
            {flowItems.map((item) => (
              <li key={item}>{item}</li>
            ))}
          </ol>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm">
          <div className="text-sm font-semibold">{t("entry.infoCards.roleplayTitle")}</div>
          <div className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t("entry.infoCards.roleplayBody")}
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm">
          <div className="text-sm font-semibold">{t("entry.infoCards.environmentTitle")}</div>
          <div className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t("entry.infoCards.environmentBody")}
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm">
          <div className="text-sm font-semibold">{t("entry.infoCards.notesTitle")}</div>
          <div className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t("entry.infoCards.notesBody")}
          </div>
        </div>

        <div className="rounded-2xl border border-border bg-card p-5 text-card-foreground shadow-sm sm:col-span-2 lg:col-span-2">
          <div className="text-sm font-semibold">{t("entry.infoCards.versionTitle")}</div>
          <div className="mt-3 text-sm leading-relaxed text-muted-foreground">
            {t("entry.infoCards.versionBody")}
          </div>
        </div>
      </div>
    </section>
  );
}
