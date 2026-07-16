# Demo claim-drift cutover receipt — 2026-07-16

## Verdict

`BLOCKED_PENDING_DEPLOYMENT`

The checked-in `main` demo shell is softer than the live Cloud Run `/demo` surface. The live runtime still displays direct-MP4/all-green language that is not supported by the current manifest.

## Current public evidence

- Live Cloud Run `/demo` text observed: `All-green release evidence`, `Actual demo MP4 integrated`, `Checking integrated MP4 variants`, `Open web MP4`, and `Open master MP4`.
- Current public manifest evidence: `assets.videoMp4` is `null`.
- Current public manifest evidence: `claimControl.fullCommercialGreenAllowed` is `false`.
- Current readiness matrix evidence: commercial launch remains `AMBER` and direct MP4/full commercial green remain explicitly disallowed without separate receipts.

## Source inspection

`demo/index.html` on the repository mainline does not contain the observed direct-MP4/all-green language. The current mainline demo shell presents a gated operator experience and hydratable live-state cards instead of an embedded MP4 claim.

Therefore the likely repair is not another source-copy edit in `demo/index.html`; it is a deployment cutover to a current safe artifact, or identification/removal of the older generated runtime artifact currently served by Cloud Run.

## Required cutover

Run the approved deployment path from an authorized workstation or CI/CD surface with GCP credentials:

1. Build from the current `Fractal5-Solutions/dominion-os-demo-build` source after claim-control PR review.
2. Deploy the `dominion-demo` Cloud Run service from the safe artifact.
3. Verify `https://demo-reduwyf2ra-uc.a.run.app/demo` no longer contains:
   - `All-green release evidence`
   - `Actual demo MP4 integrated`
   - `Open web MP4`
   - `Open master MP4`
4. Verify `/health` and `/status` remain HTTP 200 public-safe JSON.
5. Re-run `demo1-public-proof` and attach the no-secret receipt.
6. Keep `assets.videoMp4: null` and `fullCommercialGreenAllowed: false` until a real HTTPS `.mp4` asset passes HEAD/range proof and all commercial gates pass.

## Do not claim

- direct public MP4 available;
- full commercial green;
- customer portal green;
- self-serve SaaS commerce green;
- native GCP self-healing green;
- production observability green.

## Safe interim public language

Use only controlled-preview language until the cutover receipt exists:

> Dominion OS has a public-safe Cloud Run sandbox, health/status receipts, source-served demo assets, and a controlled-access buyer path. Direct MP4 playback, full self-serve commerce, customer portal readiness, production observability, and autonomous remediation are not claimed without separate receipts.
