# Dominion OS Multicloud Demo Green Plan

Status date: 2026-08-02

## Objective

Deliver the strongest truthful public demo at the lowest intelligent operating cost, while preventing website copy, manifests, and runtime evidence from drifting apart.

## Green states established by this change

- A verified static public-safe demonstration is the default public experience.
- The Squarespace source fails closed to that verified static surface.
- A provider can be labelled live only after an allowlisted health endpoint returns an explicit healthy state and a receipt no older than five minutes.
- The canonical demo manifest, runtime-state manifest, page source, and publication workflow use the same claim boundary.
- Pull requests test the public claim contract before merge.
- Main-branch publication emits an exact-release receipt bound to the Git commit.
- Direct MP4, continuous multicloud runtime, production SLA, and full-commercial-green claims remain disabled without separate evidence.

## Architecture baseline

- Google Cloud Run remains the optional reference runtime.
- Azure Container Apps is the preferred economical Azure proof path.
- AWS Lambda Function URLs are the preferred economical AWS proof path; ECS Fargate is reserved for resilient requirements.
- OCI remains a portable client-specific provisioning path until a dedicated provider package is receipted.
- Public data is immutable, bundled, or read-only. No cross-cloud write database is introduced for demonstration theatre.
- Provider identities use short-lived workload federation. Static cloud keys are prohibited.

## External authenticated gates

### Gate A: Squarespace publication

State: BLOCKED OUTSIDE REPOSITORY

Required proof:

1. An authenticated Squarespace editor publishes `squarespace/demo-1-final.html` to `/demo-1`.
2. The deployed DOM contains `data-version="2026-08-02-multicloud-proof-v2"`.
3. The default CTA resolves to the verified GitHub Pages demonstration.
4. No stale live-runtime or direct-MP4 claim appears.
5. Desktop, tablet, mobile, keyboard, and external-link behaviour pass.

Until this proof exists, the repository source is green but the live Squarespace page is not certified.

### Gate B: Google workload identity and Cloud Run

State: WITHHELD BY DESIGN

Required proof:

1. A Google Cloud owner restores a least-privilege GitHub OIDC trust relationship restricted to this repository and approved refs.
2. The deployment service account has only required Artifact Registry, Cloud Run deployment, and runtime service-account impersonation authority.
3. Repository deployment variables explicitly enable the OIDC lane.
4. The exact reviewed commit is deployed as an immutable image digest.
5. `/demo`, `/health`, and `/status` return HTTP 200.
6. Health and status return JSON with `Cache-Control: no-store`.
7. The runtime reports the expected release SHA and named revision.
8. The runtime manifest is promoted to `publicClaimAllowed: true` only after those checks pass.

Until this proof exists, Google Cloud is deployment-ready but its public runtime is not certified live.

## Separate commercial gates

The public demo does not certify self-service commerce, customer onboarding, entitlements, support, refunds, production SLOs, autonomous remediation, or production tenant isolation. Full commercial green remains false until each capability has its own current receipt.

A controlled, invoice-led deployment may proceed when accurately described and governed; it must not be represented as a fully self-service SaaS platform.

## Closure rule

All green means every asserted capability has current evidence. A missing credential, unpublished page, stale receipt, skipped deploy, 404 route, release mismatch, or unsupported claim remains non-green. The system must never weaken this rule merely to change the displayed colour.
