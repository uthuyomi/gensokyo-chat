from fastapi import APIRouter

from .health import router as health_router
from .world_commands import router as world_commands_router
from .world_events import router as world_events_router
from .world_knowledge import router as world_knowledge_router
from .world_queries import router as world_queries_router
from .world_story import router as world_story_router
from .world_ticks import router as world_ticks_router
from .world_visits import router as world_visits_router


def build_api_router() -> APIRouter:
    router = APIRouter()
    router.include_router(health_router)
    router.include_router(world_events_router)
    router.include_router(world_commands_router)
    router.include_router(world_knowledge_router)
    router.include_router(world_queries_router)
    router.include_router(world_story_router)
    router.include_router(world_visits_router)
    router.include_router(world_ticks_router)
    return router
