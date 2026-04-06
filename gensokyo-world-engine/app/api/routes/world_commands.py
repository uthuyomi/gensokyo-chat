from fastapi import APIRouter, Header

from app import legacy

router = APIRouter()


@router.post("/world/command")
async def submit_command(
    req: legacy.CommandRequest,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.submit_command(req, x_world_secret=x_world_secret)


@router.get("/world/command/{command_id}")
async def get_command(
    command_id: str,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.get_command(command_id, x_world_secret=x_world_secret)


@router.get("/world/commands")
async def list_commands(
    world_id: str,
    status: str = "",
    limit: int = 20,
    x_world_secret: str | None = Header(default=None),
):
    return await legacy.list_commands(
        world_id=world_id,
        status=status,
        limit=limit,
        x_world_secret=x_world_secret,
    )
