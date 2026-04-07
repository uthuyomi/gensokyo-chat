"use client";

import PwaInstallButton from "@/components/pwa/PwaInstallButton";
import { useLanguage } from "@/components/i18n/LanguageProvider";

export default function EntryInstallSection() {
  const { t } = useLanguage();

  return (
    <section
      id="entry-install"
      data-entry-section="install"
      className="mx-auto mt-10 flex w-full max-w-6xl flex-col items-center space-y-3 text-center"
    >
      <h2 className="text-xl font-semibold tracking-wide">{t("entry.footer.installTitle")}</h2>
      <p className="max-w-3xl text-sm text-muted-foreground">{t("entry.footer.installBody")}</p>

      <div className="flex w-full justify-center">
        <PwaInstallButton />
      </div>
    </section>
  );
}
