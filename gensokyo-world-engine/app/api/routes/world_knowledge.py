from fastapi import APIRouter, Header

from app.knowledge_service import get_knowledge_universe

router = APIRouter()


@router.get("/world/knowledge/universe")
async def world_knowledge_universe(
    world_id: str,
    limit: int = 240,
    embedding_model: str | None = None,
    max_edges_per_node: int = 2,
    similarity_threshold: float = 0.32,
    x_world_secret: str | None = Header(default=None),
):
    return await get_knowledge_universe(
        world_id=world_id,
        limit=limit,
        embedding_model=embedding_model,
        max_edges_per_node=max_edges_per_node,
        similarity_threshold=similarity_threshold,
        x_world_secret=x_world_secret,
    )
