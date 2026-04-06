from __future__ import annotations

import hashlib
import json
from datetime import datetime, timezone
from typing import Any, Dict, List, Optional, Tuple

from fastapi import HTTPException

from app.config import WORLD_ENGINE_SECRET, env
from app.content_store import load_events, load_locations


def is_uuid_like(value: Optional[str]) -> bool:
    if not value or not isinstance(value, str):
        return False
    s = value.strip()
    if len(s) != 36:
        return False
    parts = s.split("-")
    if len(parts) != 5:
        return False
    lengths = [8, 4, 4, 4, 12]
    for part, size in zip(parts, lengths):
        if len(part) != size:
            return False
        try:
            int(part, 16)
        except Exception:
            return False
    return True


def check_secret(x_world_secret: Optional[str]) -> None:
    if not WORLD_ENGINE_SECRET:
        return
    if not x_world_secret or x_world_secret != WORLD_ENGINE_SECRET:
        raise HTTPException(status_code=403, detail="Forbidden")


def now_utc() -> datetime:
    return datetime.now(timezone.utc)


def parse_user_time(value: Optional[str]) -> Optional[datetime]:
    if not value:
        return None
    try:
        dt = datetime.fromisoformat(value)
        if dt.tzinfo is None:
            dt = dt.replace(tzinfo=timezone.utc)
        return dt.astimezone(timezone.utc)
    except Exception:
        return None


def day_part(dt_utc: datetime) -> str:
    hour = dt_utc.hour
    if 5 <= hour < 10:
        return "morning"
    if 10 <= hour < 17:
        return "day"
    if 17 <= hour < 21:
        return "evening"
    return "night"


def season_of(dt_utc: datetime) -> str:
    month = dt_utc.month
    if month in (3, 4, 5):
        return "spring"
    if month in (6, 7, 8):
        return "summer"
    if month in (9, 10, 11):
        return "autumn"
    return "winter"


def base_event_budget(delta_sec: int) -> int:
    if delta_sec < 10 * 60:
        return 1 if delta_sec >= 60 else 0
    if delta_sec < 2 * 60 * 60:
        return 2
    if delta_sec < 8 * 60 * 60:
        return 5
    return 8


def density_multiplier(density: str) -> float:
    value = (density or "").strip().lower()
    if value == "low":
        return 0.5
    if value == "high":
        return 1.5
    return 1.0


def compute_event_budget(delta_sec: int, density: str) -> int:
    scaled = int(round(base_event_budget(delta_sec) * density_multiplier(density)))
    return max(0, min(scaled, 8))


def stable_seed(*parts: str) -> int:
    joined = "|".join([part for part in parts if part is not None])
    digest = hashlib.sha256(joined.encode("utf-8")).hexdigest()
    return int(digest[:8], 16)


def log_world_visit_debug(data: Dict[str, Any]) -> None:
    if env("GENSOKYO_WORLD_LOG_VISIT_DEBUG", "1").strip() in ("0", "false", "False"):
        return
    try:
        print("[world.visit]", json.dumps(data, ensure_ascii=False, separators=(",", ":")))
    except Exception:
        pass


def location_density(location_id: str) -> str:
    data = load_locations()
    for loc in data.get("locations", []) or []:
        if isinstance(loc, dict) and loc.get("id") == location_id:
            return str(loc.get("density") or "med")
    return "med"


def default_npcs_for_location(location_id: str) -> List[str]:
    out: List[str] = []
    data = load_locations()
    for loc in data.get("locations", []) or []:
        if not isinstance(loc, dict) or str(loc.get("id") or "") != location_id:
            continue
        default_npcs = loc.get("default_npcs") if isinstance(loc.get("default_npcs"), list) else []
        for npc_id in default_npcs:
            if isinstance(npc_id, str) and npc_id.strip() and npc_id.strip() not in out:
                out.append(npc_id.strip())

    if out:
        return out

    try:
        events = load_events()
    except Exception:
        return out
    for event in events:
        if not isinstance(event, dict) or str(event.get("location_id") or "") != location_id:
            continue
        participants = event.get("participants") if isinstance(event.get("participants"), dict) else {}
        required = participants.get("required") if isinstance(participants.get("required"), list) else []
        for npc_id in required:
            if isinstance(npc_id, str) and npc_id.strip() and npc_id.strip() not in out:
                out.append(npc_id.strip())
    return out


def check_sub_location(parent_location_id: str, sub_location_id: Optional[str]) -> Optional[str]:
    if not sub_location_id:
        return None
    data = load_locations()
    for sub in data.get("sub_locations", []) or []:
        if isinstance(sub, dict) and sub.get("id") == sub_location_id:
            if sub.get("parent") == parent_location_id:
                return str(sub_location_id)
            return None
    return None


def event_constraints_ok(defn: Dict[str, Any], world_state: Dict[str, Any]) -> bool:
    constraints = defn.get("constraints") if isinstance(defn.get("constraints"), dict) else {}
    tod = str(world_state.get("time_of_day") or "")
    weather = str(world_state.get("weather") or "")
    if isinstance(constraints.get("time_of_day"), list) and constraints["time_of_day"]:
        if tod not in [str(x) for x in constraints["time_of_day"]]:
            return False
    if isinstance(constraints.get("weather_not"), list) and constraints["weather_not"]:
        if weather in [str(x) for x in constraints["weather_not"]]:
            return False
    return True


def event_participants(defn: Dict[str, Any]) -> List[str]:
    participants = defn.get("participants")
    if not isinstance(participants, dict):
        return []
    required = participants.get("required")
    if not isinstance(required, list):
        return []
    return [str(x) for x in required if isinstance(x, str) and x.strip()]


def extract_event_type(row: Dict[str, Any]) -> Optional[str]:
    payload = row.get("payload")
    if isinstance(payload, dict) and isinstance(payload.get("event_type"), str):
        return str(payload["event_type"])
    return None


def extract_summary(row: Dict[str, Any]) -> str:
    payload = row.get("payload")
    if isinstance(payload, dict) and isinstance(payload.get("summary"), str):
        return str(payload["summary"]).strip()
    return ""


def recent_weight(event_id: str, recent_event_types: List[str]) -> float:
    if event_id in recent_event_types[:3]:
        return 0.05
    if event_id in recent_event_types[:10]:
        return 0.2
    return 1.0


def effect_location_changes(defn: Dict[str, Any]) -> List[Tuple[str, str]]:
    effects = defn.get("effects") if isinstance(defn.get("effects"), dict) else {}
    state = effects.get("state") if isinstance(effects.get("state"), list) else []
    changes: List[Tuple[str, str]] = []
    for effect in state:
        if not isinstance(effect, dict):
            continue
        target = effect.get("target")
        patch = effect.get("set") if isinstance(effect.get("set"), dict) else {}
        if isinstance(target, str) and isinstance(patch.get("location_id"), str) and patch.get("location_id"):
            changes.append((target, str(patch.get("location_id"))))
    return changes


def apply_effects_world(world_state: Dict[str, Any], defn: Dict[str, Any]) -> Dict[str, Any]:
    effects = defn.get("effects") if isinstance(defn.get("effects"), dict) else {}
    world = effects.get("world") if isinstance(effects.get("world"), list) else []
    out = dict(world_state)
    for effect in world:
        if not isinstance(effect, dict):
            continue
        patch = effect.get("set") if isinstance(effect.get("set"), dict) else {}
        for key in ("time_of_day", "weather", "season", "moon_phase", "anomaly"):
            if key in patch:
                out[key] = patch.get(key)
    return out


def npc_effect_patches(defn: Dict[str, Any]) -> List[Tuple[str, Dict[str, Any]]]:
    effects = defn.get("effects") if isinstance(defn.get("effects"), dict) else {}
    state = effects.get("state") if isinstance(effects.get("state"), list) else []
    out: List[Tuple[str, Dict[str, Any]]] = []
    for effect in state:
        if not isinstance(effect, dict):
            continue
        target = effect.get("target")
        patch = effect.get("set") if isinstance(effect.get("set"), dict) else {}
        if isinstance(target, str) and patch:
            out.append((target, patch))
    return out
