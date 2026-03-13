# 10 World Engine Invariants & Tick（整合性ルール / Time Skipの核）

ここは “世界が壊れないためのルール” を固定する章。
仕組み的には、LLMよりこっちが重要だよ。ここがブレると全部が破綻する。

対象:

- Invariants（絶対に守るべき整合性）
- Time Skip tick（訪問時に世界を進める手順）
- 乱数/同時更新/競合の扱い

---

## 1) Invariants（絶対ルール）

### I1. 位置の一意性

- 1キャラは同時に1つの `location_id` にしか存在しない
- `sub_location_id` はその `location_id` の子である

### I2. 時間の単調性

- `last_visit <= now` を保証（未来のlast_visitは禁止）
- `event_log.created_at` は原則、過去に戻らない（Time Skip中も）

### I3. 世界更新の権限

- **世界状態（位置/イベント数/発生ログ）はワールドエンジンが決める**
- LLMは **会話/要約/演技** だけ

### I4. 再現性（デバッグ可能性）

同じ入力（world_id/location/last_visit/now/seed）なら、できるだけ同じ結果を出せる設計が強い。

---

## 2) Time Skip Tick（訪問時に世界を進める）

基本形（おすすめ）:

1. `delta_sec = now - last_visit` を計算
2. `event_budget = f(delta_sec, location_density)` を決める
3. `event_candidates` を集める
4. `cooldown/recent` で候補を削る/重みを落とす
5. 抽選して `event_logs` を作る
6. `effects` を適用して `character_state/world_state` を更新
7. `summary` を必要なら作る（LLMまたはテンプレ）
8. `last_visit` を更新

> コスト爆発を防ぐコツは「2) で上限を握る」こと。

---

## 3) event_budget（生成数）設計

まずは雑に強いルールでOK:

- `delta_sec < 10分`: 0〜1
- `10分〜2時間`: 1〜2
- `2時間〜8時間`: 2〜5
- `8時間以上`: 3〜8（ただし上限固定）

さらに場所で補正:

- `density=low`: ×0.5
- `density=med`: ×1.0
- `density=high`: ×1.5

> ここは “体験のテンポ” のツマミ。後から調整しやすいように定数化しとくのが良い。

---

## 4) 候補の集め方（event_candidates）

最初は単純でいい:

- location_id が一致するイベント
- サブロケ一致（任意）
- required participants が「そこに居る」または「来られる」イベント

後から強くする:

- 天気/時間帯/季節の制約
- “静かな場所” は会話イベント中心に寄せる

---

## 5) 連発防止（cooldown + recent filter）

### 5.1 cooldown

`event_type` ごとに `cooldown_hours` を持ち、直近にあれば弾く。

### 5.2 recent filter

直近N件に同じ `event_type` があると、重みを落とす（完全禁止より自然）。

例:

- 直近10件に存在 → 重み 0.2
- 直近3件に存在 → 重み 0.05

---

## 6) effects（状態更新）の扱い

大原則:

- “状態更新” は **機械ルールで確定** する
- `effects` は小さく、衝突しない設計にする

よくある衝突:

- Aイベントが「魔理沙は神社にいる」と言い、Bイベントが「魔理沙は村にいる」と言う

対策:

- 1 tick 内で「位置更新イベント」を多重に起こさない
- “移動イベント” は tick の最初にまとめて処理する、など順序を決める

---

## 7) 乱数（RNG）の扱い

デバッグのために、可能なら seed を固定する。

おすすめ:

- `seed = hash(layer_id, location_id, last_visit, now, user_id?)`
- 乱数は tick の中だけで使う（外に漏らさない）

> これで “なぜそのイベントが出たか” を追いやすくなる。

---

## 8) 同時更新（競合）をどう潰すか

現実の勝ち筋:

- **1ユーザー=1 layer_id** なら、競合はほぼ起きない（最初はこれでOK）
- 共有ワールドにするなら、ロック/キュー/トランザクション設計が必要

最初の設計メモ:

- `world_state` 更新は `SELECT ... FOR UPDATE` 相当でロック
- `visit` を “同じ world_id/location は同時に1つだけ” に制限

---

## 9) LLMを入れる場所（最小）

Time Skip tick の中で LLM を呼ぶなら、原則ここだけ:

- `event_log.summary` の短い要約（任意）

会話は tick の外（ユーザーが話しかけたとき）にする。
