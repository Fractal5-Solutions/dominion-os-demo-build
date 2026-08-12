#!/usr/bin/env bash
set -euo pipefail

cat >&2 <<'EOF'
PUBLIC PROOF LANE: OAUTH REPAIR DEPLOYMENT REFUSED

This public repository may not modify OAuth runtime source, rebuild containers, bind service
accounts, inspect production logs, or deploy Phi services.

OAuth repair and deployment authority belongs to the private Phi-governed runtime with
least privilege, explicit policy gates, and receipts.
EOF

exit 2
