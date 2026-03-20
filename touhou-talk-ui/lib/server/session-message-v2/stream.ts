import { NextResponse } from "next/server";

import type { supabaseServer } from "@/lib/supabase-server";
import type { TouhouChatMode } from "@/lib/touhouPersona";
import { mergeMeta, isRecord } from "@/lib/server/session-message/meta";
import type { PersonaIntentResponse } from "@/lib/server/session-message-v2/types";
import {
  toSse,
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

export async function handleStreamSessionMessage(params: {
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
  let upstream: Response;

  try {
    upstream = await fetch(`${params.base}/persona/chat/stream`, {
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
  } catch (e) {
    const msg = e instanceof Error ? e.message : String(e);
    console.error("[touhou] core stream fetch failed:", {
      base: params.base,
      msg,
    });
    return NextResponse.json(
      {
        error: "Persona core is unreachable",
        base: params.base,
        detail: msg,
      },
      { status: 502 },
    );
  }

  if (!upstream.ok || !upstream.body) {
    const detail = await upstream.text().catch(() => "");
    console.error("[touhou] core stream failed:", upstream.status, detail);
    return NextResponse.json(
      { error: "Persona core stream failed", detail },
      { status: 502 },
    );
  }

  const decoder = new TextDecoder();
  const reader = upstream.body.getReader();
  const { readable, writable } = new TransformStream();
  const writer = writable.getWriter();

  const touhouUiMeta = {
    chat_mode: params.chatMode,
    character_id: params.characterId,
    persona_system_sha256: params.personaSystemSha256,
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
        }
      : { director_overlay: false }),
  };

  let replyAcc = "";
  let finalMeta: Record<string, unknown> = mergeMeta(null, touhouUiMeta);

  (async () => {
    let buf = "";

    try {
      while (true) {
        const { value, done } = await reader.read();
        if (done) break;

        buf += decoder.decode(value, { stream: true });

        while (true) {
          const idx = buf.indexOf("\n\n");
          if (idx === -1) break;

          const block = buf.slice(0, idx);
          buf = buf.slice(idx + 2);

          const lines = block.split("\n");
          let event = "message";
          const dataLines: string[] = [];

          for (const line of lines) {
            if (line.startsWith("event:")) {
              event = line.slice(6).trim();
            } else if (line.startsWith("data:")) {
              dataLines.push(line.slice(5).trim());
            }
          }

          const dataRaw = dataLines.join("\n");

          if (event === "delta") {
            try {
              const parsed = JSON.parse(dataRaw);
              const textPart =
                isRecord(parsed) && typeof parsed.text === "string"
                  ? parsed.text
                  : "";

              if (textPart) replyAcc += textPart;
              await writer.write(toSse("delta", { text: textPart }));
            } catch {
              await writer.write(`event: delta\ndata: ${dataRaw}\n\n`);
            }
          } else if (event === "done") {
            try {
              const parsed = JSON.parse(dataRaw);
              const reply =
                isRecord(parsed) && typeof parsed.reply === "string"
                  ? parsed.reply
                  : replyAcc;

              finalMeta =
                isRecord(parsed) && isRecord(parsed.meta)
                  ? mergeMeta(parsed.meta, touhouUiMeta)
                  : mergeMeta(null, touhouUiMeta);

              const replyGuarded = sanitizeReplyByContext({
                characterId: params.characterId,
                chatMode: params.chatMode,
                reply,
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

                finalMeta = mergeMeta(finalMeta, {
                  forced_output_style_passed: forcedStylePassed,
                  forced_output_style_retry: forcedStyleRetry,
                  forced_output_style_reason: forcedStyleReason,
                });
              }

              replyAcc = replyFinal;
              await writer.write(
                toSse("done", { reply: replyFinal, meta: finalMeta }),
              );
            } catch {
              await writer.write(`event: done\ndata: ${dataRaw}\n\n`);
            }
          } else if (event === "start") {
            await writer.write(toSse("start", { sessionId: params.sessionId }));
          } else if (event === "error") {
            await writer.write(toSse("error", { error: dataRaw }));
          }
        }
      }
    } catch (e: unknown) {
      const msg = e instanceof Error ? e.message : String(e);
      await writer.write(toSse("error", { error: msg }));
    } finally {
      let replyGuarded = "";

      try {
        const replySafe =
          typeof replyAcc === "string" && replyAcc.trim().length > 0
            ? replyAcc
            : "すみません、うまく返答をまとめられませんでした。もう一度試してください。";

        replyGuarded = sanitizeReplyByContext({
          characterId: params.characterId,
          chatMode: params.chatMode,
          reply: replySafe,
          history: params.coreHistory,
          currentUserText: params.text,
        });

        const aiInsertError = await saveAssistantMessage({
          supabase: params.supabase,
          sessionId: params.sessionId,
          userId: params.userId,
          characterId: params.characterId,
          content: replyGuarded,
          meta: finalMeta,
        });

        if (aiInsertError) {
          console.warn("[touhou] persist ai message failed:", aiInsertError);
        }
      } catch (e) {
        console.warn("[touhou] persist ai message failed:", e);
      }

      try {
        if (isRecord(finalMeta)) {
          const snapshotError = await saveStateSnapshot({
            supabase: params.supabase,
            userId: params.userId,
            sessionId: params.sessionId,
            meta: finalMeta as Record<string, unknown>,
          });

          if (snapshotError) {
            console.warn(
              "[touhou] state snapshot insert failed:",
              snapshotError,
            );
          }
        }
      } catch (e) {
        console.warn("[touhou] state snapshot insert failed:", e);
      }

      try {
        await updateRelationshipAndMemoryBestEffort({
          supabase: params.supabase,
          base: params.base,
          accessToken: params.accessToken,
          sessionId: params.sessionId,
          userId: params.userId,
          characterId: params.characterId,
          chatMode: params.chatMode,
          userText: params.text,
          assistantText: replyGuarded,
        });
      } catch {
        // ignore
      }

      try {
        await writer.close();
      } catch {
        // ignore
      }
    }
  })();

  return new Response(readable, {
    headers: {
      "Content-Type": "text/event-stream; charset=utf-8",
      "Cache-Control": "no-cache, no-transform",
      Connection: "keep-alive",
    },
  });
}
