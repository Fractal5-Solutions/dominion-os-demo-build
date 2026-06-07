# /demo-1 Delivery Contract

Status: canonical public bridge contract for the Fractal5 Solutions `/demo-1` page.

## Purpose

`https://www.fractal5solutions.com/demo-1` is the live public Squarespace target page for Dominion OS 1.0 demo delivery.

The page must present a beautiful, Canon-aligned public experience that lets a visitor:

1. open the live Dominion OS Cloud Run demo,
2. watch the demo video or video-equivalent runtime section,
3. play with public-safe demo data online,
4. inspect health/status proof,
5. open or download public-safe demo receipts/assets,
6. request client access through Fractal5 Solutions.

`/demo-1` is the visitor-facing bridge. It is not the private runtime, not the source repository, and not the place where secrets or internal APIs live.

## Canon roles

- `/demo-1`: public Squarespace bridge and sales/demo page.
- `dominion-os-demo-build`: public source-of-truth for demo-build public artifacts.
- Cloud Run demo: live runtime source at `https://demo-reduwyf2ra-uc.a.run.app/demo`.
- `Fractal5-Solutions/phi-ops`: operational daemon/evidence layer for public route probes and daily readiness packets.
- Dominion Command Center: executive control-plane memory and decision ledger.

## Required public routes

These routes must remain public and working for `/demo-1` delivery:

- `https://demo-reduwyf2ra-uc.a.run.app/`
- `https://demo-reduwyf2ra-uc.a.run.app/demo`
- `https://demo-reduwyf2ra-uc.a.run.app/health`
- `https://demo-reduwyf2ra-uc.a.run.app/status`
- `https://www.fractal5solutions.com/demo-1`

## Required source-served assets

The following source-served assets are public-safe and may be consumed by `/demo-1` as remote runtime assets:

- `demo/assets/demo-manifest.json`
- `demo/assets/dominion-os-demo-poster.svg`
- `demo/assets/sample-data.json`

Additional public assets should be added only when they are real, generated, and verified:

- direct MP4 recording file,
- downloadable demo package,
- direct release receipts JSON,
- poster image variants.

Do not advertise a direct asset URL in the manifest unless the file exists and can be fetched publicly.

## Required visitor actions

`/demo-1` must expose the following visitor actions:

- Open Live Demo -> Cloud Run `/demo`
- Watch Video -> Cloud Run `/demo#recording-proof` or direct MP4 when available
- Play With Data -> Cloud Run `/demo#live-operations` or public sample data when available
- Open Receipts -> Cloud Run `/demo#evidence-proof` or public receipt JSON when available
- Health -> Cloud Run `/health`
- Status -> Cloud Run `/status`
- Request Client Access -> Fractal5 contact or member/customer path

## Continuous verification requirements

The system must continuously watch:

- `/demo-1` page availability,
- Cloud Run root/demo/health/status routes,
- demo manifest availability,
- source-served demo assets,
- stale bridge detection: `/demo-1` must reference the current live demo route or approved branded runtime URL,
- secret/private marker detection in public content,
- dependency/security alerts in operational repos,
- evidence packet publication.

The current installed watchers are:

- ChatGPT hourly live demo health watcher,
- ChatGPT daily commercial launch readiness audit,
- GitHub-native hourly public probe daemon in `Fractal5-Solutions/phi-ops`,
- GitHub-native daily evidence packet daemon in `Fractal5-Solutions/phi-ops`.

Native GCP Scheduler / Cloud Run Job self-healing remains a desired next body unless separately proven installed.

## Public safety boundaries

`/demo-1` must never expose:

- production customer data,
- private API endpoints,
- signing keys,
- payment secrets,
- source code beyond approved public demo-build artifacts,
- internal operational dashboards,
- private Cloud Run services.

Private services must remain authenticated or otherwise intentionally controlled.

## Claim control

Allowed claim today:

> Dominion OS 1.0 has a live public Google Cloud demo surface with public demo, health, and status routes and a watched public Squarespace bridge.

Not allowed without additional evidence:

> Full SaaS commerce, direct MP4/package downloads, production customer portal, branded runtime domain, and native GCP self-healing are completely green.

Those claims require separate receipts.

## Acceptance criteria for `/demo-1` perfection

`/demo-1` is green only when:

1. the Squarespace page loads cleanly,
2. it follows Fractal5 Canon visual language from `/launch`,
3. all CTAs resolve to working public routes,
4. all referenced assets exist and are public-safe,
5. health/status proof is available,
6. no stale or false asset claims exist,
7. the watcher daemon confirms the page and routes continuously,
8. the page does not expose private information,
9. visitors can watch, play, inspect, and request access without manual explanation.

## Current truth

The `/demo-1` contract is formalized here. The live demo routes are proven by operator output. The manifest is merged to `dominion-os-demo-build` main. Generated poster and sample-data assets are in progress on the asset branch. Direct MP4 and direct downloadable package must not be claimed until real files are generated and publicly verified.
