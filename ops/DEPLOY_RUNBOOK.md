# Fractal5 Demo Deploy Runbook

## Canonical target

- Project ID: `f5-prod-command-core`
- Project number: `732190342674`
- Cloud Run service: `demo`
- Region: `us-central1`
- Public runtime base: `https://demo-reduwyf2ra-uc.a.run.app`
- Required runtime routes: `/demo`, `/health`, `/status`
- Canonical deployment workflow: `.github/workflows/cicd-deploy.yml`

The GitHub OIDC workflow is the canonical deployment path. Local `gcloud auth login` and ad-hoc IAM mutation are not the normal deployment model.

## Identity contract

GitHub Actions authentication uses short-lived Google Workload Identity Federation credentials. The provider must be the full resource name:

```text
projects/732190342674/locations/global/workloadIdentityPools/POOL/providers/PROVIDER
```

The configured deployment service account is expected to be a dedicated least-privilege identity for this repository. Static service-account JSON keys are not an approved fallback.

The current governed provider identifiers are tracked in issue #189 and the repository deployment workflow. A shorthand `POOL/PROVIDER` value may be normalized by the workflow, but it must resolve to the numeric project number above.

## Repository-side preflight

The deployment workflow must fail closed unless all of the following are true:

1. `ENABLE_OIDC_DEPLOY=true`.
2. `GCP_PROJECT_ID` resolves to `f5-prod-command-core` unless an intentionally approved successor is documented.
3. `GCP_PROJECT_NUMBER` is numeric and matches the provider resource.
4. The WIF provider resolves to a full provider resource name.
5. The deployment service-account identity is configured.

Malformed, missing, or mismatched identity inputs must produce a WITHHELD receipt rather than attempting deployment.

## Google Cloud owner verification

An authenticated Google Cloud owner/operator session is required to verify or restore the provider-side trust root. Read-only verification should establish:

```bash
gcloud auth list
gcloud config list
gcloud projects describe f5-prod-command-core --format='value(projectNumber)'
gcloud iam workload-identity-pools describe fractal5-github-pool \
  --project=f5-prod-command-core \
  --location=global
gcloud iam workload-identity-pools providers describe github-provider \
  --project=f5-prod-command-core \
  --location=global \
  --workload-identity-pool=fractal5-github-pool
gcloud iam service-accounts describe \
  dominion-demo-oidc-sa@f5-prod-command-core.iam.gserviceaccount.com \
  --project=f5-prod-command-core
```

Do not interpret repository configuration as proof that the provider exists or is ACTIVE.

## Provider restoration boundary

If the provider is absent, disabled, or deleted, restoration is a Google Cloud control-plane action. It must preserve:

- issuer `https://token.actions.githubusercontent.com`;
- attribute mappings required by the GitHub trust policy;
- a condition restricted to the approved Fractal5 organization/repository/ref scope;
- `roles/iam.workloadIdentityUser` only for the intended principal set on the dedicated deployment service account;
- no long-lived service-account key fallback.

Provider/IAM restoration must be followed by a fresh GitHub OIDC authentication receipt before runtime deployment is considered available.

## Runtime certificate gate

After authenticated deployment of the exact certified source commit, require all of the following before GREEN:

```text
GET /demo    -> HTTP 200
GET /health  -> HTTP 200 JSON
GET /status  -> HTTP 200 JSON
```

`/health` and `/status` must include `Cache-Control: no-store`. The runtime receipt must bind the expected source SHA to the deployed release SHA and named Cloud Run revision. Claim-safety checks must pass.

A successful build alone is not runtime GREEN.

## Local recovery script

`deploy_demo.sh` is retained as an explicitly gated recovery path only. It is fail-closed unless:

```bash
ALLOW_MUTATING_LOCAL_DEPLOY=true ./deploy_demo.sh
```

That flag is not authorization by itself. The recovery path must only be used for a specifically approved deployment. It no longer creates APIs, Artifact Registry repositories, or IAM role bindings automatically.

## Failure triage

For authenticated read-only diagnosis:

```bash
gcloud builds list --project=f5-prod-command-core --limit=10
gcloud run services describe demo --project=f5-prod-command-core --region=us-central1
gcloud run revisions list --project=f5-prod-command-core --region=us-central1 --service=demo
```

If the GitHub auth action reports `invalid_target`, first verify that the provider input is the full numeric-project resource name. If the canonical resource name is already correct, treat the failure as evidence that the provider-side trust root is absent, disabled, deleted, or otherwise not usable and keep deployment WITHHELD.

## Completion definition

GCloud public-demo authentication/runtime is complete only when:

1. the WIF provider exists and is ACTIVE;
2. the trust condition and service-account binding are least-privilege and repository/ref scoped;
3. GitHub obtains a short-lived federated credential successfully;
4. the exact certified source commit is deployed to service `demo` in `us-central1`;
5. `/demo`, `/health`, and `/status` pass the receipt contract;
6. the runtime certificate is current and bound to the deployed SHA/revision.

Until then, GCloud authentication/runtime remains WITHHELD by design.
