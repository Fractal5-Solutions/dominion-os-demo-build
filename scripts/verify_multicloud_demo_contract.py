#!/usr/bin/env python3
"""Fail closed when the public multicloud demo and its claim contract drift."""

from __future__ import annotations

import json
from pathlib import Path
from urllib.parse import urlparse

ROOT = Path(__file__).resolve().parents[1]
HTML_PATH = ROOT / "squarespace" / "demo-1-final.html"
MANIFEST_PATH = ROOT / "demo" / "assets" / "multicloud-runtime-manifest.json"

STATIC_DEMO = "https://fractal5-solutions.github.io/dominion-os-demo-build/"
RUNTIME_MANIFEST_PATH = "demo/assets/multicloud-runtime-manifest.json"

REQUIRED_HTML_MARKERS = (
    'data-version="2026-08-02-multicloud-proof-v2"',
    "One governed system. Your cloud.",
    "Open verified public demo",
    "Runtime claims fail closed.",
    RUNTIME_MANIFEST_PATH,
    STATIC_DEMO,
)

FORBIDDEN_HTML_MARKERS = (
    "LIVE GOOGLE CLOUD DEMO",
    "Dominion OS, live on the cloud.",
    "Four continuously live public deployments",
    "Open web MP4",
    "Open master MP4",
)

ALLOWED_PROVIDER_IDS = {"gcp", "azure", "aws", "oci"}


def require(condition: bool, message: str) -> None:
    if not condition:
        raise SystemExit(message)


def validate_https(value: str, label: str) -> None:
    parsed = urlparse(value)
    require(parsed.scheme == "https" and bool(parsed.netloc), f"{label} must be HTTPS")


def main() -> int:
    html = HTML_PATH.read_text(encoding="utf-8")
    manifest = json.loads(MANIFEST_PATH.read_text(encoding="utf-8"))

    for marker in REQUIRED_HTML_MARKERS:
        require(marker in html, f"missing public-demo marker: {marker}")
    for marker in FORBIDDEN_HTML_MARKERS:
        require(marker not in html, f"forbidden stale claim detected: {marker}")

    require(manifest.get("schema") == "f5.dominion.multicloud-runtime.v1", "unexpected schema")

    static_proof = manifest.get("staticProof") or {}
    require(static_proof.get("state") == "verified-public-safe", "static proof must be verified")
    require(static_proof.get("publicClaimAllowed") is True, "static proof claim must be allowed")
    validate_https(str(static_proof.get("url") or ""), "staticProof.url")
    validate_https(str(static_proof.get("receipt") or ""), "staticProof.receipt")

    claim = manifest.get("claimControl") or {}
    require(claim.get("failClosed") is True, "claim control must fail closed")
    require(
        claim.get("continuousPublicRuntimeClaimAllowed") is False,
        "continuous public runtime claims must remain disabled",
    )
    require(claim.get("multiCloudArchitectureClaimAllowed") is True, "multicloud claim must be explicit")
    require(claim.get("directMp4ClaimAllowed") is False, "direct MP4 claim must remain disabled")
    require(claim.get("productionSlaClaimAllowed") is False, "production SLA claim must remain disabled")

    providers = manifest.get("providers") or []
    require(isinstance(providers, list) and len(providers) == 4, "exactly four provider records required")
    ids = {str(provider.get("id") or "") for provider in providers}
    require(ids == ALLOWED_PROVIDER_IDS, f"unexpected provider set: {sorted(ids)}")

    for provider in providers:
        provider_id = str(provider.get("id") or "")
        require(provider.get("publicClaimAllowed") is False, f"{provider_id} live claim must default false")
        if provider_id == "gcp":
            require(provider.get("publicRuntimeState") == "uncertified", "GCP must remain uncertified")
            for key in ("demoUrl", "healthUrl", "statusUrl"):
                validate_https(str(provider.get(key) or ""), f"gcp.{key}")
            certification = provider.get("certification") or {}
            require(
                certification.get("maxReceiptAgeSeconds") == 300,
                "GCP receipt freshness must be five minutes",
            )
            require(certification.get("requiredReleaseBinding") is True, "GCP release binding required")

    safety = manifest.get("safety") or {}
    require(safety.get("publicSafe") is True, "manifest must be public-safe")
    for key in ("containsSecrets", "containsCustomerData", "containsPaymentData"):
        require(safety.get(key) is False, f"safety.{key} must be false")

    print(
        json.dumps(
            {
                "ok": True,
                "html": str(HTML_PATH.relative_to(ROOT)),
                "manifest": str(MANIFEST_PATH.relative_to(ROOT)),
                "providers": sorted(ids),
                "defaultLiveProviderClaims": 0,
                "staticProof": static_proof.get("url"),
            },
            indent=2,
        )
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
