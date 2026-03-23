from __future__ import annotations

from typing import Any, Dict, List, Optional

from pydantic import BaseModel, Field


class StoryBeatInput(BaseModel):
    beat_code: str
    beat_kind: str = Field(default="scene")
    title: str
    summary: str
    location_id: Optional[str] = None
    actor_ids: List[str] = Field(default_factory=list)
    is_required: bool = False
    status: str = Field(default="planned")
    happens_at: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)


class StoryPhaseInput(BaseModel):
    phase_code: str
    phase_order: int = Field(ge=1)
    title: str
    summary: str
    status: str = Field(default="pending")
    start_condition: Dict[str, Any] = Field(default_factory=dict)
    end_condition: Dict[str, Any] = Field(default_factory=dict)
    required_beats: List[str] = Field(default_factory=list)
    allowed_locations: List[str] = Field(default_factory=list)
    active_cast: List[str] = Field(default_factory=list)
    starts_at: Optional[str] = None
    ends_at: Optional[str] = None
    metadata: Dict[str, Any] = Field(default_factory=dict)
    beats: List[StoryBeatInput] = Field(default_factory=list)


class StoryCastInput(BaseModel):
    character_id: str
    role_type: str
    knowledge_level: str = Field(default="aware")
    must_appear: bool = False
    primary_location_id: Optional[str] = None
    availability: Dict[str, Any] = Field(default_factory=dict)
    notes: Optional[str] = None


class StoryActionInput(BaseModel):
    action_code: str
    title: str
    description: str
    action_kind: str = Field(default="talk")
    location_id: Optional[str] = None
    actor_id: Optional[str] = None
    phase_code: Optional[str] = None
    is_repeatable: bool = False
    is_active: bool = True
    result_summary: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)


class StoryHistoryInput(BaseModel):
    history_kind: str = Field(default="canon_fact")
    fact_summary: str
    location_id: Optional[str] = None
    actor_ids: List[str] = Field(default_factory=list)
    phase_code: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    committed_at: Optional[str] = None


class CharacterMemoryInput(BaseModel):
    character_id: str
    summary: str
    memory_type: str = Field(default="event")
    importance: int = Field(default=1, ge=1, le=10)
    stance: Optional[str] = None
    knows_truth: bool = True
    history_ref: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)


class StoryEventCreateRequest(BaseModel):
    world_id: str
    event_code: str
    title: str
    theme: str
    canon_level: str = Field(default="official")
    status: str = Field(default="draft")
    start_at: Optional[str] = None
    end_at: Optional[str] = None
    lead_location_id: Optional[str] = None
    organizer_character_id: Optional[str] = None
    synopsis: Optional[str] = None
    narrative_hook: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)
    metadata: Dict[str, Any] = Field(default_factory=dict)
    phases: List[StoryPhaseInput] = Field(default_factory=list)
    cast: List[StoryCastInput] = Field(default_factory=list)
    actions: List[StoryActionInput] = Field(default_factory=list)
    initial_history: List[StoryHistoryInput] = Field(default_factory=list)
    initial_memories: List[CharacterMemoryInput] = Field(default_factory=list)


class StoryAdvanceRequest(BaseModel):
    phase_code: Optional[str] = None
    phase_id: Optional[str] = None
    summary: Optional[str] = None
    committed_beats: List[str] = Field(default_factory=list)
    history: List[StoryHistoryInput] = Field(default_factory=list)
    memories: List[CharacterMemoryInput] = Field(default_factory=list)


class StoryParticipationRequest(BaseModel):
    world_id: str
    user_id: str
    phase_code: Optional[str] = None
    action_code: Optional[str] = None
    overlay_type: str = Field(default="participation")
    summary: str
    location_id: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)

