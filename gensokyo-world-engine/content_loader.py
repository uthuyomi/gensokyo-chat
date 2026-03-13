from __future__ import annotations

import json
import os
from pathlib import Path
from typing import Any, Dict, List, Optional


def env(name: str, default: str = "") -> str:
    return str(os.environ.get(name, default) or "")


def _default_content_dir() -> Path:
    return Path(__file__).resolve().parent / "content"


def content_root() -> Path:
    """
    Optional external content root for authoring.

    Example:
      GENSOKYO_CONTENT_ROOT=D:\\souce\\Project-Sigmaris\\touhou-talk-ui\\world\\layers\\gensokyo
    """

    raw = (env("GENSOKYO_CONTENT_ROOT", "") or "").strip()
    if not raw:
        return _default_content_dir()
    return Path(raw)


def _read_json(path: Path) -> Any:
    with path.open("r", encoding="utf-8") as f:
        return json.load(f)


def load_locations() -> Dict[str, Any]:
    root = content_root()
    p = root / "locations.json"
    if p.exists():
        data = _read_json(p)
        return data if isinstance(data, dict) else {"locations": [], "sub_locations": []}

    # Support split files (proposal in docs)
    locs = root / "locations.json"
    subs = root / "sub_locations.json"
    out: Dict[str, Any] = {"locations": [], "sub_locations": []}
    if locs.exists():
        d = _read_json(locs)
        if isinstance(d, dict) and isinstance(d.get("locations"), list):
            out["locations"] = d["locations"]
    if subs.exists():
        d = _read_json(subs)
        if isinstance(d, dict) and isinstance(d.get("sub_locations"), list):
            out["sub_locations"] = d["sub_locations"]
    return out


def load_events() -> List[Dict[str, Any]]:
    root = content_root()
    p = root / "events.json"
    if p.exists():
        data = _read_json(p)
        if isinstance(data, dict) and isinstance(data.get("events"), list):
            return [e for e in data["events"] if isinstance(e, dict) and isinstance(e.get("id"), str)]
        return []

    # Support event_defs directory (proposal in docs)
    event_defs = root / "event_defs"
    if not event_defs.exists() or not event_defs.is_dir():
        return []
    out: List[Dict[str, Any]] = []
    for fp in sorted(event_defs.glob("*.json")):
        try:
            d = _read_json(fp)
            if isinstance(d, dict) and isinstance(d.get("id"), str) and d.get("id"):
                out.append(d)
        except Exception:
            continue
    return out


def load_relationships() -> List[Dict[str, Any]]:
    """
    Optional NPC↔NPC relationship graph for weighting dialogue/behavior.

    Expected file:
      relationships.json

    Example:
      {
        "relationships": [
          { "character_a": "reimu", "character_b": "marisa", "trust": 0.75, "caution": 0.25, "familiarity": 0.9 }
        ]
      }
    """

    root = content_root()
    p = root / "relationships.json"
    if not p.exists():
        return []
    try:
        data = _read_json(p)
    except Exception:
        return []
    if not isinstance(data, dict) or not isinstance(data.get("relationships"), list):
        return []
    out: List[Dict[str, Any]] = []
    for r in data.get("relationships") or []:
        if not isinstance(r, dict):
            continue
        a = r.get("character_a")
        b = r.get("character_b")
        if not (isinstance(a, str) and a.strip() and isinstance(b, str) and b.strip()):
            continue
        out.append(r)
    return out
