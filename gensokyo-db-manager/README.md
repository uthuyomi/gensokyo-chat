# gensokyo-db-manager

Multi-layer knowledge DB management service for `gensokyo-chat`.

This service is intentionally separate from `gensokyo-world-engine`.
It handles slower and riskier operations that should not share the same
runtime or permissions as the read-oriented world API.

Responsibilities:

- coverage / gap preview for the world DB
- multi-layer knowledge claim ingestion
- source / conflict / approval management
- schema extension suggestions and migration drafts
- interaction-driven expansion signals
- web ingest queueing for later review

## Run locally

### 1) Apply optional manager schema

Run this SQL in Supabase SQL Editor:

- `supabase/world/WORLD_SCHEMA_DB_MANAGER.sql`

### 2) Configure env

The service best-effort loads the repo root `.env`.

Required:

- `WORLD_SUPABASE_URL` or `SUPABASE_URL`
- `WORLD_SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_SERVICE_ROLE_KEY`

Optional:

- `GENSOKYO_DB_MANAGER_SECRET`
- `GENSOKYO_DB_MANAGER_PORT` (default: `8011`)
- `GENSOKYO_DB_MANAGER_HTTP_TIMEOUT` (default: `20`)
- `GENSOKYO_DB_MANAGER_SWEEP_ENABLED` (default: `1`)
- `GENSOKYO_DB_MANAGER_SWEEP_SECONDS` (default: `180`)
- `GENSOKYO_DB_MANAGER_AUTO_REVIEW_ENABLED` (default: `1`)
- `GENSOKYO_DB_MANAGER_DISCOVERY_ENABLED` (default: `1`)
- `GENSOKYO_DB_MANAGER_EMBED_REFRESH_ENABLED` (default: `1`)
- `GENSOKYO_DB_MANAGER_AI_ENABLED` (default: `1`)
- `GENSOKYO_DB_MANAGER_AI_MODEL` (default: `gpt-5-mini`)
- `GENSOKYO_DB_MANAGER_AI_TIMEOUT` (default: `45`)
- `GENSOKYO_DB_MANAGER_AI_MAX_INPUT_CHARS` (default: `24000`)
- `OPENAI_API_KEY`

### 3) Install deps & start

```powershell
cd gensokyo-db-manager
python -m venv .venv
./.venv/Scripts/pip install -r requirements.txt
./.venv/Scripts/python -m uvicorn server:app --host 127.0.0.1 --port 8011
```

Health:

- `GET http://127.0.0.1:8011/health`

## Key endpoints

- `GET /health`
- `GET /audit/coverage-preview?world_id=gensokyo_main`
- `GET /audit/report?world_id=gensokyo_main`
- `POST /schema/suggest`
- `POST /schema/migration-draft`
- `POST /signals/interaction`
- `POST /claims/ingest`
- `GET /claims/pending?world_id=gensokyo_main`
- `POST /claims/{claim_id}/review`
- `POST /claims/auto-review`
- `GET /claims/conflicts?world_id=gensokyo_main`
- `POST /discovery/sources`
- `GET /discovery/sources?world_id=gensokyo_main`
- `POST /discovery/presets/install`
- `POST /discovery/run`
- `POST /ingest/web-page`
- `POST /ingest/process-queue`
- `GET /ops/policies`
- `GET /ops/policies/{policy_key}`
- `POST /ops/policies/{policy_key}`
- `GET /ops/jobs`
- `GET /ops/jobs/{run_id}`
- `POST /ops/embedding-refresh`

## Phase coverage

Current implementation covers the practical skeleton for phase 1-3:

- Phase 1: multi-layer knowledge tables (`claims`, `sources`, `conflicts`)
- Phase 2: manager APIs for pending review, conflict tracking, schema suggestion
- Phase 3: interaction signals, web ingest queueing, migration draft generation
- Phase 3+: web queue to pending claim conversion and safe auto-review
- Discovery: source registry -> URL discovery -> queue insertion
- Ops: policy storage, job history, audit report, embedding refresh hook
- AI: web-to-claim extraction, claim judgement, signal judgement, schema judgement

## Interaction-driven expansion

`POST /signals/interaction` is the entrypoint for:

- "this was missing during a user interaction"
- "this should probably be stored in DB"
- "this might need a schema extension"

The signal is stored as a pending observation and scored for follow-up.

## Knowledge claim flow

1. Collect a signal from user interaction or web ingest.
2. Ingest a structured claim with `POST /claims/ingest`.
3. Link supporting / contradicting sources.
4. Detect competing claims and open conflicts.
5. Review with `POST /claims/{claim_id}/review` or `POST /claims/auto-review`.

## Discovery flow

1. Register a discovery source with `POST /discovery/sources`.
   You can also bootstrap official presets with `POST /discovery/presets/install`.
2. The scheduler or `POST /discovery/run` fetches the source URL.
3. RSS / sitemap / index-page links are extracted into candidate URLs.
4. New URLs are inserted into `world_web_ingest_queue`.
5. The existing ingest worker fetches those pages and converts them into pending claims.

### Official preset

`POST /discovery/presets/install` with:

```json
{
  "world_id": "gensokyo_main",
  "preset_name": "official_touhou",
  "overwrite_existing": false
}
```

This installs:

- Touhou Project News RSS
- Team Shanghai Alice index page
- Tasofro index page

## Notes

- This service does **not** auto-apply schema changes to production.
- `POST /schema/migration-draft` generates SQL text only.
- Actual migration application should remain a reviewed step.
- Web ingest queue processing runs in the background when scheduler is enabled.
- The scheduler can also be triggered manually with `POST /ingest/process-queue`.
- Discovery source polling also runs in the background when enabled.
- Auto-review only promotes low-risk claims. Weak or conflicted claims stay pending or become disputed.
- Canonical URL and claim fingerprint dedupe are built in, so obvious URL/claim duplicates are reused instead of multiplied.
- Accepted claims can trigger `world_refresh_embedding_documents` and `world_queue_embedding_refresh` when enabled.
- When AI is enabled, the manager uses OpenAI to extract multiple claim candidates from fetched pages and to judge storage / schema / signal decisions.
