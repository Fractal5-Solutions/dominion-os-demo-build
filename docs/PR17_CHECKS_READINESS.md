# PR #17 - Checks Readiness

This document tracks the readiness state for required checks and review threads.

## Latest commits
- WebGL2 shader compile/link checks corrected (gl.COMPILE_STATUS, gl.LINK_STATUS)
- VS Code settings modernized (Ruff lint on save, Black default formatter)
- Terrain viewer input sanitization and deduped fetch for assets

## Required checks
- governance-suite: EXPECTED → will rerun on latest commit
- CodeQL: should pass (no JS/Python/C# high severity findings expected)
- proof-html: expected to pass for web docs

## Actions
- Mark review threads resolved in PR UI (shader constant correction addressed)
- Re-run governance-suite if not automatically triggered
- After all checks green, proceed with squash-merge

## Notes
If checks do not appear for the latest SHA, manually trigger workflow rerun from PR UI or via API using a token with `repo:workflow` scope.