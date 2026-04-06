import { NextRequest, NextResponse } from "next/server";

import { getAccessibleTouhouSession } from "@/lib/rooms/access";
import { requireUser } from "@/lib/supabase-server";
import { supabaseAdmin } from "@/lib/supabase-server";

function looksLikeMissingColumn(err: unknown, column: string) {
  const msg =
    (typeof (err as { message?: unknown } | null)?.message === "string"
      ? String((err as { message?: unknown }).message)
      : "") || String(err ?? "");
  return msg.includes(column) && (msg.includes("column") || msg.includes("schema"));
}

export async function PATCH(
  req: NextRequest,
  context: { params: Promise<{ sessionId: string }> },
) {
  try {
    const { sessionId } = await context.params;
    const user = await requireUser();
    const supabase = supabaseAdmin();

    const body = (await req.json()) as { title?: unknown; chatMode?: unknown };
    const title = typeof body.title === "string" ? body.title.trim() : null;
    const chatMode = typeof body.chatMode === "string" ? body.chatMode : null;

    const patch: Record<string, unknown> = {};
    if (title) patch.title = title;
    if (chatMode) patch.chat_mode = chatMode;

    if (Object.keys(patch).length === 0) {
      return NextResponse.json({ error: "No patch fields" }, { status: 400 });
    }

    if ("chat_mode" in patch) {
      const cm = String(patch.chat_mode);
      if (cm !== "partner" && cm !== "roleplay" && cm !== "coach") {
        return NextResponse.json({ error: "Invalid chatMode" }, { status: 400 });
      }
    }

    const session = await getAccessibleTouhouSession({ sessionId, user });
    if (!session) {
      return NextResponse.json({ error: "Session not found" }, { status: 404 });
    }
    if (!session.isOwner) {
      return NextResponse.json({ error: "Only the room owner can update room settings" }, { status: 403 });
    }

    const { error } = await supabase
      .from("common_sessions")
      .update(patch)
      .eq("id", sessionId)
      .eq("app", "touhou");

    if (error) {
      if ("chat_mode" in patch && looksLikeMissingColumn(error, "chat_mode")) {
        return NextResponse.json(
          {
            error: "chat_mode column is missing",
            hint: "Run supabase/RESET_TO_COMMON.sql in Supabase SQL Editor.",
          },
          { status: 409 },
        );
      }
      console.error("[PATCH session] Supabase error:", error);
      return NextResponse.json({ error: "Update failed" }, { status: 500 });
    }

    return NextResponse.json({ ok: true, sessionId });
  } catch (err) {
    console.error("[PATCH session] Error:", err);
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
}

export async function DELETE(
  req: NextRequest,
  context: { params: Promise<{ sessionId: string }> },
) {
  try {
    const { sessionId } = await context.params;
    const user = await requireUser();
    const supabase = supabaseAdmin();

    const session = await getAccessibleTouhouSession({ sessionId, user });
    if (!session) {
      return NextResponse.json({ error: "Session not found" }, { status: 404 });
    }
    if (!session.isOwner) {
      return NextResponse.json({ error: "Only the room owner can delete the room" }, { status: 403 });
    }

    const { error } = await supabase
      .from("common_sessions")
      .delete()
      .eq("id", sessionId)
      .eq("app", "touhou");

    if (error) {
      console.error("[DELETE session] Supabase error:", error);
      return NextResponse.json({ error: "Delete failed" }, { status: 500 });
    }

    return NextResponse.json({ ok: true, sessionId });
  } catch (err) {
    console.error("[DELETE session] Error:", err);
    return NextResponse.json({ error: "Unauthorized" }, { status: 401 });
  }
}
