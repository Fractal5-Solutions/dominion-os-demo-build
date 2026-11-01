#!/usr/bin/env python3
"""Fail-closed public demo gate check. Standard library; no credentials or mutations."""
import json
import hashlib
import pathlib
import sys
import urllib.request

ROOT = pathlib.Path(__file__).resolve().parents[1]
PACKAGE = ROOT / "demo/assets/demo-download-package.json"
APP = ROOT / "demo/live-mission-demo.html"
LIVE = "https://www.fractal5solutions.com/demo-1"
MISSION = "https://fractal5-solutions.github.io/dominion-os-demo-build/demo/live-mission-demo.html"
errors = []

def verify(condition, msg):
    print(("PASS" if condition else "FAIL") + ": " + msg)
    if not condition:
        errors.append(msg)

data = json.loads(PACKAGE.read_text(encoding="utf-8"))
html = APP.read_text(encoding="utf-8")
verify("<!doctype html>" in html.lower(), "Synthetic mission HTML present")
verify('data-mode="business"' in html and 'data-mode="politics"' in html, "Both mission contexts present")
verify("function approve()" in html and "function reject()" in html, "Approval and rejection controls present")
verify("idx===4&&!approved" in html, "Decision boundary blocks unapproved advancement")
verify(data["politicsExperience"]["downloadable"] is False, "Politics binary download disabled")
verify(data["windowsExperience"]["publicDownloadCertified"] is False or data["windowsExperience"]["authenticode"] == "VERIFIED", "Common Windows signing gate")
for provider in data.get("providerDownloads", []):
    if provider.get("publicDownloadCertified"):
        verify(False, provider["id"] + " must use independently verified exact-artifact release attestation (not implemented in this gate)")
    else:
        verify(not provider.get("publicDownloadUrl"), provider["id"] + " uncertified URL withheld")

# Public catalogue may not silently regress to historical SKUs or claim 13 live modules.
PRODUCT_SNAPSHOT = ROOT / "demo/assets/dominion-product-manifest.v1.json"
SAAS_CATALOG = ROOT / "demo/assets/dominion-saas-catalog.json"
EXPECTED_SAAS = {
    "GrantConnect": "APP-GRANTCONNECT-W1",
    "TeamConnect": "APP-TEAMCONNECT-W1",
    "PolicyConnect": "APP-POLICYCONNEC-W1",
    "ChannelConnect": "APP-CHANNELCONNE-W1",
    "Cloud Engine": "APP-CLOUD-ENGINE-W2",
    "Vault Systems": "APP-VAULT-SYSTEM-W2",
    "Command Core": "DOM-FS-COMMAND-CORE",
    "Advocate Engine": "APP-ADVOCATE-ENG-W2",
    "Install Grid": "APP-INSTALL-GRID",
    "OpsSignal": "APP-OPSSIGNAL-W2",
    "EcoStack": "APP-ECOSTACK",
    "StoryThread": "APP-STORYTHREAD-W2",
    "DataHarbor": "APP-DATAHARBOR",
}
product_bytes = PRODUCT_SNAPSHOT.read_bytes()
product = json.loads(product_bytes.decode("utf-8-sig"))
saas = json.loads(SAAS_CATALOG.read_text(encoding="utf-8-sig"))
for item_name, module_rows in (("public product snapshot", product["modules"]), ("public SaaS catalogue", saas["modules"])):
    pairs = [(m["name"], m["sku"]) for m in module_rows]
    verify(len(pairs) == 13 and len({name for name, _ in pairs}) == 13 and
           dict(pairs) == EXPECTED_SAAS, item_name + " exact 13 canonical module SKUs")
    verify(all(m.get("standalone_ga") is False for m in module_rows),
           item_name + " does not assert universal standalone GA")
verify(saas.get("module_count") == 13, "SaaS catalogue count is exactly 13")
verify(saas.get("canonical_manifest", {}).get("snapshot_sha256") == hashlib.sha256(product_bytes).hexdigest(),
       "Public catalogue is bound to exact product snapshot bytes")
verify(saas.get("independent_ga_claim") is False and saas.get("marketplace_listing_claim") is False,
       "Public catalogue retains fail-closed commercial claim boundary")

if "--network" in sys.argv:
    for url in [LIVE, MISSION + "?mode=business", MISSION + "?mode=politics"]:
        try:
            req = urllib.request.Request(url, headers={"User-Agent":"Fractal5DemoAcceptance/1.0"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                body = resp.read(500000).decode("utf-8", "replace")
                marker_ok = ("SYNTHETIC DATA" in body and "DOMINION OS" in body) if url.startswith(MISSION) else ("dominion" in body.lower() and "demo" in body.lower())
                verify(resp.status == 200 and len(body) > 1000 and marker_ok, "Public content and HTTP page: " + url)
        except Exception as ex:
            verify(False, "Public HTTP page: " + url + " (" + type(ex).__name__ + ")")
else:
    print("INFO: run with --network for public endpoint checks; browser E2E and product-runtime certification are separate.")

print("RESULT:", "FAIL" if errors else "PASS (limited static gates)")
sys.exit(1 if errors else 0)
