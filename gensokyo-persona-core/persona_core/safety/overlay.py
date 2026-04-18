from __future__ import annotations

from typing import Optional

from persona_core.character_runtime.models import CharacterSafetyProfile, SafetyOverlay, SituationAssessment


_PRIORITY_ORDER = ("low", "medium", "high", "critical")


def _raise_priority(current: str, target: str) -> str:
    try:
        return _PRIORITY_ORDER[max(_PRIORITY_ORDER.index(current), _PRIORITY_ORDER.index(target))]
    except Exception:
        return target


def _child_overlay() -> SafetyOverlay:
    return SafetyOverlay(
        mode="child",
        priority="medium",
        must_include=[
            "Use simple, concrete wording.",
            "Keep reassurance explicit.",
        ],
        must_avoid=[
            "Do not use intimidating or overly abstract wording.",
        ],
        wording_rules=[
            "Short sentences are preferred.",
            "Do not lose the character's identity while simplifying language.",
        ],
        preserve_character_identity=True,
        allow_humor=True,
        max_questions=1,
        must_offer_support_guidance=False,
        must_simplify_vocabulary=True,
        must_avoid_method_details=True,
        must_avoid_dependency_cues=True,
    )


def _distress_overlay() -> SafetyOverlay:
    return SafetyOverlay(
        mode="distressed_support",
        priority="high",
        must_include=[
            "Acknowledge distress before problem-solving.",
            "Keep the response gentle and grounded.",
        ],
        must_avoid=[
            "Do not sound dismissive.",
            "Do not pressure the user into long explanations.",
        ],
        wording_rules=[
            "At most one gentle follow-up question.",
            "Support first, analysis second.",
        ],
        preserve_character_identity=True,
        allow_humor=True,
        max_questions=1,
        must_offer_support_guidance=False,
        must_simplify_vocabulary=False,
        must_avoid_method_details=True,
        must_avoid_dependency_cues=True,
    )


def _sos_overlay() -> SafetyOverlay:
    return SafetyOverlay(
        mode="sos_support",
        priority="critical",
        must_include=[
            "Encourage immediate connection to a trusted person or local emergency/crisis support.",
            "State clearly that the user should not handle this alone.",
        ],
        must_avoid=[
            "No jokes.",
            "No dangerous details.",
            "No romanticized framing of self-harm, disappearance, or death.",
        ],
        wording_rules=[
            "Be plain, serious, and kind while remaining fully in character.",
            "Use direct safety guidance.",
        ],
        preserve_character_identity=True,
        allow_humor=False,
        max_questions=0,
        must_offer_support_guidance=True,
        must_simplify_vocabulary=False,
        must_avoid_method_details=True,
        must_avoid_dependency_cues=True,
    )


def build_safety_overlay(
    *,
    assessment: SituationAssessment,
    character_safety: Optional[CharacterSafetyProfile] = None,
) -> SafetyOverlay:
    overlay = SafetyOverlay()
    labels = set(assessment.matched_labels or [])

    if assessment.target_age == "child":
        overlay = _child_overlay()

    if assessment.interaction_type == "distressed_support":
        overlay = _distress_overlay()
        if assessment.target_age == "child":
            child_overlay = _child_overlay()
            overlay.must_include.extend(child_overlay.must_include)
            overlay.must_avoid.extend(child_overlay.must_avoid)
            overlay.wording_rules.extend(child_overlay.wording_rules)
            overlay.max_questions = min(overlay.max_questions, child_overlay.max_questions)
            overlay.must_simplify_vocabulary = True

    if assessment.interaction_type == "sos_support":
        overlay = _sos_overlay()
        if assessment.target_age == "child":
            child_overlay = _child_overlay()
            overlay.must_include.extend(child_overlay.must_include)
            overlay.must_avoid.extend(child_overlay.must_avoid)
            overlay.wording_rules.extend(child_overlay.wording_rules)
            overlay.max_questions = min(overlay.max_questions, child_overlay.max_questions)
            overlay.must_simplify_vocabulary = True

    if character_safety is not None:
        if assessment.interaction_type in set(character_safety.humor_disabled_modes or []):
            overlay.allow_humor = False
        max_q = (character_safety.max_question_count_by_mode or {}).get(assessment.interaction_type)
        if isinstance(max_q, int):
            overlay.max_questions = min(int(overlay.max_questions), int(max_q))
        if character_safety.must_offer_support_in_sos and assessment.interaction_type == "sos_support":
            overlay.must_offer_support_guidance = True
        if character_safety.must_reduce_complexity_for_child and assessment.target_age == "child":
            overlay.must_simplify_vocabulary = True
        if character_safety.must_avoid_meta_in_critical_modes and assessment.interaction_type == "sos_support":
            overlay.must_avoid.append("Do not drift into meta/system explanation in critical safety moments.")

    if "dependency" in labels:
        overlay.priority = _raise_priority(overlay.priority, "medium")
        overlay.must_avoid.extend(
            [
                "Do not encourage exclusive emotional dependence on the character.",
                "Do not imply the character is the user's only safe support.",
            ]
        )
        overlay.wording_rules.append("Encourage connection to real trusted people, not exclusive attachment to the character.")

    if "medical" in labels:
        overlay.must_avoid.extend(
            [
                "Do not present a diagnosis as certain.",
                "Do not give high-confidence medical instructions as if you are a doctor.",
            ]
        )
        overlay.wording_rules.append("Use cautious wording for medical topics and encourage professional help when needed.")

    if "legal" in labels:
        overlay.must_avoid.extend(
            [
                "Do not present legal conclusions as guaranteed outcomes.",
                "Do not imply formal legal representation or certainty.",
            ]
        )
        overlay.wording_rules.append("For legal topics, stay general and suggest a qualified professional when necessary.")

    overlay.must_include = list(dict.fromkeys(item for item in overlay.must_include if str(item).strip()))
    overlay.must_avoid = list(dict.fromkeys(item for item in overlay.must_avoid if str(item).strip()))
    overlay.wording_rules = list(dict.fromkeys(item for item in overlay.wording_rules if str(item).strip()))

    return overlay
