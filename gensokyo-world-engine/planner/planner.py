from __future__ import annotations

import random
from dataclasses import dataclass
from datetime import datetime, timedelta
from typing import Any, Awaitable, Callable, Dict, List, Optional, Tuple

from .bt import plan_once
from .interfaces import ActorRef, NpcSnapshot, PlannerContext, PlannedEvent, UserSnapshot
from .memory import InMemoryShortMemoryStore, ShortMemoryStore

try:
    import npc_dialogue_engine
except Exception:  # pragma: no cover
    npc_dialogue_engine = None


@dataclass(frozen=True)
class PlannerConfig:
    enabled: bool = True
    cooldown_sec: int = 6
    max_events_per_trigger: int = 2
    npc_dialogue_enabled: bool = True
    npc_dialogue_max_events: int = 1
    npc_dialogue_probability: float = 0.22  # per trigger (world_tick only)


_inmem_store: Optional[InMemoryShortMemoryStore] = None


def _get_inmem_store() -> InMemoryShortMemoryStore:
    global _inmem_store
    if _inmem_store is None:
        _inmem_store = InMemoryShortMemoryStore()
    return _inmem_store


def _pick_speaker_npc_id(ctx: PlannerContext) -> Optional[str]:
    payload = ctx.source_event.get("payload") if isinstance(ctx.source_event.get("payload"), dict) else {}
    to = payload.get("to")
    if isinstance(to, str) and to.strip():
        for n in ctx.npcs_here:
            if n.npc_id == to.strip():
                return n.npc_id
    # Default: first NPC at location.
    return ctx.npcs_here[0].npc_id if ctx.npcs_here else None


async def maybe_plan_reactions(
    cfg: PlannerConfig,
    ctx: PlannerContext,
    short_memory: Optional[ShortMemoryStore] = None,
    speech_generator: Optional[Callable[[str, PlannerContext], Awaitable[str]]] = None,
    npc_dialogue_llm_generate: Optional[Callable[[str, str, str, Optional[str], PlannerContext], Awaitable[str]]] = None,
) -> Tuple[List[PlannedEvent], Dict[str, Any]]:
    """
    Returns planned events + updated short memory for the chosen speaker NPC.

    I/O-less except for short memory store access (if provided).
    """
    if not cfg.enabled:
        return [], {}

    speaker = _pick_speaker_npc_id(ctx)
    if not speaker:
        return [], {}

    store = short_memory or _get_inmem_store()
    state0 = await store.get_state(ctx.world_id, speaker)

    forced_text: Optional[str] = None
    if speech_generator is not None:
        try:
            forced_text = await speech_generator(speaker, ctx)
        except Exception:
            forced_text = None
    planned, state1 = plan_once(
        ctx=ctx,
        speaker_npc_id=speaker,
        short_memory_state=state0,
        cooldown_sec=cfg.cooldown_sec,
        max_events=cfg.max_events_per_trigger,
        forced_text=forced_text,
    )

    # Optional: NPC↔NPC dialogue (only on world_tick to avoid stepping on user-facing turns).
    try:
        payload = ctx.source_event.get("payload") if isinstance(ctx.source_event.get("payload"), dict) else {}
        event_type = str(payload.get("event_type") or "")
    except Exception:
        event_type = ""
    if (
        cfg.npc_dialogue_enabled
        and npc_dialogue_engine is not None
        and event_type == "world_tick"
        and len(ctx.npcs_here or []) >= 2
    ):
        try:
            # Deterministic-ish seed based on world/location/time.
            seed = f"{ctx.world_id}:{ctx.location_id}:{ctx.now.isoformat()}"
            rng = random.Random(seed)
            npc_ids = [n.npc_id for n in (ctx.npcs_here or []) if isinstance(getattr(n, "npc_id", None), str)]
            max_conversations = max(1, int(cfg.npc_dialogue_max_events or 1))
            max_conversations = min(3, max_conversations)
            prob = float(cfg.npc_dialogue_probability or 0.0)
            prob = max(0.0, min(1.0, prob))

            conv_i = 0
            while conv_i < max_conversations:
                if rng.random() >= prob:
                    conv_i += 1
                    continue
                pair = npc_dialogue_engine.pick_pair(npc_ids, rng=rng)
                if not pair:
                    break

                # 2-turn fixed exchange: A -> B, then B -> A.
                async def _llm_generate(speaker_id: str, listener_id: str, location_id: str, previous_text: Optional[str]) -> str:
                    if npc_dialogue_llm_generate is None:
                        return ""
                    return await npc_dialogue_llm_generate(speaker_id, listener_id, location_id, previous_text, ctx)

                line1, line2 = await npc_dialogue_engine.generate_dialogue_exchange(
                    pair,
                    location_id=ctx.location_id,
                    rng=rng,
                    llm_generate=_llm_generate if npc_dialogue_llm_generate is not None else None,
                )
                t1 = str(line1 or "").strip()
                t2 = str(line2 or "").strip()
                if not (t1 and t2):
                    conv_i += 1
                    continue

                conv_id = npc_dialogue_engine.make_conversation_id(
                    seed=seed,
                    speaker_id=pair.speaker_id,
                    listener_id=pair.listener_id,
                    index=conv_i,
                )

                planned.append(
                    PlannedEvent(
                        type="npc_dialogue",
                        actor=ActorRef(kind="npc", id=pair.speaker_id),
                        location_id=ctx.location_id,
                        ts=ctx.now,
                        payload={
                            "event_type": "npc_dialogue",
                            "conversation_id": conv_id,
                            "turn": 1,
                            "speaker": pair.speaker_id,
                            "listener": pair.listener_id,
                            "text": t1,
                            "summary": t1[:80],
                        },
                    )
                )
                planned.append(
                    PlannedEvent(
                        type="npc_dialogue",
                        actor=ActorRef(kind="npc", id=pair.listener_id),
                        location_id=ctx.location_id,
                        ts=ctx.now + timedelta(seconds=1),
                        payload={
                            "event_type": "npc_dialogue",
                            "conversation_id": conv_id,
                            "turn": 2,
                            "speaker": pair.listener_id,
                            "listener": pair.speaker_id,
                            "text": t2,
                            "summary": t2[:80],
                            "reply_to_turn": 1,
                        },
                    )
                )
                conv_i += 1
        except Exception:
            pass
    return planned, state1
