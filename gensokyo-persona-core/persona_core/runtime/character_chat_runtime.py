from __future__ import annotations

from typing import Any, Dict, Iterable, List, Optional

from persona_core.behavior.resolver import resolve_character_behavior
from persona_core.character_runtime.locale_loader import resolve_locale_profile
from persona_core.character_runtime.models import (
    ClientContext,
    CharacterAsset,
    CharacterLocaleProfile,
    ResolvedCharacterBehavior,
    ResponseStrategy,
    RuntimeMeta,
    SafetyOverlay,
    UserProfile,
)
from persona_core.character_runtime.registry import get_character_registry
from persona_core.performance.prompt_cache import get_prompt_cache
from persona_core.prompting.assembler import PromptAssembler
from persona_core.rendering.character_renderer import render_character_reply
from persona_core.safety.overlay import build_safety_overlay
from persona_core.situation.analyzer import assess_situation
from persona_core.strategy.response_strategy import build_response_strategy


class CharacterChatRuntime:
    def __init__(self, *, llm_client: Any) -> None:
        self._llm = llm_client
        self._registry = get_character_registry()
        self._prompt_assembler = PromptAssembler()
        self._prompt_cache = get_prompt_cache()

    def list_characters(self) -> list[dict[str, Any]]:
        out: list[dict[str, Any]] = []
        for asset in self._registry.list_assets():
            out.append(
                {
                    "id": asset.id,
                    "name": asset.name,
                    "title": asset.title,
                    "world": asset.world,
                    "control_plane_en": asset.control_plane_en,
                    "localized_prompt_locales": sorted((asset.localized_prompts or {}).keys()),
                    "soul": asset.soul.model_dump(),
                    "style": asset.style.model_dump(),
                    "safety": asset.safety.model_dump(),
                    "default_locale": asset.default_locale,
                    "available_locales": sorted((asset.locales or {}).keys()),
                    "available_chat_modes": [
                        mode
                        for mode, prompt in {
                            "partner": asset.prompts.partner,
                            "roleplay": asset.prompts.roleplay,
                            "coach": asset.prompts.coach,
                        }.items()
                        if str(prompt or "").strip()
                    ],
                }
            )
        return out

    def get_character(self, character_id: str) -> dict[str, Any]:
        asset = self._resolve_asset(character_id)
        return {
            "id": asset.id,
            "name": asset.name,
            "title": asset.title,
            "world": asset.world,
            "prompt_version": asset.prompt_version,
            "control_plane_en": asset.control_plane_en,
            "localized_prompts": {key: value.model_dump() for key, value in (asset.localized_prompts or {}).items()},
            "soul": asset.soul.model_dump(),
            "style": asset.style.model_dump(),
            "safety": asset.safety.model_dump(),
            "situational_behavior": asset.situational_behavior.model_dump(),
            "default_locale": asset.default_locale,
            "locales": {key: profile.model_dump() for key, profile in (asset.locales or {}).items()},
            "available_chat_modes": [
                mode
                for mode, prompt in {
                    "partner": asset.prompts.partner,
                    "roleplay": asset.prompts.roleplay,
                    "coach": asset.prompts.coach,
                }.items()
                if str(prompt or "").strip()
            ],
        }

    def _resolve_asset(self, character_id: str):
        asset = self._registry.get(character_id)
        if asset is None:
            raise KeyError(f"Unknown character_id: {character_id}")
        return asset

    def _resolve_locale(
        self,
        *,
        asset: CharacterAsset,
        client_context: Optional[Dict[str, Any]],
    ) -> tuple[str, CharacterLocaleProfile]:
        context = ClientContext.model_validate(client_context or {})
        return resolve_locale_profile(asset=asset, requested_locale=context.locale)

    def _prepare_history_context(
        self,
        history: Optional[List[Dict[str, str]]],
    ) -> tuple[List[Dict[str, str]], str, str]:
        if not isinstance(history, list) or not history:
            return [], "", ""

        normalized: List[Dict[str, str]] = []
        for item in history:
            if not isinstance(item, dict):
                continue
            role = str(item.get("role") or "").strip().lower()
            if role == "ai":
                role = "assistant"
            if role not in ("user", "assistant"):
                continue
            content = str(item.get("content") or "").strip()
            if not content:
                continue
            normalized.append({"role": role, "content": content})

        if not normalized:
            return [], "", ""

        recent = normalized[-6:]
        older = normalized[:-6]

        recent_lines = [f"- {msg['role']}: {msg['content'][:160]}" for msg in recent]
        recent_history = "\n".join(recent_lines)

        if not older:
            return recent, "", recent_history

        older_lines = [f"- {msg['role']}: {msg['content'][:120]}" for msg in older[-8:]]
        session_summary = "Earlier relevant turns:\n" + "\n".join(older_lines)
        return recent, session_summary, recent_history

    def _build_turn_layers(
        self,
        *,
        asset: CharacterAsset,
        message: str,
        user_profile: Optional[Dict[str, Any]],
        chat_mode: Optional[str],
        conversation_profile: Optional[Dict[str, Any]],
    ) -> tuple[Any, ResolvedCharacterBehavior, SafetyOverlay, ResponseStrategy]:
        assessment = assess_situation(message=message, user_profile=user_profile, chat_mode=chat_mode)
        behavior = resolve_character_behavior(asset=asset, assessment=assessment)
        safety = build_safety_overlay(assessment=assessment, character_safety=asset.safety)
        strategy = self._apply_safety_to_strategy(
            strategy=build_response_strategy(assessment=assessment, conversation_profile=conversation_profile),
            behavior=behavior,
            safety=safety,
        )
        return assessment, behavior, safety, strategy

    def _build_system_prompt(
        self,
        *,
        asset: CharacterAsset,
        assessment: Any,
        behavior: ResolvedCharacterBehavior,
        safety: SafetyOverlay,
        strategy: ResponseStrategy,
        locale_profile: CharacterLocaleProfile,
        resolved_locale: str,
        session_summary: str,
        recent_history: str,
        chat_mode: Optional[str],
        external_system: Optional[str],
        external_knowledge: Optional[str],
    ) -> str:
        prompt_key = self._prompt_cache.make_key(
            {
                "character_id": asset.id,
                "assessment": assessment.model_dump(),
                "behavior": behavior.model_dump(),
                "safety": safety.model_dump(),
                "strategy": strategy.model_dump(),
                "resolved_locale": resolved_locale,
                "locale_profile": locale_profile.model_dump(),
                "session_summary": session_summary,
                "recent_history": recent_history,
                "chat_mode": chat_mode,
                "external_system": external_system,
                "external_knowledge": external_knowledge,
            }
        )
        cached = self._prompt_cache.get(prompt_key)
        if cached is not None:
            return cached
        prompt = self._prompt_assembler.assemble(
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
        self._prompt_cache.put(prompt_key, prompt)
        return prompt

    def _build_runtime_meta(
        self,
        *,
        asset: CharacterAsset,
        assessment: Any,
        strategy: ResponseStrategy,
        behavior: ResolvedCharacterBehavior,
        safety: SafetyOverlay,
        session_summary: str,
        resolved_locale: str,
        locale_profile: CharacterLocaleProfile,
        client_context: Optional[Dict[str, Any]],
        user_profile: Optional[Dict[str, Any]],
        rendering_meta: Optional[Dict[str, Any]] = None,
    ) -> Dict[str, Any]:
        meta = RuntimeMeta(
            character_id=asset.id,
            interaction_type=assessment.interaction_type,
            safety_risk=assessment.safety_risk,
            response_speed_mode=strategy.response_speed_mode,
            strategy_snapshot=strategy.model_dump(),
            situation_snapshot=assessment.model_dump(),
            behavior_snapshot=behavior.model_dump(),
            safety_snapshot=safety.model_dump(),
            session_summary=session_summary,
            resolved_locale=resolved_locale,
            locale_style_snapshot=locale_profile.model_dump(),
            tts_style="calm" if assessment.interaction_type in ("distressed_support", "sos_support") else "default",
            animation_hint="gentle_nod" if assessment.interaction_type in ("distressed_support", "sos_support") else "idle",
        ).model_dump()
        meta["client_context"] = ClientContext.model_validate(client_context or {}).model_dump()
        meta["user_profile"] = UserProfile.model_validate(user_profile or {}).model_dump()
        meta["character_name"] = asset.name
        meta["rendering"] = rendering_meta or {}
        return meta

    def _apply_safety_to_strategy(
        self,
        *,
        strategy: ResponseStrategy,
        behavior: ResolvedCharacterBehavior,
        safety: SafetyOverlay,
    ) -> ResponseStrategy:
        updated = strategy.model_copy(deep=True)
        updated.max_questions = min(int(updated.max_questions), int(behavior.question_limit))
        updated.max_questions = min(int(updated.max_questions), int(safety.max_questions))
        if behavior.support_guidance_level >= 0.5:
            updated.should_offer_support_guidance = True
        if safety.must_simplify_vocabulary:
            updated.should_simplify_vocabulary = True
        if safety.must_offer_support_guidance:
            updated.should_offer_support_guidance = True
        if not safety.allow_humor or not behavior.humor_allowed:
            updated.humor = 0.0
        if safety.priority in ("high", "critical"):
            updated.ask_back_probability = min(float(updated.ask_back_probability), 0.1)
        if safety.priority == "critical":
            updated.max_sentences = min(int(updated.max_sentences), 4)
        return updated

    def generate(
        self,
        *,
        character_id: str,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
        chat_mode: Optional[str] = None,
        external_system: Optional[str] = None,
        external_knowledge: Optional[str] = None,
        gen: Optional[Dict[str, Any]] = None,
        user: Optional[str] = None,
        audit_ctx: Optional[Dict[str, Any]] = None,
        user_profile: Optional[Dict[str, Any]] = None,
        client_context: Optional[Dict[str, Any]] = None,
        conversation_profile: Optional[Dict[str, Any]] = None,
    ) -> tuple[str, Dict[str, Any]]:
        asset = self._resolve_asset(character_id)
        resolved_locale, locale_profile = self._resolve_locale(asset=asset, client_context=client_context)
        prepared_history, session_summary, recent_history = self._prepare_history_context(history)
        assessment, behavior, safety, strategy = self._build_turn_layers(
            asset=asset,
            message=message,
            user_profile=user_profile,
            chat_mode=chat_mode,
            conversation_profile=conversation_profile,
        )
        system_prompt = self._build_system_prompt(
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

        merged_gen = dict(asset.gen_params or {})
        if isinstance(gen, dict):
            merged_gen.update(gen)

        raw_reply = self._llm.generate_direct(
            system_prompt=system_prompt,
            user_text=message,
            history=prepared_history,
            gen=merged_gen,
            user=user,
            audit_ctx=audit_ctx,
        )
        reply, render_meta = render_character_reply(
            asset=asset,
            assessment=assessment,
            behavior=behavior,
            safety=safety,
            locale_profile=locale_profile,
            resolved_locale=resolved_locale,
            reply=raw_reply,
        )

        meta = self._build_runtime_meta(
            asset=asset,
            assessment=assessment,
            strategy=strategy,
            behavior=behavior,
            safety=safety,
            session_summary=session_summary,
            resolved_locale=resolved_locale,
            locale_profile=locale_profile,
            client_context=client_context,
            user_profile=user_profile,
            rendering_meta=render_meta,
        )
        return reply, meta

    def generate_stream(
        self,
        *,
        character_id: str,
        message: str,
        history: Optional[List[Dict[str, str]]] = None,
        chat_mode: Optional[str] = None,
        external_system: Optional[str] = None,
        external_knowledge: Optional[str] = None,
        gen: Optional[Dict[str, Any]] = None,
        user: Optional[str] = None,
        audit_ctx: Optional[Dict[str, Any]] = None,
        user_profile: Optional[Dict[str, Any]] = None,
        client_context: Optional[Dict[str, Any]] = None,
        conversation_profile: Optional[Dict[str, Any]] = None,
    ) -> tuple[Iterable[str], Dict[str, Any]]:
        asset = self._resolve_asset(character_id)
        resolved_locale, locale_profile = self._resolve_locale(asset=asset, client_context=client_context)
        prepared_history, session_summary, recent_history = self._prepare_history_context(history)
        assessment, behavior, safety, strategy = self._build_turn_layers(
            asset=asset,
            message=message,
            user_profile=user_profile,
            chat_mode=chat_mode,
            conversation_profile=conversation_profile,
        )
        system_prompt = self._build_system_prompt(
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
        merged_gen = dict(asset.gen_params or {})
        if isinstance(gen, dict):
            merged_gen.update(gen)
        stream = self._llm.generate_stream_direct(
            system_prompt=system_prompt,
            user_text=message,
            history=prepared_history,
            gen=merged_gen,
            user=user,
            audit_ctx=audit_ctx,
        )
        meta = self._build_runtime_meta(
            asset=asset,
            assessment=assessment,
            strategy=strategy,
            behavior=behavior,
            safety=safety,
            session_summary=session_summary,
            resolved_locale=resolved_locale,
            locale_profile=locale_profile,
            client_context=client_context,
            user_profile=user_profile,
            rendering_meta={"streaming": True},
        )
        return stream, meta
