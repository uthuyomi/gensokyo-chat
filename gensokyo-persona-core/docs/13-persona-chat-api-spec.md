# 13. `/persona/chat` API 仕様

## 13-1. 目的
- どの UI からでも同じ会話 API を利用できるようにする
- backend を唯一のキャラクター応答経路にする

## 13-2. エンドポイント
- `POST /persona/chat`
- `POST /persona/chat/stream`

## 13-3. Request 例

```json
{
  "session_id": "sess_001",
  "user_id": "user_001",
  "character_id": "aya",
  "messages": [
    {"role": "user", "content": "つらい"}
  ],
  "history": [
    {"role": "assistant", "content": "どうしたの？"}
  ],
  "chat_mode": "partner",
  "user_profile": {
    "age_group": "teen",
    "relationship_stage": "familiar"
  },
  "client_context": {
    "ui_type": "web",
    "surface": "chat",
    "locale": "ja-JP"
  },
  "conversation_profile": {
    "response_style": "balanced"
  },
  "tool_policy": {
    "allow_web_search": false
  }
}
```

## 13-4. Request フィールド方針

### 必須
- `session_id`
- `character_id`
- `message` または `messages`

### 推奨
- `history`
- `user_profile`
- `client_context`
- `conversation_profile`

### 補助
- `chat_mode`
- `tool_policy`
- `gen`
- `attachments`

## 13-4a. UI 実装原則
- UI は request を組み立てるが、人格 prompt は埋め込まない
- UI は `character_id` を選び、入力と履歴をそのまま送る
- 人格制御は backend のみが行う
- UI は response の `reply` を表示し、必要なら `meta` を演出へ使うだけ

## 13-5. Response 例

```json
{
  "reply": "……それはかなりしんどそうだね。少しだけ整理しようか。",
  "meta": {
    "character_id": "aya",
    "interaction_type": "distressed_support",
    "safety_risk": "medium",
    "response_speed_mode": "balanced",
    "tts_style": "calm",
    "animation_hint": "gentle_nod",
    "strategy": {
      "verbosity": "short",
      "empathy": 0.92
    }
  }
}
```

## 13-6. meta に入れるべきもの
- `character_id`
- `interaction_type`
- `safety_risk`
- `response_speed_mode`
- `tts_style`
- `animation_hint`
- `strategy_snapshot`
- `classifier_result`
- `resolved_locale`
- `locale_style_snapshot`

## 13-7. エラーポリシー
- 不正 request は 400
- 認証失敗は 401 / 403
- 内部処理失敗は 500
- safety critical failure は fallback safe reply を返す

## 13-8. Streaming 方針
- `reply.delta`
- `meta.partial`
- `meta.final`

のようなイベント分離を推奨

## 13-9. なぜこの仕様にするのか
- 複数 UI で共通化しやすい
- UI ごとの演出に必要な meta を返せる
- backend 主導の動的制御を維持できる
- 「そのキャラがこの状況でどう振る舞ったか」を meta に残せる
- UI を薄いクライアントとして保てる
