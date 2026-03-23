# Gensokyo Refactor Directory Plan

## Goal

This document fixes the target directory structure and responsibility boundaries for:

- `gensokyo-world-engine`
- `gensokyo-event-gateway`

The refactor must satisfy these rules:

- responsibilities are explicit
- route handlers stay thin
- domain logic does not depend on HTTP concerns
- database access is isolated from domain logic
- worker logic is separated from API modules
- files are split when they start carrying multiple reasons to change

## Architecture Principles

### `gensokyo-world-engine`

Purpose:

- accept world commands and visits
- persist canonical world events
- expose world read APIs
- run background command and simulation workers
- coordinate planner side effects

Must not own:

- WebSocket session handling
- UI formatting rules
- client-side replay state

### `gensokyo-event-gateway`

Purpose:

- expose a stable WebSocket protocol for UI clients
- provide snapshot + live event streaming
- manage auth and channel subscriptions

Must not own:

- world rules
- event generation
- database state mutation outside gateway-specific concerns

## Target Directory Structure

### `gensokyo-world-engine`

```text
gensokyo-world-engine/
  app/
    __init__.py
    main.py
    config.py
    dependencies.py
    api/
      __init__.py
      routes/
        __init__.py
        health.py
        world_events.py
        world_commands.py
        world_queries.py
        world_visits.py
        world_ticks.py
    application/
      __init__.py
      dto.py
      services/
        __init__.py
        emit_event_service.py
        submit_command_service.py
        visit_world_service.py
        tick_world_service.py
        query_world_service.py
        planner_service.py
    domain/
      __init__.py
      models/
        __init__.py
        events.py
        commands.py
        actors.py
        world_state.py
        npc_state.py
      rules/
        __init__.py
        time_rules.py
        event_rules.py
        location_rules.py
        npc_rules.py
      services/
        __init__.py
        event_selection.py
        state_projection.py
        relation_updates.py
    infrastructure/
      __init__.py
      env.py
      http.py
      repos/
        __init__.py
        postgrest.py
        world_events_repo.py
        world_commands_repo.py
        world_state_repo.py
        world_visits_repo.py
        world_npcs_repo.py
        world_users_repo.py
      clients/
        __init__.py
        supabase_rpc.py
        persona_chat.py
      content/
        __init__.py
        loader.py
    workers/
      __init__.py
      command_worker.py
      simulator_worker.py
    planner/
      __init__.py
      adapters.py
      orchestration.py
    legacy/
      __init__.py
      migration_notes.md
  content/
  planner/
  tools/
  requirements.txt
  README.md
```

### `gensokyo-event-gateway`

```text
gensokyo-event-gateway/
  src/
    index.ts
    config/
      env.ts
    protocol/
      messages.ts
      validation.ts
    ws/
      server.ts
      connection.ts
    auth/
      hello.ts
      access.ts
    subscriptions/
      hub.ts
      registry.ts
    streaming/
      snapshot.ts
      live.ts
    infrastructure/
      supabase.ts
      logger.ts
    utils/
      channel.ts
      json.ts
  package.json
  tsconfig.json
  README.md
```

## Responsibility Map

### World Engine Modules

#### `app/api/routes/*`

Own:

- FastAPI routes
- request/response mapping
- HTTP status handling
- dependency injection wiring

Do not own:

- direct business rules
- direct SQL/PostgREST construction
- worker loops

#### `application/services/*`

Own:

- use-case orchestration
- transaction-like sequencing across repos and domain services
- conversion between external requests and domain models

Do not own:

- HTTP objects
- raw environment reads
- low-level fetch logic

#### `domain/models/*`

Own:

- typed world concepts
- event/command payload structures
- state containers

#### `domain/rules/*`

Own:

- monotonic time constraints
- candidate event filtering
- location and sub-location validation
- NPC movement and relation constraints

#### `domain/services/*`

Own:

- deterministic event selection
- state projection logic
- relation impact rules

#### `infrastructure/repos/*`

Own:

- PostgREST table access
- query assembly for persistence
- row mapping for database IO

#### `infrastructure/clients/*`

Own:

- RPC calls
- external service clients

#### `workers/*`

Own:

- polling loops
- job claiming
- worker-level retries

Do not own:

- HTTP route registration
- prompt formatting for UI

### Event Gateway Modules

#### `protocol/*`

Own:

- client/server message types
- parsing and validation helpers

#### `ws/*`

Own:

- WebSocket server lifecycle
- per-connection state
- message dispatch entrypoint

#### `auth/*`

Own:

- hello auth handling
- anon access policy
- channel access checks

#### `subscriptions/*`

Own:

- hub creation/removal
- client membership tracking

#### `streaming/*`

Own:

- snapshot replay
- live insert fanout

#### `infrastructure/*`

Own:

- Supabase client creation
- logging helpers

## Migration Plan

### Phase 1: `gensokyo-world-engine`

1. Introduce `app/` package and move environment/bootstrap code into `config.py` and `dependencies.py`.
2. Split route handlers out of `server.py` into `app/api/routes/*`.
3. Extract PostgREST helpers and table access into `infrastructure/repos/*`.
4. Extract event emission and query use cases into `application/services/*`.
5. Move worker loops into `workers/*`.
6. Leave a thin compatibility entrypoint so the service can still boot during migration.

### Phase 2: `gensokyo-event-gateway`

1. Split protocol types from `src/index.ts`.
2. Move auth, snapshot, live streaming, and hub management into dedicated modules.
3. Keep `src/index.ts` as a bootstrap-only file.

## File Size Rule

Refactor trigger:

- if a file mixes API + domain + persistence concerns, split immediately
- if a file exceeds comfortable single-responsibility review size, split by responsibility rather than arbitrary line count
- prefer one cohesive service per file over one giant helper file

## Current Legacy Concentration

The following files are current concentration points and should be reduced:

- `gensokyo-world-engine/server.py`
- `gensokyo-event-gateway/src/index.ts`

These files should end up as thin entrypoints, not primary logic containers.
