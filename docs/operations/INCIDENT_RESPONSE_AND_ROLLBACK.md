# Dominion OS™ + SaaS Suite — Incident Response and Rollback

## Operating objective

Detect, contain, recover, communicate, and learn without exposing secrets or overstating automation.

## Severity

- **SEV-1:** broad outage, confirmed data exposure, unauthorized privileged access, or material customer harm.
- **SEV-2:** major degradation, failed deployment, repeated errors, or loss of an important commercial function.
- **SEV-3:** limited defect with a workaround and no confirmed security or data impact.

## Response sequence

1. Open a private incident record with UTC start time, reporter, affected service, current revision, and known customer impact.
2. Assign an incident commander and technical owner.
3. Preserve relevant logs, metrics, deployment metadata, and public-safe health receipts.
4. Contain the issue: disable the affected function, restrict traffic, revoke compromised access, or freeze deployments as appropriate.
5. Decide recovery: configuration repair, forward fix, or rollback.
6. Verify `/health`, `/status`, core customer path, access controls, and public claim boundaries after recovery.
7. Communicate status through the approved customer/support channel.
8. Record resolution, contributing factors, corrective actions, owners, and due dates.

## Cloud Run rollback procedure

Before any commercial deployment, record the current stable revision and traffic allocation. A rollback must:

1. identify the last verified revision;
2. move traffic to that revision through the authorized Cloud Run project and service;
3. verify the revision identity and image digest;
4. confirm fresh health/status timestamps;
5. run the public proof verifier;
6. confirm customer access and entitlement behavior;
7. record operator, UTC time, reason, command or console action, outcome, and receipt locations.

No rollback command may be executed until the authoritative project, region, service, and revision are confirmed. Repository prose is not authority for an unknown live service.

## Recovery validation

Recovery is complete only when:

- route and asset probes pass;
- security and public-boundary checks pass;
- no stale or unsupported MP4, commerce, portal, observability, or autonomous-operation claim remains;
- customer-impact assessment is recorded;
- follow-up actions have owners.

## Evidence gate

The rollback and incident-response gate becomes GREEN after one authorized non-production exercise or real incident produces a public-safe redacted receipt showing detection, decision, rollback or recovery, verification, and review. A written runbook alone is readiness evidence, not execution evidence.