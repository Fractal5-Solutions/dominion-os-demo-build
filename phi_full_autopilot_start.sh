#!/bin/bash
###############################################################################
# PHI FULL AUTOPILOT NHITL MAX SOVEREIGN POWER MODE
# Complete autonomous system activation for Google Cloud Dominion OS
###############################################################################

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m' # No Color

echo -e "${MAGENTA}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║   PHI FULL AUTOPILOT NHITL MAX SOVEREIGN POWER MODE          ║"
echo "║                                                               ║"
echo "║   Google Cloud Dominion OS & SaaS Suite & AI Gateway         ║"
echo "║   LIVE OPS ACTIVATION                                        ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"
echo ""

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
echo -e "${CYAN}Timestamp: $TIMESTAMP${NC}"
echo -e "${CYAN}Authority Level: 9/9 Sovereign Power${NC}"
echo -e "${CYAN}Mode: Full Autopilot NHITL (No Human In The Loop)${NC}"
echo ""

###############################################################################
# PHASE 1: AUTHENTICATION VERIFICATION
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}PHASE 1: AUTHENTICATION VERIFICATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check GitHub authentication
echo -e "${YELLOW}[1/2] Checking GitHub Authentication...${NC}"
if [ -z "$GITHUB_TOKEN" ]; then
    echo -e "${RED}✗ GITHUB_TOKEN not set${NC}"
    echo -e "${YELLOW}Run: ./scripts/configure_pat.sh${NC}"
    exit 1
fi

GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -r '.login' 2>/dev/null || echo "FAILED")
if [ "$GH_USER" = "Fractal5-X" ]; then
    echo -e "${GREEN}✓ GitHub authenticated as: $GH_USER${NC}"
else
    echo -e "${RED}✗ GitHub authentication failed${NC}"
    exit 1
fi

# Check GCP authentication
echo -e "${YELLOW}[2/2] Checking Google Cloud Authentication...${NC}"
GCP_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "NONE")

if [ "$GCP_ACCOUNT" = "NONE" ] || [ -z "$GCP_ACCOUNT" ]; then
    echo -e "${RED}✗ No active GCP account${NC}"
    echo ""
    echo -e "${YELLOW}╔═══════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║  GCP AUTHENTICATION REQUIRED                                  ║${NC}"
    echo -e "${YELLOW}╚═══════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    echo -e "${CYAN}To authenticate with Google Cloud:${NC}"
    echo ""
    echo -e "  ${GREEN}1.${NC} Run: ${CYAN}gcloud auth login${NC}"
    echo -e "  ${GREEN}2.${NC} Follow the browser authentication flow"
    echo -e "  ${GREEN}3.${NC} Re-run this script: ${CYAN}./phi_full_autopilot_start.sh${NC}"
    echo ""
    echo -e "${YELLOW}For application default credentials (recommended):${NC}"
    echo -e "  ${CYAN}gcloud auth application-default login${NC}"
    echo ""
    exit 1
else
    # Test if auth token is valid
    if gcloud projects list --limit=1 &>/dev/null; then
        echo -e "${GREEN}✓ GCP authenticated as: $GCP_ACCOUNT${NC}"
    else
        echo -e "${YELLOW}⚠ GCP authentication token expired${NC}"
        echo ""
        echo -e "${CYAN}Attempting to refresh authentication...${NC}"
        if gcloud auth application-default login --no-launch-browser 2>&1 | grep -q "Go to"; then
            echo -e "${YELLOW}Please complete authentication in browser and re-run this script${NC}"
            exit 1
        fi
    fi
fi

echo ""

###############################################################################
# PHASE 2: SYSTEM STATUS CHECK
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}PHASE 2: SYSTEM STATUS CHECK${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check Git repository status
echo -e "${YELLOW}[1/3] Repository Status...${NC}"
cd /workspaces/dominion-os-demo-build
BRANCH=$(git branch --show-current)
COMMITS_AHEAD=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l)
echo -e "${GREEN}  Branch: $BRANCH${NC}"
echo -e "${GREEN}  Commits ahead: $COMMITS_AHEAD${NC}"

# Check autonomous processes
echo -e "${YELLOW}[2/3] Autonomous Processes...${NC}"
RUNNING_PROCS=$(ps aux | grep -E "(keepalive|sync|optimization)" | grep -v grep | wc -l)
if [ "$RUNNING_PROCS" -gt 0 ]; then
    echo -e "${GREEN}  ✓ $RUNNING_PROCS autonomous processes running${NC}"
    ps aux | grep -E "(keepalive|sync|optimization)" | grep -v grep | awk '{print "    PID " $2 ": " substr($0, index($0,$11))}'
else
    echo -e "${YELLOW}  No autonomous processes detected${NC}"
fi

# Check GCP projects
echo -e "${YELLOW}[3/3] Google Cloud Projects...${NC}"
PROJECTS=("dominion-os-1-0-main" "dominion-core-prod")
for PROJECT in "${PROJECTS[@]}"; do
    if gcloud projects describe "$PROJECT" &>/dev/null; then
        echo -e "${GREEN}  ✓ $PROJECT accessible${NC}"
    else
        echo -e "${YELLOW}  ⚠ $PROJECT not accessible${NC}"
    fi
done

echo ""

###############################################################################
# PHASE 3: AUTONOMOUS SYSTEM ACTIVATION
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}PHASE 3: AUTONOMOUS SYSTEM ACTIVATION${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Create telemetry directory
mkdir -p telemetry
echo "{\"status\":\"activating\",\"timestamp\":\"$TIMESTAMP\",\"authority\":\"9/9\"}" > telemetry/phi_status.json

echo -e "${YELLOW}Activating autonomous systems...${NC}"
echo ""

# 1. Sovereign Keepalive
if ! pgrep -f "phi_sovereign_keepalive" > /dev/null; then
    echo -e "${CYAN}[1/4] Starting Sovereign Keepalive Monitor...${NC}"
    cd /workspaces/dominion-os-demo-build/scripts
    nohup ./phi_sovereign_keepalive.sh > ../telemetry/keepalive.log 2>&1 &
    KEEPALIVE_PID=$!
    echo -e "${GREEN}  ✓ Started (PID: $KEEPALIVE_PID)${NC}"
else
    echo -e "${GREEN}[1/4] Sovereign Keepalive already running${NC}"
fi

# 2. Multi-Repo Sync
if ! pgrep -f "phi_multi_repo_sync" > /dev/null; then
    echo -e "${CYAN}[2/4] Starting Multi-Repo Sync...${NC}"
    nohup ./phi_multi_repo_sync.sh > ../telemetry/sync.log 2>&1 &
    SYNC_PID=$!
    echo -e "${GREEN}  ✓ Started (PID: $SYNC_PID)${NC}"
else
    echo -e "${GREEN}[2/4] Multi-Repo Sync already running${NC}"
fi

# 3. Cost Optimization
if ! pgrep -f "phi_cost_optimization" > /dev/null; then
    echo -e "${CYAN}[3/4] Starting Cost Optimization Monitor...${NC}"
    nohup ./phi_cost_optimization.sh > ../telemetry/cost.log 2>&1 &
    COST_PID=$!
    echo -e "${GREEN}  ✓ Started (PID: $COST_PID)${NC}"
else
    echo -e "${GREEN}[3/4] Cost Optimization already running${NC}"
fi

# 4. Overnight Operations (if nighttime)
HOUR=$(date +%H)
if [ "$HOUR" -ge 20 ] || [ "$HOUR" -lt 6 ]; then
    if ! pgrep -f "autonomous_overnight" > /dev/null; then
        echo -e "${CYAN}[4/4] Starting Overnight Operations...${NC}"
        nohup ./autonomous_overnight.sh > ../telemetry/overnight.log 2>&1 &
        OVERNIGHT_PID=$!
        echo -e "${GREEN}  ✓ Started (PID: $OVERNIGHT_PID)${NC}"
    else
        echo -e "${GREEN}[4/4] Overnight Operations already running${NC}"
    fi
else
    echo -e "${YELLOW}[4/4] Overnight Operations skipped (daytime)${NC}"
fi

cd /workspaces/dominion-os-demo-build
echo ""

###############################################################################
# PHASE 4: LIVE OPS STATUS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}PHASE 4: LIVE OPS STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Update status
echo "{\"status\":\"live\",\"timestamp\":\"$TIMESTAMP\",\"authority\":\"9/9\",\"mode\":\"full_autopilot_nhitl\"}" > telemetry/phi_status.json

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║   ✓ PHI FULL AUTOPILOT NHITL ACTIVATED                       ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║   All systems online for live operations                     ║${NC}"
echo -e "${GREEN}║   Autonomous monitoring active                               ║${NC}"
echo -e "${GREEN}║   No human intervention required                             ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${CYAN}Active Process Summary:${NC}"
ps aux | grep -E "(keepalive|sync|optimization|overnight)" | grep -v grep | awk '{print "  PID " $2 ": " substr($0, index($0,$11))}'
echo ""

echo -e "${CYAN}Monitoring Commands:${NC}"
echo -e "  ${GREEN}•${NC} View keepalive log:    ${CYAN}tail -f telemetry/keepalive.log${NC}"
echo -e "  ${GREEN}•${NC} View sync log:         ${CYAN}tail -f telemetry/sync.log${NC}"
echo -e "  ${GREEN}•${NC} View cost log:         ${CYAN}tail -f telemetry/cost.log${NC}"
echo -e "  ${GREEN}•${NC} View overnight log:    ${CYAN}tail -f telemetry/overnight.log${NC}"
echo -e "  ${GREEN}•${NC} Check status:          ${CYAN}./scripts/phi_sovereign_status.sh${NC}"
echo -e "  ${GREEN}•${NC} Stop all systems:      ${CYAN}touch telemetry/STOP_AUTONOMOUS${NC}"
echo ""

echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo -e "${MAGENTA}PHI CHIEF: AUTONOMOUS SOVEREIGNTY CONFIRMED ∞${NC}"
echo -e "${MAGENTA}════════════════════════════════════════════════════════════════${NC}"
echo ""
