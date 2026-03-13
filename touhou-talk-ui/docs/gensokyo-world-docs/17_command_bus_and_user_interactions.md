# 17 Command Bus（ユーザー介入）と永続ログ

この章は「ユーザー介入（発話/移動/選択肢/依頼/アイテム）」を **最初から想定**し、長期運用で壊れにくい Command（意図）側の設計を固定する。

到達点③（イベントログが流れる）でも、将来の拡張（ユーザーが世界へ働きかける）を見据えるなら、**Event（事実）** と **Command（意図）** を分離するのが自然。

## 17.1 なぜCommandを分けるのか

- UIからの入力は「意図（Command）」であり、必ずしも成功しない
- 成功/失敗/却下/遅延/再試行が起こり得る
- “何が起きたか”は Event（`world_event_log`）に残すべきで、Commandはその起点（原因）として残す

結果:

- デバッグが簡単（「どの入力が、どのイベントを生んだか」）
- 再現が簡単（同じCommandを流して挙動比較ができる）
- UI/3D/自動操作/バッチが同じ入口に乗る（拡張しやすい）

## 17.2 Source of Truth（真実の置き場）

- **Command**: `world_command_log`（append-only）
- **Event**: `world_event_log`（append-only, channel/seq）

「世界状態」は Event を適用した結果（派生）として扱うのが基本。

## 17.3 Supabaseテーブル案（Commandログ）

`world_id` を前提にする（複数ワールド/シャード/テスト環境が破綻しにくい）。

```sql
create table world_command_log (
  id uuid primary key default gen_random_uuid(),

  world_id text not null,
  user_id uuid,                             -- ユーザー由来なら入る（NPC/システムはnullも可）

  type text not null,                       -- "user_say" | "user_move" | ...
  payload jsonb not null default '{}'::jsonb,

  -- 冪等性（同じ入力の二重実行を避ける）
  dedupe_key text,

  -- 追跡（このコマンドが生んだイベント群に繋ぐ）
  correlation_id uuid not null default gen_random_uuid(),
  causation_id uuid,                        -- 連鎖（別コマンド/別イベント由来）なら入る

  -- 実行状態（ワールドエンジンが更新する）
  status text not null default 'queued',    -- queued|accepted|rejected|processing|done|failed
  error_code text,
  error_message text,

  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create unique index idx_world_command_dedupe on world_command_log(world_id, dedupe_key) where dedupe_key is not null;
create index idx_world_command_world_time on world_command_log(world_id, created_at desc);
create index idx_world_command_corr on world_command_log(world_id, correlation_id);
```

### dedupe_key（冪等性）の方針

UIが「再送」しても二重に世界が進まないよう、`dedupe_key` を入れる。

例（UI側の生成）:

- `dedupe_key = "{sessionId}:{messageId}"`（チャット発話の再送抑止）
- `dedupe_key = "{worldId}:{userId}:{timestamp_bucket}:{action_hash}"`（操作系）

> `dedupe_key` が無いコマンドは「二重実行され得る」前提になる。危険な操作（アイテム消費など）は必ずdedupeする。

## 17.4 Commandタイプ（最初から想定する範囲）

“完成形”を見据えて、最初から **typeの枠だけ** 固定しておく（中身のpayloadはjsonbで拡張）。

### 17.4.1 user_say（発話）

```json
{
  "type": "user_say",
  "payload": {
    "channel": "world:{world_id}:{loc}",
    "loc": "hakurei_shrine",
    "text": "話しに来ただけだね",
    "to": { "kind": "npc", "id": "reimu" }
  }
}
```

### 17.4.2 user_move（移動）

```json
{
  "type": "user_move",
  "payload": {
    "from": "hakurei_shrine",
    "to": "human_village",
    "reason": "visit_shop"
  }
}
```

### 17.4.3 user_choose（選択肢）

```json
{
  "type": "user_choose",
  "payload": {
    "prompt_id": "uuid-or-string",
    "choice_id": "A",
    "choice_text": "お茶を飲む"
  }
}
```

### 17.4.4 user_request（依頼）

```json
{
  "type": "user_request",
  "payload": {
    "to": { "kind": "npc", "id": "nitori" },
    "request": "神社の賽銭箱の修理を手伝って",
    "constraints": { "budget": 0 }
  }
}
```

### 17.4.5 user_item_*（アイテム）

アイテムは“運用で破綻しやすい”ので、最初から型だけ分ける。

- `user_item_use`
- `user_item_give`
- `user_item_take`

> 実体（所持/消費/譲渡）はワールドエンジンが責務を持つ。UIはCommandを投げてEventを見る。

## 17.5 API契約（Command入口）

実装時の入口は、HTTPでもWSでも良い。長期で自然なのは「CommandはHTTP（or WS）で受付、結果はEventで返す」。

推奨（HTTP）:

- `POST /api/world/command`

Request（例）:

```json
{
  "world_id": "gensokyo_main",
  "type": "user_say",
  "payload": { "loc": "hakurei_shrine", "text": "話しに来ただけだね", "to": { "kind": "npc", "id": "reimu" } },
  "dedupe_key": "session:...:msg:..."
}
```

Response（例）:

```json
{
  "ok": true,
  "command_id": "uuid",
  "correlation_id": "uuid",
  "status": "queued"
}
```

重要:

- APIの戻りは「成功したイベント」ではなく **コマンド受付** を返す
- 実際に起きたことは WS（`world_event_log`）から流れる

## 17.5.1 実行（worker）モデル

本実装では、World Engine 側に「Command worker」を常駐させて、

1. `world_command_log (status=queued)` をポーリング
2. `queued → processing → done/failed` に更新
3. 成功時に `world_event_log` へイベントを append（`payload.trace` に correlation/causation を運ぶ）

という流れで処理する。

> UI は Command を投げるだけ。結果は WS で Event を購読して反映する（Source of Truth は Event）。

## 17.6 Eventとの紐付け（correlation / causation）

- `world_command_log.correlation_id` を、イベント側の `payload.trace.correlation_id`（または `payload.correlation_id`）として運ぶ
- これでUIは「自分の操作の結果のイベント」を追える

## 17.7 “最小を避ける”ための最初の約束

実装をまだしなくても、ここだけは先に固定しておくと後が楽:

1) **Commandログは必ず残す（append-only）**
2) **Eventログは必ず残す（append-only）**
3) **UIはCommandを投げ、Eventを購読する**
4) `world_id` は必須（複数ワールド/テスト/シャード前提）
