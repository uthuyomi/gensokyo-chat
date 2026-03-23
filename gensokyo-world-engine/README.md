# gensokyo-world-engine

Optional world layer service for Project Sigmaris / Touhou Talk.

This service is responsible for:

- Accepting Commands (user intent) and persisting them to Supabase (`world_command_log`)
- Appending Events (facts) to the ordered event log (`world_event_log`)
- Serving read APIs for world state / recent events / NPC snapshots (minimal, extensible)

The UI is not coupled to this service directly; real-time consumption is designed to go through the WS gateway (`gensokyo-event-gateway/`).

## Run locally

### 1) Apply Supabase schema

Run these SQL files in Supabase SQL Editor:

- `supabase/RESET_TO_COMMON.sql` (shared `common_*`)
- `supabase/GENSOKYO_WORLD_SCHEMA.sql` (world tables)

### 2) Configure env

The server best-effort loads the repo root `.env` (without overwriting shell env).

Required:

- `WORLD_SUPABASE_URL` or `SUPABASE_URL`
- `WORLD_SUPABASE_SERVICE_ROLE_KEY` or `SUPABASE_SERVICE_ROLE_KEY`

Optional hardening:

- `GENSOKYO_WORLD_ENGINE_SECRET` (when set, endpoints require header `x-world-secret: <value>`)

Optional port:

- `GENSOKYO_WORLD_ENGINE_PORT` (default: `8010`)
- `OPENAI_API_KEY` (when running the embedding worker)
- `WORLD_EMBEDDING_MODEL` (default: `text-embedding-3-small`)
- `WORLD_EMBEDDING_BATCH_SIZE` (default: `32`)
- `WORLD_EMBEDDING_JOB_LIMIT` (default: `128`)

### 3) Install deps & start

```powershell
cd gensokyo-world-engine
python -m venv .venv
./.venv/Scripts/pip install -r requirements.txt
./.venv/Scripts/python -m uvicorn server:app --host 127.0.0.1 --port 8010
```

Health: `GET http://127.0.0.1:8010/health`

## Key endpoints

- `POST /world/emit` (append an event)
- `POST /world/command` (enqueue a command)
- `POST /world/visit` (enter a location / create visitor snapshot)
- `POST /world/tick` (time skip / simulation tick)
- `GET /world/state?world_id=...&location_id=...`
- `GET /world/recent?world_id=...&location_id=...&limit=...`
- `GET /world/npcs?world_id=...&location_id=...`

## Command worker

`POST /world/command` persists `world_command_log` with `status=queued`.
A background worker consumes queued commands, emits corresponding events (`world_event_log`), and updates status to `done/failed`.

Env knobs:

- `GENSOKYO_COMMAND_WORKER_ENABLED=1` (default)
- `GENSOKYO_COMMAND_WORKER_POLL_MS=500`
- `GENSOKYO_COMMAND_WORKER_BATCH=20`

## Content (data)

Time skip generation reads repo-local JSON:

- `gensokyo-world-engine/content/locations.json`
- `gensokyo-world-engine/content/events.json`
- `gensokyo-world-engine/content/relationships.json`

## World embeddings

When the Supabase world schema includes the vector layer:

- `supabase/world/WORLD_SCHEMA_VECTOR.sql`
- `supabase/world/WORLD_SEED_VECTOR_BOOTSTRAP.sql`

you can queue searchable world documents and embed them with:

```powershell
cd gensokyo-world-engine
./.venv/Scripts/python tools/world_embedding_worker.py --preview 5
./.venv/Scripts/python tools/world_embedding_worker.py
```

This reads pending rows from `world_embedding_jobs`, generates embeddings for
`world_embedding_documents`, and stores them in `world_embeddings`.
