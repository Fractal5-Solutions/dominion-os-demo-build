#!/usr/bin/env python3
"""Classify GitHub gate states for controlled-burn source-control automation.

This script is intentionally local and side-effect free. It converts workflow or
check conclusions into a merge-readiness classification that can be used in PR
comments, local audits, or future automation.
"""

from __future__ import annotations

import json
import sys
from dataclasses import dataclass
from typing import Iterable, List, Optional

GREEN = {"success"}
RED = {"failure", "timed_out", "action_required"}
BLOCKED = {"startup_failure", "stale", "neutral"}
PENDING = {"queued", "in_progress", "requested", "waiting", "pending"}
IGNORED = {"skipped"}


@dataclass(frozen=True)
class Gate:
    name: str
    status: Optional[str] = None
    conclusion: Optional[str] = None
    required: bool = True

    @property
    def state(self) -> str:
        value = (self.conclusion or self.status or "unknown").lower()
        return value

    @property
    def classification(self) -> str:
        state = self.state
        if state in GREEN:
            return "green"
        if state in RED:
            return "red"
        if state in BLOCKED:
            return "blocked"
        if state in PENDING:
            return "pending"
        if state in IGNORED:
            return "ignored"
        if state in {"unknown", "none", "null", ""}:
            return "unknown"
        return "unknown"


def classify(gates: Iterable[Gate]) -> dict:
    items: List[Gate] = list(gates)
    required = [gate for gate in items if gate.required]

    blockers = [
        gate
        for gate in required
        if gate.classification in {"red", "blocked", "pending", "unknown"}
    ]

    return {
        "merge_ready": not blockers,
        "summary": {
            "total": len(items),
            "required": len(required),
            "green": sum(g.classification == "green" for g in items),
            "red": sum(g.classification == "red" for g in items),
            "blocked": sum(g.classification == "blocked" for g in items),
            "pending": sum(g.classification == "pending" for g in items),
            "unknown": sum(g.classification == "unknown" for g in items),
            "ignored": sum(g.classification == "ignored" for g in items),
        },
        "gates": [
            {
                "name": gate.name,
                "state": gate.state,
                "classification": gate.classification,
                "required": gate.required,
            }
            for gate in items
        ],
        "blockers": [
            {
                "name": gate.name,
                "state": gate.state,
                "classification": gate.classification,
            }
            for gate in blockers
        ],
    }


def load_gates(payload: object) -> List[Gate]:
    if not isinstance(payload, list):
        raise ValueError("input JSON must be a list of gate objects")

    gates: List[Gate] = []
    for index, item in enumerate(payload):
        if not isinstance(item, dict):
            raise ValueError(f"gate at index {index} must be an object")
        name = str(item.get("name") or item.get("workflow") or item.get("context") or "unnamed")
        status = item.get("status")
        conclusion = item.get("conclusion")
        required = bool(item.get("required", True))
        gates.append(Gate(name=name, status=status, conclusion=conclusion, required=required))
    return gates


def main() -> int:
    try:
        payload = json.load(sys.stdin)
        result = classify(load_gates(payload))
    except Exception as exc:  # noqa: BLE001 - CLI needs concise failure output
        print(json.dumps({"merge_ready": False, "error": str(exc)}, indent=2))
        return 2

    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["merge_ready"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
