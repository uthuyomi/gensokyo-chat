# 00 Stack & Phased Architecture（AI幻想郷ワールド）

このドキュメントは「今の `touhou-talk-ui` の延長として、AI幻想郷ワールドをどう積み上げるか」を人間が読める形でまとめたもの。

前提:

- 現状は **約20キャラ** 規模を想定
- UIは `touhou-talk-ui` の「左=AI/中央=VRM/右=ユーザー」を基本維持
- 重要原則は **Time Skip Simulation（リアルタイム常時進行しない）**

---

## 結論（20キャラの最短構成）

20キャラなら、最初に入れるべき“世界エンジン”はこれだけで成立する:

- **World State Engine（ルールベース）**
  - ワールド状態: 天候/時間帯/季節/異変など
  - ロケーショングラフ: 場所・サブロケ・隣接関係
  - キャラ状態: 現在地/行動/感情/エネルギーなど
  - 関係値: trust / caution / familiarity など
- **Event Generation（Time Skip）**
  - 再訪時に「前回から今までの差分」をまとめて生成
  - recent_event_filter / cooldown / 場所密度で連発・破綻を防止
- **LLMは“会話と要約”に限定**
  - 行動決定や世界更新は極力ルールで
  - LLMは: 会話生成 / 直近イベント要約 / 物語化（任意）

この構成だと、重いライブラリ（Mesa / Neo4j / Celery / ベクタDBなど）無しで「世界が動いてる感」を出せる。

---

## 構成の層（ざっくり）

```
UI (Next.js / VRM / TTS)
  ↓
Chat API（プロンプト組み立て）
  ↓
World State Engine（DB + ルール）
  ↓
Event Engine（Time Skip）
  ↓
LLM（会話/要約のみ）
```

UIが欲しい情報は基本これだけ:

- 今の場所（layer / loc）
- 直近の出来事（recent events）
- 今の世界状態（天気/時間帯）

---

## フェーズ設計（S/M/Lの目安）

### Phase S（チャット拡張）

- NPC: 1〜10
- 場所: 5〜20ノード
- 目的: 「戻ってきたら“さっき◯◯があった”が言える」
- 追加コンポーネント:
  - 最小DB（world_state, events, relationships, characters, user_state）
  - Time Skipイベント生成（少数イベントのみ）

### Phase M（生活圏が回る: 20〜80 NPC）

- NPC: 20〜80（= 現状はここ入口）
- 場所: 50〜200ノード（サブロケ追加）
- 目的: 「場所ごとに空気が違う」「関係が蓄積する」
- 追加コンポーネント:
  - Active/Passive（近いキャラだけ詳細）
  - イベント密度（場所ごとの頻度）
  - cooldown / recent_event_filter の実装
  - ログ圧縮（要約）とTTL

### Phase L（運用レベル）

- NPC: 200〜1000（同時に詳細なのは一部）
- 目的: インスタンス分割や運用まで含めて“サービス”にする
- 追加コンポーネント:
  - ワールドの水平分割（world_instance）
  - バッチ/キュー（Celery/RQ + Redis）
  - 通知/リアルタイム（WebSocket）

---

## 主要ライブラリの「使いどころ」整理

この構想で挙げられていたライブラリ群は方向性として正しい。が、導入順を間違えると地獄を見る。

### ① マルチエージェントAI（LangGraph / AutoGen / CrewAI）

**導入タイミング: Phase M以降の“必要が出たら”**

- 20キャラなら「会話・要約」をLLM単発で回すだけで体験は出る
- “長期計画”“複数NPCの同時対話”をやりたいなら LangGraph が扱いやすい
- AutoGen/CrewAIは会話協調に強いが、世界状態エンジンが固まってから

### ② シミュレーション（SimPy / Mesa）

**導入タイミング: Phase M後半〜L**

- Time Skip + ルールだけで十分回る限り、入れない方が軽い
- Mesaは研究・可視化・大量エージェントの検証には強い

### ③ 行動AI（py_trees / transitions）

**導入タイミング: 早めに入れてよい（Phase SでもOK）**

- 世界の破綻を防ぐのは「行動の決定規則」なので、FSM/BTは相性が良い
- ルールが増えても“読める”形で保てる

### ④ 記憶（Chroma / Weaviate / Milvus）

**導入タイミング: “長文を検索したくなったら”**

- 最初はPostgresでイベントログ＋関係＋要約で十分
- ベクタDBは「会話ログ全文から検索」「長期記憶検索」の段階で導入

### ⑤ グラフ（Neo4j / NetworkX）

**導入タイミング: まずはRDBでOK**

- 20キャラなら relationships テーブル + locationグラフ（JSON/テーブル）で足りる
- 複雑な多段関係クエリが増えたらNeo4j検討

### ⑥ スケジューラ（Celery / RQ）

**導入タイミング: “常時進行”が必要になったら**

- Time Skip設計では「訪問時にまとめて生成」で十分
- 常時生成にすると運用が一気に重くなる

### ⑦ リアルタイム通信（WebSocket）

**導入タイミング: UI演出を増やすとき**

- チャットだけなら必須ではない
- 「幻想郷が勝手に動くログが流れる」「同じ世界を複数人で見る」等で必要

---

## まず人間が用意すべきデータ（最低限）

- ロケーショングラフ（場所/サブロケ/隣接/タグ/密度）
- 主要キャラのホーム＋スケジュール（時間帯ごとの基本行動）
- 関係値の初期値（全組み合わせは不要、主要ペアだけ）
- イベント定義（20〜50個から開始）
  - 条件（場所/時間/天気/参加キャラ）
  - クールダウン
  - 重要度（会話に出すか）

---

## 実装メモ（touhou-talk-ui延長）

- `layer` / `loc` はすでにURLにあるので、そのまま世界コンテキストにできる
- チャット応答のプロンプトに `world_state` と `recent_events` を混ぜるだけで体験が激変する

関連:

- `ai-gensokyo-world-design.md`（全体構想）
- `01_supabase_schema_ai_gensokyo.md`（DB）
- `02_event_generation_engine.md`（Time Skip）
- `03_npc_behavior_planner.md`（行動決定）
- `04_scalability_and_simulation_architecture.md`（スケール）

