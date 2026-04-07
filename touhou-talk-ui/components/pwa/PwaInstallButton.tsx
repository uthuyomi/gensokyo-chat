"use client";

import { useEffect, useMemo, useState } from "react";
import { FaAndroid, FaApple, FaWindows } from "react-icons/fa6";

import { useLanguage } from "@/components/i18n/LanguageProvider";

type BeforeInstallPromptEvent = Event & {
  prompt: () => Promise<void>;
  userChoice: Promise<{ outcome: "accepted" | "dismissed"; platform: string }>;
};

function isIOS() {
  if (typeof window === "undefined") return false;
  const ua = window.navigator.userAgent;
  const iPhone = /iPhone/.test(ua);
  const iPad = /iPad/.test(ua) || (/(Macintosh)/.test(ua) && "ontouchend" in document);
  return iPhone || iPad;
}

function isAndroid() {
  if (typeof window === "undefined") return false;
  return /Android/i.test(window.navigator.userAgent);
}

function isWindows() {
  if (typeof window === "undefined") return false;
  return /Windows/i.test(window.navigator.userAgent);
}

function isMac() {
  if (typeof window === "undefined") return false;
  const ua = window.navigator.userAgent;
  const isMacLike = /Macintosh/i.test(ua);
  const isTouch = "ontouchend" in document;
  return isMacLike && !isTouch;
}

function isStandalone() {
  if (typeof window === "undefined") return false;
  const nav = window.navigator as Navigator & { standalone?: boolean };
  if (typeof nav.standalone === "boolean") return nav.standalone;
  return window.matchMedia?.("(display-mode: standalone)")?.matches ?? false;
}

function OsButton(props: {
  icon: React.ReactNode;
  label: string;
  description: string;
  disabled?: boolean;
  active?: boolean;
  activeLabel: string;
  onClick?: () => void;
}) {
  const { icon, label, description, disabled, active, activeLabel, onClick } = props;
  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={
        "flex w-full items-start gap-3 rounded-2xl border bg-card p-5 text-left shadow-sm transition-colors " +
        (disabled
          ? "cursor-not-allowed border-border opacity-60"
          : active
            ? "border-primary/35 bg-accent hover:bg-accent/80"
            : "border-border hover:border-primary/35 hover:bg-card/90")
      }
    >
      <div className="grid h-10 w-10 place-items-center rounded-xl border border-border bg-secondary text-xl text-foreground/80">
        {icon}
      </div>
      <div className="min-w-0">
        <div className="flex items-center gap-2">
          <div className="text-base font-semibold text-card-foreground">{label}</div>
          {active ? (
            <span className="inline-flex items-center rounded-full border border-primary/30 bg-primary/10 px-2 py-0.5 text-[11px] font-medium text-primary">
              {activeLabel}
            </span>
          ) : null}
        </div>
        <div className="mt-1 text-xs leading-relaxed text-muted-foreground">{description}</div>
      </div>
    </button>
  );
}

export default function PwaInstallButton() {
  const { lang } = useLanguage();
  const [mounted, setMounted] = useState(false);
  const [deferred, setDeferred] = useState<BeforeInstallPromptEvent | null>(null);
  const [installed, setInstalled] = useState(false);
  const [showIosHelp, setShowIosHelp] = useState(false);
  const [os, setOs] = useState({ ios: false, android: false, windows: false, mac: false });

  const copy = useMemo(() => ({
    active: lang === "ja" ? "おすすめ" : "Recommended",
    installedTitle: lang === "ja" ? "この端末ではすでに追加済みです" : "Already added on this device",
    installedBody: lang === "ja" ? "ホーム画面やアプリ一覧からすぐに起動できます。" : "You can launch it quickly from your home screen or app list.",
    title: lang === "ja" ? "ホームに追加して、いつでも幻想郷へ" : "Add it to your home screen and open it anytime",
    body: lang === "ja" ? "ショートカットを追加すると、すばやくチャットを開けます。" : "Add a shortcut to open chat faster next time.",
    browserInstallAvailable: lang === "ja" ? "ブラウザの案内に従って追加できます。" : "You can add it by following the browser prompt.",
    browserInstallUnavailable: lang === "ja" ? "このブラウザではまだ案内を表示できません。メニューから追加をお試しください。" : "This browser cannot show the install prompt yet. Try adding it from the browser menu.",
    iosHelp: lang === "ja" ? "共有メニューから「ホーム画面に追加」を選ぶと追加できます。" : "Use the Share menu and choose Add to Home Screen.",
    iosHelpTitle: lang === "ja" ? "iPhone / iPad での手順" : "iPhone / iPad steps",
    iosStep1: lang === "ja" ? "Safariでこのページを開きます" : "Open this page in Safari",
    iosStep2: lang === "ja" ? "共有ボタンを押します" : "Tap the Share button",
    iosStep3: lang === "ja" ? "「ホーム画面に追加」を選びます" : "Choose Add to Home Screen",
    android: lang === "ja" ? "Android" : "Android",
    ios: lang === "ja" ? "iPhone / iPad" : "iPhone / iPad",
    windows: lang === "ja" ? "Windows" : "Windows",
    mac: lang === "ja" ? "macOS" : "macOS",
    windowsHint: lang === "ja" ? "Windowsでもブラウザ版をそのままアプリのように追加できます。" : "On Windows, you can add the browser version as an app too.",
    macHint: lang === "ja" ? "macOSでもブラウザ版をそのまま追加できます。" : "On macOS, you can add the browser version as an app too.",
    contextAndroid: lang === "ja" ? "Android: Chrome / Edge 推奨です" : "Android: Chrome / Edge recommended",
    contextWindows: lang === "ja" ? "Windows: Chrome / Edge 推奨です" : "Windows: Chrome / Edge recommended",
    contextMac: lang === "ja" ? "macOSでは Chrome 推奨です。Safariは条件によって表示されないことがあります。" : "macOS: Chrome recommended. Safari may not expose the prompt in some cases.",
    contextDefault: lang === "ja" ? "環境によってはインストール案内が表示されない場合があります。" : "Depending on your environment, the install prompt may not appear.",
  }), [lang]);

  const { ios, android, windows, mac } = os;

  useEffect(() => {
    setMounted(true);
    setOs({ ios: isIOS(), android: isAndroid(), windows: isWindows(), mac: isMac() });
    setInstalled(isStandalone());
  }, []);

  useEffect(() => {
    const onBeforeInstall = (e: Event) => {
      e.preventDefault();
      setDeferred(e as BeforeInstallPromptEvent);
    };
    window.addEventListener("beforeinstallprompt", onBeforeInstall);
    return () => window.removeEventListener("beforeinstallprompt", onBeforeInstall);
  }, []);

  const handlePrompt = deferred
    ? async () => {
        const ev = deferred;
        setDeferred(null);
        await ev.prompt();
        try {
          await ev.userChoice;
        } finally {
          setInstalled(isStandalone());
        }
      }
    : undefined;

  if (installed) {
    return (
      <div className="rounded-3xl border border-border bg-card p-6 text-card-foreground shadow-sm">
        <div className="text-base font-semibold">{copy.installedTitle}</div>
        <div className="mt-2 text-sm leading-relaxed text-muted-foreground">{copy.installedBody}</div>
      </div>
    );
  }

  return (
    <div className="relative overflow-hidden rounded-3xl border border-border bg-card p-6 text-card-foreground shadow-sm">
      <div className="pointer-events-none absolute inset-0 opacity-80 [background:radial-gradient(900px_560px_at_30%_10%,color-mix(in_oklab,var(--primary)_18%,transparent),transparent_60%),radial-gradient(900px_560px_at_80%_80%,oklch(1_0_0_/_0.14),transparent_62%)]" />

      <div className="relative">
        <div className="text-base font-semibold">{copy.title}</div>
        <div className="mt-2 text-sm leading-relaxed text-muted-foreground">{copy.body}</div>

        <div className="mt-5 grid grid-cols-1 gap-3 sm:grid-cols-2">
          <OsButton
            icon={<FaAndroid />}
            label={copy.android}
            description={deferred ? copy.browserInstallAvailable : copy.browserInstallUnavailable}
            disabled={!deferred}
            active={mounted && android}
            activeLabel={copy.active}
            onClick={handlePrompt}
          />

          <OsButton
            icon={<FaApple />}
            label={copy.ios}
            description={copy.iosHelp}
            disabled={!mounted || !ios}
            active={mounted && ios}
            activeLabel={copy.active}
            onClick={() => setShowIosHelp((v) => !v)}
          />

          <OsButton
            icon={<FaWindows />}
            label={copy.windows}
            description={deferred ? copy.windowsHint : copy.browserInstallUnavailable}
            disabled={!deferred}
            active={mounted && windows}
            activeLabel={copy.active}
            onClick={handlePrompt}
          />

          <OsButton
            icon={<FaApple />}
            label={copy.mac}
            description={deferred ? copy.macHint : copy.browserInstallUnavailable}
            disabled={!deferred}
            active={mounted && mac}
            activeLabel={copy.active}
            onClick={handlePrompt}
          />
        </div>

        {mounted && ios && showIosHelp ? (
          <div className="mt-4 rounded-2xl border border-border bg-secondary/60 p-4 text-sm text-muted-foreground">
            <div className="font-semibold text-card-foreground">{copy.iosHelpTitle}</div>
            <ol className="mt-2 list-decimal space-y-1 pl-5">
              <li>{copy.iosStep1}</li>
              <li>{copy.iosStep2}</li>
              <li>{copy.iosStep3}</li>
            </ol>
          </div>
        ) : null}

        <div className="mt-4 text-xs text-muted-foreground">
          {android
            ? copy.contextAndroid
            : windows
              ? copy.contextWindows
              : mac
                ? copy.contextMac
                : copy.contextDefault}
        </div>
      </div>
    </div>
  );
}
