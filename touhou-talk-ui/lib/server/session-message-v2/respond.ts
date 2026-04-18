import { NextResponse } from "next/server";

import type { supabaseServer } from "@/lib/supabase-server";
import { CHARACTERS } from "@/data/characters";
import type { TouhouChatMode } from "@/lib/touhou-settings";
import {
  mergeMeta,
  isRecord,
  summarizeCoreRoutingMeta,
  withTtsReadingMeta,
} from "@/lib/server/session-message/meta";
import { generateTtsReadingText } from "@/lib/server/session-message/tts-reading";
import {
  buildVrmPerformanceCue,
  toVrmPerformanceMeta,
} from "@/lib/vrm/performanceDirector";
import type {
  PersonaChatResponse,
  PersonaToolPolicy,
} from "@/lib/server/session-message-v2/types";
import {
  saveAssistantMessage,
  saveStateSnapshot,
} from "@/lib/server/session-message-v2/persistence";
import { updateRelationshipAndMemoryBestEffort } from "@/lib/server/session-message-v2/relationship";

function runPostReplyTasks(task: () => Promise<void>) {
  void task().catch((error) => {
    console.warn("[touhou] post-reply task failed:", error);
  });
}

export async function handleNonStreamSessionMessage(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  sessionId: string;
  userId: string;
  accessToken: string | null;
  base: string;
  chatMode: TouhouChatMode;
  characterId: string;
  locale: string;
  text: string;
  coreHistory: Array<{ role: "user" | "assistant"; content: string }>;
  coreAttachments: Record<string, unknown>[];
  isSeedTurn: boolean;
  shouldGenerateTtsReading: boolean;
  shouldUpdateRelationship: boolean;
}) {
  const enrichedGen = {
    multimodal: {
      mode: "sdk_first" as const,
      attachment_count: params.coreAttachments.length,
      client_augmented_text_present: false,
    },
  };
  const toolPolicy: PersonaToolPolicy = {
    attachment_mode: "sdk_first",
    web_search_mode: "auto",
    allow_web_search: true,
    prefer_native_attachments: true,
  };

  const r = await fetch(`${params.base}/persona/chat`, {
    method: "POST",
    headers: {
      "Content-Type": "application/json",
      ...(params.accessToken
        ? { Authorization: `Bearer ${params.accessToken}` }
        : {}),
    },
    body: JSON.stringify({
      user_id: params.userId,
      session_id: params.sessionId,
      message: params.text,
      history: params.coreHistory,
      character_id: params.characterId,
      chat_mode: params.chatMode,
      gen: enrichedGen,
      attachments: params.coreAttachments,
      tool_policy: toolPolicy,
      client_context: {
        ui_type: "touhou-talk-ui",
        surface: "session-message",
        locale: params.locale,
      },
      conversation_profile: {
        response_style: "auto",
      },
    }),
  });

  if (!r.ok) {
    const detail = await r.text().catch(() => "");
    console.error("[touhou] core /persona/chat failed:", r.status, detail);
    return NextResponse.json({ error: "Persona core failed" }, { status: 502 });
  }

  const data = (await r.json()) as PersonaChatResponse;
  const replySafe =
    typeof data.reply === "string" && data.reply.trim().length > 0
      ? data.reply
      : "ごめん、うまく言葉がまとまらなかった。もう一度だけ言ってみて。";
  const replyFinal = replySafe;

  const ttsReading = params.shouldGenerateTtsReading
    ? await generateTtsReadingText({
        characterId: params.characterId,
        replyText: replyFinal,
      })
    : { readingText: null, model: null };

  let mergedMeta = mergeMeta(data.meta ?? null, {
    chat_mode: params.chatMode,
    character_id: params.characterId,
    speaker: {
      kind: "ai_character",
      character_id: params.characterId,
      display_name: CHARACTERS[params.characterId]?.name ?? params.characterId,
      title: CHARACTERS[params.characterId]?.title ?? null,
    },
    seed_turn: params.isSeedTurn,
    core_routing: summarizeCoreRoutingMeta(data.meta ?? null),
  });
  mergedMeta = withTtsReadingMeta(
    mergedMeta,
    ttsReading.readingText,
    ttsReading.model,
  );
  mergedMeta = mergeMeta(mergedMeta, {
    vrm_performance: toVrmPerformanceMeta(
      buildVrmPerformanceCue({
        characterId: params.characterId,
        text: replyFinal,
        messageId: params.sessionId,
        speaking: false,
      }),
    ),
  });

  const coreRouting = summarizeCoreRoutingMeta(data.meta ?? null);
  console.info("[touhou] core route summary:", {
    sessionId: params.sessionId,
    traceId:
      isRecord(data.meta) && typeof data.meta.trace_id === "string"
        ? data.meta.trace_id
        : null,
    ...coreRouting,
  });

  const aiInsertError = await saveAssistantMessage({
    supabase: params.supabase,
    sessionId: params.sessionId,
    userId: params.userId,
    characterId: params.characterId,
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

  runPostReplyTasks(async () => {
    if (isRecord(mergedMeta)) {
      const snapshotError = await saveStateSnapshot({
        supabase: params.supabase,
        userId: params.userId,
        sessionId: params.sessionId,
        meta: mergedMeta as Record<string, unknown>,
      });

      if (snapshotError) {
        console.warn("[touhou] state snapshot insert failed:", snapshotError);
      }
    }

    await updateRelationshipAndMemoryBestEffort({
      supabase: params.supabase,
      base: params.base,
      accessToken: params.accessToken,
      sessionId: params.sessionId,
      userId: params.userId,
      characterId: params.characterId,
      chatMode: params.chatMode,
      userText: params.text,
      assistantText: replyFinal,
      shouldUpdate: params.shouldUpdateRelationship,
    });
  });

  return NextResponse.json({
    role: "ai",
    content: replyFinal,
    meta: mergedMeta,
  });
}
