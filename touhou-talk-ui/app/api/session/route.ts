/**
 * Session list / creation API for Touhou Talk.
 *
 * This route now supports mixed rooms:
 * - owner human + multiple AI characters
 * - owner human + invited human emails/userIds + AI characters
 */

import { NextRequest, NextResponse } from "next/server";

import { requireUser } from "@/lib/supabase-server";
import { listAccessibleTouhouSessions } from "@/lib/rooms/access";
import {
  buildSessionParticipants,
  getPrimaryAiCharacterId,
  normalizeRoomParticipants,
  type RoomParticipant,
} from "@/lib/rooms/participants";
import { supabaseAdmin } from "@/lib/supabase-server";

type SessionMode = "single" | "group";
type ChatMode = "partner" | "roleplay" | "coach";

type CreateSessionRequest = {
  characterId?: string;
  participantCharacterIds?: string[];
  invitedHumans?: Array<{
    userId?: string | null;
    displayName?: string | null;
    email?: string | null;
  }>;
  mode?: SessionMode;
  layer?: string;
  location?: string;
  chatMode?: ChatMode;
};

type ConversationRow = {
  id: string;
  title: string | null;
  character_id: string;
  mode: SessionMode;
  layer: string | null;
  location: string | null;
  chat_mode: ChatMode | null;
  meta: Record<string, unknown> | null;
  created_at: string;
};

export type SessionSummary = {
  id: string;
  title: string;
  characterId: string;
  mode: SessionMode;
  layer: string | null;
  location: string | null;
  chatMode: ChatMode;
  participants: RoomParticipant[];
  meta?: Record<string, unknown> | null;
  createdAt: string;
};

type CreateSessionResponse = {
  sessionId: string;
};

export async function GET(req: NextRequest) {
  try {
    const user = await requireUser();
    const sessions = await listAccessibleTouhouSessions({ user, limit: 200 });

    const response: SessionSummary[] = sessions.map((row) => ({
      id: row.id,
      title: row.title ?? "新しい会話",
      characterId: row.character_id ?? "",
      mode: row.mode ?? "single",
      layer: row.layer,
      location: row.location,
      chatMode: (row.chat_mode ?? "partner") as ChatMode,
      participants: normalizeRoomParticipants({
        meta: row.meta ?? null,
        fallbackCharacterId: row.character_id,
      }),
      meta: row.meta ?? null,
      createdAt: row.created_at,
    }));

    return NextResponse.json({ sessions: response });
  } catch (err) {
    console.error("[/api/session][GET] Error:", err);
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
}

export async function POST(req: NextRequest) {
  try {
    const supabase = supabaseAdmin();
    const user = await requireUser();
    const userId = user.id;

    const body = (await req.json()) as CreateSessionRequest;
    const {
      characterId,
      participantCharacterIds,
      invitedHumans,
      mode = "single",
      layer,
      location,
      chatMode,
    } = body;

    const aiCharacterIds = Array.from(
      new Set(
        [
          ...(Array.isArray(participantCharacterIds) ? participantCharacterIds : []),
          ...(typeof characterId === "string" && characterId.trim() ? [characterId.trim()] : []),
        ]
          .filter((value): value is string => typeof value === "string")
          .map((value) => value.trim())
          .filter(Boolean),
      ),
    );

    if (aiCharacterIds.length === 0) {
      return NextResponse.json({ error: "Invalid request body" }, { status: 400 });
    }

    if (mode !== "single" && mode !== "group") {
      return NextResponse.json({ error: "Invalid session mode" }, { status: 400 });
    }

    const cm: ChatMode = chatMode ?? "partner";
    if (cm !== "partner" && cm !== "roleplay" && cm !== "coach") {
      return NextResponse.json({ error: "Invalid chat mode" }, { status: 400 });
    }

    const participants = buildSessionParticipants({
      owner: user,
      aiCharacterIds,
      invitedHumans,
    });
    const primaryCharacterId = getPrimaryAiCharacterId(participants, aiCharacterIds[0]);
    if (!primaryCharacterId) {
      return NextResponse.json({ error: "Failed to resolve primary character" }, { status: 400 });
    }

    const roomMode: SessionMode = aiCharacterIds.length > 1 ? "group" : mode;
    const roomKind = participants.some((participant) => participant.kind === "human" && !participant.isSelf)
      ? "mixed"
      : aiCharacterIds.length > 1
        ? "group_ai"
        : "single";

    const insertPayload: Record<string, unknown> = {
      user_id: userId,
      app: "touhou",
      title: roomMode === "group" ? "新しいルーム" : "新しい会話",
      character_id: primaryCharacterId,
      mode: roomMode,
      layer: layer ?? null,
      location: location ?? null,
      chat_mode: cm,
      meta: {
        participants,
        room_kind: roomKind,
        participant_character_ids: aiCharacterIds,
        owner_user_id: userId,
        last_speaker_character_id: primaryCharacterId,
      },
    };

    const { data, error } = await supabase
      .from("common_sessions")
      .insert(insertPayload)
      .select("id")
      .single();

    if (error || !data) {
      console.error("[/api/session][POST] Supabase error:", error);
      return NextResponse.json({ error: "Failed to create session" }, { status: 500 });
    }

    const response: CreateSessionResponse = { sessionId: data.id };
    return NextResponse.json(response);
  } catch (err) {
    console.error("[/api/session][POST] Error:", err);
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
}
