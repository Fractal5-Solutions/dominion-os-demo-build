#!/usr/bin/env python3
"""Verify the public /demo-1 Squarespace surface against the canonical v2.4 contract."""

from __future__ import annotations

import argparse
import json
import sys
import time
import urllib.error
import urllib.request

DEFAULT_URL = "https://www.fractal5solutions.com/demo-1"
EXPECTED_BUILD = "demo-1-v2.4-20261002-canon-light-evidence-disciplined"

REQUIRED_TEXT = (
    EXPECTED_BUILD,
    'data-claim-mode="evidence-disciplined"',
    'data-public-runtime-claim="none"',
    "Operate the mission.",
    "Public Proof Surface",
    "Demo here. Production in the Store.",
    "The film is synthetic. Deployment evidence is documented separately.",
    "Public deployment evidence is separated from the synthetic",
    "Presentation is not authority.",
    "Different claims require different evidence.",
    "Production is its own claim.",
    "governed commercial access and deployment paths through the",
    "provider-runtime certification dashboard",
    "Public-safe demonstration",
)

FORBIDDEN_TEXT = (
    "The film is synthetic. The deployment record is real.",
    "controlled live campaign deployments at Canadian federal",
    "2 Publicly documented campaign deployment contexts",
    "remain commercial Store products.",
    "Dominion OS™ 1.0 and the Fractal5 SaaS Suite are",
)

def fetch(url: str, timeout: int) -> str:
    separator = "&" if "?" in url else "?"
    cache_busted = f"{url}{separator}f5verify={int(time.time())}"
    req = urllib.request.Request(
        cache_busted,
        headers={
            "User-Agent": "Fractal5-Dominion-Live-Verifier/1.0",
            "Cache-Control": "no-cache, no-store, max-age=0",
            "Pragma": "no-cache",
            "Accept": "text/html,application/xhtml+xml",
        },
    )
    with urllib.request.urlopen(req, timeout=timeout) as response:
        body = response.read()
        charset = response.headers.get_content_charset() or "utf-8"
        return body.decode(charset, errors="replace")


def verify(html: str) -> dict:
    required = {text: (text in html) for text in REQUIRED_TEXT}
    forbidden = {text: (text in html) for text in FORBIDDEN_TEXT}

    result = {
        "schema": "dominion.demo1.live-verification.v2",
        "expectedBuild": EXPECTED_BUILD,
        "required": required,
        "forbiddenPresent": forbidden,
        "pass": all(required.values()) and not any(forbidden.values()),
    }
    return result


def main() -> int:
    parser = argparse.ArgumentParser()
    parser.add_argument("--url", default=DEFAULT_URL)
    parser.add_argument("--timeout", type=int, default=30)
    parser.add_argument("--json", action="store_true")
    args = parser.parse_args()

    try:
        html = fetch(args.url, args.timeout)
    except (urllib.error.URLError, TimeoutError, OSError) as exc:
        print(f"LIVE_SURFACE_FETCH_ERROR: {exc}", file=sys.stderr)
        return 2

    result = verify(html)
    if args.json:
        print(json.dumps(result, indent=2, sort_keys=True))
    else:
        print(f"URL: {args.url}")
        print(f"Expected build: {EXPECTED_BUILD}")
        print(f"Result: {'PASS' if result['pass'] else 'FAIL'}")
        for text, present in result["required"].items():
            print(f"required {'PASS' if present else 'FAIL'}: {text}")
        for text, present in result["forbiddenPresent"].items():
            print(f"forbidden {'FAIL' if present else 'PASS'}: {text}")

    return 0 if result["pass"] else 1


if __name__ == "__main__":
    raise SystemExit(main())
