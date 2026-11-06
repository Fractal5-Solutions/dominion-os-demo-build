"""Chromium prepublication check for full Squarespace v4.5 candidate; no cloud or release mutation."""
import hashlib
import tempfile
from pathlib import Path
from playwright.sync_api import sync_playwright

ROOT=Path(__file__).resolve().parents[1]
PAGE=ROOT/"squarespace/demo-1-v4-5-windows-google-release-candidate.html"
PORTABLE=ROOT/"demo/portable-public-mission-v4.3.html"
EXPECTED_HASH=hashlib.sha256(PORTABLE.read_bytes()).hexdigest()
WIDTHS=(1440,1200,1024,768,430,390,360)

def run():
    checks=0
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,args=["--no-sandbox"])
        for width in WIDTHS:
            page=browser.new_page(viewport={"width":width,"height":900},accept_downloads=True)
            errors=[]
            page.on("pageerror",lambda e: errors.append(str(e)))
            try:
                page.goto(PAGE.resolve().as_uri(),wait_until="domcontentloaded",timeout=30000)
                root=page.locator("#fractal5-demo-v44")
                root.wait_for(state="visible",timeout=15000)
                assert root.get_attribute("data-build")=="demo-1-v4.5-20261106-windows-google-release-candidate", width
                dims=page.evaluate("""() => {const d=document.documentElement,r=document.getElementById('fractal5-demo-v44');return [d.scrollWidth,d.clientWidth,r.scrollWidth,r.clientWidth]}""")
                assert dims[0]<=dims[1]+2 and dims[2]<=dims[3]+2,(width,dims)
                assert "Google Workspace" in root.inner_text()
                assert "Commercial Runtime Verified" not in root.inner_text()
                page.locator('[data-preview-mode="politics"]').click()
                assert "POLICY" in page.locator("#fractal5-demo-v44-stage-title").inner_text().upper(),width
                page.locator("#fractal5-demo-v44-reset").click()
                with page.expect_download(timeout=15000) as event:
                    page.locator("#fractal5-demo-v44-download").click()
                with tempfile.TemporaryDirectory() as temp:
                    output=Path(temp)/"offline.html"
                    event.value.save_as(output)
                    assert hashlib.sha256(output.read_bytes()).hexdigest()==EXPECTED_HASH,width
                assert not errors,(width,errors)
                checks+=7
                print(f"PASS {width}px | build, overflow, Workspace, claims, Politics, portable hash, JS")
            finally:
                page.close()
        browser.close()
    assert checks==49
    print("PASS v4.5 prepublication Chromium 49/49")

if __name__=="__main__":
    run()
