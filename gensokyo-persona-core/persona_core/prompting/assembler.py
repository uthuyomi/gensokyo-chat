from __future__ import annotations

from typing import Optional

from persona_core.character_runtime.models import (
    CharacterAsset,
    CharacterLocaleProfile,
    CharacterPromptModes,
    ResolvedCharacterBehavior,
    ResponseStrategy,
    SafetyOverlay,
    SituationAssessment,
)
from .blocks import (
    behavior_block,
    character_soul_block,
    control_plane_block,
    locale_style_block,
    recent_history_block,
    root_rules_block,
    safety_block,
    session_summary_block,
    strategy_block,
)


def assemble_character_system_prompt(
    *,
    asset: CharacterAsset,
    assessment: SituationAssessment,
    behavior: ResolvedCharacterBehavior,
    safety: SafetyOverlay,
    strategy: ResponseStrategy,
    locale_profile: CharacterLocaleProfile,
    resolved_locale: str,
    session_summary: Optional[str] = None,
    recent_history: Optional[str] = None,
    chat_mode: Optional[str] = None,
    external_system: Optional[str] = None,
    external_knowledge: Optional[str] = None,
) -> str:
    mode = str(chat_mode or "partner").strip().lower()
    locale_prompts = asset.localized_prompts.get(resolved_locale) if isinstance(asset.localized_prompts, dict) else None
    if not isinstance(locale_prompts, CharacterPromptModes):
        locale_prompts = CharacterPromptModes.model_validate(locale_prompts or {})

    def _pick_prompt(prompts: CharacterPromptModes) -> str:
        if mode == "roleplay" and prompts.roleplay.strip():
            return prompts.roleplay
        if mode == "coach" and prompts.coach.strip():
            return prompts.coach
        return prompts.partner

    prompt_base = _pick_prompt(asset.prompts)
    localized_prompt_base = _pick_prompt(locale_prompts)
    if localized_prompt_base.strip():
        prompt_base = localized_prompt_base

    parts: list[str] = [
        root_rules_block(),
        control_plane_block(asset),
        prompt_base.strip(),
        character_soul_block(asset, locale_profile, resolved_locale),
        behavior_block(behavior),
        safety_block(safety),
        strategy_block(assessment, strategy),
        locale_style_block(resolved_locale, locale_profile),
        session_summary_block(session_summary),
        recent_history_block(recent_history),
    ]

    if external_system and str(external_system).strip():
        parts.append("# External runtime notes\n" + str(external_system).strip())
    if external_knowledge and str(external_knowledge).strip():
        parts.append("# Relevant external context\n" + str(external_knowledge).strip())

    return "\n\n".join(part for part in parts if str(part or "").strip())


class PromptAssembler:
    def assemble(
        self,
        *,
        asset: CharacterAsset,
        assessment: SituationAssessment,
        behavior: ResolvedCharacterBehavior,
        safety: SafetyOverlay,
        strategy: ResponseStrategy,
        locale_profile: CharacterLocaleProfile,
        resolved_locale: str,
        session_summary: Optional[str] = None,
        recent_history: Optional[str] = None,
        chat_mode: Optional[str] = None,
        external_system: Optional[str] = None,
        external_knowledge: Optional[str] = None,
    ) -> str:
        return assemble_character_system_prompt(
            asset=asset,
            assessment=assessment,
            behavior=behavior,
            safety=safety,
            strategy=strategy,
            locale_profile=locale_profile,
            resolved_locale=resolved_locale,
            session_summary=session_summary,
            recent_history=recent_history,
            chat_mode=chat_mode,
            external_system=external_system,
            external_knowledge=external_knowledge,
        )
