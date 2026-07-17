#!/usr/bin/env bash
# Simple helper that lists likely secret files and shows git history lines for review.
set -euo pipefail
REPO_ROOT="$(dirname "$(dirname "$0")")"
echo "Scanning for committed secret-like files..."
grep -RIn --exclude-dir=.git -E "ghp_|sk_(live|test)|AKIA|AIza|xox[baprs]-|-----BEGIN|POSTGRES_PASSWORD|FLASK_SECRET_KEY|GITHUB_TOKEN" || true
echo
echo "To securely remove a tracked secret from history, use git filter-repo or BFG."
echo "Example (requires backup and repo permissions):"
echo "  git clone --mirror <repo> repo.git"
echo "  bfg --delete-files .env repo.git"
echo "  cd repo.git && git reflog expire --expire=now --all && git gc --prune=now --aggressive"
echo "  git push --force"
