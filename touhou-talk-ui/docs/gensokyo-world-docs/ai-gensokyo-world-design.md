# AI幻想郷ワールド構想（読みやすい版）

このプロジェクトは、LLMを使って幻想郷世界を“会話アプリ”ではなく“世界”として扱い、
ユーザーがいない間も進行していたように見える **AIワールド** を作る構想。

> 重要: ここでいう「世界が進む」は **リアルタイム常時シミュレーションではなく**、再訪時にまとめて進める *Time Skip Simulation* を中核にする。

関連ドキュメント:

- `00_stack_and_phased_architecture.md`（導入順と構成の整理）
- `01_supabase_schema_ai_gensokyo.md`（DB）
- `02_event_generation_engine.md`（Time Skipイベント生成）
- `03_npc_behavior_planner.md`（NPC行動決定）
- `04_scalability_and_simulation_architecture.md`（スケール）
- `05_domain_models_and_data_specs.md`（実装用のデータ仕様）
- `06_api_contracts_world_layer.md`（実装用のAPI I/O）
- `07_prompt_templates.md`（プロンプト部品）
- `08_checklists_and_test_plan.md`（破綻検知）
- `09_content_authoring_playbook.md`（素材づくり手順）
- `10_world_engine_invariants_and_tick.md`（整合性ルール / Time Skipの核）
- `11_migrations_seeding_and_local_dev.md`（DB適用/seed/ローカル手順）
- `12_integration_with_touhou_talk_ui.md`（既存UIへの統合）
- `13_observability_and_cost_tuning.md`（運用/コスト/観測）
- `14_prompt_regression_suite.md`（品質チェック用プロンプト集）
- `15_3d_migration_path.md`（UI維持のまま3Dへ段階移行）

---

## ゴール

- NPCが生活しているように見える
- 場所や時間帯で空気が変わる
- ユーザーが離席して戻ると「さっき◯◯があった」と自然に語れる

---

## 非ゴール（最初はやらない）

- NPC全員のリアルタイム常時計算
- 会話や行動をすべてLLMに丸投げ
- “重い”インフラ（ベクタDB/Neo4j/キュー/リアルタイム）を最初から全部載せ

---

## 基本アーキテクチャ（5層）

### 1) World Layer（世界状態）

天気/季節/月齢/異変/イベントなど、「世界が今どうなってるか」。

例:

- `weather = rain`
- `season = spring`
- `moon_phase = full`

### 2) Time Layer（時間）

現実時間 or 幻想郷時間（朝/昼/夕/夜）。
行動や会話のトーン、イベント候補の重み付けに使う。

### 3) Space Layer（空間）

場所は **グラフ構造** で管理する（場所・サブロケ・隣接）。

例:

```
博麗神社
  ├ 縁側
  ├ 境内
  └ 社殿

魔法の森
  ├ 入口
  └ アリスの家
```

### 4) Social Layer（関係）

キャラ同士・キャラとユーザーの関係値（trust/caution/familiarityなど）。
行動選択・会話トーン・イベント候補に影響。

### 5) Character Layer（人格/状態）

NPCごとの状態（現在地/行動/感情/エネルギー/興味など）。
ここは **行動決定の入力** になる。

---

## 記憶（Memory Architecture）

世界が“生きてる感”を出す上で一番重要。
最初は次の3分類で十分。

### Episodic Memory（出来事）

例: 魔理沙が神社に来た

```json
{
  "event": "marisa_visit",
  "location": "hakurei_shrine",
  "time": "2026-03-11T14:00",
  "participants": ["reimu", "marisa"]
}
```

### Social Memory（関係）

例: `reimu ↔ marisa trust=0.7`

### World Memory（世界状態）

例: 昨日は雨だった

---

## 「ユーザーがいない間に起きたこと」を作る（Time Skip Simulation）

リアルタイムに世界を回さない代わりに、ユーザー再訪時にまとめて生成する。

1. `last_visit` を取得
2. `now` を取得
3. `delta = now - last_visit` を計算
4. `delta` に応じてイベントを抽選（条件・クールダウン・密度あり）
5. NPC状態・世界状態を更新
6. イベントを保存（必要なら要約も生成）
7. 次の会話プロンプトに `recent_events` を渡す

ユーザー再訪時の台詞例:

> 「さっき魔理沙が来てたのよ」

---

## 最低限必要なデータ構造

- `world_state`
- `characters`（NPC状態）
- `events`（出来事ログ）
- `relationships`（関係値）
- `user_state`（最終訪問など）

---

## 既知の最大問題と対策

### 問題: 計算量の爆発

`NPC数 × 会話回数 × LLM呼び出し` が増えると破綻しやすい。

### 対策: 世界エンジンを先に固める

- **リアルタイム禁止**
- 行動決定は **ルールベース（FSM/BT）**
- LLMは **会話/要約に限定**
- Active/Passive（近いキャラだけ詳細）

---

## 最終目標（到達イメージ）

- AIキャラが生活し
- NPCイベントが蓄積し
- 社会関係が変化し
- 小さなストーリーが自然に生まれる

ユーザーは「幻想郷に訪問する」感覚で体験する。
