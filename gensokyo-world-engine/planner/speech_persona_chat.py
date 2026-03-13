from __future__ import annotations

from dataclasses import dataclass
from typing import Any, Dict, Optional

import httpx

from .interfaces import PlannerContext


def _extract_user_text(ctx: PlannerContext) -> str:
    payload = ctx.source_event.get("payload") if isinstance(ctx.source_event.get("payload"), dict) else {}
    t = payload.get("text")
    return str(t or "").strip()


def _sanitize_reply(text: str) -> str:
    s = str(text or "").strip()
    if not s:
        return s
    # Remove common policy/system prefaces if they leak into output.
    bad_prefixes = (
        "安全/",
        "安全",
        "同一性",
        "システム",
        "注:",
    )
    lines = [ln.strip() for ln in s.splitlines() if ln.strip()]
    while lines and any(lines[0].startswith(p) for p in bad_prefixes):
        lines.pop(0)
    s2 = "\n".join(lines).strip()
    return s2 or s


@dataclass(frozen=True)
class PersonaChatClient:
    base_url: str  # e.g. http://127.0.0.1:8000
    bearer_token: Optional[str] = None
    internal_token: Optional[str] = None
    timeout_sec: float = 25.0

    async def generate_reply(self, speaker_character_id: str, ctx: PlannerContext) -> str:
        """
        Calls sigmaris_core /persona/chat to generate ONLY the spoken line.

        This MUST NOT update world state. We enforce that by:
        - using the endpoint only for text generation
        - asking for plain dialogue output
        - ignoring any structured outputs besides reply text
        """
        user_text = _extract_user_text(ctx)
        if not user_text:
            return ""

        system = (
            "You are an NPC in a fictional world. Output MUST be a single natural Japanese spoken line.\n"
            "Rules:\n"
            "- Output ONLY the line to speak. No preface, no policy text, no meta commentary.\n"
            "- Do NOT describe actions. Do NOT output JSON.\n"
            "- Do NOT claim to update world state.\n"
            "- Keep it short (<= 40 Japanese characters) unless the user asked a direct question.\n"
        )

        session_id = f"world:{ctx.world_id}:{ctx.location_id}:npc:{speaker_character_id}"
        req: Dict[str, Any] = {
            "session_id": session_id,
            "message": user_text,
            "character_id": speaker_character_id,
            "chat_mode": "roleplay",
            "system": system,
            "gen": {"temperature": 0.7, "max_tokens": 120},
        }
        if ctx.user and getattr(ctx.user, "user_id", None):
            req["user_id"] = str(ctx.user.user_id)

        headers: Dict[str, str] = {"Content-Type": "application/json", "Accept": "application/json"}
        if self.bearer_token:
            headers["Authorization"] = f"Bearer {self.bearer_token}"
        if self.internal_token:
            headers["X-Sigmaris-Internal-Token"] = self.internal_token

        url = self.base_url.rstrip("/") + "/persona/chat"
        async with httpx.AsyncClient(timeout=self.timeout_sec) as client:
            r = await client.post(url, headers=headers, json=req)
            if r.status_code >= 400:
                return ""
            data = r.json() if r.headers.get("content-type", "").startswith("application/json") else {}
            reply = data.get("reply") if isinstance(data, dict) else ""
            return _sanitize_reply(str(reply or ""))

    async def generate_npc_dialogue_line(
        self,
        *,
        speaker_character_id: str,
        listener_character_id: str,
        location_id: str,
        ctx: PlannerContext,
        previous_text: Optional[str],
        world_context: str = "",
    ) -> str:
        """
        Calls sigmaris_core /persona/chat to generate a single NPC-to-NPC dialogue line.

        Inputs:
        - speaker_character_id: character prompt/persona to use
        - listener_character_id: who the speaker is addressing
        - previous_text: if provided, must reply to it (2nd turn)
        - world_context: optional short summary of world state/events to ground the line
        """
        loc = str(location_id or ctx.location_id or "").strip()
        prev = str(previous_text or "").strip()

        # We feed "message" as the previous line (turn2), or a short situation prompt (turn1).
        if prev:
            message = f"相手の発言: {prev}\n相手({listener_character_id})に返答して。"
        else:
            message = f"相手({listener_character_id})に話しかけて。"

        system = (
            "You are an NPC in a fictional world. Output MUST be a single natural Japanese spoken line.\n"
            "Situation:\n"
            f"- Location: {loc}\n"
            f"- You (speaker): {speaker_character_id}\n"
            f"- Listener: {listener_character_id}\n"
        )
        if world_context.strip():
            system += f"- World context: {world_context.strip()}\n"
        system += (
            "Rules:\n"
            "- Output ONLY the line to speak. No preface, no policy text, no meta commentary.\n"
            "- Do NOT describe actions. Do NOT output JSON.\n"
            "- Do NOT claim to update world state.\n"
            "- Keep it short and spoken (aim <= 45 Japanese characters).\n"
            "- Use your character's voice/persona.\n"
        )

        session_id = f"world:{ctx.world_id}:{loc}:npc_dialogue:{speaker_character_id}:{listener_character_id}"
        req: Dict[str, Any] = {
            "session_id": session_id,
            "message": message,
            "character_id": speaker_character_id,
            "chat_mode": "roleplay",
            "system": system,
            "gen": {"temperature": 0.8, "max_tokens": 180},
        }

        headers: Dict[str, str] = {"Content-Type": "application/json", "Accept": "application/json"}
        if self.bearer_token:
            headers["Authorization"] = f"Bearer {self.bearer_token}"
        if self.internal_token:
            headers["X-Sigmaris-Internal-Token"] = self.internal_token

        url = self.base_url.rstrip("/") + "/persona/chat"
        async with httpx.AsyncClient(timeout=self.timeout_sec) as client:
            r = await client.post(url, headers=headers, json=req)
            if r.status_code >= 400:
                return ""
            data = r.json() if r.headers.get("content-type", "").startswith("application/json") else {}
            reply = data.get("reply") if isinstance(data, dict) else ""
            return _sanitize_reply(str(reply or ""))
