# Source-Control Automation Controlled Burn

## Purpose

This document defines the controlled burn for stabilizing source-control automation in this repository. It is linked to issue #129 and supports the goal that a human operator can command source-control work in natural language while the system performs branching, patching, pull request creation, audit, evidence gathering, and merge-readiness analysis.

## Current baseline

The current controlled-burn baseline is PR #128 and issue #129.

Known state at burn start:

- PR #128 contains demo source hardening for `squarespace/demo-1-final.html`.
- PR #128 also contains workflow repairs for `dependency-review.yml` and `codeql.yml`.
- Four workflows have produced success evidence on the current head:
  - `Canon Phi v1.0 Color Compliance`
  - `governance-suite`
  - `Security Scan`
  - `PHI + MCP CI/CD Pipeline`
- `dependency-review` and `codeql` have reported `startup_failure` before jobs on the current head.

## Doctrine

1. Do not force-push.
2. Do not write directly to `main`.
3. Do not change production surfaces from this lane.
4. Do not merge around red or unknown gates.
5. Treat `startup_failure` as blocked until it is repaired, reclassified with rationale, or escalated as a repository or organization policy issue.
6. Preserve the public-surface policy: public demo assets only, no secrets, no private APIs, no customer data, no payment systems, no signing keys, and no operational credentials.

## Phase 1: resolve PR #128 cleanly

Goal: get PR #128 to a clean, auditable posture.

Actions:

- Preserve the source hardening already present.
- Preserve valid workflow repairs already present.
- Keep required PR gates limited to checks that schedule and produce evidence.
- Treat CodeQL as a trusted-source scan if PR startup continues to be blocked by repository policy.
- Record final gate evidence in PR #128.

Acceptance criteria:

- Required PR gates are green or explicitly reclassified with rationale.
- Startup failures are not treated as success.
- No production change is included.
- No merge occurs unless the gate posture is clean under this doctrine.

## Phase 2: automation-health lane

Goal: make automation health visible and auditable.

Actions:

- Add an Actions startup smoke test if workflow-file creation is permitted.
- Document the difference between a job failure and a startup failure.
- Update stale Actions incident documentation to reflect the current narrower state.
- Record owner or administrator settings that may need manual verification.

Acceptance criteria:

- Automation health is visible in GitHub.
- Startup failures have a documented handling path.
- The health lane does not weaken security checks.

## Phase 3: self-healing evidence loop

Goal: make pull requests explain their own merge-readiness.

Actions:

- Add gate classification semantics.
- Add a PR evidence report format.
- Add repair recommendation behavior for blocked checks.
- Add a standard source-control automation operating template.

Acceptance criteria:

- Each PR can report changed files, head SHA, check states, gate classification, and merge doctrine.
- Red or unknown gates are never normalized as green.
- The system can recommend repair steps without hiding risk.

## Stop conditions

Stop and report if any of the following occurs:

- A connector safety block prevents a required write.
- GitHub permissions prevent branch, run, or workflow operations.
- Required gates remain red or unknown after source-side repairs.
- A proposed action would expose secrets, weaken public-surface controls, bypass branch protection, or unexpectedly touch production.

## Operational target

The final target is a clean source-control loop:

1. Natural-language command.
2. Branch creation.
3. Minimal patch.
4. Pull request.
5. Automated checks.
6. Evidence report.
7. Doctrine-based merge-readiness decision.
8. Merge only when clean.
