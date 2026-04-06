"use client";

import Link from "next/link";
import { useCallback, useEffect, useMemo, useRef, useState } from "react";

import { useLanguage } from "@/components/i18n/LanguageProvider";
import { Button } from "@/components/ui/button";
import { Separator } from "@/components/ui/separator";
import { CHARACTERS } from "@/data/characters";

type RelationshipRow = {
  characterId: string;
  scopeKey: string;
  trust: number;
  familiarity: number;
  lastUpdated: string | null;
};

type MemoryRow = {
  scopeKey: string;
  topics: string[];
  emotions: string[];
  recurringIssues: string[];
  traits: string[];
  updatedAt: string | null;
} | null;

type RelationshipResponse = {
  relationships?: RelationshipRow[];
  memory?: MemoryRow;
  error?: string;
};

type MutationResponse = {
  ok?: boolean;
  error?: string;
};

function clamp01(n: number) {
  if (!Number.isFinite(n)) return 0;
  return Math.max(0, Math.min(1, n));
}

function clampTrust(n: number) {
  if (!Number.isFinite(n)) return 0;
  return Math.max(-1, Math.min(1, n));
}

function Meter(props: { label: string; value: number; min: number; max: number }) {
  const v = Math.max(props.min, Math.min(props.max, props.value));
  const pct = ((v - props.min) / (props.max - props.min)) * 100;

  return (
    <div className="space-y-1">
      <div className="flex items-center justify-between text-xs">
        <div className="text-muted-foreground">{props.label}</div>
        <div className="font-mono">{v.toFixed(3)}</div>
      </div>
      <div className="h-2 w-full rounded-full bg-border/50">
        <div className="h-2 rounded-full bg-primary/70" style={{ width: `${pct}%` }} />
      </div>
    </div>
  );
}

export default function RelationshipSettingsClient() {
  const { lang, t } = useLanguage();
  const characterOptions = useMemo(() => Object.values(CHARACTERS), []);
  const [selectedChar, setSelectedChar] = useState<string>(() => characterOptions[0]?.id ?? "reimu");

  const [relationships, setRelationships] = useState<RelationshipRow[]>([]);
  const [memory, setMemory] = useState<MemoryRow>(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState<string | null>(null);
  const [info, setInfo] = useState<string | null>(null);

  const importRef = useRef<HTMLInputElement | null>(null);

  const copy = useMemo(
    () =>
      lang === "ja"
        ? {
            title: "関係性設定",
            description: "キャラクターごとの trust / familiarity と、会話メモリの状態を確認・調整できます。",
            character: "キャラクター",
            relationship: "Relationship",
            memory: "Memory",
            noData: "まだ保存されていません",
            lastUpdated: "最終更新",
            resetCharacter: "このキャラクターをリセットする",
            resetAll: "すべてリセットする",
            resetMemory: "Memory をリセットする",
            infoReset: "リセットしました。",
            infoExport: "エクスポートしました。",
            infoImport: "インポートしました。",
            loading: "読み込み中…",
            topics: "topics",
            emotions: "emotions",
            recurringIssues: "recurring issues",
            traits: "traits",
            trustValue: "trust (-1..1)",
            familiarityValue: "familiarity (0..1)",
            trustStrongLow: "不信（強）",
            trustLow: "不信",
            trustNeutral: "中立",
            trustHigh: "信頼",
            trustStrongHigh: "信頼（強）",
            familiarityLow: "低い",
            familiarityMid: "中程度",
            familiarityHigh: "高い",
          }
        : {
            title: "Relationship settings",
            description: "Inspect and adjust per-character trust / familiarity and the stored conversation memory.",
            character: "Character",
            relationship: "Relationship",
            memory: "Memory",
            noData: "No saved data yet",
            lastUpdated: "Last updated",
            resetCharacter: "Reset this character",
            resetAll: "Reset everything",
            resetMemory: "Reset memory",
            infoReset: "Reset complete.",
            infoExport: "Exported.",
            infoImport: "Imported.",
            loading: "Loading…",
            topics: "topics",
            emotions: "emotions",
            recurringIssues: "recurring issues",
            traits: "traits",
            trustValue: "trust (-1..1)",
            familiarityValue: "familiarity (0..1)",
            trustStrongLow: "Strong distrust",
            trustLow: "Distrust",
            trustNeutral: "Neutral",
            trustHigh: "Trust",
            trustStrongHigh: "Strong trust",
            familiarityLow: "Low",
            familiarityMid: "Medium",
            familiarityHigh: "High",
          },
    [lang],
  );

  const trustLabel = useCallback(
    (value: number) => {
      if (value <= -0.6) return copy.trustStrongLow;
      if (value <= -0.2) return copy.trustLow;
      if (value < 0.2) return copy.trustNeutral;
      if (value < 0.6) return copy.trustHigh;
      return copy.trustStrongHigh;
    },
    [copy],
  );

  const familiarityLabel = useCallback(
    (value: number) => {
      if (value < 0.25) return copy.familiarityLow;
      if (value < 0.6) return copy.familiarityMid;
      return copy.familiarityHigh;
    },
    [copy],
  );

  const fetchAll = useCallback(async () => {
    setLoading(true);
    setError(null);
    setInfo(null);

    try {
      const r = await fetch(`/api/relationship?characterId=${encodeURIComponent(selectedChar)}`, {
        cache: "no-store",
      });
      const j = (await r.json().catch(() => null)) as RelationshipResponse | null;
      if (!r.ok) throw new Error(j?.error || "fetch failed");
      setRelationships(Array.isArray(j?.relationships) ? j.relationships : []);
      setMemory(j?.memory ?? null);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e ?? ""));
    } finally {
      setLoading(false);
    }
  }, [selectedChar]);

  useEffect(() => {
    void fetchAll();
  }, [fetchAll]);

  const activeRel = useMemo(() => {
    const row = relationships.find((r) => r.characterId === selectedChar) ?? null;
    return row
      ? {
          ...row,
          trust: clampTrust(row.trust),
          familiarity: clamp01(row.familiarity),
        }
      : null;
  }, [relationships, selectedChar]);

  const doReset = async (kind: "all" | "character" | "memory") => {
    setLoading(true);
    setError(null);
    setInfo(null);

    try {
      const body =
        kind === "all"
          ? { resetRelationships: true, resetMemory: true }
          : kind === "memory"
            ? { characterId: selectedChar, resetRelationships: false, resetMemory: true }
            : { characterId: selectedChar, resetRelationships: true, resetMemory: false };

      const r = await fetch("/api/relationship/reset", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(body),
      });
      const j = (await r.json().catch(() => null)) as MutationResponse | null;
      if (!r.ok) throw new Error(j?.error || "reset failed");
      setInfo(copy.infoReset);
      await fetchAll();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e ?? ""));
    } finally {
      setLoading(false);
    }
  };

  const doExport = async () => {
    setError(null);
    setInfo(null);

    try {
      const r = await fetch("/api/relationship/export", { cache: "no-store" });
      if (!r.ok) throw new Error("export failed");

      const blob = await r.blob();
      const url = URL.createObjectURL(blob);
      const a = document.createElement("a");
      a.href = url;
      a.download = "touhou-talk-relationship-export.json";
      document.body.appendChild(a);
      a.click();
      a.remove();
      URL.revokeObjectURL(url);
      setInfo(copy.infoExport);
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e ?? ""));
    }
  };

  const doImport = async (file: File) => {
    setLoading(true);
    setError(null);
    setInfo(null);

    try {
      const text = await file.text();
      const json = JSON.parse(text);
      const r = await fetch("/api/relationship/import", {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify(json),
      });
      const j = (await r.json().catch(() => null)) as MutationResponse | null;
      if (!r.ok) throw new Error(j?.error || "import failed");
      setInfo(copy.infoImport);
      await fetchAll();
    } catch (e) {
      setError(e instanceof Error ? e.message : String(e ?? ""));
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="flex w-full flex-col gap-6">
      <div className="flex items-center justify-between gap-4">
        <div>
          <h1 className="font-gensou text-2xl">{copy.title}</h1>
          <p className="text-sm text-muted-foreground">{copy.description}</p>
        </div>
        <Button asChild variant="outline">
          <Link href="/chat/session">{t("common.chat")}</Link>
        </Button>
      </div>

      <Separator />

      <section className="rounded-2xl border bg-card/60 p-5">
        <div className="flex flex-wrap items-center justify-between gap-3">
          <div className="flex items-center gap-3">
            <div className="text-sm font-medium">{copy.character}</div>
            <select
              className="h-9 rounded-md border bg-background px-2 text-sm"
              value={selectedChar}
              onChange={(e) => setSelectedChar(e.currentTarget.value)}
              disabled={loading}
            >
              {characterOptions.map((c) => (
                <option key={c.id} value={c.id}>
                  {c.name} ({c.id})
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-wrap gap-2">
            <Button variant="outline" onClick={doExport} disabled={loading}>
              {t("common.export")}
            </Button>
            <Button
              variant="outline"
              onClick={() => {
                importRef.current?.click();
              }}
              disabled={loading}
            >
              {t("common.import")}
            </Button>
            <input
              ref={importRef}
              type="file"
              accept="application/json"
              className="hidden"
              onChange={(e) => {
                const f = e.currentTarget.files?.[0] ?? null;
                e.currentTarget.value = "";
                if (f) void doImport(f);
              }}
            />
          </div>
        </div>

        <div className="mt-4 grid gap-4 md:grid-cols-2">
          <div className="rounded-xl border bg-background/40 p-4">
            <div className="flex items-center justify-between">
              <div className="text-sm font-medium">{copy.relationship}</div>
              {activeRel ? (
                <div className="text-xs text-muted-foreground">
                  trust={trustLabel(activeRel.trust)}, familiarity={familiarityLabel(activeRel.familiarity)}
                </div>
              ) : (
                <div className="text-xs text-muted-foreground">{copy.noData}</div>
              )}
            </div>

            <div className="mt-3 space-y-3">
              <Meter label={copy.trustValue} value={activeRel?.trust ?? 0} min={-1} max={1} />
              <Meter label={copy.familiarityValue} value={activeRel?.familiarity ?? 0} min={0} max={1} />
              <div className="text-xs text-muted-foreground">
                {copy.lastUpdated}: {activeRel?.lastUpdated ?? "-"}
              </div>
            </div>

            <div className="mt-4 flex flex-wrap gap-2">
              <Button variant="destructive" onClick={() => void doReset("character")} disabled={loading}>
                {copy.resetCharacter}
              </Button>
              <Button variant="outline" onClick={() => void doReset("all")} disabled={loading}>
                {copy.resetAll}
              </Button>
            </div>
          </div>

          <div className="rounded-xl border bg-background/40 p-4">
            <div className="flex items-center justify-between">
              <div className="text-sm font-medium">{copy.memory}</div>
              <div className="text-xs text-muted-foreground">{copy.lastUpdated}: {memory?.updatedAt ?? "-"}</div>
            </div>

            <div className="mt-3 space-y-3 text-sm">
              <div>
                <div className="text-xs text-muted-foreground">{copy.topics}</div>
                <div className="font-mono text-xs">{memory?.topics?.join(", ") || "-"}</div>
              </div>
              <div>
                <div className="text-xs text-muted-foreground">{copy.emotions}</div>
                <div className="font-mono text-xs">{memory?.emotions?.join(", ") || "-"}</div>
              </div>
              <div>
                <div className="text-xs text-muted-foreground">{copy.recurringIssues}</div>
                <div className="font-mono text-xs">{memory?.recurringIssues?.join(", ") || "-"}</div>
              </div>
              <div>
                <div className="text-xs text-muted-foreground">{copy.traits}</div>
                <div className="font-mono text-xs">{memory?.traits?.join(", ") || "-"}</div>
              </div>
            </div>

            <div className="mt-4 flex flex-wrap gap-2">
              <Button variant="destructive" onClick={() => void doReset("memory")} disabled={loading}>
                {copy.resetMemory}
              </Button>
            </div>
          </div>
        </div>

        <div className="mt-4 text-xs">
          {loading ? <span className="text-muted-foreground">{copy.loading}</span> : null}
          {info ? <span className="text-foreground/80">{info}</span> : null}
          {error ? <span className="text-red-400">{error}</span> : null}
        </div>
      </section>
    </div>
  );
}
