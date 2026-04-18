from __future__ import annotations

from typing import Optional

from persona_core.character_runtime.models import (
    CharacterAsset,
    CharacterLocaleProfile,
    ResolvedCharacterBehavior,
    ResponseStrategy,
    SafetyOverlay,
    SituationAssessment,
)


def root_rules_block() -> str:
    return "\n".join(
        [
            "# System root rules",
            "- You are the character themselves, not a generic assistant imitating the character.",
            "- Preserve the character's identity, tone, values, and speaking habits in every reply.",
            "- Situation adaptation changes how the character handles the moment, not who the character is.",
            "- Never break character into generic assistant phrasing.",
        ]
    )


def control_plane_block(asset: CharacterAsset) -> str:
    payload = asset.control_plane_en if isinstance(asset.control_plane_en, dict) else {}
    if not payload:
        return ""
    lines: list[str] = ["# English control plane"]
    summary = str(payload.get("summary") or "").strip()
    if summary:
        lines.append(f"- Summary: {summary}")
    for key, title in (
        ("identity_rules", "Identity rules"),
        ("conversation_rules", "Conversation rules"),
        ("child_rules", "Child-facing rules"),
        ("sos_rules", "SOS / crisis rules"),
        ("style_rules", "Style rules"),
        ("avoid_rules", "Avoid rules"),
    ):
        values = payload.get(key)
        if isinstance(values, list):
            values = [str(x).strip() for x in values if str(x).strip()]
            if values:
                lines.append(f"- {title}:")
                lines.extend(f"  - {item}" for item in values)
    return "\n".join(lines)


def character_soul_block(
    asset: CharacterAsset,
    locale_profile: Optional[CharacterLocaleProfile] = None,
    resolved_locale: Optional[str] = None,
) -> str:
    first_person = asset.soul.first_person
    second_person = asset.soul.second_person_default
    locale_name = str(resolved_locale or "").lower()
    is_japanese_surface = locale_name.startswith("ja")
    if locale_profile is not None:
        if locale_profile.first_person:
            first_person = locale_profile.first_person
        if locale_profile.second_person_default:
            second_person = locale_profile.second_person_default
    lines: list[str] = [
        "# Character soul",
        f"- Character id: {asset.id}",
        f"- Character name: {asset.name}",
    ]
    if asset.title:
        lines.append(f"- Title: {asset.title}")
    if first_person:
        lines.append(f"- First person: {first_person}")
    if second_person:
        lines.append(f"- Default second person: {second_person}")
    lines.append(f"- Tone: {asset.soul.tone}")
    if asset.soul.catchphrases and is_japanese_surface:
        lines.append("- Catchphrases / recurring flavor:")
        lines.extend(f"  - {item}" for item in asset.soul.catchphrases)
    elif asset.soul.catchphrases and not is_japanese_surface:
        lines.append("- Do not carry over Japanese stock phrases literally into non-Japanese output.")
    if asset.style.speech_rules:
        lines.append("- Speech rules:")
        lines.extend(f"  - {item}" for item in asset.style.speech_rules)
    if asset.style.metaphor_style:
        lines.append(f"- Metaphor / imagery style: {asset.style.metaphor_style}")
    if asset.soul.forbidden_expressions:
        lines.append("- Forbidden expressions:")
        lines.extend(f"  - {item}" for item in asset.soul.forbidden_expressions)
    return "\n".join(lines)


def behavior_block(behavior: ResolvedCharacterBehavior) -> str:
    lines: list[str] = [
        "# Character situational behavior",
        f"- Scene: {behavior.scene}",
        f"- Emotional tone: {behavior.emotional_tone}",
        f"- Explanation style: {behavior.explanation_style}",
        f"- Guidance style: {behavior.guidance_style}",
        f"- Humor policy: {behavior.humor_policy}",
        f"- Question style: {behavior.question_style}",
        f"- Sentence style: {behavior.sentence_style}",
        f"- Vocabulary style: {behavior.vocabulary_style}",
        f"- Question limit from behavior: {behavior.question_limit}",
        f"- Support guidance level: {behavior.support_guidance_level}",
        f"- Humor allowed by behavior: {str(bool(behavior.humor_allowed)).lower()}",
    ]
    if behavior.active_traits:
        lines.append("- Active traits:")
        lines.extend(f"  - {trait}" for trait in behavior.active_traits)
    if behavior.applied_layers:
        lines.append("- Applied behavior layers:")
        lines.extend(f"  - {layer}" for layer in behavior.applied_layers)
    if behavior.priority_notes:
        lines.append("- Priority notes:")
        lines.extend(f"  - {note}" for note in behavior.priority_notes)
    if behavior.hard_constraints:
        lines.append("- Hard constraints:")
        lines.extend(f"  - {constraint}" for constraint in behavior.hard_constraints)
    return "\n".join(lines)


def safety_block(safety: SafetyOverlay) -> str:
    lines: list[str] = [
        "# Safety constraints",
        f"- Safety mode: {safety.mode}",
        f"- Priority: {safety.priority}",
        f"- Preserve character identity: {str(bool(safety.preserve_character_identity)).lower()}",
        f"- Humor allowed: {str(bool(safety.allow_humor)).lower()}",
        f"- Max questions under safety layer: {safety.max_questions}",
    ]
    if safety.must_offer_support_guidance:
        lines.append("- Support guidance is mandatory in this response.")
    if safety.must_simplify_vocabulary:
        lines.append("- Vocabulary simplification is mandatory in this response.")
    if safety.must_avoid_method_details:
        lines.append("- Do not include dangerous method details.")
    if safety.must_avoid_dependency_cues:
        lines.append("- Do not use wording that encourages emotional dependence on the character.")
    if safety.must_include:
        lines.append("- Must include:")
        lines.extend(f"  - {item}" for item in safety.must_include)
    if safety.must_avoid:
        lines.append("- Must avoid:")
        lines.extend(f"  - {item}" for item in safety.must_avoid)
    if safety.wording_rules:
        lines.append("- Wording rules:")
        lines.extend(f"  - {item}" for item in safety.wording_rules)
    return "\n".join(lines)


def strategy_block(assessment: SituationAssessment, strategy: ResponseStrategy) -> str:
    lines: list[str] = [
        "# Response strategy",
        f"- Interaction type: {strategy.interaction_type}",
        f"- Target age: {strategy.target_age}",
        f"- Verbosity: {strategy.verbosity}",
        f"- Response speed mode: {strategy.response_speed_mode}",
        f"- Empathy: {strategy.empathy}",
        f"- Humor: {strategy.humor}",
        f"- Directness: {strategy.directness}",
        f"- Explanation depth: {strategy.explanation_depth}",
        f"- Safety priority: {strategy.safety_priority}",
        f"- Ask-back probability: {strategy.ask_back_probability}",
        f"- Max questions: {strategy.max_questions}",
        f"- Max sentences: {strategy.max_sentences}",
    ]
    if strategy.should_simplify_vocabulary:
        lines.append("- Simplify vocabulary for this reply.")
    if strategy.should_offer_choices:
        lines.append("- When useful, offer a small number of concrete choices.")
    if strategy.should_offer_support_guidance:
        lines.append("- Include support guidance appropriate to the user's state.")
    if strategy.should_use_examples:
        lines.append("- A brief concrete example is allowed when it helps clarity.")
    if strategy.should_request_clarification:
        lines.append("- If the request is ambiguous, ask at most one clarifying question.")
    if strategy.allow_roleplay_narration:
        lines.append("- Light in-character narration is allowed if it fits the scene.")
    if assessment.interaction_type == "distressed_support":
        lines.extend(
            [
                "- The user sounds distressed. Respond gently, warmly, and in character.",
                "- Do not interrogate. Use at most one gentle question.",
            ]
        )
    if assessment.interaction_type == "sos_support":
        lines.extend(
            [
                "- The user may be in crisis. Stay fully in character, but be serious and kind.",
                "- Do not use dangerous details or jokes.",
                "- Encourage immediate support from a trusted person or local emergency/crisis support.",
            ]
        )
    if assessment.interaction_type == "technical":
        lines.extend(
            [
                "- Provide structured, practical explanation.",
                "- Keep the character's voice fully intact.",
            ]
        )
    if assessment.interaction_type == "playful":
        lines.append("- Keep it snappy and friendly in character.")
    return "\n".join(lines)


def locale_style_block(resolved_locale: str, locale_profile: CharacterLocaleProfile) -> str:
    lines: list[str] = [
        "# Locale style block",
        f"- Target locale: {resolved_locale}",
        f"- First person for this locale: {locale_profile.first_person or '(keep character default)'}",
        f"- Default second person for this locale: {locale_profile.second_person_default or '(keep character default)'}",
        f"- Formality policy: {locale_profile.formality_policy}",
        "- Speak naturally in the target locale without flattening the character's identity.",
        "- Treat this locale block as the surface expression layer, not as a replacement for character soul.",
    ]
    if not str(resolved_locale or "").lower().startswith("ja"):
        lines.append("- Do not emit untranslated Japanese catchphrases or sentence fragments unless the user used them first.")
    if locale_profile.tone_notes:
        lines.append("- Locale tone notes:")
        lines.extend(f"  - {item}" for item in locale_profile.tone_notes)
    if locale_profile.speech_rules:
        lines.append("- Locale speech rules:")
        lines.extend(f"  - {item}" for item in locale_profile.speech_rules)
    if locale_profile.child_style_rules:
        lines.append("- Child-facing locale rules:")
        lines.extend(f"  - {item}" for item in locale_profile.child_style_rules)
    if locale_profile.sos_style_rules:
        lines.append("- SOS locale rules:")
        lines.extend(f"  - {item}" for item in locale_profile.sos_style_rules)
    if locale_profile.lexical_preferences:
        lines.append("- Preferred lexical cues:")
        lines.extend(f"  - {item}" for item in locale_profile.lexical_preferences)
    if locale_profile.lexical_avoid:
        lines.append("- Avoid these lexical cues:")
        lines.extend(f"  - {item}" for item in locale_profile.lexical_avoid)
    if locale_profile.example_phrasings:
        lines.append("- Locale example phrasings:")
        lines.extend(f"  - {item}" for item in locale_profile.example_phrasings[:5])
    return "\n".join(lines)


def session_summary_block(session_summary: Optional[str]) -> str:
    summary = str(session_summary or "").strip()
    if not summary:
        return ""
    return "# Session context summary\n" + summary


def recent_history_block(recent_history: Optional[str]) -> str:
    summary = str(recent_history or "").strip()
    if not summary:
        return ""
    return "# Recent history\n" + summary
