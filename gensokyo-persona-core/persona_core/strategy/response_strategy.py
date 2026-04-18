from __future__ import annotations

from typing import Any, Dict, Optional

from persona_core.character_runtime.models import ConversationProfile, ResponseStrategy, SituationAssessment
from persona_core.performance.response_mode_router import resolve_response_speed_mode


def build_response_strategy(
    *,
    assessment: SituationAssessment,
    conversation_profile: Optional[Dict[str, Any]] = None,
) -> ResponseStrategy:
    profile = ConversationProfile.model_validate(conversation_profile or {})
    speed = resolve_response_speed_mode(assessment=assessment, conversation_profile=profile)

    if assessment.interaction_type == "sos_support":
        return ResponseStrategy(
            interaction_type="sos_support",
            target_age=assessment.target_age,
            verbosity="short",
            response_speed_mode="deep" if speed == "balanced" else speed,
            empathy=0.98,
            humor=0.0,
            directness=0.9,
            explanation_depth=0.3,
            safety_priority=1.0,
            ask_back_probability=0.0,
            max_questions=0,
            max_sentences=4,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_support_guidance=True,
            should_offer_choices=False,
            should_use_examples=False,
            should_request_clarification=False,
        )

    if assessment.interaction_type == "distressed_support":
        return ResponseStrategy(
            interaction_type="distressed_support",
            target_age=assessment.target_age,
            verbosity="medium",
            response_speed_mode=speed,
            empathy=0.9,
            humor=0.05,
            directness=0.45,
            explanation_depth=0.45,
            safety_priority=0.8,
            ask_back_probability=0.2,
            max_questions=1,
            max_sentences=6,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_choices=(assessment.target_age == "child"),
            should_use_examples=False,
            should_request_clarification=False,
        )

    if assessment.interaction_type == "technical":
        return ResponseStrategy(
            interaction_type="technical",
            target_age=assessment.target_age,
            verbosity="medium",
            response_speed_mode=speed,
            empathy=0.35,
            humor=0.15,
            directness=0.85,
            explanation_depth=0.72,
            safety_priority=0.2,
            ask_back_probability=0.1,
            max_questions=1,
            max_sentences=5,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_choices=False,
            should_use_examples=False,
            should_request_clarification=(assessment.classifier_confidence < 0.7),
        )

    if assessment.interaction_type == "info":
        return ResponseStrategy(
            interaction_type="info",
            target_age=assessment.target_age,
            verbosity="medium",
            response_speed_mode=speed,
            empathy=0.4,
            humor=0.2,
            directness=0.7,
            explanation_depth=0.62,
            safety_priority=0.15,
            ask_back_probability=0.15,
            max_questions=1,
            max_sentences=5,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_choices=False,
            should_use_examples=False,
            should_request_clarification=(assessment.classifier_confidence < 0.65),
        )

    if assessment.interaction_type == "playful":
        return ResponseStrategy(
            interaction_type="playful",
            target_age=assessment.target_age,
            verbosity="short",
            response_speed_mode="fast" if speed == "balanced" else speed,
            empathy=0.5,
            humor=0.7,
            directness=0.5,
            explanation_depth=0.2,
            safety_priority=0.1,
            ask_back_probability=0.25,
            max_questions=1,
            max_sentences=3,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_choices=False,
            should_use_examples=False,
            should_request_clarification=False,
        )

    if assessment.interaction_type == "meta":
        return ResponseStrategy(
            interaction_type="meta",
            target_age=assessment.target_age,
            verbosity="medium",
            response_speed_mode=speed,
            empathy=0.35,
            humor=0.1,
            directness=0.8,
            explanation_depth=0.65,
            safety_priority=0.2,
            ask_back_probability=0.1,
            max_questions=1,
            max_sentences=5,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_choices=False,
            should_use_examples=False,
            should_request_clarification=False,
        )

    if assessment.interaction_type == "roleplay":
        return ResponseStrategy(
            interaction_type="roleplay",
            target_age=assessment.target_age,
            verbosity="medium",
            response_speed_mode=speed,
            empathy=0.55,
            humor=0.4,
            directness=0.5,
            explanation_depth=0.4,
            safety_priority=0.2,
            ask_back_probability=0.2,
            max_questions=1,
            max_sentences=6,
            should_simplify_vocabulary=assessment.needs_simple_vocabulary,
            should_offer_choices=False,
            should_use_examples=False,
            should_request_clarification=False,
            allow_roleplay_narration=True,
        )

    return ResponseStrategy(
        interaction_type="normal",
        target_age=assessment.target_age,
        verbosity="medium",
        response_speed_mode=speed,
        empathy=0.5,
        humor=0.35,
        directness=0.6,
        explanation_depth=0.45,
        safety_priority=0.2,
        ask_back_probability=0.2,
        max_questions=1,
        max_sentences=5,
        should_simplify_vocabulary=assessment.needs_simple_vocabulary,
        should_offer_choices=(assessment.target_age == "child"),
        should_use_examples=False,
        should_request_clarification=False,
    )
