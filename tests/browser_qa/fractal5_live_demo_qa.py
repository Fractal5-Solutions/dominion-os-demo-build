"""Bounded public-only Fractal5 demo QA. No production mutations or credentials."""
import argparse
import datetime as dt
import hashlib
import json
from pathlib import Path
from urllib.parse import urlsplit

TARGET = "https://www.fractal5solutions.com/demo-1"
APPROVED_HOSTS = frozenset({
    "www.fractal5solutions.com", "fractal5solutions.com",
    "static1.squarespace.com", "images.squarespace-cdn.com",
    "assets.squarespace.com", "fonts.googleapis.com", "fonts.gstatic.com",
    "fractal5-solutions.github.io",
})
CHECK_NAMES = (
    "http_ok", "url_unchanged", "new_page_marker", "catalogue_13",
    "business_default", "decision_requires_approval", "approval_unlocks",
    "politics_resets", "offline_download", "offline_reopen",
    "no_desktop_overflow", "no_mobile_overflow", "no_js_errors",
)

def approved(url):
    try:
        parts = urlsplit(url)
        return (parts.scheme == "https" and parts.hostname in APPROVED_HOSTS
                and parts.port in (None, 443) and not parts.username and not parts.password)
    except ValueError:
        return False

def run(output, screenshot):
    from playwright.sync_api import sync_playwright
    receipt = {
        "target": TARGET,
        "checked_at_utc": dt.datetime.now(dt.timezone.utc).isoformat(),
        "checks": {key: False for key in CHECK_NAMES},
        "errors": [], "blocked_hosts": [], "status": None,
        "browser": None, "screenshot": None, "offline_sha256": None,
    }
    output = Path(output)
    screenshot = Path(screenshot)
    blocked = set()
    js_errors = []
    try:
        with sync_playwright() as p:
            browser = p.chromium.launch(headless=True)
            receipt["browser"] = browser.version
            ctx = browser.new_context(viewport={"width": 1365, "height": 900},
                                      accept_downloads=True, service_workers="block")
            def route_request(route):
                if approved(route.request.url) or route.request.url.startswith(("data:", "blob:")):
                    route.continue_()
                else:
                    blocked.add(urlsplit(route.request.url).hostname or "non-http")
                    route.abort()
            ctx.route("**/*", route_request)
            page = ctx.new_page()
            page.on("pageerror", lambda error: js_errors.append(str(error)[:400]))
            try:
                response = page.goto(TARGET, wait_until="domcontentloaded", timeout=30000)
                receipt["status"] = response.status if response else None
                receipt["checks"]["http_ok"] = bool(response and response.ok)
                receipt["checks"]["url_unchanged"] = page.url.rstrip("/") == TARGET
                root = page.locator("#f5d26")
                root.wait_for(timeout=10000)
                receipt["checks"]["new_page_marker"] = root.count() == 1
                receipt["checks"]["catalogue_13"] = root.locator(".suite").count() == 13
                receipt["checks"]["business_default"] = (
                    root.locator('[data-mode="business"]').get_attribute("aria-pressed") == "true"
                )
                for _ in range(4):
                    root.locator("[data-next]").click()
                receipt["checks"]["decision_requires_approval"] = root.locator("[data-next]").is_disabled()
                root.locator("[data-approve]").click()
                receipt["checks"]["approval_unlocks"] = root.locator("[data-next]").is_enabled()
                root.locator('[data-mode="politics"]').click()
                receipt["checks"]["politics_resets"] = (
                    root.locator("[data-counter]").inner_text().startswith("01")
                    and root.locator("[data-approve]").is_disabled()
                )
                with page.expect_download(timeout=15000) as event:
                    root.locator("[data-download]").first.click()
                download = event.value
                if download.suggested_filename.lower().endswith(".html") and not download.failure():
                    artifact = output.with_suffix(".offline.html")
                    download.save_as(artifact)
                    raw = artifact.read_bytes()
                    receipt["offline_sha256"] = hashlib.sha256(raw).hexdigest()
                    receipt["checks"]["offline_download"] = b"<html" in raw.lower() and len(raw) > 200
                    offline_ctx = browser.new_context(service_workers="block")
                    offline_ctx.route("http**/*", lambda route: route.abort())
                    offline_page = offline_ctx.new_page()
                    offline_page.goto(artifact.resolve().as_uri(), wait_until="domcontentloaded")
                    offline_root = offline_page.locator("#f5d26")
                    receipt["checks"]["offline_reopen"] = (offline_root.count() == 1
                        and offline_root.locator("[data-next]").count() > 0
                        and offline_root.locator("[data-next]").is_enabled())
                    offline_ctx.close()
                receipt["checks"]["no_desktop_overflow"] = page.evaluate(
                    "document.documentElement.scrollWidth <= innerWidth")
                page.screenshot(path=str(screenshot), full_page=True)
                receipt["screenshot"] = str(screenshot)
                page.set_viewport_size({"width": 390, "height": 844})
                receipt["checks"]["no_mobile_overflow"] = page.evaluate(
                    "document.documentElement.scrollWidth <= innerWidth")
            except Exception as exc:
                receipt["errors"].append(type(exc).__name__ + ": " + str(exc)[:500])
            receipt["checks"]["no_js_errors"] = not js_errors
            receipt["errors"].extend(js_errors)
            ctx.close()
            browser.close()
    except Exception as exc:
        receipt["errors"].append("runtime: " + type(exc).__name__ + ": " + str(exc)[:500])
    receipt["blocked_hosts"] = sorted(blocked)
    receipt["verdict"] = ("PASS" if all(receipt["checks"].values()) and not receipt["errors"]
                          else "NOT_CERTIFIED")
    output.write_text(json.dumps(receipt, indent=2), encoding="utf-8")
    return receipt

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", default="fractal5-live-qa-receipt.json")
    parser.add_argument("--screenshot", default="fractal5-live-qa.png")
    args = parser.parse_args()
    print(json.dumps(run(args.output, args.screenshot), indent=2))
