# Gensokyo world docs

This directory contains frontend-side planning and reference material for world-layer features in the `gensokyo-chat` workspace.
It covers how world context may be represented, surfaced, or integrated across UI and supporting services.

## Quick Read

- Project summary: Frontend-side planning docs for world-context features.
- Scope: Maps world-state ideas into UI and service integration plans.
- Technical highlights: World-layer architecture notes, schema thinking, integration routes, and planning references.
- Why it matters: It shows deliberate expansion planning rather than unstructured feature accumulation.

## Topics covered

- world-layer architecture
- Supabase schema and world data modeling
- event generation and simulation plans
- UI integration points
- observability, cost, and testing considerations

## Scope boundary

These documents are about world context and integration strategy.
They do not replace the backend-owned character runtime design in `gensokyo-persona-core`.

## Suggested starting point

Begin with `00_stack_and_phased_architecture.md`, then move into schema, API, and integration documents as needed.
