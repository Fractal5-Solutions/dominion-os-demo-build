#!/bin/bash
# PHI Automated Continuous Improvement & Hardening
# Runs all scans, applies fixes, and triggers deployment

set -euo pipefail

BASE_DIR="/workspaces/dominion-command-center"
SCRIPT="/workspaces/dominion-os-demo-build/scripts/phi_ai_continuous_improvement.sh"

cd "$BASE_DIR"
echo "[PHI] Running continuous improvement engine..."
bash "$SCRIPT"

if [ $? -eq 0 ]; then
  echo "[PHI] Continuous improvement completed successfully."
else
  echo "[PHI] Continuous improvement detected issues. Check logs and reports."
fi

# Harden product repositories (example: security scan, permissions)
SECURITY_SCRIPT="/workspaces/dominion-os-demo-build/scripts/harden_security.sh"
if [ -f "$SECURITY_SCRIPT" ]; then
  echo "[PHI] Running security hardening..."
  bash "$SECURITY_SCRIPT"
fi

# Trigger deployment if all checks pass (example placeholder)
DEPLOY_SCRIPT="/workspaces/dominion-os-demo-build/scripts/deploy_mcp_full.sh"
if [ -f "$DEPLOY_SCRIPT" ]; then
  echo "[PHI] Deploying MCP..."
  bash "$DEPLOY_SCRIPT"
fi

# Optional: Add notification logic here
