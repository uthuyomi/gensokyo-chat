from __future__ import annotations

from typing import List

from persona_core.character_runtime.models import (
    CharacterAsset,
    CharacterBehaviorProfile,
    ResolvedCharacterBehavior,
    SituationAssessment,
)


def _merge_profiles(*profiles: CharacterBehaviorProfile) -> ResolvedCharacterBehavior:
    merged = ResolvedCharacterBehavior()
    notes: List[str] = []
    constraints: List[str] = []
    traits: List[str] = []
    question_limit = merged.question_limit
    support_guidance_level = merged.support_guidance_level
    humor_allowed = merged.humor_allowed

    for profile in profiles:
        if not isinstance(profile, CharacterBehaviorProfile):
            continue
        merged.emotional_tone = profile.emotional_tone or merged.emotional_tone
        merged.explanation_style = profile.explanation_style or merged.explanation_style
        merged.guidance_style = profile.guidance_style or merged.guidance_style
        merged.humor_policy = profile.humor_policy or merged.humor_policy
        merged.question_style = profile.question_style or merged.question_style
        merged.sentence_style = profile.sentence_style or merged.sentence_style
        merged.vocabulary_style = profile.vocabulary_style or merged.vocabulary_style
        notes.extend(profile.priority_notes or [])
        constraints.extend(profile.hard_constraints or [])
        traits.extend(profile.active_traits or [])
        question_limit = max(0, min(question_limit, int(profile.question_limit)))
        support_guidance_level = max(float(support_guidance_level), float(profile.support_guidance_level))
        humor_allowed = bool(humor_allowed and profile.humor_allowed)

    merged.priority_notes = notes
    merged.hard_constraints = constraints
    merged.active_traits = list(dict.fromkeys(t for t in traits if str(t).strip()))
    merged.question_limit = question_limit
    merged.support_guidance_level = support_guidance_level
    merged.humor_allowed = humor_allowed
    return merged


def _base_behavior(asset: CharacterAsset) -> CharacterBehaviorProfile:
    tone = str(asset.soul.tone or "in_character").strip() or "in_character"
    speech_rules = list(asset.style.speech_rules or [])
    do_rules = list(asset.soul.core_traits or [])
    dont_rules = list(asset.soul.forbidden_expressions or [])
    return CharacterBehaviorProfile(
        emotional_tone=tone,
        explanation_style="natural",
        guidance_style="in_character",
        humor_policy=asset.style.humor_style or "keep_character_humor",
        question_style=asset.style.question_style or "natural",
        sentence_style=asset.style.sentence_style or "follow_character_prompt",
        vocabulary_style=asset.style.vocabulary_style or "follow_character_prompt",
        priority_notes=[str(x).strip() for x in [*speech_rules, *do_rules] if str(x).strip()],
        hard_constraints=[str(x).strip() for x in dont_rules if str(x).strip()],
        active_traits=list(asset.style.preferred_topics or []),
        question_limit=max(0, int((asset.safety.max_question_count_by_mode or {}).get("normal", 1))),
        humor_allowed=True,
    )


def _child_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="gentle_in_character",
        explanation_style="simple_and_concrete",
        guidance_style="reassuring_in_character",
        humor_policy="kind_and_safe",
        question_style="minimal_and_clear",
        sentence_style="short",
        vocabulary_style="simple",
        priority_notes=[
            "Use shorter sentences.",
            "Use simpler words while remaining fully in character.",
            "Prefer concrete phrasing over abstract explanation.",
        ],
        hard_constraints=[
            "Do not become generic assistant-like while simplifying vocabulary.",
        ],
        active_traits=["child_facing"],
        question_limit=1,
    )


def _teen_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="clear_in_character",
        explanation_style="concrete",
        guidance_style="steady_in_character",
        humor_policy="natural_and_safe",
        question_style="clear",
        sentence_style="medium",
        vocabulary_style="slightly_simplified",
        priority_notes=[
            "Keep wording direct and easy to follow without sounding childish.",
        ],
        active_traits=["teen_facing"],
        question_limit=1,
    )


def _adult_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="default_adult_in_character",
        explanation_style="natural",
        guidance_style="in_character",
        humor_policy="keep_character_humor",
        question_style="natural",
        sentence_style="default",
        vocabulary_style="default",
        active_traits=["adult_facing"],
    )


def _distressed_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="warm_in_character",
        explanation_style="careful",
        guidance_style="supportive_in_character",
        humor_policy="very_light_only_if_natural",
        question_style="at_most_one_gentle_question",
        sentence_style="steady",
        vocabulary_style="clear",
        priority_notes=[
            "Acknowledge the user's distress first.",
            "Do not rush into abstract analysis before emotional grounding.",
        ],
        hard_constraints=[
            "Do not interrogate the user.",
        ],
        active_traits=["distress_support"],
        support_guidance_level=0.45,
        question_limit=1,
    )


def _sos_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="serious_and_kind_in_character",
        explanation_style="direct_and_clear",
        guidance_style="immediate_support_in_character",
        humor_policy="none",
        question_style="minimal",
        sentence_style="short_and_clear",
        vocabulary_style="clear",
        priority_notes=[
            "Prioritize immediate safety and connection to trusted support.",
            "Stay fully in character while speaking plainly and urgently.",
        ],
        hard_constraints=[
            "No jokes.",
            "Do not include dangerous details.",
            "Do not romanticize self-harm or disappearance.",
        ],
        active_traits=["sos_support"],
        support_guidance_level=1.0,
        question_limit=0,
        humor_allowed=False,
    )


def _technical_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="confident_in_character",
        explanation_style="structured_and_practical",
        guidance_style="stepwise_in_character",
        humor_policy="light_if_natural",
        question_style="precise",
        sentence_style="structured",
        vocabulary_style="technical",
        priority_notes=[
            "Prefer stepwise explanation.",
            "Lead with practical structure and concrete tradeoffs.",
        ],
        active_traits=["technical"],
    )


def _info_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="clear_in_character",
        explanation_style="structured_and_clear",
        guidance_style="explanatory_in_character",
        humor_policy="light_if_natural",
        question_style="focused",
        sentence_style="structured",
        vocabulary_style="clear",
        priority_notes=[
            "Answer the user's question directly before elaborating.",
            "Use examples when they improve clarity.",
        ],
        active_traits=["info"],
    )


def _meta_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="reflective_in_character",
        explanation_style="structured",
        guidance_style="clear_in_character",
        humor_policy="light_if_natural",
        question_style="focused",
        sentence_style="structured",
        vocabulary_style="clear",
        active_traits=["meta"],
    )


def _playful_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="playful_in_character",
        explanation_style="light",
        guidance_style="casual_in_character",
        humor_policy="active",
        question_style="light",
        sentence_style="snappy",
        vocabulary_style="default",
        active_traits=["playful"],
    )


def _first_time_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="welcoming_in_character",
        explanation_style="clear",
        guidance_style="approachable_in_character",
        humor_policy="light_until_relationship_forms",
        question_style="minimal_and_clear",
        sentence_style="steady",
        vocabulary_style="clear",
        priority_notes=[
            "Assume the relationship is not established yet.",
            "Avoid overfamiliar framing while staying in character.",
        ],
        active_traits=["first_time_user"],
        question_limit=1,
    )


def _close_behavior() -> CharacterBehaviorProfile:
    return CharacterBehaviorProfile(
        emotional_tone="familiar_in_character",
        explanation_style="natural",
        guidance_style="warm_in_character",
        humor_policy="keep_character_humor",
        question_style="natural",
        sentence_style="default",
        vocabulary_style="default",
        priority_notes=[
            "Allow familiar warmth if it fits the character.",
        ],
        active_traits=["close_user"],
    )


def resolve_character_behavior(
    *,
    asset: CharacterAsset,
    assessment: SituationAssessment,
) -> ResolvedCharacterBehavior:
    base = _base_behavior(asset)
    layers: list[CharacterBehaviorProfile] = [base]
    applied_layers: list[str] = ["base"]
    sb = asset.situational_behavior

    scene = "normal"

    if assessment.target_age == "child":
        layers.extend([_child_behavior(), sb.toward_child])
        applied_layers.append("toward_child")
        scene = "child"
    elif assessment.target_age == "teen":
        layers.extend([_teen_behavior(), sb.toward_teen])
        applied_layers.append("toward_teen")
    elif assessment.target_age == "adult":
        layers.extend([_adult_behavior(), sb.toward_adult])
        applied_layers.append("toward_adult")

    if assessment.relationship_stage == "first_time":
        layers.extend([_first_time_behavior(), sb.toward_first_time_user])
        applied_layers.append("toward_first_time_user")
    elif assessment.relationship_stage == "close":
        layers.extend([_close_behavior(), sb.toward_close_user])
        applied_layers.append("toward_close_user")

    if assessment.interaction_type == "distressed_support":
        layers.extend([_distressed_behavior(), sb.toward_distressed_user])
        applied_layers.append("toward_distressed_user")
        scene = "distressed_support"
    elif assessment.interaction_type == "sos_support":
        layers.extend([_sos_behavior(), sb.toward_sos_user])
        applied_layers.append("toward_sos_user")
        scene = "sos_support"
    elif assessment.interaction_type == "technical":
        layers.extend([_technical_behavior(), sb.toward_technical_question])
        applied_layers.append("toward_technical_question")
        scene = "technical"
    elif assessment.interaction_type == "info":
        layers.extend([_info_behavior(), sb.toward_information_request])
        applied_layers.append("toward_information_request")
        scene = "normal"
    elif assessment.interaction_type == "meta":
        layers.extend([_meta_behavior(), sb.toward_meta_topic])
        applied_layers.append("toward_meta_topic")
        scene = "meta"
    elif assessment.interaction_type == "playful":
        layers.extend([_playful_behavior(), sb.toward_playful_exchange])
        applied_layers.append("toward_playful_exchange")
        scene = "playful"
    elif assessment.interaction_type == "roleplay":
        scene = "roleplay"
        applied_layers.append("toward_roleplay")

    merged = _merge_profiles(*layers)
    merged.scene = scene  # type: ignore[assignment]
    merged.applied_layers = applied_layers
    return merged
