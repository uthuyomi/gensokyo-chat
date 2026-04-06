from __future__ import annotations

from typing import List

from app.models import DiscoverySourceRequest


def build_official_touhou_preset(world_id: str = "gensokyo_main") -> List[DiscoverySourceRequest]:
    return [
        DiscoverySourceRequest(
            world_id=world_id,
            source_name="Touhou Project News RSS",
            source_kind="rss",
            start_url="https://touhou-project.news/feed/",
            topic="official_news",
            claim_type="fact",
            layer="official_primary",
            include_patterns=["touhou-project.news"],
            exclude_patterns=["/tag/", "/category/"],
            max_urls_per_run=20,
            metadata={"preset": "official_touhou", "priority": "high"},
        ),
        DiscoverySourceRequest(
            world_id=world_id,
            source_name="Team Shanghai Alice Index",
            source_kind="index_page",
            start_url="https://www16.big.or.jp/~zun/",
            topic="official_site",
            claim_type="fact",
            layer="official_primary",
            include_patterns=["big.or.jp/~zun", "www16.big.or.jp/~zun"],
            max_urls_per_run=20,
            metadata={"preset": "official_touhou", "priority": "high"},
        ),
        DiscoverySourceRequest(
            world_id=world_id,
            source_name="Tasofro News Index",
            source_kind="index_page",
            start_url="https://tasofro.net/",
            topic="official_collab",
            claim_type="fact",
            layer="official_primary",
            include_patterns=["tasofro.net"],
            exclude_patterns=["/contact", "/privacy"],
            max_urls_per_run=20,
            metadata={"preset": "official_touhou", "priority": "medium"},
        ),
    ]


def build_discovery_preset(preset_name: str, world_id: str = "gensokyo_main") -> List[DiscoverySourceRequest]:
    if preset_name == "official_touhou":
        return build_official_touhou_preset(world_id=world_id)
    return []
