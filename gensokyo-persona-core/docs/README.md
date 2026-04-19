# gensokyo-persona-core docs

This directory collects architecture notes, implementation plans, schema drafts, and migration documents for the character runtime backend.
It is the best place to understand why the backend is structured the way it is, not just how the code is arranged today.

## Quick Read

- Project summary: The design-history and architecture reference for the character runtime backend.
- Scope: Captures architectural intent, migration direction, and implementation rationale alongside the code.
- Technical highlights: Design principles, API plans, character-model documentation, and testing/evaluation planning.
- Why it matters: It shows that the backend was designed deliberately, not only grown by iteration.

## What you will find here

- architecture and design principles
- character definition and asset model notes
- API specifications
- migration and refactor planning
- testing and evaluation plans

## Suggested reading order

1. `01-overview-and-goals.md`
2. `04-design-principles.md`
3. `05-architecture.md`
4. `06-character-definition-model.md`
5. `09-api-and-directory-plan.md`
6. `11-character-profile-schema.md`
7. `13-persona-chat-api-spec.md`
8. `15-implementation-task-list.md`
9. `16-test-plan.md`

## How to use these docs

Start here if you want to understand:

- why persona assembly moved from UI to backend
- how character assets, locale behavior, safety, and strategy fit together
- which APIs are intended to be shared across clients
- which parts are stable architecture versus active implementation work

## Reading note

Some documents capture design intent while others capture migration steps from earlier project phases.
Treat this directory as architecture context and decision history rather than a strict mirror of current code at every line.
