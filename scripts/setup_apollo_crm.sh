#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. Apollo/CRM ingestion,
credential-bearing business integrations, private CRM data writes, and cloud
service orchestration belong in governed private systems and are intentionally
unavailable here.

No API call, credential read, CRM write, cloud inspection, or deployment was
attempted.
EOF

exit 2
