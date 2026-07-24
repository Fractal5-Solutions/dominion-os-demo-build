# Dominion OS Demo Build

Public-facing demo service repository for Dominion OS.

## Purpose

- Hosts demo UX and supporting demo APIs.
- Demonstrates `dominion-command-center` capabilities in a marketable SaaS presentation.
- Focuses on public-safe business overlays only for this stream.

## Minimum Spend Public Demo Mode

Minimum Spend Mode is active for the wider Fractal5 / Dominion OS stack.

This does **not** remove or weaken the public demo surface. `/demo-1` remains a protected client-acquisition asset. The demo should make the first impression with static, cached, pre-rendered, and demo-only material wherever possible, while avoiding background AI processing, speculative cloud scans, always-warm infrastructure, or premium model calls unless a paying client, scheduled demo, or explicit approval justifies them.

See [`MINIMUM_SPEND_PUBLIC_DEMO_MODE.md`](MINIMUM_SPEND_PUBLIC_DEMO_MODE.md).

## Core Demo Capabilities

- Dominion OS Core and top feature walkthroughs.
- Google Cloud SaaS integration surface for demo scenarios.
- Shapefile mapping workflows for geo/business visualization.
- Google API integrations for broader cloud-universe demonstrations.

## Governance

- This repo is serving-only and non-authoritative.
- Control plane and source-of-truth runtime authority remains in `dominion-command-center`.
- Demo content in this repo is intended for public presentation use.
- Production demo packaging must remain public-safe: no secrets, no tokens, no CRM/contact dumps, and no plain-source runtime payload in the final demo image.
- Public claims must stay receipt-gated and must not rely on stale proof language.

## Proof Artifacts

- `DOMINION_OS_DEPLOYMENT_PROOF.md`
- `MINIMUM_SPEND_PUBLIC_DEMO_MODE.md`
- `OPTIMAL_DEPLOYMENT_PROOF.md` *(archived notice; superseded for public claims)*
- `PRODUCTION_READINESS_PROOF.md` *(archived notice; superseded for public claims)*

## Runbook Notes

- Probe semantics for `/status` and `/api/v1/topology` are documented in `RUNBOOK_STATUS_PROBES.md`.
