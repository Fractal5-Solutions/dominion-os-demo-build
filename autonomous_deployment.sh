#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: AUTONOMOUS DEPLOYMENT REFUSED

This public repository may not commit or force-update branches, deploy Dominion services,
or exercise autonomous live-operations authority.

Phi remains the sole Dominion command service. Source mutation and deployment belong in
private Phi-governed workflows with policy gates, review, and receipts.
EOF

exit 2
