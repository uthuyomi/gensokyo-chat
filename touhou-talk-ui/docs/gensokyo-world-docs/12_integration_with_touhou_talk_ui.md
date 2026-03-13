# 12 Integration with `touhou-talk-ui`（UI統合の設計）

この章は「既存のチャットUIの延長で、幻想郷ワールドを足す」ための統合設計。

狙い:

- UIは今の体験を崩さない
- ワールド更新は `visit` でまとめて実行（Time Skip）
- 会話は “世界状態を踏む” けど、世界更新はしない

---

## 1) 入口（URLパラメータ）

現状のUIはクエリでワールド（推奨）・レイヤ（互換）・ロケーションを指定している想定:

例:

```
/chat/session?world=gensokyo_main&loc=hakurei_shrine&char=reimu
```

統合の方針:

- `char` は “会話相手”
- `world/loc` は “世界の場所”
  - `world_id` は `gensokyo_main`, `gensokyo_test`, `gensokyo_shard_01` など
  - `layer_id` は表示・分類用（例: `gensokyo`）で、`world_id` から導出しても良い
- 画面表示時に `visit` を呼び、`world_state/recent_events` をUI状態として保持する

---

## 2) ページ表示時フロー（おすすめ）

1. UIが `world/loc` を読む
2. `POST /api/world/visit` を呼ぶ
3. 返ってきた `world_state/recent_events` を state に保存
4. チャット送信時に、その state を “会話プロンプト材料” として混ぜる

> 重要: `visit` は “会話のたびに” 呼ばない。ページ入場/再訪のタイミングで十分。

---

## 3) チャット送信（プロンプト注入の形）

チャット送信の server-side（Next.js route）でやること:

- 元の会話入力（user message）を受ける
- `world_state/recent_events` を付与して “会話生成” だけを依頼する

混ぜる内容（最小）:

- キャラプロフィール（短い）
- キャラ現在状態（emotion/action/location）
- 世界状態（時間帯/天気/季節）
- 最近イベント要約（最大N件）

テンプレは `07_prompt_templates.md` を正本にする。

---

## 3.5) Player↔Character関係性（Relation）と Character Scoped Memory

Touhou-talkは「同じユーザーでも、キャラごとに関係値・記憶を分ける」前提で設計する。

- Relation（関係値）
  - DB: `player_character_relations (user_id, character_id)`
  - UI（Next.js route）で relation を読み、**persona_system にソフトに注入**する（数値は表示しない）
  - world-engine は会話イベント（例: `user_say`）に応じて relation を best-effort で更新できる
- Character Scoped Memory（Episodic）
  - sigmaris_core の `common_episodes` を `user_id + character_id` でフィルタする
  - 霊夢に話した内容が、魔理沙に自動で漏れない

> 重要: 「世界状態の更新」は world-engine の責務。  
> 「会話生成（persona / memory）」は sigmaris_core の責務。  
> UIは “材料を渡すだけ” に寄せる。

---

## 4) UIへの反映（表示）

UIで最初にやるならこれだけで十分:

- `recent_events` を左カラム（AI側）に “出来事ログ” として出す
- 会話に自然に混ぜる（LLMが1つだけ触れる）

やりすぎ注意:

- 全イベントを長文で見せる → スクロール地獄になる
- ワールドの説明をLLMにさせる → 捏造が入りやすい

---

## 5) VRM演技（emotion/gesture）との統合

これは “世界状態” と切り離すのが安全。

流れ:

1. 会話テキストを生成
2. （任意）同テキストに対して `emotion/gesture` を選ばせる
3. フロントで VRM 表情/モーションを再生する

I/Oの形は `07_prompt_templates.md` の “VRM Directive” を使う。

---

## 5.5) リアルタイムイベントログ（WS）をUIに流す

到達点③（イベントログが流れる）をリアルタイムでやる場合、UIは「ワールドの状態」を直接ポーリングするより、**WSのイベントストリーム** を購読してログ表示する。

- WS仕様: `16_realtime_event_gateway_ws.md`
- DB永続（取りこぼしゼロ）: `01_supabase_schema_ai_gensokyo.md` の `world_event_channels / world_event_log`

UI側の基本フロー:

1. `/chat/session?world=...&loc=...` で表示
2. `channel = world:{world_id}:{loc}` を購読（必要なら `world:{world_id}` も購読）
3. `snapshot` → `event` を受け取り、イベントログにappendして描画
4. チャンネルごとに `lastSeq` を保存し、再接続時に送る（取りこぼし回収）

> ここでのポイントは「UIはイベントを描画するだけ」。  
> 世界更新（NPC状態・出来事生成）は `gensokyo-world` 側の責務に寄せる。

補足（イベント種別）：
- `npc_dialogue`（NPC↔NPC会話）
  - 表示例: `[Reimu → Marisa] また来たの？`

---

## 6) 失敗時のフォールバック

上流サーバ（会話生成）が落ちた場合でも、世界は壊さない設計にする。

おすすめ:

- `visit` は成功しているなら、その `recent_events` だけは表示できる
- 会話生成が失敗したら、UIは “再送を促す” だけにする（世界更新はしない）

> 逆に、会話生成に失敗したからといって `visit` を巻き戻すのはNG。

---

## 7) “20キャラ” をUIに落とす最小

最初の勝ち筋は、UIに大量のNPC一覧を出さないこと。

- 画面は “いま会話してる1キャラ” が主役
- 同じ場所のNPCは、必要になったら後で出す（`/api/world/npcs`）

この割り切りが、コスト/実装量/体験の全部に効く。
