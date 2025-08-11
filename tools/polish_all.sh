#!/usr/bin/env bash
set -euo pipefail
echo "== POLISH: starting =="

# Python formatters
if command -v python3 >/dev/null; then
  python3 -m pip install --upgrade pip >/dev/null 2>&1 || true
  python3 -m pip install black isort mdformat[plugins] -q || true
  python3 -m black . || true
  python3 -m isort . || true
  python3 -m mdformat . || true
fi

# Shell format
if ! command -v shfmt >/dev/null; then
  sudo apt-get update -y >/dev/null 2>&1 || true
  sudo apt-get install -y shfmt >/dev/null 2>&1 || true
fi
if command -v shfmt >/dev/null; then
  find . -type f \( -name "*.sh" -o -name "*.bash" \) -print0 | xargs -0 -r shfmt -w -s || true
fi

# Web / json / yaml / md
if command -v node >/dev/null; then
  npx --yes prettier@3 --write "**/*.{js,jsx,ts,tsx,css,scss,md,mdx,json,yml,yaml,html}" || true
fi

git add -A
if [ -n "$(git diff --cached --name-only)" ]; then
  echo "== POLISH: changes staged =="
else
  echo "== POLISH: no changes =="
fi
