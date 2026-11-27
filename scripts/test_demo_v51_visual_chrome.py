"""Read-only Chrome visual and real MP4 acceptance for Squarespace v5.1 candidate.
Candidate renders in synthetic Squarespace-like wrapper, NOT the real editor.
"""
import json
from pathlib import Path
from playwright.sync_api import sync_playwright
BASE=Path(__file__).resolve().parents[1]
SOURCE=BASE/"squarespace/demo-1-v5.1-live-parity-candidate.html"
OUT=Path("v51-visual-proof")
OUT.mkdir(exist_ok=True)
WIDTHS=(1440,1200,1024,768,430,390,360)
checks=[]
def check(name,condition,detail=""):
    checks.append({"check":name,"pass":bool(condition),"detail":str(detail)[:320]})
    print(("PASS " if condition else "FAIL ")+name+" "+str(detail)[:90])
source=SOURCE.read_text(encoding="utf-8")
wrapper="""<!doctype html><html lang="en"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width, initial-scale=1">
<style>body{margin:0;background:#fff;color:#111;font-family:Manrope,Arial,sans-serif}
#site-head{padding:20px 24px;border-bottom:1px solid #ddd;font-weight:700;letter-spacing:.08em}
#site-foot{padding:30px 24px;background:#faf9f6;color:#555}</style>
</head><body><div id="site-head">FRACTAL5 SOLUTIONS / DEMO</div>
"""+source+"""<div id="site-foot">Fractal5 Solutions · Synthetic Public Proof</div></body></html>"""
with sync_playwright() as p:
    browser=p.chromium.launch(channel="chrome",headless=True,args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
    for width in WIDTHS:
        ctx=browser.new_context(viewport={"width":width,"height":900},device_scale_factor=1,accept_downloads=True)
        page=ctx.new_page()
        errors=[]
        page.on("pageerror",lambda e: errors.append(str(e)))
        page.set_content(wrapper,wait_until="domcontentloaded",timeout=30000)
        root=page.locator("#fractal5-demo-v44")
        root.wait_for(state="visible")
        layout=page.evaluate("""() => {
            const r=document.querySelector('#fractal5-demo-v44');
            const bad=[...r.querySelectorAll('a,button,summary,h1,h2,h3,.v5-choice')].filter(el=>{
               let g=el.getBoundingClientRect(),s=getComputedStyle(el);
               return g.width>0 && s.display!=='none' && s.visibility!=='hidden' && (g.left< -2 || g.right>innerWidth+2);
            });
            return {pageScroll:document.documentElement.scrollWidth,pageClient:document.documentElement.clientWidth,
                    rootScroll:r.scrollWidth,rootClient:r.clientWidth,offenders:bad.map(x=>x.outerHTML.slice(0,90))};
        }""")
        check(f"{width}px visual layout no overflow",layout["pageScroll"]<=layout["pageClient"]+2 and layout["rootScroll"]<=layout["rootClient"]+2,layout)
        check(f"{width}px controls on screen",not layout["offenders"],layout["offenders"])
        check(f"{width}px opens with two mission cards",page.locator("header.v5-hero .v5-choice").count()==2)
        check(f"{width}px catalogue expandable",page.locator(".v5-expand summary").count()==4)
        page.locator(".v5-expand summary").last.click()
        check(f"{width}px 13 catalogue items visible",page.locator(".v5-module-grid [role=listitem]:visible").count()==13)
        page.screenshot(path=str(OUT/f"candidate-{width}.png"),full_page=True,animations="disabled")
        check(f"{width}px screenshot captured",(OUT/f"candidate-{width}.png").stat().st_size>4000)
        check(f"{width}px zero script errors",not errors,errors)
        if width==1440:
            videos=page.locator("#fractal5-demo-v44 video")
            check("two candidate videos",videos.count()==2)
            for mode,index in (("business",0),("politics",1)):
                v=videos.nth(index)
                v.scroll_into_view_if_needed()
                outcome=v.evaluate("""async v=>{
                    v.muted=true;v.preload='auto';
                    try {await Promise.race([v.play(),new Promise((_,rej)=>setTimeout(()=>rej(new Error('timeout')),18000))]);}
                    catch(e){return {ok:false,error:String(e),readyState:v.readyState};}
                    await new Promise(res=>setTimeout(res,1100));
                    return {ok:!v.paused&&v.currentTime>0&&!v.error,currentTime:v.currentTime,readyState:v.readyState};
                }""")
                check(mode+" actual Chrome video advances",outcome["ok"],outcome)
                v.evaluate("v=>v.pause()")
        ctx.close()
    # Live page observation is read-only, and does not assert build parity.
    ctx=browser.new_context(viewport={"width":1440,"height":900},device_scale_factor=1)
    page=ctx.new_page()
    response=page.goto("https://www.fractal5solutions.com/demo-1",wait_until="domcontentloaded",timeout=45000)
    check("public live page reachable",bool(response and response.ok))
    live_meta=page.evaluate("""() => ({title:document.title,builds:[...document.querySelectorAll('[data-build]')].map(x=>x.getAttribute('data-build')),scroll:document.documentElement.scrollWidth,client:document.documentElement.clientWidth})""")
    (OUT/"live-metadata.json").write_text(json.dumps(live_meta,indent=2),encoding="utf-8")
    page.screenshot(path=str(OUT/"live-1440.png"),full_page=True,animations="disabled")
    check("public live screenshot captured",(OUT/"live-1440.png").stat().st_size>4000)
    check("live desktop no overflow",live_meta["scroll"]<=live_meta["client"]+2,live_meta)
    ctx.close()
    browser.close()
report={"candidate":str(SOURCE.relative_to(BASE)),"browser":"Google Chrome stable","live_page_changed":False,"live_editor_parity":False,"passed":sum(x["pass"] for x in checks),"total":len(checks),"checks":checks}
(OUT/"report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print("V51 REAL CHROME VISUAL AND VIDEO",report["passed"],"/",report["total"])
if report["passed"]!=report["total"]:raise SystemExit(1)
