# Source-Control Automation Controlled Burn

## Purpose

This document binds demo-build source-control automation back to the existing Dominion OS source-code-first operating canon. It does not invent a parallel process. The source of truth for live AI operations is `Fractal5-Solutions/dominion-command-center`.

This lane is linked to issue #129 and supports the already-established goal that a human operator can command work in natural language while the system performs discovery, branch creation, patching, pull request creation, audit, evidence gathering, and merge-readiness analysis.

## Source-code-first authority

The operating model already exists in source:

- `docs/NHITL_AUTOPILOT.md` defines end-to-end non-human-in-the-loop automation, proof workflows, sidecar execution, and autopilot CI/orchestrator behavior.
- `docs/NHITL_FULL_AUTO.md` defines continuous NHITL services, health endpoint behavior, proof backfill, tuning, and self-heal tasks.
- `AUTOPILOT_README.md` defines autonomous watcher behavior, discovery, patch-stub generation, optimizer handoff, and PAT handling boundaries.

This repository should optimize and connect to that source canon rather than create new operational doctrine.

## Current baseline

The current demo-build baseline is PR #128 and issue #129.

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

1. Source code first. Read and use the existing system before proposing new process.
2. `dominion-command-center` is the Tier 1 control plane and source of truth.
3. `dominion-os-demo-build` remains a public demo surface repository with no private source, secrets, customer data, signing keys, payment systems, or internal services.
4. Do not force-push.
5. Do not write directly to `main`.
6. Do not change production surfaces from this lane.
7. Do not merge around red or unknown gates.
8. Treat `startup_failure` as blocked until it is repaired, reclassified with rationale, or escalated as a repository or organization policy issue.
9. Optimize toward live political and business operations, not endless demo/development loops.

## Phase 1: resolve PR #128 cleanly

Goal: get PR #128 to a clean, auditable posture while preserving the live demo bridge and moving past first-demo posture.

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

## Phase 2: connect demo-build to existing live-ops canon

Goal: bind demo-build automation evidence to existing NHITL/autopilot operations rather than inventing new process.

Actions:

- Use source discovery against `dominion-command-center` before adding new automation.
- Keep startup-policy auditing local and source-visible.
- Use gate classification and PR evidence output to feed the existing NHITL/autopilot loop.
- Record any repository settings that block source-controlled automation from becoming live operations.

Acceptance criteria:

- Automation health is visible in GitHub.
- Startup failures have a documented handling path.
- The health lane does not weaken security checks.
- The demo-build lane points back to command-center live ops, not away from it.

## Phase 3: self-healing evidence loop

Goal: make pull requests explain their own merge-readiness and become inputs to fully automated AI live operations.

Actions:

- Use gate classification semantics.
- Use startup-policy auditing for workflow `uses:` lines.
- Produce PR evidence reports with changed files, head SHA, workflow state, and merge doctrine.
- Feed repaired, verified PR evidence into the existing NHITL/autopilot execution path.

Acceptance criteria:

- Each PR can report changed files, head SHA, check states, gate classification, and merge doctrine.
- Red or unknown gates are never normalized as green.
- The system can recommend repair steps without hiding risk.
- Source-control automation supports live business and political operations.

## Stop conditions

Stop and report if any of the following occurs:

- A connector safety block prevents a required write.
- GitHub permissions prevent branch, run, or workflow operations.
- Required gates remain red or unknown after source-side repairs.
- A proposed action would expose secrets, weaken public-surface controls, bypass branch protection, or unexpectedly touch production.

## Operational target

The final target is a clean live-ops source-control loop:

1. Natural-language command.
2. Source discovery in command-center and repo-local files.
3. Minimal patch.
4. Pull request.
5. Automated checks.
6. Evidence report.
7. Doctrine-based merge-readiness decision.
8. Hand off green evidence to existing NHITL/autopilot live-ops execution.
9. Merge only when clean.
