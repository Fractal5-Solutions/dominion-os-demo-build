"""Build an allowlisted synthetic preview from an immutable public Git blob.

This does not build, sign, certify, or publish the Dominion product or SaaS.
Generated artifacts must stay outside the source repository.
"""
from __future__ import annotations

import argparse
import hashlib
import io
import json
from html.parser import HTMLParser
from pathlib import Path, PurePosixPath
import re
import stat
import subprocess
import zipfile

SOURCE_COMMIT = "c2e066cfc1c95cba129bbadcd864833a05e86d99"
SOURCE_PATH = "demo/live-mission-demo.html"
RAW_HTML_SHA256 = "6e8ca733f3dbd3798064b47309c1cfd56b29957c5f27d39593d9d1a9295eedb2"
PACKAGE_NAME = "Dominion-OS-Business-Politics-Offline-Preview.zip"
ALLOWLIST = ("DEMO-TERMS.txt", "README.txt", "demo-manifest.json", "index.html")
CSP = (
    "default-src 'none'; script-src 'unsafe-inline'; style-src 'unsafe-inline'; "
    "connect-src 'none'; img-src 'none'; font-src 'none'; media-src 'none'; "
    "frame-src 'none'; object-src 'none'; worker-src 'none'; base-uri 'none'; form-action 'none'"
)
README = """DOMINION OS BUSINESS + POLITICS — OFFLINE PREVIEW

Free synthetic preview for evaluation. Extract this ZIP, then open index.html
in a current browser. Select Business or Politics. The preview starts only
when you open it and advance the mission. No installation, administrator
permission, account, API key, cloud access, or internet connection is needed.

All scenarios, approvals, workstreams, and receipts are simulated. They grant
no real authority and perform no external work. Do not enter real customer,
campaign, personal, voter, confidential, or production data.

This archive contains a public presentation preview, not the licensed native
product, production SaaS, cloud runtime, connector implementation, or deployment
tool. It does not certify a Google deployment or completion of those products.
No telemetry, persistent browser storage, installer, startup registration,
scheduled task, executable, or background service is included. Delete the
extracted directory to remove the preview.

index.html contains the public preview HTML, CSS, and JavaScript. It is derived
from the source identity in demo-manifest.json with explicit offline changes.
The original input hash and generated HTML hash differ by design. The ZIP's
detached .sha256 file is supplied separately. See DEMO-TERMS.txt for preview use.
"""
TERMS = """DOMINION OS — FREE SYNTHETIC PREVIEW TERMS

Copyright Fractal5 Solutions. All rights reserved except the preview permission
below. Prepared under the owner's request for free safe downloadable Business
and Politics demonstrations.

Permission is granted to download and run this unchanged public synthetic
preview locally, without charge, for preview and evaluation purposes. Keep
this notice with any unchanged copy shared for those same purposes.

This permission covers only the public presentation files in this archive.
It grants no license to the licensed native product, production SaaS, private
source, connectors, infrastructure, trademarks, production data, or operational
authority. All such production rights remain reserved. Do not represent this
preview as a live deployment, production product, or certified operating system.

The preview is provided as is for demonstration. No support, production fitness,
security certification, or service availability is promised by these terms.
"""


def digest(data: bytes) -> str:
    return hashlib.sha256(data).hexdigest()


def json_bytes(value: dict) -> bytes:
    return (json.dumps(value, indent=2, ensure_ascii=False, sort_keys=True) + "\n").encode("utf-8")


class PreviewBoundary(HTMLParser):
    def handle_starttag(self, tag, attrs):
        if tag in {"iframe", "frame", "object", "embed", "form", "input", "textarea", "select", "link", "base", "img", "video", "audio"}:
            raise ValueError(f"Disallowed preview element: {tag}")
        for name, value in attrs:
            if name.lower() in {"src", "href", "action", "formaction", "srcset", "poster"}:
                raise ValueError(f"Disallowed external-resource/navigation attribute: {name}")
            if name.lower() == "http-equiv" and (value or "").lower() == "refresh":
                raise ValueError("Automatic navigation is prohibited.")


def validate_html(raw: bytes) -> None:
    text = raw.decode("utf-8", errors="strict")
    PreviewBoundary().feed(text)
    forbidden = [
        r"\b(?:fetch|XMLHttpRequest|WebSocket|EventSource|sendBeacon|importScripts|Worker)\s*\(",
        r"\b(?:localStorage|sessionStorage|indexedDB|serviceWorker)\b",
        r"\bimport\s*(?:\(|[\"'])",
        r"-----BEGIN (?:[A-Z ]+ )?PRIVATE KEY-----",
        r"\b(?:ghp_[A-Za-z0-9]{20,}|AIza[A-Za-z0-9_-]{30,}|sk-proj-[A-Za-z0-9_-]{20,})\b",
        r"(?i)(?:D:[/\\]phi-ops|/mnt/d/phi-ops|\.git[/\\]|\.env\b)",
    ]
    if any(re.search(pattern, text) for pattern in forbidden):
        raise ValueError("Preview includes prohibited network, storage, private-input, or credential content.")
    for required in ("Synthetic scenarios only", "No customer data", 'data-mode="business"', 'data-mode="politics"', "No real authority or external action"):
        if required not in text:
            raise ValueError(f"Required public boundary missing: {required}")


def read_source(repo_root: Path) -> bytes:
    raw = subprocess.check_output(
        ["git", "cat-file", "blob", f"{SOURCE_COMMIT}:{SOURCE_PATH}"], cwd=repo_root
    )
    if digest(raw) != RAW_HTML_SHA256:
        raise ValueError("Immutable public input does not match its pinned raw HTML digest.")
    validate_html(raw)
    return raw


def make_offline_html(raw: bytes) -> bytes:
    if digest(raw) != RAW_HTML_SHA256:
        raise ValueError("Offline generation accepts only the pinned immutable public HTML.")
    validate_html(raw)
    text = raw.decode("utf-8")
    replacements = {
        "<head>": f'<head>\n<meta http-equiv="Content-Security-Policy" content="{CSP}">',
        "<title>Dominion OS 1.0 Live Mission Demo</title>": "<title>Dominion OS Business + Politics Offline Preview</title>",
        "DOMINION OS™ 1.0 · LIVE MISSION DEMO": "DOMINION OS™ · OFFLINE PREVIEW",
        "SYNTHETIC DATA · FILMING BUILD": "SYNTHETIC DATA · OFFLINE PREVIEW",
        "<strong>Demonstration boundary.</strong>": "<strong>Free offline synthetic preview for evaluation.</strong> This public presentation does not include the licensed production runtime or SaaS services.",
        'const autoplay=params.get("autoplay")==="1";': "const autoplay=false; // Offline preview never starts automatic progression.",
    }
    for old, new in replacements.items():
        if text.count(old) != 1:
            raise ValueError(f"Expected exactly one immutable transformation target: {old}")
        text = text.replace(old, new, 1)
    generated = text.encode("utf-8")
    validate_html(generated)
    return generated


def make_payloads(raw: bytes) -> dict[str, bytes]:
    offline = make_offline_html(raw)
    payloads = {"index.html": offline, "README.txt": README.encode("utf-8"), "DEMO-TERMS.txt": TERMS.encode("utf-8")}
    manifest = {
        "schema": "dominion.offline-preview.payload.v1",
        "title": "Dominion OS Business + Politics Offline Preview",
        "artifactClass": "synthetic-static-web-preview",
        "source": {"repository": "Fractal5-Solutions/dominion-os-demo-build", "commit": SOURCE_COMMIT, "path": SOURCE_PATH, "inputRawHtmlSha256": digest(raw)},
        "generatedOfflineHtmlSha256": digest(offline),
        "transformations": ["restrictive-offline-CSP", "preview-title-and-boundary-labels", "disable-automatic-progression"],
        "expectedEntries": list(ALLOWLIST),
        "files": {name: {"sha256": digest(data), "bytes": len(data)} for name, data in sorted(payloads.items())},
        "manifestIntegrity": "Manifest and ZIP digests are recorded in the detached build receipt; no self-digest is claimed.",
        "missions": ["Business", "Politics"],
        "syntheticOnly": True,
        "realAuthority": False,
        "externalRequests": False,
        "installationOrAutostart": False,
        "productionRuntimeIncluded": False,
        "saasIncluded": False,
        "googleDeploymentCertified": False,
        "publicUrl": None,
        "publicationState": "PENDING_GOOGLE_CERTIFICATION",
    }
    payloads["demo-manifest.json"] = json_bytes(manifest)
    return payloads


def validate_name(name: str) -> None:
    path = PurePosixPath(name)
    if name not in ALLOWLIST or path.is_absolute() or ".." in path.parts or "\\" in name or ":" in name:
        raise ValueError(f"Archive entry is outside the exact preview allowlist: {name}")


def make_zip(payloads: dict[str, bytes]) -> bytes:
    if set(payloads) != set(ALLOWLIST):
        raise ValueError("Preview payload does not match the closed four-file allowlist.")
    buffer = io.BytesIO()
    with zipfile.ZipFile(buffer, "w", compression=zipfile.ZIP_STORED) as archive:
        for name in sorted(payloads):
            validate_name(name)
            info = zipfile.ZipInfo(name, date_time=(1980, 1, 1, 0, 0, 0))
            info.create_system = 3
            info.external_attr = (stat.S_IFREG | 0o644) << 16
            archive.writestr(info, payloads[name])
    return buffer.getvalue()


def validate_archive(data: bytes, expected: dict[str, bytes]) -> dict:
    with zipfile.ZipFile(io.BytesIO(data)) as archive:
        infos = archive.infolist()
        names = [info.filename for info in infos]
        if len(names) != len(set(names)) or set(names) != set(ALLOWLIST):
            raise ValueError("Archive has missing, duplicate, or unapproved entries.")
        for info in infos:
            validate_name(info.filename)
            mode = info.external_attr >> 16
            if not stat.S_ISREG(mode) or mode & 0o111 or info.flag_bits & 1:
                raise ValueError("Archive must contain ordinary nonexecutable unencrypted files only.")
            if info.file_size != len(expected[info.filename]):
                raise ValueError("Archive entry length differs from the bounded preview payload.")
            if archive.read(info) != expected[info.filename]:
                raise ValueError(f"Archive bytes differ from the exact generated preview: {info.filename}")
        manifest = json.loads(archive.read("demo-manifest.json"))
        for name, record in manifest["files"].items():
            content = archive.read(name)
            if digest(content) != record["sha256"] or len(content) != record["bytes"]:
                raise ValueError(f"Manifest mismatch: {name}")
        if manifest["generatedOfflineHtmlSha256"] != digest(archive.read("index.html")):
            raise ValueError("Generated offline HTML identity mismatch.")
        validate_html(archive.read("index.html"))
        return manifest


def build(repo_root: Path, output_dir: Path) -> dict:
    repo_root, output_dir = repo_root.resolve(), output_dir.resolve()
    if output_dir == repo_root or output_dir.is_relative_to(repo_root):
        raise ValueError("Generated ZIPs and receipts must be outside the source repository.")
    raw = read_source(repo_root)
    payloads = make_payloads(raw)
    package = make_zip(payloads)
    manifest = validate_archive(package, payloads)
    receipt = {
        "schema": "dominion.offline-preview.build-receipt.v1",
        "validation": "PASS",
        "source": manifest["source"],
        "generatedOfflineHtmlSha256": manifest["generatedOfflineHtmlSha256"],
        "packageName": PACKAGE_NAME,
        "packageSha256": digest(package),
        "packageBytes": len(package),
        "entries": {name: {"sha256": digest(data), "bytes": len(data)} for name, data in sorted(payloads.items())},
        "publicUrl": None,
        "publicationState": manifest["publicationState"],
        "signatureClaimed": False,
        "malwareScan": "NOT_PERFORMED_BY_PACKAGER",
        "googleDeploymentCertified": False,
        "nativeProductOrSaasCertification": False,
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / PACKAGE_NAME).write_bytes(package)
    (output_dir / f"{PACKAGE_NAME}.sha256").write_text(f"{digest(package)}  {PACKAGE_NAME}\n", encoding="utf-8", newline="\n")
    (output_dir / "offline-preview-build-receipt.json").write_bytes(json_bytes(receipt))
    return receipt


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(build(Path(__file__).resolve().parents[1], args.output_dir), indent=2))
