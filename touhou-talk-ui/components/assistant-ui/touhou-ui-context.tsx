"use client";

import { createContext, useContext } from "react";
import type { RoomParticipant } from "@/lib/rooms/participants";

type Character = {
  id: string;
  title?: string;
  promptVersion?: string;
  name?: string;
  color?: {
    accent?: string;
  };
  ui?: {
    avatar?: string;
  };
};

type SessionSummary = {
  id: string;
  characterId: string;
  mode?: "single" | "group";
  participants?: RoomParticipant[];
  meta?: Record<string, unknown> | null;
};

export type TouhouUiContextValue = {
  activeSessionId: string | null;
  sessions: SessionSummary[];
  characters: Record<string, Character>;
  visibleCharacters: Character[];
  openCreateThreadDialog: () => void;
  createThreadForCharacter: (characterId: string) => Promise<void>;
  createThreadForCharacters?: (
    characterIds: string[],
    invitedHumans?: Array<{ userId?: string | null; displayName?: string | null; email?: string | null }>,
  ) => Promise<void>;
};

const TouhouUiContext = createContext<TouhouUiContextValue | null>(null);

export function TouhouUiProvider({
  value,
  children,
}: {
  value: TouhouUiContextValue;
  children: React.ReactNode;
}) {
  return (
    <TouhouUiContext.Provider value={value}>{children}</TouhouUiContext.Provider>
  );
}

export function useTouhouUi() {
  const ctx = useContext(TouhouUiContext);
  if (!ctx) throw new Error("useTouhouUi must be used within TouhouUiProvider");
  return ctx;
}
