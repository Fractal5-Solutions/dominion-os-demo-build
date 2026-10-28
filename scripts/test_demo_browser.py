#!/usr/bin/env python3
"""Interactive browser acceptance for synthetic mission flows only."""
from pathlib import Path
from playwright.sync_api import sync_playwright

URL = (Path(__file__).resolve().parents[1] / "demo" / "live-mission-demo.html").as_uri()

with sync_playwright() as pw:
    browser = pw.chromium.launch(headless=True)
    page = browser.new_page()
    for mode in ("business", "politics"):
        page.goto(URL + "?mode=" + mode)
        assert page.locator(".tab.active").get_attribute("data-mode") == mode
        assert page.locator("#state").inner_text() == "MISSION"
        for expected in ("SITUATION", "INTELLIGENCE", "OPTIONS", "DECISION"):
            page.evaluate("next()")
            assert page.locator("#state").inner_text() == expected, (mode, expected)
        page.evaluate("next()")
        assert page.locator("#state").inner_text() == "DECISION", "Approval bypassed"
        page.evaluate("reject()")
        assert page.locator("#state").inner_text() == "DECISION"
        page.evaluate("approve()")
        assert page.locator("#state").inner_text() == "EXECUTION"
        page.evaluate("next()")
        assert page.locator("#state").inner_text() == "EVIDENCE"
        page.evaluate("resetFlow()")
        assert page.locator("#state").inner_text() == "MISSION"
        print("PASS: browser journey and human authority boundary:", mode)
    browser.close()
