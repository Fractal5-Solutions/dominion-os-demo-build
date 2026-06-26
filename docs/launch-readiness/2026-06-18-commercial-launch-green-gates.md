# Dominion OS commercial launch green gates — 2026-06-18

Status: AMBER

This receipt converts the public launch-readiness audit into operational gates. It is intentionally conservative: the public demo may be strong while the commercial launch remains incomplete.

## Current truth

Dominion OS has a credible public demo spine:

- canonical public bridge target: `https://www.fractal5solutions.com/demo-1`
- public Cloud Run runtime target: `https://demo-reduwyf2ra-uc.a.run.app/demo`
- public health/status route requirements
- source-served demo manifest, sample data, demo package manifest, release receipts, commercial readiness receipt, poster asset, and watchlist artifacts
- PR #127 merged the `/demo-1` watchlist and post-publish verification layer

Commercial launch is not fully green until separate receipts prove commerce, customer portal, production observability, autonomous remediation, and client-safe payment/provisioning boundaries.

## Current repair blocker

Direct MP4 remains null in `demo/assets/demo-manifest.json`. Until a real public MP4 URL exists and is verified, public copy may point to the video-equivalent runtime section but must not claim a direct MP4 asset is available.

## Status matrix

| Area | Status | Gate to green |
| --- | --- | --- |
| Demo runtime | AMBER | Daemon confirms root/demo/health/status probes pass, and live copy contains no stale direct-MP4, all-green, or full-commercial-green claims. |
| Hardened website bridge | AMBER | Live Squarespace `/demo-1` DOM passes the full post-publish checklist. |
| Source-served assets | AMBER | Manifest, poster, sample data, package JSON, release receipts, commercial readiness receipt, and compatibility receipt return expected public content types. |
| Security | AMBER | Secret scan, dependency scan, public-boundary review, and tenant-isolation proof exist. |
| Build/test | AMBER | Current CI, link checks, public-boundary checks, and e2e bridge checks pass on release candidate. |
| Cloud health | GREEN | Hourly route probes publish durable receipts. |
| Commerce/customer portal | RED | Live or deliberately invoice-only sales motion is proven with onboarding, entitlement, support, refund, privacy, and payment/procurement receipts. |
| Observability | AMBER | Uptime, alerting, log sampling, SLO/incident, and rollback receipts exist. |
| Autonomous operations | AMBER | Watcher ingestion, remediation, rollback/recovery, and self-healing receipts exist before those claims are made. |

## Allowed claim now

Dominion OS has a live public Google Cloud demo surface with public demo, health, and status routes, a canonical `/demo-1` bridge package, source-served public demo assets, sample data, release receipts, and a watchlist verification layer.

## Not allowed without separate receipts

Do not claim any of the following until the relevant receipt exists:

- full SaaS commerce is green
- customer portal is green
- direct MP4 is available
- native GCP self-healing is green
- production observability is green
- full commercial stack is 100% green

## Required receipts for full commercial green

1. Deployed `/demo-1` live-DOM verification receipt.
2. Daemon watchlist ingestion receipt.
3. Hourly probe output for `/demo-1`, Cloud Run routes, and raw assets.
4. Secret/public-boundary scan receipt.
5. Current CI/build/test receipt.
6. Commerce or invoice-only sales-motion receipt.
7. Customer onboarding and entitlement receipt.
8. Observability and alert-routing receipt.
9. Rollback and incident-response receipt.
10. Autonomous remediation/self-healing receipt if that claim is made.

## Operator note

The bridge is not the cathedral. The bridge gets prospects safely across the river. Commerce, portal, observability, and autonomous operations are the stonework that makes it a city.
