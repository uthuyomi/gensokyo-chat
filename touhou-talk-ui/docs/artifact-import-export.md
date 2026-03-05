# Artifact（run.jsonl）インポート / エクスポート

チャットページで、テストループ等で出力した `run.jsonl`（JSONL）を **復元（インポート）**し、現在のセッションを **JSONLで書き出し（エクスポート）**できるようにした仕組みのメモです。

目的は「履歴をDBへ復元して、そこから続きの会話をできるようにする」ことです。

## UI

- チャットページの左サイドバー内「セッション」見出し右側に
  - `インポート`
  - `エクスポート`
  を表示します。

## 対応フォーマット

### 1) JSONL（`run.jsonl`）

1行=1JSON の形式です。最低限、次が入っていれば復元できます。

- `session_id`（文字列）
- `user`（文字列）
- `reply`（文字列）

他のフィールド（例: `intent`, `case_id`, `ms` など）はあっても構いません（復元には必須ではありません）。

### 2) JSON

次のどれかを自動判定して受け入れます（テストデータの揺れ対策）。

- 配列（artifact行の配列）
- `{ sessions: [...] }`
- `{ messages: [...] }`
- `[{ role, content }, ...]`（メッセージ配列）

## 復元の動作（重要）

1. クライアント側でファイルを読み取り、JSON/JSONL を自動判定してパースします（`lib/artifact/artifact-io.ts`）。
2. `session_id` が複数ある場合は **session_id ごとに別セッション**として復元します。
3. `POST /api/session/import` を呼び、Supabase の
   - `common_sessions`
   - `common_messages`
   に insert します。
4. insert 後、UI側のセッション一覧へ追加して、先頭の復元セッションをアクティブにします。

### 「続きの会話」ができる理由

このUIは送信時に履歴をリクエストへ同封しません。サーバ側が `common_messages` の履歴を読んで core に渡す設計です。

そのため、インポート時に DB へ履歴を入れておけば、そのまま通常の送信処理で続き会話が成立します。

### 順序の保証（created_at）

`common_messages` は `created_at` 昇順で読み出します。

Postgres の `now()` は「1つのINSERT文の中では同じ値になりやすい」ため、復元では **created_at を1ms刻みで明示**して順序を安定させています（`app/api/session/import/route.ts`）。

## エクスポート

現在のセッション（表示中の履歴）から、`run.jsonl` 相当の JSONL を生成してダウンロードします。

出力は最低限の互換フィールドのみです。

- `turn`（1始まり）
- `turn_index`（0始まり）
- `session_id`（現在のsessionId）
- `user`
- `reply`

## 制限（安全弁）

サーバ側で次を上限にしています。

- セッション数: 500
- メッセージ総数: 20,000

クライアント側では、ファイルサイズの目安として 10MB を上限にしています。

