# 18. CharacterSituationalBehavior 合成ルール

## 18-1. 目的
- 複数状況が同時に成立したとき、どのキャラ挙動をどう重ねるかを固定する
- 実装時の曖昧さをなくす

## 18-2. 入力
- `CharacterProfile.core`
- `CharacterStyleProfile`
- `CharacterBehaviorProfile`
- `CharacterSituationalBehaviorProfile.*`
- `SituationAssessment`

## 18-3. 合成対象候補
- `toward_child`
- `toward_teen`
- `toward_adult`
- `toward_distressed_user`
- `toward_sos_user`
- `toward_technical_question`
- `toward_close_user`
- `toward_first_time_user`

## 18-4. 適用順序
順番に上書き / 合成する

1. `core identity`
2. `base style`
3. 年齢対象 (`toward_child` / `toward_teen` / `toward_adult`)
4. 関係性 (`toward_first_time_user` / `toward_close_user`)
5. 会話内容 (`toward_technical_question`)
6. 感情状況 (`toward_distressed_user`)
7. 緊急状況 (`toward_sos_user`)
8. safety constraints

## 18-5. 上書き原則

### 文字列項目
- 後勝ち
- ただし空文字は無視

### 数値項目
- 原則 clamp 付き加算または min/max
- 例:
  - `empathy_boost`: 加算
  - `humor_scale`: 乗算
  - `question_limit`: min

### bool 項目
- safety 系は `True` 優先
- 表現許可系は `False` 優先

### リスト項目
- 重複除去して連結
- 優先順は後段追加を前へ寄せない

## 18-6. 競合ルール

### child と sos が同時に立つ場合
- `toward_sos_user` を優先
- ただし `toward_child` の簡単語彙制約は保持

### technical と distressed が同時に立つ場合
- 技術説明より emotional care を優先
- ただし technical 用の構造化説明の一部は残してよい

### close と first_time が同時に立つ場合
- `first_time` を優先

## 18-7. 合成結果モデル

```python
class ResolvedSituationalBehavior(BaseModel):
    vocabulary_level: str = "normal"
    sentence_length: str = "medium"
    emotional_tone: str = "in_character_default"
    guidance_style: str = "normal"
    question_limit: int = 1
    humor_allowed: bool = True
    support_guidance_level: float = 0.0
    explanation_style: str = "normal"
    active_traits: list[str] = []
```

## 18-8. 実装メモ
- `BehaviorResolver` を独立モジュール化する
- merge の途中経過を `debug/meta` に残す
- テストケースで child+sos, teen+distress, close+technical を必須化する

