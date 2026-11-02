"""Bounded read-only public Fractal5 website/demo secret-exposure and conversion audit.
Does not fetch private assets, authenticate, mutate CMS, test intrusion, or print credential values.
"""
from __future__ import annotations
from html.parser import HTMLParser
from urllib.parse import urlsplit, urljoin
from urllib.request import Request, urlopen
from urllib.error import HTTPError, URLError
from xml.etree import ElementTree
from pathlib import Path
import json, re, hashlib, datetime, os

SITE="https://www.fractal5solutions.com"
DEMO=SITE+"/demo-1"
PAGES=["/","/demo-1","/launch","/store-preview","/license","/dominion-os","/dominion-politics","/assurance","/about"]
PUBLIC_DEMOS=["https://fractal5-solutions.github.io/dominion-os-demo-build/demo/live-mission-demo.html?mode=business",
              "https://fractal5-solutions.github.io/dominion-os-demo-build/demo/live-mission-demo.html?mode=politics"]
LIMIT_PAGES=60
LIMIT_BYTES=2_000_000
TIMEOUT=20
OUT=Path("security-audit-receipts")
OUT.mkdir(exist_ok=True)
class Parser(HTMLParser):
    def __init__(self):
        super().__init__();self.links=[];self.scripts=[];self.forms=[];self.inputs=[];self.iframes=[]
    def handle_starttag(self,tag,attrs):
        a=dict(attrs)
        if tag=="a":self.links.append(a.get("href",""))
        if tag=="script" and a.get("src"):self.scripts.append(a.get("src"))
        if tag=="form":self.forms.append(a)
        if tag=="input":self.inputs.append(a)
        if tag=="iframe":self.iframes.append(a.get("src",""))
def fetch(url):
    req=Request(url,headers={"User-Agent":"Fractal5-Public-ReadOnly-Security-Audit/1.0",
                              "Cache-Control":"no-cache","Accept":"text/html,application/xml,text/xml"})
    with urlopen(req,timeout=TIMEOUT) as r:
        ct=r.headers.get("Content-Type","")
        blob=r.read(LIMIT_BYTES+1)
        if len(blob)>LIMIT_BYTES:raise ValueError("size-cap-exceeded")
        return r.status,r.geturl(),ct,blob.decode("utf-8","replace"),{
          key:r.headers.get(key) for key in ("Strict-Transport-Security","Content-Security-Policy","X-Content-Type-Options",
                    "Referrer-Policy","Permissions-Policy","Access-Control-Allow-Origin","Cache-Control")
        }
def sitemap_urls():
    entries=[]
    try:
        status, url, ct, xml, _=fetch(SITE+"/sitemap.xml")
        root=ElementTree.fromstring(xml)
        for e in root.iter():
            if e.tag.rsplit("}",1)[-1]=="loc" and e.text:
                loc=e.text.strip()
                if urlsplit(loc).netloc in ("www.fractal5solutions.com","fractal5solutions.com"):
                    if loc.endswith(".xml"):continue
                    if urlsplit(loc).path.lower().endswith((".jpg",".jpeg",".png",".gif",".pdf",".webp")):continue
                    entries.append(loc)
    except Exception as e:
        print("SITEMAP_NOT_AVAILABLE",type(e).__name__)
    return entries
PATTERNS={
  "private_key":r"-----BEGIN\s+(?:RSA|EC|OPENSSH|DSA|ENCRYPTED|PRIVATE)\s+PRIVATE KEY-----",
  "aws_access_id":r"\b(?:AKIA|ASIA)[0-9A-Z]{16}\b",
  "github_token":r"\b(?:ghp_|gho_|ghu_|ghs_|ghr_)[a-zA-Z0-9]{30,}\b|\bgithub_pat_[A-Za-z0-9_]{30,}\b",
  "openai_secret":r"\bsk-(?:proj-|svcacct-)?[A-Za-z0-9_-]{24,}\b",
  "google_browser_key":r"\bAIza[0-9A-Za-z_-]{35}\b",
  "slack_token":r"\bxox[baprs]-[A-Za-z0-9-]{15,}\b",
  "stripe_private":r"\bsk_(?:live|test)_[A-Za-z0-9]{18,}\b",
  "twilio_key":r"\bSK[0-9a-fA-F]{32}\b",
  "credential_assignment":r"(?i)\b(?:client_secret|private_key|refresh_token|access_token|password|api_secret)\b\s*[:=]\s*['\"](?!false|true|undefined|null)[^'\"\s]{12,}['\"]",
  "sensitive_path":r"(?:[CcDd]:\\(?:Users|ProgramData|phi-ops|Fractal5)\\|/home/(?:ubuntu|runner|oai)/[^\s<>\"']+|/etc/(?:shadow|passwd))",
  "source_map_reference":r"(?i)(?:sourceMappingURL=|[\"']/[^\"']+\.map[\"'])",
}
regex={k:re.compile(p) for k,p in PATTERNS.items()}
all_urls=list(dict.fromkeys([SITE+p for p in PAGES]+sitemap_urls()+PUBLIC_DEMOS))[:LIMIT_PAGES]
records=[]
for idx,url in enumerate(all_urls):
    item={"url":url,"reachable":False,"findings":[]}
    try:
        status,dest,ct,html,headers=fetch(url)
        item.update({"reachable":status==200,"status":status,"content_type":ct,
                     "size_chars":len(html),"sha256":hashlib.sha256(html.encode()).hexdigest()})
        parser=Parser();parser.feed(html)
        item["counts"]={"anchors":len(parser.links),"external_script_src":len(parser.scripts),"forms":len(parser.forms),
                        "file_inputs":sum(x.get("type","").lower()=="file" for x in parser.inputs),"iframes":len(parser.iframes)}
        item["script_hostnames"]=sorted(set(urlsplit(urljoin(dest,s)).netloc for s in parser.scripts))
        item["headers_present"]={k:bool(v) for k,v in headers.items()}
        # Findings are label/counts only: never print matching material, raw snippets, credentials, or query tokens.
        for label,rgx in regex.items():
            found=list(rgx.finditer(html))
            if found:item["findings"].append({"name":label,"count":len(found)})
        if urlsplit(url).path=="/demo-1":
            item["demo"]={
              "v46_marker":"demo-1-v4.6-20261102-canon-v2" in html,
              "signed_installer_enabled":'data-windows-installer-certified="true"' in html,
              "cloud_trial_enabled":'data-cloud-trial-certified="true"' in html,
              "licensing_enabled":'data-licence-issuance-enabled="true"' in html,
              "evaluation_section":"fractal5-demo-v46-evaluation" in html,
              "download_handler":"Dominion-OS-Free-Business-Politics-Demo.html" in html,
              "direct_executable_links":sum(bool(re.search(r"\.(?:exe|msi|msix)(?:$|[?#])",x,re.I)) for x in parser.links),
              "has_valid_license_link":any(urlsplit(urljoin(dest,l)).path=="/license" for l in parser.links),
              "has_valid_store_link":any(urlsplit(urljoin(dest,l)).path=="/store-preview" for l in parser.links),
              "has_valid_launch_link":any(urlsplit(urljoin(dest,l)).path=="/launch" for l in parser.links),
              "listed_billing_checkout":any("checkout" in x.lower() or "billing" in x.lower() for x in parser.links)
            }
    except Exception as e:
        item["error_class"]=type(e).__name__
    records.append(item)
    print("AUDIT",idx+1,"/"+str(len(all_urls)),urlsplit(url).path,"reach",item["reachable"],
          "findings",','.join(x["name"] for x in item["findings"]) or "-")
demo=next((x for x in records if urlsplit(x["url"]).path=="/demo-1"),{})
exposed=[(x["url"],f["name"],f["count"]) for x in records for f in x["findings"]]
required=["/demo-1","/launch","/store-preview","/license"]
required_available=all(any(urlsplit(r["url"]).path==p and r["reachable"] for r in records) for p in required)
checks={
 "required_public_routes_reachable":required_available,
 "live_v46_is_published":demo.get("demo",{}).get("v46_marker",False),
 "public_demo_no_installer_or_cloud_activation":not any(demo.get("demo",{}).get(k,True) for k in ("signed_installer_enabled","cloud_trial_enabled","licensing_enabled")),
 "no_direct_executable_links_in_demo":demo.get("demo",{}).get("direct_executable_links")==0,
 "no_customer_file_upload_in_demo":demo.get("counts",{}).get("file_inputs")==0,
 "no_high_confidence_secret_patterns":len(exposed)==0,
 "has_governed_access_route":demo.get("demo",{}).get("has_valid_launch_link",False)
}
report={"timestamp_utc":datetime.datetime.now(datetime.timezone.utc).isoformat(),
        "scope":"Read-only public HTML/inline JS of bounded known routes, sitemap entries (if accessible), and hosted demos; NOT server, private repo history, third-party JS, edge/WAF, authenticated APIs or future binaries",
        "checks":checks,"pages_checked":len(records),"pages_reachable":sum(x["reachable"] for x in records),
        "findings_count":len(exposed),"findings": [{"url":u,"category":n,"count":c} for u,n,c in exposed],
        "demo":demo.get("demo",{}),"records":records,
        "limits":"Public strings and source patterns are indicators, not full vulnerability testing; zero matches never guarantees zero exposed secrets."}
(OUT/"public-security-scan.json").write_text(json.dumps(report,indent=2),encoding="utf-8")
print("SUMMARY",json.dumps({"checks":checks,"pages_checked":report["pages_checked"],
"pages_reachable":report["pages_reachable"],"findings_count":report["findings_count"],
"demo":report["demo"]}),flush=True)
# Explicitly not failing for absence of paid link: report that as a required improvement, since current route /launch qualifies.
if not all(checks.values()):raise SystemExit(1)
