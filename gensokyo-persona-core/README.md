# gensokyo-persona-core

`gensokyo-persona-core` is the shared FastAPI backend that powers character responses in `gensokyo-chat`.
It owns runtime orchestration, character asset loading, prompt assembly, safety overlays, locale-aware response shaping, streaming APIs, and a growing set of runtime-side IO capabilities.

## Quick Read

- Project summary: The central character runtime service for the entire workspace.
- Scope: Owns the backend response pipeline, API surface, character asset model, and runtime control layers.
- Technical highlights: Situation-aware routing, safety overlays, response strategy design, structured prompt assembly, streaming support, and retrieval/attachment integration.
- Why it matters: This module turns character behavior from scattered prompt logic into a maintainable system.

## Executive summary

This module is the technical center of the repository.
Its job is not only to generate text, but to decide how a character should respond, under what constraints, in which locale, with what metadata, and with which supporting retrieval or attachment context.

## Role in the system

This module is the authoritative character runtime.
Frontend clients do not build persona prompts on their own. Instead, they send conversation state and the backend resolves how the character should respond.

## Portfolio value

If the repository is read as a portfolio, this module is the centerpiece.
It demonstrates the shift from UI-owned prompting to a backend-owned runtime with explicit layers for character data, situation analysis, safety, strategy, rendering, and retrieval support.

## Why this architecture matters

Character AI systems often degrade when prompt logic is allowed to spread across clients.
This module pushes in the opposite direction: one runtime, one behavior pipeline, multiple surfaces.
That makes the system easier to reason about, easier to evolve, and easier to keep coherent.

## What this service owns

- chat and streaming endpoints
- per-character backend assets
- situation analysis and intent handling
- response strategy and policy selection
- safety overlays and guarded behavior
- locale-aware wording and presentation
- attachment upload and parsing
- runtime-side web and GitHub retrieval helpers
- relationship scoring and operator-side overrides

## Problems this module is solving

This backend exists to address common failure modes in character AI products:

- character drift between clients
- prompt logic becoming unmaintainable in the UI layer
- safety decisions being scattered across product surfaces
- localized expression being handled as copy variation instead of runtime behavior
- richer client features depending on metadata that a raw text-only backend does not expose

## Core runtime pipeline

At a systems level, the runtime is organized into distinct stages:

1. character asset resolution
2. locale resolution
3. history normalization and summarization
4. situation assessment
5. behavior resolution
6. safety overlay construction
7. response strategy construction
8. prompt assembly
9. model invocation
10. reply rendering
11. structured metadata return

This separation is one of the most important engineering ideas in the repository.

## Situation and control logic in practice

The current implementation does not rely on a single vague "AI decides" step.
Instead, the code contains explicit control logic for:

- SOS and distress signals
- dependency-style cues
- medical and legal topics
- technical and informational requests
- playful, meta, roleplay, and normal interactions
- age-sensitive handling for child, teen, and adult contexts

Those signals feed both safety and response-strategy decisions before generation happens.

## Public API surface

| Endpoint | Purpose |
| --- | --- |
| `POST /persona/chat` | Standard chat response |
| `POST /persona/chat/stream` | Streaming chat response |
| `POST /persona/intent` | Lightweight intent and situation inspection |
| `POST /persona/relationship/score` | Relationship scoring helper |
| `POST /persona/operator/override` | Operator-side control override |
| `GET /persona/characters` | Character catalog |
| `GET /persona/characters/{character_id}` | Character detail |
| `GET /persona/session/{session_id}` | Session snapshot |
| `POST /io/upload` | Attachment upload |
| `POST /io/parse` | Attachment parsing |
| `GET /io/attachment/{attachment_id}` | Attachment fetch |
| `POST /io/web/search` | Web search helper |
| `POST /io/web/fetch` | Web fetch and summarization helper |
| `POST /io/web/rag` | Web RAG-style retrieval helper |
| `POST /io/github/repos` | GitHub repository search helper |
| `POST /io/github/code` | GitHub code search helper |

## Request-to-reply behavior

The current `CharacterChatRuntime` flow is roughly:

1. resolve the character asset from the backend registry
2. resolve locale profile from client context
3. normalize recent history and build a short session summary
4. assess situation from message, chat mode, and user profile
5. resolve behavior, safety overlay, and response strategy
6. assemble a system prompt from layered runtime inputs
7. call the LLM with merged generation parameters
8. post-process the raw reply through the character renderer
9. return the reply plus structured runtime metadata

For streaming, the same turn analysis is performed up front, then the stream is emitted with runtime metadata attached separately.

## Post-generation shaping

Generation is not the final step.
After the model returns text, the renderer currently applies:

- safety rewriting
- child-text adaptation for Japanese child-facing cases
- consistency checking against the character profile

This is an important distinction: the runtime treats generation as one stage inside a larger response system.

## Retrieval and IO support

The runtime is also expanding beyond pure text generation.
From the current API surface, it already supports:

- file upload and parse flows for attachments
- web search and web fetch helpers
- a web RAG-style endpoint
- GitHub repository and code retrieval helpers

This means the backend is gradually becoming a character runtime plus controlled external-information layer, not just a prompt wrapper.

## Metadata and state outputs

The runtime currently emits enough structure to support downstream product behavior.
Depending on the path, metadata can include:

- situation and strategy snapshots
- safety and behavior snapshots
- locale resolution outputs
- rendering hints
- state-related fields later persisted by the UI layer

This gives clients more than a string; it gives them a controlled view of why the reply took the shape it did.

## What the metadata contains

The runtime metadata is not just debug noise.
It includes structured signals such as:

- interaction type
- safety risk
- strategy snapshot
- situation snapshot
- behavior snapshot
- safety snapshot
- resolved locale
- locale style snapshot
- rendering hints such as TTS style or animation hints

This makes the service useful not only for text generation but also for downstream UI behavior and instrumentation.

## Why this is a strong engineering sample

This module combines several types of work that are often split across teams:

- API surface design
- runtime pipeline design
- prompt assembly architecture
- structured asset loading
- safety-aware response control
- streaming response handling
- metadata design for downstream clients

That breadth makes it a good representation of systems-oriented application engineering.

## What engineers can inspect directly

The highest-signal code paths are:

- `persona_core/server_persona_os.py` for API surface and service composition
- `persona_core/runtime/character_chat_runtime.py` for the response pipeline
- `persona_core/character_runtime/registry.py` for asset loading
- `persona_core/prompting/` for prompt composition
- `persona_core/rendering/` for post-generation shaping
- `persona_core/safety/`, `persona_core/situation/`, and `persona_core/strategy/` for the control layers

## Directory guide

| Path | Role |
| --- | --- |
| `persona_core/server_persona_os.py` | FastAPI entrypoint |
| `persona_core/runtime/` | Core runtime flow |
| `persona_core/character_runtime/` | Character asset loading and schemas |
| `persona_core/characters/` | Backend source of truth for characters |
| `persona_core/behavior/` | Behavior resolution |
| `persona_core/situation/` | Situation analysis |
| `persona_core/strategy/` and `persona_core/policy/` | Response strategy and policy |
| `persona_core/safety/` | Safety overlays |
| `persona_core/prompting/` | Prompt block assembly |
| `persona_core/rendering/` | Response shaping |
| `persona_core/memory/` | Memory and recall helpers |
| `persona_core/storage/` | Supabase-backed persistence and auth helpers |
| `persona_core/evaluation/` | Evaluation and regression helpers |
| `docs/` | Architecture and planning documents |

## Character asset model

Each character is defined under:

```text
persona_core/characters/<character_id>/
```

Typical files include:

```text
profile.json
world.json
prompts.json
gen_params.json
control_plane_en.json
soul.json
style.json
safety.json
situational_behavior.json
locales/
localized_prompts/
```

The goal is to keep character data structured enough for runtime composition while still being practical to edit by hand.

In code, the registry only treats directories with a `profile.json` as valid characters, then lazily loads and caches the parsed assets for runtime use.

## Local development

Install dependencies from `requirements.txt`, then run:

```powershell
cd gensokyo-persona-core
.\.venv\Scripts\python -m uvicorn persona_core.server_persona_os:app --host 127.0.0.1 --port 8000 --reload
```

## Why this module matters

This backend is the main architectural decision in the repository.
By centralizing character behavior here, the project can support multiple clients without duplicating persona logic or letting character identity drift between interfaces.

From an engineering portfolio perspective, this module shows work across API design, runtime orchestration, prompt architecture, safety layering, file-based character modeling, streaming, and retrieval integration.

## Evaluation lens

The best way to evaluate this module is not by asking whether it can call a model.
It is by asking whether it turns character behavior into a maintainable system.
That is the bar this module is trying to meet.

## Related reading

See `docs/README.md` for the document index and architecture notes.
