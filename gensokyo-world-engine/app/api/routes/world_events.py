from fastapi import APIRouter, Header

from app import legacy

router = APIRouter()


@router.post("/world/emit")
async def emit_event(
    req: legacy.EmitEventRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.emit_event(req, x_world_secret=x_world_secret)
