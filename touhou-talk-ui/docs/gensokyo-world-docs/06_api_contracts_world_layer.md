# 06 API Contracts（World Layer / 実装用）

このドキュメントは `touhou-talk-ui` の延長でワールド層を足す時の、APIのI/Oを固定する。

方針:

- UIは現状のチャットUIを基本維持
- ワールドは **訪問時** に Time Skip を実行して追いつく
- “会話に混ぜる材料”を返すAPIを用意する

---

## 1) Visit（再訪・Time Skip）

### `POST /api/world/visit`

用途:

- ユーザーが `world/loc` に入った（または再訪した）タイミングで呼ぶ
- `last_visit` から `now` までの差分を使ってイベントを生成し、状態を更新する

Request:

```json
{
  "world_id": "gensokyo_main",
  "location_id": "hakurei_shrine",
  "sub_location_id": "kei_dai",
  "user_time": "2026-03-12T18:00:00+09:00"
}
```

Response:

```json
{
  "ok": true,
  "delta_sec": 28800,
  "world_state": {
    "world_id": "gensokyo_main",
    "time_of_day": "evening",
    "weather": "clear",
    "season": "spring",
    "moon_phase": "full"
  },
  "recent_events": [
    {
      "event_type": "marisa_visit",
      "summary": "魔理沙が神社に寄って、霊夢に小言を言われた。",
      "created_at": "2026-03-12T16:10:00+09:00"
    }
  ],
  "npc_state_changes": [
    { "id": "marisa", "location_id": "hakurei_shrine" }
  ]
}
```

備考:

- `recent_events` は「会話プロンプトに混ぜる」ことを意図して短く返す
- UIに表示する場合もあるので、極力短く

---

## 2) Read World State

### `GET /api/world/state?world_id=...&location_id=...`

Response:

```json
{
  "world_id": "gensokyo_main",
  "location_id": "hakurei_shrine",
  "time_of_day": "evening",
  "weather": "clear",
  "season": "spring",
  "moon_phase": "full",
  "anomaly": null,
  "updated_at": "2026-03-12T18:00:00+09:00"
}
```

---

## 3) Read Recent Events

### `GET /api/world/recent?world_id=...&location_id=...&limit=10`

Response:

```json
{
  "recent_events": [
    {
      "event_type": "reimu_cleaning",
      "summary": "霊夢が境内を軽く掃除した。",
      "created_at": "2026-03-12T12:00:00+09:00"
    }
  ]
}
```

---

## 4) NPC Snapshot（必要なら）

### `GET /api/world/npcs?world_id=...&location_id=...`

用途:

- “同じ場所にいるNPC” をUIに出したい場合

Response:

```json
{
  "npcs": [
    { "id": "reimu", "location_id": "hakurei_shrine", "action": "tea_time", "emotion": "calm" }
  ]
}
```

---

## 5) Chat APIに混ぜる（設計方針）

チャットのプロンプトに混ぜる材料:

- `world_state`（短く）
- `recent_events`（最大N件、短い要約）
- `relationship`（主要なものだけ）

> ここで重要なのは **LLMに“世界更新”をさせない** こと。  
> LLMは「会話と要約」に限定し、状態更新はワールドエンジン側で行う。

---

## 6) Realtime Event Stream（WebSocket / 推奨）

到達点③（イベントログが流れる）＋リアルタイムは、HTTPポーリングより **WSのイベントゲートウェイ** を正にする。

- 仕様の本体: `16_realtime_event_gateway_ws.md`
- この章では「UIがどう繋ぐか」の入口だけを定義する

### 接続

- UIは `World Event Gateway` にWS接続する
- `channel` を購読して `snapshot` → `event` を受け取る

### 購読単位（channel）

前提: **`world_id` を最初から導入する**（複数ワールド/シャード/テスト環境のため）。

- `world:{world_id}`
- `world:{world_id}:{loc}`

例:

- `world:gensokyo_main`
- `world:gensokyo_main:hakurei_shrine`

### 再接続（lastSeq）

UIはチャンネルごとに `lastSeq` を保持し、再接続時に `subscribe(channel, lastSeq)` を送る。  
サーバは `snapshot(fromSeq=lastSeq+1)` を返してから live に切り替える。

---

## 7) User Commands（発話/移動/選択肢/依頼/アイテム）

ユーザー介入は「世界更新」なので、チャットの延長でLLMにやらせず **Commandとして受付**し、結果はEventで返す。

仕様の本体: `17_command_bus_and_user_interactions.md`

推奨API（実装時）:

### `POST /api/world/command`

Request（例）:

```json
{
  "world_id": "gensokyo_main",
  "type": "user_move",
  "payload": { "from": "hakurei_shrine", "to": "human_village" },
  "dedupe_key": "..."
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

> コマンドが受理されても、実際に何が起きたかは WS（イベントログ）で観測する。
