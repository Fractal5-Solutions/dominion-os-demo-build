#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: DEPLOYMENT REFUSED

This repository is a non-commanding public proof/build surface.
It must not enable cloud APIs, modify IAM, build from private source, or deploy Dominion services.

Phi is the sole Dominion command service. Deployment belongs in a private, authenticated,
receipt-backed Phi workflow governed by Dominion Command Center policy.
EOF

exit 2
