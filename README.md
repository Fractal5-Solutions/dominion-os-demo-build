# Dominion OS™ public demo artifacts

This repository is the deliberately minimal public-proof surface for **Dominion OS™ + SaaS Suite**.

It is **not** the Dominion OS source repository, an operator console, a deployment repository, or a production control plane.

## Public artifact contract

Current `main` is limited to public presentation and sanitized proof material:

- `index.html` — static public demonstration
- `404.html` — fail-closed route handling
- `.nojekyll` — static hosting marker
- `README.md` — public boundary description
- `SECURITY.md` — disclosure and repository-safety policy
- `demo/assets/cloud-deployment-manifest.json` — sanitized deployment-readiness contract
- `demo/assets/multicloud-runtime-manifest.json` — sanitized provider-runtime claim state

Private source, credentials, signing material, customer data, payment data, private APIs, operational keys, internal automation, infrastructure definitions, production controls, and private service authority do not belong in this repository.

## Claim discipline

Deployment readiness and public-runtime availability are separate claims. The public demo fails closed: **no cloud provider is labelled live unless a separate fresh machine-produced certificate proves health, a named revision, and exact release binding.**

The current static proof surface may remain available even when no optional public provider runtime is certified live.

## Public routes

- Public proof: https://fractal5-solutions.github.io/dominion-os-demo-build/
- Dominion OS™: https://www.fractal5solutions.com/dominion-os
- Deployment contact: https://www.fractal5solutions.com/#contact

Security concerns should be reported privately as described in `SECURITY.md`.