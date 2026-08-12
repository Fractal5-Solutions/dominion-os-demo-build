#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository may be scanned for secret exposure, but secret
remediation, history mutation, destructive cleanup, credential rotation, and
force-push operations belong in governed private/admin workflows and are
intentionally unavailable here.

No file, history, branch, credential, or remote repository state was modified.
EOF

exit 2
