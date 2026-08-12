#!/bin/bash
# Public proof-lane verifier.
#
# This repository is a public build/proof surface. It must not start, install,
# stop, mutate, or directly command Phi MCP, Dominion OS, private Command Center
# services, cloud infrastructure, or production-like backing services.
#
# The historical filename is preserved for compatibility, but the behavior is
# intentionally verification-only.

set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

printf '%s\n' "============================================================"
printf '%s\n' "Dominion public proof-lane verifier"
printf '%s\n' "Mode: NON-COMMANDING / SANDBOX-ONLY"
printf '%s\n' "============================================================"

fail=0

check_file() {
  local path="$1"
  local label="$2"
  if [ -e "$path" ]; then
    printf 'PASS  %s\n' "$label"
  else
    printf 'INFO  %s not present: %s\n' "$label" "$path"
  fi
}

# Static proof checks only. No package installation, process start/stop,
# Docker mutation, private repository access, or MCP tool invocation occurs.
check_file "$ROOT_DIR" "proof repository root"
check_file "$ROOT_DIR/scripts" "proof scripts directory"

if command -v git >/dev/null 2>&1; then
  if git -C "$ROOT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    printf 'PASS  git worktree detected\n'
    git -C "$ROOT_DIR" status --short --untracked-files=no || true
  else
    printf 'INFO  git metadata unavailable in this build representation\n'
  fi
else
  printf 'INFO  git is not installed in this environment\n'
fi

cat <<'EOF'

Authority boundary:
- Phi is the sole Dominion command service.
- Phi MCP is Phi's governed command/capability surface.
- This public proof repository does not start or control Phi MCP.
- This public proof repository does not start or control Dominion services.
- Internal endpoints, credentials, signing material, production data, and
  private source are outside this repository's authority.

To operate the real ecosystem, use an authenticated Phi-authorized interface
and the private runtime/control-plane repositories. A public proof lane must
never be used as a bridge into those services.
EOF

exit "$fail"
