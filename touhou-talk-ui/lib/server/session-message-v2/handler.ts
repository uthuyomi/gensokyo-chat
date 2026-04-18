import { NextRequest, NextResponse } from "next/server";

import { buildSessionMessageContext } from "./context";
import { buildImplicitAttachmentMessage, parseSessionMessageRequestBody } from "./request-body";
import { saveUserMessage } from "./persistence";
import { handleNonStreamSessionMessage } from "./respond";
import { handleStreamSessionMessage } from "./stream";
import type {
  Phase04Attachment,
  SessionMessageRouteContext,
  SessionMessageStage,
} from "./types";

function resolveRequestLocale(req: NextRequest): string {
  const raw = req.headers.get("accept-language") || "ja-JP";
  const first = raw
    .split(",")
    .map((part) => part.trim())
    .filter(Boolean)[0];
  return first || "ja-JP";
}

function buildExecutionPlan(): SessionMessageStage[] {
  return [
    "validate-request",
    "load-context",
    "upload-attachments",
    "persist-user-message",
    "delegate-runtime",
  ];
}

function inferAttachmentKind(file: File): string {
  const type = String(file.type ?? "").toLowerCase();
  const name = String(file.name ?? "").toLowerCase();
  if (type.startsWith("image/")) return "image";
  if (type === "application/pdf" || name.endsWith(".pdf")) return "pdf";
  if (
    type.startsWith("text/") ||
    [
      ".md",
      ".txt",
      ".json",
      ".jsonl",
      ".yaml",
      ".yml",
      ".ts",
      ".tsx",
      ".js",
      ".py",
      ".java",
      ".rs",
      ".go",
      ".sql",
    ].some((ext) => name.endsWith(ext))
  ) {
    return "text";
  }
  return "file";
}

async function uploadFilesToCore(params: {
  base: string;
  accessToken: string | null;
  sessionId: string;
  files: File[];
}): Promise<Phase04Attachment[]> {
  const out: Phase04Attachment[] = [];

  for (const file of params.files) {
    const form = new FormData();
    form.append("file", file);

    const res = await fetch(`${params.base}/io/upload`, {
      method: "POST",
      headers: {
        ...(params.accessToken
          ? { Authorization: `Bearer ${params.accessToken}` }
          : {}),
        "x-sigmaris-session-id": params.sessionId,
      },
      body: form,
    });

    if (!res.ok) {
      const detail = await res.text().catch(() => "");
      throw new Error(
        `attachment upload failed: HTTP ${res.status} ${detail}`.trim(),
      );
    }

    const data = (await res.json()) as {
      attachment_id?: string;
      file_name?: string;
      mime_type?: string;
    };
    const attachmentId = String(data.attachment_id ?? "").trim();
    if (!attachmentId) {
      throw new Error("attachment upload returned no attachment_id");
    }

    out.push({
      type: "upload",
      attachment_id: attachmentId,
      file_name: String(data.file_name ?? file.name ?? "").trim() || file.name,
      mime_type:
        String(data.mime_type ?? file.type ?? "").trim() ||
        "application/octet-stream",
      kind: inferAttachmentKind(file),
    });
  }

  return out;
}

function isResponseLike(value: unknown): value is Response {
  return value instanceof Response;
}

export async function handleSessionMessageRoute(
  req: NextRequest,
  context: SessionMessageRouteContext,
): Promise<Response> {
  const plan = buildExecutionPlan();
  if (plan.length === 0) {
    return NextResponse.json(
      { error: "Session message execution plan is empty" },
      { status: 500 },
    );
  }

  const parsed = await parseSessionMessageRequestBody(req);
  if (isResponseLike(parsed)) return parsed;

  const loaded = await buildSessionMessageContext({
    context,
    coreModeRaw: parsed.coreModeRaw,
  });
  if (isResponseLike(loaded)) return loaded;

  let uploads: Phase04Attachment[] = [];
  try {
    uploads = await uploadFilesToCore({
      base: loaded.base,
      accessToken: loaded.accessToken,
      sessionId: loaded.sessionId,
      files: parsed.files,
    });
  } catch (error) {
    console.error("[touhou] attachment upload failed:", error);
    return NextResponse.json(
      { error: "Attachment upload failed" },
      { status: 502 },
    );
  }

  const text =
    String(parsed.text ?? "").trim() || buildImplicitAttachmentMessage(parsed.files);

  const userInsertError = await saveUserMessage({
    supabase: loaded.supabase,
    sessionId: loaded.sessionId,
    userId: loaded.userId,
    content: text,
    phase04Uploads: uploads,
    phase04Links: [],
  });
  if (userInsertError) {
    console.error("[touhou] user message insert error:", userInsertError);
    return NextResponse.json(
      { error: "Failed to save user message" },
      { status: 500 },
    );
  }

  const isSeedTurn = !loaded.coreHistory.some((m) => m.role === "assistant");
  const isGroup =
    String((loaded.conv as Record<string, unknown>)?.mode ?? "").trim() === "group";
  const wantsStream =
    req.nextUrl.searchParams.get("stream") === "1" &&
    !isGroup &&
    parsed.sceneMode !== "continue";
  const locale = resolveRequestLocale(req);

  if (wantsStream) {
    return handleStreamSessionMessage({
      supabase: loaded.supabase,
      sessionId: loaded.sessionId,
      userId: loaded.userId,
      accessToken: loaded.accessToken,
      base: loaded.base,
      chatMode: loaded.chatMode,
      characterId: parsed.characterId,
      locale,
      text,
      coreHistory: loaded.coreHistory,
      coreAttachments: uploads,
      isSeedTurn,
      shouldGenerateTtsReading: true,
      shouldUpdateRelationship: true,
    });
  }

  const singleResponse = await handleNonStreamSessionMessage({
    supabase: loaded.supabase,
    sessionId: loaded.sessionId,
    userId: loaded.userId,
    accessToken: loaded.accessToken,
    base: loaded.base,
    chatMode: loaded.chatMode,
    characterId: parsed.characterId,
    locale,
    text,
    coreHistory: loaded.coreHistory,
    coreAttachments: uploads,
    isSeedTurn,
    shouldGenerateTtsReading: true,
    shouldUpdateRelationship: true,
  });

  if (!isGroup && parsed.sceneMode !== "continue") {
    return singleResponse;
  }

  if (!singleResponse.ok) {
    return singleResponse;
  }

  const payload = (await singleResponse.json().catch(() => null)) as
    | { content?: unknown; meta?: unknown }
    | null;
  const content = String(payload?.content ?? "").trim();
  const meta =
    payload?.meta && typeof payload.meta === "object" && !Array.isArray(payload.meta)
      ? (payload.meta as Record<string, unknown>)
      : null;

  return NextResponse.json({
    messages: [
      {
        role: "ai",
        content,
        speaker_id: parsed.characterId,
        meta,
      },
    ],
    meta,
  });
}
