import { NextRequest, NextResponse } from "next/server";

import { getAccessibleTouhouSession } from "@/lib/rooms/access";
import { getAiParticipants } from "@/lib/rooms/participants";
import { requireUser, supabaseAdmin } from "@/lib/supabase-server";

type MessageRow = {
  id: string;
  role: "user" | "ai";
  content: string;
  speaker_id: string | null;
  created_at: string;
  meta: Record<string, unknown> | null;
};

type MessagesResponse = {
  messages: MessageRow[];
};

export async function GET(
  req: NextRequest,
  context: { params: Promise<{ sessionId: string }> },
) {
  try {
    const { sessionId } = await context.params;
    if (!sessionId || typeof sessionId !== "string") {
      return NextResponse.json({ error: "Missing sessionId" }, { status: 400 });
    }

    const user = await requireUser();
    const session = await getAccessibleTouhouSession({ sessionId, user });
    if (!session) {
      return NextResponse.json(
        { error: "Conversation not found or forbidden" },
        { status: 403 },
      );
    }

    const supabase = supabaseAdmin();
    const { data, error } = await supabase
      .from("common_messages")
      .select("id, role, content, speaker_id, created_at, meta")
      .eq("session_id", sessionId)
      .eq("app", "touhou")
      .order("created_at", { ascending: true });

    if (error) {
      console.error("[DB:messages select error]", error);
      return NextResponse.json({ error: "Failed to fetch messages" }, { status: 500 });
    }

    const aiCharacterIds = new Set(
      getAiParticipants(session.participants).map((participant) => participant.characterId),
    );
    const filteredMessages: MessageRow[] = (data ?? []).filter((m) => {
      if (m.role === "user") return true;
      if (!m.speaker_id) return true;
      if (session.mode === "group") {
        return aiCharacterIds.size === 0 ? true : aiCharacterIds.has(m.speaker_id);
      }
      return m.speaker_id === session.character_id;
    });

    const response: MessagesResponse = { messages: filteredMessages };
    return NextResponse.json(response);
  } catch (error) {
    console.error("[/api/session/[sessionId]/messages][GET] Error:", error);
    return NextResponse.json(
      { error: "Unauthorized or server error" },
      { status: 401 },
    );
  }
}
