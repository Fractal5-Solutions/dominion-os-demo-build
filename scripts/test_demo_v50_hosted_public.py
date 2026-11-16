"""Read-only public hosted Business/Politics smoke checks. No credentials or uploads."""
import json, urllib.request, urllib.error, sys
BASE="https://fractal5-solutions.github.io/dominion-os-demo-build/demo/"
results=[]
def check(name,good,detail=""):
    results.append({"name":name,"pass":bool(good),"detail":str(detail)[:180]})
    print(("PASS " if good else "FAIL ")+name+" "+str(detail)[:90])
def get(relative,limit=600000):
    request=urllib.request.Request(BASE+relative,headers={"User-Agent":"Dominion-Public-Demo-QA/1.0","Accept":"text/html,video/mp4,*/*"})
    with urllib.request.urlopen(request, timeout=22) as response:
        payload=response.read(limit+1)
        return response.status,response.headers.get("Content-Type",""),payload
for mode in ("business","politics"):
    try:
        status,ctype,payload=get("live-mission-demo.html?mode="+mode)
        decoded=payload.decode("utf-8")
        check(mode+" hosted HTML 200",status==200 and "html" in ctype.lower(),str(status)+" "+ctype)
        check(mode+" hosted synthetic UI", "SYNTHETIC" in decoded.upper() and "mode" in decoded.lower(),len(payload))
    except (urllib.error.URLError,TimeoutError,UnicodeDecodeError) as exc:
        check(mode+" hosted HTML 200",False,type(exc).__name__)
        check(mode+" hosted synthetic UI",False,type(exc).__name__)
    try:
        status,ctype,payload=get("media/dominion-os-"+mode+"-1080p.mp4")
        check(mode+" hosted MP4 container",status==200 and len(payload)>128 and payload[4:8]==b"ftyp",str(status)+" "+ctype+" "+str(len(payload)))
    except (urllib.error.URLError,TimeoutError) as exc:
        check(mode+" hosted MP4 container",False,type(exc).__name__)
result={"base":BASE,"passed":sum(x["pass"] for x in results),"total":len(results),"checks":results}
print("PUBLIC HOSTED SMOKE",result["passed"],"/",result["total"])
if result["passed"]!=result["total"]:sys.exit(1)
