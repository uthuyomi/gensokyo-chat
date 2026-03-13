# 15 3D Migration Path（UI維持のまま3Dへ持っていく）

結論: **可能**。しかも「今のチャットUI」を捨てずに段階移行できる。

この章は、将来的に幻想郷ワールドを 2D（チャット中心）→ 3D（空間中心）へ拡張する時の“差し替えポイント”を固定する。

---

## 0) 大原則（資産を殺さない）

3D化で変えるのは **表示レイヤ** が中心。
次は最初から “表示に依存しない” 形で持つ。

- ワールド層（Time Skip / world_state / event_logs）
- 素材（locations / characters / relationships / event_defs）
- 会話層（prompt templates / VRM directive）

> ここが分離できていれば、3Dにしてもロジックはそのまま使える。

---

## 1) 変えなくていいもの（そのまま使う）

- `POST /api/world/visit`（訪問時に追いつく）
- `GET /api/world/state` / `GET /api/world/recent`（読み取り）
- `characters/relationships/event_defs` の素材
- 会話生成（world_state / recent_events を注入するプロンプト）

つまり、3D化は **フロントの表現強化** が主。

---

## 2) 差し替えるもの（3D化ポイント）

### 2.1 “中央の表示領域” を3Dに差し替える

いま:

- チャットUI（左右）
- VRM表示（中央）

将来:

- チャットUI（左右）は維持
- 中央を **Three.js/Babylon.js のシーン** にし、背景/小物/ライト/カメラ演出を載せる

> 一番安全な移行は「中央だけ差し替え」。

### 2.2 入力を増やす（任意）

最初はテキスト入力のままでOK。
拡張で:

- クリックで視点移動
- ロケーション選択（移動）
- UI上の“同じ場所にいるNPC”を選択

---

## 3) 3D化の段階（おすすめロードマップ）

### Phase A: 2Dのまま、3D演出だけ強化（最短）

- 中央に VRM + 3D背景（単一シーン）
- `world/loc` に応じて背景やライトを切り替え（`layer` は `world_id` から導出しても良い）

必要な追加は最小。

### Phase B: ロケーションを“シーン”として持つ

- location_id → scene_id のマッピングを追加
- `visit` の結果（天気/時間帯）で、fog/lighting を変える

### Phase C: 空間内UI（軽量）

- “同じ場所にいるNPC” をシーン内のUIで見せる
- ただしNPCを大量に歩かせない（Time Skip方針は維持）

### Phase D: 本格3D（必要なら）

- 移動ルート/近接/遮蔽物など、空間的ルールを増やす
- 必要に応じて WebSocket で更新を流す

> ここまで行くと実装/運用コストが跳ねる。20キャラ規模なら Phase B〜C が勝ちやすい。

---

## 4) 3D化しても Time Skip を捨てない理由

3Dにすると “リアルタイムで全部動かしたくなる” けど、それはコスト爆発の入口。

勝ち筋:

- 世界更新は `visit`（Time Skip）でまとめて行う
- 3Dは “今の瞬間の演出” と “空気感” を強化する

---

## 5) VRMとの統合（演技は独立にする）

3Dになっても、演技（emotion/gesture）は同じI/Oで回せる。

- 会話テキスト生成
- VRM directive（emotion/gesture）生成（任意）
- フロントで表情・モーション・視線を再生

I/Oは `07_prompt_templates.md`、統合は `12_integration_with_touhou_talk_ui.md` を正本にする。
