# Dominion OS full commercial green execution plan — 2026-07-10

Status: execution plan, not a green receipt.

Purpose: convert the current AMBER controlled-preview posture into a conservative full commercial GREEN release posture by requiring proof receipts for every commercial claim.

## Current baseline

Dominion OS has a credible public demo spine:

- canonical public website bridge: `https://www.fractal5solutions.com/demo-1`
- public Cloud Run demo route: `https://demo-reduwyf2ra-uc.a.run.app/demo`
- public Cloud Run health/status routes
- source-served demo manifest, poster, sample data, demo package manifest, release receipts, and watchlist artifacts
- merged `/demo-1` watchlist and post-publish verification scaffolding

Full commercial GREEN remains blocked until all proof gates below are complete and receipted.

## Non-negotiable claim-control rule

Full commercial GREEN may not be claimed until the release candidate has all required receipts for:

1. live demo claim drift repaired,
2. hardened `/demo-1` live-DOM verification,
3. public and production security scans,
4. current CI/build/link/e2e verification,
5. commerce or deliberately invoice-only sales motion,
6. customer onboarding and entitlement lifecycle,
7. observability and alert routing,
8. rollback and incident response,
9. autonomous watcher/remediation evidence,
10. client-safe production/payment/provisioning proof.

Direct MP4 may not be claimed unless a real public MP4 URL exists, is fetchable, and is reflected in `demo/assets/demo-manifest.json`.

## Gate 1 — demo runtime claim drift

Target status: GREEN.

Required work:

- Either remove/soften runtime copy that implies direct MP4 availability, or publish a real public MP4 and update the manifest.
- Add an automated claim-drift check that fails if `assets.videoMp4` is null while public HTML includes forbidden phrases such as `Actual demo MP4 integrated`, `Open web MP4`, `Open master MP4`, `direct MP4 is available`, or `MP4 integrated`.

Required receipt:

- `docs/launch-readiness/receipts/<date>-demo-runtime-claim-drift-repair.json`

Acceptance:

- `/demo` remains live.
- `/health` and `/status` remain live.
- No MP4 availability claim exists unless the public MP4 is real and verified.

## Gate 2 — hardened `/demo-1` live-DOM verification

Target status: GREEN.

Required work:

- Fetch live `https://www.fractal5solutions.com/demo-1` after Squarespace publish/cache propagation.
- Verify exact required CTA labels:
  - Open Live Demo
  - Watch Video
  - Play With Data
  - Health JSON
  - Status JSON
  - View Sample Data
  - Open Demo Package
  - Open Receipts
  - Contact Fractal5
- Verify exact hardening assertions:
  - `data-version="2026-06-08-hardened"`
  - `rel="noopener noreferrer"`
  - `referrerpolicy="strict-origin-when-cross-origin"`
  - hidden poster fallback before manifest load
  - Cloud Run, raw asset, and Fractal5 URL allowlists

Required receipt:

- `docs/launch-readiness/receipts/<date>-demo-1-live-dom-verification.json`

Acceptance:

- Source package and live DOM match the hardened bridge contract.
- The old deleted Squarespace `/demo` route is ignored and not treated as canonical.

## Gate 3 — source-served asset watch

Target status: GREEN.

Required work:

- Verify public fetch for:
  - `demo/assets/demo-manifest.json`
  - `demo/assets/dominion-os-demo-poster.svg`
  - `demo/assets/sample-data.json`
  - `demo/assets/demo-download-package.json`
  - `demo/assets/release-receipts.json`
- Verify content type, status code, schema marker, and public-safety assertions.

Required receipt:

- `docs/launch-readiness/receipts/<date>-source-served-assets.json`

Acceptance:

- All source-served public assets return expected content and contain no secrets, customer data, payment data, or private service endpoints.

## Gate 4 — security and public-boundary proof

Target status: GREEN.

Required work:

- Run secret scanning against public demo-build assets and production deployment config references.
- Run dependency scan for runtime and bridge package dependencies.
- Run public-boundary review for exposed URLs, headers, payloads, analytics, and downloadable assets.
- Produce tenant-isolation proof for any customer-facing production path.

Required receipts:

- `docs/launch-readiness/receipts/<date>-secret-scan.json`
- `docs/launch-readiness/receipts/<date>-dependency-scan.json`
- `docs/launch-readiness/receipts/<date>-public-boundary-review.json`
- `docs/launch-readiness/receipts/<date>-tenant-isolation-proof.json`

Acceptance:

- No secrets or private customer/payment data are present in any public surface.
- Production paths are not exposed through the demo bridge.

## Gate 5 — build, link, and e2e release candidate

Target status: GREEN.

Required work:

- Run current CI for the release candidate.
- Run link checks against `/demo-1`, Cloud Run root/demo/health/status, and raw assets.
- Run browser/e2e checks for primary CTAs.
- Run schema checks for JSON assets.
- Run claim-drift checks.

Required receipt:

- `docs/launch-readiness/receipts/<date>-ci-build-link-e2e.json`

Acceptance:

- CI, link checks, browser route checks, schema checks, and claim-drift checks pass on the same release candidate.

## Gate 6 — commerce motion

Target status: GREEN by one of two paths.

Path A: self-serve commerce.

Required work:

- Live checkout.
- Production payment processor proof.
- Tax/invoice receipt.
- Refund/cancellation path.
- Terms/privacy/customer communication path.

Path B: invoice-only commercial motion.

Required work:

- Approved offer/pricing sheet or quote template.
- Procurement/invoice workflow receipt.
- Manual qualification and onboarding SOP.
- Payment terms and refund/cancellation/offboarding policy.

Required receipt:

- `docs/launch-readiness/receipts/<date>-commerce-motion.json`

Acceptance:

- Claim states the true sales motion. If invoice-only, do not claim self-serve SaaS checkout.

## Gate 7 — customer onboarding and entitlement

Target status: GREEN.

Required work:

- Define tenant/customer onboarding flow.
- Define entitlement lifecycle: provision, suspend, renew, cancel, offboard.
- Define support intake and escalation path.
- Verify no customer data is exposed through public demo surfaces.

Required receipt:

- `docs/launch-readiness/receipts/<date>-customer-onboarding-entitlement.json`

Acceptance:

- A client can be onboarded safely, supported, and offboarded without improvisation.

## Gate 8 — observability and alert routing

Target status: GREEN.

Required work:

- Uptime monitor for `/demo-1`, Cloud Run root/demo/health/status, and raw assets.
- Alert routing to a responsible operator channel.
- SLO definition for demo/customer-facing surfaces.
- Log-sampling and metrics-retention policy.
- Incident receipt format.

Required receipt:

- `docs/launch-readiness/receipts/<date>-observability-alert-routing.json`

Acceptance:

- Failure is detected, routed, and recorded. A green dashboard alone is not enough.

## Gate 9 — rollback and incident response

Target status: GREEN.

Required work:

- Document rollback path for Squarespace bridge, Cloud Run runtime, and source-served assets.
- Confirm last-known-good artifact references.
- Run or simulate rollback rehearsal.
- Document incident severity, response owner, and communication path.

Required receipt:

- `docs/launch-readiness/receipts/<date>-rollback-incident-response.json`

Acceptance:

- The team can recover from a bad publish without heroics.

## Gate 10 — autonomous operations and self-healing

Target status: GREEN only if claimed.

Required work:

- Prove watchlist ingestion.
- Prove hourly probe output.
- Prove remediation behavior or explicitly scope it to alert-only.
- Prove GCP-native or equivalent self-healing only if that claim is used publicly.

Required receipt:

- `docs/launch-readiness/receipts/<date>-autonomous-operations-self-healing.json`

Acceptance:

- Autonomous claims match reality. Alert-only is acceptable if stated honestly; self-healing requires proof.

## Final commercial green packet

After all gates pass, publish one final machine-readable packet:

- `demo/assets/commercial-launch-readiness.json` updated to `overallStatus: GREEN`
- `demo/assets/commercial-green-receipt.json` created
- `docs/launch-readiness/receipts/<date>-full-commercial-green.json` created

The final packet must include:

- exact release candidate SHA,
- public demo route statuses,
- hardened `/demo-1` live-DOM proof,
- source-served asset proof,
- security/public-boundary proof,
- CI/build/e2e proof,
- commerce/payment or invoice-only proof,
- onboarding/entitlement proof,
- observability/alert proof,
- rollback/incident proof,
- autonomous operation proof or explicit non-claim,
- final claim-control section.

## Launch language after GREEN

Allowed only after all receipts exist:

> Dominion OS is commercially launch-ready under the documented sales motion, with a live public demo bridge, verified runtime and asset surfaces, receipted security and public-boundary controls, receipted commerce/onboarding/entitlement operations, production observability, rollback/incident procedures, and watched operational proof.

Still forbidden unless specifically proven:

- direct MP4 availability without a real public MP4 URL,
- self-serve checkout if using invoice-only commerce,
- native GCP self-healing unless GCP-native self-healing is installed and receipted,
- customer portal readiness unless a real customer portal exists and is verified.

## Execution order

1. Repair demo runtime claim drift.
2. Capture hardened `/demo-1` live-DOM receipt.
3. Capture source-served asset receipt.
4. Run security/public-boundary scans.
5. Run CI/link/e2e release-candidate proof.
6. Decide commerce mode: self-serve checkout or invoice-only.
7. Receipt onboarding, entitlement, support, refund/cancellation, and offboarding.
8. Receipt observability and alert routing.
9. Receipt rollback and incident response.
10. Receipt autonomous watch/remediation, or explicitly mark alert-only.
11. Update commercial readiness JSON to GREEN only after all receipts exist.

## Final verdict rule

No receipt, no green. The throne is earned, not announced.
