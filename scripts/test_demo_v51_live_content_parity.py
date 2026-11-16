"""Read-only visible-content parity check for current Squarespace /demo-1 and v5.1.
This is NOT exact HTML or Squarespace editor-code parity.
"""
from pathlib import Path
import json, re, urllib.request
from bs4 import BeautifulSoup
BASE=Path(__file__).resolve().parents[1]
CANDIDATE=BASE/"squarespace/demo-1-v5.1-live-parity-candidate.html"
LIVE="https://www.fractal5solutions.com/demo-1"
with urllib.request.urlopen(urllib.request.Request(LIVE,headers={"User-Agent":"Mozilla/5.0 (compatible; Fractal5DemoParityQA/1.0)"}),timeout=30) as response:
    assert response.status==200, "live Squarespace HTTP unavailable"
    live_bytes=response.read(2_000_000)
current=BeautifulSoup(live_bytes,"html.parser")
candidate=BeautifulSoup(CANDIDATE.read_text(encoding="utf-8"),"html.parser")
for unwanted in current.select("script,style,noscript"):
    unwanted.decompose()
for unwanted in candidate.select("script,style,noscript"):
    unwanted.decompose()
def normalize(s):
    return re.sub(r"\\s+"," ",s.replace("\\u00a0"," ")).casefold()
live_text=normalize(current.get_text(" ",strip=True))
draft_text=normalize(candidate.get_text(" ",strip=True))
phrases={
    "business and politics":("business","politics"),
    "synthetic and authorisation":("synthetic","approve simulated decision"),
    "windows evaluation":("windows evaluation","authenticode"),
    "google cloud gates":("google cloud","cloud run","public login"),
    "seven day proposed terms":("seven-day","50 read-only runs","10 mib per file","50 mib per tenant"),
    "module catalogue":("grantconnect","teamconnect","policyconnect","channelconnect","cloud engine","vault systems","command core","advocate engine","install grid","opssignal","ecostack","storythread","dataharbor"),
    "commercial access":("request","governed"),
}
checks=[]
for group,words in phrases.items():
    present_live=all(word in live_text for word in words)
    present_draft=all(word in draft_text for word in words)
    if group == "commercial access":
        access_url="https://www.fractal5solutions.com/launch"
        present_live=present_live and any(a.get("href", "").rstrip("/")==access_url for a in current.select("a[href]"))
        present_draft=present_draft and any(a.get("href", "").rstrip("/")==access_url for a in candidate.select("a[href]"))
    checks.append({"group":group,"live":present_live,"candidate":present_draft,"pass":present_live and present_draft})
    print(("PASS " if present_live and present_draft else "FAIL ")+group+" live="+str(present_live)+" draft="+str(present_draft))
report={"live_url":LIVE,"live_bytes":len(live_bytes),"candidate":str(CANDIDATE.relative_to(BASE)),"checks":checks,"passed":sum(x["pass"] for x in checks),"total":len(checks),"exact_squarespace_editor_parity":False}
print("LIVE CONTENT PARITY",report["passed"],"/",report["total"])
if report["passed"]!=report["total"]:
    raise SystemExit(1)
