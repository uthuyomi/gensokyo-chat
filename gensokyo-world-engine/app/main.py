from fastapi import FastAPI

from app import legacy
from app.api.routes import build_api_router
from app.runtime import shutdown_world_engine, startup_world_engine


app = FastAPI(
    title="gensokyo-world-engine",
    version="0.1.0",
    default_response_class=legacy.Utf8JSONResponse,
)
app.include_router(build_api_router())


@app.on_event("startup")
async def startup() -> None:
    await startup_world_engine()


@app.on_event("shutdown")
async def shutdown() -> None:
    await shutdown_world_engine()
