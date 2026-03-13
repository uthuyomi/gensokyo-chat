# 01 Supabaseテーブル設計（AI幻想郷ワールド）

目的:

- AI幻想郷ワールドの **世界状態・NPC状態・出来事・関係・ユーザー最終訪問** を保存する
- 最小構成で始めつつ、後で拡張できる形にする

前提:

- Supabase = PostgreSQL なので標準的なRDB設計で良い
- “全文ログ保存”は肥大化しやすいので、基本は **イベントは短い要約＋機械用JSON** を保存する

関連:

- `02_event_generation_engine.md`（イベント生成と保存の流れ）
- `03_npc_behavior_planner.md`（NPC状態がどう更新されるか）

---

## 最小テーブル（推奨）

- `world_state`（世界状態: いまどうなってるか）
- `characters`（NPC状態）
- `events`（出来事ログ）
- `relationships`（関係値）
- `user_state`（ユーザー最終訪問・現在地など）

> 方針決定: **`world_id` を最初から導入する（必須）**。  
> `layer_id` は表示・分類用として残して良いが、シャード/別幻想郷/テスト環境の単位は `world_id` を正にする。

推奨で追加する:

- `worlds`（ワールド定義）
- `world_event_channels` / `world_event_log`（WS配信向けの順序保証ログ）
- `world_command_log`（ユーザー介入の意図ログ）→ `17_command_bus_and_user_interactions.md`

---

## worlds（ワールド定義 / 推奨）

```sql
create table worlds (
  id text primary key,                    -- world_id（例: "gensokyo_main"）
  layer_id text not null,                 -- 表示・分類（例: "gensokyo"）
  name text not null,                     -- 表示名
  created_at timestamptz not null default now()
);
```

### world_id 命名規約（方針確定）

`world_id` は「運用とデバッグで人間が読める」ことを優先し、固定の命名規約で作る。

- 本番メイン: `gensokyo_main`
- テスト: `gensokyo_test`
- シャード: `gensokyo_shard_01`, `gensokyo_shard_02`, ...

ルール:

- `world_id` は **一度作ったら変更しない**（ログ/チャンネル/外部キーに埋まる）
- shard番号はゼロ埋め（`01`）で揃える（並びが安定）

例:

- `id = gensokyo_main`
- `layer_id = gensokyo`
- `name = 幻想郷（メイン）`

---

## world_state（世界状態）

保存するもの（例）:

- `layer_id`（例: gensokyo）
- `location_id` / `sub_location_id`
- `time_of_day`（morning/day/evening/night）
- `weather` / `season` / `moon_phase`
- `anomaly`（異変ID、なければnull）

SQL例（最低限）:

```sql
create table world_state (
  world_id text not null,
  layer_id text not null,
  location_id text not null,
  sub_location_id text,
  time_of_day text not null,
  weather text not null,
  season text not null,
  moon_phase text,
  anomaly text,
  updated_at timestamptz not null default now(),
  primary key (world_id, location_id)
);
```

---

## characters（NPC状態）

保存するもの（例）:

- 現在地（location/sub_location）
- 行動（current_action）
- 感情（emotion）
- エネルギー等（任意）

SQL例:

```sql
create table characters (
  world_id text not null,
  layer_id text not null,
  id text not null,
  name text not null,
  location_id text,
  sub_location_id text,
  current_action text,
  emotion text,
  energy real,
  last_update timestamptz not null default now(),
  primary key (world_id, id)
);
```

例:

- `id = reimu`
- `location_id = hakurei_shrine`
- `current_action = tea_time`
- `emotion = calm`

---

## relationships（関係値）

最初は主要ペアだけでも成立する（全組み合わせは不要）。

SQL例:

```sql
create table relationships (
  world_id text not null,
  layer_id text not null,
  character_a text not null,
  character_b text not null,
  trust real,
  caution real,
  familiarity real,
  last_update timestamptz not null default now(),
  primary key (world_id, character_a, character_b)
);
```

---

## events（出来事ログ）

イベントは **機械用の構造（JSON）** と **表示用の短い要約** を分けて持つと後で強い。

SQL例:

```sql
create table events (
  id uuid primary key default gen_random_uuid(),
  world_id text not null,
  layer_id text not null,
  location_id text not null,
  sub_location_id text,
  event_type text not null,
  participants jsonb not null default '[]'::jsonb,
  payload jsonb not null default '{}'::jsonb,
  summary text,
  created_at timestamptz not null default now()
);
```

例:

- `event_type = marisa_visit`
- `participants = ["reimu","marisa"]`
- `summary = "魔理沙が神社に来てお茶を飲んだ"`

インデックス例:

```sql
create index idx_events_world_loc_time on events(world_id, location_id, created_at desc);
create index idx_events_type_time on events(event_type, created_at desc);
```

---

## world_event_channels / world_event_log（リアルタイム配信用・推奨）

到達点③（イベントログが流れる）＋リアルタイム（WS）を、**取りこぼしゼロ**（`lastSeq` で確実リプレイ）にしたい場合に必要。

- 詳細仕様: `16_realtime_event_gateway_ws.md`
- ここでは **DB永続ログ** の最小スキーマだけを確定する

### 何を解決するテーブルか

- `world_event_channels`: チャンネルごとの `current_seq` を持つ（単調増加の根拠）
- `world_event_log`: チャンネル内のイベントを `seq` 付きでappend-only保存する

> 既存の `events` と役割が被るように見えるが、`events` は「世界エンジンの出来事ログ」、`world_event_log` は「UI配信（WS）のための順序保証ログ」として分ける。  
> 将来、運用が安定したら `events` に寄せる（統合）こともできるが、最初は分離が安全。

### world_event_channels（チャンネルのseq管理）

```sql
create table world_event_channels (
  channel text primary key,               -- "world:{world_id}" or "world:{world_id}:{loc}"
  world_id text not null,
  layer_id text not null,
  location_id text,                       -- loc channelの場合のみ（nullable）
  current_seq bigint not null default 0,
  updated_at timestamptz not null default now()
);
```

### world_event_log（イベント本体）

```sql
create table world_event_log (
  id uuid primary key default gen_random_uuid(),

  channel text not null references world_event_channels(channel) on delete cascade,
  seq bigint not null,                    -- channel内で単調増加
  ts timestamptz not null default now(),

  world_id text not null,
  layer_id text not null,
  location_id text,                       -- locがある場合のみ

  type text not null,                     -- "world_tick" | "npc_action" | "npc_say" | "system"
  actor jsonb,                            -- { kind: "npc"|"user"|"system", id?: string }
  payload jsonb not null default '{}'::jsonb
);

create unique index idx_world_event_log_channel_seq on world_event_log(channel, seq);
create index idx_world_event_log_channel_seq_desc on world_event_log(channel, seq desc);
create index idx_world_event_log_channel_ts_desc on world_event_log(channel, ts desc);
```

### seq採番（重要）

`seq` は **チャンネルごと** に単調増加させる。採番は必ず **トランザクション** で行う。

擬似コード（実装時）:

1. `world_event_channels` を `UPDATE ... SET current_seq = current_seq + 1 ... RETURNING current_seq` で更新
2. 返ってきた `current_seq` を `world_event_log.seq` に入れてINSERT

これで `lastSeq` → `fromSeq` の復元が確実になる。

---

## user_state（ユーザー状態）

最小で必要なのは:

- `last_visit`（Time Skipの基準）
- `location_id`（再訪時の場所）

SQL例:

```sql
create table user_state (
  user_id uuid primary key,
  world_id text not null,
  layer_id text not null,
  location_id text,
  sub_location_id text,
  last_visit timestamptz,
  updated_at timestamptz not null default now()
);
```

---

## ログ肥大化対策（最初から入れておく）

- **Event TTL**: 古いイベントは削除 or アーカイブ（例: 30日）
- **要約保存**: 長文会話を保存せず、短い要約と機械用JSONで残す

ポイント:

- “全部保存”は必ず破綻する
- 「何を残すと世界の継続感が出るか」を選ぶ（recent events / 関係 / 世界状態が最重要）
