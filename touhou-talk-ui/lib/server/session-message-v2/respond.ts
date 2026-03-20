import { NextResponse } from "next/server";

import type { supabaseServer } from "@/lib/supabase-server";
import type { TouhouChatMode } from "@/lib/touhouPersona";
import { mergeMeta, isRecord } from "@/lib/server/session-message/meta";
import type {
  PersonaChatResponse,
  PersonaIntentResponse,
} from "@/lib/server/session-message-v2/types";
import {
  effectiveOutputStyle,
  lintOutputStyle,
  coerceToForcedStyle,
} from "@/lib/server/session-message-v2/director";
import { sanitizeReplyByContext } from "@/lib/server/session-message-v2/sanitize";
import {
  saveAssistantMessage,
  saveStateSnapshot,
} from "@/lib/server/session-message-v2/persistence";
import { updateRelationshipAndMemoryBestEffort } from "@/lib/server/session-message-v2/relationship";

export async function handleNonStreamSessionMessage(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  sessionId: string;
  userId: string;
  accessToken: string | null;
  base: string;
  chatMode: TouhouChatMode;
  characterId: string;
  text: string;
  augmentedText: string;
  coreHistory: Array<{ role: "user" | "assistant"; content: string }>;
  coreAttachments: Record<string, unknown>[];
  personaSystemWithRetrieval: string;
  personaSystemSha256: string;
  gen: ReturnType<typeof import("@/lib/touhouPersona").genParamsFor>;
  intent: PersonaIntentResponse | null;
  isSeedTurn: boolean;
}) {
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
      message: params.augmentedText,
      history: params.coreHistory,
      character_id: params.characterId,
      chat_mode: params.chatMode,
      persona_system: params.personaSystemWithRetrieval,
      gen: params.gen,
      attachments: params.coreAttachments,
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

  const replyGuarded = sanitizeReplyByContext({
    characterId: params.characterId,
    chatMode: params.chatMode,
    reply: replySafe,
    history: params.coreHistory,
    currentUserText: params.text,
  });

  let replyFinal = replyGuarded;
  let forcedStylePassed = true;
  let forcedStyleRetry = false;
  let forcedStyleReason = "";

  if (params.intent) {
    const style = effectiveOutputStyle(params.intent);
    const lint1 = lintOutputStyle({
      style,
      intent: params.intent,
      reply: replyFinal,
    });

    if (!lint1.ok) {
      forcedStylePassed = false;
      forcedStyleReason = lint1.reason;

      const coerced = coerceToForcedStyle({
        style,
        intent: params.intent,
        reply: replyFinal,
      });

      if (coerced.applied) {
        const lint2 = lintOutputStyle({
          style,
          intent: params.intent,
          reply: coerced.reply,
        });

        forcedStyleRetry = true;

        if (lint2.ok) {
          forcedStylePassed = true;
          forcedStyleReason = "";
          replyFinal = coerced.reply;
        } else {
          forcedStyleReason = `coerce_${lint2.reason}`;
        }
      }
    }
  }

  const mergedMeta = mergeMeta(data.meta ?? null, {
    persona_system_sha256: params.personaSystemSha256,
    chat_mode: params.chatMode,
    character_id: params.characterId,
    seed_turn: params.isSeedTurn,
    ...(params.intent
      ? {
          director_overlay: true,
          intent: params.intent.intent,
          intent_confidence: params.intent.confidence,
          intent_output_style: params.intent.output_style,
          intent_effective_output_style: effectiveOutputStyle(params.intent),
          intent_allowed_humor: params.intent.allowed_humor,
          intent_urgency: params.intent.urgency,
          intent_needs_clarify: params.intent.needs_clarify,
          intent_safety_risk: params.intent.safety_risk,
          forced_output_style_passed: forcedStylePassed,
          forced_output_style_retry: forcedStyleRetry,
          forced_output_style_reason: forcedStyleReason,
        }
      : { director_overlay: false }),
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
  });

  return NextResponse.json({
    role: "ai",
    content: replyFinal,
    meta: mergedMeta,
  });
}
