#!/usr/bin/env python3
"""No-cost hosted Chromium acceptance for the PUBLIC synthetic mission page.

Read-only. Opens only the canonical public GitHub Pages HTML, rejects every
other browser network request, and never touches PHI/AT2 or customer data.
A --expected-commit post-deployment run additionally checks exact HTML bytes
and the static Pages release receipt. Passing does NOT certify product runtime.
"""
import argparse
import hashlib
import json
from pathlib import Path
import re
import time
from urllib.parse import urlsplit
from urllib.request import Request, urlopen

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
PAGE_PATH = "/dominion-os-demo-build/demo/live-mission-demo.html"
BASE = "https://fractal5-solutions.github.io" + PAGE_PATH
RECEIPT = "https://fractal5-solutions.github.io/dominion-os-demo-build/release.json"
HEX40 = re.compile(r"^[0-9a-f]{40}$")
LOCAL_SHA = hashlib.sha256(
    (ROOT / "demo" / "live-mission-demo.html").read_bytes()
).hexdigest()


def deployed_sha(expected):
    """Wait for static GitHub Pages CDN propagation; never accept stale SHA."""
    for attempt in range(12):
        try:
            request = Request(
                RECEIPT + "?sha=" + expected,
                headers={"Cache-Control": "no-cache", "User-Agent": "DominionPublicDemoReadOnly/1"},
            )
            with urlopen(request, timeout=12) as result:
                if result.status != 200:
                    raise AssertionError("release receipt HTTP status differs from 200")
                raw = result.read(65537)
            if len(raw) > 65536:
                raise AssertionError("published receipt exceeds bounded size")
            receipt = json.loads(raw)
            if (
                isinstance(receipt, dict)
                and receipt.get("mode") == "artifact-only-static-proof"
                and receipt.get("releaseSha") == expected
                and receipt.get("interactiveMissionDemoDataClass") == "synthetic"
                and receipt.get("externalConnectorClaimedLive") is False
                and receipt.get("containsPrivateSource") is False
                and receipt.get("containsSecrets") is False
            ):
                return
        except (OSError, ValueError, AssertionError) as exc:
            if attempt == 11:
                raise AssertionError("published release receipt not verified") from exc
        if attempt < 11:
            time.sleep(3)
    raise AssertionError("published release receipt SHA stale or incomplete")


def test_hosted(expected_commit):
    browser_errors = []
    forbidden_requests = []
    hosted_hashes = {}
    with sync_playwright() as pw:
        browser = pw.chromium.launch(headless=True)
        try:
            page = browser.new_page()
            page.on("pageerror", lambda error: browser_errors.append(type(error).__name__))

            def only_public_mission(route):
                url = urlsplit(route.request.url)
                allowed = (
                    url.scheme == "https"
                    and url.netloc == "fractal5-solutions.github.io"
                    and url.path == PAGE_PATH
                    and url.query in ("mode=business", "mode=politics")
                )
                if allowed:
                    route.continue_()
                else:
                    forbidden_requests.append(route.request.url.split("?")[0])
                    route.abort()

            page.route("**/*", only_public_mission)
            for mode, receipt_id in (
                ("business", "DEMO-BUS-001"),
                ("politics", "DEMO-POL-001"),
            ):
                response = page.goto(BASE + "?mode=" + mode, wait_until="load", timeout=30000)
                assert response is not None and response.status == 200, mode
                hosted_hashes[mode] = hashlib.sha256(response.body()).hexdigest()
                assert "SYNTHETIC DATA" in page.locator("body").inner_text(), mode
                assert page.locator(".tab.active").get_attribute("data-mode") == mode
                assert page.locator("#state").inner_text() == "MISSION"
                for expected in ("SITUATION", "INTELLIGENCE", "OPTIONS", "DECISION"):
                    page.locator("#mission button.action").first.click()
                    assert page.locator("#state").inner_text() == expected, (mode, expected)
                page.keyboard.press("ArrowRight")
                assert page.locator("#state").inner_text() == "DECISION", "approval bypass"
                page.locator("#mission button.action.secondary").click()
                assert page.locator("#state").inner_text() == "DECISION", "hold bypass"
                assert "Decision held" in page.locator("#log").inner_text()
                page.locator("#mission button.action.approve").click()
                assert page.locator("#state").inner_text() == "EXECUTION", mode
                page.locator("#mission button.action").first.click()
                assert page.locator("#state").inner_text() == "EVIDENCE", mode
                evidence = page.locator("#mission .receipt").inner_text()
                assert receipt_id in evidence, mode
                assert "EXTERNAL CONNECTOR: NOT CLAIMED LIVE IN THIS BUILD" in evidence
                page.get_by_role("button", name="Reset mission").click()
                assert page.locator("#state").inner_text() == "MISSION"
                print("PASS: deployed synthetic seven-stage mission, explicit approval and reset:", mode)

            assert hosted_hashes["business"] == hosted_hashes["politics"], (
                "different published HTML for Business and Politics"
            )
            page.locator('.tab[data-mode="business"]').click()
            assert page.locator("#state").inner_text() == "MISSION"
            assert page.locator(".tab.active").get_attribute("data-mode") == "business"
            page.locator('.tab[data-mode="politics"]').click()
            assert page.locator("#state").inner_text() == "MISSION"
            assert page.locator(".tab.active").get_attribute("data-mode") == "politics"
            assert not forbidden_requests, "public demo attempted unapproved network request"
            assert not browser_errors, "browser script error(s): " + repr(browser_errors)
            print("PASS: deployed context isolation and no unapproved browser requests")

            if expected_commit is not None:
                assert hosted_hashes["business"] == LOCAL_SHA, (
                    "published HTML differs from exact local release-source bytes"
                )
                print("PASS: published HTML SHA-256 equals exact release source", LOCAL_SHA)
            else:
                print("INFO: hosted smoke only; no deploy-head parity claim")
        finally:
            browser.close()


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument(
        "--expected-commit",
        help="40-character GitHub SHA of published main; requires exact Pages receipt and source parity",
    )
    args = parser.parse_args()
    if args.expected_commit is not None:
        if not HEX40.fullmatch(args.expected_commit):
            parser.error("expected commit must be a lowercase 40-character SHA")
        deployed_sha(args.expected_commit)
    test_hosted(args.expected_commit)


if __name__ == "__main__":
    main()
