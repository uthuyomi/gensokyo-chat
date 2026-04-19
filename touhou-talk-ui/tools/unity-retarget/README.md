# Unity retarget tools

This directory contains Unity-side support files for retargeting and related asset workflows in the `touhou-talk-ui` workspace.

## Quick Read

- Project summary: Unity-side support for avatar or motion retarget workflows.
- Scope: Isolates retarget and asset-pipeline concerns from the chat application layers.
- Technical highlights: Drop-in support files for Unity-based retarget work.
- Why it matters: Character presentation assets can evolve without polluting runtime/business logic.

## Purpose

The tools here help with motion, rig, or avatar retarget tasks that belong to the asset pipeline rather than the chat runtime.

## What is here

| Path | Role |
| --- | --- |
| `UnityDropIn/` | Unity-side files intended to be dropped into a project for retarget work |

## Project position

Use this directory when working on asset-side retargeting or avatar preparation.
Character response behavior, locale control, and prompt execution remain the responsibility of `gensokyo-persona-core`.
