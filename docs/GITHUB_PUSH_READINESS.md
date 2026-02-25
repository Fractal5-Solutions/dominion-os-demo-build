# GitHub Push Readiness (Dominion OS Demo Build)

This repo uses sovereign CI practices and may enforce organization SSO or protected branches. To enable pushes and CI dispatch:

## Token

Use a fine‑grained GitHub token and add it to your environment.

Required permissions on `Fractal5-Solutions/dominion-os-demo-build`:

- Contents: write
- Repository: workflows (for CI dispatch) — optional but recommended

If your organization uses SSO, go to the token page and click “Authorize” under the organization.

Export token or place in `.env`:

```
GH_TOKEN=ghp_XXXXXXXXXXXXXXXXXXXXXXXXXXXX
GH_OWNER=Fractal5-Solutions
GH_REPO=dominion-os-demo-build
```

## Branch protection

If `main` is protected, push to a feature branch and open a PR:

```
git checkout -b copilot/push-readiness
git push -u origin copilot/push-readiness
```

## Troubleshooting

- 403 “Permission denied to <org>”: authorize the token via SSO and ensure Contents: write on the repo.
- Classic tokens show global scopes; fine‑grained tokens show repo-specific permissions.
- If HTTPS continues to fail, configure SSH and add a deploy key with write access.

## Sovereign alignment

- Prefer least‑privilege fine‑grained tokens bound to the org.
- Use branch PRs if main is protected.
- Avoid embedding tokens in remote URLs; use environment variables only.
