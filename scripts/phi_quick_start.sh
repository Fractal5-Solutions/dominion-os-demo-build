#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# PHI SYSTEMS - QUICK START
# ═══════════════════════════════════════════════════════════════════

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
mkdir -p "$LOG_DIR"

echo -e "${MAGENTA}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║              PHI SYSTEMS - QUICK START                            ║${NC}"
echo -e "${MAGENTA}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

export DOMINION_WORKSPACE_ROOT="/workspaces/dominion-command-center"
export DOMINION_LIVE_OPS_ROOT="$(dirname "$SCRIPT_DIR")"

if [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
    echo -e "${GREEN}✓${NC} Virtual environment activated"
fi

echo -e "${CYAN}Using command center root:${NC} $DOMINION_WORKSPACE_ROOT"
echo -e "${CYAN}Using live ops root:${NC} $DOMINION_LIVE_OPS_ROOT"
echo ""

if [ ! -x "$SCRIPT_DIR/phi_start_all_systems.sh" ]; then
    echo -e "${RED}✗${NC} Missing startup script: $SCRIPT_DIR/phi_start_all_systems.sh"
    exit 1
fi

bash "$SCRIPT_DIR/phi_start_all_systems.sh"

echo ""
echo -e "${CYAN}━━━ POST-START VERIFICATION ━━━${NC}"
echo ""

if [ -x "$SCRIPT_DIR/phi_live_ops_verification.sh" ]; then
    bash "$SCRIPT_DIR/phi_live_ops_verification.sh"
fi
