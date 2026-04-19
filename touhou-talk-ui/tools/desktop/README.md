# Touhou Talk Desktop

This directory contains the Electron wrapper used to package `touhou-talk-ui` as a Windows desktop application.

## Quick Read

- Project summary: The desktop packaging layer for the main chat client.
- Scope: Adapts the web product into a packaged Windows application with controlled runtime environment handling.
- Technical highlights: Electron shell, dev runner, packaging preparation, and user-data-based env management.
- Why it matters: The same client experience can be reused beyond the browser without forking the architecture.

## Purpose

The desktop build provides a local application shell around the web client while preserving the same backend-first character architecture used by the browser version.

## What is here

| Path | Role |
| --- | --- |
| `main.cjs` | Electron main-process entrypoint |
| `dev-runner.cjs` | Local development launcher |
| `prepare-next.cjs` | Build preparation for desktop packaging |
| `default.env` | Default desktop environment template |
| `.bundle/` | Files bundled into packaged builds |

## Development

From `touhou-talk-ui/`:

```powershell
npm install
npm run desktop:dev
```

`desktop:dev` starts a local Next.js server on an available port, then launches Electron against that local instance.

## Environment handling

On launch, Electron sets:

- `TOUHOU_DESKTOP_USERDATA_DIR`
- `TOUHOU_DESKTOP_ENV_PATH`

The runtime environment file is typically stored in the app `userData` directory as `touhou-talk.env`.

## Packaging note

Packaged builds can include bundled defaults via `tools/desktop/.bundle/default.env`.
User environment values only fill missing keys and do not overwrite bundled defaults.

## Security note

Do not ship high-privilege secrets such as service-role credentials in bundled desktop defaults.
