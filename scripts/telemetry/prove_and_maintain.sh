#!/bin/bash
# Public proof-lane compatibility shim.
# Historical runtime maintenance behavior has been removed from this public repo.

set -euo pipefail

cat <<'EOF'
Phi proof-lane status: NON-COMMANDING.

This public repository does not restart Phi MCP, start monitors, mutate runtime
telemetry, inspect private process state, or maintain Dominion services.

Phi is the sole Dominion command service. Runtime proof and maintenance must be
performed through an authenticated Phi-authorized interface in the private
PhiOps/runtime authority surface, with policy decisions and receipts.
EOF

exit 0
