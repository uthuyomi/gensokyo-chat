export const runtime = "nodejs";
export const dynamic = "force-dynamic";

// Legacy implementation retained as a fallback during the strangler migration.

import { NextRequest, NextResponse } from "next/server";
import "server-only";

import {
  buildTouhouPersonaSystem,
  genParamsFor,
} from "@/lib/touhouPersona";
import {
  isRecord,
  mergeMeta,
  sha256Hex,
} from "@/lib/server/session-message/meta";
import {
  enforceOrigin,
  envFlag,
  wantsStream,
} from "@/lib/server/session-message/request";
import type {
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
} from "@/lib/server/session-message-v2/sanitize";

import {
  uploadAndParseFiles,
  analyzeLinks,
  autoBrowseFromText,
  buildAugmentedMessage,
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

// Character persona is injected via `persona_system` (system-side) to avoid dilution over long chats.

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
  
  const { characterId, text, coreModeRaw, files, urls } = parsed;

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

  const relationshipEnabled = envFlag("TOUHOU_RELATIONSHIP_ENABLED", true);
  const worldPromptEnabled = envFlag("TOUHOU_WORLD_PROMPT_ENABLED", true);
  const layer =
    conv && typeof (conv as Record<string, unknown>).layer === "string"
      ? String((conv as Record<string, unknown>).layer)
      : null;
  const location =
    conv && typeof (conv as Record<string, unknown>).location === "string"
      ? String((conv as Record<string, unknown>).location)
      : null;

  const relMemPromise = relationshipEnabled
    ? loadRelationshipAndMemoryBestEffort({ supabase, userId, characterId })
    : Promise.resolve({
        relationship: { trust: 0, familiarity: 0 },
        memory: null,
      });
  const worldPromise = worldPromptEnabled
    ? loadWorldPromptContextBestEffort({ worldId: layer, locationId: location })
    : Promise.resolve(null);

  const intentPromise: Promise<PersonaIntentResponse | null> =
    shouldUseDirectorOverlay({
      characterId,
      chatMode,
    })
      ? fetchPersonaIntent({
          base,
          accessToken,
          sessionId,
          characterId,
          chatMode,
          message: text.trim(),
          history: coreHistory,
        })
      : Promise.resolve(null);
  const isProd = process.env.NODE_ENV === "production";
  const uploadsEnabled = envFlag("TOUHOU_UPLOAD_ENABLED", !isProd);
  const linkAnalysisEnabled = envFlag("TOUHOU_LINK_ANALYSIS_ENABLED", !isProd);
  const autoBrowseEnabled = envFlag("TOUHOU_AUTO_BROWSE_ENABLED", false);

  const phase04Uploads = uploadsEnabled
    ? await uploadAndParseFiles({ base, accessToken, files })
    : [];

  let phase04Links: Phase04LinkAnalysis[] = [];
  if (linkAnalysisEnabled && urls.length > 0) {
    phase04Links = await analyzeLinks({ base, accessToken, urls });
  } else if (autoBrowseEnabled) {
    phase04Links = await autoBrowseFromText({
      base,
      accessToken,
      userText: text.trim(),
    });
  } else {
    phase04Links = [];
  }
  const augmentedText = buildAugmentedMessage({
    userText: text.trim(),
    uploads: phase04Uploads,
    linkAnalyses: phase04Links,
  });
  const coreAttachments = [
    ...phase04Uploads,
    ...phase04Links,
  ] as unknown as Record<string, unknown>[];

  // store user message
  const userInsertError = await saveUserMessage({
    supabase,
    sessionId,
    userId,
    content: text,
    phase04Uploads,
    phase04Links,
  });

  if (userInsertError) {
    console.error("[touhou] user message insert error:", userInsertError);
    return NextResponse.json(
      { error: "Failed to save user message" },
      { status: 500 },
    );
  }

  const isSeedTurn = isFirstAssistantTurn(coreHistory);
  let intent = await intentPromise;
  if (intent) {
    intent = normalizePersonaIntent({
      intent,
      history: coreHistory,
      userText: text.trim(),
      characterId,
      chatMode,
    });
  }

  const [relMem, worldCtx] = await Promise.all([relMemPromise, worldPromise]);
  const personaSystemBase = buildTouhouPersonaSystem(characterId, {
    chatMode,
    includeExamples: isSeedTurn,
    includeRoleplayExamples: isSeedTurn,
  });

  // Turn-scoped tuning: prefer "tell the model" over "delete later".
  const lowerRecentUser = buildRecentUserText({
    history: coreHistory,
    currentUserText: text,
  });
  const saisenRe = /(?:賽銭箱|お賽銭|賽銭|寄付)/i;
  const userMentionsSaisen = saisenRe.test(lowerRecentUser);
  const assistantRecentText = coreHistory
    .filter((m) => m.role === "assistant")
    .slice(-3)
    .map((m) => String(m.content ?? ""))
    .join("\n");
  const assistantRecentlyMentionedSaisen = saisenRe.test(assistantRecentText);

  const turnTuningLines: string[] = [];
  if (
    chatMode === "roleplay" &&
    characterId === "reimu" &&
    !userMentionsSaisen
  ) {
    if (assistantRecentlyMentionedSaisen) {
      turnTuningLines.push(
        "- このターンは賽銭/寄付ネタを出さない（クールダウン）。",
      );
    } else {
      turnTuningLines.push("- 賽銭/寄付ネタは最大1文まで（連発しない）。");
    }
  }

  const directorOverlay = intent ? reimuDirectorOverlay(intent) : "";
  const relationshipOverlay =
    relationshipEnabled && relMem
      ? buildRelationshipMemoryOverlay({
          characterId,
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
  const gen = genParamsFor(characterId);
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
      persona_system_sha256: personaSystemSha256,
      chat_mode: chatMode,
      character_id: characterId,
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
      characterId,
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
      characterId,
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

  if (!streamMode) {
    return handleNonStreamSessionMessage({
      supabase,
      sessionId,
      userId,
      accessToken,
      base,
      chatMode,
      characterId,
      text,
      augmentedText,
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
    characterId,
    text,
    augmentedText,
    coreHistory,
    coreAttachments,
    personaSystemWithRetrieval,
    personaSystemSha256,
    gen,
    intent,
    isSeedTurn,
  });
}
