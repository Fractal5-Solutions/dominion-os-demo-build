# /demo-1 Post-Publish Verification

This checklist is the operator and daemon receipt path after `squarespace/demo-1-final.html` is pasted into the live Squarespace `/demo-1` page.

## Scope

Target page:

- `https://www.fractal5solutions.com/demo-1`

Runtime:

- `https://demo-reduwyf2ra-uc.a.run.app/demo`

Public source-served assets:

- `demo/assets/demo-manifest.json`
- `demo/assets/dominion-os-demo-poster.svg`
- `demo/assets/sample-data.json`
- `demo/assets/demo-download-package.json`
- `demo/assets/release-receipts.json`
- `squarespace/demo-1-final.html`

## Required green checks

1. `/demo-1` returns HTTP 200.
2. `/demo-1` displays the headline `Dominion OS, live on the cloud.`
3. `/demo-1` exposes clickable actions:
   - Open Live Demo
   - Watch Video
   - Play With Data
   - Health JSON
   - Status JSON
   - View Sample Data
   - Open Demo Package
   - Open Receipts
   - Contact Fractal5
4. Cloud Run `/demo` returns HTTP 200.
5. Cloud Run `/health` returns HTTP 200 JSON.
6. Cloud Run `/status` returns HTTP 200 JSON.
7. Raw GitHub manifest returns HTTP 200 JSON.
8. Raw GitHub poster returns HTTP 200 SVG.
9. Raw GitHub sample data returns HTTP 200 JSON.
10. Raw GitHub demo package returns HTTP 200 JSON.
11. Raw GitHub release receipts return HTTP 200 JSON.
12. `/demo-1` uses `/launch` Canon visual language: white/bone panels, thin warm lines, graphite text, gold-border buttons, no SaaS-blue visual system.

## Claim-control boundaries

Allowed after all required checks pass:

> `/demo-1` is live as the public Dominion OS 1.0 demo bridge with source-served public demo assets, sample data, release receipts, health/status proof, and live Cloud Run demo access.

Not allowed without separate proof:

- direct MP4 binary is available,
- downloadable binary package is available,
- Stripe/customer portal/live commerce is fully green,
- native GCP self-healing is green,
- full commercial stack is 100% green.

## Evidence storage

Store verification outputs in the operational evidence layer, preferably:

- `Fractal5-Solutions/phi-ops` public probe daemon outputs,
- daily commercial launch readiness packet,
- Dominion Command Center decision/evidence ledger,
- optional Cloud Logging / uptime check receipts.

## Next body

After publishing `/demo-1`, update the watcher daemon to include `demo/assets/demo-1-watchlist.json` as the source of expected routes and strings.
