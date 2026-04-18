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
import type { PersonaToolPolicy } from "@/lib/server/session-message-v2/types";
import { toSse } from "@/lib/server/session-message-v2/sse";
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

export async function handleStreamSessionMessage(params: {
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
    speaker: {
      kind: "ai_character",
      character_id: params.characterId,
      display_name: CHARACTERS[params.characterId]?.name ?? params.characterId,
      title: CHARACTERS[params.characterId]?.title ?? null,
    },
    seed_turn: params.isSeedTurn,
  };

  let replyAcc = "";
  let finalMeta: Record<string, unknown> = mergeMeta(null, touhouUiMeta);

  (async () => {
    let buf = "";
    let sawReplyDelta = false;

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

          if (event === "reply.delta" || event === "delta") {
            try {
              const parsed = JSON.parse(dataRaw);
              const textPart =
                isRecord(parsed) && typeof parsed.text === "string"
                  ? parsed.text
                  : "";

              if (event === "reply.delta") {
                sawReplyDelta = true;
              } else if (sawReplyDelta) {
                continue;
              }

              if (textPart) replyAcc += textPart;
              await writer.write(toSse("delta", { text: textPart }));
            } catch {
              if (event === "delta" && sawReplyDelta) {
                continue;
              }
              await writer.write(`event: delta\ndata: ${dataRaw}\n\n`);
            }
          } else if (event === "meta.partial") {
            try {
              const parsed = JSON.parse(dataRaw);
              if (isRecord(parsed)) {
                finalMeta = mergeMeta(finalMeta, parsed);
              }
              await writer.write(
                toSse("meta.partial", isRecord(parsed) ? parsed : {}),
              );
            } catch {
              await writer.write(`event: meta.partial\ndata: ${dataRaw}\n\n`);
            }
          } else if (event === "meta.final") {
            try {
              const parsed = JSON.parse(dataRaw);
              if (isRecord(parsed)) {
                finalMeta = mergeMeta(finalMeta, parsed);
              }
              await writer.write(
                toSse("meta.final", isRecord(parsed) ? parsed : {}),
              );
            } catch {
              await writer.write(`event: meta.final\ndata: ${dataRaw}\n\n`);
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
              const coreRouting =
                isRecord(parsed) && isRecord(parsed.meta)
                  ? summarizeCoreRoutingMeta(parsed.meta)
                  : summarizeCoreRoutingMeta(null);
              finalMeta = mergeMeta(finalMeta, {
                core_routing: coreRouting,
              });
              console.info("[touhou] core route summary:", {
                sessionId: params.sessionId,
                traceId:
                  isRecord(parsed) &&
                  isRecord(parsed.meta) &&
                  typeof parsed.meta.trace_id === "string"
                    ? parsed.meta.trace_id
                    : null,
                ...coreRouting,
              });

              const replyFinal =
                typeof reply === "string" && reply.trim().length > 0
                  ? reply
                  : "うまく返答を受け取れなかった。もう一度だけ試してくれ。";

              const ttsReading = params.shouldGenerateTtsReading
                ? await generateTtsReadingText({
                    characterId: params.characterId,
                    replyText: replyFinal,
                  })
                : { readingText: null, model: null };
              finalMeta = withTtsReadingMeta(
                finalMeta,
                ttsReading.readingText,
                ttsReading.model,
              );
              finalMeta = mergeMeta(finalMeta, {
                vrm_performance: toVrmPerformanceMeta(
                  buildVrmPerformanceCue({
                    characterId: params.characterId,
                    text: replyFinal,
                    messageId: params.sessionId,
                    speaking: false,
                  }),
                ),
              });

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
      const replyFinal =
        typeof replyAcc === "string" && replyAcc.trim().length > 0
          ? replyAcc
          : "すまん、返答を最後まで受け取れなかった。";

      try {
        const aiInsertError = await saveAssistantMessage({
          supabase: params.supabase,
          sessionId: params.sessionId,
          userId: params.userId,
          characterId: params.characterId,
          content: replyFinal,
          meta: finalMeta,
        });

        if (aiInsertError) {
          await writer.write(
            toSse("error", { error: "Failed to persist ai message" }),
          );
        }
      } catch (e) {
        console.warn("[touhou] persist ai message crashed:", e);
      }

      runPostReplyTasks(async () => {
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
