# 05 Domain Models & Data Specs（実装用）

このドキュメントは「実装時に迷わないための“データの形”」を固定する。

対象:

- Location Graph（場所/サブロケ/隣接）
- Character Profile / State（キャラの固定プロフィール / 変化する状態）
- Relationship（関係値）
- Event Definition / Event Log（イベント定義 / 発生ログ）

> 方針: まずはRDB（Supabase/Postgres）＋JSONで成立させる。  
> グラフDBやベクタDBは、必要になってから導入する。

---

## 1) Location Graph

目的:

- NPCの移動、遭遇、会話トリガー、イベント抽選の「地形」を提供する

### 1.1 ロケーション（Location）

```json
{
  "id": "hakurei_shrine",
  "name": "博麗神社",
  "tags": ["shrine", "outdoor", "public"],
  "density": "high",
  "capacity": 6,
  "sub_locations": ["kei_dai", "engawa", "haiden"],
  "neighbors": ["human_village", "youkai_mountain_foot"]
}
```

フィールド:

- `id`: 永続ID（URL/DBキー）
- `tags`: ルール参照用（屋内/屋外/公共/静か/危険…）
- `density`: イベント密度（high/med/low）
- `capacity`: “濃いイベント”を同時に発火させてよい人数目安
- `sub_locations`: サブロケID一覧
- `neighbors`: 隣接するlocation_id（移動可能先）

### 1.2 サブロケ（SubLocation）

```json
{
  "id": "engawa",
  "parent": "hakurei_shrine",
  "name": "縁側",
  "tags": ["rest", "quiet"],
  "capacity": 2
}
```

---

## 2) Character（固定プロフィール / 変化する状態）

### 2.1 固定プロフィール（CharacterProfile）

```json
{
  "id": "reimu",
  "name": "霊夢",
  "home_location_id": "hakurei_shrine",
  "traits": ["pragmatic", "low_energy", "guardian"],
  "speech_style": "reimu",
  "likes": ["tea", "quiet"],
  "dislikes": ["trouble", "debt"],
  "default_emotion": "neutral"
}
```

### 2.2 変化する状態（CharacterState）

```json
{
  "id": "reimu",
  "location_id": "hakurei_shrine",
  "sub_location_id": "engawa",
  "current_action": "tea_time",
  "emotion": "calm",
  "energy": 0.7,
  "social_interest": 0.4,
  "updated_at": "2026-03-12T10:00:00+09:00"
}
```

ルール:

- `location_id` / `sub_location_id` が“空間”の真実
- `current_action` は “FSM/BTの状態” として使う
- `emotion` は “会話トーンと表現（VRM）” の入力

---

## 3) Relationship（関係値）

```json
{
  "character_a": "reimu",
  "character_b": "marisa",
  "trust": 0.8,
  "caution": 0.3,
  "familiarity": 0.9,
  "last_update": "2026-03-01T09:00:00+09:00"
}
```

ルール:

- 方向性が必要なら A→B と B→A を別行にする
- 最初は“主要ペアのみ”でよい（全組み合わせ不要）

---

## 4) Event（定義 / 発生ログ）

### 4.1 EventDefinition（イベント定義）

```json
{
  "id": "marisa_visit",
  "location_id": "hakurei_shrine",
  "probability": 0.25,
  "cooldown_hours": 12,
  "constraints": {
    "time_of_day": ["day", "evening"],
    "weather_not": ["storm"]
  },
  "participants": {
    "required": ["reimu", "marisa"],
    "optional": []
  },
  "effects": {
    "state": [
      { "target": "marisa", "set": { "location_id": "hakurei_shrine" } }
    ],
    "relationship": []
  }
}
```

### 4.2 EventLog（発生ログ）

```json
{
  "id": "uuid",
  "event_type": "marisa_visit",
  "world_id": "gensokyo_main",
  "layer_id": "gensokyo",
  "location_id": "hakurei_shrine",
  "sub_location_id": "kei_dai",
  "participants": ["reimu", "marisa"],
  "payload": {
    "reason": "borrow_money"
  },
  "summary": "魔理沙が神社に寄って、霊夢に小言を言われた。",
  "created_at": "2026-03-12T18:00:00+09:00"
}
```

ルール:

- `payload` は機械用（後で再要約/再生成しやすい）
- `summary` はUI/会話用（短く）

---

## 5) “レイヤ/ワールドID”の扱い

将来のスケールのために、最初から以下を入れるのが安全:

- `world_id`（必須。複数ワールド/シャード/テスト環境の単位）
- `layer_id`（任意。表示・分類用。world_idから導出できても持って良い）
- `location_id`（世界内の場所）

これで「複数ワールド」「複数インスタンス」の拡張が破綻しにくい。
