# gensokyo-db-manager

`gensokyo-db-manager` contains database-oriented service logic and operational helpers for the `gensokyo-chat` workspace.
It exists to separate data maintenance and repository concerns from both the frontend and the character runtime.

## Quick Read

- Project summary: A database-facing service for ingest, review, schema assistance, scheduling, and operational workflows.
- Scope: Separates durable data operations and review pipelines from request-path product services.
- Technical highlights: Claims workflows, ingest/discovery flows, ops controls, scheduler-driven maintenance, and audit-style endpoints.
- Why it matters: Data quality and operations are treated as first-class system concerns rather than hidden scripts.

## Responsibilities

- database-facing service logic
- repository and persistence helpers
- scheduled or maintenance-oriented workflows
- schema and operational support tasks

## API behavior visible in the code

The current service exposes route groups for:

- health checks
- ingest workflows such as `/ingest/web-page`
- discovery source registration and execution
- claim ingestion, review, conflict checks, and auto-review
- schema suggestion and migration draft support
- operational policies, jobs, alerts, scheduler inspection, and manual scheduler runs
- audit coverage preview and report output
- interaction signal ingestion

The implementation also shows that this service is not purely passive CRUD.
It starts a scheduler on service startup, exposes operational control routes, and supports review-style workflows around claims and ingest quality.

## Directory snapshot

| Path | Role |
| --- | --- |
| `app/repository.py` | Repository layer |
| `app/service.py` | Main service logic |
| `app/scheduler.py` | Scheduled workflows |
| `app/api/` | API-related modules |
| `tests/` | Test coverage for DB-oriented workflows |

## Development

Install dependencies from `requirements.txt`, then run the FastAPI app with your preferred ASGI launcher.
On startup, the service also starts its scheduler, which is one reason it is kept separate from the request-path services.

## Project position

This module supports operations and data workflows.
It is not part of the main character generation path; persona control and response generation stay in `gensokyo-persona-core`.
