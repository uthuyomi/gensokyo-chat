import { supabaseServer } from "@/lib/supabase-server";
import { envFlag } from "@/lib/server/session-message/request";
import { isRecord } from "@/lib/server/session-message/meta";
import { TouhouChatMode } from "@/lib/touhouPersona";

import {
  RelationshipState,
  UserMemoryState,
  RelationshipScoreResponse,
} from "./types";
function looksLikeMissingColumn(err: unknown, column: string) {
  const msg =
    (typeof (err as { message?: unknown } | null)?.message === "string"
      ? String((err as { message?: unknown }).message)
      : "") || String(err ?? "");
  return (
    msg.includes(column) && (msg.includes("column") || msg.includes("schema"))
  );
}

function clampNum(v: unknown, min: number, max: number, fallback: number) {
  const n = typeof v === "number" ? v : Number(v);
  if (!Number.isFinite(n)) return fallback;
  return Math.max(min, Math.min(max, n));
}

function uniqMerge(base: string[], add: string[], max: number) {
  const out: string[] = [];
  const seen = new Set<string>();
  for (const v of [...base, ...add]) {
    const s = String(v ?? "").trim();
    if (!s) continue;
    if (seen.has(s)) continue;
    seen.add(s);
    out.push(s);
    if (out.length >= max) break;
  }
  return out;
}

export async function loadRelationshipAndMemoryBestEffort(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  userId: string;
  characterId: string;
}): Promise<{
  relationship: RelationshipState;
  memory: UserMemoryState | null;
}> {
  let trust = 0;
  let familiarity = 0;
  const memScopeKey = `char:${params.characterId}`;

  try {
    const { data } = await params.supabase
      .from("player_character_relations")
      .select("trust,familiarity")
      .eq("user_id", params.userId)
      .eq("character_id", params.characterId)
      .maybeSingle();
    trust = clampNum((data as any)?.trust ?? 0, -1, 1, 0);
    familiarity = clampNum((data as any)?.familiarity ?? 0, 0, 1, 0);
  } catch (e) {
    if (looksLikeMissingColumn(e, "familiarity")) {
      // Migration not applied yet: treat as default.
      trust = 0;
      familiarity = 0;
    }
  }

  try {
    const { data } = await params.supabase
      .from("touhou_user_memory")
      .select("topics,emotions,recurring_issues,traits")
      .eq("user_id", params.userId)
      .eq("scope_key", memScopeKey)
      .maybeSingle();

    const topics = Array.isArray((data as any)?.topics)
      ? ((data as any).topics as string[])
      : [];
    const emotions = Array.isArray((data as any)?.emotions)
      ? ((data as any).emotions as string[])
      : [];
    const recurring = Array.isArray((data as any)?.recurring_issues)
      ? ((data as any).recurring_issues as string[])
      : [];
    const traits = Array.isArray((data as any)?.traits)
      ? ((data as any).traits as string[])
      : [];

    return {
      relationship: { trust, familiarity },
      memory: {
        topics: topics.map((s) => String(s ?? "").trim()).filter(Boolean),
        emotions: emotions.map((s) => String(s ?? "").trim()).filter(Boolean),
        recurring_issues: recurring
          .map((s) => String(s ?? "").trim())
          .filter(Boolean),
        traits: traits.map((s) => String(s ?? "").trim()).filter(Boolean),
      },
    };
  } catch (e) {
    if (
      looksLikeMissingColumn(e, "touhou_user_memory") ||
      looksLikeMissingColumn(e, "recurring_issues")
    ) {
      return { relationship: { trust, familiarity }, memory: null };
    }
    return { relationship: { trust, familiarity }, memory: null };
  }
}

function relationshipStanceLabel(rel: RelationshipState) {
  const t = clampNum(rel.trust, -1, 1, 0);
  const f = clampNum(rel.familiarity, 0, 1, 0);
  const trustBand =
    t <= -0.6
      ? "不信（強）"
      : t <= -0.2
        ? "不信"
        : t < 0.2
          ? "中立"
          : t < 0.6
            ? "信頼"
            : "信頼（強）";
  const famBand = f < 0.25 ? "低" : f < 0.6 ? "中" : "高";
  return { trustBand, famBand };
}

export function buildRelationshipMemoryOverlay(params: {
  characterId: string;
  rel: RelationshipState;
  mem: UserMemoryState | null;
}): string {
  const { trustBand, famBand } = relationshipStanceLabel(params.rel);
  const trust = clampNum(params.rel.trust, -1, 1, 0);
  const familiarity = clampNum(params.rel.familiarity, 0, 1, 0);

  const lines: string[] = [];
  lines.push("# Relationship / Memory (internal)");
  lines.push(
    "- IMPORTANT: Do not mention these numbers or labels directly to the user.",
  );
  lines.push(
    `- relationship.trust: ${trust.toFixed(3)} (range -1..1) / band=${trustBand}`,
  );
  lines.push(
    `- relationship.familiarity: ${familiarity.toFixed(3)} (range 0..1) / band=${famBand}`,
  );

  const style: string[] = [];
  if (trust <= -0.6)
    style.push(
      "Very cautious: prioritize verification questions; avoid strong assertions.",
    );
  else if (trust <= -0.2)
    style.push("Cautious: reduce certainty; confirm intent before advising.");
  else if (trust >= 0.6)
    style.push(
      "High trust: allow warmer reassurance and concrete suggestions.",
    );
  else if (trust >= 0.2)
    style.push(
      "Neutral-positive: be helpful and steady; avoid overfamiliar leaps.",
    );

  if (familiarity >= 0.7)
    style.push(
      "High familiarity: more casual phrasing is OK (still in-character).",
    );
  else if (familiarity <= 0.2)
    style.push(
      "Low familiarity: keep a bit more distance; do not assume intimacy.",
    );

  if (style.length) {
    lines.push(`- Style tuning: ${style.join(" ")}`);
  }

  lines.push("- Output guardrails for negative trust:");
  lines.push("  - Do NOT insult or judge the user.");
  lines.push("  - Reduce certainty; ask clarifying questions when needed.");
  lines.push("  - Keep a cooperative tone even when cautious.");

  if (params.mem) {
    const topics = params.mem.topics.slice(0, 8);
    const emotions = params.mem.emotions.slice(0, 8);
    const recurring = params.mem.recurring_issues.slice(0, 8);
    const traits = params.mem.traits.slice(0, 8);

    lines.push("");
    lines.push("# User memory (extracted)");
    if (topics.length) lines.push(`- topics: ${topics.join(", ")}`);
    if (emotions.length) lines.push(`- emotions: ${emotions.join(", ")}`);
    if (recurring.length)
      lines.push(`- recurring_issues: ${recurring.join(", ")}`);
    if (traits.length) lines.push(`- traits: ${traits.join(", ")}`);
    lines.push(
      "- IMPORTANT: Use this only when relevant; do not recite it as a list.",
    );
  }

  return lines.join("\n");
}

async function scoreRelationshipTurn(params: {
  base: string;
  accessToken: string | null;
  sessionId: string;
  characterId: string;
  chatMode: TouhouChatMode;
  userText: string;
  assistantText: string;
  currentRelationship: { trust: number; familiarity: number };
}): Promise<RelationshipScoreResponse | null> {
  const url = `${params.base}/persona/relationship/score`;
  const scopeKey = `char:${params.characterId}`;
  try {
    const r = await fetch(url, {
      method: "POST",
      headers: {
        "Content-Type": "application/json",
        ...(params.accessToken
          ? { Authorization: `Bearer ${params.accessToken}` }
          : {}),
      },
      body: JSON.stringify({
        session_id: params.sessionId,
        character_id: params.characterId,
        chat_mode: params.chatMode,
        scope_key: scopeKey,
        user_message: params.userText,
        assistant_message: params.assistantText,
        relationship: params.currentRelationship,
      }),
    });
    if (!r.ok) return null;
    const j = (await r.json().catch(() => null)) as unknown;
    if (!isRecord(j)) return null;
    return j as RelationshipScoreResponse;
  } catch {
    return null;
  }
}

export async function updateRelationshipAndMemoryBestEffort(params: {
  supabase: Awaited<ReturnType<typeof supabaseServer>>;
  base: string;
  accessToken: string | null;
  sessionId: string;
  userId: string;
  characterId: string;
  chatMode: TouhouChatMode;
  userText: string;
  assistantText: string;
}) {
  const enabled = envFlag("TOUHOU_RELATIONSHIP_ENABLED", true);
  if (!enabled) return;
  const memScopeKey = `char:${params.characterId}`;

  const confThreshold = clampNum(
    process.env.TOUHOU_RELATIONSHIP_CONFIDENCE_THRESHOLD ?? "0.55",
    0.0,
    1.0,
    0.55,
  );
  const alpha = clampNum(
    process.env.TOUHOU_RELATIONSHIP_EMA_ALPHA ?? "0.15",
    0.0,
    1.0,
    0.15,
  );
  const trustStepSize = clampNum(
    process.env.TOUHOU_RELATIONSHIP_TRUST_STEP ?? "0.02",
    0.0,
    0.2,
    0.02,
  );
  const famStepSize = clampNum(
    process.env.TOUHOU_RELATIONSHIP_FAMILIARITY_STEP ?? "0.02",
    0.0,
    0.2,
    0.02,
  );
  const maxDeltaTrust = clampNum(
    process.env.TOUHOU_RELATIONSHIP_TRUST_MAX_DELTA ?? "0.02",
    0.0,
    0.3,
    0.02,
  );
  const maxDeltaFam = clampNum(
    process.env.TOUHOU_RELATIONSHIP_FAMILIARITY_MAX_DELTA ?? "0.03",
    0.0,
    0.3,
    0.03,
  );

  let prevTrust = 0;
  let prevFam = 0;
  let prevRelRev = 0;
  try {
    const { data } = await params.supabase
      .from("player_character_relations")
      .select("trust,familiarity,rev")
      .eq("user_id", params.userId)
      .eq("character_id", params.characterId)
      .maybeSingle();
    prevTrust = clampNum((data as any)?.trust ?? 0, -1, 1, 0);
    prevFam = clampNum((data as any)?.familiarity ?? 0, 0, 1, 0);
    prevRelRev = clampNum(
      (data as any)?.rev ?? 0,
      0,
      Number.MAX_SAFE_INTEGER,
      0,
    );
  } catch (e) {
    if (
      looksLikeMissingColumn(e, "familiarity") ||
      looksLikeMissingColumn(e, "rev")
    )
      return;
  }

  const score = await scoreRelationshipTurn({
    base: params.base,
    accessToken: params.accessToken,
    sessionId: params.sessionId,
    characterId: params.characterId,
    chatMode: params.chatMode,
    userText: params.userText,
    assistantText: params.assistantText,
    currentRelationship: { trust: prevTrust, familiarity: prevFam },
  });
  if (!score) return;

  const confidence = clampNum(score.confidence ?? 0, 0, 1, 0);
  if (confidence < confThreshold) return;

  const stepTrust = clampNum(score.delta?.trust ?? 0, -2, 2, 0);
  const stepFam = clampNum(score.delta?.familiarity ?? 0, -2, 2, 0);

  const dTrust = Math.max(
    -maxDeltaTrust,
    Math.min(maxDeltaTrust, stepTrust * trustStepSize),
  );
  const dFam = Math.max(
    -maxDeltaFam,
    Math.min(maxDeltaFam, stepFam * famStepSize),
  );

  const nextTrust = clampNum(prevTrust + alpha * dTrust, -1, 1, prevTrust);
  const nextFam = clampNum(prevFam + alpha * dFam, 0, 1, prevFam);

  try {
    const { error } = await params.supabase
      .from("player_character_relations")
      .upsert(
        {
          user_id: params.userId,
          character_id: params.characterId,
          scope_key: "global",
          trust: nextTrust,
          familiarity: nextFam,
          rev: prevRelRev + 1,
          last_updated: new Date().toISOString(),
        } as any,
        { onConflict: "user_id,character_id" },
      );
    if (error) {
      if (
        looksLikeMissingColumn(error, "scope_key") ||
        looksLikeMissingColumn(error, "familiarity")
      )
        return;
      console.warn("[touhou] relationship upsert failed:", error);
      return;
    }
  } catch (e) {
    if (
      looksLikeMissingColumn(e, "scope_key") ||
      looksLikeMissingColumn(e, "familiarity")
    )
      return;
    console.warn("[touhou] relationship upsert failed:", e);
    return;
  }

  const mem = score.memory ?? null;
  if (!mem) return;

  const addTopics = Array.isArray(mem.topics_add) ? mem.topics_add : [];
  const addEmotions = Array.isArray(mem.emotions_add) ? mem.emotions_add : [];
  const addRecurring = Array.isArray(mem.recurring_issues_add)
    ? mem.recurring_issues_add
    : [];
  const addTraits = Array.isArray(mem.traits_add) ? mem.traits_add : [];
  if (
    addTopics.length +
      addEmotions.length +
      addRecurring.length +
      addTraits.length <=
    0
  )
    return;

  try {
    const { data } = await params.supabase
      .from("touhou_user_memory")
      .select("topics,emotions,recurring_issues,traits,rev")
      .eq("user_id", params.userId)
      .eq("scope_key", memScopeKey)
      .maybeSingle();

    const prevTopics = Array.isArray((data as any)?.topics)
      ? ((data as any).topics as string[])
      : [];
    const prevEmotions = Array.isArray((data as any)?.emotions)
      ? ((data as any).emotions as string[])
      : [];
    const prevRecurring = Array.isArray((data as any)?.recurring_issues)
      ? ((data as any).recurring_issues as string[])
      : [];
    const prevTraits = Array.isArray((data as any)?.traits)
      ? ((data as any).traits as string[])
      : [];
    const prevMemRev = clampNum(
      (data as any)?.rev ?? 0,
      0,
      Number.MAX_SAFE_INTEGER,
      0,
    );

    const nextTopics = uniqMerge(prevTopics, addTopics, 48);
    const nextEmotions = uniqMerge(prevEmotions, addEmotions, 48);
    const nextRecurring = uniqMerge(prevRecurring, addRecurring, 48);
    const nextTraits = uniqMerge(prevTraits, addTraits, 48);

    const { error } = await params.supabase.from("touhou_user_memory").upsert(
      {
        user_id: params.userId,
        scope_key: memScopeKey,
        topics: nextTopics,
        emotions: nextEmotions,
        recurring_issues: nextRecurring,
        traits: nextTraits,
        rev: prevMemRev + 1,
        updated_at: new Date().toISOString(),
      } as any,
      { onConflict: "user_id,scope_key" },
    );
    if (error) console.warn("[touhou] memory upsert failed:", error);
  } catch (e) {
    if (looksLikeMissingColumn(e, "touhou_user_memory")) return;
    console.warn("[touhou] memory upsert failed:", e);
  }
}
