"""Fail-closed checks for the Google Business/Politics demo launch contract."""
import json
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
CONTRACT = ROOT / "demo/assets/gcp-business-politics-live-acceptance.json"


def test_google_demo_contract_is_explicitly_uncertified():
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    assert data["schema"] == "fractal5.dominion.google-demo.acceptance.v1"
    assert data["status"] == "SOURCE_CONTRACT_ONLY_NOT_DEPLOYED"
    assert data["provider_attestation"] != "PASS"
    assert data["authority"]["live_dominion_management"] == "PHI_MCP_ONLY"
    assert data["authority"]["require_independent_source_review"] is True
    assert data["authority"]["require_publication_approval"] is True


def test_both_demo_missions_are_isolated_and_have_no_placeholder_url():
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    experiences = {item["id"]: item for item in data["experience"]}
    assert set(experiences) == {"business", "politics"}
    for name, item in experiences.items():
        assert item["certified"] is False
        assert item["requested_live_url"] is None
        assert item["verified_live_url"] is None
        assert "same-core-artifact-provenance" in item["gates"]
        assert f"synthetic-{name}-tenant-isolation" in item["gates"]
        assert "external-clickthrough-pass" in item["gates"]
        assert item["public_demo_fallback"].startswith("https://fractal5-solutions.github.io/")
        assert f"mode={name}" in item["public_demo_fallback"]
    assert "no-voter-personal-data" in experiences["politics"]["gates"]
    assert "no-campaign-transmissions" in experiences["politics"]["gates"]


def test_publication_is_fail_closed():
    data = json.loads(CONTRACT.read_text(encoding="utf-8"))
    p = data["publication"]
    assert p["change_only_after_both_endpoints_certified"] is True
    assert p["retain_current_fallbacks_until_complete"] is True
    assert p["live_page_published"] is False
    assert len(data["candidate_services_historical_only"]) >= 2
    assert all(s["current_state"] == "UNVERIFIED" for s in data["candidate_services_historical_only"])
