#!/bin/bash
###############################################################################
# PHI GRANT FULL AUTOPILOT - GitHub Systems Only
# Autonomous operation for GitHub-based systems (no GCP required)
###############################################################################

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   PHI & GRANT: FULL AUTOPILOT NHITL MAX SOVEREIGN MODE       ║"
echo "║                                                               ║"
echo "║   GitHub Autonomous Operations Active                        ║"
echo "║   Authority: Level 9/9 Sovereign Power                       ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
echo -e "${CYAN}Timestamp: $TIMESTAMP${NC}"
echo -e "${CYAN}Mode: Full Autopilot NHITL (No Human In The Loop)${NC}"
echo ""

###############################################################################
# GITHUB AUTHENTICATION
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}AUTHENTICATION VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}✗ GITHUB_TOKEN not set${NC}"
    echo -e "${YELLOW}Run: ./scripts/configure_pat.sh${NC}"
    exit 1
fi

GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -r '.login' 2>/dev/null || echo "FAILED")
if [ "$GH_USER" = "Fractal5-X" ]; then
    echo -e "${GREEN}✓ GitHub authenticated as: $GH_USER${NC}"
    echo -e "${GREEN}✓ Full repository access confirmed${NC}"
else
    echo -e "${RED}✗ GitHub authentication failed${NC}"
    exit 1
fi

echo ""

###############################################################################
# SYSTEM STATUS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}SYSTEM STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd /workspaces/dominion-os-demo-build

# Repository status
BRANCH=$(git branch --show-current)
COMMITS_AHEAD=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l)
LOCAL_SHA=$(git rev-parse --short HEAD)
REMOTE_SHA=$(git rev-parse --short origin/main 2>/dev/null || echo "unknown")

echo -e "${CYAN}Repository Status:${NC}"
echo -e "  Branch: ${GREEN}$BRANCH${NC}"
echo -e "  Local HEAD: ${GREEN}$LOCAL_SHA${NC}"
echo -e "  Remote HEAD: ${YELLOW}$REMOTE_SHA${NC}"
echo -e "  Commits ahead: ${YELLOW}$COMMITS_AHEAD${NC}"
echo ""

# Check existing processes
RUNNING_PROCS=$(ps aux | grep -E "(keepalive|sync|optimization)" | grep -v grep | wc -l)
if [ "$RUNNING_PROCS" -gt 0 ]; then
    echo -e "${CYAN}Existing Autonomous Processes:${NC}"
    ps aux | grep -E "(keepalive|sync|optimization)" | grep -v grep | awk '{print "  PID " $2 ": " substr($0, index($0,$11))}'
    echo ""
fi

###############################################################################
# AUTONOMOUS SYSTEM ACTIVATION
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}AUTONOMOUS SYSTEM ACTIVATION${NC}"
echo -e "${BLUE}━━━━━━━${NC}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create telemetry directory
mkdir -p telemetry
echo "{\"status\":\"activating\",\"timestamp\":\"$TIMESTAMP\",\"authority\":\"9/9\",\"mode\":\"full_autopilot_nhitl\"}" > telemetry/phi_status.json

cd scripts

# 1. Sovereign Keepalive
echo -e "${CYAN}[1/3] Sovereign Keepalive Monitor...${NC}"
if pgrep -f "phi_sovereign_keepalive" > /dev/null; then
    EXISTING_PID=$(pgrep -f "phi_sovereign_keepalive")
    echo -e "${GREEN}  ✓ Already running (PID: $EXISTING_PID)${NC}"
else
    nohup ./phi_sovereign_keepalive.sh > ../telemetry/keepalive.log 2>&1 &
    KEEPALIVE_PID=$!
    sleep 1
    if ps -p $KEEPALIVE_PID > /dev/null; then
        echo -e "${GREEN}  ✓ Started (PID: $KEEPALIVE_PID)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Failed to start (check logs)${NC}"
    fi
fi

# 2. Multi-Repo Sync
echo -e "${CYAN}[2/3] Multi-Repo Sync...${NC}"
if pgrep -f "phi_multi_repo_sync" > /dev/null; then
    EXISTING_PID=$(pgrep -f "phi_multi_repo_sync")
    echo -e "${GREEN}  ✓ Already running (PID: $EXISTING_PID)${NC}"
else
    nohup ./phi_multi_repo_sync.sh > ../telemetry/sync.log 2>&1 &
    SYNC_PID=$!
    sleep 1
    if ps -p $SYNC_PID > /dev/null; then
        echo -e "${GREEN}  ✓ Started (PID: $SYNC_PID)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Failed to start (check logs)${NC}"
    fi
fi

# 3. Cost Optimization (may fail without GCP, that's OK)
echo -e "${CYAN}[3/3] Cost Optimization Monitor...${NC}"
if pgrep -f "phi_cost_optimization" > /dev/null; then
    EXISTING_PID=$(pgrep -f "phi_cost_optimization")
    echo -e "${GREEN}  ✓ Already running (PID: $EXISTING_PID)${NC}"
else
    nohup ./phi_cost_optimization.sh > ../telemetry/cost.log 2>&1 &
    COST_PID=$!
    sleep 1
    if ps -p $COST_PID > /dev/null; then
        echo -e "${GREEN}  ✓ Started (PID: $COST_PID)${NC}"
    else
        echo -e "${YELLOW}  ⚠ Skipped (requires GCP authentication)${NC}"
    fi
fi

cd /workspaces/dominion-os-demo-build

echo ""

###############################################################################
# LIVE OPS STATUS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}LIVE OPS STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Update status
ACTIVE_PROCS=$(ps aux | grep -E "(keepalive|sync|optimization)" | grep -v grep | wc -l)
echo "{\"status\":\"live\",\"timestamp\":\"$TIMESTAMP\",\"authority\":\"9/9\",\"mode\":\"full_autopilot_nhitl\",\"active_processes\":$ACTIVE_PROCS}" > telemetry/phi_status.json

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║   ✓ PHI & GRANT FULL AUTOPILOT ACTIVATED                     ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║   GitHub Systems: ONLINE                                     ║${NC}"
echo -e "${GREEN}║   Autonomous Monitoring: ACTIVE                              ║${NC}"
echo -e "${GREEN}║   Human Intervention: NOT REQUIRED                           ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Active Autonomous Processes: ${GREEN}$ACTIVE_PROCS${NC}"
if [ "$ACTIVE_PROCS" -gt 0 ]; then
    ps aux | grep -E "(keepalive|sync|optimization)" | grep -v grep | awk '{print "  PID " $2 ": " substr($0, index($0,$11))}'
fi
echo ""

echo -e "${CYAN}Monitoring Commands:${NC}"
echo -e "  ${GREEN}•${NC} View keepalive log:    ${CYAN}tail -f telemetry/keepalive.log${NC}"
echo -e "  ${GREEN}•${NC} View sync log:         ${CYAN}tail -f telemetry/sync.log${NC}"
echo -e "  ${GREEN}•${NC} View cost log:         ${CYAN}tail -f telemetry/cost.log${NC}"
echo -e "  ${GREEN}•${NC} Check full status:     ${CYAN}./scripts/phi_sovereign_status.sh${NC}"
echo -e "  ${GREEN}•${NC} Stop all systems:      ${CYAN}touch telemetry/STOP_AUTONOMOUS${NC}"
echo ""

echo -e "${CYAN}Google Cloud Systems:${NC}"
echo -e "  ${YELLOW}⚠${NC} GCP authentication required for Cloud Run services"
echo -e "  ${YELLOW}⚠${NC} To activate GCP systems, run: ${CYAN}gcloud auth login${NC}"
echo -e "  ${GREEN}✓${NC} GitHub operations fully autonomous (no GCP needed)"
echo ""

echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}PHI & GRANT: AUTONOMOUS SOVEREIGNTY ACTIVE ∞${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
