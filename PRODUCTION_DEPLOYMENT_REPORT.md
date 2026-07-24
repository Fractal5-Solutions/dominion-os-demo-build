# Archived Production Deployment Report Notice

**Archived:** 2026-07-24  
**Status:** superseded for public claims  
**Current doctrine:** [`MINIMUM_SPEND_PUBLIC_DEMO_MODE.md`](MINIMUM_SPEND_PUBLIC_DEMO_MODE.md)  
**Current claim boundary:** [`DOMINION_OS_DEPLOYMENT_PROOF.md`](DOMINION_OS_DEPLOYMENT_PROOF.md)

## Decision

This historical deployment report is no longer an active liveops or infrastructure claim.

Earlier versions described always-warm services, high scaling limits, broad service health, automatic rollback, real-time logs, and perfect liveops. Those statements must not be treated as current public proof unless fresh receipts support them.

## Current public-demo posture

- `/demo-1` remains protected as the public proof bridge.
- Default status endpoints should be lightweight.
- Remote probes should run only on deliberate operator request.
- Expensive AI/model work should not run by default.
- Noncritical infrastructure should avoid always-warm assumptions.
- Claims must remain public-safe and receipt-gated.

## Replacement guidance

Use [`RUNBOOK_STATUS_PROBES.md`](RUNBOOK_STATUS_PROBES.md) for probe semantics. Use [`MINIMUM_SPEND_PUBLIC_DEMO_MODE.md`](MINIMUM_SPEND_PUBLIC_DEMO_MODE.md) for current operating doctrine.

Keep the demo alive. Put the expensive machinery to sleep.
