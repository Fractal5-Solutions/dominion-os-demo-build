import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
PAGE = ROOT / "squarespace" / "demo-1-final.html"
CATALOG = ROOT / "demo" / "assets" / "dominion-release-catalog.json"
PACKAGE = ROOT / "demo" / "assets" / "demo-download-package.json"
CONTRACT = ROOT / "demo" / "assets" / "customer-owned-experience-contract.json"


def load_json(path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_v16_is_windows_business_first_and_preserves_public_politics():
    text = PAGE.read_text(encoding="utf-8")
    assert 'data-page-build="demo-1-v1.7-20260926-business-media"' in text
    assert "Operate the mission." in text
    assert 'id="d1-download"' in text
    assert "Dominion OS 1.0 for Business. Windows first." in text
    assert "Politics remains fully demonstrable here" in text
    assert "DOMINION OS FOR POLITICS" not in text
    assert "Download Dominion OS 1.0 for Business" in text
    assert "mode=politics" in text
    assert "dominion-os-business-1080p.mp4" in text
    assert "dominion-os-politics-1080p.mp4" in text
    assert "no downloadable Politics artifact is authorized" in text


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
    assert package["platformRoadmap"]["next"] == "macOS Business"
    assert package["platformRoadmap"]["nextState"] == "not-currently-implemented"


def test_release_catalog_binds_exact_business_candidate():
    catalog = load_json(CATALOG)
    windows = [e for e in catalog["entries"] if e.get("deploymentTarget") == "Windows x64"]
    assert len(windows) == 1
    win = windows[0]
    assert win["domain"] == "Business"
    assert win["build"] == "a3d51eb4876b801c726d3b776ddb6f8e265c4001"
    assert win["checksum"] == "sha256:70311d6dfea3800fbe31be9b69e587757c0b83e40d8eace50e2c55f70b887ff6"
    assert win["proof"]["mergedMainSha"] == "a177ea79c2a09f24dc29da075fd2b71bd1b259b2"
    assert win["proof"]["executableSha256"] == "ac3e59c76bd0819fe5e42be79bfab0ade3fd5f0137982685d0ecda4f35839d23"
    assert win["proof"]["politicsIncluded"] is False
    assert win["proof"]["lifecycleAcceptance"] == "PASS"
    assert win["proof"]["defenderScan"] == "PASS"
    assert win["proof"]["publicDownloadCertified"] is False


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


def test_page_only_enables_download_when_all_independent_gates_agree():
    text = PAGE.read_text(encoding="utf-8")
    assert "controls.binaryDownloadEnabled===true" in text
    assert "controls.businessDownloadAllowedWhenCertified===true" in text
    assert "controls.politicsDownloadAllowed===false" in text
    assert "win.proof.publicDownloadCertified===true" in text
    assert "Public Download Certification Pending" in text
    assert "customer-owned-experience-contract.json" in text
