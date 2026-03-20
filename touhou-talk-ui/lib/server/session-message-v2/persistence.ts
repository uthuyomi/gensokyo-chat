import { isRecord } from "../session-message/meta";
import { supabaseServer } from "@/lib/supabase-server";
import {
  Phase04LinkAnalysis,
  Phase04Attachment,
} from "@/lib/server/session-message-v2/types";

export function retrievalSystemHint(params: {
  linkAnalyses: Phase04LinkAnalysis[];
}) {
  void params;
  return "";
}

export function toStateSnapshotRow(params: {
  userId: string;
  sessionId: string;
  meta: Record<string, unknown>;
}) {
  const meta = params.meta ?? {};

  const traceId = typeof meta.trace_id === "string" ? meta.trace_id : null;

  const globalState =
    isRecord(meta.global_state) && typeof meta.global_state.state === "string"
      ? meta.global_state.state
      : null;

  const overloadScore =
    isRecord(meta.controller_meta) &&
    typeof meta.controller_meta.overload_score === "number"
      ? meta.controller_meta.overload_score
      : isRecord(meta.global_state) &&
          isRecord(meta.global_state.meta) &&
          typeof meta.global_state.meta.overload_score === "number"
        ? meta.global_state.meta.overload_score
        : null;

  const reflectiveScore =
    isRecord(meta.global_state) &&
    isRecord(meta.global_state.meta) &&
    typeof meta.global_state.meta.reflective_score === "number"
      ? meta.global_state.meta.reflective_score
      : null;

  const memoryPointerCount =
    isRecord(meta.controller_meta) &&
    isRecord(meta.controller_meta.memory) &&
    typeof meta.controller_meta.memory.pointer_count === "number"
      ? meta.controller_meta.memory.pointer_count
      : isRecord(meta.memory) && typeof meta.memory.pointer_count === "number"
        ? meta.memory.pointer_count
        : null;

  const safetyFlag =
    isRecord(meta.safety) && typeof meta.safety.flag === "string"
      ? meta.safety.flag
      : typeof meta.safety_flag === "string"
        ? meta.safety_flag
        : null;

  const safetyRiskScore =
    isRecord(meta.safety) && typeof meta.safety.risk_score === "number"
      ? meta.safety.risk_score
      : null;

  return {
    user_id: params.userId,
    session_id: params.sessionId,
    trace_id: traceId,
    global_state: globalState,
    overload_score: overloadScore,
    reflective_score: reflectiveScore,
    memory_pointer_count: memoryPointerCount,
    safety_flag: safetyFlag,
    safety_risk_score: safetyRiskScore,
    value_state: isRecord(meta.value) ? (meta.value.state ?? null) : null,
    trait_state: isRecord(meta.trait) ? (meta.trait.state ?? null) : null,
    meta,
    created_at: new Date().toISOString(),
  };
}

export async function saveUserMessage(params: {
    supabase: Awaited<ReturnType<typeof supabaseServer>>;
    sessionId: string;
    userId: string;
    content: string;
    phase04Uploads: Phase04Attachment[];
    phase04Links: Phase04LinkAnalysis[];
}) { 
    const { error } = await params.supabase
        .from("common_messages")
        .insert({
            session_id: params.sessionId,
            user_id: params.userId,
            app: "touhou",
            role: "user",
            content: params.content,
            speaker_id: null,
            meta: {
                phase04: {
                    uploads: params.phase04Uploads,
                    link_analyses: params.phase04Links,
                },
            },
        });
    return error;
}

export async function saveAssistantMessage(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  sessionId: string;
  userId: string;
  characterId: string;
  content: string;
  meta: Record<string, unknown>;
}) { 
   const { error } = await params.supabase
     .from("common_messages")
     .insert({
       session_id: params.sessionId,
       user_id: params.userId,
       app: "touhou",
       role: "ai",
       content: params.content,
       speaker_id: params.characterId,
       meta: params.meta,
     });
  
  return error;
}

export async function saveStateSnapshot(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  userId: string;
  sessionId: string;
  meta: Record<string, unknown>;
}) { 
  try {
    await params.supabase.from("common_state_snapshots").insert([
      toStateSnapshotRow({
        userId: params.userId,
        sessionId: params.sessionId,
        meta: params.meta,
      }),
    ]);
    return null;
  } catch (error) { 
    return error;
  }
}