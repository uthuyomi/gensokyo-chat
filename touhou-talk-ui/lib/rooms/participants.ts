import type { User } from "@supabase/supabase-js";

import { CHARACTERS } from "@/data/characters";

export type RoomParticipantHuman = {
  id: string;
  kind: "human";
  userId: string | null;
  displayName: string;
  email?: string | null;
  isSelf?: boolean;
};

export type RoomParticipantAi = {
  id: string;
  kind: "ai_character";
  characterId: string;
  displayName: string;
  title?: string | null;
};

export type RoomParticipant = RoomParticipantHuman | RoomParticipantAi;

export function buildOwnerHumanParticipant(user: Pick<User, "id" | "email" | "user_metadata">): RoomParticipantHuman {
  const md = (user.user_metadata ?? {}) as Record<string, unknown>;
  const displayName =
    (typeof md.full_name === "string" && md.full_name.trim()) ||
    (typeof md.name === "string" && md.name.trim()) ||
    (typeof user.email === "string" && user.email.trim()) ||
    "You";

  return {
    id: `human:${user.id}`,
    kind: "human",
    userId: user.id,
    displayName,
    email: typeof user.email === "string" ? user.email : null,
    isSelf: true,
  };
}

function buildAiParticipant(characterId: string): RoomParticipantAi | null {
  const ch = CHARACTERS[characterId];
  if (!ch) return null;
  return {
    id: `ai:${characterId}`,
    kind: "ai_character",
    characterId,
    displayName: ch.name,
    title: ch.title,
  };
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return !!value && typeof value === "object" && !Array.isArray(value);
}

function normalizeParticipant(raw: unknown): RoomParticipant | null {
  if (!isRecord(raw)) return null;
  const kind = typeof raw.kind === "string" ? raw.kind : "";
  if (kind === "human") {
    const displayName =
      typeof raw.displayName === "string" && raw.displayName.trim()
        ? raw.displayName.trim()
        : typeof raw.email === "string" && raw.email.trim()
          ? raw.email.trim()
          : "User";
    return {
      id:
        typeof raw.id === "string" && raw.id.trim()
          ? raw.id.trim()
          : typeof raw.userId === "string" && raw.userId.trim()
            ? `human:${raw.userId.trim()}`
            : `human:${displayName}`,
      kind: "human",
      userId: typeof raw.userId === "string" && raw.userId.trim() ? raw.userId.trim() : null,
      displayName,
      email: typeof raw.email === "string" && raw.email.trim() ? raw.email.trim() : null,
      isSelf: raw.isSelf === true,
    };
  }
  if (kind === "ai_character") {
    const characterId =
      typeof raw.characterId === "string" && raw.characterId.trim()
        ? raw.characterId.trim()
        : "";
    if (!characterId || !CHARACTERS[characterId]) return null;
    return {
      id:
        typeof raw.id === "string" && raw.id.trim()
          ? raw.id.trim()
          : `ai:${characterId}`,
      kind: "ai_character",
      characterId,
      displayName:
        typeof raw.displayName === "string" && raw.displayName.trim()
          ? raw.displayName.trim()
          : CHARACTERS[characterId].name,
      title:
        typeof raw.title === "string" && raw.title.trim()
          ? raw.title.trim()
          : CHARACTERS[characterId].title,
    };
  }
  return null;
}

export function normalizeRoomParticipants(params: {
  meta: unknown;
  fallbackCharacterId?: string | null;
}): RoomParticipant[] {
  const meta = isRecord(params.meta) ? params.meta : null;
  const rawParticipants = Array.isArray(meta?.participants) ? meta?.participants : [];
  const normalized = rawParticipants
    .map((entry) => normalizeParticipant(entry))
    .filter((entry): entry is RoomParticipant => !!entry);

  const seen = new Set<string>();
  const deduped: RoomParticipant[] = [];
  for (const participant of normalized) {
    if (seen.has(participant.id)) continue;
    seen.add(participant.id);
    deduped.push(participant);
  }

  if (deduped.length > 0) return deduped;

  const fallbackCharacterId =
    typeof params.fallbackCharacterId === "string" && params.fallbackCharacterId.trim()
      ? params.fallbackCharacterId.trim()
      : "";
  const fallbackAi = fallbackCharacterId ? buildAiParticipant(fallbackCharacterId) : null;
  return fallbackAi ? [fallbackAi] : [];
}

export function buildSessionParticipants(params: {
  owner: Pick<User, "id" | "email" | "user_metadata">;
  aiCharacterIds: string[];
  invitedHumans?: Array<{ userId?: string | null; displayName?: string | null; email?: string | null }>;
}): RoomParticipant[] {
  const participants: RoomParticipant[] = [buildOwnerHumanParticipant(params.owner)];

  for (const invited of params.invitedHumans ?? []) {
    const userId =
      typeof invited.userId === "string" && invited.userId.trim() ? invited.userId.trim() : null;
    const email =
      typeof invited.email === "string" && invited.email.trim() ? invited.email.trim() : null;
    const displayName =
      typeof invited.displayName === "string" && invited.displayName.trim()
        ? invited.displayName.trim()
        : email ?? "Guest";
    participants.push({
      id: userId ? `human:${userId}` : `human:${displayName}`,
      kind: "human",
      userId,
      displayName,
      email,
    });
  }

  for (const characterId of params.aiCharacterIds) {
    const ai = buildAiParticipant(characterId);
    if (ai) participants.push(ai);
  }

  const seen = new Set<string>();
  return participants.filter((participant) => {
    if (seen.has(participant.id)) return false;
    seen.add(participant.id);
    return true;
  });
}

export function getAiParticipants(participants: RoomParticipant[]): RoomParticipantAi[] {
  return participants.filter((participant): participant is RoomParticipantAi => participant.kind === "ai_character");
}

export function getPrimaryAiCharacterId(participants: RoomParticipant[], fallbackCharacterId?: string | null) {
  const ai = getAiParticipants(participants);
  if (ai.length > 0) return ai[0].characterId;
  if (typeof fallbackCharacterId === "string" && fallbackCharacterId.trim()) return fallbackCharacterId.trim();
  return null;
}

export function getLastSpeakerCharacterId(meta: unknown): string | null {
  if (!isRecord(meta)) return null;
  const v = meta.last_speaker_character_id;
  return typeof v === "string" && v.trim() ? v.trim() : null;
}

export function getRecentSpeakerCharacterIds(meta: unknown): string[] {
  if (!isRecord(meta)) return [];
  const direct = Array.isArray(meta.recent_speaker_character_ids)
    ? meta.recent_speaker_character_ids
    : [];
  const sceneState = isRecord(meta.scene_state) ? meta.scene_state : null;
  const nested = Array.isArray(sceneState?.recent_speaker_character_ids)
    ? sceneState.recent_speaker_character_ids
    : [];
  const out: string[] = [];
  for (const value of [...direct, ...nested]) {
    if (typeof value !== "string") continue;
    const id = value.trim();
    if (!id || out.includes(id)) continue;
    out.push(id);
  }
  return out;
}

export function withLastSpeakerCharacterId(meta: unknown, characterId: string) {
  const base = isRecord(meta) ? { ...meta } : {};
  base.last_speaker_character_id = characterId;
  return base;
}

export function withRecentSpeakerCharacterIds(meta: unknown, characterIds: string[]) {
  const base = isRecord(meta) ? { ...meta } : {};
  const normalized = characterIds
    .map((value) => (typeof value === "string" ? value.trim() : ""))
    .filter((value, index, arr): value is string => !!value && arr.indexOf(value) === index)
    .slice(0, 6);
  base.recent_speaker_character_ids = normalized;
  if (isRecord(base.scene_state)) {
    base.scene_state = {
      ...base.scene_state,
      recent_speaker_character_ids: normalized,
    };
  }
  return base;
}

function buildParticipantNeedles(participant: RoomParticipantAi) {
  const character = CHARACTERS[participant.characterId];
  return [
    participant.characterId,
    participant.displayName,
    character?.name,
    character?.title,
  ]
    .filter((v): v is string => typeof v === "string" && !!v.trim())
    .map((v) => v.trim().toLowerCase());
}

export function findMentionedGroupSpeakerIds(params: {
  text: string;
  participants: RoomParticipant[];
}) {
  const aiParticipants = getAiParticipants(params.participants);
  const text = String(params.text ?? "").trim().toLowerCase();
  if (!text) return [] as string[];
  const matched: string[] = [];
  for (const participant of aiParticipants) {
    const needles = buildParticipantNeedles(participant);
    if (needles.some((needle) => text.includes(needle))) {
      matched.push(participant.characterId);
    }
  }
  return matched;
}

function scoreDirectMention(text: string, participant: RoomParticipantAi) {
  const needles = buildParticipantNeedles(participant);
  return needles.some((needle) => text.includes(needle)) ? 120 : 0;
}

function stableBias(text: string, seed: string) {
  const src = `${text}::${seed}`;
  let hash = 0;
  for (let i = 0; i < src.length; i += 1) {
    hash = (hash * 33 + src.charCodeAt(i)) >>> 0;
  }
  return (hash % 11) - 5;
}

export function chooseGroupSpeaker(params: {
  text: string;
  participants: RoomParticipant[];
  fallbackCharacterId?: string | null;
  lastSpeakerCharacterId?: string | null;
  recentSpeakerCharacterIds?: string[] | null;
  excludeCharacterIds?: string[] | null;
}): string | null {
  const aiParticipants = getAiParticipants(params.participants);
  if (aiParticipants.length === 0) {
    return typeof params.fallbackCharacterId === "string" && params.fallbackCharacterId.trim()
      ? params.fallbackCharacterId.trim()
      : null;
  }
  if (aiParticipants.length === 1) return aiParticipants[0].characterId;

  const text = String(params.text ?? "").trim().toLowerCase();
  const last = typeof params.lastSpeakerCharacterId === "string" ? params.lastSpeakerCharacterId.trim() : "";
  const recent = (params.recentSpeakerCharacterIds ?? [])
    .map((value) => (typeof value === "string" ? value.trim() : ""))
    .filter(Boolean);
  const exclude = new Set(
    (params.excludeCharacterIds ?? [])
      .map((value) => (typeof value === "string" ? value.trim() : ""))
      .filter(Boolean),
  );

  const ranked = aiParticipants
    .filter((participant) => !exclude.has(participant.characterId))
    .map((participant, index) => {
      let score = 0;
      score += scoreDirectMention(text, participant);
      if (!text) score += 4;
      if (last) {
        if (participant.characterId === last) {
          score -= 90;
        } else {
          const lastIndex = aiParticipants.findIndex((entry) => entry.characterId === last);
          if (lastIndex >= 0) {
            const distance = (index - lastIndex + aiParticipants.length) % aiParticipants.length;
            if (distance === 1) score += 18;
            else if (distance === 2) score += 8;
          }
        }
      }
      const recentIndex = recent.findIndex((value) => value === participant.characterId);
      if (recentIndex >= 0) {
        score -= Math.max(16, 42 - recentIndex * 10);
      } else {
        score += 10;
      }
      score += stableBias(text || "room-turn", participant.characterId);
      return { characterId: participant.characterId, score, index };
    });

  if (ranked.length === 0) {
    return typeof params.fallbackCharacterId === "string" && params.fallbackCharacterId.trim()
      ? params.fallbackCharacterId.trim()
      : aiParticipants[0].characterId;
  }

  ranked.sort((a, b) => b.score - a.score || a.index - b.index);
  return ranked[0]?.characterId ?? aiParticipants[0].characterId;
}
