"""Package the pinned synthetic SaaS presentation; no product or Google certification."""
from __future__ import annotations

import argparse
import importlib.util
import json
from pathlib import Path
import re
import subprocess

SPEC = importlib.util.spec_from_file_location("public_preview_archive", Path(__file__).with_name("build_offline_preview.py"))
archive = importlib.util.module_from_spec(SPEC)
SPEC.loader.exec_module(archive)
SOURCE_COMMIT = "5e80d1824be37a124f4d001fcc3a2fb8b3656f56"
SOURCE_PATH = "demo/saas-suite-offline-preview.html"
CATALOGUE_PATH = "demo/assets/dominion-saas-catalog.json"
SOURCE_SHA256 = "ce517d7d7daeabbde58a7b82387c5be26d501023a1f279a033aa2ced71346a37"
CATALOGUE_SHA256 = "1065dfe1f5d76fca34ec3b5968da56ca4b805a9e54432ab44267d14eb60e78a3"
PACKAGE_NAME = "Fractal5-SaaS-Suite-Business-Politics-Offline-Preview.zip"
README = """FRACTAL5 SAAS SUITE - BUSINESS + POLITICS OFFLINE PREVIEW

Free synthetic preview for evaluation. Extract this ZIP, then open index.html
in a current browser. Choose Business or Politics and select one of 13 modules.
Advance through the fixed sample and plan. Explicitly approve the simulation
before issuing its in-memory receipt. Hold pauses progression and approvals
across every module. Reset clears the whole suite; changing mode also clears
all progress, approvals, and receipts. Hold persists until Resume is selected.

The 13 modules are interactive catalogue examples, not the actual standalone
module implementations or production SaaS. Catalogue states are retained,
including Coming Soon. Google deployment and product completion are not claimed.
Politics examples cover neutral civic administration only; no personal records,
voter profiling, campaign targeting, political-position inference, or persuasion
is present. The sample accepts no free-text input or real customer data.

No installation, administrator permission, account, API key, cloud connection,
internet connection, external action, telemetry, persistent storage, executable,
scheduled task, background timer, or service is included. No document, notice,
message, deployment, database, or approval is acted on outside this page.
Close the page to clear its memory. Delete the extracted directory to remove it.

The archive contains public HTML/CSS/JavaScript presentation files only, not
private source or the licensed native product. See DEMO-TERMS.txt for permission.
demo-manifest.json binds the immutable source HTML and catalogue commit/hash.
A detached checksum and build receipt are supplied outside the archive.
"""
TERMS = archive.TERMS.replace("DOMINION OS - FREE SYNTHETIC PREVIEW TERMS", "FRACTAL5 SAAS SUITE - FREE SYNTHETIC PREVIEW TERMS")


def read_source(repo_root: Path) -> tuple[bytes, bytes]:
    data = []
    for path, expected in ((SOURCE_PATH, SOURCE_SHA256), (CATALOGUE_PATH, CATALOGUE_SHA256)):
        raw = subprocess.check_output(["git", "cat-file", "blob", f"{SOURCE_COMMIT}:{path}"], cwd=repo_root)
        if archive.digest(raw) != expected:
            raise ValueError(f"Pinned public source hash mismatch: {path}")
        data.append(raw)
    validate_source(*data)
    return tuple(data)


def validate_source(raw: bytes, catalogue_raw: bytes) -> dict:
    if archive.digest(raw) != SOURCE_SHA256 or archive.digest(catalogue_raw) != CATALOGUE_SHA256:
        raise ValueError("Only the exact pinned presentation and catalogue are accepted.")
    archive.validate_html(raw)
    text = raw.decode("utf-8")
    if text.count(f'content="{archive.CSP}"') != 1:
        raise ValueError("The restrictive offline CSP is required exactly once.")
    if re.search(r"\b(?:setTimeout|setInterval|requestAnimationFrame|eval|Function)\s*\(|\b(?:navigator|location|cookie|openDatabase|BroadcastChannel|RTCPeerConnection)\b", text):
        raise ValueError("Timers, dynamic code, browser I/O, or navigation are prohibited.")
    matches = re.findall(r'<script id="preview-data" type="application/json">(.*?)</script>', text, re.S)
    if len(matches) != 1:
        raise ValueError("One bounded sample dataset is required.")
    data, catalogue = json.loads(matches[0]), json.loads(catalogue_raw)
    if len(data["modules"]) != 13 or catalogue["module_count"] != 13:
        raise ValueError("The preview must cover all 13 catalogue modules.")
    keys = ("id", "name", "store_state", "implementation_state", "standalone_ga")
    for sample, canonical in zip(data["modules"], catalogue["modules"]):
        if {key: sample[key] for key in keys} != {key: canonical[key] for key in keys}:
            raise ValueError("Preview module identity or availability differs from the catalogue.")
        if sample["standalone_ga"] is not False or set(sample["examples"]) != {"business", "politics"}:
            raise ValueError("Both synthetic modes and the GA boundary are required.")
        if any(set(example) != {"title", "input", "plan"} or not all(isinstance(value, str) and value for value in example.values()) for example in sample["examples"].values()):
            raise ValueError("Each module requires complete, fixed public samples.")
    return data


def make_payloads(raw: bytes, catalogue_raw: bytes) -> dict[str, bytes]:
    data = validate_source(raw, catalogue_raw)
    payloads = {"index.html": raw, "README.txt": README.encode(), "DEMO-TERMS.txt": TERMS.encode()}
    manifest = {
        "schema": "dominion.synthetic-saas-offline-preview.payload.v1",
        "title": "Fractal5 SaaS Suite Business + Politics Offline Preview",
        "artifactClass": "synthetic-static-saas-catalogue-preview",
        "source": {"repository": "Fractal5-Solutions/dominion-os-demo-build", "commit": SOURCE_COMMIT, "path": SOURCE_PATH, "inputRawHtmlSha256": SOURCE_SHA256, "cataloguePath": CATALOGUE_PATH, "catalogueSha256": CATALOGUE_SHA256},
        "generatedOfflineHtmlSha256": archive.digest(raw),
        "transformations": [],
        "expectedEntries": list(archive.ALLOWLIST),
        "files": {name: {"sha256": archive.digest(content), "bytes": len(content)} for name, content in sorted(payloads.items())},
        "manifestIntegrity": "The detached build receipt hashes the manifest and ZIP; no self-digest is claimed.",
        "modules": [{key: module[key] for key in ("id", "name", "store_state", "implementation_state", "standalone_ga")} for module in data["modules"]],
        "moduleCount": 13, "missions": ["Business", "Politics"],
        "syntheticOnly": True, "realAuthority": False, "externalRequests": False,
        "persistentStorage": False, "installationOrAutostart": False,
        "productionRuntimeIncluded": False, "actualSaasImplementationsIncluded": False,
        "independentGeneralAvailabilityClaim": False, "googleDeploymentCertified": False,
        "publicUrl": None, "publicationState": "PENDING_GOOGLE_CERTIFICATION",
    }
    payloads["demo-manifest.json"] = archive.json_bytes(manifest)
    return payloads


def build(repo_root: Path, output_dir: Path) -> dict:
    repo_root, output_dir = repo_root.resolve(), output_dir.resolve()
    if output_dir == repo_root or output_dir.is_relative_to(repo_root):
        raise ValueError("Generated packages and receipts must remain outside the source repository.")
    payloads = make_payloads(*read_source(repo_root))
    package = archive.make_zip(payloads)
    manifest = archive.validate_archive(package, payloads)
    packager_path = "scripts/build_saas_offline_preview.py"
    packager_head = subprocess.check_output(["git", "rev-parse", "HEAD"], cwd=repo_root, text=True).strip()
    packager_files = {}
    for path in (packager_path, "scripts/build_offline_preview.py"):
        actual = (repo_root / path).read_bytes()
        tracked = subprocess.run(["git", "cat-file", "blob", f"{packager_head}:{path}"], cwd=repo_root, capture_output=True)
        packager_files[path] = {"sha256": archive.digest(actual), "headBlobMatches": tracked.returncode == 0 and tracked.stdout == actual}
    receipt = {
        "schema": "dominion.synthetic-saas-offline-preview.build-receipt.v1", "validation": "PASS",
        "source": manifest["source"], "generatedOfflineHtmlSha256": archive.digest(payloads["index.html"]),
        "packager": {"head": packager_head, "files": packager_files, "headBlobMatches": all(record["headBlobMatches"] for record in packager_files.values())},
        "packageName": PACKAGE_NAME, "packageSha256": archive.digest(package), "packageBytes": len(package),
        "entries": {name: {"sha256": archive.digest(content), "bytes": len(content)} for name, content in sorted(payloads.items())},
        "publicUrl": None, "publicationState": "PENDING_GOOGLE_CERTIFICATION",
        "signatureClaimed": False, "malwareScan": "NOT_PERFORMED_BY_PACKAGER",
        "browserFileAcceptance": "NOT_PERFORMED_BY_PACKAGER",
        "googleDeploymentCertified": False, "nativeProductOrSaasCertification": False,
    }
    output_dir.mkdir(parents=True, exist_ok=True)
    (output_dir / PACKAGE_NAME).write_bytes(package)
    (output_dir / f"{PACKAGE_NAME}.sha256").write_text(f"{archive.digest(package)}  {PACKAGE_NAME}\n", encoding="utf-8", newline="\n")
    (output_dir / "saas-offline-preview-build-receipt.json").write_bytes(archive.json_bytes(receipt))
    return receipt


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output-dir", required=True, type=Path)
    args = parser.parse_args()
    print(json.dumps(build(Path(__file__).resolve().parents[1], args.output_dir), indent=2))
