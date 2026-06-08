#!/usr/bin/env python3
"""Audit GitHub Actions workflow startup policy risks.

This script is source-only and side-effect free. It scans workflow files for
external action references and reports whether each reference is immutable.

A reference is treated as startup-policy safe when it is:

- a local action path beginning with `./`, or
- a full-length 40-character commit SHA after `@`.

Tag references such as `@v3` and branch references such as `@main` are reported
as policy risks because strict repository or organization settings may reject
or fail them before jobs start.
"""

from __future__ import annotations

import json
import re
import sys
from dataclasses import dataclass
from pathlib import Path
from typing import Iterable, List

WORKFLOW_DIR = Path(".github/workflows")
FULL_SHA = re.compile(r"^[0-9a-fA-F]{40}$")
USES_LINE = re.compile(r"^\s*uses:\s*([^\s#]+)")


@dataclass(frozen=True)
class ActionUse:
    path: str
    line: int
    value: str

    @property
    def classification(self) -> str:
        if self.value.startswith("./"):
            return "local"
        if "@" not in self.value:
            return "unpinned"
        _, ref = self.value.rsplit("@", 1)
        if FULL_SHA.fullmatch(ref):
            return "immutable"
        return "mutable"

    @property
    def startup_safe(self) -> bool:
        return self.classification in {"local", "immutable"}


def iter_workflow_files(root: Path = WORKFLOW_DIR) -> Iterable[Path]:
    if not root.exists():
        return []
    return sorted(
        path for path in root.iterdir()
        if path.is_file() and path.suffix in {".yml", ".yaml"}
    )


def scan_file(path: Path) -> List[ActionUse]:
    findings: List[ActionUse] = []
    for line_no, line in enumerate(path.read_text(encoding="utf-8", errors="replace").splitlines(), 1):
        match = USES_LINE.match(line)
        if match:
            findings.append(ActionUse(path=str(path), line=line_no, value=match.group(1)))
    return findings


def audit() -> dict:
    uses: List[ActionUse] = []
    for path in iter_workflow_files():
        uses.extend(scan_file(path))

    risks = [use for use in uses if not use.startup_safe]
    return {
        "startup_policy_ready": not risks,
        "summary": {
            "workflow_action_uses": len(uses),
            "startup_policy_risks": len(risks),
        },
        "uses": [
            {
                "path": use.path,
                "line": use.line,
                "value": use.value,
                "classification": use.classification,
                "startup_safe": use.startup_safe,
            }
            for use in uses
        ],
        "risks": [
            {
                "path": use.path,
                "line": use.line,
                "value": use.value,
                "classification": use.classification,
            }
            for use in risks
        ],
    }


def main() -> int:
    result = audit()
    print(json.dumps(result, indent=2, sort_keys=True))
    return 0 if result["startup_policy_ready"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
