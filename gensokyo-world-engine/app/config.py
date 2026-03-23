from __future__ import annotations

import os
from pathlib import Path
from typing import Dict


def _load_root_dotenv_into_environ() -> None:
    """Best-effort root `.env` loading for local development."""
    try:
        here = Path(__file__).resolve()
        root = here.parent.parent.parent
        dotenv = root / ".env"
        if not dotenv.exists() or not dotenv.is_file():
            return

        text = dotenv.read_text(encoding="utf-8", errors="replace")
        for raw_line in text.splitlines():
            line = raw_line.strip()
            if not line or line.startswith("#") or "=" not in line:
                continue
            key, value = line.split("=", 1)
            name = key.strip()
            if not name or name.startswith("#") or name in os.environ:
                continue
            parsed = value.strip()
            if parsed and parsed[0] not in ("'", '"') and " #" in parsed:
                parsed = parsed.split(" #", 1)[0].rstrip()
            if len(parsed) >= 2 and ((parsed[0] == parsed[-1] == '"') or (parsed[0] == parsed[-1] == "'")):
                parsed = parsed[1:-1]
            os.environ[name] = parsed
    except Exception:
        return


_load_root_dotenv_into_environ()


def env(name: str, default: str = "") -> str:
    return str(os.environ.get(name, default) or "")


SUPABASE_URL = env("WORLD_SUPABASE_URL") or env("SUPABASE_URL")
SUPABASE_SERVICE_ROLE_KEY = env("WORLD_SUPABASE_SERVICE_ROLE_KEY") or env("SUPABASE_SERVICE_ROLE_KEY")
SUPABASE_SCHEMA = env("SUPABASE_SCHEMA", "public")
WORLD_ENGINE_SECRET = env("GENSOKYO_WORLD_ENGINE_SECRET", "")


def require_supabase() -> None:
    if not SUPABASE_URL or not SUPABASE_SERVICE_ROLE_KEY:
        raise RuntimeError("SUPABASE_URL / SUPABASE_SERVICE_ROLE_KEY missing")


def postgrest_base_url() -> str:
    return SUPABASE_URL.rstrip("/") + "/rest/v1"


def rpc_url(fn: str) -> str:
    return postgrest_base_url().rstrip("/") + f"/rpc/{fn}"


def auth_headers() -> Dict[str, str]:
    return {
        "apikey": SUPABASE_SERVICE_ROLE_KEY,
        "Authorization": f"Bearer {SUPABASE_SERVICE_ROLE_KEY}",
        "Content-Type": "application/json",
        "Accept": "application/json",
        "Accept-Profile": SUPABASE_SCHEMA,
        "Content-Profile": SUPABASE_SCHEMA,
    }
