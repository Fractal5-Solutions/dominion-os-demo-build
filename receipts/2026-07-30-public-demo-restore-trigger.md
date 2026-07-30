# Public demo restoration trigger — July 30, 2026

## Purpose

Trigger the repository's existing governed OIDC deployment workflow from a reviewed `main` commit so the public Cloud Run reference service can be rebuilt, redeployed, and judged by its own `/demo`, `/health`, and `/status` receipt contract.

## Pre-deployment evidence

At the time of this trigger, all three public routes returned HTTP 404 while the live Squarespace bridge still described the service as live.

## Governing workflow

`.github/workflows/cicd-deploy.yml` must:

1. authenticate through the configured Workload Identity Federation boundary;
2. submit `cloudbuild.yaml` for service `demo` in `us-central1`;
3. deploy the public-safe production image with unauthenticated ingress;
4. require HTTP 200 from `/demo`, `/health`, and `/status`;
5. require `no-store` on health and status receipts;
6. require the runtime release SHA to equal the triggering commit;
7. fail rather than claim success when any proof is absent.

## Safety and cost boundary

This file changes no application code, secret, permission, service configuration, or marketing claim. Deployment remains gated by the existing repository variable and WIF secrets. Cloud Run remains minimum-spend compatible with scale-to-zero behavior.
