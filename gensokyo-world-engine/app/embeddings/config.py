from __future__ import annotations

from app.config import env


OPENAI_API_KEY = env("OPENAI_API_KEY")
WORLD_EMBEDDING_MODEL = env("WORLD_EMBEDDING_MODEL", "text-embedding-3-small")
WORLD_EMBEDDING_BATCH_SIZE = int(env("WORLD_EMBEDDING_BATCH_SIZE", "32") or "32")
WORLD_EMBEDDING_JOB_LIMIT = int(env("WORLD_EMBEDDING_JOB_LIMIT", "128") or "128")
WORLD_EMBEDDING_WORLD_ID = env("WORLD_EMBEDDING_WORLD_ID", "gensokyo_main")


def require_openai_api_key() -> None:
    if not OPENAI_API_KEY:
        raise RuntimeError("OPENAI_API_KEY missing")
