#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: LIVEOPS DEPLOYMENT REFUSED

This public repository must not create service accounts, change IAM, enable cloud APIs,
deploy Command Center, deploy Dominion services, or act as a production control plane.

Phi is the sole Dominion command service. Use the private Phi runtime with policy gates,
least privilege, explicit approvals where required, and command receipts.
EOF

exit 2
