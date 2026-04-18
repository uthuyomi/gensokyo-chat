import { NextRequest, NextResponse } from "next/server";

function personaOsBaseUrl() {
  const raw =
    process.env.SIGMARIS_CORE_URL ||
    process.env.NEXT_PUBLIC_SIGMARIS_CORE ||
    "http://127.0.0.1:8000";
  return String(raw).replace(/\/+$/, "");
}

function personaOsChatEndpoint(opts?: { local?: boolean }) {
  const base = personaOsBaseUrl();
  const localBase =
    opts?.local && process.env.SIGMARIS_CORE_LOCAL_URL
      ? String(process.env.SIGMARIS_CORE_LOCAL_URL).replace(/\/+$/, "")
      : base;
  return `${localBase}/persona/chat`;
}

const PERSONA_OS_ENDPOINT = personaOsChatEndpoint({ local: false });
const PERSONA_OS_LOCAL_ENDPOINT = personaOsChatEndpoint({ local: true });

type ChatMessage = {
  role: "user" | "ai" | "assistant";
  content: string;
};

type FrontendChatRequestBody = {
  characterId: string;
  messages: ChatMessage[];
  userId?: string | null;
  chatMode?: "partner" | "roleplay" | "coach" | null;
  ageGroup?: "child" | "teen" | "adult" | "unknown" | null;
};

type PersonaOsResponse = {
  reply: string;
  meta?: Record<string, unknown>;
};

export async function POST(req: NextRequest) {
  try {
    const body = (await req.json()) as FrontendChatRequestBody;
    const { characterId, messages, userId, chatMode, ageGroup } = body;

    if (!characterId || !Array.isArray(messages) || messages.length === 0) {
      return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
    }

    const lastUserMessage = [...messages].reverse().find((m) => m.role === "user");
    if (!lastUserMessage?.content?.trim()) {
      return NextResponse.json({ error: "No user message found" }, { status: 400 });
    }

    const normalizedUserId =
      typeof userId === "string" && userId.trim() ? userId.trim() : null;
    const endpointToUse = normalizedUserId
      ? PERSONA_OS_LOCAL_ENDPOINT
      : PERSONA_OS_ENDPOINT;
    const sessionIdToUse = normalizedUserId || "frontend-session";

    const personaResponse = await fetch(endpointToUse, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(req.headers.get("authorization")
          ? { Authorization: String(req.headers.get("authorization")) }
          : {}),
        ...(process.env.SIGMARIS_INTERNAL_TOKEN
          ? { "X-Sigmaris-Internal-Token": process.env.SIGMARIS_INTERNAL_TOKEN }
          : {}),
      },
      body: JSON.stringify({
        session_id: sessionIdToUse,
        user_id: normalizedUserId,
        character_id: characterId,
        chat_mode: chatMode || "partner",
        messages: messages.map((message) => ({
          role: message.role === "ai" ? "assistant" : message.role,
          content: message.content,
        })),
        user_profile: {
          age_group: ageGroup || "unknown",
        },
        client_context: {
          ui_type: "web",
          surface: "chat",
          locale: req.headers.get("accept-language") || "ja-JP",
        },
        conversation_profile: {
          response_style: "auto",
        },
      }),
    });

    if (!personaResponse.ok) {
      const text = await personaResponse.text();
      console.error("[Persona OS Error]", {
        status: personaResponse.status,
        endpoint: endpointToUse,
        body: text,
      });
      throw new Error("Persona OS API request failed");
    }

    const personaJson = (await personaResponse.json()) as PersonaOsResponse;
    return NextResponse.json({
      role: "ai",
      content: personaJson.reply,
      meta: personaJson.meta || {},
    });
  } catch (error) {
    console.error("[/api/chat] Error:", error);
    return NextResponse.json(
      {
        role: "ai",
        content: "……少し配線が乱れたみたいだね。少し置いてからもう一度試してくれ。",
      },
      { status: 500 },
    );
  }
}
