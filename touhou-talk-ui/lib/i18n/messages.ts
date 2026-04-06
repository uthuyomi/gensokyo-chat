import type { AppLanguage } from "@/lib/i18n/types";

type MessageTree = { [key: string]: string | string[] | MessageTree };

export const messages: Record<AppLanguage, MessageTree> = {
  ja: {
    common: {
      appName: "Touhou Talk",
      back: "戻る",
      chat: "チャットへ",
      save: "保存",
      loading: "読み込み中…",
      selected: "選択中",
      on: "ON",
      off: "OFF",
      language: "言語",
      japanese: "日本語",
      english: "English",
      relationship: "関係性設定",
      export: "エクスポート",
      import: "インポート",
      reset: "リセット",
      refresh: "再読み込み",
      clear: "クリア",
      upload: "アップロード",
      enabled: "有効",
      disabled: "無効",
      none: "なし",
      you: "あなた",
    },
    settings: {
      webTitle: "Web 設定",
      desktopTitle: "デスクトップ設定",
      subtitleWeb: "Web 版で使用する表示設定、言語、会話モードを調整できます。",
      subtitleDesktop: "デスクトップ版で使用する表示設定、言語、会話モードを調整できます。",
      sections: {
        language: {
          title: "表示言語",
          description: "UI の表示言語を切り替えます。ログイン済みの場合はプロフィールにも保存されます。",
        },
        map: {
          title: "起動設定",
          description: "起動時にマップ画面を表示するかどうかを設定できます。",
          label: "マップをスキップ",
          hint: "有効にすると、ログイン後にマップ画面を経由せずチャット画面へ移動します。",
        },
        theme: {
          title: "テーマ",
          description: "表示テーマを選択できます。",
        },
        chatMode: {
          title: "会話モード",
          description: "既定の会話スタイルを選択できます。",
          partner: "パートナー",
          roleplay: "ロールプレイ",
          coach: "コーチ",
        },
      },
    },
    top: {
      lines: ["ようこそ、幻想郷の対話端末へ。", "好きな相手を選んで、会話を始めてください。"],
      login: "ログイン",
      enter: "チャットを始める",
      description1:
        "このサイトは Touhou Project に着想を得た非公式のキャラクターチャット UI です。幻想郷の空気を残したまま、自然な対話を試せます。",
      description2:
        "二次創作としての表現を含みます。キャラクターや世界観の解釈には揺れがある場合があります。",
    },
    auth: {
      loginTitle: "ログイン",
      loginDescription: "Supabase Auth の OAuth を使用してログインします。",
      loginRedirectHint: "ログイン後は、選択していたページへ戻ります。",
      continueWith: {
        google: "Google でログイン",
        github: "GitHub でログイン",
        discord: "Discord でログイン",
      },
      redirecting: "リダイレクト中…",
      requireTitle: "ログインが必要です",
      requireDescription: "このキャラクターチャットを始めるにはログインが必要です。",
      goLogin: "ログインする",
    },
    entry: {
      heroTitle: "東方キャラクターと自然に会話できます。",
      heroDescription: "キャラクターを選ぶと、ログイン後すぐに会話を始められます。",
      talkWith: "と話す",
      comingSoon: "準備中",
      charactersTitle: "キャラクター一覧",
      charactersDescription: "ロケーションごとにキャラクターを表示しています。気になる相手を選んでください。",
      infoTitle: "はじめに",
      infoCards: {
        flowTitle: "使い方",
        flowItems: ["1. キャラクターを選びます", "2. ログインします", "3. 会話を始めます"],
        roleplayTitle: "ロールプレイ方針",
        roleplayBody:
          "実用的な返答と、キャラクターらしい雰囲気の両立を目指しています。場面によって温度感が変わることがあります。",
        environmentTitle: "推奨環境",
        environmentBody:
          "PC / タブレット / スマートフォンに対応しています。Chrome / Safari / Edge の最新版を推奨します。",
        notesTitle: "注意事項",
        notesBody:
          "本サービスは個人による試験運用中のため、仕様や表現は予告なく調整されることがあります。",
        versionTitle: "プロンプト表記",
        versionBody:
          "キャラクターカードに表示される B-YYYYMMDD / beta は、ロールプレイ用プロンプトの調整版を表します。",
      },
      footer: {
        installTitle: "ホームに追加",
        installBody: "PWA としてホーム画面へ追加しておくと、次回からすぐに起動できます。",
        contactTitle: "連絡先・お問い合わせ",
        contactBody: "不具合報告やご要望は X または GitHub Issues までお寄せください。",
        privacy: "プライバシー",
        terms: "利用規約",
      },
      location: {
        roleplayChip: "ロールプレイ",
        cardHint: "設定済み / ロールプレイ / 会話可能",
        emptyLayer: "このレイヤーには現在表示できるキャラクターがいません。",
      },
    },
    legal: {
      privacy: {
        title: "プライバシーポリシー",
        intro: "このページは、現時点での取り扱い方針を簡潔にまとめたものです。",
        items: [
          "ログインには Supabase Auth を利用し、認証に必要な範囲の情報を保持します。",
          "会話内容、添付ファイル、リンク解析などは、機能提供や改善のために保存される場合があります。",
          "不要になった情報や不適切な保存内容は、運用判断で削除・修正することがあります。",
        ],
      },
      terms: {
        title: "利用規約",
        intro: "このページは、現在の試験運用向けの簡易規約です。",
        items: [
          "本サービスは個人運用の実験環境であり、継続性や完全性は保証されません。",
          "利用者は、法令や各プラットフォームの規約に反する使い方をしないでください。",
          "運用上必要な場合、機能や表示内容、保存データの扱いを変更することがあります。",
        ],
      },
    },
    chat: {
      sessionId: "セッション ID",
    },
  },
  en: {
    common: {
      appName: "Touhou Talk",
      back: "Back",
      chat: "Open chat",
      save: "Save",
      loading: "Loading…",
      selected: "Selected",
      on: "ON",
      off: "OFF",
      language: "Language",
      japanese: "Japanese",
      english: "English",
      relationship: "Relationship",
      export: "Export",
      import: "Import",
      reset: "Reset",
      refresh: "Refresh",
      clear: "Clear",
      upload: "Upload",
      enabled: "Enabled",
      disabled: "Disabled",
      none: "None",
      you: "You",
    },
    settings: {
      webTitle: "Web Settings",
      desktopTitle: "Desktop Settings",
      subtitleWeb: "Adjust display options, language, and default chat mode for the web app.",
      subtitleDesktop: "Adjust display options, language, and default chat mode for the desktop app.",
      sections: {
        language: {
          title: "Display language",
          description: "Switch the UI language. If you are logged in, it is also saved to your profile.",
        },
        map: {
          title: "Startup",
          description: "Choose whether to show the map screen on startup.",
          label: "Skip map screen",
          hint: "When enabled, login jumps straight to chat instead of opening the map first.",
        },
        theme: {
          title: "Theme",
          description: "Choose the visual theme.",
        },
        chatMode: {
          title: "Default chat mode",
          description: "Choose the default conversation style.",
          partner: "Partner",
          roleplay: "Roleplay",
          coach: "Coach",
        },
      },
    },
    top: {
      lines: [
        "Welcome to a dialogue terminal from Gensokyo.",
        "Pick who you want to talk to, then start the conversation.",
      ],
      login: "Sign in",
      enter: "Start chatting",
      description1:
        "This site is an unofficial Touhou-inspired character chat UI. It is built to keep the atmosphere while letting you talk naturally.",
      description2:
        "Interpretations of characters and setting may vary because this is a fan-made project.",
    },
    auth: {
      loginTitle: "Sign in",
      loginDescription: "Use Supabase Auth with OAuth providers.",
      loginRedirectHint: "After signing in, you will return to the page you selected.",
      continueWith: {
        google: "Continue with Google",
        github: "Continue with GitHub",
        discord: "Continue with Discord",
      },
      redirecting: "Redirecting…",
      requireTitle: "Sign-in required",
      requireDescription: "You need to sign in before opening this character chat.",
      goLogin: "Go to sign in",
    },
    entry: {
      heroTitle: "Talk to Touhou characters for real.",
      heroDescription: "Pick a character and jump into conversation right after sign-in.",
      talkWith: "Talk to",
      comingSoon: "Coming soon",
      charactersTitle: "Characters",
      charactersDescription: "Characters are grouped by location. Pick whoever catches your eye.",
      infoTitle: "Getting started",
      infoCards: {
        flowTitle: "How it works",
        flowItems: ["1. Pick a character", "2. Sign in", "3. Start chatting"],
        roleplayTitle: "Roleplay direction",
        roleplayBody:
          "The goal is to balance practical answers with each character's distinct atmosphere. Tone may shift depending on context.",
        environmentTitle: "Recommended environment",
        environmentBody: "Works on PC, tablet, and phone. Latest Chrome, Safari, or Edge is recommended.",
        notesTitle: "Notes",
        notesBody:
          "This project is under active personal development, so specs and expressions may change without notice.",
        versionTitle: "Prompt labels",
        versionBody:
          "Labels such as B-YYYYMMDD or beta on character cards indicate roleplay prompt revisions.",
      },
      footer: {
        installTitle: "Add to home screen",
        installBody: "Install it as a PWA to launch it quickly next time.",
        contactTitle: "Contact / feedback",
        contactBody: "Bug reports and requests are welcome via X or GitHub Issues.",
        privacy: "Privacy",
        terms: "Terms",
      },
      location: {
        roleplayChip: "Roleplay",
        cardHint: "Configured / roleplay / chat-ready",
        emptyLayer: "There are no characters available in this layer right now.",
      },
    },
    legal: {
      privacy: {
        title: "Privacy Policy",
        intro: "This page is a short summary of the current data-handling policy.",
        items: [
          "Supabase Auth is used for sign-in, and only the information needed for authentication is stored.",
          "Chat logs, attachments, and link analysis data may be stored to provide the service and improve it.",
          "Information may be corrected or removed when it is no longer needed or when operationally necessary.",
        ],
      },
      terms: {
        title: "Terms of Use",
        intro: "This page is a lightweight terms summary for the current test operation.",
        items: [
          "This service is an individually operated experimental environment and continuity is not guaranteed.",
          "Users must not use the service in ways that violate laws or the rules of connected platforms.",
          "Features, displayed content, and data handling may change when needed for operation.",
        ],
      },
    },
    chat: {
      sessionId: "Session ID",
    },
  },
};
