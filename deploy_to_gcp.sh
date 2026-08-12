#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: GCP DEPLOYMENT REFUSED

This public repository may not authenticate to production cloud projects, enable APIs,
submit source builds, or deploy Dominion services.

Route deployment through the private Phi command surface with explicit policy gates and receipts.
EOF

exit 2
