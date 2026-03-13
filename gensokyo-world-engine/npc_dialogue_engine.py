from __future__ import annotations

import random
import hashlib
from dataclasses import dataclass
from typing import Any, Awaitable, Callable, Dict, Iterable, List, Optional, Tuple

try:
    from content_loader import load_relationships as _load_relationships_from_content
except Exception:  # pragma: no cover
    _load_relationships_from_content = None


@dataclass(frozen=True)
class NpcPair:
    speaker_id: str
    listener_id: str


def _norm01(v: Any) -> float:
    try:
        x = float(v)
    except Exception:
        return 0.0
    if x != x:
        return 0.0
    return max(0.0, min(1.0, x))


def _pair_key(a: str, b: str) -> Tuple[str, str]:
    aa = str(a or "").strip()
    bb = str(b or "").strip()
    return (aa, bb) if aa <= bb else (bb, aa)


class RelationshipGraph:
    """
    Lightweight undirected relationship lookup for NPC↔NPC.
    Used only for weighting (does not mutate).
    """

    def __init__(self, rows: Iterable[Dict[str, Any]]) -> None:
        self._m: Dict[Tuple[str, str], Dict[str, float]] = {}
        for r in rows or []:
            if not isinstance(r, dict):
                continue
            a = str(r.get("character_a") or "").strip()
            b = str(r.get("character_b") or "").strip()
            if not a or not b:
                continue
            k = _pair_key(a, b)
            self._m[k] = {
                "trust": _norm01(r.get("trust")),
                "caution": _norm01(r.get("caution")),
                "familiarity": _norm01(r.get("familiarity")),
            }

    def get(self, a: str, b: str) -> Dict[str, float]:
        k = _pair_key(a, b)
        return self._m.get(k, {"trust": 0.0, "caution": 0.0, "familiarity": 0.0})


_REL_CACHE: Optional[RelationshipGraph] = None


def relationship_graph() -> RelationshipGraph:
    global _REL_CACHE
    if _REL_CACHE is not None:
        return _REL_CACHE

    rows: List[Dict[str, Any]] = []
    if _load_relationships_from_content is not None:
        try:
            rr = _load_relationships_from_content()
            if isinstance(rr, list):
                rows = [x for x in rr if isinstance(x, dict)]
        except Exception:
            rows = []

    _REL_CACHE = RelationshipGraph(rows)
    return _REL_CACHE


def pick_pair(
    npc_ids: List[str],
    *,
    rng: random.Random,
    rel: Optional[RelationshipGraph] = None,
) -> Optional[NpcPair]:
    ids = [str(x or "").strip() for x in (npc_ids or []) if str(x or "").strip()]
    ids = list(dict.fromkeys(ids))  # stable unique
    if len(ids) < 2:
        return None

    g = rel or relationship_graph()

    # Weight pairs: prefer familiar/trusty combinations, avoid high-caution.
    weighted: List[Tuple[NpcPair, float]] = []
    for i in range(len(ids)):
        for j in range(i + 1, len(ids)):
            a = ids[i]
            b = ids[j]
            s = g.get(a, b)
            w = (
                0.2
                + 0.9 * float(s.get("familiarity", 0.0))
                + 0.6 * float(s.get("trust", 0.0))
                - 0.4 * float(s.get("caution", 0.0))
            )
            w = max(0.05, w)

            # Direction: randomize speaker/listener but keep same weight.
            pair = NpcPair(speaker_id=a, listener_id=b) if rng.random() < 0.5 else NpcPair(speaker_id=b, listener_id=a)
            weighted.append((pair, w))

    total = sum(w for _, w in weighted)
    if total <= 0:
        a, b = ids[0], ids[1]
        return NpcPair(speaker_id=a, listener_id=b)

    pick = rng.random() * total
    acc = 0.0
    for pair, w in weighted:
        acc += w
        if acc >= pick:
            return pair
    return weighted[-1][0] if weighted else None


def _template_line(_pair: NpcPair, location_id: str, *, rng: random.Random) -> str:
    loc = str(location_id or "").strip()
    # Keep templates ultra-short; style comes from character persona elsewhere.
    if loc == "hakurei_shrine":
        options = [
            "また来たの？",
            "賽銭箱見るのやめなさい。",
            "今日は静かにしていきなさいよ。",
            "変なこと企んでないでしょうね？",
        ]
    else:
        options = [
            "どうしたの？",
            "……ふーん。",
            "今は忙しいの。",
            "あとで話そう。",
        ]
    return options[int(rng.random() * len(options)) % len(options)]


def make_conversation_id(*, seed: str, speaker_id: str, listener_id: str, index: int = 0) -> str:
    """
    Deterministic conversation id for grouping multi-turn npc_dialogue events.

    - Stable across retries for the same seed/pair/index (useful for tests)
    - Short and URL/UI-friendly
    """
    s = f"{seed}|{index}|{speaker_id}|{listener_id}"
    return hashlib.sha1(s.encode("utf-8")).hexdigest()[:12]


def _exchange_templates(pair: NpcPair, location_id: str) -> List[Tuple[str, str]]:
    """
    Return (speaker_line, listener_reply) templates for a pair/location.
    Keeps it tiny and deterministic; higher-level "story" comes from world-state/events.
    """
    a = str(pair.speaker_id or "").strip()
    b = str(pair.listener_id or "").strip()
    loc = str(location_id or "").strip()

    # Pair-specific: Reimu <-> Marisa at Hakurei Shrine.
    if loc == "hakurei_shrine" and {a, b} == {"reimu", "marisa"}:
        if a == "reimu":
            return [
                ("賽銭箱見るのやめなさい。", "研究費だぜ"),
                ("また来たの？", "来ちまったぜ"),
                ("変なこと企んでないでしょうね？", "実験だよ実験"),
                ("今日は静かにしていきなさいよ。", "無理言うなよ"),
            ]
        # Marisa speaks first
        return [
            ("今日も顔出しに来たぜ。", "暇なら帰りなさい"),
            ("おーい霊夢、なんか面白い話ないか？", "あんたの面白い話はだいたい面倒なのよ"),
            ("賽銭箱、今日も寂しそうだな。", "触るな"),
            ("ちょっと借りるぜ。", "返しなさい"),
        ]

    # Generic fallback: short call-and-response.
    # Generic fallback: keep it stable but not identical every time.
    reply_options = [
        "……そう。",
        "まあ、いいけど。",
        "それで？",
        "今はその話じゃない。",
    ]
    # Use location hash for a stable-ish first line.
    rr = random.Random(f"fallback|{loc}|{a}|{b}")
    speaker_line = _template_line(pair, location_id, rng=rr)
    return [(speaker_line, reply_options[int(rr.random() * len(reply_options)) % len(reply_options)])]


async def generate_dialogue_exchange(
    pair: NpcPair,
    *,
    location_id: str,
    rng: random.Random,
    llm_generate: Optional[Callable[[str, str, str, Optional[str]], Awaitable[str]]] = None,
) -> Tuple[str, str]:
    """
    Returns (speaker_line, listener_reply).

    If llm_generate is provided, it should be:
      (speaker_id, listener_id, location_id, previous_text) -> text
    where previous_text is None for the first line and the first line for the reply.
    """
    if llm_generate is not None:
        try:
            t1 = await llm_generate(pair.speaker_id, pair.listener_id, location_id, None)
            s1 = str(t1 or "").strip()
            if s1:
                t2 = await llm_generate(pair.listener_id, pair.speaker_id, location_id, s1)
                s2 = str(t2 or "").strip()
                if s2:
                    return s1, s2
        except Exception:
            pass

    templates = _exchange_templates(pair, location_id)
    if not templates:
        line1 = _template_line(pair, location_id, rng=rng)
        return line1, "……そう。"

    a, b = templates[int(rng.random() * len(templates)) % len(templates)]
    return str(a or "").strip() or "……", str(b or "").strip() or "……"


async def generate_dialogue_text(
    pair: NpcPair,
    *,
    location_id: str,
    rng: random.Random,
    llm_generate: Optional[Callable[[str, str, str], Awaitable[str]]] = None,
) -> str:
    """
    Returns a single spoken line. If llm_generate is provided, it should be:
      (speaker_id, listener_id, location_id) -> text
    """

    if llm_generate is not None:
        try:
            t = await llm_generate(pair.speaker_id, pair.listener_id, location_id)
            s = str(t or "").strip()
            if s:
                return s
        except Exception:
            pass
    return _template_line(pair, location_id, rng=rng)


async def plan_npc_dialogue_events(
    *,
    world_id: str,
    layer_id: str,
    location_id: str,
    npc_ids: List[str],
    now_iso: str,
    seed: str,
    llm_generate: Optional[Callable[[str, str, str], Awaitable[str]]] = None,
    max_events: int = 1,
) -> List[Dict[str, Any]]:
    """
    Returns event dicts (world_event_log payload style) to be appended by the caller.
    """

    rng = random.Random(str(seed or "") + "|npc_dialogue")
    out: List[Dict[str, Any]] = []
    rel = relationship_graph()

    for _ in range(max(0, int(max_events or 0))):
        pair = pick_pair(npc_ids, rng=rng, rel=rel)
        if not pair:
            break
        text = await generate_dialogue_text(pair, location_id=location_id, rng=rng, llm_generate=llm_generate)
        text = str(text or "").strip()
        if not text:
            continue

        out.append(
            {
                "world_id": world_id,
                "layer_id": layer_id,
                "location_id": location_id,
                "type": "npc_dialogue",
                "actor": {"kind": "npc", "id": pair.speaker_id},
                "ts": now_iso,
                "payload": {
                    "event_type": "npc_dialogue",
                    "speaker": pair.speaker_id,
                    "listener": pair.listener_id,
                    "text": text,
                    "summary": text[:80],
                },
            }
        )

    return out
