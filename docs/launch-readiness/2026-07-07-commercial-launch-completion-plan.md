# Dominion OS commercial launch completion plan - 2026-07-07

Generated: 2026-07-07T18:35:00Z
Repository: Fractal5-Solutions/dominion-os-demo-build
Primary tracker: Issue #145
Status: AMBER, controlled preview only

## Verdict

The commercial launch path is now decomposed into executable gates and receipt requirements.

This is not full commercial GREEN. The honest state remains controlled-preview AMBER. The remaining blockers are evidence-dependent: direct MP4 or claim-drift repair, exact deployed /demo-1 DOM proof, current public-proof artifacts, current security/build receipts, production-grade commerce/provisioning proof, observability/rollback proof, and autonomous-operations proof if that claim is made.

This package turns the work into a closed ledger: what is proven, what is structurally ready, what is blocked, and what exact receipt clears each blocker.

## Already structurally completed

1. PR #146 merged the executable public-proof layer, watchlist hardening, controlled-preview commerce receipt, and NHITL execution receipt.
2. PR #149 repaired the proof workflow startup path and preserved receipt upload with if: always().
3. PR #150 merged strict proof mode, so AMBER or RED public-proof results should fail the workflow while preserving the artifact upload path.
4. demo/assets/demo-manifest.json remains the canonical demo asset manifest.
5. demo/assets/demo-1-watchlist.json remains the canonical public proof target set.
6. demo/assets/controlled-preview-commerce-receipt.json establishes the only currently allowed commercial motion: controlled-preview, invoice-only, direct Fractal5 handling.

## Gate ledger

| Gate | Current state | What clears it |
| --- | --- | --- |
| Public MP4 / claim drift | BLOCKED unless /demo no longer claims direct MP4 while assets.videoMp4 is null | Publish a real public MP4 URL and update demo/assets/demo-manifest.json, or deploy runtime copy that only describes the recording-section fallback. |
| /demo-1 live DOM | SOURCE READY, DEPLOYMENT PROOF REQUIRED | Capture a live DOM receipt proving the deployed page contains the hardened source features and required CTAs. |
| Public-proof workflow receipts | STRUCTURALLY READY, ARTIFACT OBSERVATION REQUIRED | Observe and retain a post-merge demo1-public-proof-receipt artifact from the strict workflow. |
| Build/test/security | PARTIAL | Current CI, e2e, link, asset, public-boundary, secret scan, dependency scan, and tenant-isolation receipts. |
| Commerce/customer portal | CONTROLLED-PREVIEW ONLY | Full checkout/customer-portal proof or a complete invoice-only package: offer, invoice/procurement, onboarding, entitlement, support, refund/cancellation, privacy/data handling. |
| Observability/rollback | PARTIAL | Uptime/SLO, alert routing, metrics/log retention, incident-response, and rollback/recovery receipts. |
| Autonomous operations | UNCLAIMED | Watcher ingestion, remediation, recovery, and self-healing receipts if and only if the loop is real and auditable. |

## Completion sequence

### Phase 1 - remove public claim risk

Exit receipt: claim-drift-repair or verified-public-mp4.

- Inspect the live Cloud Run /demo route.
- If assets.videoMp4 is still null, remove or soften any wording that implies a direct MP4 exists.
- Run the strict public-proof workflow.
- Confirm claimDriftFailures equals 0.

### Phase 2 - capture deployed bridge proof

Exit receipt: demo-1-live-dom-receipt.

- Fetch the live deployed HTML from https://www.fractal5solutions.com/demo-1.
- Verify data-version="2026-06-08-hardened".
- Verify all required CTAs, noreferrer/referrerpolicy, hidden poster fallback, and allowlist constants.
- Store only public-safe DOM evidence.

### Phase 3 - prove the proof loop

Exit receipt: demo1-public-proof-receipt.

- Observe a strict-mode workflow run after the latest main commit.
- Retain the artifact.
- If verdict is AMBER or RED, keep the workflow failed and treat the artifact as the next repair map.

### Phase 4 - current release qualification

Exit receipt: release-qualification-receipt.

- Current CI/build/test/e2e pass.
- Link and asset checks pass.
- Public-boundary and tenant-isolation review passes.
- Secret and dependency scans pass.

### Phase 5 - commercial controlled-preview package

Exit receipt: controlled-preview-sales-motion-receipt.

- Approved offer or quote template.
- Invoice/procurement flow.
- Manual onboarding/provisioning record template.
- Entitlement lifecycle record template.
- Support path.
- Refund/cancellation/offboarding path.
- Privacy/data-processing boundary.

### Phase 6 - production operations package

Exit receipt: operations-readiness-receipt.

- Uptime/SLO target.
- Alert routing.
- Log/metric retention boundary.
- Incident response.
- Rollback/recovery.

### Phase 7 - autonomy proof or silence

Exit receipt: autonomous-operations-receipt, only if real.

- Watchlist ingestion evidence.
- Remediation event evidence.
- Rollback/recovery evidence.
- Claim-control check proving no unsupported self-healing language exists.

## Allowed language now

Dominion OS has a live public demo bridge, public Cloud Run demo routes, source-served public proof assets, strict public-proof workflow scaffolding, and a controlled-preview invoice-only commercial path.

## Forbidden language now

Do not claim direct MP4 availability, self-serve SaaS checkout, customer portal green, production observability green, native GCP self-healing green, or full commercial all-green readiness until the corresponding receipts exist.

## Final GREEN rule

fullCommercialGreenCurrentlyAllowed may become true only when every gate above has a current receipt and the manifest/readiness assets are updated from those receipts. No receipt, no claim.
