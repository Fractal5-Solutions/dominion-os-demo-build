# Environment Placeholders (Local Dev)

When running the demo build locally, you may want to set a few environment variables. Create a `.env` file at the repo root (not committed) and populate:

- PYTHONPATH=../dominion-os-1.0
- AI_GATEWAY_URL=http://localhost:8082
- DOMINION_DEMO_CONFIG=dev
- GH_TOKEN=
- GITHUB_TOKEN=
- GCLOUD_PROJECT=

Notes:
- The demo build imports sibling `dominion-os-1.0`; `PYTHONPATH` ensures local imports resolve.
- `AI_GATEWAY_URL` should point to your locally running Gateway on port 8082.
- Export `GH_TOKEN`/`GITHUB_TOKEN` in your shell for CI actions if needed.
