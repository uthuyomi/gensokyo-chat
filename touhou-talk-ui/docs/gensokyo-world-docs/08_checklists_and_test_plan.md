# 08 Checklists & Test Plan（実装用）

このドキュメントは「世界が壊れてないか」を実装中に確認するためのチェックリスト。

目的:

- 破綻しやすいポイント（整合性/連発/矛盾/コスト）を先に潰す
- デバッグの観測点を固定する

---

## A. 整合性チェック（必須）

### A1. 位置の整合性

- NPCの `location_id` は存在するか（ロケーショングラフにあるか）
- `sub_location_id` は `location_id` の子か
- 同一NPCが同時に複数場所にいないか

### A2. 時間の整合性

- `user_state.last_visit` が未来になっていないか
- event_log の created_at が単調増加しているか（少なくとも“逆転”してないか）

### A3. 世界状態の整合性

- `world_state` が `layer_id, location_id` で1行に収まっているか
- `time_of_day` が許容値か（morning/day/evening/night）

---

## B. 破綻防止チェック（体験に直結）

### B1. 連発防止

- 同じ event_type が短時間に連続しない（cooldown）
- recent_event_filter が機能している（直近N件で重みを落とす）

### B2. 場所密度

- “静かな場所”でイベントが起きすぎない
- “人が集まる場所”でイベントが全然起きない、になっていない

---

## C. LLMコスト・呼び出し制御

### C1. LLMを呼ぶ箇所が限定されている

- 会話生成
- 要約生成（任意）

※ 行動決定や状態更新でLLMが呼ばれていないこと。

### C2. 呼び出し回数がスケールしない

- “訪問時にまとめて生成”になっている
- NPC数に比例して常時LLMを呼ばない

---

## D. テストシナリオ（最小）

### D1. 8時間のTime Skip

1. last_visit=10:00
2. now=18:00
3. 期待: event_countが増える / recent_eventsが出る / キャラが「さっき〜」と言える

### D2. 連続訪問（deltaが小さい）

1. last_visit=18:00
2. now=18:05
3. 期待: ほぼイベントが増えない / 無駄なLLMを呼ばない

### D3. 雨の日の制約

1. weather=rain
2. 期待: outdoorイベントが減る / 代替の屋内イベントが増える

### D4. 同一イベントの連発防止

1. marisa_visit が直近にある
2. 期待: 次の抽選で marisa_visit が出にくい/出ない

---

## E. デバッグ観測点（ログに出すと便利）

- visit実行時:
- world_id/location
  - last_visit, now, delta_sec
  - event_count（生成数）
  - 抽選候補数 / 除外数（cooldown/recent）
- 生成後:
  - recent_events（event_typeのみでも良い）
  - NPC state changes（誰がどこへ）

実装状況（現状）：
- `visit` の観測ログ：`GENSOKYO_WORLD_LOG_VISIT_DEBUG=1`（既定ON）で `[world.visit] {...}` を出力
- Invariants簡易チェッカ：`gensokyo-world-engine/tools/check_invariants.py`
