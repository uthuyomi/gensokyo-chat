# 20. Prompt Assembler 仕様

## 20-1. 目的
- LLM に渡す構成を固定し、品質と速度を両立する

## 20-2. 重要原則
- 最初から **そのキャラ本人** として生成する
- 下書き→キャラ化の二段生成を常用しない
- prompt は固定ブロック + 差分ブロックで構成する

## 20-3. ブロック順

1. System Root Rules
2. Character Soul
3. Resolved Situational Behavior
4. Safety Constraints
5. Response Strategy
6. Session Context Summary
7. Recent History
8. Current User Message

## 20-4. 各ブロックの役割

### 1. System Root Rules
- runtime 全体の不変制約
- 応答言語や安全の土台

### 2. Character Soul
- そのキャラ本人であること
- 一人称 / 二人称 / 価値観 / 話法

### 3. Resolved Situational Behavior
- 子ども相手ならどう話すか
- SOS相手ならどう助けるか
- 技術質問にどう返すか

### 4. Safety Constraints
- 絶対禁止
- 必須支援導線

### 5. Response Strategy
- 今回は短め
- 今回は質問1つまで
- 今回は fast

### 6. Session Context Summary
- 長期文脈要約

### 7. Recent History
- 直近の必要履歴だけ

### 8. Current User Message
- 最新入力

## 20-5. few-shot の投入条件
- 新規キャラ
- 回帰テストで崩れやすいキャラ
- 特殊シーン
- debug モード

通常時は入れない

## 20-6. 実装 API 形

```python
class PromptAssembler:
    def assemble(
        self,
        *,
        character_soul,
        resolved_behavior,
        safety_constraints,
        response_strategy,
        session_summary,
        recent_history,
        user_message,
    ) -> list[dict]:
        ...
```

## 20-7. 性能ルール
- history は件数制限する
- summary を優先し、全文履歴を避ける
- few-shot は基本無効



## 20-8. ??? prompt ??
Prompt Assembler ?????????????????

### A. English Control Plane
- System Root Rules
- Character Soul
- Resolved Situational Behavior
- Safety Constraints
- Response Strategy

????????????????????????????????????????

### B. Locale Style Block
- locale ?????? / ???
- ?? / ??? / ????
- ????? wording
- SOS wording
- ?? / ???? / ?????

??? `ja-JP` / `en-US` ????????????

## 20-9. ?? block ?
1. System Root Rules (EN)
2. Base Character Prompt / Character Soul (EN)
3. Resolved Situational Behavior (EN)
4. Safety Constraints (EN)
5. Response Strategy (EN)
6. Locale Style Block (target locale)
7. Session Context Summary
8. Recent History
9. Current User Message

## 20-10. ????
- locale style block ???????????????????????
- locale ????? Character Soul ??????
- ????????? `ja-JP` style profile ???????????????
