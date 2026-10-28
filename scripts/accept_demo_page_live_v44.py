"""Read-only *post-publish* gate. Run only after principal pastes /demo-1 v4.4."""
import argparse, hashlib, json, tempfile
from pathlib import Path
from playwright.sync_api import sync_playwright

BASE=Path(__file__).resolve().parents[1]
PORTABLE=BASE/"demo/portable-public-mission-v4.3.html"
DIGEST=hashlib.sha256(PORTABLE.read_bytes()).hexdigest()
WIDTHS=(1440,1200,1024,768,430,390,360)

def main():
    ap=argparse.ArgumentParser()
    ap.add_argument("--url",default="https://www.fractal5solutions.com/demo-1")
    ap.add_argument("--report",default="live-acceptance-v44.json")
    args=ap.parse_args()
    results=[]
    def verify(label,good,detail=""):
        results.append({"name":label,"pass":bool(good),"detail":str(detail)[:320]})
        if not good:print("FAIL",label,detail)
    with sync_playwright() as p:
        browser=p.chromium.launch(headless=True,args=["--no-sandbox"])
        for width in WIDTHS:
            page=browser.new_page(viewport={"width":width,"height":900},accept_downloads=True)
            errors=[]
            page.on("pageerror",lambda e: errors.append(str(e)))
            try:
                response=page.goto(args.url,wait_until="domcontentloaded",timeout=45000)
                verify(f"{width}px website HTTP 200",bool(response and response.ok))
                root=page.locator("#fractal5-demo-v44")
                root.wait_for(state="visible",timeout=15000)
                verify(f"{width}px correct published build",root.get_attribute("data-build")=="demo-1-v4.4-20261028-production-preflight")
                verify(f"{width}px no old broad claim","Commercial Runtime Verified" not in root.inner_text())
                dims=page.evaluate("""() => {let d=document.documentElement,r=document.getElementById('fractal5-demo-v44');return [d.scrollWidth,d.clientWidth,r.scrollWidth,r.clientWidth]}""")
                verify(f"{width}px no horizontal overflow",dims[0]<=dims[1]+2 and dims[2]<=dims[3]+2,dims)
                page.locator('[data-preview-mode="politics"]').click()
                verify(f"{width}px Politics operates","POLICY" in page.locator("#fractal5-demo-v44-stage-title").inner_text().upper())
                page.locator("#fractal5-demo-v44-reset").click()
                with page.expect_download(timeout=15000) as evt:
                    page.locator("#fractal5-demo-v44-download").click()
                with tempfile.TemporaryDirectory() as temp:
                    path=Path(temp)/"offline.html"
                    evt.value.save_as(path)
                    verify(f"{width}px exact portable download",hashlib.sha256(path.read_bytes()).hexdigest()==DIGEST)
                verify(f"{width}px no script exceptions",not errors,errors)
            except Exception as e:
                verify(f"{width}px Squarespace acceptance",False,f"{type(e).__name__}: {e}")
            finally:page.close()
        request=browser.new_context().request
        root_url="https://fractal5-solutions.github.io/dominion-os-demo-build/demo/"
        for mode in ("business","politics"):
            try:
                r=request.get(root_url+"live-mission-demo.html?mode="+mode,timeout=30000)
                verify(mode+" hosted mission",r.ok and "SYNTHETIC DATA" in r.text(),r.status)
            except Exception as e:verify(mode+" hosted mission",False,e)
            try:
                r=request.get(root_url+f"media/dominion-os-{mode}-1080p.mp4",timeout=30000)
                verify(mode+" hosted MP4",r.ok and r.body()[4:8]==b"ftyp",r.status)
            except Exception as e:verify(mode+" hosted MP4",False,e)
        browser.close()
    report={"url":args.url,"passed":sum(x["pass"] for x in results),"total":len(results),"checks":results}
    Path(args.report).write_text(json.dumps(report,indent=2),encoding="utf-8")
    print("LIVE CANON ACCEPTANCE",report["passed"],"/",report["total"])
    if report["passed"]!=report["total"]:raise SystemExit(1)

if __name__=="__main__":main()
