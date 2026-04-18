# 02. 現状の課題

## 2-1. キャラクター制御が UI と Python に分散している

### UI側
- `touhou-talk-ui/lib/touhouPersona.ts`
- `touhou-talk-ui/lib/touhouPersona/characters/*.ts`
- `touhou-talk-ui/lib/touhouPersona/finish.ts`

### Python側
- `persona_core/controller/persona_controller.py`
- `persona_core/phase03/*`
- `persona_core/phase03/roleplay_character_policies/*.py`

## 2-2. UIから Python へ渡る会話文脈が不足している
- 現状は `character_id` と最後の `text` 中心
- Python側 `ChatRequest` は `messages/history/chat_mode/system/gen/tool_policy` を受けられる
- しかし UI 側で十分転送していない

## 2-3. 今後 UI が増えると人格差分が破綻する
- UIごとに prompt を持つ構成では、新 UI を作るたびに人格がズレる
- 同じキャラなのに UI ごとに振る舞いが変わる

## 2-4. 入力適応型制御が未分離
- 相談 / SOS / 子ども向け / 通常会話の切替が独立した層になっていない
- 「何を言うか」と「どう言うか」が混在している

