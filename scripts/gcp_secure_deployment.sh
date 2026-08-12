#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: SECURE GCP DEPLOYMENT REFUSED

This public repository may not create deployment source, configure cloud projects,
read or bind production secrets, or deploy Phi/Dominion services.

Use the private Phi command surface for governed deployment. Public proof artifacts remain
non-commanding and sandbox-only.
EOF

exit 2
