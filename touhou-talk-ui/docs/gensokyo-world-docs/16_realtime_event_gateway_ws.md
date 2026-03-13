# 16 Realtime World Event Gateway (WebSocket)

この章は、`docs/gensokyo-world-docs` の到達点 **「③イベントログが流れる」** を、**リアルタイム（WS）** かつ **DB永続（Supabase/Postgres）** で実現するための最小仕様を固定する。

目的は「今すぐ動く」より、将来の拡張（ユーザー介入・場所購読・3D化・リプレイ）で壊れない“土台”を作ること。

## 16.1 設計原則

- **イベントはappend-onlyでDBに保存**（真実はログ）
- UIは「状態を直接いじる」より **イベント適用（event sourcing）で描画**
- **channelごとに `seq` を単調増加**させる（順序保証・取りこぼし回収が楽になる）
- 再接続は `lastSeq` を使って **確実にリプレイ**する

## 16.2 チャンネル（購読単位）

購読キーは2段に固定する。

前提: **`world_id` を最初から導入する**（複数ワールド/シャード/テスト環境を想定）。

- グローバル: `world:{world_id}`
- 場所: `world:{world_id}:{loc}`

例:

- `world:gensokyo_main`
- `world:gensokyo_main:hakurei_shrine`

将来 `subLoc` を入れたくなった場合も、まずは `payload.sub_location_id` で運び、チャンネルは増やしすぎない（購読爆発を避ける）。

## 16.3 イベント共通スキーマ（DBとWSで共通）

イベントはDB格納形とWS配信形を同一にする（変換を最小化する）。

```ts
type WorldEvent = {
  id: string;                 // uuid
  channel: string;            // "world:{world_id}" or "world:{world_id}:{loc}"
  seq: number;                // channel内で単調増加
  ts: string;                 // ISO8601

  world_id: string;           // "gensokyo_main"
  layer: string;              // 表示・分類用（例: "gensokyo"）。world_idから導出可能でも持って良い
  loc?: string | null;        // "hakurei_shrine"

  type: "world_tick" | "npc_action" | "npc_say" | "system";
  actor?: { kind: "npc" | "user" | "system"; id?: string | null } | null;

  // 仕様が変わっても破壊的変更を避けるため、payloadはjsonbで運ぶ
  payload: Record<string, unknown>;
};
```

### typeの意図（最小セット）

- `world_tick`: 時間/天候/異変フラグなどの“世界の進行”
- `npc_action`: NPCの行動（移動/掃除/待機/探索など）
- `npc_say`: 発話（ログの本体。後で音声/モーションに繋ぐ）
- `system`: システム通知（メンテ/接続/負荷/ルール警告）

## 16.4 WSプロトコル（client ⇄ gateway）

WSは **World Event Gateway** として1本にする。UIはここに繋ぐだけ。

### 16.4.1 client → server

```json
{ "type": "hello", "auth": { "mode": "supabase_jwt", "access_token": "..." } }
```

```json
{ "type": "subscribe", "channel": "world:gensokyo_main:hakurei_shrine", "lastSeq": 120 }
```

```json
{ "type": "unsubscribe", "channel": "world:gensokyo_main:hakurei_shrine" }
```

### 16.4.2 server → client

```json
{ "type": "ack", "hello": true }
```

```json
{
  "type": "snapshot",
  "channel": "world:gensokyo_main:hakurei_shrine",
  "fromSeq": 121,
  "events": [ /* WorldEvent[] */ ]
}
```

```json
{
  "type": "event",
  "channel": "world:gensokyo_main:hakurei_shrine",
  "event": { /* WorldEvent */ }
}
```

```json
{ "type": "error", "code": "forbidden", "message": "..." }
```

### 16.4.3 再接続の流れ（取りこぼしゼロ）

1) clientは最後に処理した `lastSeq` を保持
2) 再接続したら `subscribe(channel, lastSeq)` を送る
3) serverは `fromSeq=lastSeq+1` からDBを読み、`snapshot` を返す
4) `snapshot` が終わった後は `event` をリアルタイムに流す

> `snapshot` が巨大になる場合は分割送信（ページング）する。プロトコル上は `snapshot` を複数回送って良い。

## 16.5 Supabase（Postgres）永続ログの要件

WSゲートウェイは “配信” だけでなく、必ずDBのログを根拠に配信できること。

- `channel + seq` で一意（重複排除できる）
- `seq` は **channel内で単調増加**（飛び番は許容するが、順序は守る）
- `lastSeq` からの復元が `index` で高速（DBで効く）

テーブル案は `01_supabase_schema_ai_gensokyo.md` に定義する。

## 16.6 最初の実装スコープ（実装時の最小）

- WSゲートウェイ（別プロセス推奨）
- `subscribe` で `snapshot` を返してから live に切り替え
- `npc_say` だけ先に流せば、UIのイベントログが成立する

## 16.7 運用注意（重要）

Next.jsのホスティング（特にサーバレス）だと、WS常駐が難しいことがある。

したがって、実装は

- UI: `touhou-talk-ui`（Next.js）
- WS: `gensokyo-world`（別サービス/別プロセス）

の分離を前提に設計する（ローカル開発は同一マシンでOK）。
