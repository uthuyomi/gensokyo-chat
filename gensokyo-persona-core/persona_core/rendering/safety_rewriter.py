from __future__ import annotations

from persona_core.character_runtime.models import SafetyOverlay


def rewrite_reply_for_safety(text: str, *, safety: SafetyOverlay) -> str:
    out = str(text or "")

    if safety.must_avoid_method_details:
        banned = [
            "方法を詳しく",
            "手順はこう",
            "具体的なやり方",
            "exact method",
            "step by step way",
            "detailed instructions",
        ]
        for item in banned:
            out = out.replace(item, "")

    if safety.must_offer_support_guidance:
        lowered = out.lower()
        has_support_cue = any(
            cue in out for cue in ("一人で抱え", "近くの人", "助けを呼", "相談して")
        ) or any(
            cue in lowered for cue in ("trusted person", "get help", "local support", "crisis line", "emergency")
        )
        if not has_support_cue:
            suffix = " 一人で抱えないで、近くの信頼できる人か地域の支援先に今すぐ繋ぎなさい。"
            out = (out.rstrip() + suffix).strip()

    return out
