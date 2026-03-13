from __future__ import annotations

from dataclasses import dataclass, field
from datetime import datetime, timedelta, timezone
from typing import Any, Dict, List, Optional, Tuple

import py_trees

from .interfaces import ActorRef, PlannedEvent, PlannerContext
from .memory import parse_dt


@dataclass
class _BlackboardState:
    speaker_npc_id: str
    intent: str = "respond"
    emotion: str = "neutral"
    gesture: Optional[str] = None
    text: str = ""
    planned: List[PlannedEvent] = field(default_factory=list)
    next_short_memory: Dict[str, Any] = field(default_factory=dict)


def _event_type(source_event: Dict[str, Any]) -> str:
    payload = source_event.get("payload")
    if isinstance(payload, dict) and isinstance(payload.get("event_type"), str):
        return str(payload.get("event_type") or "")
    t = source_event.get("type")
    return str(t or "")


def _event_text(source_event: Dict[str, Any]) -> str:
    payload = source_event.get("payload")
    if isinstance(payload, dict) and isinstance(payload.get("text"), str):
        return str(payload.get("text") or "")
    return ""


def _pick_gesture(text: str) -> Optional[str]:
    t = (text or "").strip()
    if not t:
        return None
    # Super small heuristic set; UI can map gestures to motion clips.
    if "?" in t or "？" in t:
        return "think"
    if any(w in t for w in ["ありがとう", "助かる", "了解"]):
        return "nod_yes"
    if any(w in t for w in ["違う", "いや", "だめ", "無理"]):
        return "shake_no"
    return "nod_yes"


def _fallback_reply(npc_id: str, user_text: str) -> str:
    t = (user_text or "").strip()
    if not t:
        return "……どうしたの？"
    if len(t) <= 8:
        return "……うん。"
    if "?" in t or "？" in t:
        return "それで、どうしたいの？"
    return "ふーん。"


class _HasUserTrigger(py_trees.behaviour.Behaviour):
    def __init__(self, name: str = "HasUserTrigger"):
        super().__init__(name)

    def update(self) -> py_trees.common.Status:
        bb: _BlackboardState = py_trees.blackboard.Blackboard().get("gensokyo_bb")
        ctx: PlannerContext = py_trees.blackboard.Blackboard().get("gensokyo_ctx")
        if not bb or not ctx:
            return py_trees.common.Status.FAILURE
        et = _event_type(ctx.source_event)
        # Important: avoid self-trigger loops by default.
        if et in ("user_say", "user_move", "user_choose", "user_request", "user_item_use", "user_item_give", "user_item_take"):
            return py_trees.common.Status.SUCCESS
        return py_trees.common.Status.FAILURE


class _CooldownOK(py_trees.behaviour.Behaviour):
    def __init__(self, cooldown_sec: int, name: str = "CooldownOK"):
        super().__init__(name)
        self._cooldown = max(0, int(cooldown_sec))

    def update(self) -> py_trees.common.Status:
        bb: _BlackboardState = py_trees.blackboard.Blackboard().get("gensokyo_bb")
        ctx: PlannerContext = py_trees.blackboard.Blackboard().get("gensokyo_ctx")
        if not bb or not ctx:
            return py_trees.common.Status.FAILURE
        last = parse_dt(bb.next_short_memory.get("last_spoke_at"))
        if not last:
            return py_trees.common.Status.SUCCESS
        if ctx.now - last >= timedelta(seconds=self._cooldown):
            return py_trees.common.Status.SUCCESS
        return py_trees.common.Status.FAILURE


class _DecideIntent(py_trees.behaviour.Behaviour):
    def __init__(self, name: str = "DecideIntent"):
        super().__init__(name)

    def update(self) -> py_trees.common.Status:
        bb: _BlackboardState = py_trees.blackboard.Blackboard().get("gensokyo_bb")
        ctx: PlannerContext = py_trees.blackboard.Blackboard().get("gensokyo_ctx")
        if not bb or not ctx:
            return py_trees.common.Status.FAILURE
        et = _event_type(ctx.source_event)
        if et == "user_move":
            bb.intent = "greet"
        else:
            bb.intent = "respond"
        return py_trees.common.Status.SUCCESS


class _SelectGesture(py_trees.behaviour.Behaviour):
    def __init__(self, name: str = "SelectGesture"):
        super().__init__(name)

    def update(self) -> py_trees.common.Status:
        bb: _BlackboardState = py_trees.blackboard.Blackboard().get("gensokyo_bb")
        ctx: PlannerContext = py_trees.blackboard.Blackboard().get("gensokyo_ctx")
        if not bb or not ctx:
            return py_trees.common.Status.FAILURE
        text = _event_text(ctx.source_event)
        bb.gesture = _pick_gesture(text)
        return py_trees.common.Status.SUCCESS


class _GenerateSpeech(py_trees.behaviour.Behaviour):
    def __init__(self, name: str = "GenerateSpeech"):
        super().__init__(name)

    def update(self) -> py_trees.common.Status:
        bb: _BlackboardState = py_trees.blackboard.Blackboard().get("gensokyo_bb")
        ctx: PlannerContext = py_trees.blackboard.Blackboard().get("gensokyo_ctx")
        if not bb or not ctx:
            return py_trees.common.Status.FAILURE
        # If the caller already provided a reply (LLM injected), keep it.
        if isinstance(bb.text, str) and bb.text.strip():
            return py_trees.common.Status.SUCCESS
        user_text = _event_text(ctx.source_event)
        # LLM integration is intentionally outside BT (pure planner), so we use a fallback here.
        bb.text = _fallback_reply(bb.speaker_npc_id, user_text)
        return py_trees.common.Status.SUCCESS


class _ComposePlan(py_trees.behaviour.Behaviour):
    def __init__(self, max_events: int = 3, name: str = "ComposePlan"):
        super().__init__(name)
        self._max = max(0, int(max_events))

    def update(self) -> py_trees.common.Status:
        bb: _BlackboardState = py_trees.blackboard.Blackboard().get("gensokyo_bb")
        ctx: PlannerContext = py_trees.blackboard.Blackboard().get("gensokyo_ctx")
        if not bb or not ctx:
            return py_trees.common.Status.FAILURE

        events: List[PlannedEvent] = []
        if bb.gesture and self._max >= 1:
            events.append(
                PlannedEvent(
                    type="npc_action",
                    actor=ActorRef(kind="npc", id=bb.speaker_npc_id),
                    location_id=ctx.location_id,
                    ts=ctx.now,
                    payload={
                        "event_type": "npc_action",
                        "gesture": bb.gesture,
                        "summary": f"{bb.speaker_npc_id}が身振りした。",
                    },
                )
            )
        if self._max >= 1:
            events.append(
                PlannedEvent(
                    type="npc_say",
                    actor=ActorRef(kind="npc", id=bb.speaker_npc_id),
                    location_id=ctx.location_id,
                    ts=ctx.now,
                    payload={
                        "event_type": "npc_say",
                        "text": bb.text,
                        "summary": f"{bb.speaker_npc_id}が話した。",
                    },
                )
            )

        bb.planned = events[: self._max] if self._max else []
        bb.next_short_memory["last_spoke_at"] = ctx.now.isoformat()
        if bb.gesture:
            bb.next_short_memory["last_gesture_at"] = ctx.now.isoformat()
        return py_trees.common.Status.SUCCESS


def build_tree(cooldown_sec: int, max_events: int) -> py_trees.trees.BehaviourTree:
    respond = py_trees.composites.Sequence(
        name="Respond",
        children=[
            _HasUserTrigger(),
            _CooldownOK(cooldown_sec=cooldown_sec),
            _DecideIntent(),
            _SelectGesture(),
            _GenerateSpeech(),
            _ComposePlan(max_events=max_events),
        ],
        memory=False,
    )
    idle = py_trees.behaviours.Success(name="NoOp")
    root = py_trees.composites.Selector(name="NPCPlannerRoot", children=[respond, idle], memory=False)
    return py_trees.trees.BehaviourTree(root)


def plan_once(
    ctx: PlannerContext,
    speaker_npc_id: str,
    short_memory_state: Dict[str, Any],
    cooldown_sec: int,
    max_events: int,
    forced_text: Optional[str] = None,
) -> Tuple[List[PlannedEvent], Dict[str, Any]]:
    """
    Pure planner step: tick the BT once and return (planned_events, next_short_memory_state).
    """
    bb = _BlackboardState(
        speaker_npc_id=speaker_npc_id,
        text=str(forced_text or ""),
        next_short_memory=dict(short_memory_state or {}),
    )
    py_trees.blackboard.Blackboard().set("gensokyo_ctx", ctx)
    py_trees.blackboard.Blackboard().set("gensokyo_bb", bb)

    tree = build_tree(cooldown_sec=cooldown_sec, max_events=max_events)
    tree.tick()

    return list(bb.planned or []), dict(bb.next_short_memory or {})
