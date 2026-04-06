from fastapi import APIRouter, Header

from app import legacy

router = APIRouter()


@router.post("/world/tick")
async def tick(
    req: legacy.TickRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.tick(req, x_world_secret=x_world_secret)
