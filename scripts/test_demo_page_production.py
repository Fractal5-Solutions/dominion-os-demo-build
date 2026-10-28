"""Canonical PR-only production prepublication checks; no provider/cloud writes."""
from pathlib import Path
import base64, hashlib, json, os, re, tempfile
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parents[1]
HTML = ROOT / "squarespace/demo-1-v4-4-production-preflight.html"
PORTABLE = ROOT / "demo/portable-public-mission-v4.3.html"
raw = HTML.read_text(encoding="utf-8")
portable = PORTABLE.read_bytes()
soup = BeautifulSoup(raw, "html.parser")
root = soup.select_one("#fractal5-demo-v44")
report = {"source_sha256": hashlib.sha256(HTML.read_bytes()).hexdigest(),
          "portable_sha256": hashlib.sha256(portable).hexdigest(), "checks": []}

def check(name, condition):
    report["checks"].append({"check":name, "pass":bool(condition)})
    if not condition: print("FAIL", name)

check("one scoped root", len(soup.select("section#fractal5-demo-v44")) == 1)
check("Canon Light metadata", bool(root and root.get("data-canon")=="fractal5-light"))
check("canonical build", "demo-1-v4.4-20261028-production-preflight" in raw)
check("one H1", len(root.find_all("h1")) == 1)
check("unique IDs", len(root.find_all(id=True)) == len({e["id"] for e in root.find_all(id=True)}))
check("no duplicate site footer", not root.select("footer, nav"))
check("Dominion OS indivisible", "Dominion\u00a0OS" in raw and not bool(re.search(r"Dominion OS", soup.get_text())))
check("canonical palette", all(k in raw for k in ["--ink:#101112","--gold:#c5a461","--bronze:#765f2b"]))
check("no large dark panel", not root.select(".section.dark"))
check("primary CTA self-contained", bool(root.select_one('a[href="#fractal5-demo-v44-command-title"]')))
check("all anchor targets exist", all(root.select_one(a["href"]) for a in root.select('a[href^="#"]')))
check("external tabs safe", all("noopener" in a.get("rel",[]) and "noreferrer" in a.get("rel",[]) for a in root.select("a[target=_blank]")))
check("Business and Politics links", all(root.find("a",href=lambda x: x and "mode="+m in x) for m in ("business","politics")))
check("two video fallbacks", len(root.select("[data-video-status]")) == 2)
check("synthetic only", "data-claim=\"synthetic-public-proof\"" in raw)
check("cloud fail closed", 'data-gcloud-runtime-certified="false"' in raw and 'data-customer-uploads="disabled"' in raw)
check("no user file or cloud upload", not root.select("input[type=file], form"))
check("no installer download URL", not any(re.search(r"\.(exe|msi|zip)(\?|$)",a.get("href",""),re.I) for a in root.find_all("a")))
check("no external download fetch", "fetch(" not in raw)
check("download data embedded exact", base64.b64encode(portable).decode("ascii") in raw)
check("standalone CSP denies connections", b"connect-src 'none'" in portable)
check("portable has no external URLs", b"https://" not in portable and b"http://" not in portable)
check("portable modes", all(("data-mode=\""+m+"\"").encode() in portable for m in ("business","politics")))
check("reliable current access destination", bool(root.find("a",href="https://www.fractal5solutions.com/launch")))
check("no unsafe signup/login", not any(re.sub(r"^https?://[^/]+", "", a.get("href","")).split("?")[0] in ("/signup","/account","/store","/login") for a in root.find_all("a")))

with sync_playwright() as pw:
    kwargs={"executable_path":"/usr/bin/chromium"} if Path("/usr/bin/chromium").is_file() else {}
    browser = pw.chromium.launch(headless=True, args=["--no-sandbox"], **kwargs)
    for width in [1440,1200,1024,768,430,390,360]:
        page=browser.new_page(viewport={"width":width,"height":900},accept_downloads=True)
        errors=[]
        page.on("pageerror",lambda e:errors.append(str(e)))
        page.route("**/*",lambda route:route.abort())
        page.set_content(raw,wait_until="domcontentloaded")
        data=page.evaluate("""() => {
          let r=document.querySelector('#fractal5-demo-v44'),
          els=[...r.querySelectorAll('h1,h2,h3,button,a,.panel,.step')];
          return {client:document.documentElement.clientWidth,
          scroll:document.documentElement.scrollWidth,rc:r.clientWidth,rs:r.scrollWidth,
          outside:els.some(el => {let x=el.getBoundingClientRect();
            return x.width && (x.left < -2 || x.right > innerWidth + 2);})};
        }""")
        check(f"{width}px fits",data["scroll"]<=data["client"]+2 and data["rs"]<=data["rc"]+2)
        check(f"{width}px controls visible",not data["outside"])
        check(f"{width}px no script errors",not errors)
        page.locator('[data-preview-mode="politics"]').click()
        check(f"{width}px Politics controls", "POLICY" in page.locator("#fractal5-demo-v44-stage-title").inner_text().upper())
        page.locator('[data-preview-mode="business"]').click()
        for _ in range(4): page.locator("#fractal5-demo-v44-next").click()
        check(f"{width}px approval gate blocks", page.locator("#fractal5-demo-v44-approve").is_visible() and not page.locator("#fractal5-demo-v44-next").is_visible())
        page.locator("#fractal5-demo-v44-approve").click()
        check(f"{width}px approval unlocks",page.locator("#fractal5-demo-v44-next").is_visible())
        page.locator("#fractal5-demo-v44-reset").click()
        check(f"{width}px reset",page.locator("#fractal5-demo-v44-stage-count").inner_text().startswith("01"))
        with page.expect_download() as evt:page.locator("#fractal5-demo-v44-download").click()
        dl=evt.value
        check(f"{width}px download name",dl.suggested_filename=="Dominion-OS-1.0-Portable-Business-Politics-Demo.html")
        with tempfile.TemporaryDirectory() as td:
            saved=Path(td)/"offline.html"
            dl.save_as(saved)
            check(f"{width}px exact download",saved.read_bytes()==portable)
        check(f"{width}px button restored",page.locator("#fractal5-demo-v44-download").is_enabled())
        if width == 1440:
            page.locator('a[href="#fractal5-demo-v44-command-title"]').click()
            check("on-page primary CTA",page.evaluate("location.hash")=="#fractal5-demo-v44-command-title")
            page.locator("#fractal5-demo-v44-reset").focus()
            page.keyboard.press("Enter")
            check("keyboard resets preview",page.locator("#fractal5-demo-v44-stage-count").inner_text().startswith("01"))
            video=page.locator(".media-wrap video").first
            fallback=page.locator('[data-video-status="business"]')
            video.dispatch_event("error")
            check("failed video keeps fallback", fallback.is_visible())
            video.dispatch_event("loadedmetadata")
            check("working video hides fallback",not fallback.is_visible())
        page.close()
    offline=browser.new_page()
    network=[]
    offline.on("request",lambda req:network.append(req.url))
    offline.route("**/*",lambda route:route.abort())
    offline.set_content(portable.decode("utf-8"),wait_until="domcontentloaded")
    check("offline mission starts",offline.locator("#stage-name").inner_text()=="Mission")
    offline.locator('[data-mode="politics"]').click()
    check("offline Politics", "Legislative" in offline.locator("#mission-heading").inner_text())
    for _ in range(4): offline.locator("#advance").click()
    check("offline cannot bypass approval",offline.locator("#approve").is_visible() and offline.locator("#advance").is_hidden())
    offline.locator("#approve").click()
    offline.locator("#advance").click()
    offline.locator("#advance").click()
    check("offline decision evidence",offline.locator("#stage-name").inner_text()=="Evidence")
    check("offline no outgoing network",not network)
    offline.close()
    browser.close()

report["passed"]=sum(x["pass"] for x in report["checks"])
report["total"]=len(report["checks"])
target=Path(os.environ.get("F5_DEMO_QA_REPORT","prepublication-v44-results.json"))
target.write_text(json.dumps(report,indent=2),encoding="utf-8")
print("Canon production prepublication:",report["passed"],"/",report["total"])
if report["passed"] != report["total"]:raise SystemExit(1)
