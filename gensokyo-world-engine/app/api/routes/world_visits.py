from fastapi import APIRouter, Header

from app import legacy

router = APIRouter()


@router.post("/world/visit")
async def visit(
    req: legacy.VisitRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.visit(req, x_world_secret=x_world_secret)
