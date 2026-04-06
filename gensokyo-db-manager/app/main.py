from fastapi import FastAPI

from app import legacy
from app.api.routes import build_api_router
from app.scheduler import start_scheduler, stop_scheduler


app = FastAPI(
    title="gensokyo-db-manager",
    version="0.1.0",
    default_response_class=legacy.Utf8JSONResponse,
)
app.include_router(build_api_router())


@app.on_event("startup")
async def startup() -> None:
    start_scheduler()


@app.on_event("shutdown")
async def shutdown() -> None:
    stop_scheduler()
