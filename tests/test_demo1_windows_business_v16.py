import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "squarespace" / "demo-1-final.html"
CATALOG = ROOT / "demo" / "assets" / "dominion-release-catalog.json"
PACKAGE = ROOT / "demo" / "assets" / "demo-download-package.json"
CONTRACT = ROOT / "demo" / "assets" / "customer-owned-experience-contract.json"


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_v19_is_four_provider_windows_business_and_preserves_public_politics():
    text = PAGE.read_text(encoding="utf-8")
    assert 'data-page-build="demo-1-v1.9-20260927-hardened-four-provider-gates"' in text
    assert "Operate the mission." in text
    assert 'id="d1-download"' in text
    assert "WINDOWS BUSINESS · FOUR-PROVIDER RELEASE TARGET" in text
    assert "One Dominion payload. Four governed provider packages." in text
    assert "Windows Release Paths" in text
    assert "GCP · AWS · Azure · OCI" in text
    assert "Politics remains public-demonstration-only" in text
    assert "mode=politics" in text
    assert "dominion-os-business-1080p.mp4" in text
    assert "dominion-os-politics-1080p.mp4" in text
    assert "no downloadable Politics artifact is authorized" in text
    assert "MISSION 01 · DOWNLOADABLE EXPERIENCE" not in text
    assert "Dominion OS 1.0 for Business. Windows first." not in text


def test_download_gate_is_fail_closed_and_business_only():
    package = load_json(PACKAGE)
    controls = package["claimControl"]
    assert controls["binaryDownloadEnabled"] is False
    assert controls["businessDownloadAllowedWhenCertified"] is True
    assert controls["politicsDownloadAllowed"] is False
    assert package["windowsExperience"]["missionPack"] == "Business"
    assert package["windowsExperience"]["publicDownloadCertified"] is False
    assert package["politicsExperience"]["publicDemoAllowed"] is True
    assert package["politicsExperience"]["downloadable"] is False
    assert package["platformRoadmap"]["current"] == "Windows x64 Business"
    assert package["providerFanout"]["packagingMechanics"] == "PASS"
    assert package["providerFanout"]["publicDownloadCertified"] is False


def test_four_provider_release_targets_stay_fail_closed():
    package = load_json(PACKAGE)
    providers = package["providerDownloads"]
    assert {p["id"] for p in providers} == {"gcp", "aws", "azure", "oci"}
    for provider in providers:
        assert provider["missionPack"] == "Business"
        assert provider["politicsIncluded"] is False
        assert provider["publicDownloadCertified"] is False
        assert provider["publicDownloadUrl"] is None

    catalog = load_json(CATALOG)
    entries = [e for e in catalog["entries"] if e.get("providerDownloadFamily") is True]
    assert {e["providerId"] for e in entries} == {"gcp", "aws", "azure", "oci"}
    for entry in entries:
        assert entry["proof"]["providerPackagingMechanics"] == "PASS"
        assert entry["proof"]["publicDownloadCertified"] is False
        assert entry["proof"]["politicsIncluded"] is False


def test_page_download_activation_requires_exact_dual_evidence():
    text = PAGE.read_text(encoding="utf-8")
    assert "commonCertified&&packageCertified&&catalogCertified&&hrefMatches&&checksumMatches" in text
    assert "claimControl.binaryDownloadEnabled===true" in text
    assert "claimControl.politicsDownloadAllowed===false" in text
    assert "packageEntry.publicDownloadCertified===true" in text
    assert "catalogEntry.proof.publicDownloadCertified===true" in text
    assert "common.lifecycleAcceptance===\"PASS\"" in text
    assert "common.defenderScan===\"PASS\"" in text
    assert "data-download-certified" in text


def test_politics_is_demo_only_and_macos_is_later():
    catalog = load_json(CATALOG)
    politics = [e for e in catalog["entries"] if e.get("domain") == "Politics"]
    assert len(politics) == 1
    assert politics[0]["proof"]["publicDemonstrationAllowed"] is True
    assert politics[0]["proof"]["downloadAllowed"] is False

    contract = load_json(CONTRACT)
    assert contract["missionPackPolicy"]["downloadableNow"] == ["Business"]
    assert contract["missionPackPolicy"]["publiclyDemonstratedButNotDownloadable"] == ["Politics"]
    assert contract["platformPolicy"]["currentMission"].startswith("Windows x64 Business")
    assert contract["platformPolicy"]["nextMission"].startswith("macOS Business")
    assert contract["platformPolicy"]["nextMissionState"] == "later"
