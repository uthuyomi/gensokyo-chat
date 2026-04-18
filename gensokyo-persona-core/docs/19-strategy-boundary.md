# 19. CharacterSituationalBehavior と ResponseStrategy の責務境界

## 19-1. 目的
- 実装で `behavior` と `strategy` が混線しないようにする

## 19-2. CharacterSituationalBehavior の責務
- キャラ固有
- 長期不変
- 「そのキャラはこの状況でどう振る舞うか」

### 例
- 霊夢が子どもにどう話すか
- にとりがSOS相手にどう寄り添うか
- 文が技術質問にどう乗るか

## 19-3. ResponseStrategy の責務
- ターン固有
- 場面の会話運びを調整
- キャラ本人性は変えない

### 例
- 今回は short で返す
- 今回は質問は1つまで
- 今回は fast で返す

## 19-4. CharacterSituationalBehavior に入れるべきもの
- emotional_tone
- child対応の仕方
- SOS時の態度
- 技術説明の口調
- 距離感
- 比喩傾向

## 19-5. ResponseStrategy に入れるべきもの
- verbosity
- max_questions
- response_speed_mode
- should_use_examples
- should_offer_choices
- should_request_clarification

## 19-6. 入れてはいけないもの

### Behavior に入れてはいけない
- fast/balanced/deep
- 今回だけ短く返す判断

### Strategy に入れてはいけない
- 一人称
- 二人称
- キャラ固有の励まし方そのもの
- キャラ固有の子ども対応そのもの

## 19-7. 判断ルール
- 「毎ターン変わる」なら Strategy
- 「そのキャラなら基本そうする」なら Behavior



## 19-8. locale ??????
- `CharacterSituationalBehavior` ? locale ????????????
- `ResponseStrategy` ? locale ??????????????
- ??? / ??? / ?? / ???? / ??????? `CharacterLocaleProfile` ???????
- ??? locale ????????? Strategy ???? **Locale Surface** ????
