# VS Code Setup — Dominion OS Demo Build

This guide keeps the demo build workspace aligned with Dominion OS for a stable, efficient developer experience.

## Recommended extensions

- Python + Pylance + Black: `ms-python.python`, `ms-python.vscode-pylance`, `ms-python.black-formatter`
- Ruff lint: `charliermarsh.ruff`
- GitHub Copilot + Actions: `github.copilot`, `github.copilot-chat`, `github.vscode-github-actions`
- YAML + Prettier + Markdown lint: `redhat.vscode-yaml`, `esbenp.prettier-vscode`, `DavidAnson.vscode-markdownlint`
- Optional (Node/JS): `dbaeumer.vscode-eslint`, `yzhang.markdown-all-in-one`, `streetsidesoftware.code-spell-checker`

## Settings highlights

Workspace settings under `.vscode/settings.json` enable:

- Pytest, Black, Ruff
- Format on save
- Excludes for venv, cache, dist
- Markdown lint basics

## Repo hygiene

- `.npmrc` and `.nvmrc` included (Node 20 LTS target)
- Prefer keeping vendor artifacts out of commits
- Use pre‑commit in the main OS repo; demo build runs pytest before publishing

## CI & tokens

- If demo workflows need dispatch: use `GH_TOKEN` with `repo, workflow` scopes (via GitHub App token or PAT)

## Troubleshooting

- If extension prompts don’t appear, check recommendations in `.vscode/extensions.json`
- For YAML/Markdown lint issues, run formatters or adjust rules in `markdownlint.config`
