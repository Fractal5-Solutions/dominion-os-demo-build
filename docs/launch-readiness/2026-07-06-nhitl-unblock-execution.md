# Dominion OS NHITL Commercial Unblock Execution — 2026-07-06

Generated: 2026-07-06T00:45:00Z  
Mode: NHITL execution with public-safe guardrails  
Primary tracker: Issue #145  
Repository: Fractal5-Solutions/dominion-os-demo-build

## Execution verdict

The unblock plan is now executable, not merely descriptive.

This package adds a machine-readable public proof verifier, a scheduled/manual GitHub Actions workflow, stronger watchlist assertions, and a controlled-preview commerce receipt.

The commercial state remains AMBER. Controlled commercial preview is allowed. Full commercial green remains blocked.

## What changed

1. Added `tools/verify-demo1-public-proof.mjs`.
2. Added `.github/workflows/demo1-public-proof.yml`.
3. Strengthened `demo/assets/demo-1-watchlist.json` with:
   - hardened bridge assertions,
   - claim-drift checks for MP4 language,
   - controlled-preview commerce receipt route,
   - NHITL execution document reference.
4. Added `demo/assets/controlled-preview-commerce-receipt.json`.
5. Preserved full-commercial-green claim control.

## Probe behavior

The verifier fetches only public URLs declared in the watchlist and manifest. It checks:

- `/demo-1`, `/demo`, `/health`, `/status`;
- source-served manifest, poster, sample data, package, receipts, bridge source, readiness, and commerce receipt;
- expected HTTP 200 status;
- basic content-type posture;
- required `/demo-1` visible strings;
- hardened bridge strings such as `data-version="2026-06-08-hardened"`, noreferrer, referrer policy, hidden poster fallback, and allowlist constants;
- forbidden MP4-complete language while `assets.videoMp4` remains null.

The workflow runs hourly and manually. It uploads a public-safe JSON artifact named `demo1-public-proof-receipt`.

## Commercial interpretation

The new commerce receipt deliberately chooses the fastest honest sales posture: controlled-preview / invoice-only.

That can support serious prospect conversations and paid controlled access, but it is not self-serve SaaS commerce. It does not prove checkout, a customer portal, automated subscription billing, or automated entitlement lifecycle.

## Remaining blockers

Full commercial GREEN still requires:

1. claim-drift repair for `/demo` MP4 language or a real verified public MP4 URL;
2. exact deployed `/demo-1` live-DOM receipt;
3. first successful public-proof workflow receipt;
4. secret/public-boundary/dependency/tenant-isolation receipts;
5. current CI/e2e receipt;
6. real invoice/procurement or payment receipt;
7. onboarding/provisioning/entitlement receipt;
8. observability, alerting, rollback, and incident-response receipts;
9. autonomous remediation/self-healing receipts if that claim is made.

## Claim-control line

Allowed now:

> Dominion OS has a live public demo bridge, public proof assets, public health/status endpoints, source-served receipts, executable probe scaffolding, and a controlled-preview commercial path.

Not allowed now:

> Direct MP4, self-serve SaaS commerce, customer portal green, production observability green, native GCP self-healing green, or full commercial all-green readiness.

The bridge is open. The drawbridge is not yet a bank.
