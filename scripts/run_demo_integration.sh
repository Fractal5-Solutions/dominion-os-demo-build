#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. Relationship/CRM demo
integration that depends on private business data or private-system pipelines is
not permitted here. Public proof must use static, synthetic, public-safe
artifacts only.

No private data was read or written and no integration workflow was executed.
EOF

exit 2
