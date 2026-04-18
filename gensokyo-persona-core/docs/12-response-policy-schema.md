# 12. ResponseStrategy スキーマ設計

## 12-1. 目的
- ChatGPT系のような入力適応型応答制御を backend で行う
- キャラ性を固定したまま、会話運び / 話しやすさ / 速度を別軸で制御する
- prompt の巨大分岐を避ける

## 12-2. 設計原則
- `CharacterProfile` は不変
- `CharacterSituationalBehavior` が主役
- `ResponseStrategy` は毎ターン可変の補助層
- 生成前に policy を決め、生成後に renderer で補正する
- `ResponseStrategy` は言語中立の control plane として扱う
- locale ごとの話し方は `CharacterLocaleProfile` に逃がす

## 12-3. 推奨モデル

### 必須項目
- `interaction_type`
- `target_age`
- `verbosity`
- `empathy`
- `humor`
- `directness`
- `explanation_depth`
- `safety_priority`
- `response_speed_mode`
- `ask_back_probability`

### 追加推奨項目
- `allow_roleplay_narration`
- `max_sentences`
- `max_questions`
- `should_offer_choices`
- `should_simplify_vocabulary`
- `should_use_examples`
- `should_request_clarification`

## 12-4. Pydantic 例

```python
from typing import Literal
from pydantic import BaseModel

class ResponseStrategy(BaseModel):
    interaction_type: Literal["normal", "info", "distressed_support", "sos_support", "playful"] = "normal"
    target_age: Literal["child", "teen", "adult", "unknown"] = "unknown"
    verbosity: Literal["short", "medium", "long"] = "medium"
    empathy: float = 0.5
    humor: float = 0.3
    directness: float = 0.5
    explanation_depth: float = 0.5
    safety_priority: float = 0.5
    response_speed_mode: Literal["fast", "balanced", "deep"] = "balanced"
    ask_back_probability: float = 0.3
    max_sentences: int = 5
    max_questions: int = 1
    should_simplify_vocabulary: bool = False
```

## 12-5. strategy の決まり方

### 入力
- user message
- history summary
- character id
- user profile
- situation analyzer result
- character situational behavior
- locale

### 出力
- そのターン専用の応答方針

## 12-6. strategy 決定例

### 雑談
```json
{
  "interaction_type": "playful",
  "verbosity": "short",
  "empathy": 0.5,
  "humor": 0.7,
  "response_speed_mode": "fast"
}
```

### 技術質問
```json
{
  "interaction_type": "info",
  "verbosity": "medium",
  "directness": 0.8,
  "explanation_depth": 0.9,
  "response_speed_mode": "balanced"
}
```

### SOS疑い
```json
{
  "interaction_type": "sos_support",
  "verbosity": "short",
  "empathy": 0.98,
  "humor": 0.0,
  "safety_priority": 1.0,
  "response_speed_mode": "deep"
}
```

## 12-7. なぜこのスキーマにするのか
- キャラ性を固定したまま話しやすさを調整できる
- 速度モードを独立して制御できる
- LLM prompt を軽量に保てる
