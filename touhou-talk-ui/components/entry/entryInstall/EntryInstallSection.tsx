"use client";

import Link from "next/link";

import PwaInstallButton from "@/components/pwa/PwaInstallButton";
import { Button } from "@/components/ui/button";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export default function EntryInstallSection() {
  const { t } = useLanguage();

  return (
    <section
      id="entry-install"
      data-entry-section="install"
      className="mx-auto mt-10 w-full max-w-6xl space-y-3"
    >
      <h2 className="text-xl font-semibold tracking-wide">{t("entry.footer.installTitle")}</h2>
      <p className="text-sm text-muted-foreground">{t("entry.footer.installBody")}</p>

      <div className="flex flex-wrap items-center gap-2">
        <PwaInstallButton />
        <Button asChild variant="secondary">
          <Link href="/chat/session">{t("common.chat")}</Link>
        </Button>
      </div>
    </section>
  );
}
