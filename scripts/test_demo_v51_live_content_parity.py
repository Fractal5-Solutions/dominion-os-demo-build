"""Read-only SEMANTIC release and feature parity, not source/editor-code equality.

Current Squarespace copy may legitimately condense technical detail. Validate that
its core experiences and nonavailability boundaries remain truthful, and that the
candidate preserves those experiences PLUS planned Windows/Google integrations.
Never bypass a real absence by asserting a historical build marker.
"""
from pathlib import Path
import json, re, urllib.request
from bs4 import BeautifulSoup

BASE=Path(__file__).resolve().parents[1]
CANDIDATE=BASE/"squarespace/demo-1-v5.1-live-parity-candidate.html"
LIVE="https://www.fractal5solutions.com/demo-1"
with urllib.request.urlopen(
    urllib.request.Request(LIVE,headers={"User-Agent":"Mozilla/5.0 (compatible; Fractal5DemoParityQA/1.1)"}),
    timeout=30,
) as response:
    assert response.status == 200, "live Squarespace HTTP unavailable"
    live_bytes=response.read(2_000_000)
current=BeautifulSoup(live_bytes,"html.parser")
candidate=BeautifulSoup(CANDIDATE.read_text(encoding="utf-8"),"html.parser")
live_builds=[x.get("data-build") for x in current.select("[data-build]")]
candidate_builds=[x.get("data-build") for x in candidate.select("[data-build]")]
for doc in (current,candidate):
    for unwanted in doc.select("script,style,noscript"):
        unwanted.decompose()

def normalize(s):
    return re.sub(r"\s+"," ",s.replace("\u00a0"," ")).casefold()

live=normalize(current.get_text(" ",strip=True))
draft=normalize(candidate.get_text(" ",strip=True))
def all_of(t,*values):
    return all(normalize(v) in t for v in values)
def any_of(t,*values):
    return any(normalize(v) in t for v in values)
def launch_link(doc):
    return any(a.get("href","").rstrip("/")=="https://www.fractal5solutions.com/launch" for a in doc.select("a[href]"))

# These are meaning-equivalent evidence-bound claims, NOT a copy-exact requirement.
# A live site that removes its availability warnings must fail this test.
checks=[
    ("Business and Politics mission modes",
     all_of(live,"business","politics") and all_of(draft,"business","politics")),
    ("fictional demonstration and human approval",
     all_of(live,"synthetic","approval") and all_of(draft,"synthetic","approval")),
    ("Windows not yet publicly installable",
     all_of(live,"windows","seven-day") and any_of(live,"no public executable download","not yet signed","not yet certified")
     and all_of(draft,"windows","seven-day") and any_of(draft,"no installer","no executable download")),
    ("Google Cloud held from public login and upload",
     all_of(live,"google cloud","sandbox") and any_of(live,"no public login","not yet activated","no public cloud login")
     and all_of(draft,"google cloud") and any_of(draft,"public login, uploads and authenticated customer-data processing remain disabled","customer-data upload, hosted login")),
    ("candidate preserves additional nonactive pilot restrictions",
     all_of(draft,"50 read-only runs","10 mib per file","50 mib per tenant","not presently active")
     and all_of(live,"seven-day") and any_of(live,"not yet activated","not yet signed","review-stage")),
    ("thirteen SaaS catalogue entries",
     all_of(live,"grantconnect","teamconnect","policyconnect","channelconnect","cloud engine","vault systems",
            "command core","advocate engine","install grid","opssignal","ecostack","storythread","dataharbor")
     and all_of(draft,"grantconnect","teamconnect","policyconnect","channelconnect","cloud engine","vault systems",
            "command core","advocate engine","install grid","opssignal","ecostack","storythread","dataharbor")),
    ("governed commercial inquiry destination",
     launch_link(current) and launch_link(candidate)),
    ("two priority platform choices, with no false native or Google access",
     len(candidate.select('header [data-platform="windows"]'))==1
     and len(candidate.select('header [data-platform="google"]'))==1
     and len(candidate.select('[data-native-installer-certified="false"]'))==1
     and len(candidate.select('[data-google-login-certified="false"]'))==1),
    ("Workspace OAuth is explicitly gated and no customer upload offered",
     all_of(draft,"google workspace","gmail","calendar","drive","docs","sheets")
     and len(candidate.select('[data-workspace-oauth-certified="false"][data-live-google-connectors="disabled"]'))==1
     and not candidate.select('input[type="file"],form')),
]
results=[]
for name, passed in checks:
    results.append({"group":name,"pass":bool(passed)})
    print(("PASS " if passed else "FAIL ")+name)
report={
    "live_url":LIVE,
    "live_bytes":len(live_bytes),
    "live_builds":live_builds,
    "candidate":str(CANDIDATE.relative_to(BASE)),
    "candidate_builds":candidate_builds,
    "exact_squarespace_editor_parity":False,
    "semantic_feature_scope_only":True,
    "checks":results,
    "passed":sum(x["pass"] for x in results),
    "total":len(results),
}
print("LIVE SEMANTIC EXPERIENCE PARITY",report["passed"],"/",report["total"])
if report["passed"] != report["total"]:
    raise SystemExit(1)
