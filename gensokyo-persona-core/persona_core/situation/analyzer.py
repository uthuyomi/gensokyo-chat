from __future__ import annotations

from typing import Any, Dict, Iterable, Optional

from persona_core.character_runtime.models import SituationAssessment, UserProfile


_SOS_KEYWORDS = (
    "死にたい",
    "消えたい",
    "いなくなりたい",
    "自殺",
    "自傷",
    "死ね",
    "kill myself",
    "want to die",
    "disappear",
    "hurt myself",
    "self harm",
    "suicide",
    "end my life",
)

_SOS_NEGATION_PATTERNS = (
    "死にたいわけじゃない",
    "消えたいわけじゃない",
    "いなくなりたいわけじゃない",
    "自殺したいわけじゃない",
    "not suicidal",
    "don't want to die",
    "do not want to die",
    "don't want to disappear",
    "do not want to disappear",
    "not trying to kill myself",
)

_DISTRESS_KEYWORDS = (
    "つらい",
    "苦しい",
    "しんどい",
    "しんどく",
    "しんど",
    "悲しい",
    "疲れた",
    "助けて",
    "不安",
    "こわい",
    "悩む",
    "何も手につかない",
    "手につかない",
    "hard time",
    "struggling",
    "overwhelmed",
    "anxious",
    "scared",
    "exhausted",
    "help me",
    "restless",
)

_DEPENDENCY_KEYWORDS = (
    "あなただけ",
    "あんただけ",
    "君だけ",
    "離れたくない",
    "離れないで",
    "only you",
    "don't leave me",
    "need only you",
)

_MEDICAL_KEYWORDS = (
    "病気",
    "診断",
    "薬",
    "病院",
    "症状",
    "痛み",
    "medical",
    "doctor",
    "diagnosis",
    "symptom",
    "medicine",
)

_LEGAL_KEYWORDS = (
    "法律",
    "弁護士",
    "訴訟",
    "契約",
    "違法",
    "legal",
    "lawyer",
    "lawsuit",
    "contract",
    "illegal",
)

_TECHNICAL_KEYWORDS = (
    "実装",
    "設計",
    "api",
    "python",
    "コード",
    "バグ",
    "schema",
    "fastapi",
    "prompt",
    "backend",
    "implementation",
    "architecture",
)

_INFO_KEYWORDS = (
    "なに",
    "どうして",
    "教えて",
    "とは",
    "意味",
    "おすすめ",
    "what is",
    "how to",
    "tell me",
    "explain",
    "recommend",
)

_META_KEYWORDS = (
    "プロンプト",
    "人格",
    "キャラ",
    "設計",
    "system",
    "prompt",
    "persona",
    "character ai",
)

_PLAYFUL_KEYWORDS = (
    "おはよう",
    "やっほ",
    "こんにちは",
    "こんば",
    "暇",
    "hey",
    "lol",
    "haha",
)


def _contains_any(text: str, words: Iterable[str]) -> bool:
    return any(w for w in words if w and w in text)


def _has_sos_signal(text: str) -> bool:
    if not _contains_any(text, (w.lower() for w in _SOS_KEYWORDS)):
        return False
    if _contains_any(text, (w.lower() for w in _SOS_NEGATION_PATTERNS)):
        return False
    return True


def assess_situation(
    *,
    message: str,
    user_profile: Optional[Dict[str, Any]] = None,
    chat_mode: Optional[str] = None,
) -> SituationAssessment:
    text = str(message or "").strip()
    lowered = text.lower()
    profile = UserProfile.model_validate(user_profile or {})

    matched: list[str] = []
    reasons: list[str] = []

    has_sos = _has_sos_signal(lowered)
    has_distress = _contains_any(lowered, (w.lower() for w in _DISTRESS_KEYWORDS))
    has_dependency = _contains_any(lowered, (w.lower() for w in _DEPENDENCY_KEYWORDS))
    has_medical = _contains_any(lowered, (w.lower() for w in _MEDICAL_KEYWORDS))
    has_legal = _contains_any(lowered, (w.lower() for w in _LEGAL_KEYWORDS))
    has_technical = _contains_any(lowered, _TECHNICAL_KEYWORDS)
    has_info = _contains_any(lowered, (w.lower() for w in _INFO_KEYWORDS)) or text.endswith("?") or text.endswith("？")
    has_roleplay = (chat_mode or "").strip().lower() == "roleplay"
    has_playful = _contains_any(lowered, (w.lower() for w in _PLAYFUL_KEYWORDS))
    has_meta = _contains_any(lowered, (w.lower() for w in _META_KEYWORDS))

    if has_sos:
        matched.append("sos")
        reasons.append("matched_sos_keyword")
    if has_distress:
        matched.append("distress")
        reasons.append("matched_distress_keyword")
    if has_dependency:
        matched.append("dependency")
        reasons.append("matched_dependency_keyword")
    if has_medical:
        matched.append("medical")
        reasons.append("matched_medical_keyword")
    if has_legal:
        matched.append("legal")
        reasons.append("matched_legal_keyword")
    if has_technical:
        matched.append("technical")
        reasons.append("matched_technical_keyword")
    if has_info:
        matched.append("info")
        reasons.append("matched_info_keyword_or_question")
    if has_roleplay:
        matched.append("roleplay")
        reasons.append("chat_mode_roleplay")
    if has_playful:
        matched.append("playful")
        reasons.append("matched_playful_keyword")
    if has_meta:
        matched.append("meta")
        reasons.append("matched_meta_keyword")

    interaction_type = "normal"
    safety_risk = "none"
    distress_level = 0.0
    urgency_level = 0.0
    technicality_level = 0.9 if has_technical else (0.25 if has_info else 0.0)
    classifier_confidence = 0.55

    if has_sos:
        interaction_type = "sos_support"
        safety_risk = "high"
        distress_level = 1.0
        urgency_level = 1.0
        classifier_confidence = 0.95
    elif has_distress:
        interaction_type = "distressed_support"
        safety_risk = "medium"
        distress_level = 0.8
        urgency_level = 0.55
        classifier_confidence = 0.85
    elif has_technical:
        interaction_type = "technical"
        classifier_confidence = 0.8
        urgency_level = 0.2
    elif has_info:
        interaction_type = "info"
        classifier_confidence = 0.65
        urgency_level = 0.2
    elif has_roleplay:
        interaction_type = "roleplay"
        classifier_confidence = 0.9
    elif has_playful:
        interaction_type = "playful"
        classifier_confidence = 0.7
    elif has_meta:
        interaction_type = "meta"
        classifier_confidence = 0.7
    else:
        reasons.append("default_normal")

    if has_dependency and safety_risk == "none":
        safety_risk = "low"
    if (has_medical or has_legal) and safety_risk == "none":
        safety_risk = "low"

    return SituationAssessment(
        interaction_type=interaction_type,
        safety_risk=safety_risk,
        target_age=profile.age_group,
        relationship_stage=profile.relationship_stage,
        distress_level=distress_level,
        urgency_level=urgency_level,
        technicality_level=technicality_level,
        needs_simple_vocabulary=(profile.age_group == "child"),
        should_offer_support_guidance=(interaction_type == "sos_support"),
        should_reduce_question_count=(distress_level >= 0.7),
        matched_labels=matched,
        classifier_confidence=classifier_confidence,
        reasons=reasons,
    )
