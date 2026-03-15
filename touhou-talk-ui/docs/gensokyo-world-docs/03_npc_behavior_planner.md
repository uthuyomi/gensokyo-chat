# 03 NPC Behavior Planner（NPC思考・行動決定）

この章は **「NPCが世界イベントを見て、意図→行動→台詞を決め、イベントとして記録する」** ための設計です。

結論：Touhou-talkのワールド更新におけるNPC plannerは **Behavior Tree（BT）で実装** します。

- 採用：**BT（`py_trees`）**
- 理由：状態爆発しにくく、優先順位（割り込み）・条件分岐・再利用が素直、後からノードを増やしやすい
- LLMの扱い：**「台詞生成 / 要約 / 選択」だけ** に限定し、**世界状態更新は禁止**（世界更新はワールドエンジンのコードのみ）

関連：`02_event_generation_engine.md`（Time Skip） / `17_command_bus_and_user_interactions.md`（Command Bus）

---

## 03.1 目的と非目的

### 目的
- 直近イベント（例：`user_say`）を入力に、NPCが「何をするか」を決める
- 決定した行動を **Event（`world_event_log`）として追記** し、UI/3Dが同じログを再生できる
- 破綻しやすい点（無限会話・反復・キャラ崩壊）を **構造（BT + 制約 + 記憶）で抑制** する

### 非目的（禁止事項）
- NPC plannerが `world_state` / `world_npc_state` / `world_user_state` を直接更新すること（= LLMに更新させること）
- Eventログを読んでさらにEventを無限に生成する“自己増殖”
- 物理/IK/アニメーションの詳細制御（それはUI/3D側の責務）

---

## 03.2 入力（Plannerが参照できる情報）

plannerは以下を **参照専用** で受け取ります。

- `source_event`: きっかけになったイベント（多くはCommandから生成されたEvent）
- `world_state`: 時間帯/天候/季節など（`world_state`）
- `npc_state[]`: そのロケーションに居るNPCスナップショット（`world_npc_state`）
- `user_state`（任意）: ユーザー位置/所持品など（`world_user_state`）
- `memory`（短期/長期）: 後述（差し替え可能なインターフェース）

---

## 03.3 出力（Plannerが生成するもの）

plannerは **“世界を直接更新せず”**、あくまで「こういうイベントを追加してほしい」という **計画（plan）** を返します。

例：

```json
[
  {
    "type": "npc_action",
    "actor": { "kind": "npc", "id": "reimu" },
    "payload": {
      "event_type": "npc_action",
      "gesture": "nod_yes",
      "summary": "霊夢がうなずいた。"
    }
  },
  {
    "type": "npc_say",
    "actor": { "kind": "npc", "id": "reimu" },
    "payload": {
      "event_type": "npc_say",
      "text": "……話しに来ただけ？",
      "summary": "霊夢が返答した。"
    }
  }
]
```

**実際のDB書き込み（append）はワールドエンジン側が行う**（plannerはI/Oを持たない）。

---

## 03.4 BT採用の理由（FSMではなくBT）

### BTが得意
- 優先順位（割り込み）を自然に表現できる（例：危険→会話→作業→待機）
- ノードの再利用がしやすい（条件/行動を部品化して増やせる）
- “会話しすぎ”をクールダウン/回数制限ノードで統制しやすい

### FSMで起きがちな痛み
- 状態が増えるほど遷移が増える（状態爆発）
- “例外（割り込み）”が増えるほど見通しが悪くなる

---

## 03.5 重要な設計：イベント → 意図 → 行動 → 台詞 → イベント

plannerは必ずこの流れで動きます（LLMを使う場合も同じ）。

1) `source_event` を読む（何が起きた？）
2) **意図** を決める（返事する/無視/警戒/招く など）
3) **行動** を決める（gesture / 移動 / 依頼受諾 など）
4) **台詞**（または要約/選択）を生成する（LLMはここだけ）
5) それを **Eventとして追記** する（append-only）

“世界の真実”はEventログに残り、UI/3Dはそれを再生して表現します。

---

## 03.6 制約（破綻を防ぐための強制ルール）

- **反応回数の上限**：1つの`source_event`につき、plannerが追記するイベントは最大N件（例：1〜3）
- **クールダウン**：同じNPCが短時間に連続発話しない
- **recent filter**：直近で同種イベントが多い場合は反応確率を落とす
- **自己トリガ禁止**：`npc_say` に対して `npc_say` を無限に返さない（“ユーザー発話”や“外部イベント”にだけ反応する等）

---

## 03.7 記憶の器（差し替え前提インターフェース）

最初から差し替え前提で、少なくとも次を用意します。

### 短期記憶（Short Memory）
- `last_spoke_at` / `last_gesture_at`
- 直近の会話相手（`user_id` or `npc_id`）
- 直近のintent（短期の態度）

### 長期記憶（Long Memory）
- エピソード（出来事）要約
- 関係（trust/caution/familiarity等）の更新履歴（最初はログだけでもよい）

バックエンドは段階導入：最初はDB（Supabase JSON）→ 後でベクタDBに置換。

---

## 03.8 LLMの役割（“世界更新禁止”を徹底）

LLMは **副作用ゼロ** の関数として扱います。

- 入力：コンテキスト（`source_event` / `npc_profile` / `recent_events` / `memory`要約）
- 出力：台詞テキスト、要約、選択（JSON）

禁止：
- `world_state` / `world_npc_state` / `world_user_state` を書き換える指示（たとえJSONで返ってきても無視）

実装メモ（現状）：
- LLMは `gensokyo-persona-core` の `POST /persona/chat` を **台詞生成専用** として呼ぶ（SSEではない）
- world-engineは **reply文字列だけ** を採用し、他の構造出力（JSON等）は無視する

---

## 03.9 実行モデル（どこでplannerが走るか）

- `world_command_log` にCommandが入る（UI/WSゲート経由）
- **world-engineのcommand worker** がCommandを処理し、Eventを追記する
- その直後に **plannerを実行** し、追加Event（`npc_action` / `npc_say` 等）を追記する

これで「リアルタイム更新（Command→Event→planner→Event）」が一本化されます。
