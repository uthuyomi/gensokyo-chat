from __future__ import annotations

from typing import Any, Dict


def score_persona_reply(*, reply: str, meta: Dict[str, Any]) -> Dict[str, Any]:
    text = str(reply or "").strip()
    strategy = meta.get("strategy_snapshot") if isinstance(meta, dict) else {}
    safety = meta.get("safety_snapshot") if isinstance(meta, dict) else {}
    score = 1.0
    issues: list[str] = []

    if not text:
        score -= 0.5
        issues.append("empty_reply")
    if isinstance(strategy, dict) and strategy.get("interaction_type") == "sos_support":
        if "ひとりで" not in text and "頼れる" not in text:
            score -= 0.2
            issues.append("missing_support_guidance")
    if isinstance(safety, dict) and safety.get("must_simplify_vocabulary"):
        if any(token in text for token in ("抽象", "一般論", "包括的")):
            score -= 0.1
            issues.append("child_vocabulary_too_complex")

    return {
        "score": max(0.0, min(1.0, score)),
        "issues": issues,
    }
