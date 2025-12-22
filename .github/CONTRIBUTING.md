# Contributing to Dominion OS Demo Build

## Prerequisites
- Python 3.10+
- `python -m venv .venv && source .venv/bin/activate`

## Workflow
1. Branch off `main` (or the appropriate chore branch).
2. Run tests: `pytest -q`.
3. Keep commits clean; avoid vendor files.
4. Open a PR using the repo’s PR template.

## Style
- Black format, Ruff lint (see `.vscode/extensions.json`).
- Markdown lint configured via workspace settings.

## CI & tokens
- If workflows are dispatched, ensure `GH_TOKEN` has `repo, workflow` scopes.
