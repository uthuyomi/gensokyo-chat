from fastapi import APIRouter

from .audit import router as audit_router
from .claims import router as claims_router
from .discovery import router as discovery_router
from .health import router as health_router
from .ingest import router as ingest_router
from .ops import router as ops_router
from .schema import router as schema_router
from .signals import router as signals_router


def build_api_router() -> APIRouter:
    router = APIRouter()
    router.include_router(health_router)
    router.include_router(audit_router)
    router.include_router(schema_router)
    router.include_router(signals_router)
    router.include_router(claims_router)
    router.include_router(discovery_router)
    router.include_router(ingest_router)
    router.include_router(ops_router)
    return router
