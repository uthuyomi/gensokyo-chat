"use client";

import Link from "next/link";
import { useMemo, useState } from "react";

import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import DevCoreToggle from "@/components/dev/DevCoreToggle";
import LanguageSelector from "@/components/i18n/LanguageSelector";
import { useLanguage } from "@/components/i18n/LanguageProvider";
import {
  applyThemeClass,
  getDefaultChatMode,
  getSkipMapOnStart,
  getTheme,
  setDefaultChatMode,
  setSkipMapOnStart,
  setTheme,
  type TouhouChatMode,
  type TouhouTheme,
} from "@/lib/touhou-settings";

function ThemeButton({
  label,
  active,
  selectedLabel,
  onClick,
}: {
  label: string;
  active: boolean;
  selectedLabel: string;
  onClick: () => void;
}) {
  return (
    <button
      type="button"
      onClick={onClick}
      className={[
        "rounded-xl border px-4 py-3 text-left transition",
        active ? "border-ring bg-accent/70" : "border-border hover:bg-accent/40",
      ].join(" ")}
    >
      <div className="text-sm font-medium">{label}</div>
      <div className="text-xs text-muted-foreground">{active ? selectedLabel : " "}</div>
    </button>
  );
}

export default function SettingsWebClient() {
  const { t } = useLanguage();
  const [skipMap, setSkipMapState] = useState(() => getSkipMapOnStart());
  const [theme, setThemeState] = useState<TouhouTheme>(() => getTheme());
  const [chatMode, setChatMode] = useState<TouhouChatMode>(() => getDefaultChatMode());

  const updateTheme = (next: TouhouTheme) => {
    setThemeState(next);
    setTheme(next);
    applyThemeClass(next);
  };

  const title = useMemo(() => t("settings.webTitle"), [t]);

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-6 px-6 py-10">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="font-gensou text-2xl">{title}</h1>
          <p className="text-sm text-muted-foreground">{t("settings.subtitleWeb")}</p>
        </div>
        <div className="flex gap-2">
          <Button asChild variant="outline">
            <Link href="/chat/session">{t("common.chat")}</Link>
          </Button>
          <Button asChild variant="outline">
            <Link href="/settings/relationship">{t("common.relationship")}</Link>
          </Button>
        </div>
      </div>

      <Separator />

      <DevCoreToggle />

      <section className="rounded-2xl border bg-card/60 p-5">
        <h2 className="font-medium">{t("settings.sections.language.title")}</h2>
        <p className="mt-1 text-sm text-muted-foreground">{t("settings.sections.language.description")}</p>
        <LanguageSelector />
      </section>

      <section className="rounded-2xl border bg-card/60 p-5">
        <h2 className="font-medium">{t("settings.sections.map.title")}</h2>
        <p className="mt-1 text-sm text-muted-foreground">{t("settings.sections.map.description")}</p>

        <div className="mt-4 flex items-center justify-between gap-4">
          <div>
            <div className="text-sm font-medium">{t("settings.sections.map.label")}</div>
            <div className="text-xs text-muted-foreground">{t("settings.sections.map.hint")}</div>
          </div>

          <label className="inline-flex cursor-pointer items-center gap-2 text-sm">
            <input
              type="checkbox"
              checked={skipMap}
              onChange={(e) => {
                const value = e.currentTarget.checked;
                setSkipMapState(value);
                setSkipMapOnStart(value);
              }}
              className="size-4"
            />
            {skipMap ? t("common.on") : t("common.off")}
          </label>
        </div>
      </section>

      <section className="rounded-2xl border bg-card/60 p-5">
        <h2 className="font-medium">{t("settings.sections.theme.title")}</h2>
        <p className="mt-1 text-sm text-muted-foreground">{t("settings.sections.theme.description")}</p>

        <div className="mt-4 grid grid-cols-2 gap-3 sm:grid-cols-4">
          <ThemeButton label="Light" active={theme === "light"} selectedLabel={t("common.selected")} onClick={() => updateTheme("light")} />
          <ThemeButton label="Dark" active={theme === "dark"} selectedLabel={t("common.selected")} onClick={() => updateTheme("dark")} />
          <ThemeButton label="Sigmaris" active={theme === "sigmaris"} selectedLabel={t("common.selected")} onClick={() => updateTheme("sigmaris")} />
          <ThemeButton label="Soft" active={theme === "soft"} selectedLabel={t("common.selected")} onClick={() => updateTheme("soft")} />
        </div>
      </section>

      <section className="rounded-2xl border bg-card/60 p-5">
        <h2 className="font-medium">{t("settings.sections.chatMode.title")}</h2>
        <p className="mt-1 text-sm text-muted-foreground">{t("settings.sections.chatMode.description")}</p>

        <div className="mt-4">
          <select
            className="w-full rounded-xl border bg-background/60 px-4 py-3 text-sm outline-none transition focus:border-ring"
            value={chatMode}
            onChange={(e) => {
              const value = e.currentTarget.value;
              const next: TouhouChatMode = value === "roleplay" ? "roleplay" : value === "coach" ? "coach" : "partner";
              setChatMode(next);
              setDefaultChatMode(next);
            }}
          >
            <option value="partner">{t("settings.sections.chatMode.partner")}</option>
            <option value="roleplay">{t("settings.sections.chatMode.roleplay")}</option>
            <option value="coach">{t("settings.sections.chatMode.coach")}</option>
          </select>
        </div>
      </section>
    </div>
  );
}
