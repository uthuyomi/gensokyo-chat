# 05. 新アーキテクチャ

## 5-1. 全体像

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
  ├─ Locale Style Registry
  ├─ User Model / Session Model
  ├─ Situation Analyzer
  ├─ Character Situational Behavior Selector
  ├─ Response Strategy Builder
  ├─ Prompt Assembler
  ├─ LLM Generator
  ├─ Character Renderer
  ├─ Safety Layer
  └─ Memory / Telemetry
```

## 5-2. UI の責務
- メッセージ送受信
- 表示
- 音声 / アニメーション / 演出
- セッション切替
- ユーザー設定入力
- `character_id` と会話文脈の転送

### UI がやってはいけないこと
- キャラ prompt 組み立て
- キャラ口調の後加工
- few-shot 注入
- 相談 / SOS / 子ども向け分岐
- キャラ別 generation 制御
- safety 応答の本文組み立て

## 5-3. backend の責務
- キャラ定義管理
- locale ごとの style 定義管理
- 会話文脈解釈
- 年齢配慮
- 相談 / SOS 判定
- そのキャラの場面別振る舞い選択
- 応答戦略決定
- そのキャラ本人として応答生成
- キャラ表現レンダリング
- 安全補正
- 記憶保持
- UI向けメタ返却
- 人格制御の全責務

## 5-4. 多言語化の中核設計

### Control Plane
- 英語ベース
- Character Soul の抽象定義
- Situational Behavior
- Safety Constraints
- Response Strategy
- Session Summary

### Locale Style Pack
- `ja-JP`, `en-US` など locale ごと
- 一人称 / 二人称
- 語尾 / 距離感
- 語彙の傾向
- 子ども向けの言い換え
- SOS時のその言語として自然な支え方

### 原則
- 「同じキャラの魂」を保ったまま各言語に再表現する
- 日本語ユーザーにも英語ユーザーにも同じ backend で対応する
