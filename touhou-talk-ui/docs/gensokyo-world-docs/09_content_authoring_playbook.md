# 09 Content Authoring Playbook（素材づくり手順 / 実装前提）

このドキュメントは「幻想郷ワールドの中身（場所・キャラ・関係・イベント）」を**どう管理して増やすか**の手順書。

狙い:

- “とりあえず動く”を最短で作る
- 20キャラ規模で破綻しない編集フローにする
- 後からDB/キュー/シミュレーション拡張しても、素材が死なない形にする

前提:

- 最初は **RDB（Supabase/Postgres） + JSON** で十分
- 「世界の真実（位置・状態）」はワールドエンジン側で決める（LLMに決めさせない）

---

## 0) 素材の置き場（推奨）

実装時に “素材置き場” を固定しておくと、後で楽。

例（案）:

```
touhou-talk-ui/
  world/
    layers/
      gensokyo/
        locations.json
        sub_locations.json
        characters.json
        relationships.json
        event_defs/
          marisa_visit.json
          reimu_cleaning.json
          ...
```

> 注: この `world/` は現状のリポジトリに無いなら、実装時に追加する前提の“提案”。

実装状況（現状）：
- 置き場は `touhou-talk-ui/world/layers/gensokyo/` を追加済み
- world-engineは `GENSOKYO_CONTENT_ROOT` を設定すると、このディレクトリから `locations.json` / `event_defs/*.json` を読み込む

---

## 1) ID/命名ルール（これが一番ミソ）

迷いを減らすために、最初から固定する。

- `layer_id`: `gensokyo`（将来 multi-world にするなら増やす）
- `location_id`: `hakurei_shrine` みたいに `snake_case`
- `sub_location_id`: `hakurei_shrine/engawa` でもいいが、最初は `engawa` でOK（衝突しない運用なら）
- `character_id`: `reimu`, `marisa`（URLに出せる英数）
- `event_type`: `marisa_visit`, `reimu_cleaning`（動詞+目的語）

### 1.1 “表示名”と“ID”を混ぜない

- **表示名**: 日本語OK（UI/ログ用）
- **ID**: 英数のみ推奨（URL/DBキー用）

---

## 2) ロケーション素材（locations / sub_locations）

最初に必要な最小:

- `id`, `name`
- `tags`（屋内/屋外/静か/危険…）
- `neighbors`（移動用）
- `density`（イベント頻度の地形）

「サブロケ」は、イベント演出（縁側・賽銭箱前・境内など）に効く。

---

## 3) キャラ素材（characters）

20キャラなら、最小でもこの4つだけは欲しい:

- `home_location_id`（帰る場所）
- `traits`（行動決定のルール入力）
- `speech_style`（会話の口調スイッチ）
- `default_emotion`（無入力時の表情/トーン）

### 3.1 “会話用の性格”と“行動用の性格”を分ける

- 会話: 口調、語彙、テンポ
- 行動: 好み、回避、優先度、疲労（energy）

ここが混ざると、LLMが“世界更新”を始めて破綻しやすい。

---

## 4) 関係素材（relationships）

20キャラの全組み合わせ（190ペア）を最初から作るのは負け筋。

おすすめ:

- “主要ペア” だけ作る（例: 霊夢↔魔理沙、霊夢↔早苗…）
- その他は「未定義＝ニュートラル」で扱う

---

## 5) イベント素材（event_defs）

イベントは **“出来事の種類”** のカタログ。

最初の勝ち筋:

- 1ロケあたり 5〜15個（まずは神社だけ作ってもOK）
- “日常イベント” を厚くする（掃除・お茶・訪問・立ち話…）
- “大事件” は少なく（演出が重い）

イベント定義の形は `05_domain_models_and_data_specs.md` の `EventDefinition` を基準にする。

---

## 6) 追加・変更フロー（実装時の運用）

おすすめの運用（案）:

1. JSON（素材）を編集
2. “軽いバリデーション” を通す（ID重複、neighborsの存在、必須フィールド）
3. DBに seed（初期投入） or 差分反映
4. ロケーションへ `visit` してイベントが出るか確認

> バリデーションは、実装時に `node` スクリプト（または `zod`）で作るのが安定。

---

## 7) 20キャラ前提の「素材の優先度」

最初に効く順:

1. ロケーション（移動/遭遇の土台）
2. 日常イベント（生活感の8割）
3. キャラの home/traits/speech_style
4. 主要関係（霊夢-魔理沙など）
5. 例外イベント（異変/戦闘/長尺）
