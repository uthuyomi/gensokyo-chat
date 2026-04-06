"use client";

import Link from "next/link";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export const dynamic = "force-dynamic";

export default function TermsPage() {
  const { t, tList } = useLanguage();
  const items = tList("legal.terms.items");

  return (
    <main className="min-h-dvh bg-black px-6 py-10 text-white">
      <div className="mx-auto max-w-3xl">
        <h1 className="text-2xl font-bold">{t("legal.terms.title")}</h1>
        <p className="mt-4 text-sm text-white/80">{t("legal.terms.intro")}</p>

        <section className="mt-8 space-y-3 text-sm text-white/80">
          {items.map((item) => (
            <p key={item}>{item}</p>
          ))}
        </section>

        <div className="mt-10">
          <Link href="/" className="text-sm text-white/70 hover:text-white">
            {t("common.back")}
          </Link>
        </div>
      </div>
    </main>
  );
}
