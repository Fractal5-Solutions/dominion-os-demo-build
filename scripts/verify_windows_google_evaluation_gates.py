#!/usr/bin/env python3
"""Read-only gate for the Windows + Google commercial evaluation public claim contract."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PATH = ROOT / "demo/assets/windows-google-evaluation-readiness.v1.json"

def validate(data):
    assert data["schema"] == "f5.dominion.windows-google-evaluation-readiness.v1"
    assert data["releasePolicy"] == "FAIL_CLOSED"
    assert data["scope"]["platforms"] == ["windows-x64", "google-cloud-workspace"]
    assert data["scope"]["domains"] == ["business", "politics-neutral"]
    assert isinstance(data["sharedGates"], dict)
    for platform, certified, url, local_gates in [
        ("windows", "publicDownloadCertified", "downloadUrl", [
            "authenticodeVerified", "installerCleanMachineTested",
            "defenderAndSbomPassed", "uninstallAndRecoveryPassed"]),
        ("google", "publicLoginCertified", "loginUrl", [
            "gcpProviderIdentityVerified", "workspaceOAuthScopesVerified",
            "mfaAndIsolationTested", "perTenantQuotaAndBudgetTested",
            "consentScanningAndDeletionTested", "authenticatedE2ECertified"]),
    ]:
        item = data[platform]
        active = item[certified] is True
        if active:
            # A public source registry cannot independently attest a private signed
            # Windows package or an authenticated GCP tenant. Never let changing
            # self-asserted booleans mint a distribution certificate.
            raise AssertionError(
                f"{platform}: public activation requires independent immutable "
                "release-certificate verification outside this source-only gate"
            )
        else:
            assert item[url] is None, f"{platform}: URL must remain absent while blocked"
            assert item["status"] == "BLOCKED"
            assert not data["publicClaims"][("windowsCommercialEvaluationAvailable" if platform == "windows" else "googleCommercialEvaluationAvailable")]
    assert not data["google"]["customerDataUploadsEnabled"] or data["google"]["publicLoginCertified"], "uploads must fail closed"
    assert data["windows"]["portableSyntheticHtmlIsNotInstaller"] is True
    assert data["publicClaims"]["allThirteenSaaSModulesProductionCertified"] is False, "module-specific evidence required"

if __name__ == "__main__":
    validate(json.loads(PATH.read_text(encoding="utf-8")))
    print("PASS: Windows/Google public claims fail closed")
