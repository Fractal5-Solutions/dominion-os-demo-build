import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "demo" / "media"
MANIFEST = ROOT / "demo" / "assets" / "live-mission-video-manifest.json"
PACKAGE = ROOT / "demo" / "assets" / "demo-download-package.json"
GATE = ROOT / "demo" / "assets" / "dominion-business-1.0-release-gate.json"


def sha256(path: Path) -> str:
    return hashlib.sha256(path.read_bytes()).hexdigest()


def load_json(path: Path):
    return json.loads(path.read_text(encoding="utf-8-sig"))


def test_media_manifest_binds_durable_bytes():
    manifest = load_json(MANIFEST)
    assert manifest["schema_version"] == 4
    assert manifest["publication"]["state"] in {"publishing", "available"}
    assert manifest["sources"]["business_windows_candidate"]["source_sha"] == "90de700bb9c44ab62212731dbaa13c0bea3b3ffd"
    assert manifest["sources"]["public_demo"]["html_sha256"] == "5789702b1fabcb20b48bcdf81bef7e32ff723f9b135199ad82588d5edbda831d"

    videos = {video["id"]: video for video in manifest["videos"]}
    assert set(videos) == {"business", "politics"}

    for video in videos.values():
        assert video["state"] in {"publishing", "available"}
        for basename_key, hash_key in (
            ("basename", "sha256"),
            ("poster_basename", "poster_sha256"),
            ("captions_basename", "captions_sha256"),
        ):
            asset = MEDIA / video[basename_key]
            assert asset.is_file(), asset
            assert sha256(asset) == video[hash_key]
        assert video["mp4_url"].startswith(
            "https://fractal5-solutions.github.io/dominion-os-demo-build/demo/media/"
        )


def test_business_and_politics_release_authority_remain_separate():
    manifest = load_json(MANIFEST)
    videos = {video["id"]: video for video in manifest["videos"]}
    business = videos["business"]
    politics = videos["politics"]

    assert "Windows Business Candidate A" in business["source_authority"]
    assert "does not certify unsigned Windows public download" in business["distribution_boundary"]
    assert politics["source_authority"] == "Public synthetic demonstration only"
    assert "no downloadable Politics artifact authorized" in politics["distribution_boundary"]

    package = load_json(PACKAGE)
    assert package["windowsExperience"]["missionPack"] == "Business"
    assert package["windowsExperience"]["publicDownloadCertified"] is False
    assert package["politicsExperience"]["downloadable"] is False
    assert package["claimControl"]["politicsDownloadAllowed"] is False


def test_human_readable_release_record_is_fail_closed():
    release = (ROOT / "release" / "business-windows-1.0.html").read_text(encoding="utf-8")
    assert "CANDIDATE" in release
    assert "90de700bb9c44ab62212731dbaa13c0bea3b3ffd" in release
    assert "ccbe636f6017bd3f5d2ae95fce261d1cb4cee2e963d255328886d6abce20aeeb" in release
    assert "d8b2f974dda56bd48fb9790f1ac8966fba4e72f2a643dc6c75d7b44406143de3" in release
    assert "AUTHENTICODE" in release and "NOT SIGNED" in release
    assert "PUBLIC DOWNLOAD CERTIFIED" in release
    assert "No unsigned substitute is authorized" in release


def test_business_release_gate_is_fail_closed():
    gate = load_json(GATE)
    assert gate["release_state"] == "CANDIDATE"
    assert gate["candidate"]["source_sha"] == "90de700bb9c44ab62212731dbaa13c0bea3b3ffd"
    assert gate["candidate"]["politics_included"] is False
    assert gate["earned_gates"]["microsoft_defender"] == "PASS"
    assert gate["earned_gates"]["business_film_pages_deployment"] == "PASS"
    assert gate["earned_gates"]["business_film_clean_browser_playback"] == "PASS"
    assert gate["pending_gates"]["authenticode"] == "PENDING"
    assert gate["pending_gates"]["public_binary_download"] == "DISABLED_FAIL_CLOSED"
    assert gate["separate_non_release_claims"]["politics_download"] == "WITHHELD_BY_PRODUCT_POLICY"
    assert "No unsigned public binary." in gate["prohibitions"]
