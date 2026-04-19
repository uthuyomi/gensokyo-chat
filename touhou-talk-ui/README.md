# touhou-talk-ui

`touhou-talk-ui` is the main Next.js client for `gensokyo-chat`.
It provides the user-facing chat experience, stream rendering, session handling, attachment flows, relationship tooling, world-facing UI integration, and desktop packaging support.

## Quick Read

- Project summary: The main product client built on top of the shared character runtime.
- Scope: Covers chat UX, session orchestration, streaming integration, persistence, and service-facing UI routes.
- Technical highlights: Session-message pipeline design, attachment handling, relationship/world integration, and avatar-oriented metadata consumption.
- Why it matters: The frontend stays rich and stateful without taking persona ownership away from the backend.

## Executive summary

This frontend is not just the presentation layer for the project.
It is the product-facing orchestration layer that turns runtime capabilities into a usable chat experience, including persistence, attachment handling, streaming event translation, and avatar-oriented metadata consumption.

## Role in the system

This module is intentionally a thin client relative to the persona backend.
It sends conversation state to `gensokyo-persona-core` and focuses on presentation, interaction quality, and client-side product experience.

## Portfolio value

As a portfolio sample, this frontend is useful because it is not only a visual layer.
It shows how to build a polished product surface on top of a backend-owned character runtime while still handling persistence, streaming translation, attachments, and avatar-oriented metadata in a disciplined way.

## Why this architecture matters

Many AI frontends end up owning too much hidden prompt logic.
This one intentionally avoids that.
Its value comes from product orchestration, not from quietly duplicating backend behavior in the UI.

## What the UI owns

- route structure and application shell
- chat presentation and streaming UX
- session and attachment handling on the client side
- desktop packaging support through Electron
- UI-specific character catalog and frontend documents
- persistence and orchestration around session-message flows
- post-reply metadata usage such as TTS reading and VRM performance cues

## What the UI does not own

- persona prompt assembly
- character behavior selection
- safety wording logic
- backend runtime policy

Those responsibilities belong to `gensokyo-persona-core`.

## What the code currently does in the main chat flow

The main session message route is more than a thin proxy.
In the current implementation it:

1. validates the request body and resolves the active session context
2. uploads user attachments to the persona core when files are present
3. persists the user message to storage
4. forwards the turn to `/persona/chat` or `/persona/chat/stream`
5. relays stream events back to the client for live rendering
6. stores the assistant reply after completion
7. attaches TTS reading metadata and VRM performance hints
8. runs best-effort relationship and memory update tasks after the reply

That makes this frontend a product-layer orchestrator, not just a static UI shell.

## Problems this module is solving

The frontend is designed to solve product-side problems without reclaiming backend persona ownership:

- keeping the chat UX responsive and stream-friendly
- persisting sessions and messages around runtime calls
- handling attachments in a user-facing workflow
- converting runtime output into UI-friendly metadata for TTS and VRM behavior
- exposing world, relationship, and desktop flows inside one coherent client experience

## Core session-message pipeline

The main backend-facing pipeline in the UI can be read as:

1. request parsing
2. session context loading
3. attachment upload when needed
4. user message persistence
5. runtime delegation
6. stream translation or single-response handling
7. assistant message persistence
8. post-reply side effects such as relationship and memory updates

This is the heart of the application behavior.

## Persistence model in practice

The current server-side UI layer persists more than just chat text.
From the code paths under `session-message-v2`, it stores:

- user messages
- assistant messages
- attachment/link metadata inside message records
- derived state snapshots for runtime telemetry-like fields

That persistence layer is one reason this project reads more like an application system than a demo frontend.

## Key areas

| Path | Role |
| --- | --- |
| `app/` | Next.js routes and application entrypoints |
| `components/` | UI components |
| `app/api/session/[sessionId]/message/` | Main session message entrypoint |
| `lib/server/session-message-v2/` | Server-side bridge to persona APIs |
| `lib/characterCatalog.ts` | UI-facing character catalog metadata |
| `docs/` | Frontend-specific reference material |
| `tools/` | Desktop, Blender, and Unity support tooling |

## API surfaces handled by the UI layer

The frontend includes server routes that bridge to other services, including:

- chat/session APIs
- relationship import/export/reset APIs
- attachment proxy APIs
- world service proxy APIs
- DB manager proxy APIs
- desktop-only character settings and VRM asset routes

This means the frontend repo also contains application-backend glue, not only visual components.

## Relationship and world integration

The frontend also actively integrates non-chat state:

- relationship routes load trust, familiarity, and character-scoped memory
- session-message flows can trigger relationship scoring and memory updates after replies
- world helpers load `world/state` and `world/recent` data and turn them into prompt overlays
- world API routes proxy secret-bearing calls to the world-engine service

This broadens the frontend from "chat shell" into a stateful product coordinator.

## What engineers can inspect directly

The most important implementation paths are:

- `lib/server/session-message-v2/handler.ts`
- `lib/server/session-message-v2/respond.ts`
- `lib/server/session-message-v2/stream.ts`
- `lib/server/session-message-v2/retrieval.ts`
- `app/api/session/[sessionId]/message/`
- `app/api/world/`
- `app/api/relationship/`
- `app/api/desktop/`

## Development

```powershell
cd touhou-talk-ui
npm install
npm run dev
```

Useful scripts:

- `npm run build`
- `npm run start`
- `npm run desktop:dev`
- `npm run desktop:dist`

## Technology snapshot

- Next.js 16
- React 18
- TypeScript
- Electron for desktop packaging
- Supabase and OpenAI SDK integrations where needed

## Why this module matters

The frontend demonstrates how to build a rich chat product on top of a shared backend character runtime.
It keeps the user experience expressive without pulling persona control back into the UI layer.

For engineers, the interesting part is the combination of product UX, server routes, persistence, streaming translation, and avatar-oriented metadata handling in one client module.

## Evaluation lens

The strongest way to evaluate this module is not by asking whether it has many components.
It is by asking whether it turns backend runtime capabilities into a coherent product experience without collapsing architectural boundaries.

## Related modules

- backend runtime: `../gensokyo-persona-core/`
- workspace overview: `../README.md`
