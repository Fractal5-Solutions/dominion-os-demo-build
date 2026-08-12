#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. Apollo, CRM, BIMS,
credential-bearing integrations, private pipeline configuration, and cloud
business-system orchestration belong in governed private systems and are
intentionally unavailable here.

No API call, credential read, business-data write, monitoring setup, report
publication, or cloud mutation was attempted.
EOF

exit 2
