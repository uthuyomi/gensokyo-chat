# 11 Migrations / Seeding / Local Dev（ローカル開発手順）

この章は、`gensokyo-world-engine` / `gensokyo-event-gateway` / `touhou-talk-ui` をローカルで動かすための手順です。

前提：
- Supabaseプロジェクトがある（Service Role Keyを使える）
- Windows（PowerShell）想定

---

## 11.1 Supabase（SQL適用）

SupabaseのSQL Editorで、次を実行します。

1) 共通スキーマ（プロジェクトの既存手順がある場合はそれに従う）
2) 幻想郷ワールド用スキーマ

対象ファイル：
- `supabase/GENSOKYO_WORLD_SCHEMA.sql`
- `supabase/player_character_relations.sql`（Player↔Character関係性）
- `supabase/common_episodes_character_scoped.sql`（Episodic Memoryのcharacterスコープ）

このSQLで作られる主なテーブル：
- `world_event_log`（Event / append-only）
- `world_command_log`（Command / append-only）
- `world_state`（world_id + location_id の状態）
- `world_npc_state`（world_id + npc_id のスナップショット）
- `world_visits`（visitor_keyのlast_visit）
- `world_user_state`（移動/所持品などの器）
- `world_npc_memory_short` / `world_npc_memory_long`（記憶の器）

---

## 11.2 コンテンツ（JSON）

ワールドエンジンはローカルのJSONを読みます。

- 既定（world-engine内蔵）
  - `gensokyo-world-engine/content/locations.json`
  - `gensokyo-world-engine/content/events.json`
- 推奨（UIリポジトリ内で素材を一元管理）
  - `GENSOKYO_CONTENT_ROOT=touhou-talk-ui/world/layers/gensokyo`
  - `locations.json`, `characters.json`, `relationships.json`, `event_defs/*.json`

※ JSONはUTF-8で保存すること（壊れているとTime Skipが動きません）。

---

## 11.3 ローカル環境変数（例）

`.env` もしくはシェル環境変数で設定します（例は `.env.example` 参照）。

必須：
- `SUPABASE_URL`
- `SUPABASE_SERVICE_ROLE_KEY`

推奨（外部公開やWSゲート経由で叩くときの保護）：
- `GENSOKYO_WORLD_ENGINE_SECRET`（`/world/*` に `X-World-Secret` で付与）

コンテンツ（素材）：
- `GENSOKYO_CONTENT_ROOT` を設定すると、world-engineがそのディレクトリから素材を読む
  - 例：`touhou-talk-ui/world/layers/gensokyo`

NPC planner（BT）：
- `GENSOKYO_NPC_PLANNER_ENABLED`（既定 `1`）
- `GENSOKYO_NPC_PLANNER_COOLDOWN_SEC`（既定 `6`）
- `GENSOKYO_NPC_PLANNER_MAX_EVENTS`（既定 `2`）
- `GENSOKYO_NPC_SHORT_MEMORY_BACKEND`（`supabase` or `memory` / 既定 `supabase`）
- `GENSOKYO_NPC_PLANNER_LLM_PROVIDER`（`persona_chat` or `none` / 既定 `persona_chat`）
- `GENSOKYO_PERSONA_CORE_URL`（既定 `http://127.0.0.1:8000`）
- `GENSOKYO_PERSONA_CORE_BEARER_TOKEN`（必要なら。空なら未設定）
- `GENSOKYO_PERSONA_CORE_INTERNAL_TOKEN`（推奨: ローカル安定運用用。`SIGMARIS_INTERNAL_TOKEN` と同じ値を入れる）

Autonomous World Simulation（バックグラウンドtick）：
- `GENSOKYO_WORLD_SIM_ENABLED`（既定 `0`。有効化するとworld-engineが自律tickを開始）
- `GENSOKYO_WORLD_SIM_INTERVAL_SEC`（既定 `30`）
- `GENSOKYO_WORLD_SIM_WORLDS`（例: `gensokyo_main,gensokyo_test` / 未指定ならDB worlds→fallback）
- `GENSOKYO_WORLD_SIM_LOCATIONS`（例: `hakurei_shrine,human_village` / 未指定なら最近visitされた場所→fallback）
- `GENSOKYO_WORLD_SIM_MAX_LOCATIONS`（既定 `2`）
- `GENSOKYO_WORLD_SIM_ACTIVE_WINDOW_SEC`（既定 `600` / 最近visitベースの対象選定窓）
- `GENSOKYO_WORLD_SIM_NPC_MOVE_PROB`（既定 `0.18` / tickごとに「1NPCが隣接へ移動」する確率）

Player↔Character relation更新（会話イベント）：
- `GENSOKYO_REL_DELTA_AFFINITY_SAY`（既定 `0.010`）
- `GENSOKYO_REL_DELTA_TRUST_SAY`（既定 `0.004`）
- `GENSOKYO_REL_DELTA_FRIENDSHIP_SAY`（既定 `0.006`）

gensokyo-persona-core（認証・ローカル安定運用）：
- `SIGMARIS_INTERNAL_TOKEN`（推奨: world-engine → gensokyo-persona-core の内部呼び出しを安定化）

Command worker：
- `GENSOKYO_COMMAND_WORKER_ENABLED`（既定 `1`）
- `GENSOKYO_COMMAND_WORKER_POLL_MS`（既定 `500`）
- `GENSOKYO_COMMAND_WORKER_BATCH`（既定 `20`）

---

## 11.4 起動（world engine）

```powershell
python -m pip install -r gensokyo-world-engine/requirements.txt
cd gensokyo-world-engine
python -m uvicorn server:app --reload --port 8010
```

ヘルスチェック：
- `GET http://127.0.0.1:8010/health`

---

## 11.5 起動（event gateway / WS）

別ターミナルで：

```powershell
cd gensokyo-event-gateway
npm i
npm run dev
```

※ WSゲートはSupabase Realtime / DBを読みながらクライアントへ配信します（詳細は `16_realtime_event_gateway_ws.md`）。

---

## 11.6 起動（UI）

別ターミナルで：

```powershell
cd touhou-talk-ui
npm i
npm run dev
```

---

## 11.7 動作確認（最短）

### 1) world_state（初期作成される）
`X-World-Secret` を設定している場合はヘッダを付けます。

```powershell
$secret=$env:GENSOKYO_WORLD_ENGINE_SECRET
curl.exe -H \"X-World-Secret: $secret\" \"http://127.0.0.1:8010/world/state?world_id=gensokyo_main&location_id=hakurei_shrine\"
```

### 2) Time Skip（visit）
```powershell
curl.exe -X POST -H \"Content-Type: application/json\" -H \"X-World-Secret: $secret\" ^
  -d \"{\\\"world_id\\\":\\\"gensokyo_main\\\",\\\"layer_id\\\":\\\"gensokyo\\\",\\\"location_id\\\":\\\"hakurei_shrine\\\",\\\"visitor_key\\\":\\\"dev_user\\\",\\\"user_time\\\":\\\"2026-03-12T12:00:00+09:00\\\"}\" ^
  \"http://127.0.0.1:8010/world/visit\"
```

### 3) Command（user_say → Event → planner → Event）
```powershell
curl.exe -X POST -H \"Content-Type: application/json\" -H \"X-World-Secret: $secret\" ^
  -d \"{\\\"world_id\\\":\\\"gensokyo_main\\\",\\\"layer_id\\\":\\\"gensokyo\\\",\\\"type\\\":\\\"user_say\\\",\\\"user_id\\\":null,\\\"payload\\\":{\\\"loc\\\":\\\"hakurei_shrine\\\",\\\"text\\\":\\\"話しに来ただけ\\\",\\\"to\\\":\\\"reimu\\\"}}\" ^
  \"http://127.0.0.1:8010/world/command\"
```

その後、最新ログ確認：
```powershell
curl.exe -H \"X-World-Secret: $secret\" \"http://127.0.0.1:8010/world/recent?world_id=gensokyo_main&location_id=hakurei_shrine&limit=20\"
```

期待値：
- `user_say` が入る
- 直後に planner が `npc_action`（gesture）や `npc_say`（返答）を追記する（クールダウンで連発は抑制される）
