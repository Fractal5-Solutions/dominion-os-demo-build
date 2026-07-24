# Archived Production Readiness Proof Notice

**Archived:** 2026-07-24  
**Status:** superseded for public claims  
**Current doctrine:** [`MINIMUM_SPEND_PUBLIC_DEMO_MODE.md`](MINIMUM_SPEND_PUBLIC_DEMO_MODE.md)  
**Current claim boundary:** [`DOMINION_OS_DEPLOYMENT_PROOF.md`](DOMINION_OS_DEPLOYMENT_PROOF.md)

## Decision

This historical proof file is no longer an active public certification or production-readiness claim.

Earlier versions described a broad live production estate, always-warm Cloud Run services, high maximum scaling, all-systems-operational language, and certification-style conclusions. That posture conflicts with the current cost doctrine and may overstate the earned evidence boundary.

## Current public-safe statement

The public demo surface is a controlled client-acquisition demo. It should remain polished, public-safe, and easy to access, while the wider stack stays in Minimum Spend Mode.

## Minimum Spend compatibility

The preferred public-demo posture is:

- static or cached first impression;
- demo/sample data only;
- low-cost health and status endpoints;
- no default remote probes;
- no always-warm noncritical services;
- no premium model calls by default;
- stronger claims only with current receipts.

## Blocked inherited claims

Do not reuse this file to claim:

- `PRODUCTION READY - ALL CRITERIA MET`;
- `100% production ready`;
- `perfect liveops operational`;
- `all infrastructure verified`;
- `cleared for production traffic`;
- any tax-ready, audit-ready, certified, reconciled, or live-certified status.

## Demo carveout

Minimum Spend Mode must not degrade `/demo-1`. It should preserve the client-facing surface while shutting down unnecessary background cost.

Keep the demo alive. Put the expensive machinery to sleep.
