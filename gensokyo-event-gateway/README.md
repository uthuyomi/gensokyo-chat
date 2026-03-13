# gensokyo-event-gateway (local)

WebSocket gateway that streams ordered world events from Supabase (`world_event_log`).

## Run (local)

1) Install deps

```powershell
cd gensokyo-event-gateway
npm install
```

2) Set env vars (example; reads `../.env` by default in scripts)

```powershell
$env:SUPABASE_URL="..."
$env:SUPABASE_SERVICE_ROLE_KEY="..."
$env:GENSOKYO_EVENT_GATEWAY_PORT="8787"
```

3) Build & start

```powershell
npm run build
npm run start
```

Default WS URL: `ws://127.0.0.1:8787`

