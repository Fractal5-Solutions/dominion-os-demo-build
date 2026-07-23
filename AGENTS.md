# dominion-os-demo-build — Codex Instructions

## Operating Role

Codex is the engineering execution surface for this repo. GitHub is source
control and proof. Matthew retains final production authority. This repo is the
public-safe serving surface only — it is NOT control-plane or runtime authority.

## Workspace

- Remote: Fractal5-Solutions/dominion-os-demo-build
- Default/protected branch: `main` (PR-only)
- OS/shell: Windows/PowerShell; Python (`requirements.txt`).
- WSL `/mnt/d/phi-ops` only for Linux-native paths. VS Code optional.

## Context Intake

1. This `AGENTS.md` -> 2. `README.md` -> 3. `.github/workflows/*` -> 4. targeted `rg`.

## Commands

- Install: `pip install -r requirements.txt` (operator-approved env)
- Test: `test-minimal.yml`, `canon-phi-validation.yml`
- Security: `secret-scan.yml`, `security-scan.yml`, `codeql.yml`
- Launch gate: `full-commercial-launch-gate.yml`

## Deploy

- Deploy workflows: `cicd-deploy.yml`, `production-deploy.yml`, `cloudrun-private-gate.yml`
  — manual dispatch, env-protected, operator-approved. Public-serving target.
- Rollback: redeploy prior signed tag; simulate first.

## Editing Rules

- Feature branch off `main`; draft PR early. Preserve unrelated dirty changes; keep scoped.
- Production, public release, secrets, paid APIs, GCloud/Cloud Run, Codespaces, paid
  runners, and destructive actions require operator approval.
- Never introduce control-plane logic or secrets into this public-safe repo.

## Secrets

- Reference by name/location only; never reproduce values.

## Definition of Done

- Security scans clean + launch-gate green + diff reviewed + conventional-commit PR;
  public release additionally requires operator approval.

## Boundaries

Global charter: `D:\phi-ops\docs\codex-charter\00-CODEX-OPERATING-CHARTER.md`;
cost guardrails: `05-COST-AND-AUTHORITY-GUARDRAILS.md`. GitHub Copilot excluded.