"""PR-only v4.7 acceptance for the November 1 LIVE Squarespace baseline.
No IAM, billing, production deployment, public installer, customer upload or cloud login.
"""
from pathlib import Path
import hashlib, json, os, re, tempfile
from bs4 import BeautifulSoup
from playwright.sync_api import sync_playwright

BASE=Path(__file__).resolve().parents[1]
PAGE=BASE/"squarespace/demo-1-v4-7-commercial-handoff-candidate.html"
raw=PAGE.read_text(encoding="utf-8")
soup=BeautifulSoup(raw,"html.parser")
root=soup.select_one("#fractal5-demo-v47")
checks=[]

def check(name,good):
    checks.append({"name":name,"passed":bool(good)})
    if not good:print("FAIL",name)

check("one scoped Canon root",len(soup.select("section#fractal5-demo-v47"))==1)
check("live-baseline v4.7 identity",bool(root and root.get("data-build")=="demo-1-v4.7-20261102-commercial-handoff"))
check("synthetic-only claim",root.get("data-claim")=="synthetic-public-proof")
for key in ("data-windows-installer-certified","data-cloud-trial-certified","data-cloud-deployment-certified","data-licence-issuance-enabled"):
    check(key+" fail-closed",root.get(key)=="false")
check("no duplicate IDs",len(root.find_all(id=True))==len({x["id"] for x in root.find_all(id=True)}))
check("single H1",len(root.find_all("h1"))==1)
check("baseline live sections preserved",all(x in raw for x in ("Google Cloud is the active architectural focus.","Thirteen modules. One governed command layer.","A governed command architecture for business and politics.")))
check("Canon Light metadata",root.get("data-canon")=="fractal5-light-v2")
check("Canon tokens",all(t in raw for t in ["#101112","#fbfaf7","#f5f2ec","#e4ded3","#9b742d","#c5a461"]))
check("rounded primary surfaces",all(t in raw for t in ["border-radius:22px","border-radius:17px","border-radius:999px"]))
check("H1 bounded to canonical 68px", "clamp(40px,5.4vw,68px)" in raw and "max-width:840px" in raw)
check("brand nonbreaking", "Dominion&nbsp;OS" in raw and "DOMINION&nbsp;OS" in raw and "Dominion OS" not in raw and "DOMINION OS" not in raw)
check("legacy f5 root absent", "f5d26" not in raw)
check("prior broken button attribute corrected", 'data-prev type="button">' in raw)
check("transparent page root", "background:transparent;color:var(--ink)" in raw)
modules=["GrantConnect","TeamConnect","PolicyConnect","ChannelConnect","Cloud Engine","Vault Systems","Command Core","Advocate Engine","Install Grid","OpsSignal","EcoStack","StoryThread","DataHarbor"]
check("13 catalogued modules exact", [x.find("strong").get_text(strip=True) for x in root.select(".suites .suite")]==modules)
check("3 Coming Soon disclosed", [x.find("strong").get_text(strip=True) for x in root.select(".suites .suite") if x.find(class_="micro")] == ["Install Grid","EcoStack","DataHarbor"])
check("two distinct genuine-evaluation paths",len(root.select("#fractal5-demo-v47-evaluation article.panel"))==2)
check("public browser never accepts customer uploads",not root.select("form,input[type=file],input[type=password]"))
check("no installer/provider ZIP public href",not any(re.search(r"\\.(exe|msi|msix|zip)($|[?#])",a.get("href",""),re.I) for a in root.find_all("a")))
check("all hash anchors resolve",all(root.select_one(a["href"]) for a in root.find_all("a",href=lambda x:x and x.startswith("#"))))
check("external links use safe rel",all("noopener" in a.get("rel",[]) and "noreferrer" in a.get("rel",[]) for a in root.find_all("a",target="_blank")))

commercial=root.select_one("#fractal5-demo-v47-commercial")
check("paid upgrade section visible",commercial is not None)
check("no false checkout advertised",bool(commercial and commercial.get("data-paid-checkout-enabled")=="false"))
check("no unsupported trial backend claim",bool(commercial and commercial.get("data-trial-enforcement-state")=="BACKEND_NOT_YET_CERTIFIED"))
paidlinks={a.get("href") for a in commercial.find_all("a")} if commercial else set()
check("direct verified licensing path", "https://www.fractal5solutions.com/license" in paidlinks)
check("direct verified commercial planning path", "https://www.fractal5solutions.com/store-preview" in paidlinks)
check("direct verified qualification path", "https://www.fractal5solutions.com/launch" in paidlinks)
check("free synthetic demos not paywalled", "remain free and never require payment" in commercial.get_text(" ",strip=True) if commercial else False)
check("expired protected trial denies unpaid use", "protected features must stop" in commercial.get_text(" ",strip=True) if commercial else False)
check("not an auto checkout", "not a payment checkout" in commercial.get_text(" ",strip=True) if commercial else False)

for term in ("seven days","50 read-only runs","10 MiB per file","50 MiB per tenant","24 hours","one active cloud session","revocation","publisher Authenticode","privacy review"):
    check("proposed trial safeguard: "+term,term.lower() in raw.lower())

with sync_playwright() as pw:
    executable={"executable_path":"/usr/bin/chromium"} if Path("/usr/bin/chromium").is_file() else {}
    browser=pw.chromium.launch(headless=True,args=["--no-sandbox"],**executable)
    for width in (1440,1200,1024,768,430,390,360):
        ctx=browser.new_context(viewport={"width":width,"height":950},accept_downloads=True)
        page=ctx.new_page()
        errors=[]
        page.on("pageerror",lambda e:errors.append(str(e)))
        page.route("http**",lambda route:route.abort())
        page.set_content(raw,wait_until="domcontentloaded")
        dim=page.evaluate("""() => {let d=document.documentElement,r=document.querySelector('#fractal5-demo-v47'),v=[...r.querySelectorAll('h1,h2,h3,.btn,button,.panel,.suite')];return {dc:d.clientWidth,ds:d.scrollWidth,rc:r.clientWidth,rs:r.scrollWidth,out:v.some(e=>{let x=e.getBoundingClientRect();return x.width>0&&(x.left < -2||x.right>innerWidth+2)})}}""")
        check(f"{width}px no horizontal overflow",dim["ds"]<=dim["dc"]+2 and dim["rs"]<=dim["rc"]+2)
        check(f"{width}px visible controls",not dim["out"])
        check(f"{width}px no JS errors",not errors)
        check(f"{width}px 13 module cards",page.locator(".suites .suite").count()==13)
        page.locator('[data-mode="politics"]').click()
        check(f"{width}px Politics works","legislative" in page.locator('[data-description]').inner_text().lower())
        page.locator('[data-mode="business"]').click()
        for _ in range(4):page.locator("[data-next]").click()
        check(f"{width}px approval mandatory",page.locator("[data-next]").is_disabled())
        page.locator("[data-approve]").click()
        check(f"{width}px approval unlocks",page.locator("[data-next]").is_enabled())
        page.locator("[data-next]").click()
        check(f"{width}px bounded evidence","SIMULATED" in page.locator("[data-receipt]").inner_text())
        page.locator("[data-reset]").click()
        check(f"{width}px reset",page.locator("[data-counter]").inner_text().startswith("01 / 07"))
        if width in (1440,390):
            shots=BASE/"v47-canon-screenshots"
            shots.mkdir(exist_ok=True)
            page.screenshot(path=str(shots/f"{width}px.png"),full_page=True)
        if width==1440:
            with page.expect_download() as ev:page.locator("[data-download]").first.click()
            dl=ev.value
            check("offline HTML filename",dl.suggested_filename=="Dominion-OS-Free-Business-Politics-Demo.html")
            with tempfile.TemporaryDirectory() as temp:
                target=Path(temp)/dl.suggested_filename
                dl.save_as(target)
                offline=ctx.new_page()
                e=[];network=[]
                offline.on("pageerror",lambda x:e.append(str(x)))
                offline.on("request",lambda x:network.append(x.url) if x.url.startswith("http") else None)
                offline.route("http**",lambda route:route.abort())
                offline.set_content(target.read_text(encoding="utf-8"),wait_until="domcontentloaded")
                check("offline downloaded file opens",offline.locator("#fractal5-demo-v47").count()==1)
                offline.locator('[data-mode="politics"]').click()
                check("offline Politics interactive","legislative" in offline.locator('[data-description]').inner_text().lower())
                check("offline JS runs",not e)
                check("offline no outbound traffic",not network)
                offline.close()
        ctx.close()
    browser.close()

report={"source_sha256":hashlib.sha256(PAGE.read_bytes()).hexdigest(),"canon":"fractal5-light-v2","passed":sum(x["passed"] for x in checks),"total":len(checks),"checks":checks}
path=Path(os.environ.get("F5_DEMO_QA_REPORT","prepublication-v47-results.json"))
path.write_text(json.dumps(report,indent=2),encoding="utf-8")
print("Live baseline v4.7 Chromium acceptance:",report["passed"],"/",report["total"])
if report["passed"]!=report["total"]:raise SystemExit(1)
