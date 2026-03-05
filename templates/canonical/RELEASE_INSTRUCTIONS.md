# Canonical Release Instructions

This repository follows a minimal, repeatable release skeleton:

- `release/release_plan.json` (release intent + approvals)
- `RELEASE_INSTRUCTIONS.md` (this document)
- `secrets.example` (placeholders only; never commit real secrets)

## Standard Release Flow

1. Update `release/release_plan.json` with the target version/tag and planned artifacts.
2. Run tests and linters locally (or ensure CI passes on the release branch).
3. Generate release artifacts (packages, container images, manifests) as applicable.
4. Generate an SBOM if the repo produces deployable artifacts.
5. Obtain required approvals and record them in `release/release_plan.json`.
6. Tag the release and create a GitHub Release from that tag.

## Safety

- Do not commit `.env` files, keys, tokens, certificates, or exported credentials.
- Keep `secrets.example` as placeholders only.
