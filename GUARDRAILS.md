# 🔒 Guardrails: Dominion OS Repository Protections

This repository is **sealed**. Guardrails are enforced at both **branch** and **tag** levels to ensure integrity of Dominion OS releases.

## ✅ Branch Protection (`main`)

- Required status checks: **build**, **test** must pass before merge.
- **Linear history only** — no merge commits.
- **Conversation resolution required** — all threads must be closed.
- **Pull Request Reviews**:
    - At least **1 approval** required.
    - Approver must not be the last pusher.

## 🏷️ Tag Protection

- All **release tags (`v*`)** are immutable:
    - ❌ No deletion.
    - ❌ No rewriting (no force-push).
- Once a release tag is cut, it is permanent.

## ⚖️ Merge Strategy

- **Squash merges only**.
- PR branch automatically deleted after merge.
- No merge commits, no rebases, no auto-merges.

## 🛡️ Self-Audit CI

- The repo contains a **Guardrails workflow** (`.github/workflows/guardrails.yml`).
- On every PR to `main` or `release/**`, the workflow asserts:
    - Required checks exist.
    - Linear history enforced.
    - Conversation resolution enforced.
- If protections drift, CI fails.

## 🪦 Immutable Guarantee

This repo is **entombed**:

- History cannot be rewritten.
- Releases cannot be undone.
- Every change passes through the gauntlet above.

Dominion OS stands as a **crypt of compliance** — every artifact is truth-aligned, irreversible, and sovereign.
