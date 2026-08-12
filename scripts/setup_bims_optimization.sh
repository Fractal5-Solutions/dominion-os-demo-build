#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. BIMS optimization,
private business intelligence data handling, BigQuery mutations, and cloud
service orchestration belong in governed private systems and are intentionally
unavailable here.

No dataset, table, private data, dashboard, cloud service, or deployment was
created, modified, queried, or published.
EOF

exit 2
