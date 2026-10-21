#!/usr/bin/env python3
"""Build a fail-closed Squarespace review candidate; never publish or deploy."""
from __future__ import annotations

import argparse
import hashlib
from html.parser import HTMLParser
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CANON = ROOT / "squarespace/demo-1-v1.9-ecosystem-truth.html"
EXT = ROOT / "squarespace/demo-ecosystem-extension-20261021.review.html"
CANON_BLOB = "031d69009d424b91c73ccd868d35d6cd3491f303"
EXT_BLOB = "2a2b28f1f779ce1832204a86aeea13d571b6e521"
OLD_BUILD = "demo-1-v1.9-20260927-hardened-four-provider-gates"
NEW_BUILD = "demo-1-v2.0-20261021-ecosystem-evidence-candidate"

def git_blob(data: bytes) -> str:
    return hashlib.sha1(b"blob " + str(len(data)).encode() + b"\0" + data).hexdigest()

def exactly_one_replace(data: str, old: str, new: str) -> str:
    count = data.count(old)
    if count != 1:
        raise ValueError(f"Expected exactly one occurrence, got {count}: {old[:80]!r}")
    return data.replace(old, new, 1)

class AuditIds(HTMLParser):
    def __init__(self):
        super().__init__()
        self.ids = []
        self.references = []
    def handle_starttag(self, tag, attrs):
        m = dict(attrs)
        if "id" in m:
            self.ids.append(m["id"])
        if tag == "a" and m.get("href", "").startswith("#"):
            self.references.append(m["href"][1:])

def build() -> str:
    raw = CANON.read_bytes()
    extra_raw = EXT.read_bytes()
    if git_blob(raw) != CANON_BLOB:
        raise ValueError("Immutable v1.9 source blob differs; independent review required")
    if git_blob(extra_raw) != EXT_BLOB:
        raise ValueError("Catalogue fragment blob differs; independent review required")
    original = raw.decode("utf-8")
    addition = extra_raw.decode("utf-8")
    if "<script" in addition.lower() or "onload=" in addition.lower():
        raise ValueError("Catalogue must be static and nonexecuting")
    src = exactly_one_replace(original, OLD_BUILD, NEW_BUILD)
    src = exactly_one_replace(src, "one certified Dominion OS 1.0 + SaaS Suite Windows Business payload", "one governed Windows Business candidate payload")
    src = exactly_one_replace(src, '<span class="d1-badge positive">Live</span>', '<span class="d1-badge neutral">Public Entry</span>')
    src = exactly_one_replace(src, '<a class="d1-btn" href="#d1-releases">Releases &amp; Evidence</a>', '<a class="d1-btn" href="#dominion-ecosystem-extension">Explore Ecosystem</a><a class="d1-btn" href="#d1-releases">Releases &amp; Evidence</a>')
    marker = '  <section class="d1-section" id="d1-releases">'
    src = exactly_one_replace(src, marker, "  " + addition + "\n" + marker)
    required = ["13 SaaS Modules", "13 Intelligence Cube Families", "Six Agentic Professional Domains",
                "Dominion Deployment Families", "65-record historical commercial catalogue",
                "Windows x64", "macOS", "Linux", "Google Cloud", "AWS", "Azure", "OCI",
                "Commercial Runtime", "Politics"]
    for word in required:
        if word == "Commercial Runtime":
            if word in src or "Governed release complete" in src:
                raise ValueError("Unsupported production claim detected")
        elif word not in src:
            raise ValueError(f"Expected ecosystem term is missing: {word}")
    if src.count(NEW_BUILD) != 1:
        raise ValueError("Invalid build marker")
    if src.count("data-claim-mode=\"fail-closed\"") != 1:
        raise ValueError("Missing static fail-closed catalogue boundary")
    audit = AuditIds()
    audit.feed(src)
    collisions = sorted({i for i in audit.ids if audit.ids.count(i) > 1})
    if collisions:
        raise ValueError(f"Duplicate HTML ids: {collisions[:20]}")
    invalid_refs = sorted(set(audit.references) - set(audit.ids))
    if invalid_refs:
        raise ValueError(f"Broken fragment anchors: {invalid_refs[:20]}")
    if len(src) <= len(original) + 7000:
        raise ValueError("Expanded catalogue not fully included")
    return src

def main() -> None:
    parser = argparse.ArgumentParser()
    parser.add_argument("--output", type=Path, required=True)
    args = parser.parse_args()
    candidate = build()
    args.output.parent.mkdir(parents=True, exist_ok=True)
    args.output.write_bytes(candidate.encode("utf-8"))
    print("CANDIDATE_SOURCE_VALIDATED=true")
    print("SQUARESPACE_PUBLISHED=false")
    print("PUBLIC_DOWNLOAD_CERTIFIED=false")
    print("PUBLIC_RUNTIME_CERTIFIED=false")
    print("bytes=" + str(len(candidate.encode("utf-8"))))
    print("sha256=" + hashlib.sha256(candidate.encode("utf-8")).hexdigest())

if __name__ == "__main__":
    main()
