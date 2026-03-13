from __future__ import annotations

import asyncio
from dataclasses import dataclass
from datetime import datetime, timezone
from typing import Awaitable, Callable, Optional


@dataclass(frozen=True)
class WorldSimulatorConfig:
    enabled: bool = True
    interval_sec: int = 30


def utc_now() -> datetime:
    return datetime.now(timezone.utc)


async def simulator_loop(
    *,
    cfg: WorldSimulatorConfig,
    tick_once: Callable[[datetime], Awaitable[None]],
    on_error: Optional[Callable[[Exception], None]] = None,
) -> None:
    """
    Background loop for autonomous world simulation.

    The actual "what to tick" + DB IO should live in the caller (server.py),
    keeping this module purely about scheduling and cancellation.
    """

    if not cfg.enabled:
        return

    interval = max(1, int(cfg.interval_sec or 30))
    while True:
        dt = utc_now()
        try:
            await tick_once(dt)
        except asyncio.CancelledError:
            raise
        except Exception as e:
            if on_error is not None:
                try:
                    on_error(e)
                except Exception:
                    pass
        await asyncio.sleep(interval)

