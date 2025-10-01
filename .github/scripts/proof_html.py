from __future__ import annotations

import hashlib
import json
import re
from pathlib import Path


HTML_PATH = Path("web/sqsp/f5-applications.code.html")
OUT = Path("catalog_manifest.json")


def sha256_text(text: str) -> str:
    return hashlib.sha256(text.encode("utf-8")).hexdigest()


def main() -> int:
    if not HTML_PATH.exists():
        raise SystemExit(f"missing: {HTML_PATH}")
    html = HTML_PATH.read_text(encoding="utf-8")

    # Extract links; ensure no external absolute http(s) URLs (No-CDN rule)
    hrefs = re.findall(r'href="([^"]+)"', html)
    externals = [
        h for h in hrefs if h.startswith("http://") or h.startswith("https://")
    ]
    if externals:
        print("Found external links (disallowed):", externals)
        return 2

    manifest = {
        "file": str(HTML_PATH),
        "sha256": sha256_text(html),
        "links": hrefs,
    }
    OUT.write_text(json.dumps(manifest, indent=2))
    print("Wrote", OUT)
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
