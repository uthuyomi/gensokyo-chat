"use client";

import Link from "next/link";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export default function EntryFooter() {
  const { t } = useLanguage();

  return (
    <footer className="mx-auto mt-14 w-full max-w-6xl border-t border-border py-10 text-muted-foreground">
      <div className="grid grid-cols-1 gap-8 sm:grid-cols-2">
        <div>
          <div className="text-sm font-semibold text-foreground">{t("entry.footer.installTitle")}</div>
          <div className="mt-3 text-sm leading-relaxed">{t("entry.footer.installBody")}</div>
        </div>

        <div>
          <div className="text-sm font-semibold text-foreground">{t("entry.footer.contactTitle")}</div>
          <div className="mt-3 text-sm leading-relaxed">{t("entry.footer.contactBody")}</div>
          <div className="mt-4 flex flex-wrap gap-2">
            <a
              href="https://github.com/uthuyomi/sigmaris-project/issues"
              target="_blank"
              rel="noreferrer"
              className="rounded-xl border border-border bg-secondary px-4 py-3 text-sm text-secondary-foreground hover:bg-secondary/80"
            >
              GitHub Issues
            </a>
            <a
              href="https://x.com/Oyasu1999"
              target="_blank"
              rel="noreferrer"
              className="rounded-xl border border-border bg-secondary px-4 py-3 text-sm text-secondary-foreground hover:bg-secondary/80"
            >
              X
            </a>
            <Link
              href="/legal/terms"
              className="rounded-xl border border-border bg-secondary px-4 py-3 text-sm text-secondary-foreground hover:bg-secondary/80"
            >
              {t("entry.footer.terms")}
            </Link>
          </div>
        </div>
      </div>

      <div className="mt-10 flex flex-col gap-2 border-t border-border pt-6 text-xs text-muted-foreground sm:flex-row sm:items-center sm:justify-between">
        <div>Copyright © {new Date().getFullYear()} Touhou Talk</div>
        <div className="flex flex-wrap gap-x-4 gap-y-2">
          <Link href="/legal/privacy" className="hover:text-foreground/80">
            {t("entry.footer.privacy")}
          </Link>
          <Link href="/legal/terms" className="hover:text-foreground/80">
            {t("entry.footer.terms")}
          </Link>
        </div>
      </div>
    </footer>
  );
}
