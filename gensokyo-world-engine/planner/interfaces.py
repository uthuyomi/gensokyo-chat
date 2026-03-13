from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime
from typing import Any, Dict, List, Optional


@dataclass(frozen=True)
class ActorRef:
    kind: str  # npc|user|system
    id: Optional[str] = None


@dataclass
class NpcSnapshot:
    npc_id: str
    location_id: str
    action: Optional[str] = None
    emotion: Optional[str] = None
    updated_at: Optional[str] = None


@dataclass
class UserSnapshot:
    user_id: str
    location_id: str
    sub_location_id: Optional[str] = None
    inventory: Dict[str, Any] = field(default_factory=dict)
    updated_at: Optional[str] = None


@dataclass
class PlannedEvent:
    """
    A DB-append intent. The world engine is responsible for appending this into world_event_log.
    """

    type: str  # npc_action|npc_say|system|...
    actor: ActorRef
    location_id: Optional[str]
    ts: datetime
    payload: Dict[str, Any] = field(default_factory=dict)


@dataclass
class PlannerContext:
    world_id: str
    layer_id: str
    location_id: str
    source_event: Dict[str, Any]
    npcs_here: List[NpcSnapshot]
    user: Optional[UserSnapshot]
    now: datetime
    # Optional: player↔character relation snapshots keyed by npc_id. Filled by world-engine (server.py).
    player_relations: Dict[str, Dict[str, Any]] = field(default_factory=dict)

