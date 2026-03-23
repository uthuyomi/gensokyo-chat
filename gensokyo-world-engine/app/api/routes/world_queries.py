from fastapi import APIRouter, Header

from app import legacy

router = APIRouter()


@router.get("/world/state")
async def get_world_state(
    world_id: str,
    location_id: str = "",
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.get_world_state(
        world_id=world_id,
        location_id=location_id,
        x_world_secret=x_world_secret,
    )


@router.get("/world/recent")
async def get_recent_events(
    world_id: str,
    location_id: str = "",
    limit: int = 10,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.get_recent_events(
        world_id=world_id,
        location_id=location_id,
        limit=limit,
        x_world_secret=x_world_secret,
    )


@router.get("/world/npcs")
async def get_npcs(
    world_id: str,
    location_id: str = "",
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.get_npcs(
        world_id=world_id,
        location_id=location_id,
        x_world_secret=x_world_secret,
    )
