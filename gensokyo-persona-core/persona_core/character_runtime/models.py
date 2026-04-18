from __future__ import annotations

from typing import Any, Dict, List, Literal, Optional

from pydantic import BaseModel, Field


class CharacterPromptModes(BaseModel):
    partner: str = ""
    roleplay: str = ""
    coach: str = ""


class CharacterSoulProfile(BaseModel):
    first_person: str = ""
    second_person_default: str = ""
    tone: str = "in_character"
    catchphrases: List[str] = Field(default_factory=list)
    core_traits: List[str] = Field(default_factory=list)
    core_values: List[str] = Field(default_factory=list)
    forbidden_expressions: List[str] = Field(default_factory=list)


class CharacterStyleProfile(BaseModel):
    sentence_style: str = "follow_character_prompt"
    vocabulary_style: str = "follow_character_prompt"
    metaphor_style: str = "in_character"
    humor_style: str = "keep_character_humor"
    care_style: str = "in_character"
    question_style: str = "natural"
    speech_rules: List[str] = Field(default_factory=list)
    preferred_topics: List[str] = Field(default_factory=list)


class CharacterLocaleProfile(BaseModel):
    locale: str = "ja-JP"
    first_person: str = ""
    second_person_default: str = ""
    tone_notes: List[str] = Field(default_factory=list)
    speech_rules: List[str] = Field(default_factory=list)
    child_style_rules: List[str] = Field(default_factory=list)
    sos_style_rules: List[str] = Field(default_factory=list)
    lexical_preferences: List[str] = Field(default_factory=list)
    lexical_avoid: List[str] = Field(default_factory=list)
    formality_policy: str = "plain"
    example_phrasings: List[str] = Field(default_factory=list)


class CharacterSafetyProfile(BaseModel):
    humor_disabled_modes: List[str] = Field(default_factory=list)
    max_question_count_by_mode: Dict[str, int] = Field(default_factory=dict)
    must_offer_support_in_sos: bool = True
    must_reduce_complexity_for_child: bool = True
    must_avoid_meta_in_critical_modes: bool = True


class CharacterBehaviorProfile(BaseModel):
    emotional_tone: str = "in_character"
    explanation_style: str = "natural"
    guidance_style: str = "in_character"
    humor_policy: str = "keep_character_humor"
    question_style: str = "natural"
    sentence_style: str = "default"
    vocabulary_style: str = "default"
    priority_notes: List[str] = Field(default_factory=list)
    hard_constraints: List[str] = Field(default_factory=list)
    active_traits: List[str] = Field(default_factory=list)
    support_guidance_level: float = 0.0
    question_limit: int = 1
    humor_allowed: bool = True


class CharacterSituationalBehaviorProfile(BaseModel):
    toward_child: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_teen: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_adult: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_distressed_user: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_sos_user: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_technical_question: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_information_request: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_close_user: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_first_time_user: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_meta_topic: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)
    toward_playful_exchange: CharacterBehaviorProfile = Field(default_factory=CharacterBehaviorProfile)


class CharacterAsset(BaseModel):
    id: str
    name: str
    title: str = ""
    world: Dict[str, Any] = Field(default_factory=dict)
    control_plane_en: Dict[str, Any] = Field(default_factory=dict)
    prompts: CharacterPromptModes = Field(default_factory=CharacterPromptModes)
    localized_prompts: Dict[str, CharacterPromptModes] = Field(default_factory=dict)
    prompt_version: Optional[str] = None
    gen_params: Dict[str, Any] = Field(default_factory=dict)
    soul: CharacterSoulProfile = Field(default_factory=CharacterSoulProfile)
    style: CharacterStyleProfile = Field(default_factory=CharacterStyleProfile)
    safety: CharacterSafetyProfile = Field(default_factory=CharacterSafetyProfile)
    situational_behavior: CharacterSituationalBehaviorProfile = Field(default_factory=CharacterSituationalBehaviorProfile)
    locales: Dict[str, CharacterLocaleProfile] = Field(default_factory=dict)
    default_locale: str = "ja-JP"


class ResolvedCharacterBehavior(BaseModel):
    scene: Literal[
        "normal",
        "child",
        "distressed_support",
        "sos_support",
        "technical",
        "meta",
        "playful",
        "roleplay",
    ] = "normal"
    emotional_tone: str = "in_character"
    explanation_style: str = "natural"
    guidance_style: str = "in_character"
    humor_policy: str = "keep_character_humor"
    question_style: str = "natural"
    sentence_style: str = "default"
    vocabulary_style: str = "default"
    priority_notes: List[str] = Field(default_factory=list)
    hard_constraints: List[str] = Field(default_factory=list)
    active_traits: List[str] = Field(default_factory=list)
    support_guidance_level: float = 0.0
    question_limit: int = 1
    humor_allowed: bool = True
    applied_layers: List[str] = Field(default_factory=list)


class SafetyOverlay(BaseModel):
    mode: Literal["normal", "child", "distressed_support", "sos_support"] = "normal"
    priority: Literal["low", "medium", "high", "critical"] = "low"
    must_include: List[str] = Field(default_factory=list)
    must_avoid: List[str] = Field(default_factory=list)
    wording_rules: List[str] = Field(default_factory=list)
    preserve_character_identity: bool = True
    allow_humor: bool = True
    max_questions: int = 1
    must_offer_support_guidance: bool = False
    must_simplify_vocabulary: bool = False
    must_avoid_method_details: bool = True
    must_avoid_dependency_cues: bool = True


class UserProfile(BaseModel):
    age_group: Literal["child", "teen", "adult", "unknown"] = "unknown"
    relationship_stage: Literal["first_time", "distant", "familiar", "close", "unknown"] = "unknown"


class ClientContext(BaseModel):
    ui_type: str = "unknown"
    surface: str = "chat"
    locale: str = "ja-JP"


class ConversationProfile(BaseModel):
    response_style: Literal["fast", "balanced", "deep", "auto"] = "auto"


class SituationAssessment(BaseModel):
    interaction_type: Literal[
        "normal",
        "playful",
        "info",
        "technical",
        "distressed_support",
        "sos_support",
        "meta",
        "roleplay",
        "unclear",
    ] = "normal"
    safety_risk: Literal["none", "low", "medium", "high"] = "none"
    target_age: Literal["child", "teen", "adult", "unknown"] = "unknown"
    relationship_stage: Literal["first_time", "distant", "familiar", "close", "unknown"] = "unknown"
    distress_level: float = 0.0
    urgency_level: float = 0.0
    technicality_level: float = 0.0
    needs_simple_vocabulary: bool = False
    should_offer_support_guidance: bool = False
    should_reduce_question_count: bool = False
    matched_labels: List[str] = Field(default_factory=list)
    classifier_confidence: float = 0.0
    reasons: List[str] = Field(default_factory=list)


class ResponseStrategy(BaseModel):
    interaction_type: Literal["normal", "playful", "info", "technical", "distressed_support", "sos_support", "meta", "roleplay", "unclear"] = "normal"
    target_age: Literal["child", "teen", "adult", "unknown"] = "unknown"
    verbosity: Literal["short", "medium", "long"] = "medium"
    response_speed_mode: Literal["fast", "balanced", "deep"] = "balanced"
    empathy: float = 0.5
    humor: float = 0.3
    directness: float = 0.5
    explanation_depth: float = 0.5
    safety_priority: float = 0.5
    ask_back_probability: float = 0.3
    max_questions: int = 1
    max_sentences: int = 5
    should_simplify_vocabulary: bool = False
    should_offer_choices: bool = False
    should_offer_support_guidance: bool = False
    should_use_examples: bool = False
    should_request_clarification: bool = False
    allow_roleplay_narration: bool = False


class RuntimeMeta(BaseModel):
    character_id: str
    interaction_type: str
    safety_risk: str
    response_speed_mode: str
    strategy_snapshot: Dict[str, Any] = Field(default_factory=dict)
    situation_snapshot: Dict[str, Any] = Field(default_factory=dict)
    behavior_snapshot: Dict[str, Any] = Field(default_factory=dict)
    safety_snapshot: Dict[str, Any] = Field(default_factory=dict)
    session_summary: str = ""
    resolved_locale: str = "ja-JP"
    locale_style_snapshot: Dict[str, Any] = Field(default_factory=dict)
    tts_style: str = "default"
    animation_hint: str = "idle"
