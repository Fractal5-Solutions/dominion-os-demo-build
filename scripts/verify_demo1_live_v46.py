"""Read-only browser acceptance for live Squarespace /demo-1.
No CMS access, secrets, mutation, cloud provisioning or customer data.
"""
from pathlib import Path
from playwright.sync_api import sync_playwright
import datetime, hashlib, json, os, urllib.request, urllib.error
from urllib.parse import urlencode

URL="https://www.fractal5solutions.com/demo-1"
EXPECTED="demo-1-v4.6-20261102-canon-v2"
OUT=Path("live-v46-receipts")
OUT.mkdir(exist_ok=True)
checks=[]
def record(name,ok,details=None):
    checks.append(dict(check=name,pass_=bool(ok),details=str(details or "")[:350]))
    print(("PASS" if ok else "FAIL")+" "+name+(" "+str(details)[:170] if details else ""),flush=True)

def probe(url,tag):
    req=urllib.request.Request(url,headers={
      "User-Agent":"Mozilla/5.0 Fractal5-Certification/1.0",
      "Cache-Control":"no-cache, no-store, must-revalidate",
      "Pragma":"no-cache"
    })
    try:
        with urllib.request.urlopen(req,timeout=25) as response:
            html=response.read(1_500_000).decode("utf-8","replace")
            status=response.status
            headers={k:response.headers.get(k) for k in ("Date","Age","ETag","Cache-Control","Via","X-Cache","CF-Cache-Status")}
            observed=dict(url=response.url,status=status,bytes=len(html.encode()),sha256=hashlib.sha256(html.encode()).hexdigest(),headers=headers,
                v46="fractal5-demo-v46" in html,build=EXPECTED in html,
                v45="fractal5-demo-v45" in html,legacy="f5d26" in html,
                evaluation="fractal5-demo-v46-evaluation" in html,
                signed_windows_open='data-windows-installer-certified="true"' in html,
                cloud_open='data-cloud-trial-certified="true"' in html)
            (OUT/(tag+".json")).write_text(json.dumps(observed,indent=2))
            print("HTTP_PROBE "+json.dumps(observed),flush=True)
            return observed
    except Exception as exc:
        observed=dict(url=url,error=repr(exc)[:500])
        (OUT/(tag+".json")).write_text(json.dumps(observed,indent=2))
        print("HTTP_ERROR "+json.dumps(observed),flush=True)
        return observed
base=probe(URL,"canonical-http")
fresh=probe(URL+"?"+urlencode({"f5audit":"20261102-v46-"+os.environ.get("GITHUB_SHA","unknown")[:12]}),"cachebusted-http")
record("canonical HTTP reachable",base.get("status")==200,base.get("status") or base.get("error"))
record("cache-busted HTTP reachable",fresh.get("status")==200,fresh.get("status") or fresh.get("error"))
record("canonical v4.6 identity in HTTP",base.get("build",False))
record("fresh v4.6 identity in HTTP",fresh.get("build",False))
record("new evaluation section present",base.get("evaluation",False) or fresh.get("evaluation",False))
record("no public Windows trial activation",not base.get("signed_windows_open",False) and not fresh.get("signed_windows_open",False))
record("no public cloud trial activation",not base.get("cloud_open",False) and not fresh.get("cloud_open",False))

with sync_playwright() as pw:
    browser=pw.chromium.launch(headless=True,args=["--no-sandbox"])
    for width in (1440,1200,1024,768,430,390,360):
        context=browser.new_context(viewport={"width":width,"height":900},accept_downloads=True,ignore_https_errors=False)
        page=context.new_page()
        try:
            response=page.goto(URL,wait_until="domcontentloaded",timeout=35000)
            page.wait_for_timeout(1200)
            obs=page.evaluate("""() => {
              const root=document.querySelector('#fractal5-demo-v46'), old=document.querySelector('#f5d26');
              const d=document.documentElement;
              return {title:document.title,url:location.href,marker:root?.dataset.build??null,root:!!root,legacy:!!old,
               n13:root?.querySelectorAll('.suites .suite').length??0,
               evalPresent:!!document.querySelector('#fractal5-demo-v46-evaluation'),
               buttons:root?.querySelectorAll('button').length??0,
               scrollWidth:d.scrollWidth,clientWidth:d.clientWidth,
               winGate:root?.dataset.windowsInstallerCertified??null,
               cloudGate:root?.dataset.cloudTrialCertified??null,
               licenceGate:root?.dataset.licenceIssuanceEnabled??null};
            }""")
            print("BROWSER "+json.dumps(dict(width=width,status=response.status if response else None,**obs)),flush=True)
            if width in (1440,390):
                page.screenshot(path=str(OUT/("live-"+str(width)+".png")),full_page=True)
            record(str(width)+"px v4.6 marker",obs["marker"]==EXPECTED,obs["marker"])
            record(str(width)+"px no document overflow",obs["scrollWidth"]<=obs["clientWidth"]+2,str(obs["scrollWidth"])+"/"+str(obs["clientWidth"]))
            record(str(width)+"px correct catalogue",obs["n13"]==13,obs["n13"])
            record(str(width)+"px release gates closed",obs["winGate"]=="false" and obs["cloudGate"]=="false" and obs["licenceGate"]=="false")
            if obs["marker"]!=EXPECTED:
                continue
            page.locator("#fractal5-demo-v46 [data-mode=politics]").click(timeout=5000)
            record(str(width)+"px Politics scenario works","legislative" in page.locator("#fractal5-demo-v46 [data-description]").inner_text().lower())
            page.locator("#fractal5-demo-v46 [data-mode=business]").click(timeout=5000)
            for _ in range(4):page.locator("#fractal5-demo-v46 [data-next]").click(timeout=5000)
            record(str(width)+"px approval gate enforced",page.locator("#fractal5-demo-v46 [data-next]").is_disabled())
            page.locator("#fractal5-demo-v46 [data-approve]").click(timeout=5000)
            record(str(width)+"px approval gate opens",page.locator("#fractal5-demo-v46 [data-next]").is_enabled())
            if width==1440:
                with page.expect_download(timeout=10000) as ev:page.locator("#fractal5-demo-v46 [data-download]").first.click(timeout=5000)
                dl=ev.value
                record("offline download filename",dl.suggested_filename=="Dominion-OS-Free-Business-Politics-Demo.html")
                dest=OUT/dl.suggested_filename
                dl.save_as(str(dest))
                txt=dest.read_text(encoding="utf-8")
                record("offline download contains v4.6 assets",EXPECTED in txt and "<script>" in txt and "fractal5-demo-v46" in txt)
        except Exception as exc:
            record(str(width)+"px browser exception",False,repr(exc))
            try:page.screenshot(path=str(OUT/("error-"+str(width)+".png")),full_page=True)
            except:pass
        finally:
            context.close()
    browser.close()
receipt=dict(checked_at=datetime.datetime.now(datetime.timezone.utc).isoformat(),url=URL,expected_build=EXPECTED,
  passed=sum(c["pass_"] for c in checks),total=len(checks),checks=checks,
  public_runtime_certified=False,claims="Publication acceptance only, not product certification")
(OUT/"live-v46-audit.json").write_text(json.dumps(receipt,indent=2))
print("LIVE_AUDIT "+json.dumps(dict(passed=receipt["passed"],total=receipt["total"],url=URL,expected=EXPECTED)),flush=True)
if receipt["passed"]!=receipt["total"]:raise SystemExit(1)
