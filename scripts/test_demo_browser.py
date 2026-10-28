#!/usr/bin/env python3
"""Interactive browser acceptance for synthetic mission flows only."""
from pathlib import Path
from playwright.sync_api import sync_playwright

URL = (Path(__file__).resolve().parents[1] / "demo" / "live-mission-demo.html").as_uri()

with sync_playwright() as pw:
    browser = pw.chromium.launch(headless=True)
    page = browser.new_page()
    external_requests = []
    def guard_request(route):
        if route.request.url.startswith(("http://", "https://")):
            external_requests.append(route.request.url)
            route.abort()
        else:
            route.continue_()
    page.route("**/*", guard_request)
    for mode in ("business", "politics"):
        page.goto(URL + "?mode=" + mode)
        assert page.locator(".tab.active").get_attribute("data-mode") == mode
        assert page.locator("#state").inner_text() == "MISSION"
        for expected in ("SITUATION", "INTELLIGENCE", "OPTIONS", "DECISION"):
            page.locator("#mission button.action").first.click()
            assert page.locator("#state").inner_text() == expected, (mode, expected)
        page.keyboard.press("ArrowRight")
        assert page.locator("#state").inner_text() == "DECISION", "Approval bypassed"
        page.locator("#mission button.action.secondary").click()
        assert page.locator("#state").inner_text() == "DECISION"
        page.locator("#mission button.action.approve").click()
        assert page.locator("#state").inner_text() == "EXECUTION"
        page.locator("#mission button.action").first.click()
        assert page.locator("#state").inner_text() == "EVIDENCE"
        page.get_by_role("button", name="Reset mission").click()
        assert page.locator("#state").inner_text() == "MISSION"
        print("PASS: browser journey and human authority boundary:", mode)
    page.wait_for_timeout(1500)
    assert not external_requests, "Offline synthetic mission made external requests: " + str(external_requests)
    print("PASS: local HTML mission operates without HTTP(S) requests")
    browser.close()
