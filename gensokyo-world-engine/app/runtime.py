from __future__ import annotations

import asyncio
from typing import Optional

import npc_dialogue_engine
from world_simulator import simulator_loop

from app.config import WORLD_ENGINE_SECRET, env

_worker_task: Optional[asyncio.Task] = None
_sim_task: Optional[asyncio.Task] = None


async def startup_world_engine() -> None:
    global _worker_task, _sim_task

    from app import legacy

    try:
        _ = legacy.load_locations()
        _ = legacy.load_events()
        _ = legacy.load_relationships()
        try:
            _ = npc_dialogue_engine.relationship_graph()
        except Exception:
            pass
    except Exception:
        pass

    worker_enabled = env("GENSOKYO_COMMAND_WORKER_ENABLED", "1").strip() not in ("0", "false", "False")
    if worker_enabled and not (_worker_task and not _worker_task.done()):
        _worker_task = asyncio.create_task(legacy.command_worker_loop(x_world_secret=WORLD_ENGINE_SECRET or None))

    sim_enabled = env("GENSOKYO_WORLD_SIM_ENABLED", "0").strip() not in ("0", "false", "False")
    if sim_enabled and not (_sim_task and not _sim_task.done()):
        cfg = legacy.world_simulator_config()
        _sim_task = asyncio.create_task(
            simulator_loop(cfg=cfg, tick_once=legacy._world_sim_tick_once, on_error=legacy._on_sim_error)
        )


async def shutdown_world_engine() -> None:
    global _worker_task, _sim_task

    if _worker_task:
        _worker_task.cancel()
        _worker_task = None
    if _sim_task:
        _sim_task.cancel()
        _sim_task = None
