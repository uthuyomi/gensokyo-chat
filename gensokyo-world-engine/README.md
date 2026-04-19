# gensokyo-world-engine

`gensokyo-world-engine` is a support service for world data, lore retrieval, simulation helpers, and story-facing application logic in the `gensokyo-chat` workspace.
It keeps world-oriented concerns separate from the core character runtime.

## Quick Read

- Project summary: A dedicated service for world-state, lore, NPC, visit/tick, and story progression concerns.
- Scope: Keeps world logic outside the character runtime while still making it usable by the product.
- Technical highlights: World query routes, story/event service flows, and a clean service boundary for ambient context.
- Why it matters: Character behavior and world-state evolution can grow independently without coupling.

## Responsibilities

- world and lore retrieval support
- simulation and story helper services
- knowledge and repository access around setting data
- world-facing application logic that should not live in the persona backend

## API behavior visible in the code

The current FastAPI service exposes endpoints around:

- `GET /health`
- `GET /world/state`
- `GET /world/recent`
- `GET /world/npcs`
- `POST /world/visit`
- `POST /world/tick`
- `POST /world/command`
- `GET /world/command/{command_id}`
- `GET /world/commands`
- `POST /world/emit`
- `GET /world/knowledge/universe`
- story state, event history, event creation, event advance, and participation endpoints under `/world/story/*`

The route layer is explicitly composed from separate router modules for health, commands, events, knowledge, queries, story, visits, and ticks.
That is a small but useful signal that world concerns are being treated as a service surface rather than a collection of ad hoc helper functions.

## Directory snapshot

| Path | Role |
| --- | --- |
| `app/` | Main service implementation |
| `app/api/routes/` | FastAPI route modules |
| `content/` | Source content used by the service |
| `planner/` | Planning-oriented support material |
| `tools/` | Utility scripts and helpers |
| `server.py` | Importable service entrypoint |

## Development

Install dependencies from `requirements.txt`, then run the FastAPI app with your preferred ASGI launcher.
The service initializes world-engine runtime resources on startup and shuts them down gracefully on exit.

## System boundary

This service may enrich the wider experience with setting and world context, but it does not own character identity.
Character response strategy, safety overlays, and prompt assembly remain the responsibility of `gensokyo-persona-core`.
