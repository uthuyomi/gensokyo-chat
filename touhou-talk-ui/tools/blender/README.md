# Blender tools

This directory contains Blender-related helper scripts and job assets used by the `touhou-talk-ui` workspace.

## Quick Read

- Project summary: Blender-side support material for asset preparation workflows.
- Scope: Keeps content-pipeline tooling separate from runtime and product logic.
- Technical highlights: Helper scripts and batch/job assets for Blender-oriented processing.
- Why it matters: Asset preparation remains reproducible and isolated from the application core.

## Purpose

These tools support model and asset preparation workflows around the frontend project.
They are intentionally separate from chat runtime logic.

## What is here

| Path | Role |
| --- | --- |
| `run.ps1` | Helper entrypoint for local Blender-side tasks |
| `jobs/` | Job definitions or batch assets for Blender workflows |

## Project position

Use this directory for content-pipeline work such as model or scene preparation.
For persona behavior, prompt logic, and runtime control, the authoritative implementation lives in `gensokyo-persona-core`.
