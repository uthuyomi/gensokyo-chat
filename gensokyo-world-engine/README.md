# gensokyo-world-engine (local)

Long-term world engine (Python) for Project Sigmaris / Touhou Talk.

This service is responsible for:

- accepting Commands (user intent) and persisting them to Supabase
- appending Events (facts) to the ordered event log (`world_event_log`)
- serving read APIs for world state / recent events / npc snapshots (minimal, extensible)

It intentionally does **not** serve the UI directly. The UI consumes Events via the WS gateway.

## Run (local)

1) Ensure Supabase schema exists

Run `supabase/GENSOKYO_WORLD_SCHEMA.sql` in Supabase SQL Editor.

2) Set env vars (example)

```powershell
$env:SUPABASE_URL="..."
$env:SUPABASE_SERVICE_ROLE_KEY="..."
$env:GENSOKYO_WORLD_ENGINE_PORT="8010"
```

3) Install deps & run

```powershell
python -m venv .venv
./.venv/Scripts/pip install -r requirements.txt
./.venv/Scripts/python -m uvicorn server:app --host 127.0.0.1 --port 8010
```

## Endpoints (local)

- `GET /health`
- `POST /world/emit`
- `POST /world/command`
- `POST /world/visit`
- `POST /world/tick`
- `GET /world/state?world_id=...&location_id=...`
- `GET /world/recent?world_id=...&location_id=...&limit=...`
- `GET /world/npcs?world_id=...&location_id=...`

## Command worker (real-time)

`POST /world/command` persists `world_command_log` with `status=queued`. A background worker consumes queued commands,
emits corresponding Events (`world_event_log`), and updates status to `done/failed`.

Env knobs:

- `GENSOKYO_COMMAND_WORKER_ENABLED=1` (default)
- `GENSOKYO_COMMAND_WORKER_POLL_MS=500`
- `GENSOKYO_COMMAND_WORKER_BATCH=20`

## Content (data)

Time Skip event generation uses repo-local JSON:

- `gensokyo-world-engine/content/locations.json`（density / sub_locations / neighbors）
- `gensokyo-world-engine/content/events.json`（EventDefinition: probability / cooldown / constraints / effects / summary）
