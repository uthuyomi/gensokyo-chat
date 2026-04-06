"use client";

import { useSearchParams } from "next/navigation";
import {
  startTransition,
  useCallback,
  useEffect,
  useLayoutEffect,
  useMemo,
  useRef,
  useState,
} from "react";

import {
  AssistantRuntimeProvider,
  useExternalStoreRuntime,
  type AppendMessage,
  type CompleteAttachment,
  type ExternalStoreAdapter,
} from "@assistant-ui/react";
import { BotIcon, FastForwardIcon, InfoIcon, UserIcon, UsersIcon } from "lucide-react";

import { Thread } from "@/components/assistant-ui/thread";
import { ThreadSearch } from "@/components/assistant-ui/thread-search";
import { TouhouSidebar } from "@/components/assistant-ui/touhou-sidebar";
import { TouhouUiProvider } from "@/components/assistant-ui/touhou-ui-context";
import { useLanguage } from "@/components/i18n/LanguageProvider";
import {
  SidebarInset,
  SidebarProvider,
  SidebarTrigger,
  useSidebar,
} from "@/components/ui/sidebar";
import { Separator } from "@/components/ui/separator";

 import { CHARACTERS, isCharacterSelectable } from "@/data/characters";
import { getGroupsByLocation, canEnableGroup, GroupDef } from "@/data/group";
import { getDefaultChatMode } from "@/lib/touhou-settings";
import { buildRunJsonlFromMessages, parseArtifactText } from "@/lib/artifact/artifact-io";
import DesktopLiveAvatar from "@/components/desktop/DesktopLiveAvatar";
import type { RoomParticipant } from "@/lib/rooms/participants";
import { getAiParticipants, getPrimaryAiCharacterId } from "@/lib/rooms/participants";

import {
  extractTextFromThreadMessageContent,
  talkMessageToThreadMessageLike,
  TouhouUploadAttachmentAdapter,
  type TalkUiMessage,
} from "@/lib/assistant-ui/touhou-external-store";


/* =========================
   Types
========================= */

type Message = TalkUiMessage;

type SessionSummary = {
  id: string;
  title: string;
  characterId: string;
  mode: "single" | "group";
  layer: string | null;
  location: string | null;
  chatMode: "partner" | "roleplay" | "coach";
  participants?: RoomParticipant[];
  meta?: Record<string, unknown> | null;
};

type PanelGroupContext = {
  enabled: boolean;
  label: string;
  group: GroupDef;
};

type ChatGroupContext = {
  enabled: boolean;
  label: string;
  ui: {
    chatBackground?: string;
    accent?: string;
  };
  participants: Array<{
    id: string;
    name: string;
    title: string;
    ui: {
      chatBackground?: string | null;
      placeholder: string;
    };
    color?: {
      accent?: string;
    };
  }>;
};

type VscodeMeta = {
  diff?: string;
  touched_files?: string[];
  next_action?: string;
};

type ChatApiResponse = {
  role?: "ai" | "user";
  content: string;
  meta?: VscodeMeta | null;
  error?: string;
};

type CreateSessionResponse = {
  sessionId: string;
};

type VscodeState =
  | "idle"
  | "analyzing"
  | "diffing"
  | "analysis_done"
  | "diff_ready"
  | "applying"
  | "applied"
  | "error";

function inferSpeakerCharacterId(meta: unknown, fallbackCharacterId: string | null) {
  const source =
    meta && typeof meta === "object" && !Array.isArray(meta)
      ? (meta as Record<string, unknown>)
      : null;
  const speaker =
    source?.speaker && typeof source.speaker === "object" && !Array.isArray(source.speaker)
      ? (source.speaker as Record<string, unknown>)
      : null;
  const speakerCharacterId =
    typeof speaker?.character_id === "string" && speaker.character_id.trim()
      ? speaker.character_id.trim()
      : typeof source?.character_id === "string" && source.character_id.trim()
        ? source.character_id.trim()
        : null;
  return speakerCharacterId ?? fallbackCharacterId;
}

function normalizeFetchedMessage(m: any, fallbackCharacterId: string | null): Message {
  return {
    id: String(m.id),
    role: m.role === "user" ? "user" : "ai",
    content: String(m.content ?? ""),
    speakerId:
      typeof m.speaker_id === "string" && m.speaker_id
        ? m.speaker_id
        : inferSpeakerCharacterId(m.meta ?? null, fallbackCharacterId) ?? undefined,
    attachments: [],
    meta: (m.meta ?? null) as Record<string, unknown> | null,
  };
}

/* =========================
   Component
========================= */

function AutoCloseSidebarOnRequest(props: { requestId: number }) {
  const { isMobile, setOpen, setOpenMobile } = useSidebar();
  const prevRequestIdRef = useRef(props.requestId);

  useEffect(() => {
    if (prevRequestIdRef.current === props.requestId) return;
    prevRequestIdRef.current = props.requestId;

    // Close right away when user picks a session (mobile/tablet UX).
    if (isMobile) setOpenMobile(false);
    else setOpen(false);
  }, [props.requestId, isMobile, setOpen, setOpenMobile]);

  return null;
}

export default function ChatClient() {
  const { lang, t } = useLanguage();
  const chatUi = useMemo(() => ({
    room: lang === "ja" ? "???" : "Room",
    chooseCharacter: lang === "ja" ? "???????????????" : "Choose a character",
    sessionShow: lang === "ja" ? "?????ID???" : "Show session ID",
    sessionHide: lang === "ja" ? "?????ID????" : "Hide session ID",
    groupRosterShow: lang === "ja" ? "?????????" : "Show participants",
    groupRosterHide: lang === "ja" ? "??????????" : "Hide participants",
    participants: lang === "ja" ? "??????" : "Participants",
    cast: lang === "ja" ? "???" : "Cast",
    lead: lang === "ja" ? "??" : "Lead",
    topic: lang === "ja" ? "??" : "Topic",
    recentTurns: lang === "ja" ? "??????" : "Recent turns",
    nextCandidate: lang === "ja" ? "???" : "Next",
    continueTitle: lang === "ja" ? "AI room ?????????" : "Let the AI room continue",
    continue: lang === "ja" ? "???????" : "Continue",
    autoRunTitle: lang === "ja" ? "AI room ?????????????" : "Auto-run the AI room",
    autoRunOn: lang === "ja" ? "???????" : "Auto-running",
    autoRunOff: lang === "ja" ? "???????" : "Auto-run",
    resizeAvatarPanel: lang === "ja" ? "???????????????" : "Resize avatar panel",
    resizeByDrag: lang === "ja" ? "??????????????????????????????" : "Drag to resize. Double-click to reset.",
    character: lang === "ja" ? "??????" : "Character",
    avatarArea: lang === "ja" ? "3:4 ?????????? VRM ??????" : "VRM display area with a fixed 3:4 portrait ratio",
    dragMove: lang === "ja" ? "????????????????????????????????" : "Drag to move. Double-click to reset size.",
    avatar: lang === "ja" ? "????" : "Avatar",
    hideAvatar: lang === "ja" ? "????????????" : "Hide avatar",
    dragResize: lang === "ja" ? "???????????????" : "Drag to resize",
    empty: lang === "ja" ? "??????????????????????????" : "Choose a character from the left sidebar.",
  }), [lang]);
  const searchParams = useSearchParams();
  const currentLayer = searchParams.get("layer");
  const currentLocationId = searchParams.get("loc");

  const isElectron = useMemo(() => {
    if (typeof navigator === "undefined") return false;
    return String(navigator.userAgent ?? "").includes("Electron");
  }, []);

  const POPOUT_HEARTBEAT_KEY = "touhou.desktop.avatar.popout.heartbeatUntil";

  /* =========================
     State
  ========================= */

  const [sessions, setSessions] = useState<SessionSummary[]>([]);
  const [activeSessionId, setActiveSessionId] = useState<string | null>(null);
  const [activeCharacterId, setActiveCharacterId] = useState<string | null>(
    null,
  );

  const activeSession = useMemo(() => {
    if (!activeSessionId) return null;
    return sessions.find((s) => s.id === activeSessionId) ?? null;
  }, [sessions, activeSessionId]);

  const activeParticipants = useMemo(
    () => activeSession?.participants ?? [],
    [activeSession],
  );

  const activeAiCharacterIds = useMemo(() => {
    const ids = activeParticipants
      .filter((participant): participant is RoomParticipant => !!participant)
      .flatMap((participant) =>
        participant.kind === "ai_character" ? [participant.characterId] : [],
      );
    const unique = Array.from(new Set(ids.filter(Boolean)));
    if (unique.length > 0) return unique;
    return activeCharacterId ? [activeCharacterId] : [];
  }, [activeParticipants, activeCharacterId]);

  const activeSceneState = useMemo(() => {
    const meta =
      activeSession?.meta && typeof activeSession.meta === "object" && !Array.isArray(activeSession.meta)
        ? (activeSession.meta as Record<string, unknown>)
        : null;
    const scene =
      meta?.scene_state && typeof meta.scene_state === "object" && !Array.isArray(meta.scene_state)
        ? (meta.scene_state as Record<string, unknown>)
        : null;
    return scene;
  }, [activeSession]);

  const activeHumanParticipantCount = useMemo(
    () => activeParticipants.filter((participant) => participant.kind === "human").length,
    [activeParticipants],
  );

  const needsRoomPolling = useMemo(() => {
    if (!activeSession) return false;
    if (activeSession.mode === "group") return true;
    if (activeHumanParticipantCount > 1) return true;
    return false;
  }, [activeSession, activeHumanParticipantCount]);

  const [relationshipHud, setRelationshipHud] = useState<{
    trust: number;
    familiarity: number;
    trustLabel: string;
    familiarityLabel: string;
  } | null>(null);

  const [worldHud, setWorldHud] = useState<{
    layer: string;
    location: string;
    timeOfDay?: string;
    weather?: string;
    season?: string;
    anomaly?: string | null;
    recent?: string[];
  } | null>(null);

  const [desktopAvatarVisible, setDesktopAvatarVisible] = useState<boolean>(() => {
    if (typeof window === "undefined") return true;
    const v = String(window.localStorage.getItem("touhou.desktop.avatar.visible") ?? "").trim();
    if (!v) return true;
    return v !== "0" && v.toLowerCase() !== "false";
  });

  const [desktopAvatarLayout, setDesktopAvatarLayout] = useState<"pip" | "dock">(() => {
    if (typeof window === "undefined") return "pip";
    const v = String(window.localStorage.getItem("touhou.desktop.avatar.layout") ?? "").trim().toLowerCase();
    return v === "dock" ? "dock" : "pip";
  });

  const [desktopAvatarDockWidth, setDesktopAvatarDockWidth] = useState<number>(() => {
    if (typeof window === "undefined") return 360;
    const raw = String(window.localStorage.getItem("touhou.desktop.avatar.dockWidth") ?? "").trim();
    const n = Number(raw);
    if (!Number.isFinite(n) || n <= 0) return 360;
    return Math.max(260, Math.min(640, Math.trunc(n)));
  });

  const [desktopAvatarPipRect, setDesktopAvatarPipRect] = useState<{
    x: number;
    y: number;
    w: number;
    h: number;
  }>(() => {
    if (typeof window === "undefined") return { x: 0, y: 0, w: 340, h: 420 };
    const readNum = (k: string, fallback: number) => {
      const raw = String(window.localStorage.getItem(k) ?? "").trim();
      const n = Number(raw);
      return Number.isFinite(n) ? n : fallback;
    };

    const w = Math.max(260, Math.min(520, Math.trunc(readNum("touhou.desktop.avatar.pip.w", 340))));
    const h = Math.max(260, Math.min(620, Math.trunc(readNum("touhou.desktop.avatar.pip.h", 420))));
    const x = Math.trunc(readNum("touhou.desktop.avatar.pip.x", 0));
    const y = Math.trunc(readNum("touhou.desktop.avatar.pip.y", 80));
    return { x, y, w, h };
  });

  const [desktopAvatarAvailRev, setDesktopAvatarAvailRev] = useState(0);
  const [desktopAvatarAvailable, setDesktopAvatarAvailable] = useState(false);
  const [desktopAvatarPopoutActive, setDesktopAvatarPopoutActive] = useState(false);

  const [artifactBusy, setArtifactBusy] = useState(false);
  const [showSessionMeta, setShowSessionMeta] = useState(false);
  const [showGroupRoster, setShowGroupRoster] = useState(false);

  const [messagesBySession, setMessagesBySession] = useState<
    Record<string, Message[]>
  >({});

  const [isRunningBySession, setIsRunningBySession] = useState<
    Record<string, boolean>
  >({});

  const appendMessage = useCallback(
    (m: Message) => {
      if (!activeSessionId) return;

      setMessagesBySession((prev) => ({
        ...prev,
        [activeSessionId]: [...(prev[activeSessionId] ?? []), m],
      }));
    },
    [activeSessionId],
  );

  const [mode] = useState<"single" | "group">("single");

  const autoSelectDoneRef = useRef(false);

  /* =========================
     Mobile UI
  ========================= */

  const [isPanelOpen, setIsPanelOpen] = useState(false);
  const [hasSelectedOnce, setHasSelectedOnce] = useState(false);
  const [charactersCollapsed, setCharactersCollapsed] = useState(false);
  const [sidebarCloseRequestId, setSidebarCloseRequestId] = useState(0);

  const [isMobile, setIsMobile] = useState<boolean>(() => {
    if (typeof window === "undefined") return false;
    return window.matchMedia("(max-width: 1024px)").matches;
  });

  const [sessionsLoaded, setSessionsLoaded] = useState(false);

  useEffect(() => {
    setShowSessionMeta(false);
    setShowGroupRoster(false);
  }, [activeSessionId]);

  const [isCreateThreadDialogOpen, setIsCreateThreadDialogOpen] = useState(false);
  const [sceneAutoRun, setSceneAutoRun] = useState(false);
  const [recentCharacterIds, setRecentCharacterIds] = useState<string[]>(() => {
    if (typeof window === "undefined") return [];
    try {
      const raw = window.localStorage.getItem("touhou.chat.recentCharacters");
      const parsed = raw ? JSON.parse(raw) : [];
      return Array.isArray(parsed) ? parsed.filter((v): v is string => typeof v === "string") : [];
    } catch {
      return [];
    }
  });

  useEffect(() => {
    if (typeof window === "undefined") return;
    try {
      window.localStorage.setItem("touhou.desktop.avatar.visible", desktopAvatarVisible ? "1" : "0");
      window.localStorage.setItem("touhou.desktop.avatar.layout", desktopAvatarLayout);
      window.localStorage.setItem("touhou.desktop.avatar.dockWidth", String(desktopAvatarDockWidth));
      window.localStorage.setItem("touhou.desktop.avatar.pip.x", String(desktopAvatarPipRect.x));
      window.localStorage.setItem("touhou.desktop.avatar.pip.y", String(desktopAvatarPipRect.y));
      window.localStorage.setItem("touhou.desktop.avatar.pip.w", String(desktopAvatarPipRect.w));
      window.localStorage.setItem("touhou.desktop.avatar.pip.h", String(desktopAvatarPipRect.h));
    } catch {
      // ignore
    }
  }, [desktopAvatarVisible, desktopAvatarLayout, desktopAvatarDockWidth, desktopAvatarPipRect]);

  useEffect(() => {
    const characterId = String(activeCharacterId ?? "").trim();
    if (!characterId) {
      setRelationshipHud(null);
      return;
    }

    let canceled = false;
    (async () => {
      try {
        const r = await fetch(`/api/relationship?characterId=${encodeURIComponent(characterId)}`, {
          cache: "no-store",
        });
        const j = (await r.json().catch(() => null)) as any;
        if (!r.ok) throw new Error(j?.error || "relationship fetch failed");
        const row = Array.isArray(j?.relationships) ? j.relationships[0] : null;
        const trust = Number(row?.trust ?? 0);
        const familiarity = Number(row?.familiarity ?? 0);
        const tl =
          trust <= -0.6 ? "不信（強）" : trust <= -0.2 ? "不信" : trust < 0.2 ? "中立" : trust < 0.6 ? "信頼" : "信頼（強）";
        const fl = familiarity < 0.25 ? "低" : familiarity < 0.6 ? "中" : "高";
        if (!canceled) setRelationshipHud({ trust, familiarity, trustLabel: tl, familiarityLabel: fl });
      } catch {
        if (!canceled) setRelationshipHud(null);
      }
    })();

    return () => {
      canceled = true;
    };
  }, [activeCharacterId]);

  useEffect(() => {
    const layer = String(activeSession?.layer ?? currentLayer ?? "").trim();
    const location = String(activeSession?.location ?? currentLocationId ?? "").trim();
    if (!layer) {
      setWorldHud(null);
      return;
    }

    let canceled = false;
    (async () => {
      try {
        const qs = new URLSearchParams({ world_id: layer, location_id: location }).toString();
        const [stateRes, recentRes] = await Promise.all([
          fetch(`/api/world/state?${qs}`, { cache: "no-store" }),
          fetch(`/api/world/recent?${qs}&limit=6`, { cache: "no-store" }),
        ]);
        const state = (await stateRes.json().catch(() => null)) as any;
        const recent = (await recentRes.json().catch(() => null)) as any;
        const recentEvents = Array.isArray(recent?.recent_events)
          ? (recent.recent_events as any[]).map((e) => String(e?.summary ?? "").trim()).filter(Boolean).slice(-6)
          : [];

        if (!canceled) {
          setWorldHud({
            layer,
            location,
            timeOfDay: typeof state?.time_of_day === "string" ? state.time_of_day : undefined,
            weather: typeof state?.weather === "string" ? state.weather : undefined,
            season: typeof state?.season === "string" ? state.season : undefined,
            anomaly: typeof state?.anomaly === "string" ? state.anomaly : null,
            recent: recentEvents.length ? recentEvents : undefined,
          });
        }

        // Best-effort: register a "visit" snapshot (world service owns persistence).
        if (!canceled && activeSessionId) {
          try {
            await fetch("/api/world/visit", {
              method: "POST",
              headers: { "Content-Type": "application/json" },
              body: JSON.stringify({
                world_id: layer,
                location_id: location,
                visitor_key: activeSessionId,
                user_time: new Date().toISOString(),
              }),
            });
          } catch {
            // ignore
          }
        }
      } catch {
        if (!canceled) setWorldHud(null);
      }
    })();

    return () => {
      canceled = true;
    };
  }, [activeSession?.layer, activeSession?.location, activeSessionId, currentLayer, currentLocationId]);

  // If a dedicated avatar popout window is active, hide the in-chat avatar to avoid showing two VRMs.
  useEffect(() => {
    if (!isElectron) return;
    if (typeof window === "undefined") return;

    const read = () => {
      try {
        const raw = String(window.localStorage.getItem(POPOUT_HEARTBEAT_KEY) ?? "").trim();
        const until = Number(raw);
        const ok = Number.isFinite(until) && until > Date.now();
        setDesktopAvatarPopoutActive(ok);
      } catch {
        setDesktopAvatarPopoutActive(false);
      }
    };

    read();
    const id = window.setInterval(read, 1000);
    const onStorage = (e: StorageEvent) => {
      if (e.key !== POPOUT_HEARTBEAT_KEY) return;
      read();
    };
    try {
      window.addEventListener("storage", onStorage);
    } catch {
      // ignore
    }

    return () => {
      window.clearInterval(id);
      try {
        window.removeEventListener("storage", onStorage);
      } catch {
        // ignore
      }
    };
  }, [isElectron, POPOUT_HEARTBEAT_KEY]);

  const dockWrapRef = useRef<HTMLDivElement | null>(null);
  const dockDragRef = useRef<{
    pointerId: number;
    startX: number;
    startWidth: number;
  } | null>(null);

  const pipWrapRef = useRef<HTMLDivElement | null>(null);
  const pipDragRef = useRef<
    | {
        kind: "move";
        pointerId: number;
        startX: number;
        startY: number;
        startRect: { x: number; y: number; w: number; h: number };
      }
    | {
        kind: "resize";
        pointerId: number;
        startX: number;
        startY: number;
        startRect: { x: number; y: number; w: number; h: number };
      }
    | null
  >(null);

  const clampPipRect = useCallback(
    (rect: { x: number; y: number; w: number; h: number }) => {
      const wrap = pipWrapRef.current;
      const bounds = wrap?.getBoundingClientRect?.();
      const bw = Math.trunc(bounds?.width ?? 0);
      const bh = Math.trunc(bounds?.height ?? 0);

      const minW = 260;
      const minH = 260;
      const maxW = 520;
      const maxH = 620;

      const w = Math.max(minW, Math.min(maxW, Math.trunc(rect.w)));
      const h = Math.max(minH, Math.min(maxH, Math.trunc(rect.h)));

      const pad = 8;
      const maxX = bw > 0 ? Math.max(pad, bw - w - pad) : 10000;
      const maxY = bh > 0 ? Math.max(pad, bh - h - pad) : 10000;

      const x = Math.max(pad, Math.min(maxX, Math.trunc(rect.x)));
      const y = Math.max(pad, Math.min(maxY, Math.trunc(rect.y)));

      return { x, y, w, h };
    },
    [],
  );

  useEffect(() => {
    const onMove = (e: PointerEvent) => {
      const drag = dockDragRef.current;
      if (!drag) return;
      if (e.pointerId !== drag.pointerId) return;
      const wrap = dockWrapRef.current;
      const wrapWidth = wrap?.getBoundingClientRect?.().width ?? 0;

      // Right dock: dragging left increases width, dragging right decreases.
      const next = Math.trunc(drag.startWidth + (drag.startX - e.clientX));

      const min = 260;
      const maxByWrap = wrapWidth > 0 ? Math.max(min, Math.trunc(wrapWidth - 420)) : 640; // keep chat usable
      const max = Math.max(min, Math.min(640, maxByWrap));
      setDesktopAvatarDockWidth(Math.max(min, Math.min(max, next)));
    };

    const onUp = (e: PointerEvent) => {
      const drag = dockDragRef.current;
      if (!drag) return;
      if (e.pointerId !== drag.pointerId) return;
      dockDragRef.current = null;
    };

    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onUp);
    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onUp);
    };
  }, []);

  useEffect(() => {
    const onMove = (e: PointerEvent) => {
      const drag = pipDragRef.current;
      if (!drag) return;
      if (e.pointerId !== drag.pointerId) return;

      if (drag.kind === "move") {
        const next = {
          ...drag.startRect,
          x: drag.startRect.x + (e.clientX - drag.startX),
          y: drag.startRect.y + (e.clientY - drag.startY),
        };
        setDesktopAvatarPipRect(clampPipRect(next));
        return;
      }

      // resize (bottom-right)
      const next = {
        ...drag.startRect,
        w: drag.startRect.w + (e.clientX - drag.startX),
        h: drag.startRect.h + (e.clientY - drag.startY),
      };
      setDesktopAvatarPipRect(clampPipRect(next));
    };

    const onUp = (e: PointerEvent) => {
      const drag = pipDragRef.current;
      if (!drag) return;
      if (e.pointerId !== drag.pointerId) return;
      pipDragRef.current = null;
    };

    window.addEventListener("pointermove", onMove);
    window.addEventListener("pointerup", onUp);
    window.addEventListener("pointercancel", onUp);
    return () => {
      window.removeEventListener("pointermove", onMove);
      window.removeEventListener("pointerup", onUp);
      window.removeEventListener("pointercancel", onUp);
    };
  }, [clampPipRect]);

  useEffect(() => {
    if (!isElectron) return;
    const onUpdated = (_ev: Event) => {
      setDesktopAvatarAvailRev((n) => n + 1);
    };
    window.addEventListener("touhou-desktop:vrm-updated", onUpdated as EventListener);
    return () => {
      window.removeEventListener("touhou-desktop:vrm-updated", onUpdated as EventListener);
    };
  }, [isElectron]);

  useEffect(() => {
    if (!isElectron) {
      setDesktopAvatarAvailable(false);
      return;
    }
    if (!activeCharacterId) {
      setDesktopAvatarAvailable(false);
      return;
    }

    let canceled = false;
    (async () => {
      try {
        const res = await fetch(`/api/desktop/character-settings?char=${encodeURIComponent(activeCharacterId)}`, {
          cache: "no-store",
        });
        const j = (await res.json().catch(() => null)) as
          | { ok?: boolean; exists?: boolean; settings?: { vrm?: { enabled?: boolean; path?: string | null } } | null }
          | null;
        const ok = Boolean(res.ok && j?.ok && j.exists && j.settings?.vrm?.enabled && j.settings?.vrm?.path);
        if (!canceled) setDesktopAvatarAvailable(ok);
      } catch {
        if (!canceled) setDesktopAvatarAvailable(false);
      }
    })();

    return () => {
      canceled = true;
    };
  }, [isElectron, activeCharacterId, desktopAvatarAvailRev]);

  useEffect(() => {
    const mq = window.matchMedia("(max-width: 1024px)");
    const handler = (e: MediaQueryListEvent) => setIsMobile(e.matches);
    mq.addEventListener("change", handler);
    return () => mq.removeEventListener("change", handler);
  }, []);

  /* =========================
     Active character
  ========================= */

  const activeCharacter = useMemo(() => {
    if (!activeCharacterId) return null;
    return CHARACTERS[activeCharacterId] ?? null;
  }, [activeCharacterId]);

  useEffect(() => {
    const characterId = String(activeCharacterId ?? "").trim();
    if (!characterId) return;

    setRecentCharacterIds((prev) => {
      const next = [characterId, ...prev.filter((id) => id !== characterId)].slice(0, 8);
      try {
        window.localStorage.setItem("touhou.chat.recentCharacters", JSON.stringify(next));
      } catch {
        // ignore
      }
      return next;
    });
  }, [activeCharacterId]);

  const [resolvedChatBackground, setResolvedChatBackground] = useState<string | null>(null);

  useEffect(() => {
    const ui = activeCharacter?.ui;
    if (!ui) {
      setResolvedChatBackground(null);
      return;
    }

    const pc = typeof ui.chatBackgroundPC === "string" ? ui.chatBackgroundPC.trim() : "";
    const sp = typeof ui.chatBackgroundSP === "string" ? ui.chatBackgroundSP.trim() : "";
    const legacy = typeof ui.chatBackground === "string" ? ui.chatBackground.trim() : "";

    const preferred = isMobile ? sp || pc : pc || sp;
    const fallback = legacy || null;

    // Always show fallback immediately to avoid a "blank" background while checking preferred existence.
    setResolvedChatBackground(fallback);

    // If no preferred is configured, just use legacy (if any).
    if (!preferred) {
      return;
    }

    // Try to load preferred. If it 404s (image not yet added), fall back to legacy.
    let cancelled = false;
    const img = new Image();
    img.onload = () => {
      if (cancelled) return;
      setResolvedChatBackground(preferred);
    };
    img.onerror = () => {
      if (cancelled) return;
      setResolvedChatBackground(fallback);
    };
    img.src = preferred;

    return () => {
      cancelled = true;
    };
  }, [activeCharacterId, activeCharacter?.ui, isMobile]);

  /* =========================
     Character filter
  ========================= */

  const visibleCharacters = useMemo(() => {
    return Object.values(CHARACTERS).filter(
      (c) => isCharacterSelectable(c),
    );
  }, []);

  /* =========================
     Group Context
  ========================= */

  const panelGroupContext = useMemo<PanelGroupContext | null>(() => {
    if (!currentLayer || !currentLocationId) return null;
    const groups = getGroupsByLocation(currentLayer, currentLocationId);
    if (!groups.length) return null;
    const group = groups[0];
    if (!canEnableGroup(group.id)) return null;
    return { enabled: true, label: group.ui.label, group };
  }, [currentLayer, currentLocationId]);

  const chatGroupContext = useMemo<ChatGroupContext | null>(() => {
    if (!panelGroupContext?.enabled) return null;

    const participants = panelGroupContext.group.participants
      .map((id) => CHARACTERS[id])
      .filter((c) => isCharacterSelectable(c));

    const groupUi = panelGroupContext.group.ui as {
      chatBackground?: string | null;
      accent?: string;
    };

    return {
      enabled: true,
      label: panelGroupContext.group.ui.label,
      ui: {
        chatBackground: groupUi.chatBackground ?? undefined,
        accent: groupUi.accent,
      },
      participants,
    };
  }, [panelGroupContext]);

  const refreshSessions = useCallback(async () => {
    const res = await fetch("/api/session", { cache: "no-store" });
    if (!res.ok) return null;
    const data = (await res.json()) as { sessions?: SessionSummary[] };
    const nextSessions = data.sessions ?? [];
    setSessions(nextSessions);
    setSessionsLoaded(true);
    return nextSessions;
  }, []);

  /* =========================
     Initial session list
  ========================= */

  useEffect(() => {
    (async () => {
      await refreshSessions();
    })();
  }, [refreshSessions]);

  /* =========================
     Character select
  ========================= */

  const selectCharacter = useCallback(
    async (characterId: string) => {
      const existing = sessions.find(
        (s) =>
          s.characterId === characterId &&
          (currentLayer ? s.layer === currentLayer : true) &&
          (currentLocationId ? s.location === currentLocationId : true),
      );
      if (existing) {
        setActiveSessionId(existing.id);
        setActiveCharacterId(characterId); // 既存セッションに切り替え
        setHasSelectedOnce(true);
        setIsPanelOpen(false);
        return;
      }

      const res = await fetch("/api/session", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          characterId,
          mode,
          layer: currentLayer,
          location: currentLocationId,
          chatMode: getDefaultChatMode(),
        }),
      });

      if (!res.ok) return;
      const data = (await res.json()) as CreateSessionResponse;

      const newSession: SessionSummary = {
        id: data.sessionId,
        title: "新しい会話",
        characterId,
        mode,
        layer: currentLayer,
        location: currentLocationId,
        chatMode: getDefaultChatMode(),
      };

      setSessions((prev) => [newSession, ...prev]);
      setActiveSessionId(newSession.id);
      setActiveCharacterId(characterId);
      setMessagesBySession((prev) => ({ ...prev, [newSession.id]: [] }));
      setHasSelectedOnce(true);
      setIsPanelOpen(false);
    },
    [sessions, mode, currentLayer, currentLocationId],
  );

  const createSessionForCharacters = useCallback(async (
    characterIds: string[],
    invitedHumans?: Array<{ userId?: string | null; displayName?: string | null; email?: string | null }>,
  ) => {
    const normalizedIds = Array.from(
      new Set(
        characterIds
          .filter((value): value is string => typeof value === "string")
          .map((value) => value.trim())
          .filter(Boolean),
      ),
    );
    if (normalizedIds.length === 0) return;

    const primaryCharacterId = normalizedIds[0];
    const chatMode = getDefaultChatMode();
    const sessionMode: "single" | "group" = normalizedIds.length > 1 ? "group" : mode;
    const res = await fetch("/api/session", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({
        characterId: primaryCharacterId,
        participantCharacterIds: normalizedIds,
        invitedHumans: Array.isArray(invitedHumans) ? invitedHumans : [],
        mode: sessionMode,
        layer: currentLayer,
        location: currentLocationId,
        chatMode,
      }),
    });

    if (!res.ok) return;
    const data = (await res.json()) as CreateSessionResponse;

    const participants: RoomParticipant[] = normalizedIds.map((id) => ({
      id: `ai:${id}`,
      kind: "ai_character",
      characterId: id,
      displayName: CHARACTERS[id]?.name ?? id,
      title: CHARACTERS[id]?.title ?? null,
    }));

    const newSession: SessionSummary = {
      id: data.sessionId,
      title: normalizedIds.length > 1 ? "新しいルーム" : "新しい会話",
      characterId: primaryCharacterId,
      mode: sessionMode,
      layer: currentLayer,
      location: currentLocationId,
      chatMode,
      participants,
      meta: {
        room_kind: invitedHumans?.length ? "mixed" : normalizedIds.length > 1 ? "group_ai" : "single",
        participant_character_ids: normalizedIds,
      },
    };

    setSessions((prev) => [newSession, ...prev]);
    setActiveSessionId(newSession.id);
    setActiveCharacterId(primaryCharacterId);
    setMessagesBySession((prev) => ({ ...prev, [newSession.id]: [] }));
    setHasSelectedOnce(true);
    setIsCreateThreadDialogOpen(false);
    if (isMobile) setSidebarCloseRequestId((v) => v + 1);
  }, [currentLayer, currentLocationId, isMobile, mode]);

  const createSessionForCharacter = useCallback(async (characterId: string) => {
    await createSessionForCharacters([characterId]);
  }, [createSessionForCharacters]);

  const createSession = useCallback(async () => {
    if (!activeCharacterId) {
      setIsCreateThreadDialogOpen(true);
      return;
    }
    await createSessionForCharacter(activeCharacterId);
  }, [activeCharacterId, createSessionForCharacter]);

  /* =========================
     Artifact import / export
  ========================= */

  const handleExportActiveSession = useCallback(() => {
    if (!activeSessionId) return;

    const list = messagesBySession[activeSessionId] ?? [];
    const jsonl = buildRunJsonlFromMessages({
      sessionId: activeSessionId,
      messages: list.map((m) => ({ role: m.role, content: m.content })),
    });

    if (!jsonl.trim()) {
      alert("エクスポートできるメッセージがありません。");
      return;
    }

    const blob = new Blob([jsonl], { type: "application/x-ndjson" });
    const dlUrl = URL.createObjectURL(blob);
    try {
      const a = document.createElement("a");
      a.href = dlUrl;
      a.download = "run.jsonl";
      a.click();
    } finally {
      URL.revokeObjectURL(dlUrl);
    }
  }, [activeSessionId, messagesBySession]);

  const handleImportArtifactFile = useCallback(
    async (file: File) => {
      if (!activeCharacterId) {
        alert("先にキャラを選択してください。");
        return;
      }

      const MAX_BYTES = 10 * 1024 * 1024; // 10MB
      if (file.size > MAX_BYTES) {
        alert("ファイルが大きすぎます（最大10MB）。");
        return;
      }

      setArtifactBusy(true);
      try {
        const text = await file.text();
        const parsed = parseArtifactText(text);

        if (!parsed.sessions || parsed.sessions.length === 0) {
          alert("復元できるデータが見つかりませんでした。");
          return;
        }

        const importChatMode = getDefaultChatMode();
        const payloadSessions = parsed.sessions.map((s) => ({
          title: s.title,
          externalSessionId: s.externalSessionId,
          messages: s.messages.map((m) => ({
            role: m.role,
            content: m.content,
            meta: m.meta ?? null,
          })),
        }));

        const res = await fetch("/api/session/import", {
          method: "POST",
          headers: { "Content-Type": "application/json" },
          body: JSON.stringify({
            characterId: activeCharacterId,
            mode,
            layer: currentLayer,
            location: currentLocationId,
            chatMode: importChatMode,
            sessions: payloadSessions,
          }),
        });

        if (!res.ok) {
          const detail = await res.text().catch(() => "");
          throw new Error(`HTTP ${res.status} ${detail}`);
        }

        const data = (await res.json()) as {
          sessions?: Array<{
            sessionId: string;
            title: string;
            externalSessionId?: string;
          }>;
        };

        const created = Array.isArray(data.sessions) ? data.sessions : [];
        if (created.length === 0) {
          alert("復元に失敗しました（有効なセッションがありません）。");
          return;
        }

        const externalToSource = new Map<string, (typeof parsed.sessions)[number]>();
        for (const s of parsed.sessions) {
          if (typeof s.externalSessionId === "string" && s.externalSessionId) {
            externalToSource.set(s.externalSessionId, s);
          }
        }

        const newSessions: SessionSummary[] = created.map((s) => ({
          id: s.sessionId,
          title: s.title,
          characterId: activeCharacterId,
          mode,
          layer: currentLayer,
          location: currentLocationId,
          chatMode: importChatMode,
        }));

        setSessions((prev) => [...newSessions, ...prev]);

        setMessagesBySession((prev) => {
          const next = { ...prev };
          for (let i = 0; i < created.length; i++) {
            const createdSession = created[i];
            const source =
              (createdSession.externalSessionId
                ? externalToSource.get(createdSession.externalSessionId)
                : null) ??
              parsed.sessions[i] ??
              null;

            const msgs = (source?.messages ?? []).map((m) => ({
              id: crypto.randomUUID(),
              role: m.role,
              content: m.content,
              speakerId: m.role === "ai" ? activeCharacterId : undefined,
              attachments: [],
              meta: m.meta ?? null,
            })) satisfies Message[];

            next[createdSession.sessionId] = msgs;
          }
          return next;
        });

        setActiveSessionId(created[0].sessionId);
        setHasSelectedOnce(true);
        setSidebarCloseRequestId((v) => v + 1);
      } catch (e: any) {
        const msg = typeof e?.message === "string" ? e.message : String(e);
        alert("インポートに失敗しました。\n" + msg);
      } finally {
        setArtifactBusy(false);
      }
    },
    [activeCharacterId, currentLayer, currentLocationId, mode],
  );

  /* =========================
   Reset auto select flag when URL char changes
========================= */
  useEffect(() => {
    autoSelectDoneRef.current = false;
  }, [searchParams.get("char")]);
  /* =========================
   Auto select character from URL (map → chat)
 ========================= */
  useEffect(() => {
    if (!sessionsLoaded) return;
    if (autoSelectDoneRef.current) return;

    const charFromUrl = searchParams.get("char");
    if (!charFromUrl) return;
    if (!CHARACTERS[charFromUrl]) return;

    autoSelectDoneRef.current = true;

    // URLの変更直後は状態が競合しやすいので、次のtickで selectCharacter を実行する
    Promise.resolve().then(() => {
      selectCharacter(charFromUrl);
    });
  }, [searchParams, sessionsLoaded, selectCharacter]);
  /* =========================
     Session select / delete / rename
  ========================= */

  const selectSession = useCallback(
    (sessionId: string) => {
      const s = sessions.find((x) => x.id === sessionId);
      if (!s) return;
      setActiveSessionId(s.id);
      setActiveCharacterId(s.characterId);
      setHasSelectedOnce(true);
      if (isMobile) setSidebarCloseRequestId((v) => v + 1);
    },
    [sessions, isMobile],
  );

  const handleDeleteSession = useCallback(
    async (id: string) => {
      const res = await fetch(`/api/session/${id}`, { method: "DELETE" });
      if (!res.ok) return;

      setSessions((prev) => prev.filter((s) => s.id !== id));
      setMessagesBySession((prev) => {
        const next = { ...prev };
        delete next[id];
        return next;
      });

      if (activeSessionId === id) {
        setActiveSessionId(null);
        setActiveCharacterId(null);
        setHasSelectedOnce(false);
        setIsPanelOpen(false);
      }
    },
    [activeSessionId],
  );

  const handleRenameSession = useCallback(async (id: string, title: string) => {
    const t = title.trim();
    if (!t) return;

    const res = await fetch(`/api/session/${id}`, {
      method: "PATCH",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ title: t }),
    });

    if (!res.ok) return;

    setSessions((prev) =>
      prev.map((s) => (s.id === id ? { ...s, title: t } : s)),
    );
  }, []);

  /* =========================
     Messages restore
  ========================= */

  const refreshSessionMessages = useCallback(async (sessionId: string) => {
    const session = sessions.find((s) => s.id === sessionId) ?? null;
    const fallbackCharacterId = session?.characterId ?? null;
    const res = await fetch(`/api/session/${sessionId}/messages`, { cache: "no-store" });
    if (!res.ok) return;
    const data = await res.json();
    const normalized =
      (Array.isArray(data.messages) ? data.messages : []).map((m: any) =>
        normalizeFetchedMessage(m, fallbackCharacterId),
      ) ?? [];
    setMessagesBySession((prev) => ({
      ...prev,
      [sessionId]: normalized,
    }));
  }, [sessions]);

  useEffect(() => {
    if (!activeSessionId) return;
    if (!sessions.some((s) => s.id === activeSessionId)) return;
    if (Object.prototype.hasOwnProperty.call(messagesBySession, activeSessionId))
      return;

    (async () => {
      await refreshSessionMessages(activeSessionId);
    })();
  }, [activeSessionId, sessions, messagesBySession, refreshSessionMessages]);

  useEffect(() => {
    if (!sessionsLoaded) return;

    const tick = async () => {
      if (typeof document !== "undefined" && document.hidden) return;
      await refreshSessions();
      if (
        activeSessionId &&
        needsRoomPolling &&
        !(isRunningBySession[activeSessionId] ?? false)
      ) {
        await refreshSessionMessages(activeSessionId);
      }
    };

    const intervalMs = needsRoomPolling ? 12000 : 30000;
    const id = window.setInterval(() => {
      void tick();
    }, intervalMs);

    const onFocus = () => {
      void tick();
    };

    window.addEventListener("focus", onFocus);
    document.addEventListener("visibilitychange", onFocus);
    return () => {
      window.clearInterval(id);
      window.removeEventListener("focus", onFocus);
      document.removeEventListener("visibilitychange", onFocus);
    };
  }, [
    sessionsLoaded,
    refreshSessions,
    refreshSessionMessages,
    activeSessionId,
    isRunningBySession,
    needsRoomPolling,
  ]);

  /* =========================
     Message send
  ========================= */

  const handleSendTalk = useCallback(
    async (payload: {
      text: string;
      files: File[];
      attachments?: CompleteAttachment[];
    }) => {
      if (!activeSessionId || !activeCharacterId) return;

      const { text, files, attachments } = payload;
      const trimmed = String(text ?? "").trim();

      // Slash commands (client-side). Do NOT send to Persona core.
      // - /dump: export logs for the current session (admin-only, enforced server-side)
      if (/^\/dump\b/i.test(trimmed)) {
        appendMessage({
          id: crypto.randomUUID(),
          role: "user",
          content: trimmed,
          attachments: attachments ?? [],
          meta: null,
        });

        const aiId = crypto.randomUUID();
        appendMessage({
          id: aiId,
          role: "ai",
          content: "ログを生成中…",
          speakerId: activeCharacterId,
          attachments: [],
          meta: null,
        });

        try {
          const url = new URL("/api/logs/export", window.location.origin);
          url.searchParams.set("session_id", activeSessionId);
          url.searchParams.set("limit", "2000");

          const r = await fetch(url.toString(), { cache: "no-store" });
          if (!r.ok) {
            const detail = await r.text().catch(() => "");
            throw new Error(`export failed: HTTP ${r.status} ${detail}`);
          }

          const data = (await r.json()) as unknown;
          const ts = new Date().toISOString().replaceAll(":", "-");
          const filename = `touhou-logs_session_${activeSessionId}_${ts}.json`;

          const blob = new Blob([JSON.stringify(data, null, 2)], {
            type: "application/json",
          });
          const dlUrl = URL.createObjectURL(blob);
          try {
            const a = document.createElement("a");
            a.href = dlUrl;
            a.download = filename;
            a.click();
          } finally {
            URL.revokeObjectURL(dlUrl);
          }

          setMessagesBySession((prev) => {
            const list = prev[activeSessionId] ?? [];
            return {
              ...prev,
              [activeSessionId]: list.map((m) =>
                m.id === aiId
                  ? {
                      ...m,
                      content: `ログをダウンロードしました: ${filename}`,
                    }
                  : m
              ),
            };
          });
        } catch (e: any) {
          const msg = e?.message ?? String(e);
          setMessagesBySession((prev) => {
            const list = prev[activeSessionId] ?? [];
            return {
              ...prev,
              [activeSessionId]: list.map((m) =>
                m.id === aiId
                  ? {
                      ...m,
                      content:
                        "ログのダンプに失敗しました。権限（管理者）またはサーバ設定を確認してください。\n" +
                        msg,
                    }
                  : m
              ),
            };
          });
        }

        return;
      }

      setIsRunningBySession((prev) => ({
        ...prev,
        [activeSessionId]: true,
      }));

      let aiId = "";
      try {
        // user message
        appendMessage({
          id: crypto.randomUUID(),
          role: "user",
          content: text,
          attachments: attachments ?? [],
          meta: null,
        });

        // talk endpoint
        const endpoint = `/api/session/${activeSessionId}/message`;

        // talk: FormData に files を詰める
        const form = new FormData();
        form.append("characterId", activeCharacterId);
        form.append("text", text);

        try {
          const coreMode = String(window.localStorage.getItem("touhou.dev.coreMode") ?? "")
            .trim()
            .toLowerCase();
          if (coreMode === "local" || coreMode === "fly") {
            form.append("coreMode", coreMode);
          }
        } catch {
          // ignore
        }

        for (const file of files) {
          form.append("files", file);
        }

        if (activeSession?.mode === "group") {
          const res = await fetch(endpoint, {
            method: "POST",
            body: form,
          });
          if (!res.ok) {
            let detail = `HTTP ${res.status}`;
            try {
              const body = (await res.json().catch(() => null)) as
                | { error?: unknown; detail?: unknown }
                | null;
              const msg = String(body?.error ?? body?.detail ?? "").trim();
              if (msg) detail = msg;
            } catch {
              // ignore
            }
            appendMessage({
              id: crypto.randomUUID(),
              role: "ai",
              content: `送信失敗: ${detail}`,
              speakerId: activeCharacterId,
              attachments: [],
              meta: { source: "chat_group_request" },
            });
            return;
          }

          const data = (await res.json()) as {
            role?: "ai";
            content?: string;
            messages?: Array<{ id?: string; role?: "ai"; content?: string; speaker_id?: string | null; meta?: Record<string, unknown> | null }>;
            meta?: Record<string, unknown> | null;
          };
          const turns = Array.isArray(data.messages) ? data.messages : [];
          const appended = turns.length > 0
            ? turns.map((turn) => ({
                id: typeof turn.id === "string" && turn.id ? turn.id : crypto.randomUUID(),
                role: "ai" as const,
                content: String(turn.content ?? ""),
                speakerId:
                  typeof turn.speaker_id === "string" && turn.speaker_id
                    ? turn.speaker_id
                    : inferSpeakerCharacterId(turn.meta ?? null, activeCharacterId) ?? undefined,
                attachments: [],
                meta: (turn.meta ?? null) as Record<string, unknown> | null,
              }))
            : [{
                id: crypto.randomUUID(),
                role: "ai" as const,
                content: String(data.content ?? "返答を受け取れなかった"),
                speakerId: inferSpeakerCharacterId(data.meta ?? null, activeCharacterId) ?? undefined,
                attachments: [],
                meta: (data.meta ?? null) as Record<string, unknown> | null,
              }];

          setMessagesBySession((prev) => ({
            ...prev,
            [activeSessionId]: [...(prev[activeSessionId] ?? []), ...appended],
          }));

          const sceneState =
            data.meta && typeof data.meta === "object" && !Array.isArray(data.meta)
              ? (data.meta as Record<string, unknown>).scene_state
              : null;
          if (sceneState && typeof sceneState === "object" && !Array.isArray(sceneState)) {
            setSessions((prev) =>
              prev.map((session) =>
                session.id === activeSessionId
                  ? {
                      ...session,
                      meta: {
                        ...(session.meta ?? {}),
                        scene_state: sceneState as Record<string, unknown>,
                      },
                    }
                  : session,
              ),
            );
          }
          return;
        }

        // AI placeholder (stream target)
        aiId = crypto.randomUUID();
        appendMessage({
          id: aiId,
          role: "ai",
          content: "...",
          speakerId: activeCharacterId,
          attachments: [],
          meta: null,
        });

        const appendDelta = (delta: string) => {
          if (!delta) return;
          setMessagesBySession((prev) => {
            const list = prev[activeSessionId] ?? [];
            return {
              ...prev,
              [activeSessionId]: list.map((m) => {
                if (m.id !== aiId) return m;
                const prevText = typeof m.content === "string" ? m.content : "";
                const base = prevText === "..." ? "" : prevText;
                return { ...m, content: base + delta };
              }),
            };
          });
        };

        const finalize = (finalText: string, meta: unknown) => {
          const speakerId = inferSpeakerCharacterId(meta, activeCharacterId);
          setMessagesBySession((prev) => {
            const list = prev[activeSessionId] ?? [];
            return {
              ...prev,
              [activeSessionId]: list.map((m) =>
                m.id === aiId
                  ? {
                      ...m,
                      content: finalText,
                      speakerId: speakerId ?? undefined,
                      meta:
                        meta && typeof meta === "object" && !Array.isArray(meta)
                          ? (meta as Record<string, unknown>)
                          : null,
                    }
                  : m,
              ),
            };
          });
        };

        const res = await fetch(`${endpoint}?stream=1`, {
          method: "POST",
          headers: {
            Accept: "text/event-stream",
          },
          body: form,
        });

        if (!res.ok || !res.body) {
          let detail = `HTTP ${res.status}`;
          try {
            const body = (await res.json().catch(() => null)) as
              | { error?: unknown; detail?: unknown }
              | null;
            const msg = String(body?.error ?? body?.detail ?? "").trim();
            if (msg) detail = msg;
          } catch {
            // ignore
          }
          finalize(`（応答エラー: ${detail}）`, {
            status: res.status,
            source: "chat_stream_request",
          });
          return;
        }

        const reader = res.body.getReader();

        // ai message
        const decoder = new TextDecoder();
        let buf = "";
        let doneReceived = false;

        while (!doneReceived) {
          const { value, done } = await reader.read();
          if (done) break;
          buf += decoder.decode(value, { stream: true });

          while (true) {
            const idx = buf.indexOf("\n\n");
            if (idx === -1) break;
            const block = buf.slice(0, idx);
            buf = buf.slice(idx + 2);
            if (!block.trim()) continue;

            const lines = block.split("\n");
            let event = "message";
            const dataLines: string[] = [];
            for (const line of lines) {
              if (line.startsWith("event:")) event = line.slice(6).trim();
              else if (line.startsWith("data:"))
                dataLines.push(line.slice(5).trim());
            }
            const dataRaw = dataLines.join("\n");

            if (event === "delta") {
              try {
                const parsed = JSON.parse(dataRaw);
                appendDelta(typeof parsed?.text === "string" ? parsed.text : "");
              } catch {
                appendDelta(dataRaw);
              }
            } else if (event === "done") {
              try {
                const parsed = JSON.parse(dataRaw);
                const reply =
                  typeof parsed?.reply === "string"
                    ? parsed.reply
                    : typeof parsed?.content === "string"
                      ? parsed.content
                      : "";
                const meta = parsed?.meta ?? null;
                finalize(
                  reply && reply.trim().length > 0
                    ? reply
                    : "（応答生成が一時的に利用できません。）",
                  meta,
                );
              } catch {
                finalize("（応答生成が一時的に利用できません。）", null);
              }
              doneReceived = true;
              break;
            } else if (event === "error") {
              console.warn("[talk stream error]", dataRaw);
            }
          }
        }
      } catch (e) {
        const message =
          e instanceof Error && e.message.trim()
            ? e.message.trim()
            : "stream transport failed";
        setMessagesBySession((prev) => {
          const list = prev[activeSessionId] ?? [];
          return {
            ...prev,
            [activeSessionId]: list.map((m) =>
              aiId && m.id === aiId
                ? {
                    ...m,
                    content: `（接続エラー: ${message}）`,
                    meta: { source: "chat_stream_transport" },
                  }
                : m,
            ),
          };
        });
      } finally {
        setIsRunningBySession((prev) => ({
          ...prev,
          [activeSessionId]: false,
        }));
      }
    },
    [
      activeSessionId,
      activeCharacterId,
      appendMessage,
      activeSession?.mode,
      setMessagesBySession,
      setSessions,
    ],
  );

  const handleContinueScene = useCallback(async () => {
    if (!activeSessionId || !activeCharacterId) return;

    setIsRunningBySession((prev) => ({
      ...prev,
      [activeSessionId]: true,
    }));

    try {
      const form = new FormData();
      form.append("characterId", activeCharacterId);
      form.append("text", "そのまま続けて");
      form.append("sceneMode", "continue");
      form.append("sceneTurnCount", "2");

      const res = await fetch(`/api/session/${activeSessionId}/message`, {
        method: "POST",
        body: form,
      });
      if (!res.ok) {
        const detail = await res.text().catch(() => "");
        throw new Error(detail || `HTTP ${res.status}`);
      }

      const data = (await res.json()) as {
        messages?: Array<{ id?: string; role?: "ai"; content?: string; speaker_id?: string | null; meta?: Record<string, unknown> | null }>;
        meta?: Record<string, unknown> | null;
      };
      const turns = Array.isArray(data.messages) ? data.messages : [];
      if (turns.length === 0) return;

      setMessagesBySession((prev) => {
        const current = prev[activeSessionId] ?? [];
        const appended = turns.map((turn, index) => ({
          id: typeof turn.id === "string" && turn.id ? turn.id : crypto.randomUUID(),
          role: "ai" as const,
          content: String(turn.content ?? ""),
          speakerId:
            typeof turn.speaker_id === "string" && turn.speaker_id
              ? turn.speaker_id
              : inferSpeakerCharacterId(turn.meta ?? null, activeCharacterId) ?? undefined,
          attachments: [],
          meta: (turn.meta ?? null) as Record<string, unknown> | null,
        }));
        return {
          ...prev,
          [activeSessionId]: [...current, ...appended],
        };
      });
      const sceneState =
        data.meta && typeof data.meta === "object" && !Array.isArray(data.meta)
          ? (data.meta as Record<string, unknown>).scene_state
          : null;
      if (sceneState && typeof sceneState === "object" && !Array.isArray(sceneState)) {
        setSessions((prev) =>
          prev.map((session) =>
            session.id === activeSessionId
              ? {
                  ...session,
                  meta: {
                    ...(session.meta ?? {}),
                    scene_state: sceneState as Record<string, unknown>,
                  },
                }
              : session,
          ),
        );
      }
    } catch (error) {
      console.error("[touhou] continue scene failed:", error);
    } finally {
      setIsRunningBySession((prev) => ({
        ...prev,
        [activeSessionId]: false,
      }));
    }
  }, [activeSessionId, activeCharacterId]);

  useEffect(() => {
    if (activeSession?.mode !== "group") {
      setSceneAutoRun(false);
    }
  }, [activeSession?.id, activeSession?.mode]);

  useEffect(() => {
    if (!sceneAutoRun) return;
    if (!activeSessionId || activeSession?.mode !== "group") return;
    if (isRunningBySession[activeSessionId] ?? false) return;

    const timer = window.setTimeout(() => {
      void handleContinueScene();
    }, 1400);
    return () => window.clearTimeout(timer);
  }, [sceneAutoRun, activeSessionId, activeSession?.mode, isRunningBySession, handleContinueScene]);

  /* =========================
     Render
  ========================= */

  const activeMessages =
    activeSessionId != null ? (messagesBySession[activeSessionId] ?? []) : [];

  const attachmentAdapter = useMemo(() => new TouhouUploadAttachmentAdapter(), []);

  const store = useMemo<ExternalStoreAdapter<Message>>(
    () => ({
      isDisabled: !activeSessionId || !activeCharacterId,
      isRunning:
        !!activeSessionId && (isRunningBySession[activeSessionId] ?? false),
      isLoading: false,
      messages: activeMessages,
      convertMessage: (m) => talkMessageToThreadMessageLike(m),
      setMessages: undefined,
      onNew: async (message: AppendMessage) => {
        if (!activeSessionId || !activeCharacterId) return;
        if (message.role !== "user") return;

        const text = extractTextFromThreadMessageContent(message.content);
        const auiAttachments = (message.attachments ??
          []) as unknown as CompleteAttachment[];
        const files = auiAttachments
          .map((a) => a.file)
          .filter(Boolean) as File[];

        await handleSendTalk({ text, files, attachments: auiAttachments });
      },
      adapters: {
        attachments: attachmentAdapter,
        threadList: {
          threadId: activeSessionId ?? undefined,
          isLoading: !sessionsLoaded,
          threads: sessions.map((s) => ({
            status: "regular",
            id: s.id,
            remoteId: s.id,
            externalId: s.id,
            title: s.title,
          })),
          archivedThreads: [],
          onSwitchToNewThread: async () => {
            setIsCreateThreadDialogOpen(true);
          },
          onSwitchToThread: async (threadId: string) => {
            selectSession(threadId);
          },
          onRename: async (threadId: string, newTitle: string) => {
            await handleRenameSession(threadId, newTitle);
          },
          onDelete: async (threadId: string) => {
            await handleDeleteSession(threadId);
          },
          onArchive: undefined,
          onUnarchive: undefined,
        },
      },
      unstable_capabilities: { copy: true },
      onEdit: undefined,
      onReload: undefined,
      onResume: undefined,
      onCancel: undefined,
    }),
    [
      activeCharacterId,
      activeMessages,
      activeSessionId,
      attachmentAdapter,
      createSession,
      createSessionForCharacter,
      handleDeleteSession,
      handleRenameSession,
      handleSendTalk,
      isRunningBySession,
      selectSession,
      sessions,
      sessionsLoaded,
    ],
  );

  const runtime = useExternalStoreRuntime(store);

  // Desktop (Electron) popout avatar: notify once on assistant completion so the avatar-only window can speak/lip-sync.
  const popoutTtsPrevRunningRef = useRef(false);
  const popoutTtsLastIdRef = useRef<string | null>(null);
  useEffect(() => {
    if (!isElectron) return;
    if (!activeSessionId) return;

    const isRunning = isRunningBySession[activeSessionId] ?? false;
    const wasRunning = popoutTtsPrevRunningRef.current;
    popoutTtsPrevRunningRef.current = isRunning;

    if (!wasRunning || isRunning) return;

    const lastAi = [...activeMessages].reverse().find((m) => m?.role === "ai") ?? null;
    const id = String(lastAi?.id ?? "").trim() || null;
    const text = String(lastAi?.content ?? "").trim();
    const readingText = String((lastAi?.meta as any)?.tts?.reading_text ?? "").trim() || null;
    const speakerCharacterId =
      typeof lastAi?.speakerId === "string" && lastAi.speakerId.trim()
        ? lastAi.speakerId.trim()
        : activeCharacterId;
    if (!speakerCharacterId) return;
    if (!text) return;
    if (id && popoutTtsLastIdRef.current === id) return;
    popoutTtsLastIdRef.current = id;

    const detail = { characterId: speakerCharacterId, messageId: id, text, readingText };

    try {
      window.dispatchEvent(new CustomEvent("touhou-desktop:tts-speak", { detail }));
    } catch {
      // ignore
    }

    try {
      if (typeof BroadcastChannel !== "undefined") {
        const ch = new BroadcastChannel("touhou-desktop-tts");
        ch.postMessage({ type: "speak", ...detail });
        ch.close();
      }
    } catch {
      // ignore
    }
  }, [isElectron, activeSessionId, activeCharacterId, activeMessages, isRunningBySession]);

  useLayoutEffect(() => {
    const root = document.documentElement;
    const vv = window.visualViewport ?? null;

    const update = () => {
      const height = vv?.height ?? window.innerHeight;
      const offsetTop = vv?.offsetTop ?? 0;
      const bottomOcclusion = Math.max(
        0,
        window.innerHeight - (offsetTop + height),
      );
      root.style.setProperty("--app-vvh", `${height}px`);
      root.style.setProperty("--app-vvo", `${offsetTop}px`);
      root.style.setProperty("--app-vvb", `${bottomOcclusion}px`);
    };

    update();
    vv?.addEventListener("resize", update);
    vv?.addEventListener("scroll", update);
    window.addEventListener("resize", update);

    return () => {
      vv?.removeEventListener("resize", update);
      vv?.removeEventListener("scroll", update);
      window.removeEventListener("resize", update);
    };
  }, []);

  useEffect(() => {
    const mq = window.matchMedia("(max-width: 1024px)");
    if (!mq.matches) return;

    const root = document.documentElement;
    const vv = window.visualViewport ?? null;

    const prevOverflow = document.body.style.overflow;
    const prevPosition = document.body.style.position;
    const prevWidth = document.body.style.width;
    const prevHeight = document.body.style.height;
    const prevTop = document.body.style.top;
    const prevRootOverflow = root.style.overflow;
    const prevRootHeight = root.style.height;
    const prevOverscroll = root.style.overscrollBehaviorY;

    const scrollY = window.scrollY;

    document.body.style.overflow = "hidden";
    document.body.style.position = "fixed";
    document.body.style.width = "100%";
    document.body.style.height = "100%";
    document.body.style.top = `-${scrollY}px`;

    root.style.overflow = "hidden";
    root.style.height = "100%";
    root.style.overscrollBehaviorY = "none";

    const keepTop = () => {
      if (window.scrollY !== 0) window.scrollTo(0, 0);
      if (document.body.scrollTop !== 0) document.body.scrollTop = 0;
      if (root.scrollTop !== 0) root.scrollTop = 0;
    };

    const onFocusIn = (e: FocusEvent) => {
      const t = e.target as HTMLElement | null;
      if (!t) return;
      const tag = t.tagName;
      if (tag === "TEXTAREA" || tag === "INPUT" || t.isContentEditable) {
        setTimeout(keepTop, 0);
      }
    };

    keepTop();
    vv?.addEventListener("resize", keepTop);
    vv?.addEventListener("scroll", keepTop);
    window.addEventListener("scroll", keepTop, { passive: true });
    window.addEventListener("focusin", onFocusIn);

    return () => {
      document.body.style.overflow = prevOverflow;
      document.body.style.position = prevPosition;
      document.body.style.width = prevWidth;
      document.body.style.height = prevHeight;
      document.body.style.top = prevTop;

      root.style.overflow = prevRootOverflow;
      root.style.height = prevRootHeight;
      root.style.overscrollBehaviorY = prevOverscroll;

      vv?.removeEventListener("resize", keepTop);
      vv?.removeEventListener("scroll", keepTop);
      window.removeEventListener("scroll", keepTop);
      window.removeEventListener("focusin", onFocusIn);

      window.scrollTo(0, scrollY);
    };
  }, []);

  return (
    <AssistantRuntimeProvider runtime={runtime}>
      <TouhouUiProvider
        value={{
          activeSessionId,
          sessions: sessions.map((s) => ({
            id: s.id,
            characterId: s.characterId,
            mode: s.mode,
            participants: s.participants,
            meta: s.meta,
          })),
          characters: CHARACTERS,
          visibleCharacters,
          openCreateThreadDialog: () => setIsCreateThreadDialogOpen(true),
          createThreadForCharacter: createSessionForCharacter,
          createThreadForCharacters: createSessionForCharacters,
        }}
      >
        <SidebarProvider
          style={
            {
              "--sidebar-width": charactersCollapsed ? "17rem" : "26rem",
            } as React.CSSProperties
          }
        >
          <AutoCloseSidebarOnRequest requestId={sidebarCloseRequestId} />
          <div className="flex h-full w-full min-h-0 overflow-hidden bg-background text-foreground transition-colors duration-300">
            <TouhouSidebar
                variant="floating"
                className="z-20"
                visibleCharacters={visibleCharacters}
                activeCharacterId={activeCharacterId}
                onSelectCharacter={selectCharacter}
              activeSessionId={activeSessionId}
              onImportArtifactFile={handleImportArtifactFile}
              onExportActiveSession={handleExportActiveSession}
              artifactBusy={artifactBusy}
              charactersCollapsed={charactersCollapsed}
              onCharactersCollapsedChange={setCharactersCollapsed}
              createThreadDialogOpen={isCreateThreadDialogOpen}
              onCreateThreadDialogOpenChange={setIsCreateThreadDialogOpen}
              recentCharacterIds={recentCharacterIds}
            />

            <SidebarInset className="relative flex min-h-0 flex-col overflow-hidden">
              {/* Background */}
              <div
                className="absolute inset-0 bg-cover bg-center bg-no-repeat opacity-70"
                style={{
                  backgroundImage: resolvedChatBackground
                    ? `url('${resolvedChatBackground}')`
                    : undefined,
                  filter: "blur(1px) brightness(0.9)",
                }}
              />

              {/* Header */}
              <header className="sticky top-0 z-30 flex min-h-16 shrink-0 items-center gap-2 border-b px-4 py-2 bg-background/70 backdrop-blur">
                {activeCharacter?.color?.accent && (
                  <div
                    className={`absolute inset-0 -z-10 bg-gradient-to-br opacity-60 ${activeCharacter.color.accent}`}
                  />
                )}

                <SidebarTrigger />
                <Separator orientation="vertical" className="mr-2 h-4" />
                <div className="min-w-0 flex flex-1 items-center gap-3 overflow-visible">
                  <div className="relative flex min-w-0 flex-1 items-center gap-2 overflow-visible">
                    <div className="max-w-[16rem] truncate font-gensou text-sm">
                      {activeSession?.mode === "group"
                        ? activeSession?.title ?? chatUi.room
                        : activeCharacter?.name ?? chatUi.chooseCharacter}
                    </div>
                    {activeSessionId ? (
                      <div className="flex shrink-0 items-center gap-2">
                        <button
                          type="button"
                          onClick={() => setShowSessionMeta((v) => !v)}
                          className="inline-flex h-7 w-7 items-center justify-center rounded-full border border-border/60 bg-background/60 text-foreground/80 transition hover:bg-background/80"
                          title={showSessionMeta ? chatUi.sessionHide : chatUi.sessionShow}
                          aria-label={showSessionMeta ? chatUi.sessionHide : chatUi.sessionShow}
                        >
                          <InfoIcon className="size-3.5" />
                        </button>
                        {activeSession?.mode === "group" ? (
                          <button
                            type="button"
                            onClick={() => setShowGroupRoster((v) => !v)}
                            className="inline-flex items-center gap-1.5 rounded-full border border-border/60 bg-background/60 px-2.5 py-1 text-[11px] text-foreground/85 transition hover:bg-background/80"
                            title={showGroupRoster ? chatUi.groupRosterHide : chatUi.groupRosterShow}
                            aria-label={showGroupRoster ? chatUi.groupRosterHide : chatUi.groupRosterShow}
                          >
                            <UsersIcon className="size-3.5" />
                            <span>{chatUi.cast}</span>
                          </button>
                        ) : null}
                      </div>
                    ) : null}
                    {showSessionMeta && activeSessionId ? (
                      <div className="absolute left-0 top-full z-20 mt-2 inline-flex max-w-[min(44vw,28rem)] items-center gap-2 rounded-xl border border-border/70 bg-background/90 px-3 py-1.5 text-xs text-muted-foreground shadow-sm backdrop-blur">
                        <span className="shrink-0 font-medium text-foreground/90">{t("chat.sessionId")}</span>
                        <span className="min-w-0 truncate font-mono">{activeSessionId}</span>
                      </div>
                    ) : null}
                    {showGroupRoster && activeSession?.mode === "group" ? (
                      <div className="absolute left-0 top-full z-20 mt-2 w-[min(26rem,calc(100vw-3rem))] rounded-2xl border border-border/70 bg-background/90 p-3 shadow-lg backdrop-blur">
                        <div className="mb-2 text-xs font-medium text-foreground/90">{chatUi.participants}</div>
                        <div className="space-y-2">
                          {activeParticipants.map((participant) => {
                            const key = participant.id;
                            const isAi = participant.kind === "ai_character";
                            const ch = isAi ? CHARACTERS[participant.characterId] : null;
                            return (
                              <div
                                key={key}
                                className="flex items-center gap-2 rounded-xl border border-border/50 bg-background/45 px-3 py-2 text-xs text-foreground/85"
                              >
                                {isAi ? <BotIcon className="size-3.5 shrink-0" /> : <UserIcon className="size-3.5 shrink-0" />}
                                <div className="min-w-0 flex-1">
                                  <div className="truncate font-medium text-foreground/90">
                                    {isAi ? (ch?.name ?? participant.displayName) : (participant.isSelf ? t("common.you") : participant.displayName)}
                                  </div>
                                  <div className="truncate text-[11px] text-muted-foreground">
                                    {isAi ? chatUi.character : (lang === "ja" ? "ユーザー" : "User")}
                                  </div>
                                </div>
                              </div>
                            );
                          })}
                        </div>
                      </div>
                    ) : null}
                  </div>

                  {activeSession?.mode === "group" && activeSceneState ? (
                    <div className="hidden min-w-0 flex-1 flex-wrap items-center justify-end gap-1.5 overflow-hidden md:flex">
                      {typeof activeSceneState.initiative_character_id === "string" ? (
                        <span className="inline-flex items-center rounded-full border border-border/50 bg-background/35 px-2 py-1 text-[11px] text-muted-foreground">
                          {chatUi.lead}: {CHARACTERS[activeSceneState.initiative_character_id]?.name ?? activeSceneState.initiative_character_id}
                        </span>
                      ) : null}
                      {typeof activeSceneState.last_topic_hint === "string" && activeSceneState.last_topic_hint.trim() ? (
                        <span className="inline-flex items-center rounded-full border border-border/50 bg-background/35 px-2 py-1 text-[11px] text-muted-foreground">
                          {chatUi.topic}: {activeSceneState.last_topic_hint}
                        </span>
                      ) : null}
                      {typeof activeSceneState.last_turn_count === "number" ? (
                        <span className="inline-flex items-center rounded-full border border-border/50 bg-background/35 px-2 py-1 text-[11px] text-muted-foreground">
                          {chatUi.recentTurns}: {activeSceneState.last_turn_count}
                        </span>
                      ) : null}
                      {typeof activeSceneState.next_speaker_hint === "string" ? (
                        <span className="inline-flex items-center rounded-full border border-border/50 bg-background/35 px-2 py-1 text-[11px] text-muted-foreground">
                          {chatUi.nextCandidate}: {CHARACTERS[activeSceneState.next_speaker_hint]?.name ?? activeSceneState.next_speaker_hint}
                        </span>
                      ) : null}
                    </div>
                  ) : null}
                </div>

                {activeSession?.mode === "group" ? (
                  <div className="ml-2 flex items-center gap-2">
                    <button
                      type="button"
                      onClick={() => void handleContinueScene()}
                      disabled={!activeSessionId || (isRunningBySession[activeSessionId] ?? false)}
                      className="inline-flex items-center gap-1 rounded-md border border-border/60 bg-background/40 px-2 py-1 text-xs text-foreground/80 hover:bg-background/60 disabled:opacity-40"
                      title={chatUi.continueTitle}
                    >
                      <FastForwardIcon className="size-3.5" />
                      <span>{chatUi.continue}</span>
                    </button>
                    <button
                      type="button"
                      onClick={() => setSceneAutoRun((v) => !v)}
                      disabled={!activeSessionId}
                      className={`inline-flex items-center gap-1 rounded-md border px-2 py-1 text-xs ${
                        sceneAutoRun
                          ? "border-emerald-500/60 bg-emerald-500/15 text-emerald-200"
                          : "border-border/60 bg-background/40 text-foreground/80 hover:bg-background/60"
                      } disabled:opacity-40`}
                      title={chatUi.autoRunTitle}
                    >
                      <UsersIcon className="size-3.5" />
                      <span>{sceneAutoRun ? chatUi.autoRunOn : chatUi.autoRunOff}</span>
                    </button>
                  </div>
                ) : null}

                <ThreadSearch activeSessionId={activeSessionId} />

              </header>

              {/* Chat */}
              <div className="relative z-10 min-h-0 flex-1 overflow-hidden">
                {activeSessionId ? (
                  <>
                    {isElectron ? (
                      <div aria-hidden className="hidden">
                        {activeAiCharacterIds.map((characterId) => (
                          <DesktopLiveAvatar
                            key={`tts-driver-${characterId}`}
                            characterId={characterId}
                            autoSpeak={false}
                          />
                        ))}
                      </div>
                    ) : null}
                    {isElectron &&
                    desktopAvatarVisible &&
                    desktopAvatarAvailable &&
                    !desktopAvatarPopoutActive &&
                    desktopAvatarLayout === "dock" ? (
                      <div ref={dockWrapRef} className="flex h-full min-h-0 w-full">
                        <div className="min-w-0 flex-1 overflow-hidden">
                          <Thread />
                        </div>
                        <div
                          className="hidden h-full w-2 shrink-0 cursor-col-resize bg-transparent lg:block"
                          role="separator"
                          aria-orientation="vertical"
                          aria-label={chatUi.resizeAvatarPanel}
                          onPointerDown={(e) => {
                            if (e.button !== 0) return;
                            dockDragRef.current = {
                              pointerId: e.pointerId,
                              startX: e.clientX,
                              startWidth: desktopAvatarDockWidth,
                            };
                            try {
                              (e.currentTarget as HTMLDivElement).setPointerCapture(e.pointerId);
                            } catch {
                              // ignore
                            }
                          }}
                          onDoubleClick={() => setDesktopAvatarDockWidth(360)}
                          title={chatUi.resizeByDrag}
                        >
                          <div className="mx-auto h-full w-px bg-border/60" />
                        </div>
                        <aside
                          className="hidden h-full shrink-0 border-l border-border/60 bg-background/20 backdrop-blur lg:block"
                          style={{ width: `${desktopAvatarDockWidth}px` }}
                        >
                          <DesktopLiveAvatar
                            characterId={activeCharacterId}
                            className="h-full w-full"
                            autoSpeak={false}
                          />
                        </aside>
                      </div>
                    ) : (
                      <>
                        <div className="flex h-full min-h-0 w-full">
                          <div className="min-w-0 flex-1 overflow-hidden">
                            <Thread />
                          </div>
                          {isElectron ? (
                            <aside className="hidden h-full w-[420px] shrink-0 border-l border-border/60 bg-background/25 backdrop-blur lg:flex xl:w-[560px] 2xl:w-[680px]">
                              <div className="flex h-full w-full flex-col p-4">
                                <div className="flex min-h-0 flex-1 items-center justify-center rounded-[28px] border border-border/60 bg-gradient-to-b from-background/55 to-background/20 p-4">
                                  <div className="flex h-full w-full items-center justify-center">
                                    <div className="flex aspect-[3/4] h-full w-full max-h-[min(78vh,960px)] max-w-[560px] flex-col items-center justify-center rounded-[28px] border border-dashed border-border/70 bg-background/35 px-6 py-8 text-center shadow-sm">
                                      <div className="flex h-24 w-24 items-center justify-center rounded-full border border-dashed border-border/70 bg-background/45 text-3xl">
                                        3D
                                      </div>
                                      <div className="mt-4">
                                        <div className="text-sm font-medium text-foreground">
                                          {activeCharacter?.name ?? chatUi.character}
                                        </div>
                                        <div className="mt-1 text-xs text-muted-foreground">
                                          {chatUi.avatarArea}
                                        </div>
                                      </div>
                                    </div>
                                  </div>
                                </div>
                              </div>
                            </aside>
                          ) : null}
                        </div>
                        {isElectron &&
                        desktopAvatarVisible &&
                        desktopAvatarAvailable &&
                        !desktopAvatarPopoutActive ? (
                          <div ref={pipWrapRef} className="absolute inset-0 pointer-events-none">
                            <div
                              className="pointer-events-auto absolute hidden overflow-hidden rounded-2xl border bg-background/30 shadow-xl backdrop-blur lg:block"
                              style={{
                                left: `${desktopAvatarPipRect.x}px`,
                                top: `${desktopAvatarPipRect.y}px`,
                                width: `${desktopAvatarPipRect.w}px`,
                                height: `${desktopAvatarPipRect.h}px`,
                              }}
                            >
                              <div
                                className="flex h-8 w-full items-center justify-between gap-2 border-b border-border/60 bg-background/40 px-2 text-xs text-foreground/80"
                                onPointerDown={(e) => {
                                  if (e.button !== 0) return;
                                  pipDragRef.current = {
                                    kind: "move",
                                    pointerId: e.pointerId,
                                    startX: e.clientX,
                                    startY: e.clientY,
                                    startRect: desktopAvatarPipRect,
                                  };
                                  try {
                                    (e.currentTarget as HTMLDivElement).setPointerCapture(e.pointerId);
                                  } catch {
                                    // ignore
                                  }
                                }}
                                onDoubleClick={() => {
                                  setDesktopAvatarPipRect((prev) =>
                                    clampPipRect({
                                      ...prev,
                                      w: 340,
                                      h: 420,
                                    }),
                                  );
                                }}
                                title={chatUi.dragMove}
                              >
                                <div className="min-w-0 truncate">
                                  {activeCharacter?.name ?? chatUi.avatar}
                                </div>
                                <button
                                  type="button"
                                  className="rounded-md px-1.5 py-0.5 text-foreground/70 hover:bg-background/50"
                                  onClick={() => setDesktopAvatarVisible(false)}
                                  title={chatUi.hideAvatar}
                                >
                                  ×
                                </button>
                              </div>

                              <DesktopLiveAvatar
                                characterId={activeCharacterId}
                                className="h-[calc(100%-2rem)] w-full"
                                autoSpeak={false}
                              />

                              <div
                                className="absolute bottom-1 right-1 h-4 w-4 cursor-nwse-resize rounded-sm border border-border/60 bg-background/50"
                                onPointerDown={(e) => {
                                  if (e.button !== 0) return;
                                  pipDragRef.current = {
                                    kind: "resize",
                                    pointerId: e.pointerId,
                                    startX: e.clientX,
                                    startY: e.clientY,
                                    startRect: desktopAvatarPipRect,
                                  };
                                  try {
                                    (e.currentTarget as HTMLDivElement).setPointerCapture(e.pointerId);
                                  } catch {
                                    // ignore
                                  }
                                }}
                                title={chatUi.dragResize}
                              />
                            </div>
                          </div>
                        ) : null}
                      </>
                    )}
                  </>
                ) : (
                  <div className="flex h-full items-center justify-center text-muted-foreground">
                    {chatUi.empty}
                  </div>
                )}
              </div>
            </SidebarInset>
          </div>
        </SidebarProvider>
      </TouhouUiProvider>
    </AssistantRuntimeProvider>
  );
}

