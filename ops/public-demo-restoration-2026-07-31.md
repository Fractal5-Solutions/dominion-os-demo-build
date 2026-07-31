# Public demo restoration — 2026-07-31

## Incident

The Fractal5 `/demo-1` bridge currently advertises the public Google Cloud Run sandbox, while the canonical public runtime routes return HTTP 404:

- `/demo`
- `/health`
- `/status`

The source repository remains healthy and contains the expected Flask routes, production Docker entrypoint, OIDC deployment workflow, exact-release verification, security headers, no-store public receipts, and public-safe boundary controls.

## Authorized action

Merge of this documentation-only operational trigger is authorized to invoke the existing `Build & Deploy Public Demo (OIDC)` workflow on `main` and restore the canonical `demo` Cloud Run service in `us-central1` from the exact merged commit.

## Required proof

The deployment is complete only when the workflow proves all three routes return HTTP 200, `/health` and `/status` are JSON with `Cache-Control: no-store`, the public demo copy is claim-safe, and `releaseCandidateSha` equals the merged commit SHA.

## Boundaries

- No customer, payment, private source, secret, or production data is exposed.
- No new paid architecture is created; the existing scale-to-zero public demo service is reused.
- The deployment may not be described as successful from a build alone. The live route receipt is decisive.
