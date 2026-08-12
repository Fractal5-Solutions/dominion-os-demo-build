#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
REFUSED: NON-COMMANDING public proof compatibility entrypoint.

This public repository is an artifact-only proof lane. Complete private
relationship, CRM, BIMS, credential, or cloud integration execution belongs in
governed private systems and is intentionally unavailable here.

No credential was read, no private integration was started, and no cloud or
business-system mutation was attempted.
EOF

exit 2
