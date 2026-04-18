# 15. 実装タスク一覧

## 15-1. Phase 1: 境界整理
- [ ] `touhou-talk-ui/app/api/chat/route.ts` をフル文脈転送へ変更
- [ ] backend 側 `ChatRequest` に `user_profile/client_context/conversation_profile` を追加
- [ ] UI 側 prompt 利用箇所を棚卸し

## 15-2. Phase 2: キャラ正本化
- [ ] `persona_core/character_runtime/schemas.py` 作成
- [ ] `persona_core/character_runtime/loader.py` 作成
- [ ] `persona_core/character_runtime/registry.py` 作成
- [ ] `persona_core/characters/` ディレクトリ作成
- [ ] 既存 TS キャラを YAML へ移植

## 15-3. Phase 3: 動的制御
- [ ] `persona_core/situation/analyzer.py`
- [ ] `persona_core/situation/sos_classifier.py`
- [ ] `persona_core/situation/consultation_classifier.py`
- [ ] `persona_core/character_runtime/situational_behavior.py`
- [ ] `persona_core/policy/response_strategy.py`
- [ ] `persona_core/policy/strategy_selector.py`

## 15-4. Phase 4: 表現層
- [ ] `persona_core/rendering/character_renderer.py`
- [ ] `persona_core/rendering/child_text_adapter.py`
- [ ] `persona_core/rendering/safety_rewriter.py`
- [ ] `persona_core/rendering/consistency_checker.py`
- [ ] 「そのキャラ本人として返しているか」評価ロジック

## 15-5. Phase 5: 性能
- [ ] `persona_core/performance/prompt_cache.py`
- [ ] `persona_core/performance/response_mode_router.py`
- [ ] `fast/balanced/deep` 導入

## 15-6. Phase 6: API / UI統合
- [ ] `/persona/chat` meta 拡張
- [ ] `/persona/characters` 作成
- [ ] `/persona/intent` 整備
- [ ] UI で meta を活用する

## 15-7. Phase 7: 回帰と検証
- [ ] キャラ別回帰セット作成
- [ ] SOS テスト作成
- [ ] 子ども向け表現テスト作成
- [ ] レイテンシ計測
- [ ] 子ども向け / SOS でもキャラ性が維持されるかの検証


## 15-8. ????????
- [ ] `CharacterLocaleProfile` ? backend schema ???????
- [ ] `client_context.locale` ? runtime ?????????
- [ ] `Prompt Assembler` ? locale style block ?????
- [ ] `ja-JP` locale profile ????????????
- [ ] `en-US` locale profile ?????????
- [ ] `ResponseStrategy` ? locale ???????????
- [ ] `meta.resolved_locale` ? `meta.locale_style_snapshot` ? API contract ????
