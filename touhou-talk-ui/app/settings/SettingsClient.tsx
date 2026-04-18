"use client";

import Link from "next/link";
import { useEffect, useMemo, useRef, useState } from "react";

import DevCoreToggle from "@/components/dev/DevCoreToggle";
import LanguageSelector from "@/components/i18n/LanguageSelector";
import { useLanguage } from "@/components/i18n/LanguageProvider";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import type { DesktopCharacterSettings, DesktopTtsMode } from "@/lib/desktop/desktopSettingsTypes";
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
import { CHARACTER_CATALOG } from "@/lib/characterCatalog";

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

function FileStatus({
  label,
  value,
  emptyLabel,
  countSuffix,
}: {
  label: string;
  value: { kind: "none" } | { kind: "file"; name: string } | { kind: "files"; names: string[] };
  emptyLabel: string;
  countSuffix: string;
}) {
  const body =
    value.kind === "none" ? (
      <span className="text-muted-foreground">{emptyLabel}</span>
    ) : value.kind === "file" ? (
      <span className="font-mono">{value.name}</span>
    ) : (
      <span className="font-mono">
        {value.names.length} {countSuffix}{" "}
        {value.names.length ? (
          <span className="text-muted-foreground">
            ({value.names.slice(0, 2).join(", ")}
            {value.names.length > 2 ? "..." : ""})
          </span>
        ) : null}
      </span>
    );

  return (
    <div className="text-xs">
      <span className="text-muted-foreground">{label}: </span>
      {body}
    </div>
  );
}

export default function SettingsClient() {
  const { lang, t } = useLanguage();
  const [skipMap, setSkipMapState] = useState(false);
  const [theme, setThemeState] = useState<TouhouTheme>("dark");
  const [chatMode, setChatMode] = useState<TouhouChatMode>("partner");

  const [selectedChar, setSelectedChar] = useState<string>(() => CHARACTER_CATALOG[0]?.id ?? "reimu");
  const [charExists, setCharExists] = useState(false);
  const [charSettings, setCharSettings] = useState<DesktopCharacterSettings | null>(null);
  const [charLoading, setCharLoading] = useState(false);
  const [charError, setCharError] = useState<string | null>(null);
  const [charInfo, setCharInfo] = useState<string | null>(null);

  const vrmInputRef = useRef<HTMLInputElement | null>(null);
  const motionsJsonRef = useRef<HTMLInputElement | null>(null);
  const motionsGlbsRef = useRef<HTMLInputElement | null>(null);

  const [pendingVrmFile, setPendingVrmFile] = useState<File | null>(null);
  const [pendingMotionsJson, setPendingMotionsJson] = useState<File | null>(null);
  const [pendingMotionGlbs, setPendingMotionGlbs] = useState<File[]>([]);

  useEffect(() => {
    setSkipMapState(getSkipMapOnStart());
    setThemeState(getTheme());
    setChatMode(getDefaultChatMode());
  }, []);

  const copy = useMemo(
    () =>
      lang === "ja"
        ? {
            sectionDesktop: {
              title: "キャラクター設定 / VRM / TTS / モーション",
              description: "Electron 版で使用するキャラクターごとの VRM・TTS・モーション設定をここで調整できます。",
              characterLabel: "キャラクター選択",
              initTitle: "このキャラクターの設定はまだ初期化されていません",
              initBody: "先に設定を初期化してから、VRM / TTS / モーションを順番に組み込んでください。",
              initAction: "設定を初期化する",
              initDone: "設定を初期化しました。続けて VRM / TTS / モーションを設定できます。",
              saved: "設定を保存しました。",
            },
            vrm: {
              title: "VRM",
              current: "現在の状態",
              choose: "VRM を選ぶ",
              uploaded: (file: string) => `VRM をアップロードした: ${file}`,
            },
            tts: {
              title: "TTS",
              current: "現在の状態",
              mode: "モード",
              useAquesTalk: "AquesTalk を有効にする",
              rootDir: "AquesTalk フォルダ",
              voice: "voice",
              speed: "speed",
              browser: "Browser Web Speech API",
            },
            motions: {
              title: "モーション",
              current: "現在の状態",
              chooseJson: "motions.json を選ぶ",
              chooseGlb: "GLB を選ぶ",
              uploadHint: "motions.json がなくても、GLB だけで既存ライブラリへ追加できる場合がある。",
              uploaded: (count: string) => `モーションをアップロードした: ${count} 件`,
            },
            common: {
              current: "現在",
              notSelected: "未選択",
              items: "件",
              latestUpdate: "更新",
              enabled: "有効",
              disabled: "無効",
              localNone: "なし",
            },
          }
        : {
            sectionDesktop: {
              title: "Character settings / VRM / TTS / motions",
              description: "Adjust per-character VRM, TTS, and motion settings for the desktop app here.",
              characterLabel: "Character",
              initTitle: "This character has not been initialized yet",
              initBody: "Initialize the settings first, then wire in VRM, TTS, and motions in that order.",
              initAction: "Initialize settings",
              initDone: "Settings initialized. You can now add VRM, TTS, and motions.",
              saved: "Settings saved.",
            },
            vrm: {
              title: "VRM",
              current: "Current state",
              choose: "Choose VRM",
              uploaded: (file: string) => `Uploaded VRM: ${file}`,
            },
            tts: {
              title: "TTS",
              current: "Current state",
              mode: "Mode",
              useAquesTalk: "Enable AquesTalk",
              rootDir: "AquesTalk folder",
              voice: "voice",
              speed: "speed",
              browser: "Browser Web Speech API",
            },
            motions: {
              title: "Motions",
              current: "Current state",
              chooseJson: "Choose motions.json",
              chooseGlb: "Choose GLB",
              uploadHint: "Even without motions.json, GLB files can sometimes be appended to the existing motion library.",
              uploaded: (count: string) => `Uploaded motions: ${count}`,
            },
            common: {
              current: "Current",
              notSelected: "None selected",
              items: "items",
              latestUpdate: "Updated",
              enabled: "Enabled",
              disabled: "Disabled",
              localNone: "None",
            },
          },
    [lang],
  );

  const updateTheme = (nextTheme: TouhouTheme) => {
    setThemeState(nextTheme);
    setTheme(nextTheme);
    applyThemeClass(nextTheme);
  };

  const title = useMemo(() => t("settings.desktopTitle"), [t]);

  const notifyDesktopUpdated = () => {
    try {
      if (typeof window !== "undefined") {
        window.dispatchEvent(
          new CustomEvent("touhou-desktop:vrm-updated", {
            detail: { characterId: selectedChar, rev: String(Date.now()) },
          }),
        );
      }
    } catch {
      // ignore
    }
  };

  const loadCharSettings = async (charId: string) => {
    setCharLoading(true);
    setCharError(null);
    setCharInfo(null);
    try {
      const res = await fetch(`/api/desktop/character-settings?char=${encodeURIComponent(charId)}`, {
        cache: "no-store",
      });
      const j = (await res.json().catch(() => null)) as
        | { ok: boolean; exists?: boolean; settings?: DesktopCharacterSettings | null; error?: string }
        | null;
      if (!res.ok || !j?.ok) throw new Error(String(j?.error ?? `HTTP ${res.status}`));
      const exists = !!j.exists;
      setCharExists(exists);
      setCharSettings(exists ? (j.settings ?? null) : null);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setCharError(msg);
      setCharExists(false);
      setCharSettings(null);
    } finally {
      setCharLoading(false);
    }
  };

  useEffect(() => {
    void loadCharSettings(selectedChar);
  }, [selectedChar]);

  useEffect(() => {
    setPendingVrmFile(null);
    setPendingMotionsJson(null);
    setPendingMotionGlbs([]);
    if (vrmInputRef.current) vrmInputRef.current.value = "";
    if (motionsJsonRef.current) motionsJsonRef.current.value = "";
    if (motionsGlbsRef.current) motionsGlbsRef.current.value = "";
  }, [selectedChar]);

  const initCharSettings = async () => {
    setCharLoading(true);
    setCharError(null);
    setCharInfo(null);
    try {
      const res = await fetch(`/api/desktop/character-settings?char=${encodeURIComponent(selectedChar)}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "init" }),
      });
      const j = (await res.json().catch(() => null)) as
        | { ok: boolean; settings?: DesktopCharacterSettings | null; error?: string }
        | null;
      if (!res.ok || !j?.ok || !j.settings) throw new Error(String(j?.error ?? `HTTP ${res.status}`));
      setCharExists(true);
      setCharSettings(j.settings);
      setCharInfo(copy.sectionDesktop.initDone);
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setCharError(msg);
    } finally {
      setCharLoading(false);
    }
  };

  const saveCharSettings = async () => {
    if (!charSettings) return;
    setCharLoading(true);
    setCharError(null);
    setCharInfo(null);
    try {
      const res = await fetch(`/api/desktop/character-settings?char=${encodeURIComponent(selectedChar)}`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ action: "save", settings: charSettings }),
      });
      const j = (await res.json().catch(() => null)) as
        | { ok: boolean; settings?: DesktopCharacterSettings | null; error?: string }
        | null;
      if (!res.ok || !j?.ok || !j.settings) throw new Error(String(j?.error ?? `HTTP ${res.status}`));
      setCharSettings(j.settings);
      setCharInfo(copy.sectionDesktop.saved);
      notifyDesktopUpdated();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setCharError(msg);
    } finally {
      setCharLoading(false);
    }
  };

  const uploadVrm = async (file: File) => {
    setCharLoading(true);
    setCharError(null);
    setCharInfo(null);
    try {
      const fd = new FormData();
      fd.set("file", file);
      const res = await fetch(`/api/desktop/character-vrm?char=${encodeURIComponent(selectedChar)}`, {
        method: "POST",
        body: fd,
      });
      const j = (await res.json().catch(() => null)) as { ok?: boolean; error?: string } | null;
      if (!res.ok || !j?.ok) throw new Error(String(j?.error ?? `HTTP ${res.status}`));
      setCharInfo(copy.vrm.uploaded(file.name));
      await loadCharSettings(selectedChar);
      notifyDesktopUpdated();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setCharError(msg);
    } finally {
      setPendingVrmFile(null);
      if (vrmInputRef.current) vrmInputRef.current.value = "";
      setCharLoading(false);
    }
  };

  const uploadMotions = async (motionsJson: File | null, glbs: File[]) => {
    setCharLoading(true);
    setCharError(null);
    setCharInfo(null);
    try {
      if (!motionsJson && glbs.length === 0) {
        throw new Error(
          lang === "ja" ? "motions.json または GLB を選択してください。" : "Choose motions.json or at least one GLB file.",
        );
      }
      const fd = new FormData();
      if (motionsJson) fd.set("motionsJson", motionsJson);
      for (const g of glbs) fd.append("glbs", g);
      const res = await fetch(`/api/desktop/character-motions-import?char=${encodeURIComponent(selectedChar)}`, {
        method: "POST",
        body: fd,
      });
      const j = (await res.json().catch(() => null)) as { ok?: boolean; error?: string; motionsCount?: number } | null;
      if (!res.ok || !j?.ok) throw new Error(String(j?.error ?? `HTTP ${res.status}`));
      setCharInfo(copy.motions.uploaded(String(j?.motionsCount ?? "?")));
      await loadCharSettings(selectedChar);
      notifyDesktopUpdated();
    } catch (e) {
      const msg = e instanceof Error ? e.message : String(e);
      setCharError(msg);
    } finally {
      setPendingMotionsJson(null);
      setPendingMotionGlbs([]);
      if (motionsJsonRef.current) motionsJsonRef.current.value = "";
      if (motionsGlbsRef.current) motionsGlbsRef.current.value = "";
      setCharLoading(false);
    }
  };

  const ttsSummary = useMemo(() => {
    if (!charSettings) return "";
    if (charSettings.tts.mode === "none") return copy.common.disabled;
    if (charSettings.tts.mode === "browser") return copy.tts.browser;
    return `AquesTalk ${charSettings.tts.aquestalk.enabled ? copy.common.enabled : copy.common.disabled} / voice=${
      charSettings.tts.aquestalk.voice || copy.common.localNone
    } / speed=${String(charSettings.tts.aquestalk.speed)}${
      charSettings.tts.aquestalk.rootDir ? ` / rootDir=${charSettings.tts.aquestalk.rootDir}` : ""
    }`;
  }, [charSettings, copy]);

  return (
    <div className="mx-auto flex w-full max-w-2xl flex-col gap-6 px-6 py-10">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="font-gensou text-2xl">{title}</h1>
          <p className="text-sm text-muted-foreground">{t("settings.subtitleDesktop")}</p>
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
                const v = e.currentTarget.checked;
                setSkipMapState(v);
                setSkipMapOnStart(v);
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
              const v = e.currentTarget.value;
              const next: TouhouChatMode = v === "roleplay" ? "roleplay" : v === "coach" ? "coach" : "partner";
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

      <Separator />

      <section className="rounded-2xl border bg-card/60 p-5">
        <h2 className="font-medium">{copy.sectionDesktop.title}</h2>
        <p className="mt-1 text-sm text-muted-foreground">{copy.sectionDesktop.description}</p>

        <div className="mt-4 grid gap-3">
          <div className="grid gap-2">
            <div className="text-sm font-medium">{copy.sectionDesktop.characterLabel}</div>
            <select className="w-full rounded-xl border bg-background/60 px-4 py-3 text-sm outline-none transition focus:border-ring" value={selectedChar} onChange={(e) => setSelectedChar(e.currentTarget.value)}>
              {CHARACTER_CATALOG.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.label} ({c.id})
                </option>
              ))}
            </select>
          </div>

          {charError ? <div className="rounded-xl border border-destructive/50 bg-destructive/10 px-4 py-3 text-sm">Error: {charError}</div> : null}

          {charInfo ? <div className="rounded-xl border border-emerald-500/40 bg-emerald-500/10 px-4 py-3 text-sm">{charInfo}</div> : null}

          {!charExists ? (
            <div className="rounded-xl border bg-background/40 px-4 py-4">
              <div className="text-sm font-medium">{copy.sectionDesktop.initTitle}</div>
              <div className="mt-1 text-xs text-muted-foreground">{copy.sectionDesktop.initBody}</div>
              <div className="mt-3">
                <Button type="button" disabled={charLoading} onClick={initCharSettings}>
                  {copy.sectionDesktop.initAction}
                </Button>
              </div>
            </div>
          ) : null}

          {charExists && charSettings ? (
            <div className="grid gap-4">
              <div className="rounded-xl border bg-background/40 px-4 py-4">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <div className="text-sm font-medium">{copy.vrm.title}</div>
                    <div className="text-xs text-muted-foreground">
                      {copy.vrm.current}:{" "}
                      {charSettings.vrm.enabled ? (
                        <>
                          {copy.common.enabled} / <span className="font-mono">{charSettings.vrm.path ?? "avatar.vrm"}</span>
                        </>
                      ) : (
                        copy.common.disabled
                      )}
                      {charSettings.updatedAt ? <span className="ml-2 opacity-70">{copy.common.latestUpdate}: {charSettings.updatedAt}</span> : null}
                    </div>
                  </div>
                  <label className="inline-flex items-center gap-2 text-sm">
                    <input type="checkbox" checked={!!charSettings.vrm.enabled} onChange={(e) => {
                      const v = e.currentTarget.checked;
                      setCharSettings({ ...charSettings, vrm: { ...charSettings.vrm, enabled: v } });
                    }} className="size-4" />
                    {copy.common.enabled}
                  </label>
                </div>

                <div className="mt-3 grid gap-2">
                  <div className="rounded-xl border bg-background/60 px-3 py-2">
                    <FileStatus label={copy.common.current} value={pendingVrmFile ? { kind: "file", name: pendingVrmFile.name } : { kind: "none" }} emptyLabel={copy.common.notSelected} countSuffix={copy.common.items} />
                  </div>

                  <div className="flex flex-wrap items-center gap-2">
                    <input ref={vrmInputRef} type="file" accept=".vrm" className="hidden" disabled={charLoading} onChange={(e) => {
                      const f = e.currentTarget.files?.[0] ?? null;
                      setPendingVrmFile(f);
                    }} />
                    <Button type="button" variant="outline" disabled={charLoading} onClick={() => vrmInputRef.current?.click()}>{copy.vrm.choose}</Button>
                    <Button type="button" variant="ghost" disabled={charLoading || !pendingVrmFile} onClick={() => {
                      setPendingVrmFile(null);
                      if (vrmInputRef.current) vrmInputRef.current.value = "";
                    }}>{t("common.clear")}</Button>
                    <Button type="button" disabled={charLoading || !pendingVrmFile} onClick={() => {
                      if (!pendingVrmFile) return;
                      void uploadVrm(pendingVrmFile);
                    }}>{t("common.upload")}</Button>
                  </div>
                </div>
              </div>

              <div className="rounded-xl border bg-background/40 px-4 py-4">
                <div className="text-sm font-medium">{copy.tts.title}</div>
                <div className="mt-1 text-xs text-muted-foreground">{copy.tts.current}: {ttsSummary}</div>

                <div className="mt-3 grid gap-3">
                  <div className="grid gap-2">
                    <div className="text-xs text-muted-foreground">{copy.tts.mode}</div>
                    <select className="w-full rounded-xl border bg-background/60 px-4 py-3 text-sm outline-none transition focus:border-ring" value={charSettings.tts.mode} onChange={(e) => {
                      const v = e.currentTarget.value as DesktopTtsMode;
                      setCharSettings({ ...charSettings, tts: { ...charSettings.tts, mode: v } });
                    }}>
                      <option value="none">{t("common.none")}</option>
                      <option value="browser">{copy.tts.browser}</option>
                      <option value="aquestalk">AquesTalk</option>
                    </select>
                  </div>

                  {charSettings.tts.mode === "aquestalk" ? (
                    <div className="grid gap-3">
                      <label className="inline-flex items-center gap-2 text-sm">
                        <input type="checkbox" checked={!!charSettings.tts.aquestalk.enabled} onChange={(e) => {
                          const v = e.currentTarget.checked;
                          setCharSettings({ ...charSettings, tts: { ...charSettings.tts, aquestalk: { ...charSettings.tts.aquestalk, enabled: v } } });
                        }} className="size-4" />
                        {copy.tts.useAquesTalk}
                      </label>

                      <label className="grid gap-1 text-sm">
                        <span className="text-xs text-muted-foreground">{copy.tts.rootDir}</span>
                        <input type="text" value={charSettings.tts.aquestalk.rootDir ?? ""} placeholder={lang === "ja" ? "例: D:\\aquestalk" : "Example: D:\\aquestalk"} onChange={(e) => {
                          const v = e.currentTarget.value.trim();
                          setCharSettings({ ...charSettings, tts: { ...charSettings.tts, aquestalk: { ...charSettings.tts.aquestalk, rootDir: v ? v : null } } });
                        }} className="w-full rounded-xl border bg-background/60 px-4 py-3 text-sm outline-none transition focus:border-ring" />
                      </label>

                      <div className="grid gap-2 sm:grid-cols-2">
                        <label className="grid gap-1 text-sm">
                          <span className="text-xs text-muted-foreground">{copy.tts.voice}</span>
                          <input type="text" value={charSettings.tts.aquestalk.voice ?? ""} placeholder={lang === "ja" ? "例: f1" : "Example: f1"} onChange={(e) => {
                            const v = e.currentTarget.value;
                            setCharSettings({ ...charSettings, tts: { ...charSettings.tts, aquestalk: { ...charSettings.tts.aquestalk, voice: v } } });
                          }} className="w-full rounded-xl border bg-background/60 px-4 py-3 text-sm outline-none transition focus:border-ring" />
                        </label>

                        <label className="grid gap-1 text-sm">
                          <span className="text-xs text-muted-foreground">{copy.tts.speed}</span>
                          <input type="number" min={50} max={300} step={1} value={Number.isFinite(charSettings.tts.aquestalk.speed) ? charSettings.tts.aquestalk.speed : 100} onChange={(e) => {
                            const n = Number(e.currentTarget.value);
                            setCharSettings({ ...charSettings, tts: { ...charSettings.tts, aquestalk: { ...charSettings.tts.aquestalk, speed: Number.isFinite(n) ? n : 100 } } });
                          }} className="w-full rounded-xl border bg-background/60 px-4 py-3 text-sm outline-none transition focus:border-ring" />
                        </label>
                      </div>
                    </div>
                  ) : null}
                </div>
              </div>

              <div className="rounded-xl border bg-background/40 px-4 py-4">
                <div className="flex items-start justify-between gap-4">
                  <div>
                    <div className="text-sm font-medium">{copy.motions.title}</div>
                    <div className="text-xs text-muted-foreground">
                      {copy.motions.current}:{" "}
                      {charSettings.motions.enabled ? (
                        <>
                          {copy.common.enabled} / <span className="font-mono">{charSettings.motions.indexPath ?? "motion-library/motions.json"}</span>
                        </>
                      ) : (
                        copy.common.disabled
                      )}
                    </div>
                  </div>
                  <label className="inline-flex items-center gap-2 text-sm">
                    <input type="checkbox" checked={!!charSettings.motions.enabled} onChange={(e) => {
                      const v = e.currentTarget.checked;
                      setCharSettings({ ...charSettings, motions: { ...charSettings.motions, enabled: v } });
                    }} className="size-4" />
                    {copy.common.enabled}
                  </label>
                </div>

                <div className="mt-3 grid gap-3">
                  <div className="rounded-xl border bg-background/60 px-3 py-2">
                    <FileStatus label="motions.json" value={pendingMotionsJson ? { kind: "file", name: pendingMotionsJson.name } : { kind: "none" }} emptyLabel={copy.common.notSelected} countSuffix={copy.common.items} />
                    <FileStatus label="GLB" value={pendingMotionGlbs.length ? { kind: "files", names: pendingMotionGlbs.map((f) => f.name) } : { kind: "none" }} emptyLabel={copy.common.notSelected} countSuffix={copy.common.items} />
                  </div>

                  <div className="grid gap-2">
                    <div className="flex flex-wrap items-center gap-2">
                      <input ref={motionsJsonRef} type="file" accept="application/json,.json" className="hidden" disabled={charLoading} onChange={(e) => {
                        const f = e.currentTarget.files?.[0] ?? null;
                        setPendingMotionsJson(f);
                      }} />
                      <Button type="button" variant="outline" disabled={charLoading} onClick={() => motionsJsonRef.current?.click()}>{copy.motions.chooseJson}</Button>
                      <Button type="button" variant="ghost" disabled={charLoading || !pendingMotionsJson} onClick={() => {
                        setPendingMotionsJson(null);
                        if (motionsJsonRef.current) motionsJsonRef.current.value = "";
                      }}>{t("common.clear")}</Button>
                    </div>

                    <div className="flex flex-wrap items-center gap-2">
                      <input ref={motionsGlbsRef} type="file" accept=".glb,model/gltf-binary" className="hidden" multiple disabled={charLoading} onChange={(e) => {
                        const files = Array.from(e.currentTarget.files ?? []);
                        setPendingMotionGlbs(files);
                      }} />
                      <Button type="button" variant="outline" disabled={charLoading} onClick={() => motionsGlbsRef.current?.click()}>{copy.motions.chooseGlb}</Button>
                      <Button type="button" variant="ghost" disabled={charLoading || pendingMotionGlbs.length === 0} onClick={() => {
                        setPendingMotionGlbs([]);
                        if (motionsGlbsRef.current) motionsGlbsRef.current.value = "";
                      }}>{t("common.clear")}</Button>
                    </div>
                  </div>

                  <div className="flex flex-wrap items-center justify-between gap-2">
                    <div className="text-xs text-muted-foreground">{copy.motions.uploadHint}</div>
                    <Button type="button" disabled={charLoading || (!pendingMotionsJson && pendingMotionGlbs.length === 0)} onClick={() => void uploadMotions(pendingMotionsJson, pendingMotionGlbs)}>{t("common.upload")}</Button>
                  </div>
                </div>
              </div>

              <div className="flex flex-wrap items-center justify-end gap-2">
                <Button type="button" variant="outline" disabled={charLoading} onClick={() => void loadCharSettings(selectedChar)}>{t("common.refresh")}</Button>
                <Button type="button" disabled={charLoading} onClick={saveCharSettings}>{t("common.save")}</Button>
              </div>
            </div>
          ) : null}
        </div>
      </section>
    </div>
  );
}
