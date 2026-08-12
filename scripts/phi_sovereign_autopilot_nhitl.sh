#!/bin/bash
# Public proof-lane compatibility shim.
# Historical autonomous runtime behavior has been removed from this public repo.

set -euo pipefail

cat <<'EOF'
Phi public proof boundary: NON-COMMANDING / ENFORCED.

This public repository does not start Phi MCP, inspect private cloud accounts,
change cloud projects, control Docker/private services, or execute Dominion
runtime operations.

Phi is the sole Dominion command service. Sovereign/autonomous operations belong
inside the private PhiOps authority surface and must transit Phi's governed MCP
capabilities, policy gates, authorization thresholds, and receipt ledger.
EOF

exit 0
