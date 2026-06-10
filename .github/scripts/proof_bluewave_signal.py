from __future__ import annotations

import json
import re
from pathlib import Path

HTML_PATH = Path("web/bluewave/signal.code.html")
OUT = Path("bluewave_signal_manifest.json")

REQUIRED_SNIPPETS = [
    'id="bw-signal"',
    "Blue Wave Signal",
    "social_accounts",
    "planned_not_created",
    "Planned",
    "/store",
]

FORBIDDEN_PATTERNS = [
    r"https?://",
    r"admin",
    r"dashboard",
    r"api[_-]?key",
    r"secret",
    r"token",
    r"password",
]


def main() -> int:
    if not HTML_PATH.exists():
        raise SystemExit(f"missing: {HTML_PATH}")

    html = HTML_PATH.read_text(encoding="utf-8")
    missing = [snippet for snippet in REQUIRED_SNIPPETS if snippet not in html]
    forbidden = []
    for pattern in FORBIDDEN_PATTERNS:
        if re.search(pattern, html, flags=re.IGNORECASE):
            forbidden.append(pattern)

    manifest = {
        "file": str(HTML_PATH),
        "required_snippets_present": not missing,
        "missing_required_snippets": missing,
        "forbidden_patterns_present": forbidden,
        "ok": not missing and not forbidden,
    }
    OUT.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    return 0 if manifest["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
