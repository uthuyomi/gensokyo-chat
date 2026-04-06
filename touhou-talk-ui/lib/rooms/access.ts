import type { User } from "@supabase/supabase-js";

import { supabaseAdmin } from "@/lib/supabase-server";
import {
  normalizeRoomParticipants,
  type RoomParticipant,
} from "@/lib/rooms/participants";

type SessionRow = {
  id: string;
  user_id: string;
  app: string;
  title: string | null;
  character_id: string | null;
  mode: "single" | "group" | null;
  layer: string | null;
  location: string | null;
  chat_mode: "partner" | "roleplay" | "coach" | null;
  meta: Record<string, unknown> | null;
  created_at: string;
  updated_at?: string;
};

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

export type AccessibleSession = SessionRow & {
  participants: RoomParticipant[];
  isOwner: boolean;
};

export function canUserAccessParticipants(params: {
  user: Pick<User, "id" | "email">;
  participants: RoomParticipant[];
}) {
  const email = typeof params.user.email === "string" ? params.user.email.trim().toLowerCase() : "";
  return params.participants.some((participant) => {
    if (participant.kind !== "human") return false;
    const participantUserId =
      typeof participant.userId === "string" ? participant.userId.trim() : "";
    const participantEmail =
      typeof participant.email === "string" ? participant.email.trim().toLowerCase() : "";
    return participantUserId === params.user.id || (!!email && participantEmail === email);
  });
}

export function toAccessibleSession(params: {
  row: SessionRow;
  user: Pick<User, "id" | "email">;
}): AccessibleSession | null {
  const participants = normalizeRoomParticipants({
    meta: params.row.meta ?? null,
    fallbackCharacterId:
      typeof params.row.character_id === "string" ? params.row.character_id : null,
  }).map((participant) => {
    if (participant.kind !== "human") return participant;
    const participantEmail =
      typeof participant.email === "string" ? participant.email.trim().toLowerCase() : "";
    const userEmail =
      typeof params.user.email === "string" ? params.user.email.trim().toLowerCase() : "";
    const isSelf =
      participant.userId === params.user.id ||
      (!!participantEmail && !!userEmail && participantEmail === userEmail);
    return { ...participant, isSelf };
  });

  const isOwner = params.row.user_id === params.user.id;
  if (!isOwner && !canUserAccessParticipants({ user: params.user, participants })) {
    return null;
  }

  return {
    ...params.row,
    participants,
    isOwner,
  };
}

export async function listAccessibleTouhouSessions(params: {
  user: Pick<User, "id" | "email">;
  limit?: number;
}) {
  const supabase = supabaseAdmin();
  const limit = typeof params.limit === "number" ? Math.max(1, Math.min(300, params.limit)) : 200;

  const { data, error } = await supabase
    .from("common_sessions")
    .select("id, user_id, app, title, character_id, mode, layer, location, chat_mode, meta, created_at, updated_at")
    .eq("app", "touhou")
    .order("created_at", { ascending: false })
    .limit(limit);

  if (error) throw error;

  return (Array.isArray(data) ? data : [])
    .map((row) => toAccessibleSession({ row: row as SessionRow, user: params.user }))
    .filter((row): row is AccessibleSession => !!row);
}

export async function getAccessibleTouhouSession(params: {
  sessionId: string;
  user: Pick<User, "id" | "email">;
}) {
  const supabase = supabaseAdmin();
  const { data, error } = await supabase
    .from("common_sessions")
    .select("id, user_id, app, title, character_id, mode, layer, location, chat_mode, meta, created_at, updated_at")
    .eq("id", params.sessionId)
    .eq("app", "touhou")
    .maybeSingle();

  if (error) throw error;
  if (!data) return null;
  return toAccessibleSession({ row: data as SessionRow, user: params.user });
}

export function mergeSessionMeta(base: unknown, patch: Record<string, unknown>) {
  const seed = isRecord(base) ? { ...base } : {};
  return { ...seed, ...patch };
}
