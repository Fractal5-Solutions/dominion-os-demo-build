#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: PRODUCTION DEPLOYMENT REFUSED

This public repository may not deploy Dominion services, expose production services,
or exercise autonomous production authority.

Phi is the sole Dominion command service. Production operations belong in the private,
authenticated, receipt-backed Phi runtime.
EOF

exit 2
