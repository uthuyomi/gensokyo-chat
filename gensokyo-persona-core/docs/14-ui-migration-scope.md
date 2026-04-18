# 14. UI から剥がす対象 / 残す対象

## 14-1. 目的
- `touhou-talk-ui` を表示クライアント化する
- 人格ロジックを backend 側へ完全移行する

## 14-1a. 最重要原則
- UI では人格制御を一切しない
- UI は「今どのキャラで返すか」を backend に渡すだけ
- UI は会話文脈を backend に渡すだけ
- 人格・話法・安全・場面適応は Python 側で完結させる

## 14-2. UI から剥がす対象
- キャラ persona prompt
- speech rules
- constraints
- finish block
- roleplay addendum
- few-shot examples
- generation params
- キャラ別応答制御ロジック
- 汎用相談モード / 子ども向けモードのような人格側分岐

### 現状の代表対象
- `lib/touhouPersona.ts`
- `lib/touhouPersona/characters/*.ts`
- `lib/touhouPersona/finish.ts`

## 14-3. UI に残す対象
- キャラ名
- 肩書き
- 画像
- 背景
- 色
- placeholder
- アニメーション用見た目設定
- `character_id` の選択ロジック
- 入力欄 / セッション / 表示演出

## 14-4. UI が backend へ送るべきもの
- `character_id`
- `messages`
- `history`
- `session_id`
- `user_profile`
- `client_context`
- `conversation_profile`

### 送ってはいけないもの
- キャラ人格 prompt
- キャラ別 few-shot
- UI側で加工したキャラ口調指示
- UI独自の相談 / SOS 応答テンプレ

## 14-5. UI 側変更タスク
- `app/api/chat/route.ts` をフル文脈転送へ変更
- prompt 組み立てロジックを停止
- character 選択UIは `GET /persona/characters` に寄せる準備
- 返答後の人格後加工を禁止

## 14-6. なぜ分離するのか
- 新 UI を作るたびに人格ロジックを複製したくない
- UI差分でキャラ性が崩れるのを防ぐ
- 「そのキャラ本人の場面別応答」を backend が保証するため
