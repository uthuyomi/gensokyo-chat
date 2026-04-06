"use client";

import Link from "next/link";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export default function EntryCharactersHeader() {
  const { t } = useLanguage();

  return (
    <section className="mx-auto mt-10 w-full max-w-6xl">
      <div className="flex items-end justify-between gap-3">
        <div className="min-w-0">
          <h2 className="text-xl font-semibold tracking-wide">{t("entry.charactersTitle")}</h2>
          <p className="mt-1 text-sm text-muted-foreground">{t("entry.charactersDescription")}</p>
        </div>
      </div>
    </section>
  );
}
