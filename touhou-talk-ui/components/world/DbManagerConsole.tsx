"use client";

import type { ReactNode } from "react";
import { useEffect, useState, useTransition } from "react";

type Json = Record<string, unknown>;

async function fetchJson(path: string, init?: RequestInit) {
  const headers = new Headers(init?.headers);
  if (init?.body && !headers.has("Content-Type")) {
    headers.set("Content-Type", "application/json");
  }

  const res = await fetch(path, {
    ...init,
    headers,
    cache: "no-store",
  });
  const text = await res.text();
  const data = text ? JSON.parse(text) : null;
  if (!res.ok) {
    throw new Error((data && typeof data === "object" && "detail" in data ? String(data.detail) : text) || `request_failed:${res.status}`);
  }
  return data;
}

function postJson(path: string, body?: unknown) {
  return fetchJson(path, {
    method: "POST",
    body: body === undefined ? undefined : JSON.stringify(body),
  });
}

function pretty(value: unknown) {
  return JSON.stringify(value, null, 2);
}

export default function DbManagerConsole({ worldId = "gensokyo_main" }: { worldId?: string }) {
  const [audit, setAudit] = useState<Json | null>(null);
  const [alerts, setAlerts] = useState<Json[] | null>(null);
  const [jobs, setJobs] = useState<Json[] | null>(null);
  const [pendingClaims, setPendingClaims] = useState<Json[] | null>(null);
  const [conflicts, setConflicts] = useState<Json[] | null>(null);
  const [policies, setPolicies] = useState<Json | null>(null);
  const [harvestPlans, setHarvestPlans] = useState<Json[] | null>(null);
  const [policyText, setPolicyText] = useState<string>(
    '{\n  "enabled": true,\n  "official_primary_min_authority": 0.95,\n  "official_primary_min_confidence": 0.8,\n  "official_secondary_min_sources": 2,\n  "official_secondary_min_authority": 0.75,\n  "official_secondary_min_confidence": 0.78\n}',
  );
  const [status, setStatus] = useState("待機中です。");
  const [isPending, startTransition] = useTransition();

  const loadAll = () =>
    startTransition(() => {
      void (async () => {
        try {
          setStatus("監査と運用状況を読み込み中です。");
          const [auditData, alertsData, jobsData, pendingData, conflictsData, policiesData, harvestData] = await Promise.all([
            fetchJson(`/api/db-manager/audit/report?world_id=${encodeURIComponent(worldId)}`),
            fetchJson(`/api/db-manager/ops/alerts?world_id=${encodeURIComponent(worldId)}`),
            fetchJson("/api/db-manager/ops/jobs?limit=12"),
            fetchJson(`/api/db-manager/claims/pending?world_id=${encodeURIComponent(worldId)}`),
            fetchJson(`/api/db-manager/claims/conflicts?world_id=${encodeURIComponent(worldId)}`),
            fetchJson("/api/db-manager/ops/policies"),
            fetchJson(`/api/db-manager/ops/harvest-plans?world_id=${encodeURIComponent(worldId)}&limit=12`),
          ]);
          setAudit(auditData);
          setAlerts(Array.isArray((alertsData as Json).alerts) ? ((alertsData as Json).alerts as Json[]) : []);
          setJobs(Array.isArray(jobsData) ? (jobsData as Json[]) : []);
          setPendingClaims(Array.isArray(pendingData) ? (pendingData as Json[]) : []);
          setConflicts(Array.isArray(conflictsData) ? (conflictsData as Json[]) : []);
          setPolicies(policiesData as Json);
          setHarvestPlans(Array.isArray(harvestData) ? (harvestData as Json[]) : []);

          const stored = (policiesData as Json).stored;
          if (Array.isArray(stored)) {
            const auto = stored.find((row) => typeof row === "object" && row && (row as Json).policy_key === "auto_review") as Json | undefined;
            if (auto && typeof auto.policy_value === "object" && auto.policy_value) {
              setPolicyText(pretty(auto.policy_value));
            }
          }
          setStatus("読み込み完了です。");
        } catch (error) {
          setStatus(`読み込み失敗: ${error instanceof Error ? error.message : String(error)}`);
        }
      })();
    });

  useEffect(() => {
    loadAll();
  }, [worldId]);

  const runAction = (label: string, action: () => Promise<unknown>) =>
    startTransition(() => {
      void (async () => {
        try {
          setStatus(`${label} を実行中です。`);
          await action();
          setStatus(`${label} が完了しました。`);
          loadAll();
        } catch (error) {
          setStatus(`${label} で失敗: ${error instanceof Error ? error.message : String(error)}`);
        }
      })();
    });

  return (
    <div className="min-h-screen bg-[radial-gradient(circle_at_top,rgba(130,160,210,0.16),transparent_30%),linear-gradient(180deg,#11161d_0%,#0a0d12_100%)] text-zinc-100">
      <div className="mx-auto flex max-w-7xl flex-col gap-6 px-4 py-6 md:px-6">
        <section className="rounded-[28px] border border-white/10 bg-white/5 p-5 shadow-[0_20px_80px_rgba(0,0,0,0.35)] backdrop-blur-xl">
          <div className="flex flex-col gap-4 md:flex-row md:items-end md:justify-between">
            <div>
              <p className="text-xs uppercase tracking-[0.28em] text-cyan-200/70">World DB Manager</p>
              <h1 className="font-gensou text-3xl text-white">幻想郷DB 管理コンソール</h1>
              <p className="mt-2 max-w-3xl text-sm text-zinc-300">
                監査、pending claim、conflict、ジョブ履歴、ポリシー、harvest plan をまとめて確認できます。
              </p>
            </div>
            <div className="flex flex-wrap gap-2">
              <button className="rounded-full border border-cyan-400/30 bg-cyan-300/10 px-4 py-2 text-sm text-cyan-100" onClick={loadAll}>
                再読込
              </button>
              <button
                className="rounded-full border border-emerald-400/30 bg-emerald-300/10 px-4 py-2 text-sm text-emerald-100"
                onClick={() => runAction("discovery", () => postJson("/api/db-manager/discovery/run", { world_id: worldId, limit: 5, dry_run: false }))}
              >
                Discovery 実行
              </button>
              <button
                className="rounded-full border border-amber-400/30 bg-amber-300/10 px-4 py-2 text-sm text-amber-100"
                onClick={() => runAction("ingest queue", () => postJson("/api/db-manager/ingest/process-queue"))}
              >
                Queue 処理
              </button>
              <button
                className="rounded-full border border-fuchsia-400/30 bg-fuchsia-300/10 px-4 py-2 text-sm text-fuchsia-100"
                onClick={() => runAction("auto review", () => postJson("/api/db-manager/claims/auto-review", { world_id: worldId, limit: 30, dry_run: false }))}
              >
                Auto Review
              </button>
            </div>
          </div>
          <p className="mt-4 rounded-2xl border border-white/10 bg-black/20 px-4 py-3 text-sm text-zinc-200">{status}</p>
        </section>

        <section className="grid gap-4 md:grid-cols-4">
          <StatCard label="Claims" value={String(((audit?.totals as Json | undefined)?.claims as number | undefined) ?? 0)} accent="cyan" />
          <StatCard label="Pending" value={String(((audit?.health_flags as Json | undefined)?.pending_claim_backlog as number | undefined) ?? 0)} accent="amber" />
          <StatCard label="Open Conflicts" value={String(((audit?.health_flags as Json | undefined)?.open_conflicts as number | undefined) ?? 0)} accent="rose" />
          <StatCard label="Sources" value={String(((audit?.totals as Json | undefined)?.sources as number | undefined) ?? 0)} accent="emerald" />
        </section>

        <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <Panel title="Alerts">
            <div className="space-y-3">
              {(alerts || []).length === 0 ? <p className="text-sm text-zinc-400">大きな警告はまだ出ていません。</p> : null}
              {(alerts || []).map((alert, index) => (
                <div key={`${alert.kind ?? "alert"}-${index}`} className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3">
                  <p className="text-sm font-medium text-white">{String(alert.message || "alert")}</p>
                  <p className="mt-1 text-xs uppercase tracking-[0.2em] text-zinc-400">
                    {String(alert.level || "info")} / {String(alert.kind || "general")}
                  </p>
                </div>
              ))}
            </div>
          </Panel>
          <Panel title="Auto Review Policy">
            <div className="space-y-3">
              <textarea
                value={policyText}
                onChange={(e) => setPolicyText(e.target.value)}
                className="min-h-[260px] w-full rounded-2xl border border-white/10 bg-black/30 p-4 font-mono text-xs text-zinc-100 outline-none"
              />
              <button
                className="rounded-full border border-cyan-400/30 bg-cyan-300/10 px-4 py-2 text-sm text-cyan-100"
                onClick={() =>
                  runAction("policy 保存", async () => {
                    const parsed = JSON.parse(policyText) as Json;
                    await postJson("/api/db-manager/ops/policies/auto_review", parsed);
                  })
                }
              >
                Policy 保存
              </button>
            </div>
          </Panel>
        </section>

        <section className="grid gap-6 lg:grid-cols-2">
          <Panel title={`Pending Claims (${(pendingClaims || []).length})`}>
            <RecordList records={pendingClaims} primaryKey="claim_text" secondaryKey="layer" tertiaryKey="entity_kind" />
          </Panel>
          <Panel title={`Conflicts (${(conflicts || []).length})`}>
            <RecordList records={conflicts} primaryKey="topic" secondaryKey="resolution_status" tertiaryKey="id" />
          </Panel>
        </section>

        <section className="grid gap-6 lg:grid-cols-[1.1fr_0.9fr]">
          <Panel title={`Recent Jobs (${(jobs || []).length})`}>
            <RecordList records={jobs} primaryKey="job_type" secondaryKey="status" tertiaryKey="id" />
          </Panel>
          <Panel title="Audit Snapshot">
            <pre className="max-h-[420px] overflow-auto rounded-2xl border border-white/10 bg-black/30 p-4 text-xs text-zinc-200">{pretty(audit || {})}</pre>
          </Panel>
        </section>

        <section className="grid gap-6 lg:grid-cols-2">
          <Panel title={`Harvest Plans (${(harvestPlans || []).length})`}>
            <RecordList records={harvestPlans} primaryKey="reason" secondaryKey="task_type" tertiaryKey="status" />
          </Panel>
          <Panel title="Policies Raw">
            <pre className="max-h-[360px] overflow-auto rounded-2xl border border-white/10 bg-black/30 p-4 text-xs text-zinc-200">{pretty(policies || {})}</pre>
          </Panel>
        </section>

        <section className="grid gap-6 lg:grid-cols-2">
          <Panel title="Quick Ops">
            <div className="grid gap-3">
              <button
                className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-zinc-100"
                onClick={() => runAction("harvest planning", () => postJson(`/api/db-manager/ops/harvest-planning?world_id=${encodeURIComponent(worldId)}`))}
              >
                AI harvest planning を実行する
              </button>
              <button
                className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-zinc-100"
                onClick={() =>
                  runAction("公式 preset 追加", () =>
                    postJson("/api/db-manager/discovery/presets/install", {
                      world_id: worldId,
                      preset_name: "official_touhou",
                      overwrite_existing: false,
                    }),
                  )
                }
              >
                公式 preset を追加する
              </button>
              <button
                className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-zinc-100"
                onClick={() => runAction("embedding refresh", () => postJson(`/api/db-manager/ops/embedding-refresh?world_id=${encodeURIComponent(worldId)}`))}
              >
                accepted 後の embedding refresh を実行する
              </button>
              <button
                className="rounded-2xl border border-white/10 bg-white/5 px-4 py-3 text-left text-sm text-zinc-100"
                onClick={() => runAction("failed ingest retry", () => postJson("/api/db-manager/ops/ingest/retry-failed"))}
              >
                failed ingest を再試行する
              </button>
            </div>
          </Panel>
          <Panel title="How It Moves">
            <div className="space-y-3 text-sm text-zinc-300">
              <p>1. AI が audit report を見て、薄い領域の harvest plan を決めます。</p>
              <p>2. 必要なら discovery source を追加し、新しい URL 候補を見つけます。</p>
              <p>3. scheduler が source を巡回して URL を queue に積みます。</p>
              <p>4. 本文取得後、AI が claim 抽出と保存判定を行います。</p>
              <p>5. 重複排除、conflict 管理、auto-review、embedding refresh まで流れます。</p>
            </div>
          </Panel>
        </section>
      </div>
      {isPending ? <div className="pointer-events-none fixed inset-x-0 bottom-0 h-1 bg-[linear-gradient(90deg,transparent,rgba(56,189,248,0.9),transparent)] animate-pulse" /> : null}
    </div>
  );
}

function Panel({ title, children }: { title: string; children: ReactNode }) {
  return (
    <section className="rounded-[28px] border border-white/10 bg-white/5 p-5 shadow-[0_20px_80px_rgba(0,0,0,0.24)] backdrop-blur-xl">
      <h2 className="mb-4 text-sm uppercase tracking-[0.24em] text-zinc-400">{title}</h2>
      {children}
    </section>
  );
}

function StatCard({ label, value, accent }: { label: string; value: string; accent: "cyan" | "amber" | "rose" | "emerald" }) {
  const tones: Record<string, string> = {
    cyan: "from-cyan-300/20 to-cyan-400/5 text-cyan-100",
    amber: "from-amber-300/20 to-amber-400/5 text-amber-100",
    rose: "from-rose-300/20 to-rose-400/5 text-rose-100",
    emerald: "from-emerald-300/20 to-emerald-400/5 text-emerald-100",
  };
  return (
    <div className={`rounded-[26px] border border-white/10 bg-gradient-to-br ${tones[accent]} p-5 backdrop-blur-xl`}>
      <p className="text-xs uppercase tracking-[0.24em] text-zinc-400">{label}</p>
      <p className="mt-3 font-gensou text-4xl">{value}</p>
    </div>
  );
}

function RecordList({
  records,
  primaryKey,
  secondaryKey,
  tertiaryKey,
}: {
  records: Json[] | null;
  primaryKey: string;
  secondaryKey: string;
  tertiaryKey: string;
}) {
  if (!records || records.length === 0) {
    return <p className="text-sm text-zinc-400">まだデータがありません。</p>;
  }
  return (
    <div className="max-h-[420px] space-y-3 overflow-auto pr-1">
      {records.map((record, index) => (
        <div key={`${String(record.id || index)}`} className="rounded-2xl border border-white/10 bg-black/20 p-4">
          <p className="text-sm font-medium text-white">{String(record[primaryKey] ?? "(no title)")}</p>
          <p className="mt-1 text-xs uppercase tracking-[0.2em] text-zinc-400">
            {String(record[secondaryKey] ?? "")}
            {record[tertiaryKey] ? ` / ${String(record[tertiaryKey])}` : ""}
          </p>
          <pre className="mt-3 overflow-auto rounded-xl bg-black/30 p-3 text-[11px] text-zinc-300">{pretty(record)}</pre>
        </div>
      ))}
    </div>
  );
}
