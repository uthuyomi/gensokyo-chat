# 13 Observability & Cost Tuning（運用・デバッグ・コスト制御）

ここは “作ったあと壊れないようにする” 章。
幻想郷ワールドは放っておくと、コストとカオスが増える。だから先にツマミを作っておく。

---

## 1) ログ（最低限これだけ）

`visit` のたびに、必ずログで出す（server-side）。

- `layer_id`, `location_id`
- `last_visit`, `now`, `delta_sec`
- `event_budget`（生成予定数）
- `candidates_count`
- `excluded_by_cooldown`
- `excluded_by_recent`
- `picked_event_types`（event_typeだけでOK）

> “なぜ出たか” が追えるだけで、調整が10倍楽になる。

---

## 2) コストのツマミ（最初から固定）

### 2.1 LLM呼び出し上限

訪問あたり:

- `summary` 生成: 最大 0〜N 回（できれば 0〜1）
- 会話生成: ユーザー送信1回につき 1 回

**NPC数に比例して常時LLMを呼ばない**。これが絶対。

### 2.2 event_budget の上限

`delta_sec` がどれだけ増えても “上限” を固定する（例: 最大 8 件）。

### 2.3 recent_events の表示数

UIに返す `recent_events` は最大 10 くらいまで。
それ以上は “ログ圧縮” して 1 行にまとめる（LLM要約 or テンプレ）。

---

## 3) ログ圧縮（履歴が増えた時の勝ち筋）

やりがち失敗:

- event_logs を無限に溜めて、プロンプトに混ぜて死ぬ

勝ち筋:

- `events.summary` は短く固定（1〜2文）
- 一定期間ごとに “日報/週報” に圧縮して、古い詳細ログは参照頻度を落とす

例（圧縮後）:

- “この3日、魔理沙は3回神社に来た。大きな異変はなし。”

---

## 4) キャッシュ（体感とコストに効く）

キャッシュ候補:

- `GET /api/world/state`（短TTL）
- `GET /api/world/recent`（短TTL）

ただし注意:

- “世界更新（visit）” をキャッシュしない
- キャッシュは読み取りだけ

---

## 5) 破綻の兆候（アラートにしたい）

- 同じ event_type が連続しがち（cooldownが死んでる）
- `delta_sec` が毎回巨大（last_visit が更新されてない）
- `recent_events` が常に空（イベント候補が足りない or event_budget=0固定）
- 会話が世界状態を無視（プロンプト注入が漏れてる）

チェックは `08_checklists_and_test_plan.md` と合わせて見る。

---

## 6) “霊夢らしさ” の調整ノブ（LLMに全部任せない）

コストや破綻だけじゃなく、キャラの質にもツマミがいる。

おすすめ:

- `speech_style`（テンプレ/ルール）
- “言ってはいけないこと” の短いリスト（メタ説明禁止など）
- “最近イベントに触れる数” を 0〜1 に制限

LLMに “全ての演出” を任せるとブレるので、ルールで先に枠を作る。

