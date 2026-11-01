"""Windows x64 offline portable HTML acceptance: non-deploying and synthetic-only.

This smoke test runs on a real Windows GitHub runner, opens the exact
downloadable HTML via its file:// URI, and disables network in the browser
context. It does not install or certify the commercial Dominion runtime.
"""
import hashlib
import json
import sys
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
FILE = ROOT / "demo" / "portable-public-mission-v4.3.html"
EXPECTED = "c69dae845977ac1b91752967e2a0b72dcb520c520de9d380ea8ae24a8d155813"
checks = []

def check(label, test):
    checks.append({"name": label, "pass": bool(test)})
    if not test:
        print("FAIL:", label)

source = FILE.read_bytes()
check("exact committed portable payload digest", hashlib.sha256(source).hexdigest() == EXPECTED)
check("Windows runner required", sys.platform == "win32")
check("portable file begins with HTML doctype", source[:15].lower().startswith(b"<!doctype html>"))
with sync_playwright() as pw:
    browser = pw.chromium.launch(headless=True)
    for width in (1440, 390):
        context = browser.new_context(viewport={"width": width, "height": 900})
        context.set_offline(True)
        page = context.new_page()
        errors, outgoing = [], []
        page.on("pageerror", lambda err: errors.append(str(err)))
        page.on("request", lambda req: outgoing.append(req.url) if req.url.startswith(("https://", "http://")) else None)
        response = page.goto(FILE.resolve().as_uri(), wait_until="load", timeout=20000)
        check(f"{width}px opened local file", page.url.startswith("file:///"))
        check(f"{width}px offline mission starts", page.locator("#stage-name").inner_text() == "Mission")
        check(f"{width}px Business is default", "Market Entry" in page.locator("#mission-heading").inner_text())
        page.locator('[data-mode="politics"]').click()
        check(f"{width}px Politics changes mission", "Legislative" in page.locator("#mission-heading").inner_text())
        for _ in range(4):
            page.locator("#advance").click()
        check(f"{width}px approval blocks action", page.locator("#approve").is_visible() and page.locator("#advance").is_hidden())
        page.locator("#approve").click()
        check(f"{width}px approval unlocks next", page.locator("#advance").is_visible())
        page.locator("#advance").click()
        page.locator("#advance").click()
        check(f"{width}px reaches evidence", page.locator("#stage-name").inner_text() == "Evidence")
        page.locator("#reset").click()
        check(f"{width}px reset", page.locator("#stage-name").inner_text() == "Mission")
        check(f"{width}px no external network requests", len(outgoing) == 0)
        check(f"{width}px no JS errors", len(errors) == 0)
        check(f"{width}px no horizontal overflow", page.evaluate("document.documentElement.scrollWidth <= document.documentElement.clientWidth + 2"))
        context.close()
    browser.close()
report = {"platform": sys.platform, "real_file_uri_test": True,
          "network_disabled": True, "sha256": hashlib.sha256(source).hexdigest(),
          "passed": sum(t["pass"] for t in checks), "total": len(checks), "checks": checks}
Path("windows-offline-smoke-results.json").write_text(json.dumps(report, indent=2), encoding="utf-8")
print("Windows file:// offline acceptance:", report["passed"], "/", report["total"])
if report["passed"] != report["total"]:
    sys.exit(1)
