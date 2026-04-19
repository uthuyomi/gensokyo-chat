# touhou-talk-ui

`touhou-talk-ui` は、`gensokyo-chat` のメインクライアントとなる Next.js フロントエンドです。
チャット体験、stream 表示、session 管理、添付フロー、relationship 関連 UI、world 系 UI 連携、desktop 化のための基盤を担当します。

## Quick Read

- Project summary: 共有 character runtime の上に載るメイン product client
- Scope: chat UX、session orchestration、streaming 連携、persistence、service-facing UI route を含む
- Technical highlights: session-message pipeline、attachment handling、relationship / world integration、avatar 向け metadata 消費
- Why it matters: persona ownership を backend に残したまま、frontend を rich で stateful にしている

## Executive summary

この frontend は、単なる presentation layer ではありません。
runtime の機能を実際に使える chat experience に変換する product-facing orchestration layer であり、persistence、attachment handling、streaming event 変換、avatar 向け metadata 消費まで担います。

## システム内での役割

このモジュールは persona backend に対して意図的に薄いクライアントとして設計されています。
会話状態を `gensokyo-persona-core` に渡し、UI は表示品質、操作体験、クライアント側のプロダクト体験に集中します。

## ポートフォリオ上の価値

この frontend は、単なる見た目の実装ではない点がポートフォリオとして強みです。
backend 主導の character runtime を崩さずに、persistence、streaming 変換、attachment 処理、avatar 向け metadata 制御までを含む product surface をどう組むかを示しています。

## なぜこの構成が重要か

AI frontend は、気づかないうちに prompt logic を抱え込みがちです。
この frontend はそれを避けています。
価値の中心は、backend 挙動の複製ではなく、product orchestration にあります。

## UI が責任を持つこと

- route 構成とアプリケーション shell
- chat 表示と streaming UX
- client 側の session / attachment 処理
- Electron を使った desktop packaging
- UI 向け character catalog とフロントエンド資料
- session-message 系の persistence と orchestration
- TTS reading や VRM performance cue など応答後 metadata の利用

## UI が責任を持たないこと

- persona prompt の組み立て
- キャラクター挙動の決定
- safety wording の制御
- backend runtime policy

これらは `gensokyo-persona-core` が担います。

## メイン chat フローで実際にしていること

現在の session message ルートは、単なる proxy ではありません。
実装上は次の処理を担っています。

1. request body を検証し、対象 session の context を解決する
2. file がある場合は persona core へ attachment を upload する
3. user message を保存する
4. `/persona/chat` または `/persona/chat/stream` に turn を委譲する
5. stream event を client 向けに relay する
6. 完了後に assistant reply を保存する
7. TTS reading metadata と VRM performance hint を付与する
8. 応答後に relationship / memory 更新を best-effort で走らせる

つまりこの frontend は、見た目だけではなく product layer の orchestration も担当しています。

## このモジュールが解いている課題

この frontend は、persona ownership を backend に残したまま、product 側の課題を解くために設計されています。

- stream を前提にした chat UX を成立させること
- runtime 呼び出しの前後で session / message を保存すること
- attachment を user-facing な流れとして扱うこと
- runtime の出力を TTS / VRM 向け metadata に変換すること
- world、relationship、desktop 専用フローを一つの client に統合すること

## Core session-message pipeline

backend とつながる主経路は、次の流れとして読むと把握しやすいです。

1. request parsing
2. session context loading
3. 必要時の attachment upload
4. user message persistence
5. runtime delegation
6. stream translation または single response 処理
7. assistant message persistence
8. relationship / memory 更新などの post-reply side effect

この経路が、アプリケーション挙動の中心です。

## Persistence model の実態

現状の server-side UI 層は、chat text だけを保存しているわけではありません。
`session-message-v2` 配下のコードからは、少なくとも次を保存していることが確認できます。

- user message
- assistant message
- message record 内の attachment / link metadata
- runtime telemetry 的 field を抜き出した state snapshot

この persistence layer があるため、このプロジェクトは demo frontend というより application system として読めます。

## 主要ディレクトリ

| Path | 役割 |
| --- | --- |
| `app/` | Next.js routes とエントリポイント |
| `components/` | UI コンポーネント |
| `app/api/session/[sessionId]/message/` | メインの session message 入口 |
| `lib/server/session-message-v2/` | persona API への server-side bridge |
| `lib/characterCatalog.ts` | UI 向け character catalog metadata |
| `docs/` | frontend 固有の参考資料 |
| `tools/` | desktop、Blender、Unity 向け補助ツール |

## UI 層が持つ API 面

この frontend には、他サービスとの橋渡し API も含まれています。

- chat / session API
- relationship の import / export / reset API
- attachment proxy API
- world service への proxy API
- DB manager への proxy API
- desktop 専用の character settings / VRM asset API

そのため、このリポジトリは見た目の実装だけでなく、アプリケーション境界の glue code も多く含みます。

## Relationship / world 連携

この frontend は、chat 以外の state とも積極的につながっています。

- relationship route では trust、familiarity、character scope 単位の memory を読み出す
- session-message flow では reply 後に relationship scoring と memory 更新を走らせる
- world helper では `world/state` と `world/recent` を読み、prompt overlay に変換する
- world API route では secret を持つ world-engine 呼び出しを proxy する

この点が、単なる chat shell ではなく stateful な product coordinator になっている理由です。

## エンジニアが直接追うべきコード

重要度が高い実装経路は次のとおりです。

- `lib/server/session-message-v2/handler.ts`
- `lib/server/session-message-v2/respond.ts`
- `lib/server/session-message-v2/stream.ts`
- `lib/server/session-message-v2/retrieval.ts`
- `app/api/session/[sessionId]/message/`
- `app/api/world/`
- `app/api/relationship/`
- `app/api/desktop/`

## 開発

```powershell
cd touhou-talk-ui
npm install
npm run dev
```

主な script:

- `npm run build`
- `npm run start`
- `npm run desktop:dev`
- `npm run desktop:dist`

## 技術スナップショット

- Next.js 16
- React 18
- TypeScript
- Electron による desktop packaging
- 必要箇所で Supabase / OpenAI SDK を利用

## このモジュールの見どころ

共有 backend character runtime の上に、リッチな chat 体験をどう載せるかを示すのがこの frontend です。
体験は厚く、persona control は backend に残すという役割分担が特徴です。

エンジニア視点では、UX、server route、persistence、streaming 変換、avatar 向け metadata 制御が一つの client module にまとまっている点が見どころです。

## 評価するならどこを見るべきか

この module は、「component 数が多いか」より、「backend runtime の能力を architectural boundary を壊さずに coherent product experience に変換できているか」で評価するのが適しています。

## 関連モジュール

- backend runtime: `../gensokyo-persona-core/`
- 全体概要: `../README.ja.md`
