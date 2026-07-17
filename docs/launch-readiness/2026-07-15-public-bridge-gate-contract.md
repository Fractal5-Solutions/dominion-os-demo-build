# 2026-07-15 Public Bridge Gate Contract

## Verdict

The `/demo-1` public bridge gate is repaired as a contract problem, not inflated into a full commercial-green claim.

The live Fractal5 page and the machine-readable watchlist had drifted because the deployed public bridge now uses the current public-proof language while the watchlist still demanded legacy CTA text and source-only hardening tokens on the deployed DOM.

This receipt resolves that drift by separating the two proof scopes:

1. **Live deployed bridge assertions** are checked against `https://www.fractal5solutions.com/demo-1`.
2. **Hardened source assertions** are checked against the source-served `squarespace/demo-1-final.html` package.

## Changes

- `demo/assets/demo-1-watchlist.json`
  - updates the public bridge assertions to match the current deployed public-proof bridge;
  - adds explicit assertion scopes;
  - preserves direct MP4 claim control while `demo/assets/demo-manifest.json` has `assets.videoMp4: null`;
  - preserves controlled-preview-only commercial posture;
  - keeps full commercial green blocked without separate receipts.

- `tools/verify-demo1-public-proof.mjs`
  - checks current live bridge assertions against live `/demo-1`;
  - checks hardened implementation tokens against the source-served Squarespace package;
  - includes assertion targets in the emitted receipt;
  - preserves strict failure behavior when the public-proof contract is not green.

- `demo/assets/commercial-launch-readiness.json`
  - marks the public bridge contract aligned;
  - keeps overall status `AMBER`;
  - keeps direct MP4, commerce/customer-portal, production observability, rollback, autonomous remediation, and full commercial green blocked without receipts.

## Public bridge pass definition

The public bridge gate is passable when all of the following are true:

- live `/demo-1` exposes the current public proof bridge language, links, readiness/watchlist references, and controlled-access boundary;
- source-served `squarespace/demo-1-final.html` preserves hardened implementation tokens and URL allowlist logic;
- declared Cloud Run `/demo`, `/health`, and `/status` routes are reachable by the public-proof workflow;
- source-served public assets remain public-safe;
- no direct MP4 claim is allowed while `assets.videoMp4` is null;
- no full commercial green is allowed until separate commercial, observability, rollback, security, and autonomous-operation receipts exist.

## Claim control

Allowed now:

- controlled public/prospect preview;
- public bridge proof surface;
- source-served assets and receipts;
- invoice-only or scoped-access discussion when described as controlled preview.

Not allowed yet:

- direct public MP4 available;
- self-serve SaaS commerce green;
- customer portal green;
- production observability green;
- native GCP self-healing green;
- full commercial all-green readiness.

No secrets. No customer data. No payment data. No private runtime artifacts.
