# /demo-1 execution report - ChatGPT sandbox - 2026-06-16

## Summary

The live verifier was executed as far as this sandbox permits. The result is an environment-limited execution, not a Fractal5 runtime failure.

## Playwright execution

- Node available: v22.16.0
- npm available: 10.9.2
- Python Playwright available: installed
- Chromium path: `/usr/bin/chromium`
- Result: blocked by sandbox policy
- Evidence: Chromium launched, but even a local `data:text/html` navigation failed with `net::ERR_BLOCKED_BY_ADMINISTRATOR`. Because local navigation is blocked, the live Squarespace page cannot be tested from this sandbox browser.

## Container network execution

`curl` checks were attempted for:

- `https://www.fractal5solutions.com/demo-1`
- `https://demo-reduwyf2ra-uc.a.run.app/demo`
- `https://demo-reduwyf2ra-uc.a.run.app/health`
- `https://demo-reduwyf2ra-uc.a.run.app/status`
- `https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/demo-manifest.json`

Result: container DNS could not resolve these hosts.

## Web-layer execution

The web layer was able to open the raw GitHub public demo assets:

- `demo-manifest.json`
- `sample-data.json`
- `demo-download-package.json`
- `release-receipts.json`

Verified public-asset posture:

- Manifest declares public-safe demo assets and Cloud Run runtime routes.
- Sample data declares no production/customer/payment data and is public-safe.
- Demo package declares it is a public demo package, not a private runtime/source bundle.
- Release receipts are present and keep full-commercial claims bounded.

The web layer could not directly open the Squarespace or Cloud Run URLs in this turn because the tool requires either a search result or a URL supplied in the current user message.

## Required real execution

Run the committed verifier from an unrestricted Ultimate Stack/local machine:

```bash
npm install -D playwright
npx playwright install chromium
node tools/verify-demo1-live.mjs
```

Optional branded-domain pass after DNS/TLS is confirmed:

```bash
CHECK_BRANDED_DOMAIN=1 node tools/verify-demo1-live.mjs
```

## Conclusion

- Repo-side verifier: present.
- ChatGPT sandbox execution: attempted and environment-limited.
- Public asset layer: reachable through web layer and public-safe.
- Live DOM verification: must be completed from an unrestricted browser environment.
