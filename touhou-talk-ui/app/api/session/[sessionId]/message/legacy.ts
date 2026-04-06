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

import { parseSessionMessageRequestBody } from "@/lib/server/session-message-v2/request-body";

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

function shouldFetchDirectorIntentForTurn(params: {
  characterId: string;
  chatMode: TouhouChatMode;
  isSeedTurn: boolean;
  text: string;
  fileCount: number;
  urlCount: number;
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
  if (params.isSeedTurn) return true;
  if (params.fileCount > 0 || params.urlCount > 0) return true;
  if (text.length <= 240) return true;
  if (/[?？]\s*$/.test(text)) return true;
  return false;
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
  if (params.mentionedCharacterIds.length >= 1) return true;
  const text = String(params.text ?? "").trim().toLowerCase();
  if (!text) return false;
  const banterKeywords = [
    "all of you",
    "both of you",
    "talk to each other",
    "chat with each other",
    "everyone",
    "each of you",
    "together",
    "group",
    "banter",
  ];
  return banterKeywords.some((keyword) => text.includes(keyword));
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
  
  const { characterId, text, coreModeRaw, sceneMode, sceneTurnCount, files, urls } = parsed;

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
        turnCount: isSceneContinuation ? sceneTurnCount : Math.max(2, Math.min(3, mentionedSpeakerIds.length >= 2 ? 3 : 2)),
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
  const linkAnalysisEnabled = true;
  const autoBrowseEnabled = true;

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
    content: text,
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
  });
}
