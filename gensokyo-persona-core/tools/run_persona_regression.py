from __future__ import annotations

import json
from pathlib import Path

from persona_core.evaluation.scoring import score_persona_reply


def main() -> None:
    root = Path(__file__).resolve().parents[1]
    cases_path = root / "tests" / "persona_regression_cases.json"
    cases = json.loads(cases_path.read_text(encoding="utf-8"))
    report = []
    for case in cases:
        report.append(
            {
                "name": case.get("name"),
                "character_id": case.get("character_id"),
                "expected_interaction_type": case.get("expected_interaction_type"),
                "scoring_template": score_persona_reply(reply="", meta={}),
            }
        )
    out_path = root / "tests" / "persona_regression_report.template.json"
    out_path.write_text(json.dumps(report, ensure_ascii=False, indent=2), encoding="utf-8")


if __name__ == "__main__":
    main()
