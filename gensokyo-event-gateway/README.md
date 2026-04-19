# gensokyo-event-gateway

`gensokyo-event-gateway` is the event transport layer for the `gensokyo-chat` workspace.
It isolates subscriptions, WebSocket delivery, and event-facing integration concerns from both the persona backend and the UI.

## Quick Read

- Project summary: A dedicated WebSocket event gateway for live delivery and subscriptions.
- Scope: Separates event transport concerns from runtime and frontend application logic.
- Technical highlights: Authenticated connection flow, channel subscription handling, snapshot delivery, and cleanup lifecycle management.
- Why it matters: Real-time transport stays modular instead of leaking into unrelated services.

## Responsibilities

- websocket-based event delivery
- transport and subscription handling
- service-to-client event fan-out
- event integration boundaries that should stay outside persona generation

## Observed runtime behavior

From the current code, the server:

- starts a standalone WebSocket server
- requires an initial `hello` message for authentication
- allows authenticated clients to subscribe and unsubscribe by channel
- validates channel names before opening live subscriptions
- sends a snapshot on subscribe, then attaches the live stream
- cleans up hub membership when sockets close

This is a relatively small module, but it demonstrates a clean separation between authentication, protocol parsing, subscription registry management, snapshot delivery, and connection cleanup.

## Directory snapshot

| Path | Role |
| --- | --- |
| `src/ws/` | WebSocket-facing logic |
| `src/auth/` | Connection authentication helpers |
| `src/subscriptions/` | Subscription management |
| `src/streaming/` | Streaming-related transport code |
| `src/protocol/` | Gateway protocol definitions |
| `src/index.ts` | Service entrypoint |

## Development

```powershell
cd gensokyo-event-gateway
npm install
npm run build
npm run dev
```

## Project position

This module is supporting infrastructure.
It is important for real-time delivery, but it is not where character identity, prompt logic, or safety policy are defined.
