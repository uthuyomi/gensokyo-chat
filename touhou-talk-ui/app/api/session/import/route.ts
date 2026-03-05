import { NextRequest, NextResponse } from "next/server";
import { requireUserId, supabaseServer } from "@/lib/supabase-server";

type SessionMode = "single" | "group";
type ChatMode = "partner" | "roleplay" | "coach";

type ImportMessageRequest = {
  role: "user" | "ai";
  content: string;
  meta?: Record<string, unknown> | null;
};

type ImportMessage = {
  role: "user" | "ai";
  content: string;
  meta: Record<string, unknown> | null;
};

type ImportSession = {
  title?: string;
  externalSessionId?: string;
  messages: ImportMessageRequest[];
};

type ImportRequest = {
  characterId: string;
  mode?: SessionMode;
  layer?: string | null;
  location?: string | null;
  chatMode?: ChatMode;
  sessions: ImportSession[];
};

type ImportResponse = {
  sessions: Array<{
    sessionId: string;
    title: string;
    externalSessionId?: string;
  }>;
};

function isChatMode(v: unknown): v is ChatMode {
  return v === "partner" || v === "roleplay" || v === "coach";
}

function isSessionMode(v: unknown): v is SessionMode {
  return v === "single" || v === "group";
}

function normalizeMeta(v: unknown): Record<string, unknown> | null {
  if (!v) return null;
  if (typeof v !== "object" || Array.isArray(v)) return null;
  return v as Record<string, unknown>;
}

export async function POST(req: NextRequest) {
  try {
    const supabase = await supabaseServer();
    const userId = await requireUserId();

    const body = (await req.json()) as ImportRequest;

    const characterId =
      typeof body?.characterId === "string" ? body.characterId.trim() : "";
    if (!characterId) {
      return NextResponse.json({ error: "Missing characterId" }, { status: 400 });
    }

    const chatMode: ChatMode = isChatMode(body?.chatMode) ? body.chatMode : "partner";
    const mode: SessionMode = isSessionMode(body?.mode) ? body.mode : "single";

    const sessions = Array.isArray(body?.sessions) ? body.sessions : [];
    if (sessions.length === 0) {
      return NextResponse.json({ error: "No sessions to import" }, { status: 400 });
    }

    // Safety limits (avoid accidental huge import)
    const MAX_SESSIONS = 500;
    const MAX_MESSAGES_TOTAL = 20000;
    if (sessions.length > MAX_SESSIONS) {
      return NextResponse.json(
        { error: `Too many sessions (max ${MAX_SESSIONS})` },
        { status: 400 },
      );
    }

    const totalMessages = sessions.reduce(
      (acc, s) => acc + (Array.isArray(s?.messages) ? s.messages.length : 0),
      0,
    );
    if (totalMessages > MAX_MESSAGES_TOTAL) {
      return NextResponse.json(
        { error: `Too many messages (max ${MAX_MESSAGES_TOTAL})` },
        { status: 400 },
      );
    }

    const layer = typeof body?.layer === "string" ? body.layer : null;
    const location = typeof body?.location === "string" ? body.location : null;

    const response: ImportResponse["sessions"] = [];

    for (let si = 0; si < sessions.length; si++) {
      const s = sessions[si];
      const externalSessionId =
        typeof s?.externalSessionId === "string" ? s.externalSessionId : undefined;

      const messages = Array.isArray(s?.messages) ? s.messages : [];
      const cleanedMessages = messages
        .map((m) => {
          if (!m || (m.role !== "user" && m.role !== "ai")) return null;
          const content = typeof m.content === "string" ? m.content : String(m.content ?? "");
          if (!content.trim()) return null;
          return {
            role: m.role,
            content,
            meta: normalizeMeta(m.meta),
          } satisfies ImportMessage;
        })
        .filter((m): m is ImportMessage => !!m);

      if (cleanedMessages.length === 0) continue;

      const titleBase =
        typeof s?.title === "string" && s.title.trim()
          ? s.title.trim()
          : sessions.length > 1
            ? `復元した会話 (${si + 1})`
            : "復元した会話";

      const { data: inserted, error: insertSessionError } = await supabase
        .from("common_sessions")
        .insert({
          user_id: userId,
          app: "touhou",
          title: titleBase,
          character_id: characterId,
          mode,
          layer,
          location,
          chat_mode: chatMode,
        })
        .select("id")
        .single<{ id: string }>();

      if (insertSessionError || !inserted) {
        console.error("[/api/session/import] session insert error:", insertSessionError);
        return NextResponse.json(
          { error: "Failed to create imported session" },
          { status: 500 },
        );
      }

      const sessionId = inserted.id;

      // Preserve message order:
      // - Postgres `now()` is statement-stable, so multi-row insert would share the same created_at.
      // - We set created_at explicitly with a monotonic 1ms step.
      const baseMs = Date.now() - cleanedMessages.length - 10;

      const rows = cleanedMessages.map((m, idx) => ({
        session_id: sessionId,
        user_id: userId,
        app: "touhou",
        role: m.role,
        content: m.content,
        speaker_id: m.role === "ai" ? characterId : null,
        meta: m.meta ?? null,
        created_at: new Date(baseMs + idx).toISOString(),
      }));

      const CHUNK = 400;
      for (let i = 0; i < rows.length; i += CHUNK) {
        const chunk = rows.slice(i, i + CHUNK);
        const { error: insertMessagesError } = await supabase
          .from("common_messages")
          .insert(chunk);

        if (insertMessagesError) {
          console.error(
            "[/api/session/import] message insert error:",
            insertMessagesError,
          );
          return NextResponse.json(
            { error: "Failed to save imported messages" },
            { status: 500 },
          );
        }
      }

      response.push({ sessionId, title: titleBase, externalSessionId });
    }

    if (response.length === 0) {
      return NextResponse.json(
        { error: "No valid messages found in import payload" },
        { status: 400 },
      );
    }

    return NextResponse.json({ sessions: response } satisfies ImportResponse);
  } catch (e) {
    console.error("[/api/session/import] Error:", e);
    return NextResponse.json({ error: "Unauthorized or server error" }, { status: 401 });
  }
}
