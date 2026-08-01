from __future__ import annotations

import json
import re
from pathlib import Path
from urllib.parse import urlparse

HTML_PATH = Path("web/bluewave/signal.code.html")
CONFIG_PATH = Path("web/bluewave/signal.config.json")
OUT_PATH = Path("bluewave_signal_manifest.json")

APPROVED_IMAGE_URL = (
    "https://images.squarespace-cdn.com/content/67705dbf69e06a2e83e53c93/"
    "516a7db9-586f-416f-bcc2-fe834daf10eb/"
    "Conversations+for+a+Country+Worth+Building.png?content-type=image%2Fpng"
)

REQUIRED_HTML = [
    'id="bw-signal"',
    'data-version="signal-squarespace-v2"',
    'id="conversations"',
    "Conversations for a Country Worth Building",
    "One guest. One serious question. Thirty minutes.",
    APPROVED_IMAGE_URL,
    'aspect-ratio:16/9',
    'object-fit:contain',
    'alt="BlueWave Signal — Conversations for a Country Worth Building, connecting Ottawa and Vancouver."',
    'id="flagship-show"',
    "Guest announcements come after consent—not before.",
    "episode_status:\"in_development\"",
]

FORBIDDEN_TEXT = [
    "Patrick Hunt",
    "Maldwyn Thomas",
    "api_key",
    "api-key",
    "service account",
    "password",
    "private endpoint",
    "admin dashboard",
]


def fail(message: str, errors: list[str]) -> None:
    errors.append(message)


def main() -> int:
    errors: list[str] = []
    warnings: list[str] = []

    if not HTML_PATH.exists():
        fail(f"missing {HTML_PATH}", errors)
    if not CONFIG_PATH.exists():
        fail(f"missing {CONFIG_PATH}", errors)
    if errors:
        return write_result(errors, warnings)

    html = HTML_PATH.read_text(encoding="utf-8")
    config = json.loads(CONFIG_PATH.read_text(encoding="utf-8"))

    for snippet in REQUIRED_HTML:
        if snippet not in html:
            fail(f"required HTML snippet missing: {snippet}", errors)

    for text in FORBIDDEN_TEXT:
        if text.lower() in html.lower():
            fail(f"forbidden public text present: {text}", errors)

    if html.count('id="bw-signal"') != 1:
        fail("#bw-signal root must occur exactly once", errors)
    if re.search(r"<main\b", html, flags=re.IGNORECASE):
        fail("nested <main> is forbidden in Squarespace payload", errors)
    if re.search(r"<script[^>]+src=", html, flags=re.IGNORECASE):
        fail("external JavaScript is forbidden", errors)
    if re.search(r"<link[^>]+rel=[\"']stylesheet", html, flags=re.IGNORECASE):
        fail("external stylesheets are forbidden", errors)

    hero_index = html.find('class="hero"')
    conversations_index = html.find('id="conversations"')
    flagship_index = html.find('id="flagship-show"')
    if not (0 <= hero_index < conversations_index < flagship_index):
        fail("conversation module must appear after hero and before flagship-show", errors)

    hrefs = re.findall(r'href="([^"]+)"', html)
    for href in hrefs:
        parsed = urlparse(href)
        if parsed.scheme or parsed.netloc:
            fail(f"external href is not permitted before approval: {href}", errors)
        if not (href.startswith("/") or href.startswith("#")):
            fail(f"href must be relative or fragment-only: {href}", errors)

    image_sources = re.findall(r'<img[^>]+src="([^"]+)"', html, flags=re.IGNORECASE)
    if image_sources != [APPROVED_IMAGE_URL]:
        fail("the only image source must be the approved conversation graphic", errors)

    expected_config = {
        "page": "/signal",
        "brand": "BlueWave Action Group",
        "version": "signal-squarespace-v2",
        "mode": "public_prelaunch",
        "primaryPlatform": "Substack",
        "contentModel": "conversations_plus_writing",
    }
    for key, expected in expected_config.items():
        if config.get(key) != expected:
            fail(f"config {key!r} must equal {expected!r}", errors)

    series = config.get("series", {})
    if series.get("tagline") != "Conversations for a Country Worth Building":
        fail("series tagline mismatch", errors)
    if series.get("status") != "in_development":
        fail("series status must be in_development", errors)
    if series.get("imageUrl") != APPROVED_IMAGE_URL:
        fail("series imageUrl mismatch", errors)
    if series.get("imageAspectRatio") != "16:9" or series.get("imageCrop") != "none":
        fail("series image must remain uncropped at 16:9", errors)

    safety = config.get("safety", {})
    required_safety = {
        "publicOnly": True,
        "privateCommandAllowed": False,
        "guestNeutralUntilConfirmed": True,
        "requiresWrittenAcceptance": True,
        "requiresPublicationPermission": True,
    }
    for key, expected in required_safety.items():
        if safety.get(key) is not expected:
            fail(f"safety {key!r} must equal {expected!r}", errors)

    forbidden_guest_names = safety.get("forbiddenGuestNames", [])
    if sorted(forbidden_guest_names) != ["Maldwyn Thomas", "Patrick Hunt"]:
        fail("forbiddenGuestNames must preserve the two unconfirmed names", errors)

    ctas = config.get("callsToAction", [])
    if len(ctas) != 3:
        fail("exactly three governed calls to action are required", errors)
    for cta in ctas:
        href = cta.get("href", "")
        if not href.startswith("/?") or "#contact" not in href:
            fail(f"CTA must use canonical relative intake route: {href}", errors)

    if not html.strip().endswith("</section>"):
        fail("payload must end with the root </section>", errors)

    return write_result(errors, warnings)


def write_result(errors: list[str], warnings: list[str]) -> int:
    result = {
        "html_file": str(HTML_PATH),
        "config_file": str(CONFIG_PATH),
        "errors": errors,
        "warnings": warnings,
        "ok": not errors,
    }
    OUT_PATH.write_text(json.dumps(result, indent=2), encoding="utf-8")
    print(json.dumps(result, indent=2))
    return 0 if result["ok"] else 2


if __name__ == "__main__":
    raise SystemExit(main())
