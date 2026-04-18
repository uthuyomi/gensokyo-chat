from __future__ import annotations

import hashlib
import json
import threading
from typing import Any, Optional


class PromptCache:
    def __init__(self, *, max_items: int = 512) -> None:
        self._max_items = max(16, int(max_items))
        self._lock = threading.Lock()
        self._items: dict[str, str] = {}

    def make_key(self, payload: Any) -> str:
        encoded = json.dumps(payload, ensure_ascii=False, sort_keys=True, separators=(",", ":")).encode("utf-8")
        return hashlib.sha256(encoded).hexdigest()

    def get(self, key: str) -> Optional[str]:
        with self._lock:
            return self._items.get(key)

    def put(self, key: str, value: str) -> None:
        with self._lock:
            self._items[key] = value
            if len(self._items) > self._max_items:
                oldest = next(iter(self._items.keys()))
                self._items.pop(oldest, None)


_PROMPT_CACHE: Optional[PromptCache] = None


def get_prompt_cache() -> PromptCache:
    global _PROMPT_CACHE
    if _PROMPT_CACHE is None:
        _PROMPT_CACHE = PromptCache()
    return _PROMPT_CACHE
