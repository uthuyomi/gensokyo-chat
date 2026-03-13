# 04 Scalability and Simulation Architecture（AI幻想郷ワールド）

目的:

- NPCやユーザーが増えても破綻しない設計原則をまとめる
- 「NPC数 × 会話回数 × LLM呼び出し」の爆発を避ける

結論:

- **リアルタイム常時計算をしない**
- 必要なところだけ計算する（Active/Passive）
- LLMを呼ぶ場所を限定する（会話/要約）

関連:

- `02_event_generation_engine.md`（Time Skip）
- `03_npc_behavior_planner.md`（行動決定はルール）

---

## 基本原則（これだけは守る）

1. リアルタイムNPCシミュレーション禁止
2. 必要な部分のみ計算（Active/Passive）
3. LLM呼び出しを最小化
4. 世界状態を軽量に保つ

---

## レイヤー構造

- World State Layer（軽い状態）
- Simulation Layer（Time Skipの枠組み）
- Event Layer（出来事生成）
- LLM Layer（会話/要約）

---

## World State Layer（軽い状態）

常に軽量であるべき。

例:

- location_id / sub_location_id
- time_of_day
- weather
- season
- moon_phase
- anomaly

---

## Simulation Layer（Time Skip）

世界進行の基本は Time Skip:

```
delta = now - last_visit
event_count = floor(delta / event_interval)
```

> 「ユーザーがいない間の詳細」は計算しない。再訪時にまとめて作る。

---

## Event Layer（イベント生成）

- まとめて生成（Event Batching）
- recent_event_filter / cooldown / 場所密度で暴走を防ぐ
- recent_events として会話に渡す

例:

- marisa_visit
- reimu_cleaning
- rain_start
- cirno_playing

---

## LLM Layer（LLMの役割を限定）

LLMは次に限定する:

- 会話生成
- イベント要約
- ストーリー生成（任意）

重要:

- **NPC行動決定にLLMを使わない**
- 行動はルール（FSM/BT）で決定する

---

## Active / Passive（計算の削減）

### Active NPC

- ユーザーの近く（同じ場所/同じイベント）
- 詳細AI（会話/感情/ジェスチャ等）を動かす対象

### Passive NPC

- ユーザーから遠い
- 簡易更新のみ（スケジュール消化、場所更新など）

### Activation

- ユーザーに近づいたら Passive → Active

---

## 記憶・ログの肥大化対策

- **要約保存**（長文は残さない）
- **Event TTL**（例: 30日で削除/アーカイブ）
- 必要なイベントだけ残す（継続感に効くものを優先）

---

## 水平スケール（将来）

ユーザー増加時はワールドを分割する（World Instances）。

例:

- gensokyo instance A
- gensokyo instance B

---

## 最終構造（到達形）

```
User
  ↓
World State
  ↓
Simulation Engine（Time Skip）
  ↓
Event Engine
  ↓
NPC Planner（ルール）
  ↓
LLM Dialogue（会話/要約）
```

---

## 最終目的

この設計により、

- NPC数が増えても
- ユーザーが増えても

サーバー負荷とコストを抑えながら「AI幻想郷ワールド」を維持できる。
