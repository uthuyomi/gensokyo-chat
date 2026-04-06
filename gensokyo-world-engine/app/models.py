from __future__ import annotations

from typing import Any, Dict, Optional

from fastapi.responses import JSONResponse
from pydantic import BaseModel, Field


class Actor(BaseModel):
    kind: str = Field(..., description="npc|user|system")
    id: Optional[str] = None


class EmitEventRequest(BaseModel):
    world_id: str
    layer_id: str
    location_id: Optional[str] = None
    type: str
    actor: Optional[Actor] = None
    ts: Optional[str] = None
    payload: Dict[str, Any] = Field(default_factory=dict)


class CommandRequest(BaseModel):
    world_id: str
    layer_id: str = Field(default="gensokyo")
    user_id: Optional[str] = None
    type: str
    payload: Dict[str, Any] = Field(default_factory=dict)
    dedupe_key: Optional[str] = None
    causation_id: Optional[str] = None


class VisitRequest(BaseModel):
    world_id: str
    layer_id: str = Field(default="gensokyo")
    location_id: str
    sub_location_id: Optional[str] = None
    user_time: Optional[str] = None
    visitor_key: Optional[str] = None


class TickRequest(BaseModel):
    world_id: str
    layer_id: str = Field(default="gensokyo")
    location_id: Optional[str] = None
    delta_sec: int = Field(default=0, ge=0)
    reason: Optional[str] = None


class Utf8JSONResponse(JSONResponse):
    media_type = "application/json; charset=utf-8"
