# 07. 動的 Situation 判定と ResponseStrategy

## 7-1. 目的
ユーザー入力に応じて、**そのキャラがその状況でどう振る舞うか** を決める

## 7-2. 基本方式
- 入力ごとに Situation を判定する
- Situation と CharacterProfile から、そのキャラ固有の `situational_behavior` を選ぶ
- 補助的に `ResponseStrategy` を生成する
- 生成前に `client_context.locale` を見て locale style pack を選ぶ

## 7-3. ResponseStrategy で持つ項目
- `interaction_type`
  - `normal`
  - `info`
  - `distressed_support`
  - `sos_support`
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
- `safety_priority`
- `response_speed_mode`
- `ask_back_probability`

## 7-4. なぜ strategy 層を入れるのか
- prompt 分岐を直接増やさずに済む
- 調整理由をログ化できる
- UIをまたいでも同じ応答ロジックを再利用できる
- ただしこの層はキャラ性を下げるものではなく、キャラ本人の会話運びを補助する層

## 7-5. Situation Analyzer の役割
入力を読んで「今どういう場面か」を判定する

## 7-6. 判定対象
- 雑談
- 情報質問
- 作業依頼
- 相談
- 感情吐露
- SOS疑い
- メタ質問
- ロールプレイ

### 補助判定
- 年齢帯
- 緊張度
- 説明必要度
- 応答長さ必要度
- キャラ濃度許容量

## 7-7. 実装方針
- 初期はルール + 軽量分類器
- 将来的に `transformers` / `sentence-transformers` 補助

## 7-8. 最重要ルール
- `ResponseStrategy` は人格を変えない
- 子ども向けでも「そのキャラの子ども対応」を選ぶ
- SOSでも「そのキャラのSOS時対応」を選ぶ
- locale 切替でも人格を変えない
- 英語 / 日本語の違いは振る舞いの芯ではなく、表層言語の違いとして扱う
