import { NextResponse } from "next/server";

import { supabaseServer, requireUser } from "@/lib/supabase-server";
import { resolveCoreBaseUrl } from "@/lib/server/session-message/core-base";
import { loadCoreHistory } from "@/lib/server/session-message/history";
import type { TouhouChatMode } from "@/lib/touhouPersona";
import { getAccessibleTouhouSession } from "@/lib/rooms/access";

import type { SessionMessageRouteContext } from "./types";

export type SessionMessageLoadedContext = {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  userId: string;
  sessionId: string;
  accessToken: string | null;
  conv: Record<string, unknown>;
  coreHistory: Array<{ role: "user" | "assistant"; content: string }>;
  base: string;
  chatMode: TouhouChatMode;
};

export async function buildSessionMessageContext(params: {
  context: SessionMessageRouteContext;
  coreModeRaw: FormDataEntryValue | null;
}): Promise<SessionMessageLoadedContext | Response> {
  const { sessionId } = await params.context.params;
  if (!sessionId || typeof sessionId !== "string") {
    return NextResponse.json({ error: "Missing sessionId" }, { status: 400 });
  }

  let userId: string;
  let userEmail: string | null = null;
  try {
    const user = await requireUser();
    userId = user.id;
    userEmail = typeof user.email === "string" ? user.email : null;
  } catch {
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }

  const supabase = await supabaseServer();

  const minIntervalMsRaw = Number(process.env.TOUHOU_RATE_LIMIT_MS ?? "1200");
  const minIntervalMs = Number.isFinite(minIntervalMsRaw)
    ? Math.max(0, Math.min(60_000, minIntervalMsRaw))
    : 1200;

  if (minIntervalMs > 0) {
    try {
      const { data } = await supabase
        .from("common_messages")
        .select("created_at")
        .eq("user_id", userId)
        .eq("app", "touhou")
        .order("created_at", { ascending: false })
        .limit(1)
        .maybeSingle();

      const lastIso = (data as any)?.created_at;
      const lastTs = typeof lastIso === "string" ? Date.parse(lastIso) : NaN;

      if (Number.isFinite(lastTs) && Date.now() - lastTs < minIntervalMs) {
        return NextResponse.json(
          { error: "Rate limited" },
          {
            status: 429,
            headers: {
              "Retry-After": String(Math.ceil(minIntervalMs / 1000)),
            },
          },
        );
      }
    } catch {
      // ignore
    }
  }

  let accessToken: string | null = null;
  try {
    const {
      data: { session },
    } = await supabase.auth.getSession();
    accessToken = session?.access_token ?? null;
  } catch {
    accessToken = null;
  }

  const conv = await getAccessibleTouhouSession({
    sessionId,
    user: { id: userId, ...(userEmail ? { email: userEmail } : {}) },
  });

  if (!conv) {
    return NextResponse.json(
      { error: "Conversation not found or forbidden" },
      { status: 403 },
    );
  }

  const coreHistory = await loadCoreHistory({
    sessionId,
    limit: 16,
  });

  const base = await resolveCoreBaseUrl({
    supabase,
    requestedMode:
      typeof params.coreModeRaw === "string" ? params.coreModeRaw : null,
  });

  const chatModeRaw =
    typeof (conv as Record<string, unknown>).chat_mode === "string"
      ? String((conv as Record<string, unknown>).chat_mode)
      : null;

  const chatMode: TouhouChatMode =
    chatModeRaw === "roleplay" || chatModeRaw === "coach"
      ? chatModeRaw
      : "partner";

  return {
    supabase,
    userId,
    sessionId,
    accessToken,
    conv: conv as Record<string, unknown>,
    coreHistory,
    base,
    chatMode,
  };
}
