# 22. API Schema Contract

## 22-1. 目的
- 実装用の request / response schema を確定する

## 22-2. ChatRequest vNext

```python
class ChatRequest(BaseModel):
    user_id: str | None = None
    session_id: str
    message: str = ""
    messages: list[dict] | None = None
    history: list[dict] | None = None

    character_id: str
    chat_mode: str | None = None

    user_profile: dict | None = None
    client_context: dict | None = None
    conversation_profile: dict | None = None

    system: str | None = None
    gen: dict | None = None
    tool_policy: dict | None = None
    attachments: list[dict] | None = None
```

## 22-2a. クライアント契約
- クライアントは `ChatRequest` のデータを埋めるだけ
- クライアントは人格 prompt を追加してはならない
- クライアントは返答本文の口調変換をしてはならない
- クライアントは `character_id` を選び、文脈を正しく渡す責任を持つ

## 22-3. ChatResponse vNext

```python
class ChatResponse(BaseModel):
    reply: str
    meta: dict
```

## 22-4. meta の必須項目
- `character_id`
- `interaction_type`
- `safety_risk`
- `response_speed_mode`
- `strategy_snapshot`
- `situation_snapshot`

## 22-5. meta の推奨項目
- `tts_style`
- `animation_hint`
- `debug.reasons`
- `latency_ms`

## 22-6. Streaming contract

### event: `reply.delta`
- `text`

### event: `meta.partial`
- `character_id`
- `interaction_type`

### event: `meta.final`
- full meta

## 22-7. backward compatibility
- `message` のみでも受けられる
- `messages` があるなら最新 user を優先
- `history` 未指定なら `messages` から導出

## 22-8. 実装時に固定する enum
- `interaction_type`
- `safety_risk`
- `target_age`
- `relationship_stage`
- `response_speed_mode`
- `verbosity`


## 22-2b. locale contract
- `client_context.locale` ?????????????????????
- backend ? `resolved_locale` ?????response meta ????
- backend ? locale ??? style pack ????? `locale_style_snapshot` ???????
- ??????? locale ????????????????locale ???????? backend ???????

## 22-4a. meta ? locale ?????
- `resolved_locale`
- `locale_style_snapshot`

## 22-6a. Streaming ?? locale meta
### event: `meta.partial`
- `resolved_locale` ??????

### event: `meta.final`
- `resolved_locale`
- `locale_style_snapshot`
- full meta
