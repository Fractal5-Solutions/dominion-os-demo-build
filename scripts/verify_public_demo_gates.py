#!/usr/bin/env python3
"""Fail-closed public demo gate check. Standard library; no credentials or mutations."""
import json
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
        verify(bool(provider.get("publicDownloadUrl")), provider["id"] + " certified URL exists")
        verify(data["windowsExperience"]["authenticode"] == "VERIFIED", provider["id"] + " publisher signing")
    else:
        verify(not provider.get("publicDownloadUrl"), provider["id"] + " uncertified URL withheld")

if "--network" in sys.argv:
    for url in [LIVE, MISSION + "?mode=business", MISSION + "?mode=politics"]:
        try:
            req = urllib.request.Request(url, headers={"User-Agent":"Fractal5DemoAcceptance/1.0"})
            with urllib.request.urlopen(req, timeout=15) as resp:
                body = resp.read(500000).decode("utf-8", "replace")
                verify(resp.status == 200 and len(body) > 1000, "Public HTTP page: " + url)
        except Exception as ex:
            verify(False, "Public HTTP page: " + url + " (" + type(ex).__name__ + ")")
else:
    print("INFO: run with --network for public endpoint checks; browser E2E and product-runtime certification are separate.")

print("RESULT:", "FAIL" if errors else "PASS (limited static gates)")
sys.exit(1 if errors else 0)
