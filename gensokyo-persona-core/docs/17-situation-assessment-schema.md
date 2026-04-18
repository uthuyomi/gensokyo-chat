# 17. SituationAssessment スキーマ定義

## 17-1. 目的
- 入力を実装可能な粒度で構造化判定する
- `CharacterSituationalBehavior` と `ResponseStrategy` の入力を統一する

## 17-2. 主要モデル

```python
from typing import Literal
from pydantic import BaseModel, Field

class SituationAssessment(BaseModel):
    interaction_type: Literal[
        "normal",
        "playful",
        "info",
        "technical",
        "distressed_support",
        "sos_support",
        "meta",
        "roleplay",
        "unclear",
    ] = "normal"

    safety_risk: Literal["none", "low", "medium", "high"] = "none"
    target_age: Literal["child", "teen", "adult", "unknown"] = "unknown"
    relationship_stage: Literal["first_time", "distant", "familiar", "close", "unknown"] = "unknown"

    distress_level: float = 0.0
    urgency_level: float = 0.0
    technicality_level: float = 0.0
    needs_simple_vocabulary: bool = False
    should_offer_support_guidance: bool = False
    should_reduce_question_count: bool = False

    matched_labels: list[str] = Field(default_factory=list)
    classifier_confidence: float = 0.0
    reasons: list[str] = Field(default_factory=list)
```

## 17-3. interaction_type の定義
- `normal`: 一般会話
- `playful`: 軽い雑談 / あいさつ / ノリの良い会話
- `info`: 情報説明
- `technical`: 技術説明や設計相談
- `distressed_support`: 落ち込み / 悩み / 相談
- `sos_support`: 自傷・消失願望・緊急性の高い相談
- `meta`: システムや設定に関する話
- `roleplay`: 明示的ロールプレイ
- `unclear`: 判定保留

## 17-4. 優先順位
高い順に優先する

1. `sos_support`
2. `distressed_support`
3. `technical`
4. `info`
5. `roleplay`
6. `playful`
7. `meta`
8. `normal`
9. `unclear`

## 17-5. safety_risk の定義
- `none`: 通常
- `low`: 軽いセンシティブ
- `medium`: 明確な不安 / 依存 / 危険兆候
- `high`: 自傷・自殺示唆・緊急危険

## 17-6. target_age の推定ルール
- 明示入力があれば最優先
- UIプロフィールがあれば次点
- 文体推定は補助のみ
- 不明なら `unknown`

## 17-7. 判定の基本手順
1. ルールベース判定
2. 必要時のみ軽量分類器
3. high-risk 候補なら保守的に高めを採用
4. `reasons` に根拠を残す

## 17-8. 実装ルール
- `sos_support` が立ったら `should_offer_support_guidance = True`
- `target_age == child` なら `needs_simple_vocabulary = True`
- `distress_level >= 0.7` なら `should_reduce_question_count = True`

## 17-9. 返り値サンプル

```json
{
  "interaction_type": "sos_support",
  "safety_risk": "high",
  "target_age": "teen",
  "relationship_stage": "familiar",
  "distress_level": 0.98,
  "urgency_level": 0.95,
  "technicality_level": 0.0,
  "needs_simple_vocabulary": false,
  "should_offer_support_guidance": true,
  "should_reduce_question_count": true,
  "matched_labels": ["self_harm", "distress"],
  "classifier_confidence": 0.93,
  "reasons": ["contains self-harm phrase", "high urgency wording"]
}
```



## 17-10. locale ????
- `SituationAssessment` ???????????
- locale ??????????????????????????????? locale ???????
- ??? `ja-JP` / `en-US` ??? SituationAssessment ??????????????? locale style ??????????
