from fastapi import APIRouter, Header

from app import legacy
from app.story_models import StoryAdvanceRequest, StoryEventCreateRequest, StoryParticipationRequest
from app.story_services import (
    advance_story_event,
    create_story_event,
    get_story_event_detail,
    get_story_history_view,
    get_story_state,
    list_story_events,
    participate_story_event,
)

router = APIRouter()


@router.get("/world/story/state")
async def world_story_state(
    world_id: str,
    location_id: str = "",
    user_id: str | None = None,
    limit: int = 10,
    x_world_secret: str | None = Header(default=None),
):
    return await get_story_state(
        world_id=world_id,
        location_id=location_id,
        user_id=user_id,
        limit=limit,
        x_world_secret=x_world_secret,
    )


@router.get("/world/story/events")
async def world_story_events(
    world_id: str,
    status: str = "",
    limit: int = 20,
    x_world_secret: str | None = Header(default=None),
):
    return await list_story_events(
        world_id=world_id,
        status=status,
        limit=limit,
        x_world_secret=x_world_secret,
    )


@router.get("/world/story/events/{event_id}")
async def world_story_event_detail(
    event_id: str,
    x_world_secret: str | None = Header(default=None),
):
    return await get_story_event_detail(event_id=event_id, x_world_secret=x_world_secret)


@router.get("/world/story/history")
async def world_story_history(
    world_id: str,
    character_id: str = "",
    user_id: str | None = None,
    limit: int = 20,
    x_world_secret: str | None = Header(default=None),
):
    return await get_story_history_view(
        world_id=world_id,
        character_id=character_id,
        user_id=user_id,
        limit=limit,
        x_world_secret=x_world_secret,
    )


@router.post("/world/story/events")
async def create_world_story_event(
    req: StoryEventCreateRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await create_story_event(
        req=req,
        x_world_secret=x_world_secret,
        emit_event_fn=legacy.emit_event,
    )


@router.post("/world/story/events/{event_id}/advance")
async def advance_world_story_event(
    event_id: str,
    req: StoryAdvanceRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await advance_story_event(
        event_id=event_id,
        req=req,
        x_world_secret=x_world_secret,
        emit_event_fn=legacy.emit_event,
    )


@router.post("/world/story/events/{event_id}/participate")
async def participate_in_world_story_event(
    event_id: str,
    req: StoryParticipationRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await participate_story_event(
        event_id=event_id,
        req=req,
        x_world_secret=x_world_secret,
        emit_event_fn=legacy.emit_event,
    )
