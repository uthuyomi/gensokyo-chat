# 09. API 方針とディレクトリ構成

## 9-1. 主要 API
- `POST /persona/chat`
- `POST /persona/chat/stream`
- `POST /persona/intent`
- `GET /persona/characters`
- `GET /persona/characters/{id}`
- `GET /persona/session/{id}`

## 9-2. `/persona/chat` 入力方針
- `character_id`
- `session_id`
- `messages`
- `history`
- `user_profile`
- `client_context`
- `conversation_profile`

### 原則
- UI は上記データを渡すだけ
- UI は人格制御用 prompt を送らない
- UI はキャラ応答本文を加工しない

## 9-3. `/persona/chat` 出力方針
- `reply`
- `meta.interaction_type`
- `meta.safety_risk`
- `meta.character_id`
- `meta.tts_style`
- `meta.animation_hint`

## 9-4. なぜ本文以外の meta を返すのか
- 複数 UI の演出制御に使える
- 将来の音声 UI / Live2D UI / Desktop UI で使い回せる
- locale に応じた表層制御結果も返せる

## 9-5. 予定ディレクトリ構成

```text
gensokyo-persona-core/
  docs/
  persona_core/
    api/
    character_runtime/
      schemas.py
      registry.py
      loader.py
      situational_behavior.py
      locale_loader.py
    characters/
      aya/
        profile.yaml
        style.yaml
        locales/
          ja-JP.yaml
          en-US.yaml
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
      response_strategy.py
      strategy_selector.py
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

## 9-6. 既存資産をどう扱うか

### 残すもの
- `persona_controller.py`
- `phase03/dialogue_state_machine.py`
- `phase03/intent_layers.py`
- `phase03/safety_override.py`
- 既存 storage / memory / telemetry

### 縮退・移行対象
- UI側 `touhouPersona` 群
- TSの few-shot / finish block / roleplay addendum
- Python側のキャラ policy は最終的に軽量上書きへ

### 新設の重要概念
- `situational_behavior`
- `character-soul anchored generation`
- `response_strategy` は補助層
- `english control plane`
- `locale style packs`

### UI側に残すもの
- 名前
- 画像
- 背景
- 色
- placeholder

### UI側に残さないもの
- persona prompt
- speech rules
- finish block
- examples の注入ロジック
- キャラ別話法制御
