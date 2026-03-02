# Autopilot Nightly Runbook

## Nightly workflow

- Workflow: `.github/workflows/autopilot-nightly.yml`
- Triggers: `schedule` (nightly) and `workflow_dispatch` (manual)
- Flow: preflight -> autopilot -> deploy -> report (always runs)
- Concurrency: `autopilot-${{ github.repository }}-${{ github.ref }}` (no overlap)

## Required config

- Secrets: `GCP_PROJECT_ID`, `SIGN_IMAGE`, `SIGN_KEY_URI` (or `COSIGN_KEY_URI`)
- Auth (choose one): `GCP_WIF_PROVIDER` + `GCP_WIF_SA_EMAIL` OR `GCP_SA_KEY`
- Variables: `GCP_SERVICE_NAME`, optional `GCP_REGION` (default `us-central1`), optional `GCP_ALLOW_UNAUTH` (default `false`)
- Access: checkout of `Fractal5-Solutions/dominion-os-1.0` uses `github.token` or `GH_AUTOPILOT_TOKEN` if provided.

## Local fallback (guarded)

- Use `scripts/autopilot.ps1` for local runs; it invokes `tools/autopilot_guard.sh`.
- The guard enforces clean git state, dry-run push, and push-or-abort if commits are created.

## Operator checklist

- Confirm `git status -sb` is clean and upstream is set.
- Verify required secrets/vars in repo settings.
- Ensure WIF/OIDC is configured (preferred) or `GCP_SA_KEY` is present.
- Confirm this repo can read `Fractal5-Solutions/dominion-os-1.0` in Actions.
- Trigger `Autopilot Nightly` manually if needed and watch the Step Summary.
- If `autopilot/nightly` PR is created, ensure branch protection and auto-merge are enabled.
- Confirm deploy job emits a Cloud Run revision and URL in `deploy.json`.
- On failure, read the GitHub Issue titled `Autopilot Nightly Report` for next actions.
