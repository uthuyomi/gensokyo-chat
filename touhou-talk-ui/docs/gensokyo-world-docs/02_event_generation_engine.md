# 02 Event Generation Engine（AI幻想郷ワールド）

目的:

- ユーザーがいない間も「世界が動いていた」と感じさせる
- サーバー負荷・LLMコストを最小化する

中核方針:

- **リアルタイム常時シミュレーションは行わない**
- 代わりに **Time Skip Simulation**（再訪時にまとめて生成）を採用する

関連:

- `01_supabase_schema_ai_gensokyo.md`（events保存）
- `03_npc_behavior_planner.md`（NPC状態更新）
- `04_scalability_and_simulation_architecture.md`（Active/Passive）

---

## 仕組み（Time Skip）

ユーザーが戻ってきた時に、前回からの差分（delta）を計算してイベントをまとめて作る。

```
ユーザー離席中 → 何も計算しない
再訪時       → まとめてイベント生成・状態更新
```

これにより「大量NPCでも動く」設計になる。

---

## 基本フロー（再訪時）

1. `last_visit` を取得（user_state）
2. `now` を取得
3. `delta = now - last_visit` を計算
4. `delta` に応じて生成するイベント数を決定
5. 条件に合うイベント候補を列挙
6. recent_event_filter / cooldown を考慮して抽選
7. 世界状態・NPC状態を更新
8. events に保存（必要なら summary を生成）

---

## イベント数の決め方（例）

最初は単純でよい。

- `event_interval = 2h`
- `event_count = floor(delta / event_interval)`

ただし単調になりやすいので、早めに「場所密度」を入れると良い。

- 神社: 密度高め（人が来る）
- 森: 密度低め（静か）

---

## イベント定義（最小）

イベントは「発生条件」と「連発防止」が重要。

例:

```json
{
  "id": "marisa_visit",
  "location_id": "hakurei_shrine",
  "probability": 0.3,
  "participants": ["reimu", "marisa"],
  "cooldown_hours": 12,
  "constraints": {
    "time_of_day": ["day", "evening"],
    "weather_not": ["storm"]
  }
}
```

---

## 抽選（recent_event_filter / cooldown）

雑にランダム抽選すると「同じことが連発」して一気に世界が壊れる。
最初から以下を入れる。

- **recent_event_filter**: 直近N件に同一event_typeがあるなら重みを落とす/除外
- **cooldown**: event_typeごとにクールダウン時間を持つ

---

## NPC状態更新（イベントの副作用）

イベントは **状態を更新するためのトリガー** として扱う。

例:

- `marisa_visit`
  - `marisa.location = hakurei_shrine`
  - `reimu.emotion = neutral`（または微変化）

---

## 会話ログ/要約（LLMの役割）

LLMは次に限定する（コスト爆発を避けるため）:

- 会話を“生成”する（短い）
- 出来事を“要約”する（短い）

例プロンプト（要約）:

> 霊夢と魔理沙が博麗神社で雑談した。短く要約してください。

---

## ユーザー再訪時の会話への反映

生成した `recent_events` を、会話プロンプトに混ぜる。

例:

- recent: 「魔理沙が神社に来ていた」
- 霊夢: 「さっき魔理沙が来てたのよ」

---

## イベント例（幻想郷）

- `marisa_visit`
- `reimu_cleaning`
- `cirno_playing`
- `rain_start`
- `yukari_gap`
- `night_youkais`

---

## イベント連鎖（任意）

イベントを連鎖させると“小さな物語”が生まれる。

例:

```
marisa_visit
  ↓
argument
  ↓
reimu_annoyed
```

---

## 最重要ルール（コスト）

- NPCイベントをリアルタイム生成しない
- LLMを「会話/要約」に限定する

---

## 最終目的

Time Skipイベント生成により、

- 世界が継続している
- NPCが生活している
- 小さなストーリーが生まれる

幻想郷AIワールドを実現する。
