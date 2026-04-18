# gensokyo-persona-core 共通キャラクターバックエンド再設計計画

## 0. この文書の目的
- `gensokyo-persona-core` を **複数UIから共通利用できるキャラクター応答バックエンド** に再設計する
- UI側に散っている人格制御を Python 側へ集約する
- ChatGPT 系のような **入力適応型の応答制御** を導入する
- **キャラクター性最大化 / 話しやすさ / 応答速度** を同時に成立させる
- 実装前に、Notionへ移しても管理しやすい粒度で意思決定を固定する

---

## 1. 現状の課題

### 1-1. キャラクター制御が UI と Python に分散している
- UI側:
  - `touhou-talk-ui/lib/touhouPersona.ts`
  - `touhou-talk-ui/lib/touhouPersona/characters/*.ts`
  - `touhou-talk-ui/lib/touhouPersona/finish.ts`
- Python側:
  - `persona_core/controller/persona_controller.py`
  - `persona_core/phase03/*`
  - `persona_core/phase03/roleplay_character_policies/*.py`

### 1-2. UIから Python へ渡る会話文脈が不足している
- 現状 `character_id` と最後の `text` 中心
- Python側 `ChatRequest` は `messages/history/chat_mode/system/gen/tool_policy` などを受けられるが、UI側で十分活用していない

### 1-3. 今後 UI が増えると人格差分が破綻する
- Web UI ごとに prompt を持つ構成では、新 UI を作るたびに人格がズレる
- 同じキャラなのに UI ごとに振る舞いが変わる

### 1-4. 入力適応型制御が未分離
- 相談/SOS/子ども向け/通常会話の切替が独立した層になっていない
- 「何を言うか」と「どう言うか」が混在している

---

## 2. 再設計のゴール

### 2-1. 最上位ゴール
`gensokyo-persona-core` を **Character Runtime / Persona OS** として成立させる

### 2-2. 成果物として満たすべき条件
- どの UI からでも同じ API でキャラクター応答を取得できる
- キャラクター人格の正本が Python 側にのみ存在する
- ユーザー入力に応じて応答方針を動的調整できる
- キャラクター性を場面別に最適化しても芯がぶれない
- 応答速度をモード別に制御できる
- 安全対応とキャラ表現を分離して管理できる

---

## 3. なぜ Python 側へ集約するのか

### 3-1. 複数 UI に対する共通基盤が必要だから
- 今後 chat UI 以外の UI を作る予定がある
- UI ごとに人格ロジックを複製すると保守不能になる
- backend をキャラ本体にすることで、どの UI でも一貫した応答を返せる

### 3-2. キャラクターの一貫性を守るため
- UIごとの prompt 差分は人格崩壊の最大要因
- 一元管理すると、調整箇所が backend のみになる

### 3-3. 安全制御を UI 依存にしないため
- 相談/SOS/年齢配慮は UI ごとに実装すべきではない
- backend に統一安全層を置く必要がある

### 3-4. 性能最適化を backend でまとめて行うため
- キャッシュ
- ルーティング
- 会話履歴要約
- few-shot 条件投入
- 速度モード切替

これらは UI ではなく backend で握る方が合理的

---

## 4. 設計原則

### 4-1. 人格の正本は backend に置く
- UI には見た目情報だけ残す
- 人格・口調・few-shot・制約・安全上書きは backend 管理

### 4-2. 「キャラクター」と「会話方針」を分離する
- キャラクター = 不変の核
- 会話方針 = 入力によって変わる動的制御

### 4-3. 「意味生成」と「キャラ表現」を分離する
- 何を返すか
- どう言うか

を別層にする

### 4-4. プロンプト本数ではなくポリシー部品で管理する
- 巨大な prompt バリエーション集にしない
- 固定人格 + 動的ポリシー + テンプレート差分で組み立てる

### 4-5. 速度モードを正式な機能として持つ
- `fast`
- `balanced`
- `deep`

を runtime レベルで持つ

---

## 5. 新アーキテクチャの全体像

```text
UI Clients
  ├─ Web UI
  ├─ Desktop UI
  ├─ Future UI
  └─ Admin / Debug UI

        ↓

FastAPI / Persona API

        ↓

Character Runtime
  ├─ Character Registry
  ├─ User Model / Session Model
  ├─ Situation Analyzer
  ├─ Response Policy Builder
  ├─ Prompt Assembler
  ├─ LLM Generator
  ├─ Character Renderer
  ├─ Safety Layer
  └─ Memory / Telemetry
```

---

## 6. システム責務分離

### 6-1. UI の責務
- メッセージ送受信
- 表示
- 音声/アニメーション/演出
- セッション切替
- ユーザー設定入力

### 6-2. backend の責務
- キャラ定義管理
- 会話文脈解釈
- 年齢配慮
- 相談/SOS 判定
- 応答方針決定
- 応答生成
- キャラ表現レンダリング
- 安全補正
- 記憶保持
- UI向けメタ返却

---

## 7. キャラクター定義の新構造

### 7-1. 目的
キャラ定義を文章塊ではなく構造化データとして扱う

### 7-2. キャラ定義の4層

#### A. Core Persona
- 一人称
- 二人称
- 性格軸
- 価値観
- 世界観上の立場
- 禁則

#### B. Style Persona
- 語彙傾向
- 文長
- テンポ
- 比喩パターン
- 反応癖

#### C. Behavior Rules
- 褒め方
- 励まし方
- 断り方
- 相談時の入り方
- 真剣な場面でのトーン

#### D. Scene Modulation
- 通常
- 相談
- SOS
- 子ども向け
- 初対面
- 親密状態

### 7-3. 保存形式
候補:
- YAML
- JSON
- Pydantic モデル

推奨:
- 永続ファイルは YAML
- runtime では Pydantic へロード

---

## 8. 動的応答制御の考え方

### 8-1. 目的
ユーザー入力によって、応答の深さ・優しさ・キャラ濃度・速度を変える

### 8-2. 方式
入力ごとに `ResponsePolicy` を生成する

### 8-3. ResponsePolicy で持つ項目
- `mode`
  - `normal`
  - `info`
  - `consult`
  - `sos`
  - `playful`
- `target_age`
  - `child`
  - `teen`
  - `adult`
  - `unknown`
- `verbosity`
  - `short`
  - `medium`
  - `long`
- `empathy`
- `humor`
- `directness`
- `explanation_depth`
- `character_strength`
- `safety_priority`
- `response_speed_mode`
- `ask_back_probability`

### 8-4. なぜポリシー層を入れるのか
- prompt の分岐を直接増やさずに済む
- 調整理由をログ化できる
- UIをまたいでも同じ応答ロジックを再利用できる

---

## 9. Situation Analyzer を作る理由

### 9-1. 役割
入力を読んで「今どういう場面か」を判定する

### 9-2. 判定対象
- 雑談
- 情報質問
- 作業依頼
- 相談
- 感情吐露
- SOS疑い
- メタ質問
- ロールプレイ

補助判定:
- 年齢帯
- 緊張度
- 説明必要度
- 応答長さ必要度
- キャラ濃度許容量

### 9-3. 実装方針
- 初期はルール + 軽量分類器
- 将来的に `transformers` / `sentence-transformers` 補助

### 9-4. なぜ別モジュール化するのか
- 相談やSOSの誤処理は高コスト
- 応答生成ロジックに混ぜると検証しにくい

---

## 10. キャラ性最大化の方法

### 10-1. 重要な前提
キャラ性は語尾だけでは出ない

### 10-2. キャラ性が出る主な要素
- 優先順位
- 判断癖
- 共感の置き方
- 比喩の種類
- 情報の分解方法
- 距離感
- 驚き方
- 困り方
- 真剣さの出し方

### 10-3. 最大化のための実装
- 固定人格層を明確化
- キャラごとの反応辞書を持つ
- 生成後にキャラレンダリングを行う
- キャラ崩壊チェックを行う

### 10-4. 最大化と場面配慮の両立
- SOSでは軽口停止
- 子ども向けでは語彙簡略化
- ただし人格の芯は残す

---

## 11. 話しやすさを上げる方法

### 11-1. 話しやすさはキャラ性と別軸
- キャラ濃い = 話しやすい、ではない
- 話しやすさは独立して制御する

### 11-2. 話しやすさを決める要素
- 難語の少なさ
- 一文の短さ
- 適切な共感
- 圧の低さ
- 質問の数
- 情報量の整理
- 会話のテンポ

### 11-3. 実装方法
- `verbosity`
- `empathy`
- `directness`
- `ask_back_probability`
- 年齢向けテキスト変換

---

## 12. 応答速度を上げる方法

### 12-1. 速度を正式機能として扱う
速度は副次効果ではなく設計対象

### 12-2. 速度モード

#### fast
- 軽い雑談
- 小さな prompt
- 最小限の後処理

#### balanced
- 通常会話
- 標準の分析とレンダリング

#### deep
- 相談
- SOS
- 複雑質問
- 安全チェック/再評価あり

### 12-3. 具体的最適化項目
- キャラ定義の常駐キャッシュ
- 会話履歴の要約化
- few-shot の条件投入
- 分類器の軽量化
- prompt 差分生成
- postprocess の段階制御

---

## 13. Prompt 戦略

### 13-1. 固定 prompt
- キャラ核
- 安全原則
- システムの不変制約

### 13-2. 動的 prompt
- 今回の mode
- 年齢配慮
- 応答長さ
- キャラ濃度
- 相談/SOS 上書き

### 13-3. なぜ「prompt 本数主義」にしないのか
- 保守不能
- 差分の理由が消える
- キャラ調整と安全調整が衝突する

### 13-4. 目指す管理単位
- コア人格テンプレート
- モード別テンプレート
- 安全上書きテンプレート
- 出力スタイルテンプレート
- 動的ポリシー値

---

## 14. API 設計方針

### 14-1. 主要 API
- `POST /persona/chat`
- `POST /persona/chat/stream`
- `POST /persona/intent`
- `GET /persona/characters`
- `GET /persona/characters/{id}`
- `GET /persona/session/{id}`

### 14-2. `/persona/chat` の入力方針
- `character_id`
- `session_id`
- `messages`
- `history`
- `user_profile`
- `client_context`
- `conversation_profile`

### 14-3. `/persona/chat` の出力方針
- `reply`
- `meta.mode`
- `meta.safety_risk`
- `meta.character_id`
- `meta.tts_style`
- `meta.animation_hint`

### 14-4. なぜ本文以外の meta を返すのか
- 複数 UI の演出制御に使える
- 将来の音声 UI / Live2D UI / Desktop UI で使い回せる

---

## 15. 予定ディレクトリ構成

```text
gensokyo-persona-core/
  docs/
  persona_core/
    api/
    character_runtime/
      schemas.py
      registry.py
      loader.py
    characters/
      aya/
        profile.yaml
        style.yaml
        response_rules.yaml
        safety.yaml
      reimu/
      marisa/
      ...
    situation/
      analyzer.py
      sos_classifier.py
      consultation_classifier.py
      age_adapter.py
    policy/
      response_policy.py
      policy_selector.py
    rendering/
      character_renderer.py
      child_text_adapter.py
      safety_rewriter.py
      consistency_checker.py
    performance/
      prompt_cache.py
      response_mode_router.py
    controller/
      persona_controller.py
    llm/
      openai_llm_client.py
```

---

## 16. 既存資産をどう扱うか

### 16-1. 残すもの
- `persona_controller.py`
- `phase03/dialogue_state_machine.py`
- `phase03/intent_layers.py`
- `phase03/safety_override.py`
- 既存 storage / memory / telemetry

### 16-2. 縮退・移行対象
- UI側 `touhouPersona` 群
- TSの few-shot / finish block / roleplay addendum
- Python側のキャラ policy は最終的に軽量上書きへ

### 16-3. UI側に残すもの
- 名前
- 画像
- 背景
- 色
- placeholder

---

## 17. 実装フェーズ

### Phase 1: 境界整理
- UI の `/api/chat` をフル文脈転送へ変更
- backend を唯一のキャラ実行経路にする
- UI の人格 prompt 利用を止血

### Phase 2: キャラ正本移行
- TSキャラ定義を Python 用スキーマへ移行
- YAML/Pydantic ローダー作成
- Character Registry 作成

### Phase 3: 入力適応型制御導入
- Situation Analyzer 実装
- ResponsePolicy 実装
- Policy Selector 実装

### Phase 4: 表現強化
- Character Renderer 実装
- Child Text Adapter 実装
- Safety Rewriter 実装
- Consistency Checker 実装

### Phase 5: 性能最適化
- キャッシュ
- few-shot 条件注入
- 速度モード実装
- ログ/計測

### Phase 6: 評価
- キャラ別回帰テスト
- 相談/SOS テスト
- 年齢配慮テスト
- 速度計測

---

## 18. リスクと対策

### リスク1: 移行途中でキャラ性が落ちる
対策:
- 既存 TS キャラ定義を先に構造化変換
- キャラごとの回帰サンプルを残す

### リスク2: 速度が落ちる
対策:
- `fast/balanced/deep` の正式化
- every-turn 重処理を避ける
- few-shot 常時投入をやめる

### リスク3: 相談/SOS 誤判定
対策:
- 初期はルールベースで保守的に
- 分類結果を meta に残して検証

### リスク4: UI ごとの要望が増える
対策:
- UI依存ロジックではなく `client_context` と `meta` で吸収

---

## 19. 実装開始前に確定すべき事項
- キャラ定義ファイル形式は YAML でよいか
- 年齢帯は `child / teen / adult / unknown` で固定するか
- 速度モードの既定値を `balanced` にするか
- `consult` と `sos` を厳密に分けるか
- UI側に残すキャラ情報の最終範囲

---

## 20. この再設計の最終判断

### 採用方針
以下を正式採用する

1. `gensokyo-persona-core` を共通キャラクターバックエンド化する  
2. 人格の正本は Python 側に集約する  
3. ChatGPT 的な入力適応型制御は `ResponsePolicy` 中心で実装する  
4. キャラ性最大化は「構造化人格 + レンダリング + 一貫性検査」で行う  
5. 速度は `fast / balanced / deep` のモードとして扱う  

### 採用理由
- 複数 UI 展開に耐える
- キャラの一貫性を守れる
- 話しやすさを入力適応で上げられる
- 安全制御を中央集約できる
- 将来の拡張と保守が圧倒的に楽になる

---

## 21. 次アクション
- この文書を基準に実装リファクタリングを開始する
- 次段階では以下を個別ドキュメント化する
  - API 仕様
  - CharacterProfile スキーマ
  - ResponsePolicy スキーマ
  - 移行タスク一覧
  - テスト計画



## ??: ?????????
- ???????????? runtime ????????????????
- ???? **English control plane + locale surface** ???????????????????????????????????
- Character Soul / Safety / Situation / Strategy ??????????????????
- ???? `ja-JP` ?????????????`en-US` ???????????? locale profile ????????
- ???????????????????????????????????????????????
