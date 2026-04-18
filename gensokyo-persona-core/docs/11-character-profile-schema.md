# 11. CharacterProfile スキーマ設計

## 11-1. 目的
- キャラクター定義を backend の正本として統一する
- UI 依存の人格 prompt を撤去し、Python 側で一元ロードできるようにする
- キャラ性最大化に必要な要素を構造化する

## 11-2. 設計方針
- 保存は YAML
- runtime では Pydantic モデルへロード
- 1キャラ = 複数ファイルでもよいが、初期実装では 1ディレクトリに集約する
- 不変の核と場面別変調を分ける
- 場面別変調は「キャラ性の弱化」ではなく「そのキャラの状況別振る舞い」として定義する
- Character Soul / Safety / Situation 制御の抽象ルールは英語ベースで記述する
- 実際の発話言語は locale ごとの style profile で定義する

## 11-3. 推奨ディレクトリ

```text
persona_core/characters/
  aya/
    profile.yaml
    style.yaml
    locales/
      ja-JP.yaml
      en-US.yaml
    response_rules.yaml
    safety.yaml
```

## 11-4. 主要モデル

### CharacterProfile
- `id`: キャラID
- `name`: 表示名
- `title`: 肩書き
- `first_person`: 一人称
- `second_person_default`: 基本の二人称
- `core_traits`: 性格軸
- `core_values`: 価値観
- `world_context`: 世界観上の立場
- `forbidden_topics`: 原則避ける話題
- `forbidden_expressions`: 禁止表現
- `default_language`: 既定言語

### CharacterStyleProfile
- `tone`
- `sentence_length`
- `tempo`
- `metaphor_style`
- `humor_style`
- `care_style`
- `conflict_style`
- `question_style`
- `lexicon_preferences`
- `lexicon_avoid`

### CharacterLocaleProfile
- `locale`
- `first_person`
- `second_person_default`
- `tone_notes`
- `speech_rules`
- `child_style_rules`
- `sos_style_rules`
- `lexical_preferences`
- `lexical_avoid`
- `formality_policy`
- `example_phrasings`

### CharacterBehaviorProfile
- `greeting_patterns`
- `comfort_patterns`
- `encouragement_patterns`
- `refusal_patterns`
- `thinking_patterns`
- `surprise_patterns`
- `apology_patterns`
- `clarification_patterns`

### CharacterSceneProfile
### CharacterSituationalBehaviorProfile
- `toward_child`
- `toward_teen`
- `toward_adult`
- `toward_distressed_user`
- `toward_sos_user`
- `toward_technical_question`
- `toward_close_user`
- `toward_first_time_user`

### CharacterSafetyProfile
- `humor_disabled_modes`
- `max_question_count_by_mode`
- `must_offer_support_in_sos`
- `must_reduce_complexity_for_child`
- `must_avoid_meta_in_critical_modes`

## 11-4a. なぜ locale profile を分けるのか
- 日本語のキャラ性を翻訳で潰さないため
- 英語ユーザーにも同じキャラの魂で返すため
- control plane を英語ベースで安定化しつつ、日本語では日本語として自然なキャラ味を出すため

## 11-5. Pydantic 例

```python
from pydantic import BaseModel, Field

class CharacterSceneModifiers(BaseModel):
    empathy_boost: float = 0.0
    humor_scale: float = 1.0
    directness_scale: float = 1.0
    explanation_scale: float = 1.0
    character_strength_scale: float = 1.0


class CharacterProfile(BaseModel):
    id: str
    name: str
    title: str = ""
    first_person: str
    second_person_default: str
    core_traits: list[str] = Field(default_factory=list)
    core_values: list[str] = Field(default_factory=list)
    forbidden_topics: list[str] = Field(default_factory=list)
    forbidden_expressions: list[str] = Field(default_factory=list)
```

## 11-6. YAML 例

```yaml
id: nitori
name: 河城にとり
title: 超妖怪弾頭
first_person: 私
second_person_default: 盟友
core_traits:
  - inventive
  - practical
  - lively
  - proud
core_values:
  - craftsmanship
  - usefulness
  - curiosity
forbidden_expressions:
  - generic_assistant_tone
```

## 11-7. なぜこのスキーマにするのか
- 語尾だけでなく、反応癖と価値観まで管理できる
- 相談/SOS/子ども向けに、そのキャラ本人の場面別振る舞いを定義できる
- UI を増やしても backend のみで人格調整できる

## 11-8. 追加したいフィールド例

```yaml
situational_behavior:
  toward_child:
    vocabulary_level: simple
    sentence_length: short
    emotional_tone: gentle_in_character
    guidance_style: reassuring
  toward_sos_user:
    emotional_tone: serious_in_character
    humor: none
    support_guidance_level: high
```

## 11-9. 実装メモ
- 初回は `profile.yaml` だけでも開始可能
- `style.yaml` と `response_rules.yaml` は段階投入でよい
- TS 側キャラ設定は変換スクリプトで移行する
