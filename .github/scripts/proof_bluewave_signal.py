from __future__ import annotations

import json
import re
from pathlib import Path

HTML_PATH = Path("web/bluewave/signal.code.html")
CONFIG_PATH = Path("web/bluewave/signal.config.json")
OUT = Path("bluewave_signal_manifest.json")

REQUIRED_HTML_SNIPPETS = [
    'id="bw-signal"',
    "Blue Wave Signal",
    "social_accounts",
    "planned_not_created",
    "Planned",
    "/store",
]

FORBIDDEN_HTML_PATTERNS = [
    r"https?://",
    r"admin",
    r"dashboard",
    r"api[_-]?key",
    r"secret",
    r"token",
    r"password",
]

REQUIRED_CONFIG_KEYS = [
    "page",
    "brand",
    "mode",
    "safety",
    "hero",
    "featuredVideo",
    "podcastLinks",
    "socialLinks",
    "articles",
    "store",
]


def main() -> int:
    if not HTML_PATH.exists():
        raise SystemExit(f"missing: {HTML_PATH}")
    if not CONFIG_PATH.exists():
        raise SystemExit(f"missing: {CONFIG_PATH}")

    html = HTML_PATH.read_text(encoding="utf-8")
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))

    missing_html = [snippet for snippet in REQUIRED_HTML_SNIPPETS if snippet not in html]
    forbidden_html = []
    for pattern in FORBIDDEN_HTML_PATTERNS:
        if re.search(pattern, html, flags=re.IGNORECASE):
            forbidden_html.append(pattern)

    missing_config_keys = [key for key in REQUIRED_CONFIG_KEYS if key not in config]
    config_errors = []
    if config.get("page") != "/signal":
        config_errors.append("page must be /signal")
    if config.get("mode") != "public_scaffold":
        config_errors.append("mode must be public_scaffold")
    if not config.get("safety", {}).get("publicOnly"):
        config_errors.append("safety.publicOnly must be true")
    if config.get("safety", {}).get("privateCommandAllowed"):
        config_errors.append("safety.privateCommandAllowed must be false")

    manifest = {
        "html_file": str(HTML_PATH),
        "config_file": str(CONFIG_PATH),
        "required_html_snippets_present": not missing_html,
        "missing_html_snippets": missing_html,
        "forbidden_html_patterns_present": forbidden_html,
        "missing_config_keys": missing_config_keys,
        "config_errors": config_errors,
        "ok": not missing_html and not forbidden_html and not missing_config_keys and not config_errors,
    }
    OUT.write_text(json.dumps(manifest, indent=2), encoding="utf-8")
    print(json.dumps(manifest, indent=2))
    return 0 if manifest["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
