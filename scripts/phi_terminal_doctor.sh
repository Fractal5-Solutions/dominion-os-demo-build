#!/usr/bin/env bash
set -euo pipefail

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

if [[ ! -t 1 ]]; then
  GREEN=''
  YELLOW=''
  RED=''
  NC=''
fi

ok() { echo -e "${GREEN}✓${NC} $*"; }
warn() { echo -e "${YELLOW}⚠${NC} $*"; }
err() { echo -e "${RED}✗${NC} $*"; }

issues=0

echo "PHI Terminal Doctor"
echo "==================="
echo ""

ok "Date: $(date -Iseconds)"
ok "User: $(id -un) (uid=$(id -u))"
ok "Shell: ${SHELL:-unknown}"
ok "TERM: ${TERM:-unknown}"
ok "PWD: $(pwd)"
echo ""

ok "Bash: $(bash --version | head -n 1)"

if command -v pwsh >/dev/null 2>&1; then
  psver="$(pwsh -NoLogo -NoProfile -Command '$PSVersionTable.PSVersion.ToString()' 2>/dev/null || true)"
  ok "PowerShell (pwsh): ${psver:-unknown}"
else
  warn "PowerShell (pwsh) not found (VS Code PowerShell terminals may fail/close)"
  issues=$((issues + 1))
fi

if command -v powershell >/dev/null 2>&1; then
  ok "PowerShell alias: $(command -v powershell)"
fi

echo ""

# Check whether interactive bash inherits `errexit` (set -e). If this is ON, any
# failing command can abruptly terminate the shell, making terminals “close”.
errexit_state="$(
  bash -ic 'set -o' 2>/dev/null | awk '$1=="errexit"{print $2; exit}'
)"

if [[ "${errexit_state:-unknown}" == "on" ]]; then
  err "Interactive bash starts with 'errexit=on' (this can make terminals close on non-zero exits)"
  issues=$((issues + 1))
else
  ok "Interactive bash 'errexit': ${errexit_state:-unknown}"
fi

startup="/workspaces/dominion-command-center/.phi/startup.sh"
if [[ -f "$startup" ]]; then
  if grep -Eq '^[[:space:]]*set[[:space:]]+-e\b' "$startup"; then
    err "Startup script enables 'set -e': $startup"
    issues=$((issues + 1))
  else
    ok "Startup script does not enable 'set -e': $startup"
  fi
else
  warn "Startup script missing: $startup"
fi

echo ""

if [[ "$issues" -gt 0 ]]; then
  err "Found $issues issue(s). Fix these to stop terminals from closing."
  exit 1
fi

ok "All checks passed."
