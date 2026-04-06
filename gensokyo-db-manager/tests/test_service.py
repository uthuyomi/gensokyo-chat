from __future__ import annotations

import sys
import unittest
from pathlib import Path
from types import SimpleNamespace

sys.path.insert(0, str(Path(__file__).resolve().parents[1]))
sys.modules.setdefault("trafilatura", SimpleNamespace(extract=lambda *args, **kwargs: ""))
sys.modules.setdefault("rapidfuzz", SimpleNamespace(fuzz=SimpleNamespace(token_set_ratio=lambda a, b: 100 if a == b else 50)))

from app.models import ClaimIngestRequest
from app.service import (
    build_alerts,
    build_claim_fingerprint,
    canonicalize_url,
    find_near_duplicate_claim,
    resolve_policy,
)


class ServiceTests(unittest.TestCase):
    def test_canonicalize_url_removes_tracking(self) -> None:
        url = "https://www.Example.com/path/?utm_source=x&ref=abc&id=1"
        self.assertEqual(canonicalize_url(url), "https://example.com/path?id=1")

    def test_claim_fingerprint_is_stable(self) -> None:
        req_a = ClaimIngestRequest(entity_kind="character", entity_id="reimu", claim_text=" 博麗霊夢 は 巫女 です ", sources=[])
        req_b = ClaimIngestRequest(entity_kind="character", entity_id="reimu", claim_text="博麗霊夢 は 巫女 です", sources=[])
        self.assertEqual(build_claim_fingerprint(req_a), build_claim_fingerprint(req_b))

    def test_find_near_duplicate_claim(self) -> None:
        req = ClaimIngestRequest(entity_kind="character", entity_id="marisa", claim_text="霧雨魔理沙は魔法使いです", sources=[])
        fingerprint = build_claim_fingerprint(req)
        duplicate = find_near_duplicate_claim(
            req,
            [{"id": "claim-1", "claim_text": "霧雨魔理沙は魔法使いです", "claim_fingerprint": fingerprint}],
            fingerprint,
        )
        self.assertEqual(duplicate.get("id"), "claim-1")

    def test_alert_builder_emits_backlog_warning(self) -> None:
        report = {
            "health_flags": {"pending_claim_backlog": 60, "open_conflicts": 0},
            "duplicate_indicators": {"claim_fingerprint_collisions": 0},
        }
        alerts = build_alerts(report, [])
        self.assertTrue(any(alert["kind"] == "pending_backlog" for alert in alerts))

    def test_policy_resolution_merges_defaults(self) -> None:
        policy = resolve_policy("auto_review", {"official_secondary_min_sources": 3})
        self.assertEqual(policy["official_secondary_min_sources"], 3)
        self.assertIn("official_primary_min_authority", policy)


if __name__ == "__main__":
    unittest.main()
