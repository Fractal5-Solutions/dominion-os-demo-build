"""Read-only live visual/media acceptance of published /demo-1 v4.4.

Uses actual Google Chrome for H.264 playback (not synthetic event dispatch).
No Squarespace write, production credentials or internal control-plane access.
"""
import json
from pathlib import Path
from playwright.sync_api import sync_playwright

URL="https://www.fractal5solutions.com/demo-1"
BUILD="demo-1-v4.4-20261028-production-preflight"
WIDTHS=(1440,1200,1024,768,430,390,360)
OUT=Path("live-v44-visual-proof")
OUT.mkdir(exist_ok=True)
checks=[]
def check(name,ok,detail=""):
    item={"check":name,"pass":bool(ok),"detail":str(detail)[:320]}
    checks.append(item)
    if not ok: print("FAIL",name,item["detail"])

with sync_playwright() as p:
    browser=p.chromium.launch(channel="chrome",headless=True,args=["--no-sandbox","--autoplay-policy=no-user-gesture-required"])
    for width in WIDTHS:
        context=browser.new_context(viewport={"width":width,"height":920},device_scale_factor=1,accept_downloads=False)
        page=context.new_page()
        errors=[]
        page.on("pageerror",lambda e:errors.append(str(e)))
        response=page.goto(URL,wait_until="domcontentloaded",timeout=45000)
        check(f"{width}px live HTTP OK",bool(response and response.ok))
        root=page.locator("#fractal5-demo-v44")
        root.wait_for(state="visible",timeout=15000)
        check(f"{width}px correct live build",root.get_attribute("data-build")==BUILD)
        layout=page.evaluate("""() => {
           const root=document.getElementById('fractal5-demo-v44');
           let els=[...root.querySelectorAll('h1,h2,h3,button,a,.panel,.step')];
           let errors=els.filter(el => {
             const s=getComputedStyle(el), x=el.getBoundingClientRect();
             return s.visibility!=='hidden' && s.display!=='none' && x.width>0 && (x.left< -2 || x.right>innerWidth+2)
           });
           return {scrollWidth:document.documentElement.scrollWidth,clientWidth:document.documentElement.clientWidth,
             rootScroll:root.scrollWidth,rootClient:root.clientWidth,offenders:errors.map(e=>e.outerHTML.slice(0,100))};
        }""")
        check(f"{width}px no overflow",layout["scrollWidth"]<=layout["clientWidth"]+2 and layout["rootScroll"]<=layout["rootClient"]+2,layout)
        check(f"{width}px controls remain onscreen",not layout["offenders"],layout["offenders"])
        screenshot=OUT/f"live-{width}.png"
        page.screenshot(path=str(screenshot),full_page=True,animations="disabled")
        check(f"{width}px screenshot captured",screenshot.exists() and screenshot.stat().st_size>4000,screenshot.name)
        check(f"{width}px no uncaught JS error",not errors,errors)
        if width==1440:
            videos=page.locator("#fractal5-demo-v44 video")
            check("two visible public films",videos.count()==2,videos.count())
            for mode,idx in (("business",0),("politics",1)):
                video=videos.nth(idx)
                video.scroll_into_view_if_needed()
                # Real HTMLMediaElement play() on Chrome, not synthetic event dispatch.
                outcome=video.evaluate("""async v=>{
                  v.muted=true;
                  v.preload='auto';
                  try {await Promise.race([v.play(),
                    new Promise((_,reject)=>setTimeout(()=>reject(Error('play-timeout')),18000))]);}
                  catch(e){return {ok:false,error:String(e),readyState:v.readyState,
                    mediaError:v.error&&v.error.message,src:v.currentSrc}}
                  await new Promise(resolve=>setTimeout(resolve,1500));
                  return {ok:!v.paused && v.currentTime>0 && !v.error,
                    time:v.currentTime,readyState:v.readyState,paused:v.paused,
                    mediaError:v.error&&v.error.message,src:v.currentSrc}
                }""")
                check(mode+" actual Chrome MP4 video plays and advances",bool(outcome["ok"]),outcome)
                video.evaluate("v=>v.pause()")
            # After video test, verify public proof footer rather than production claims.
            check("customer-data uploads absent",page.locator('input[type="file"]').count()==0)
            check("commercial binary link absent",page.locator('a[href$=".exe"],a[href$=".msi"]').count()==0)
        context.close()
    browser.close()
report={"url":URL,"browser":"Google Chrome stable","build":BUILD,"passed":sum(x["pass"] for x in checks),"total":len(checks),"checks":checks}
(OUT/"report.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print("LIVE VISUAL AND REAL VIDEO ACCEPTANCE:",report["passed"],"/",report["total"])
if report["passed"]!=report["total"]:
    raise SystemExit(1)
