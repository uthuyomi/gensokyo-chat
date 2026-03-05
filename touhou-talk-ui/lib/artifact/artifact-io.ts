"use client";

export type ArtifactImportMessage = {
  role: "user" | "ai";
  content: string;
  meta?: Record<string, unknown> | null;
};

export type ArtifactImportSession = {
  externalSessionId?: string;
  title?: string;
  messages: ArtifactImportMessage[];
};

export type ArtifactImportPayload = {
  sessions: ArtifactImportSession[];
};

type JsonObject = Record<string, unknown>;

function stripBom(input: string): string {
  if (input.charCodeAt(0) === 0xfeff) return input.slice(1);
  return input;
}

function isJsonObject(v: unknown): v is JsonObject {
  return !!v && typeof v === "object" && !Array.isArray(v);
}

function coerceString(v: unknown): string | null {
  if (typeof v === "string") return v;
  if (typeof v === "number" && Number.isFinite(v)) return String(v);
  return null;
}

function coerceNumber(v: unknown): number | null {
  if (typeof v === "number" && Number.isFinite(v)) return v;
  if (typeof v === "string" && v.trim() !== "") {
    const n = Number(v);
    return Number.isFinite(n) ? n : null;
  }
  return null;
}

function tryParseJson(text: string): { ok: true; value: unknown } | { ok: false } {
  try {
    return { ok: true, value: JSON.parse(text) as unknown };
  } catch {
    return { ok: false };
  }
}

function normalizeMeta(v: unknown): Record<string, unknown> | null {
  if (!v) return null;
  if (!isJsonObject(v)) return null;
  return v;
}

function normalizeMessageLike(v: unknown): ArtifactImportMessage | null {
  if (!isJsonObject(v)) return null;

  const roleRaw = coerceString(v.role);
  const content = coerceString(v.content);
  if (!content) return null;

  const role =
    roleRaw === "user"
      ? "user"
      : roleRaw === "ai" || roleRaw === "assistant"
        ? "ai"
        : null;

  if (!role) return null;

  return {
    role,
    content,
    meta: normalizeMeta(v.meta),
  };
}

function looksLikeMessageArray(v: unknown): v is unknown[] {
  if (!Array.isArray(v) || v.length === 0) return false;
  return v.some((x) => {
    if (!isJsonObject(x)) return false;
    return typeof x.role === "string" && typeof x.content === "string";
  });
}

function normalizeSessionLike(v: unknown): ArtifactImportSession | null {
  if (!isJsonObject(v)) return null;

  const title = coerceString(v.title) ?? undefined;
  const externalSessionId =
    coerceString(v.externalSessionId) ??
    coerceString(v.external_session_id) ??
    coerceString(v.session_id) ??
    coerceString(v.sessionId) ??
    undefined;

  const messagesRaw =
    (Array.isArray(v.messages) ? v.messages : null) ??
    (Array.isArray(v.items) ? v.items : null) ??
    null;

  if (!messagesRaw) return null;

  const messages = messagesRaw
    .map((m) => normalizeMessageLike(m))
    .filter((m): m is ArtifactImportMessage => !!m);

  if (messages.length === 0) return null;

  return { title, externalSessionId, messages };
}

type ArtifactTurnRow = {
  externalSessionId: string;
  order: number;
  turnIndex: number | null;
  user: string | null;
  reply: string | null;
  raw: JsonObject;
};

function normalizeArtifactTurnRow(
  v: unknown,
  fallbackIndex: number,
): ArtifactTurnRow | null {
  if (!isJsonObject(v)) return null;

  const externalSessionId =
    coerceString(v.session_id) ?? coerceString(v.sessionId) ?? "import";

  const user =
    coerceString(v.user) ??
    coerceString(v.input) ??
    coerceString(v.prompt) ??
    coerceString(v.message) ??
    null;

  const reply =
    coerceString(v.reply) ??
    coerceString(v.output) ??
    coerceString(v.assistant) ??
    coerceString(v.answer) ??
    coerceString(v.response) ??
    null;

  const turnIndex =
    coerceNumber(v.turn_index) ?? coerceNumber(v.turnIndex) ?? null;

  const order = turnIndex ?? coerceNumber(v.turn) ?? fallbackIndex;

  return {
    externalSessionId,
    order,
    turnIndex,
    user,
    reply,
    raw: v,
  };
}

function turnsToSessions(turns: ArtifactTurnRow[]): ArtifactImportSession[] {
  const grouped = new Map<string, ArtifactTurnRow[]>();
  for (const t of turns) {
    const arr = grouped.get(t.externalSessionId) ?? [];
    arr.push(t);
    grouped.set(t.externalSessionId, arr);
  }

  const sessions: ArtifactImportSession[] = [];
  for (const [externalSessionId, items] of grouped.entries()) {
    items.sort((a, b) => (a.order !== b.order ? a.order - b.order : 0));

    const messages: ArtifactImportMessage[] = [];
    for (const it of items) {
      const importedMeta = {
        source: "artifact",
        externalSessionId,
        ...(typeof it.turnIndex === "number" ? { turnIndex: it.turnIndex } : null),
        ...(typeof it.raw.case_id === "string" ? { caseId: it.raw.case_id } : null),
        ...(typeof it.raw.case_index === "number"
          ? { caseIndex: it.raw.case_index }
          : null),
      } as Record<string, unknown>;

      if (it.user) {
        messages.push({
          role: "user",
          content: it.user,
          meta: { imported: importedMeta },
        });
      }
      if (it.reply) {
        messages.push({
          role: "ai",
          content: it.reply,
          meta: { imported: importedMeta },
        });
      }
    }

    if (messages.length === 0) continue;

    sessions.push({
      externalSessionId,
      messages,
    });
  }

  return sessions;
}

function normalizeAnyToImportPayload(v: unknown): ArtifactImportPayload {
  if (isJsonObject(v) && Array.isArray(v.sessions)) {
    const sessions = v.sessions
      .map((s) => normalizeSessionLike(s))
      .filter((s): s is ArtifactImportSession => !!s);
    return { sessions };
  }

  if (isJsonObject(v) && Array.isArray(v.messages)) {
    const s = normalizeSessionLike(v);
    return { sessions: s ? [s] : [] };
  }

  if (Array.isArray(v)) {
    if (looksLikeMessageArray(v)) {
      const messages = v
        .map((m) => normalizeMessageLike(m))
        .filter((m): m is ArtifactImportMessage => !!m);
      return messages.length > 0 ? { sessions: [{ messages }] } : { sessions: [] };
    }

    // array of session-like objects?
    const asSessions = v
      .map((s) => normalizeSessionLike(s))
      .filter((s): s is ArtifactImportSession => !!s);
    if (asSessions.length > 0) return { sessions: asSessions };

    // artifact rows (e.g. run.jsonl lines)
    const turns = v
      .map((row, idx) => normalizeArtifactTurnRow(row, idx))
      .filter((t): t is ArtifactTurnRow => !!t);
    return { sessions: turnsToSessions(turns) };
  }

  // single row / object
  if (isJsonObject(v)) {
    const t = normalizeArtifactTurnRow(v, 0);
    return { sessions: t ? turnsToSessions([t]) : [] };
  }

  return { sessions: [] };
}

export function parseArtifactText(text: string): ArtifactImportPayload {
  const trimmed = stripBom(String(text ?? "")).trim();
  if (!trimmed) return { sessions: [] };

  const asJson = tryParseJson(trimmed);
  if (asJson.ok) return normalizeAnyToImportPayload(asJson.value);

  const lines = trimmed.split(/\r?\n/);
  const rows: unknown[] = [];
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i]?.trim();
    if (!line) continue;
    const parsed = tryParseJson(line);
    if (!parsed.ok) {
      throw new Error(`JSONLの解析に失敗しました（${i + 1}行目）`);
    }
    rows.push(parsed.value);
  }
  return normalizeAnyToImportPayload(rows);
}

export function buildRunJsonlFromMessages(params: {
  sessionId: string;
  messages: Array<{ role: "user" | "ai"; content: string }>;
}): string {
  const sessionId = String(params.sessionId ?? "");
  const messages = Array.isArray(params.messages) ? params.messages : [];

  const lines: string[] = [];
  let turnIndex = 0;

  for (let i = 0; i < messages.length; i++) {
    const m = messages[i];
    if (!m || m.role !== "user") continue;

    const user = String(m.content ?? "");
    let reply = "";

    const next = i + 1 < messages.length ? messages[i + 1] : null;
    if (next && next.role === "ai") {
      reply = String(next.content ?? "");
      i += 1;
    }

    const row = {
      turn: turnIndex + 1,
      turn_index: turnIndex,
      session_id: sessionId,
      user,
      reply,
    };
    lines.push(JSON.stringify(row));
    turnIndex += 1;
  }

  return lines.join("\n") + (lines.length > 0 ? "\n" : "");
}

