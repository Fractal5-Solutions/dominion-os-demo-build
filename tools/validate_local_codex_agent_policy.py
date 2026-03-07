from __future__ import annotations

import pathlib

import yaml


ROOT = pathlib.Path(__file__).resolve().parents[1]
POLICY = ROOT / "policy" / "local_codex_agent_policy.yaml"


def fail(msg: str) -> int:
    print(f"[FAIL] {msg}")
    return 1


def main() -> int:
    if not POLICY.exists():
        return fail("policy/local_codex_agent_policy.yaml is missing")

    data = yaml.safe_load(POLICY.read_text(encoding="utf-8"))

    if data.get("version") != 1:
        return fail("version must be 1")

    if data.get("mode") != "SOVEREIGN_LOCAL_LIVEOPS_9_9":
        return fail("mode mismatch")

    authority = data.get("authority", {}).get("sole_human_user", {})
    if authority.get("email") != "matthewburbidge@fractal5solutions.com":
        return fail("sole_human_user email mismatch")

    source_of_truth = data.get("source_of_truth", {})
    if source_of_truth.get("primary_repo") != "dominion-command-center":
        return fail("source_of_truth.primary_repo mismatch")

    repos = data.get("repository_roles", {})
    expected = {
        "dominion-command-center": "allow_both",
        "dominion-os-demo-build": "business_only",
        "dominion-os-1.0-gcloud": "business_only",
        "dominion-os-1.0-aws": "business_only",
        "dominion-os-1.0-azure": "business_only",
        "dominion-os-1.0-politics": "politics_only",
    }

    for repo, enforcement in expected.items():
        actual = repos.get(repo, {}).get("enforcement")
        if actual != enforcement:
            return fail(f"{repo} expected {enforcement}, got {actual}")

    rules = data.get("agent_rules", {})
    required_true = [
        "sole_human_authority",
        "require_truthful_status",
        "require_tests_before_success",
        "require_auditability",
        "require_rollback_readiness",
    ]
    for key in required_true:
        if rules.get(key) is not True:
            return fail(f"{key} must be true")

    required_approvals = {
        "destructive_data_deletion",
        "irreversible_schema_migration",
        "credential_rotation_live",
        "disabling_security_controls",
        "cross_tenant_data_actions",
        "external_commitments",
    }
    actual_approvals = set(data.get("approval_required", []))
    if actual_approvals != required_approvals:
        return fail("approval_required entries do not match expected set")

    deny_markers = set(data.get("deny_markers_for_business_repos", []))
    required_deny_markers = {
        "politics",
        "political_stack",
        "campaign",
        "voter",
        "voter_file",
        "nationbuilder",
        "pac",
        "civic",
        "field_ops",
        "war_room",
    }
    if not required_deny_markers.issubset(deny_markers):
        return fail("deny_markers_for_business_repos is missing required markers")

    print("[OK] local codex agent policy validated")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
