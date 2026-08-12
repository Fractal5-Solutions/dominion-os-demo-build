#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. Sovereign/live-ops
monitoring, automated maintenance, process control, cleanup, and private runtime
operations belong in governed private systems and are intentionally unavailable
here.

No process, file, runtime, repository, or cloud resource was modified.
EOF

exit 2
