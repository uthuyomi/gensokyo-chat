"use client";

import { useLanguage } from "@/components/i18n/LanguageProvider";
import type { AppLanguage } from "@/lib/i18n/types";

export default function LanguageSelector() {
  const { lang, setLanguage, t } = useLanguage();

  return (
    <div className="mt-4 grid grid-cols-2 gap-3 sm:max-w-sm">
      {([
        ["ja", t("common.japanese")],
        ["en", t("common.english")],
      ] as Array<[AppLanguage, string]>).map(([value, label]) => (
        <button
          key={value}
          type="button"
          onClick={() => void setLanguage(value)}
          className={[
            "rounded-xl border px-4 py-3 text-left transition",
            lang === value ? "border-ring bg-accent/70" : "border-border hover:bg-accent/40",
          ].join(" ")}
        >
          <div className="text-sm font-medium">{label}</div>
          <div className="text-xs text-muted-foreground">{lang === value ? t("common.selected") : " "}</div>
        </button>
      ))}
    </div>
  );
}
