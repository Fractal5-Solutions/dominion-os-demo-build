from __future__ import annotations

import pathlib

import yaml


ROOT = pathlib.Path(__file__).resolve().parents[1]
POLICY = ROOT / "policy" / "local_codex_agent_policy.yaml"


def test_local_codex_agent_policy_contract() -> None:
    data = yaml.safe_load(POLICY.read_text(encoding="utf-8"))

    assert data["version"] == 1
    assert data["mode"] == "SOVEREIGN_LOCAL_LIVEOPS_9_9"
    assert data["authority"]["sole_human_user"]["email"] == "matthewburbidge@fractal5solutions.com"
    assert data["source_of_truth"]["primary_repo"] == "dominion-command-center"
    assert data["repository_roles"]["dominion-command-center"]["enforcement"] == "allow_both"
    assert data["repository_roles"]["dominion-os-demo-build"]["enforcement"] == "business_only"
    assert data["repository_roles"]["dominion-os-1.0-gcloud"]["enforcement"] == "business_only"
    assert data["repository_roles"]["dominion-os-1.0-aws"]["enforcement"] == "business_only"
    assert data["repository_roles"]["dominion-os-1.0-azure"]["enforcement"] == "business_only"
    assert data["repository_roles"]["dominion-os-1.0-politics"]["enforcement"] == "politics_only"
    assert "destructive_data_deletion" in data["approval_required"]
    assert "war_room" in data["deny_markers_for_business_repos"]
