from __future__ import annotations

from typing import Any, Dict, List, Optional

from content_loader import (
    load_events as load_events_from_content,
    load_locations as load_locations_from_content,
    load_relationships as load_relationships_from_content,
)

_LOC_CACHE: Optional[Dict[str, Any]] = None
_EVENT_CACHE: Optional[List[Dict[str, Any]]] = None
_REL_CACHE: Optional[List[Dict[str, Any]]] = None


def load_locations() -> Dict[str, Any]:
    global _LOC_CACHE
    if _LOC_CACHE is not None:
        return _LOC_CACHE
    data = load_locations_from_content()
    _LOC_CACHE = data if isinstance(data, dict) else {"locations": [], "sub_locations": []}
    return _LOC_CACHE


def load_events() -> List[Dict[str, Any]]:
    global _EVENT_CACHE
    if _EVENT_CACHE is not None:
        return _EVENT_CACHE
    _EVENT_CACHE = load_events_from_content()
    return _EVENT_CACHE


def load_relationships() -> List[Dict[str, Any]]:
    global _REL_CACHE
    if _REL_CACHE is not None:
        return _REL_CACHE
    raw = load_relationships_from_content()
    _REL_CACHE = raw if isinstance(raw, list) else []
    return _REL_CACHE
