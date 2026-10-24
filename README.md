# Dominion OS™ public demo artifacts

This repository is the deliberately minimal public-proof surface for **Dominion OS™ + SaaS Suite**.

It is **not** the Dominion OS source repository, an operator console, a deployment repository, or a production control plane.

## Public artifact contract

The approved public presentation and sanitized proof surface includes:

- `index.html` — static public demonstration
- `404.html` — fail-closed route handling
- `.nojekyll` — static hosting marker
- `README.md` — public boundary description
- `SECURITY.md` — disclosure and repository-safety policy
- `demo/assets/cloud-deployment-manifest.json` — sanitized deployment-readiness contract
- `demo/assets/multicloud-runtime-manifest.json` — sanitized provider-runtime claim state
- `demo/live-mission-demo.html` — sanitized interactive Business/Politics mission surface using synthetic data and explicit authority/evidence boundaries\n- `demo/dominion-command-preview.html` — static Dominion Command for Politics cockpit preview using synthetic data, no connectors, and zero command authority
- `demo/assets/live-mission-video-manifest.json` — receipt-bound Business/Politics media state; rendered MP4 masters remain distinct from the public interactive demo
- `squarespace/demo-1-final.html` — canonical fail-closed Squarespace `/demo-1` presentation artifact
- `demo/assets/offline-preview-download.json` - pending release record for the separate free synthetic Business/Politics offline preview; no public download URL is configured
- `demo/saas-suite-offline-preview.html` - self-contained synthetic examples for all 13 catalogue modules in Business and neutral civic administration modes; no actual SaaS implementation or general-availability claim
- `demo/assets/saas-offline-preview-download.json` - pending release record for the separate free SaaS catalogue preview; no public download URL is configured

No implementation/runtime/configuration/provider-authentication artifact is approved for the current public tree. The only public automation retained is the minimal static Pages publisher for the approved artifact bundle.

Private source, credentials, signing material, customer data, payment data, private APIs, operational keys, internal automation, infrastructure definitions, production controls, and private service authority do not belong in this repository.

## Claim discipline

Deployment readiness and public-runtime availability are separate claims. The public demo fails closed: **no cloud provider is labelled live unless a separate fresh machine-produced certificate proves health, a named revision, and exact release binding.**

The current static proof surface may remain available even when no optional public provider runtime is certified live.

The offline preview candidate contains only public presentation files and synthetic data. It does not include or certify the native Dominion product, core runtime, SaaS, connectors, or Google deployment. Its packaging contract is in `docs/OFFLINE_PREVIEW_RELEASE.md`. Google certification comes first; exact preview-artifact acceptance and approved public activation follow. Historical native Windows signing and release gates are separate.

The separate SaaS Suite preview covers all 13 catalogue entries with fixed, interactive examples. It preserves each module's catalogue state, including Coming Soon, and does not distribute or certify the actual modules. Its four-file archive, source binding, approval/Hold behavior, and pending release gates are described in `docs/SAAS_OFFLINE_PREVIEW_RELEASE.md`. This candidate adds no Pages publisher route and leaves the pending Squarespace source and download activation unchanged.

## Public routes

- Public proof: https://fractal5-solutions.github.io/dominion-os-demo-build/\n- Dominion Command public-safe preview: https://fractal5-solutions.github.io/dominion-os-demo-build/demo/dominion-command-preview.html
- Dominion OS™: https://www.fractal5solutions.com/dominion-os
- Fractal5 demo bridge: https://www.fractal5solutions.com/demo-1
- Deployment contact: https://www.fractal5solutions.com/#contact

Security concerns should be reported privately as described in `SECURITY.md`.


## Publication contract

GitHub Pages is published from protected `main` by the minimal `.github/workflows/publish-artifact-only-pages.yml` workflow. It copies only the approved public artifacts into the Pages bundle and validates the synthetic-data, authority, and connector-claim boundaries before deployment. Provider authentication, IAM repair, cloud deployment, and private runtime workflows are deliberately excluded from this public repository.

The command preview is explicitly non-authoritative: it contains synthetic data only, performs no external browser networking, and has no private runtime or campaign connection.\n\nThe canonical Squarespace page remains `squarespace/demo-1-final.html`; the principal pastes that finished artifact into Squarespace. Squarespace is not the source repository and is not mutated by this workflow.

The pending Google-first Squarespace candidate is `squarespace/demo-1-v2.5-google-first-preview-pending.html`, bound to the moving alias by `squarespace/demo-1-v2.5-handoff.json`. Its three offline preview download buttons stay disabled. No accepted Google certificate adapter exists yet; adding one requires a reviewed source change after genuine Google certification and exact preview-artifact acceptance. Older handoffs remain historical records.
