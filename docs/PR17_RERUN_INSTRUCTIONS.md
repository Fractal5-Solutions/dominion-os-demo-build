# PR #17 Rerun Instructions

To rerun required checks for PR #17:

1. Open the PR: https://github.com/Fractal5-Solutions/dominion-os-demo-build/pull/17
2. In the PR UI, click “Re-run jobs” for the governance-suite workflow (if present)
3. Ensure CodeQL and proof-html (if applicable) are re-run
4. After checks pass, resolve review threads and squash-merge

If “Re-run” is not available, use a token with `repo:workflow` scope to dispatch workflows via API.
