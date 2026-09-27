import hashlib
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
MEDIA = ROOT / "demo" / "media"
MANIFEST = ROOT / "demo" / "assets" / "live-mission-video-manifest.json"
PACKAGE = ROOT / "demo" / "assets" / "demo-download-package.json"
GATE = ROOT / "demo" / "assets" / "dominion-business-1.0-release-gate.json"
SAAS = ROOT / "demo" / "assets" / "dominion-saas-catalog.json"


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


def test_saas_catalogue_is_stable_without_overclaiming_runtime():
    catalog = load_json(SAAS)
    expected = {
        "GrantConnect", "TeamConnect", "PolicyConnect", "ChannelConnect",
        "Cloud Engine", "Vault Systems", "Command Core", "Advocate Engine",
        "Install Grid", "OpsSignal", "EcoStack", "StoryThread", "DataHarbor",
    }
    names = {module["name"] for module in catalog["modules"]}
    assert catalog["catalogue_state"] == "stable"
    assert catalog["module_count"] == 13
    assert names == expected
    by_name = {module["name"]: module for module in catalog["modules"]}
    coming_soon = {"EcoStack", "Install Grid", "DataHarbor"}
    for name, module in by_name.items():
        if name in coming_soon:
            assert module["store_state"] == "Coming Soon"
            assert module["sellable"] is False
        else:
            assert module["store_state"] == "Configure"
    assert by_name["Cloud Engine"]["sku"] == "APP-CLOUD-ENGINE-W2"
    assert by_name["OpsSignal"]["sku"] == "APP-OPSSIGNAL-W2"
    assert by_name["Advocate Engine"]["sku"] == "APP-ADVOCATE-ENG-W2"
    assert by_name["EcoStack"]["sku"] == "APP-ECOSTACK"
    assert by_name["Install Grid"]["sku"] == "APP-INSTALL-GRID"
    assert by_name["DataHarbor"]["sku"] == "APP-DATAHARBOR"
    assert catalog["runtime_certification"] == "engagement-specific"
    assert catalog["independent_ga_claim"] is False
    assert catalog["universal_api_claim"] is False
    assert catalog["marketplace_listing_claim"] is False
    snapshot_path = ROOT / "demo" / "assets" / "dominion-product-manifest.v1.json"
    snapshot = load_json(snapshot_path)
    assert catalog["canonical_manifest"]["snapshot_sha256"] == sha256(snapshot_path)
    governed = {module["name"]: module for module in snapshot["modules"]}
    for module in catalog["modules"]:
        source = governed[module["name"]]
        assert module["id"] == source["id"]
        assert module["sku"] == source["sku"]
        assert module["store_state"] == source["store_state"]
        assert module["implementation_state"] == source["implementation_state"]
        assert module["standalone_ga"] is False
        if "sellable" in source:
            assert module["sellable"] == source["sellable"]
        else:
            assert "sellable" not in module


def test_squarespace_v17_handoff_remains_immutable_while_final_can_advance():
    immutable = ROOT / "squarespace" / "demo-1-v1.7-business-media.html"
    moving = ROOT / "squarespace" / "demo-1-final.html"
    handoff = load_json(ROOT / "squarespace" / "demo-1-v1.7-handoff.json")
    assert sha256(immutable) == "0a49a40b849543c883ebc8bf65368e923796e58e0e7977d24d83fa6b64d53cec"
    assert handoff["sha256"] == sha256(immutable)
    assert moving.read_bytes() != immutable.read_bytes()
    assert 'data-page-build="demo-1-v1.8-20260927-four-provider-windows"' in moving.read_text(encoding="utf-8")
    assert handoff["principal_deployment_state"] == "PENDING_MANUAL_GATE"
    assert handoff["automatic_deployment_authorized"] is False

def test_current_release_gate_records_four_provider_fanout_and_dns_ready():
    gate = load_json(GATE)
    assert gate["separate_non_release_claims"]["canonical_phi_hostname"] == "READY"
    fanout = gate["provider_fanout_evidence"]
    assert fanout["windows_main_sha"] == "f0d6c04473175afbeeab7e835fbd4fc3a1e3ea54"
    assert fanout["packaging_mechanics"] == "PASS"
    assert set(fanout["providers"]) == {"gcp", "aws", "azure", "oci"}
    assert all(value == "PASS" for value in fanout["providers"].values())
    assert fanout["public_download_certification"] == "WITHHELD_PENDING_AUTHENTICODE"

def test_current_squarespace_fallback_is_truthful_without_javascript():
    page = (ROOT / "squarespace" / "demo-1-final.html").read_text(encoding="utf-8")
    assert "Business Candidate · Publisher Signing Pending" in page
    assert "Demonstrated · Download Withheld" in page
    assert "Google Cloud" in page
    assert "Amazon Web Services" in page
    assert "Microsoft Azure" in page
    assert "Oracle Cloud Infrastructure" in page
    assert "No public Dominion OS 1.0 release entries are currently registered." not in page
