export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Legacy implementation retained as a fallback during the strangler migration.

import { NextRequest, NextResponse } from "next/server";
import "server-only";
import { supabaseAdmin, type supabaseServer } from "@/lib/supabase-server";

import {
  buildTouhouPersonaSystem,
  genParamsFor,
} from "@/lib/touhouPersona";
import { CHARACTERS } from "@/data/characters";
import type { TouhouChatMode } from "@/lib/touhouPersona";
import {
  isRecord,
  mergeMeta,
  sha256Hex,
} from "@/lib/server/session-message/meta";
import {
  enforceOrigin,
  wantsStream,
} from "@/lib/server/session-message/request";
import type {
  PersonaChatResponse,
  PersonaIntentResponse,
  Phase04LinkAnalysis,
} from "@/lib/server/session-message-v2/types";

import {
  normalizePersonaIntent,
  shouldUseDirectorOverlay,
  fetchPersonaIntent,
  toSse,
  effectiveOutputStyle,
  reimuDirectorOverlay,
} from "@/lib/server/session-message-v2/director";

import {
  isFirstAssistantTurn,
  buildRecentUserText,
  sanitizeReplyByContext,
} from "@/lib/server/session-message-v2/sanitize";

import {
  uploadFilesForSdk,
  analyzeLinks,
  autoBrowseFromText,
} from "@/lib/server/session-message-v2/retrieval";

import {
  retrievalSystemHint,
  saveUserMessage,
  saveAssistantMessage,
  saveStateSnapshot,
} from "@/lib/server/session-message-v2/persistence";

import {
  buildImplicitAttachmentMessage,
  parseSessionMessageRequestBody,
} from "@/lib/server/session-message-v2/request-body";

import {
  loadRelationshipAndMemoryBestEffort,
  buildRelationshipMemoryOverlay,
  updateRelationshipAndMemoryBestEffort,
} from "@/lib/server/session-message-v2/relationship";

import {
  loadWorldPromptContextBestEffort,
  buildWorldOverlay,
} from "@/lib/server/session-message-v2/world";

import { buildSessionMessageContext } from "@/lib/server/session-message-v2/context";

import { handleNonStreamSessionMessage } from "@/lib/server/session-message-v2/respond";

import { handleStreamSessionMessage } from "@/lib/server/session-message-v2/stream";
import { isDesktopRuntimeEnabled } from "@/lib/desktop/desktopPaths";
import { loadCharacterSettings } from "@/lib/desktop/desktopSettingsStore";
import {
  chooseGroupSpeaker,
  findMentionedGroupSpeakerIds,
  getAiParticipants,
  getLastSpeakerCharacterId,
  getRecentSpeakerCharacterIds,
  normalizeRoomParticipants,
  withLastSpeakerCharacterId,
  withRecentSpeakerCharacterIds,
} from "@/lib/rooms/participants";

// Character persona is injected via `persona_system` (system-side) to avoid dilution over long chats.

function buildTurnTuningLines(params: {
  chatMode: TouhouChatMode;
  characterId: string;
  text: string;
  coreHistory: Array<{ role: "user" | "assistant"; content: string }>;
}) {
  const lowerRecentUser = buildRecentUserText({
    history: params.coreHistory,
    currentUserText: params.text,
  });
  const donationKeywords = ["donation", "offering", "saisen", "tips"];
  const userMentionsDonation = donationKeywords.some((keyword) =>
    lowerRecentUser.includes(keyword),
  );
  const assistantRecentText = params.coreHistory
    .filter((m) => m.role === "assistant")
    .slice(-3)
    .map((m) => String(m.content ?? ""))
    .join("\n")
    .toLowerCase();
  const assistantRecentlyMentionedDonation = donationKeywords.some((keyword) =>
    assistantRecentText.includes(keyword),
  );

  const turnTuningLines: string[] = [];
  if (
    params.chatMode === "roleplay" &&
    params.characterId === "reimu" &&
    !userMentionsDonation
  ) {
    if (assistantRecentlyMentionedDonation) {
      turnTuningLines.push("- Do not repeat donation jokes this turn.");
    } else {
      turnTuningLines.push("- Donation jokes are allowed at most once this turn.");
    }
  }
  return turnTuningLines;
}

function shouldLoadRelationshipOverlay(params: {
  enabled: boolean;
  chatMode: TouhouChatMode;
  isSeedTurn: boolean;
}) {
  if (!params.enabled) return false;
  const mode = String(
    process.env.TOUHOU_RELATIONSHIP_OVERLAY_MODE ?? "roleplay_non_seed",
  )
    .trim()
    .toLowerCase();
  if (mode === "off") return false;
  if (mode === "always") return true;
  if (mode === "roleplay") return params.chatMode === "roleplay";
  return params.chatMode === "roleplay" && !params.isSeedTurn;
}

function shouldLoadWorldOverlay(params: {
  enabled: boolean;
  chatMode: TouhouChatMode;
  layer: string | null;
  location: string | null;
}) {
  if (!params.enabled) return false;
  if (!params.layer) return false;
  const mode = String(
    process.env.TOUHOU_WORLD_PROMPT_MODE ?? "roleplay",
  )
    .trim()
    .toLowerCase();
  if (mode === "off") return false;
  if (mode === "always") return true;
  if (mode === "with_location") return Boolean(params.location);
  return params.chatMode === "roleplay";
}

async function shouldGenerateDesktopTtsReading(params: {
  req: NextRequest;
  characterId: string;
}) {
  const ua = String(params.req.headers.get("user-agent") ?? "");
  if (!ua.includes("Electron")) return false;
  if (!isDesktopRuntimeEnabled()) return false;

  try {
    const settings = await loadCharacterSettings(params.characterId);
    if (!settings) return false;
    const mode = settings.tts?.mode ?? "none";
    if (mode === "browser") return true;
    if (mode === "aquestalk") return !!settings.tts?.aquestalk?.enabled;
    return false;
  } catch {
    return false;
  }
}

function lastAssistantAskedQuestion(
  history: Array<{ role: "user" | "assistant"; content: string }>,
) {
  for (let i = history.length - 1; i >= 0; i -= 1) {
    const item = history[i];
    if (item?.role !== "assistant") continue;
    return /[?\uFF1F]\s*$/u.test(String(item.content ?? "").trim());
  }
  return false;
}

function containsAnyCue(text: string, needles: string[]) {
  const normalized = String(text ?? "").toLowerCase();
  return needles.some((needle) => normalized.includes(needle.toLowerCase()));
}

function shouldFetchDirectorIntentForTurn(params: {
  characterId: string;
  chatMode: TouhouChatMode;
  isSeedTurn: boolean;
  text: string;
  fileCount: number;
  urlCount: number;
  history: Array<{ role: "user" | "assistant"; content: string }>;
}) {
  if (
    !shouldUseDirectorOverlay({
      characterId: params.characterId,
      chatMode: params.chatMode,
    })
  ) {
    return false;
  }
  const mode = String(
    process.env.TOUHOU_DIRECTOR_INTENT_MODE ?? "selective",
  )
    .trim()
    .toLowerCase();
  if (mode === "off") return false;
  if (mode === "always") return true;

  const text = String(params.text ?? "").trim();
  if (!text) return false;
  if (params.isSeedTurn) return true;
  if (params.fileCount > 0 || params.urlCount > 0) return true;
  if (text.length <= 24) return true;
  if (/[?\uFF1F]\s*$/u.test(text)) return true;
  if (lastAssistantAskedQuestion(params.history) && text.length <= 120) return true;
  return containsAnyCue(text, [
    "\u3069\u3046\u3059\u308b",
    "\u3069\u3046\u3057\u3088\u3046",
    "\u3069\u3046\u3057\u305f\u3089",
    "\u3069\u3046\u3059\u308c\u3070",
    "\u3069\u3063\u3061",
    "\u3069\u308c",
    "\u3069\u306e",
    "\u3053\u308c\u3067\u3044\u3044",
    "\u4efb\u305b\u308b",
    "\u304a\u307e\u304b\u305b",
    "\u304a\u3059\u3059\u3081",
    "\u8ff7\u3063\u3066\u308b",
    "\u8ff7\u3046",
    "\u7d9a\u304d",
    "\u6b21\u306f",
    "help me choose",
    "which one",
    "what should",
  ]);
}

function isHighSignalRelationshipTurn(params: {
  text: string;
  chatMode: TouhouChatMode;
  fileCount: number;
  urlCount: number;
}) {
  const text = String(params.text ?? "").trim();
  if (!text) return false;
  if (params.fileCount > 0 || params.urlCount > 0) return true;
  if (text.length >= 180) return true;
  if (params.chatMode === "roleplay" && text.length >= 120) return true;
  return containsAnyCue(text, [
    "\u76f8\u8ac7",
    "\u60a9",
    "\u56f0\u3063\u3066",
    "\u3064\u3089",
    "\u8f9b\u3044",
    "\u3057\u3093\u3069",
    "\u4e0d\u5b89",
    "\u6016",
    "\u60b2",
    "\u6012",
    "\u5bc2",
    "\u5b09",
    "\u52a9\u3051\u3066",
    "\u3042\u308a\u304c\u3068\u3046",
    "\u3054\u3081\u3093",
    "\u597d\u304d",
    "\u5acc\u3044",
    "\u4fe1\u3058",
    "\u5927\u4e8b",
    "help",
    "thanks",
    "sorry",
    "love",
    "hate",
    "anxious",
    "upset",
    "sad",
  ]);
}

function shouldUpdateRelationshipForTurn(params: {
  chatMode: TouhouChatMode;
  isSeedTurn: boolean;
  text: string;
  coreHistory: Array<{ role: "user" | "assistant"; content: string }>;
  fileCount: number;
  urlCount: number;
}) {
  const mode = String(
    process.env.TOUHOU_RELATIONSHIP_UPDATE_MODE ?? "important_or_cadence",
  )
    .trim()
    .toLowerCase();
  if (mode === "off") return false;
  if (mode === "always") return true;
  if (params.isSeedTurn) return false;
  if (
    isHighSignalRelationshipTurn({
      text: params.text,
      chatMode: params.chatMode,
      fileCount: params.fileCount,
      urlCount: params.urlCount,
    })
  ) {
    return true;
  }

  const cadenceRaw = Number(process.env.TOUHOU_RELATIONSHIP_UPDATE_CADENCE ?? "4");
  const cadence = Number.isFinite(cadenceRaw)
    ? Math.max(2, Math.min(8, Math.trunc(cadenceRaw)))
    : 4;
  const completedAssistantTurns = params.coreHistory.filter(
    (item) => item.role === "assistant",
  ).length;
  const nextAssistantTurn = completedAssistantTurns + 1;
  return nextAssistantTurn % cadence === 0;
}

function shouldAutoBrowseForTurn(params: {
  text: string;
  chatMode: TouhouChatMode;
  fileCount: number;
  urlCount: number;
}) {
  if (params.fileCount > 0 || params.urlCount > 0) return false;
  const text = String(params.text ?? "").trim();
  if (text.length < 8) return false;
  const explicitResearchCue = containsAnyCue(text, [
    "\u8abf\u3079\u3066",
    "\u691c\u7d22",
    "\u691c\u7d22\u3057\u3066",
    "\u63a2\u3057\u3066",
    "\u78ba\u8a8d\u3057\u3066",
    "\u88cf\u53d6\u308a",
    "\u51fa\u5178",
    "\u30bd\u30fc\u30b9",
    "\u6700\u65b0",
    "\u30cb\u30e5\u30fc\u30b9",
    "\u73fe\u72b6",
    "\u6bd4\u8f03\u3057\u3066",
    "web\u3067",
    "\u30d6\u30e9\u30a6\u30b6\u3067",
    "look up",
    "search",
    "verify",
    "source",
    "latest",
    "news",
  ]);
  if (!explicitResearchCue) return false;
  if (
    params.chatMode === "roleplay" &&
    !containsAnyCue(text, [
      "\u8abf\u3079\u3066",
      "\u691c\u7d22",
      "\u6700\u65b0",
      "\u30cb\u30e5\u30fc\u30b9",
      "look up",
      "search",
      "latest",
      "news",
    ])
  ) {
    return false;
  }
  return true;
}

function isRecordValue(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function resolveRoomSpeaker(params: {
  conv: Record<string, unknown>;
  requestedCharacterId: string;
  text: string;
}) {
  const conv = isRecordValue(params.conv) ? params.conv : {};
  const mode = typeof conv.mode === "string" ? conv.mode : "single";
  const fallbackCharacterId =
    typeof conv.character_id === "string" && conv.character_id.trim()
      ? conv.character_id.trim()
      : params.requestedCharacterId;

  const participants = normalizeRoomParticipants({
    meta: conv.meta ?? null,
    fallbackCharacterId,
  });

  if (mode !== "group") {
    return {
      isGroupRoom: false,
      selectedCharacterId: params.requestedCharacterId,
      roomMetaPatch: null as Record<string, unknown> | null,
    };
  }

  const selectedCharacterId =
    chooseGroupSpeaker({
      text: params.text,
      participants,
      fallbackCharacterId,
      lastSpeakerCharacterId: getLastSpeakerCharacterId(conv.meta ?? null),
      recentSpeakerCharacterIds: getRecentSpeakerCharacterIds(conv.meta ?? null),
    }) ?? params.requestedCharacterId;

  const baseMeta = withLastSpeakerCharacterId(conv.meta ?? null, selectedCharacterId);
  return {
    isGroupRoom: true,
    selectedCharacterId,
    roomMetaPatch: withRecentSpeakerCharacterIds(baseMeta, [
      selectedCharacterId,
      ...getRecentSpeakerCharacterIds(conv.meta ?? null),
    ]),
  };
}

function buildSceneContinuationUserText(params: {
  speakerName: string;
  previousSpeakerName?: string | null;
  turnIndex: number;
  totalTurns: number;
  topicHint?: string | null;
  emphasis?: string | null;
  sourceText?: string | null;
  addressUserDirectly?: boolean;
}) {
  const previous = params.previousSpeakerName
    ? `After ${params.previousSpeakerName}`
    : "Continue the current flow";
  return [
    "[Scene continuation]",
    `${previous}, respond as ${params.speakerName}.`,
    params.sourceText ? `latest_user_message=${params.sourceText}` : null,
    params.addressUserDirectly
      ? "First react directly to the user's latest line in your own voice."
      : "Speak to the room and the other participants, not as a system narrator.",
    "Keep it short, around one to three sentences, but stay in character.",
    "Do not repeat the same point; move the room forward a little.",
    params.topicHint ? `topic_hint=${params.topicHint}` : null,
    params.emphasis ? `emphasis=${params.emphasis}` : null,
    `scene_turn=${params.turnIndex + 1}/${params.totalTurns}`,
  ].filter(Boolean).join("\n");
}

function inferSceneTopicHint(text: string, history: Array<{ role: "user" | "assistant"; content: string }>) {
  const current = String(text ?? "").trim();
  if (current && current !== "continue scene") return current.slice(0, 80);
  const lastUser = [...history].reverse().find((item) => item.role === "user" && item.content.trim());
  if (lastUser) return lastUser.content.trim().slice(0, 80);
  const lastAssistant = [...history].reverse().find((item) => item.role === "assistant" && item.content.trim());
  if (lastAssistant) return lastAssistant.content.trim().slice(0, 80);
  return null;
}

function shouldAddThirdSpeaker(params: { text: string; history: Array<{ role: "user" | "assistant"; content: string }>; aiCount: number }) {
  if (params.aiCount < 3) return false;
  const joined = [params.text, ...params.history.slice(-6).map((item) => item.content)].join("\n").toLowerCase();
  const thirdSpeakerKeywords = [
    "compare",
    "comparison",
    "debate",
    "plan",
    "strategy",
    "everyone",
    "all of you",
    "what do you all",
    "all three",
    "each of you",
  ];
  return thirdSpeakerKeywords.some((keyword) => joined.includes(keyword));
}

function shouldAutoGroupBanter(params: {
  text: string;
  participants: ReturnType<typeof getAiParticipants>;
  mentionedCharacterIds: string[];
}) {
  if (params.participants.length < 2) return false;
  const text = String(params.text ?? "").trim();
  if (!text) return false;
  const hasGroupCue = containsAnyCue(text, [
    "\u307f\u3093\u306a\u3067",
    "\u7686\u3067",
    "\u5168\u54e1",
    "\u4e8c\u4eba\u3067",
    "3\u4eba\u3067",
    "\u304a\u4e92\u3044",
    "\u639b\u3051\u5408\u3044",
    "\u4f1a\u8a71\u3057\u3066",
    "\u8a71\u3057\u5408\u3063\u3066",
    "\u305d\u308c\u305e\u308c",
    "\u307f\u3093\u306a",
    "all of you",
    "both of you",
    "talk to each other",
    "chat with each other",
    "everyone",
    "each of you",
    "together",
    "group",
    "banter",
  ]);
  if (params.mentionedCharacterIds.length >= 2) return true;
  if (params.mentionedCharacterIds.length >= 1) return hasGroupCue;
  return hasGroupCue;
}

function resolveAutoGroupTurnCount(params: {
  text: string;
  history: Array<{ role: "user" | "assistant"; content: string }>;
  aiCount: number;
  mentionedCharacterIds: string[];
}) {
  if (
    params.aiCount >= 3 &&
    params.mentionedCharacterIds.length >= 2 &&
    shouldAddThirdSpeaker({
      text: params.text,
      history: params.history,
      aiCount: params.aiCount,
    })
  ) {
    return 3;
  }
  return 2;
}

function buildSceneSpeakerPlan(params: {
  participants: ReturnType<typeof getAiParticipants>;
  text: string;
  history: Array<{ role: "user" | "assistant"; content: string }>;
  requestedTurnCount: number;
  lastSpeakerCharacterId?: string | null;
  recentSpeakerCharacterIds?: string[] | null;
  preferredFirstSpeakerCharacterId?: string | null;
}) {
  const aiParticipants = params.participants;
  const topicHint = inferSceneTopicHint(params.text, params.history);
  const desiredTurns = Math.max(
    2,
    Math.min(
      shouldAddThirdSpeaker({ text: params.text, history: params.history, aiCount: aiParticipants.length }) ? 3 : 2,
      params.requestedTurnCount,
      aiParticipants.length,
    ),
  );

  const selectedCharacterIds: string[] = [];
  let previousSpeakerCharacterId = params.lastSpeakerCharacterId ?? null;
  const rollingRecent = (params.recentSpeakerCharacterIds ?? []).filter(Boolean);

  for (let i = 0; i < desiredTurns; i += 1) {
    const textForChoice =
      i === 0 ? String(params.text ?? "").trim() || "continue scene" : selectedCharacterIds[selectedCharacterIds.length - 1] ?? "continue";
    let nextCharacterId =
      i === 0 && params.preferredFirstSpeakerCharacterId
        ? params.preferredFirstSpeakerCharacterId
        : chooseGroupSpeaker({
            text: textForChoice,
            participants: aiParticipants,
            fallbackCharacterId: aiParticipants[0]?.characterId ?? null,
            lastSpeakerCharacterId: previousSpeakerCharacterId,
            recentSpeakerCharacterIds: rollingRecent,
            excludeCharacterIds: selectedCharacterIds,
          }) ?? aiParticipants[i % aiParticipants.length].characterId;

    if (selectedCharacterIds.includes(nextCharacterId)) {
      const fallback = aiParticipants.find((participant) => !selectedCharacterIds.includes(participant.characterId));
      nextCharacterId = fallback?.characterId ?? nextCharacterId;
    }

    selectedCharacterIds.push(nextCharacterId);
    rollingRecent.unshift(nextCharacterId);
    if (rollingRecent.length > 6) rollingRecent.length = 6;
    previousSpeakerCharacterId = nextCharacterId;
  }

  return {
    selectedCharacterIds,
    topicHint,
    initiativeCharacterId: selectedCharacterIds[0] ?? params.lastSpeakerCharacterId ?? null,
    recentSpeakerCharacterIds: rollingRecent,
  };
}

async function generateSceneContinuationTurns(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  sessionId: string;
  userId: string;
  accessToken: string | null;
  base: string;
  chatMode: TouhouChatMode;
  conv: Record<string, unknown>;
  coreHistory: Array<{ role: "user" | "assistant"; content: string }>;
  layer: string | null;
  location: string | null;
  turnCount: number;
  sourceText: string;
  preferredFirstSpeakerCharacterId?: string | null;
  openingAddressesUser?: boolean;
}) {
  const participants = normalizeRoomParticipants({
    meta: params.conv.meta ?? null,
    fallbackCharacterId:
      typeof params.conv.character_id === "string" ? params.conv.character_id : null,
  });
  const aiParticipants = getAiParticipants(participants);
  if (aiParticipants.length === 0) {
    return {
      turns: [] as Array<{ characterId: string; content: string; meta: Record<string, unknown> }>,
      sceneState: null as Record<string, unknown> | null,
    };
  }

  const plan = buildSceneSpeakerPlan({
    participants: aiParticipants,
    text: params.sourceText,
    history: params.coreHistory,
    requestedTurnCount: Math.max(2, Math.min(3, params.turnCount)),
    lastSpeakerCharacterId: getLastSpeakerCharacterId(params.conv.meta ?? null),
    recentSpeakerCharacterIds: getRecentSpeakerCharacterIds(params.conv.meta ?? null),
    preferredFirstSpeakerCharacterId: params.preferredFirstSpeakerCharacterId,
  });

  let rollingHistory = [...params.coreHistory];
  const worldCtx = params.layer
    ? await loadWorldPromptContextBestEffort({ worldId: params.layer, locationId: params.location })
    : null;
  const worldOverlay = buildWorldOverlay(worldCtx);
  const out: Array<{ characterId: string; content: string; meta: Record<string, unknown> }> = [];

  for (let index = 0; index < plan.selectedCharacterIds.length; index += 1) {
    const speakerCharacterId = plan.selectedCharacterIds[index];
    const speakerName = CHARACTERS[speakerCharacterId]?.name ?? speakerCharacterId;
    const previousSpeakerName =
      index > 0
        ? CHARACTERS[plan.selectedCharacterIds[index - 1]]?.name ?? plan.selectedCharacterIds[index - 1]
        : null;
    const personaSystemBase = buildTouhouPersonaSystem(speakerCharacterId, {
      chatMode: params.chatMode,
      includeExamples: false,
      includeRoleplayExamples: false,
    });
    const isLastTurn = index === plan.selectedCharacterIds.length - 1;
    const emphasis = isLastTurn ? "leave a small opening for the next participant or user" : "respond directly and hand momentum forward";
    const personaSystem = [
      personaSystemBase,
      worldOverlay,
      "# Scene constraints",
      params.openingAddressesUser === true && index === 0
        ? "- First answer the user's latest message as yourself."
        : "- Speak to the room, not to the user.",
      "- This is a multi-character in-room exchange.",
      "- Keep momentum; do not ask the user to restate the prompt.",
      isLastTurn ? "- End with a light hook only if it feels natural." : "- Hand the conversation cleanly to another participant.",
    ]
      .filter(Boolean)
      .join("\n\n");

    const gen = {
      ...genParamsFor(speakerCharacterId),
      max_tokens: 220,
      temperature: 0.92,
      multimodal: {
        mode: "sdk_first" as const,
        attachment_count: 0,
        client_augmented_text_present: false,
      },
    };

    const continuationPrompt = buildSceneContinuationUserText({
      speakerName,
      previousSpeakerName,
      turnIndex: index,
      totalTurns: plan.selectedCharacterIds.length,
      topicHint: plan.topicHint,
      emphasis,
      sourceText: params.sourceText,
      addressUserDirectly: params.openingAddressesUser === true && index === 0,
    });

    const response = await fetch(`${params.base}/persona/chat`, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(params.accessToken ? { Authorization: `Bearer ${params.accessToken}` } : {}),
      },
      body: JSON.stringify({
        user_id: params.userId,
        session_id: params.sessionId,
        message: continuationPrompt,
        history: rollingHistory,
        character_id: speakerCharacterId,
        chat_mode: params.chatMode,
        persona_system: personaSystem,
        gen,
        attachments: [],
        tool_policy: {
          attachment_mode: "sdk_first",
          web_search_mode: "off",
          allow_web_search: false,
          prefer_native_attachments: true,
        },
      }),
    });

    if (!response.ok) {
      const detail = await response.text().catch(() => "");
      throw new Error(`scene continuation failed: ${response.status} ${detail}`);
    }

    const data = (await response.json()) as PersonaChatResponse;
    const replySafe = typeof data.reply === "string" && data.reply.trim() ? data.reply.trim() : "??";
    const replyFinal = sanitizeReplyByContext({
      characterId: speakerCharacterId,
      chatMode: params.chatMode,
      reply: replySafe,
      history: rollingHistory,
      currentUserText: continuationPrompt,
    });

    const mergedMeta = mergeMeta(data.meta ?? null, {
      scene_continuation: true,
      scene_turn_index: index,
      scene_turn_total: plan.selectedCharacterIds.length,
      scene_topic_hint: plan.topicHint,
      character_id: speakerCharacterId,
      speaker: {
        kind: "ai_character",
        character_id: speakerCharacterId,
        display_name: CHARACTERS[speakerCharacterId]?.name ?? speakerCharacterId,
        title: CHARACTERS[speakerCharacterId]?.title ?? null,
      },
    });

    const insertError = await saveAssistantMessage({
      supabase: params.supabase,
      sessionId: params.sessionId,
      userId: params.userId,
      characterId: speakerCharacterId,
      content: replyFinal,
      meta: mergedMeta,
    });
    if (insertError) throw insertError;

    rollingHistory = [...rollingHistory, { role: "assistant", content: replyFinal }];
    out.push({
      characterId: speakerCharacterId,
      content: replyFinal,
      meta: mergedMeta,
    });
  }

  return {
    turns: out,
    sceneState: {
      initiative_character_id: plan.initiativeCharacterId,
      next_speaker_hint:
        out.length > 0
          ? plan.selectedCharacterIds.find((id) => !out.some((turn) => turn.characterId === id)) ?? null
          : null,
      last_turn_count: out.length,
      last_topic_hint: plan.topicHint,
      last_speaker_character_id: out.length > 0 ? out[out.length - 1].characterId : getLastSpeakerCharacterId(params.conv.meta ?? null),
      recent_speaker_character_ids: plan.recentSpeakerCharacterIds,
      planner_mode: out.length >= 3 ? "triad" : "duo",
    } as Record<string, unknown>,
  };
}


export async function runLegacySessionMessageRoute(
  req: NextRequest,
  context: { params: Promise<{ sessionId: string }> },
) {
  try {
    enforceOrigin(req);
  } catch {
    return NextResponse.json({ error: "Forbidden" }, { status: 403 });
  }

 

  const parsed = await parseSessionMessageRequestBody(req);

  if (parsed instanceof Response) { 
    return parsed;
  }
  
  const {
    characterId,
    text: rawText,
    coreModeRaw,
    sceneMode,
    sceneTurnCount,
    files,
    urls,
  } = parsed;
  const text = rawText.trim() ? rawText : buildImplicitAttachmentMessage(files);

  const loaded = await buildSessionMessageContext({ context, coreModeRaw });

  if (loaded instanceof Response) return loaded;

  const {
    supabase,
    userId,
    sessionId,
    accessToken,
    conv,
    coreHistory,
    base,
    chatMode,
  } = loaded;

  const roomSpeaker = resolveRoomSpeaker({
    conv,
    requestedCharacterId: characterId,
    text,
  });
  const selectedCharacterId = roomSpeaker.selectedCharacterId;
  const roomParticipants = normalizeRoomParticipants({
    meta: conv.meta ?? null,
    fallbackCharacterId:
      conv && typeof (conv as Record<string, unknown>).character_id === "string"
        ? String((conv as Record<string, unknown>).character_id)
        : selectedCharacterId,
  });
  const roomAiParticipants = getAiParticipants(roomParticipants);
  const mentionedSpeakerIds = roomSpeaker.isGroupRoom
    ? findMentionedGroupSpeakerIds({ text, participants: roomParticipants })
    : [];
  const isSceneContinuation = sceneMode === "continue" && roomSpeaker.isGroupRoom;
  const shouldRunAutoGroupBanter =
    !isSceneContinuation &&
    roomSpeaker.isGroupRoom &&
    shouldAutoGroupBanter({
      text,
      participants: roomAiParticipants,
      mentionedCharacterIds: mentionedSpeakerIds,
    });
  const autoGroupTurnCount = shouldRunAutoGroupBanter
    ? resolveAutoGroupTurnCount({
        text,
        history: coreHistory,
        aiCount: roomAiParticipants.length,
        mentionedCharacterIds: mentionedSpeakerIds,
      })
    : 0;

  if (roomSpeaker.roomMetaPatch) {
    void supabaseAdmin()
      .from("common_sessions")
      .update({ meta: roomSpeaker.roomMetaPatch })
      .eq("id", sessionId)
      .eq("app", "touhou");
  }

  if (isSceneContinuation || shouldRunAutoGroupBanter) {
    try {
      const { turns, sceneState } = await generateSceneContinuationTurns({
        supabase,
        sessionId,
        userId,
        accessToken,
        base,
        chatMode,
        conv,
        coreHistory,
        layer:
          conv && typeof (conv as Record<string, unknown>).layer === "string"
            ? String((conv as Record<string, unknown>).layer)
            : null,
        location:
          conv && typeof (conv as Record<string, unknown>).location === "string"
            ? String((conv as Record<string, unknown>).location)
            : null,
        turnCount: isSceneContinuation ? sceneTurnCount : autoGroupTurnCount,
        sourceText: text,
        preferredFirstSpeakerCharacterId: mentionedSpeakerIds[0] ?? selectedCharacterId,
        openingAddressesUser: !isSceneContinuation,
      });

      if (turns.length > 0) {
        const lastCharacterId = turns[turns.length - 1]?.characterId ?? selectedCharacterId;
        const baseMeta =
          sceneState && typeof sceneState === "object"
            ? { ...(conv.meta ?? {}), scene_state: sceneState }
            : withLastSpeakerCharacterId(conv.meta ?? null, lastCharacterId);
        const recentSpeakerIds =
          sceneState && typeof sceneState === "object" && Array.isArray((sceneState as Record<string, unknown>).recent_speaker_character_ids)
            ? ((sceneState as Record<string, unknown>).recent_speaker_character_ids as unknown[])
                .map((value) => (typeof value === "string" ? value.trim() : ""))
                .filter(Boolean)
            : [lastCharacterId, ...getRecentSpeakerCharacterIds(conv.meta ?? null)];
        void supabaseAdmin()
          .from("common_sessions")
          .update({
            meta: withRecentSpeakerCharacterIds(withLastSpeakerCharacterId(baseMeta, lastCharacterId), recentSpeakerIds),
          })
          .eq("id", sessionId)
          .eq("app", "touhou");
      }

      return NextResponse.json({
        role: "ai",
        content: turns.map((turn) => turn.content).join("\n\n"),
        messages: turns.map((turn, index) => ({
          id: `scene-${index}-${turn.characterId}`,
          role: "ai",
          content: turn.content,
          speaker_id: turn.characterId,
          meta: turn.meta,
        })),
        meta: {
          scene_continuation: isSceneContinuation,
          group_banter: shouldRunAutoGroupBanter,
          turn_count: turns.length,
          scene_state: sceneState,
        },
      });
    } catch (error) {
      console.error("[touhou] scene continuation failed:", error);
      return NextResponse.json(
        { error: "Failed to continue scene" },
        { status: 500 },
      );
    }
  }

  const relationshipEnabled = true;
  const worldPromptEnabled = true;
  const layer =
    conv && typeof (conv as Record<string, unknown>).layer === "string"
      ? String((conv as Record<string, unknown>).layer)
      : null;
  const location =
    conv && typeof (conv as Record<string, unknown>).location === "string"
      ? String((conv as Record<string, unknown>).location)
      : null;
  const isSeedTurn = isFirstAssistantTurn(coreHistory);
  const shouldGenerateTtsReading = await shouldGenerateDesktopTtsReading({
    req,
    characterId: selectedCharacterId,
  });
  const shouldLoadRelationship = shouldLoadRelationshipOverlay({
    enabled: relationshipEnabled,
    chatMode,
    isSeedTurn,
  });
  const shouldLoadWorld = shouldLoadWorldOverlay({
    enabled: worldPromptEnabled,
    chatMode,
    layer,
    location,
  });
  const shouldFetchDirectorIntent = shouldFetchDirectorIntentForTurn({
    characterId: selectedCharacterId,
    chatMode,
    isSeedTurn,
    text,
    fileCount: files.length,
    urlCount: urls.length,
    history: coreHistory,
  });
  const shouldUpdateRelationship = shouldUpdateRelationshipForTurn({
    chatMode,
    isSeedTurn,
    text,
    coreHistory,
    fileCount: files.length,
    urlCount: urls.length,
  });

  const relMemPromise = shouldLoadRelationship
    ? loadRelationshipAndMemoryBestEffort({ supabase, userId, characterId: selectedCharacterId })
    : Promise.resolve({
        relationship: { trust: 0, familiarity: 0 },
        memory: null,
      });
  const worldPromise = shouldLoadWorld
    ? loadWorldPromptContextBestEffort({ worldId: layer, locationId: location })
    : Promise.resolve(null);

  const intentPromise: Promise<PersonaIntentResponse | null> =
    shouldFetchDirectorIntent
      ? fetchPersonaIntent({
          base,
          accessToken,
          sessionId,
          characterId: selectedCharacterId,
          chatMode,
          message: text.trim(),
          history: coreHistory,
        })
      : Promise.resolve(null);
  const uploadsEnabled = true;
  const linkAnalysisEnabled = urls.length > 0;
  const autoBrowseEnabled = shouldAutoBrowseForTurn({
    text,
    chatMode,
    fileCount: files.length,
    urlCount: urls.length,
  });

  const uploadsPromise = uploadsEnabled
    ? uploadFilesForSdk({ base, accessToken, files })
    : Promise.resolve([]);
  const linksPromise: Promise<Phase04LinkAnalysis[]> =
    linkAnalysisEnabled && urls.length > 0
      ? analyzeLinks({ base, accessToken, urls })
      : autoBrowseEnabled
        ? autoBrowseFromText({
            base,
            accessToken,
            userText: text.trim(),
          })
        : Promise.resolve([]);
  const [phase04Uploads, phase04Links] = await Promise.all([
    uploadsPromise,
    linksPromise,
  ]);
  const coreAttachments = [
    ...phase04Uploads,
    ...phase04Links,
  ] as unknown as Record<string, unknown>[];

  // store user message
  const userInsertPromise = saveUserMessage({
    supabase,
    sessionId,
    userId,
    content: rawText,
    phase04Uploads,
    phase04Links,
  });

  let intent = await intentPromise;
  if (intent) {
      intent = normalizePersonaIntent({
      intent,
      history: coreHistory,
      userText: text.trim(),
      characterId: selectedCharacterId,
      chatMode,
    });
  }

  const userInsertError = await userInsertPromise;
  if (userInsertError) {
    console.error("[touhou] user message insert error:", userInsertError);
    return NextResponse.json(
      { error: "Failed to save user message" },
      { status: 500 },
    );
  }

  const personaSystemBase = buildTouhouPersonaSystem(selectedCharacterId, {
    chatMode,
    includeExamples: isSeedTurn,
    includeRoleplayExamples: isSeedTurn,
  });
  const turnTuningLines = buildTurnTuningLines({
    chatMode,
    characterId: selectedCharacterId,
    text,
    coreHistory,
  });
  const directorOverlay = intent ? reimuDirectorOverlay(intent) : "";
  const fastPersonaSystem = [
    personaSystemBase,
    turnTuningLines.length > 0
      ? `# Turn constraints\n${turnTuningLines.join("\n")}`
      : null,
    directorOverlay || null,
  ]
    .filter(Boolean)
    .join("\n\n");
  const fastPersonaSystemSha256 = sha256Hex(fastPersonaSystem);
  const streamMode = wantsStream(req);

  // Clarify short-circuit: when the intent director asks for a single confirm-question,
  // return it directly (saves latency/cost and prevents style drift).
  if (
    intent?.needs_clarify &&
    intent.intent === "unclear" &&
    (intent.clarify_question || "").trim() &&
    Number.isFinite(intent.confidence) &&
    intent.confidence >= 0.85
  ) {
    const replyFinal = String(intent.clarify_question || "").trim();

    const mergedMeta = mergeMeta(null, {
      persona_system_sha256: fastPersonaSystemSha256,
      chat_mode: chatMode,
      character_id: selectedCharacterId,
      seed_turn: isSeedTurn,
      director_overlay: true,
      intent: intent.intent,
      intent_confidence: intent.confidence,
      intent_output_style: intent.output_style,
      intent_effective_output_style: effectiveOutputStyle(intent),
      intent_allowed_humor: intent.allowed_humor,
      intent_urgency: intent.urgency,
      intent_needs_clarify: intent.needs_clarify,
      intent_safety_risk: intent.safety_risk,
      forced_output_style_passed: true,
      forced_output_style_retry: false,
      forced_output_style_reason: "clarify_short_circuit",
    });

    const aiInsertError = await saveAssistantMessage({
      supabase,
      sessionId,
      userId,
      characterId: selectedCharacterId,
      content: replyFinal,
      meta: mergedMeta,
    });

    if (aiInsertError) {
      console.error("[touhou] ai message insert error:", aiInsertError);
      return NextResponse.json(
        { error: "Failed to save ai message" },
        { status: 500 },
      );
    }

    if (isRecord(mergedMeta)) {
      const snapshotError = await saveStateSnapshot({
        supabase,
        userId,
        sessionId,
        meta: mergedMeta as Record<string, unknown>,
      });

      if (snapshotError) {
        console.warn("[touhou] state snapshot insert failed:", snapshotError);
      }
    }

    await updateRelationshipAndMemoryBestEffort({
      supabase,
      base,
      accessToken,
      sessionId,
      userId,
      characterId: selectedCharacterId,
      chatMode,
      userText: text,
      assistantText: replyFinal,
      shouldUpdate: shouldUpdateRelationship,
    });

    if (!streamMode) {
      return NextResponse.json({
        role: "ai",
        content: replyFinal,
        meta: mergedMeta,
      });
    }

    const ts = new TransformStream();
    const writer = ts.writable.getWriter();
    try {
      await writer.write(toSse("start", { sessionId }));
      await writer.write(toSse("delta", { text: replyFinal }));
      await writer.write(
        toSse("done", { reply: replyFinal, meta: mergedMeta }),
      );
    } catch {
      // ignore
    } finally {
      try {
        await writer.close();
      } catch {
        // ignore
      }
    }

    return new NextResponse(ts.readable, {
      headers: {
        "Content-Type": "text/event-stream; charset=utf-8",
        "Cache-Control": "no-cache, no-transform",
        Connection: "keep-alive",
      },
    });
  }

  const [relMem, worldCtx] = await Promise.all([relMemPromise, worldPromise]);
  const relationshipOverlay =
    relationshipEnabled && relMem
      ? buildRelationshipMemoryOverlay({
          characterId: selectedCharacterId,
          rel: relMem.relationship,
          mem: relMem.memory,
        })
      : null;
  const worldOverlay = buildWorldOverlay(worldCtx);

  const personaSystem = [
    personaSystemBase,
    relationshipOverlay,
    worldOverlay,
    turnTuningLines.length > 0
      ? `# Turn constraints\n${turnTuningLines.join("\n")}`
      : null,
    directorOverlay || null,
  ]
    .filter(Boolean)
    .join("\n\n");
  const retrievalHint = retrievalSystemHint({ linkAnalyses: phase04Links });
  const personaSystemWithRetrieval = retrievalHint
    ? `${personaSystem}\n\n# Retrieval\n${retrievalHint}`
    : personaSystem;
  const personaSystemSha256 = sha256Hex(personaSystemWithRetrieval);
  const gen = genParamsFor(selectedCharacterId);

  if (!streamMode) {
    return handleNonStreamSessionMessage({
      supabase,
      sessionId,
      userId,
      accessToken,
      base,
      chatMode,
      characterId: selectedCharacterId,
      text,
      coreHistory,
      coreAttachments,
      personaSystemWithRetrieval,
      personaSystemSha256,
      gen,
      intent,
      isSeedTurn,
      shouldGenerateTtsReading,
      shouldUpdateRelationship,
    });
  }
  return handleStreamSessionMessage({
    supabase,
    sessionId,
    userId,
    accessToken,
    base,
    chatMode,
    characterId: selectedCharacterId,
    text,
    coreHistory,
    coreAttachments,
    personaSystemWithRetrieval,
    personaSystemSha256,
    gen,
    intent,
    isSeedTurn,
    shouldGenerateTtsReading,
    shouldUpdateRelationship,
  });
}
