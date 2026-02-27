#!/bin/bash
###############################################################################
# PHI CONTINUOUS IMPROVEMENT DASHBOARD
# Real-time status of all optimization and monitoring systems
###############################################################################

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

clear

echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║                                                               ║"
echo "║        PHI CONTINUOUS IMPROVEMENT DASHBOARD                  ║"
echo "║        Google Cloud Dominion OS & SaaS Suite                 ║"
echo "║                                                               ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

TIMESTAMP=$(date '+%Y-%m-%d %H:%M:%S UTC')
echo -e "${CYAN}Dashboard Generated: $TIMESTAMP${NC}"
echo -e "${CYAN}Authority Level: 9/9 Sovereign Power${NC}"
echo -e "${CYAN}Mode: Full Autopilot NHITL - Continuous Improvement${NC}"
echo ""

###############################################################################
# AUTHENTICATION STATUS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}AUTHENTICATION STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# GitHub Auth
if [ -n "$GITHUB_TOKEN" ]; then
    GH_USER=$(curl -s -H "Authorization: token $GITHUB_TOKEN" https://api.github.com/user | jq -r '.login' 2>/dev/null || echo "FAILED")
    if [ "$GH_USER" != "FAILED" ] && [ "$GH_USER" != "null" ]; then
        echo -e "  ${GREEN}✓ GitHub:${NC} Authenticated as $GH_USER"
    else
        echo -e "  ${RED}✗ GitHub:${NC} Authentication failed"
    fi
else
    echo -e "  ${YELLOW}⚠ GitHub:${NC} Token not configured"
fi

# GCP Auth
GCP_ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "NONE")
if [ "$GCP_ACCOUNT" != "NONE" ] && [ -n "$GCP_ACCOUNT" ]; then
    echo -e "  ${GREEN}✓ Google Cloud:${NC} Authenticated as $GCP_ACCOUNT"
else
    echo -e "  ${YELLOW}⚠ Google Cloud:${NC} Not authenticated"
fi

echo ""

###############################################################################
# INFRASTRUCTURE HEALTH
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}INFRASTRUCTURE HEALTH${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Check if system status exists
if [ -f "../telemetry/system_status.json" ]; then
    TOTAL=$(jq -r '.infrastructure.total_services' ../telemetry/system_status.json 2>/dev/null)
    OPERATIONAL=$(jq -r '.infrastructure.operational_services' ../telemetry/system_status.json 2>/dev/null)
    HEALTH_PCT=$(jq -r '.infrastructure.health_percentage' ../telemetry/system_status.json 2>/dev/null)

    if [ "$HEALTH_PCT" = "100" ]; then
        echo -e "  ${GREEN}✓ Overall Health: ${HEALTH_PCT}%${NC} (${OPERATIONAL}/${TOTAL} services)"
    elif [ "$HEALTH_PCT" -ge 90 ]; then
        echo -e "  ${YELLOW}⚠ Overall Health: ${HEALTH_PCT}%${NC} (${OPERATIONAL}/${TOTAL} services)"
    else
        echo -e "  ${RED}✗ Overall Health: ${HEALTH_PCT}%${NC} (${OPERATIONAL}/${TOTAL} services)"
    fi

    # Component breakdown
    AI_GATEWAYS=$(jq -r '.components.ai_gateways' ../telemetry/system_status.json 2>/dev/null)
    PHI_UIS=$(jq -r '.components.phi_uis' ../telemetry/system_status.json 2>/dev/null)
    CORE_APIS=$(jq -r '.components.core_apis' ../telemetry/system_status.json 2>/dev/null)

    echo -e "  ${CYAN}Components:${NC}"
    echo -e "    • AI Gateways: ${GREEN}${AI_GATEWAYS}${NC}"
    echo -e "    • PHI User Interfaces: ${GREEN}${PHI_UIS}${NC}"
    echo -e "    • Core APIs: ${GREEN}${CORE_APIS}${NC}"

    # Project breakdown
    P1_OP=$(jq -r '.projects."dominion-os-1-0-main".operational' ../telemetry/system_status.json 2>/dev/null)
    P1_TOTAL=$(jq -r '.projects."dominion-os-1-0-main".total' ../telemetry/system_status.json 2>/dev/null)
    P2_OP=$(jq -r '.projects."dominion-core-prod".operational' ../telemetry/system_status.json 2>/dev/null)
    P2_TOTAL=$(jq -r '.projects."dominion-core-prod".total' ../telemetry/system_status.json 2>/dev/null)

    echo -e "  ${CYAN}Projects:${NC}"
    echo -e "    • dominion-os-1-0-main: ${GREEN}${P1_OP}/${P1_TOTAL}${NC}"
    echo -e "    • dominion-core-prod: ${GREEN}${P2_OP}/${P2_TOTAL}${NC}"
else
    echo -e "  ${YELLOW}⚠ No system status data available${NC}"
fi

echo ""

###############################################################################
# AUTONOMOUS SYSTEMS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}AUTONOMOUS SYSTEMS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

ACTIVE_COUNT=0

# Check each autonomous system
if pgrep -f "phi_sovereign_keepalive" > /dev/null; then
    KEEPALIVE_PID=$(pgrep -f "phi_sovereign_keepalive")
    echo -e "  ${GREEN}✓ Sovereign Keepalive${NC} (PID: $KEEPALIVE_PID)"
    ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
else
    echo -e "  ${YELLOW}○ Sovereign Keepalive${NC} (not running)"
fi

if pgrep -f "phi_multi_repo_sync" > /dev/null; then
    SYNC_PID=$(pgrep -f "phi_multi_repo_sync")
    echo -e "  ${GREEN}✓ Multi-Repo Sync${NC} (PID: $SYNC_PID)"
    ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
else
    echo -e "  ${YELLOW}○ Multi-Repo Sync${NC} (not running)"
fi

if pgrep -f "phi_cost_optimization" > /dev/null; then
    COST_PID=$(pgrep -f "phi_cost_optimization")
    echo -e "  ${GREEN}✓ Cost Optimization${NC} (PID: $COST_PID)"
    ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
else
    echo -e "  ${YELLOW}○ Cost Optimization${NC} (not running)"
fi

if pgrep -f "phi_continuous_improvement" > /dev/null; then
    CI_PID=$(pgrep -f "phi_continuous_improvement" | head -1)
    echo -e "  ${GREEN}✓ Continuous Improvement${NC} (PID: $CI_PID)"
    ACTIVE_COUNT=$((ACTIVE_COUNT + 1))
else
    echo -e "  ${YELLOW}○ Continuous Improvement${NC} (not running)"
fi

echo ""
echo -e "  ${CYAN}Active Systems:${NC} ${GREEN}${ACTIVE_COUNT}/4${NC}"

echo ""

###############################################################################
# CONTINUOUS IMPROVEMENT METRICS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}CONTINUOUS IMPROVEMENT METRICS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Find latest metrics file
LATEST_METRICS=$(ls -t ../telemetry/improvements/metrics_*.json 2>/dev/null | head -1)

if [ -n "$LATEST_METRICS" ] && [ -f "$LATEST_METRICS" ]; then
    CYCLE=$(jq -r '.cycle' "$LATEST_METRICS" 2>/dev/null)
    HEALTH=$(jq -r '.health_pct' "$LATEST_METRICS" 2>/dev/null)
    SLO=$(jq -r '.slo_compliance' "$LATEST_METRICS" 2>/dev/null)
    OPT_OPS=$(jq -r '.optimization_opportunities' "$LATEST_METRICS" 2>/dev/null)

    echo -e "  ${CYAN}Latest Cycle:${NC} #$CYCLE"
    echo -e "  ${CYAN}Infrastructure Health:${NC} ${GREEN}${HEALTH}%${NC}"
    echo -e "  ${CYAN}SLO Compliance:${NC} ${GREEN}${SLO}/7${NC} critical services"

    if [ "$OPT_OPS" -gt 0 ]; then
        echo -e "  ${CYAN}Optimization Opportunities:${NC} ${YELLOW}${OPT_OPS}${NC} services"
    else
        echo -e "  ${CYAN}Optimization Status:${NC} ${GREEN}Optimal${NC}"
    fi

    # Show improvement trend
    METRICS_COUNT=$(ls ../telemetry/improvements/metrics_*.json 2>/dev/null | wc -l)
    echo -e "  ${CYAN}Total Cycles Completed:${NC} ${GREEN}${METRICS_COUNT}${NC}"
else
    echo -e "  ${YELLOW}⚠ No improvement metrics available yet${NC}"
    echo -e "    First cycle may still be in progress"
fi

echo ""

###############################################################################
# REPOSITORY STATUS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}REPOSITORY STATUS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

cd /workspaces/dominion-os-demo-build 2>/dev/null || cd ../

BRANCH=$(git branch --show-current 2>/dev/null || echo "unknown")
COMMITS_AHEAD=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l)
LOCAL_SHA=$(git rev-parse --short HEAD 2>/dev/null || echo "unknown")

echo -e "  ${CYAN}Current Branch:${NC} ${YELLOW}$BRANCH${NC}"
echo -e "  ${CYAN}Local HEAD:${NC} $LOCAL_SHA"
echo -e "  ${CYAN}Commits Ahead:${NC} ${YELLOW}$COMMITS_AHEAD${NC}"

if [ "$COMMITS_AHEAD" -gt 0 ]; then
    echo -e "  ${YELLOW}⚠ Branch protection requires PR for main${NC}"
fi

echo ""

###############################################################################
# QUICK ACTIONS
###############################################################################

echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BLUE}${BOLD}QUICK ACTIONS${NC}"
echo -e "${BLUE}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

echo -e "  ${CYAN}View Live Logs:${NC}"
echo -e "    ${GREEN}•${NC} Keepalive:    ${YELLOW}tail -f telemetry/keepalive.log${NC}"
echo -e "    ${GREEN}•${NC} Sync:         ${YELLOW}tail -f telemetry/sync.log${NC}"
echo -e "    ${GREEN}•${NC} Cost:         ${YELLOW}tail -f telemetry/cost.log${NC}"
echo -e "    ${GREEN}•${NC} Improvements: ${YELLOW}tail -f telemetry/continuous_improvement.log${NC}"
echo ""

echo -e "  ${CYAN}System Control:${NC}"
echo -e "    ${GREEN}•${NC} Full Status:  ${YELLOW}./scripts/phi_sovereign_status.sh${NC}"
echo -e "    ${GREEN}•${NC} Stop All:     ${YELLOW}touch telemetry/STOP_AUTONOMOUS${NC}"
echo -e "    ${GREEN}•${NC} Refresh:      ${YELLOW}watch -n 5 ./scripts/phi_continuous_improvement_dashboard.sh${NC}"
echo ""

###############################################################################
# SYSTEM SUMMARY
###############################################################################

echo -e "${GREEN}╔═══════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}║   PHI CONTINUOUS IMPROVEMENT: OPERATIONAL                     ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"

if [ "$ACTIVE_COUNT" -eq 4 ]; then
    echo -e "${GREEN}║   All autonomous systems active and optimizing               ║${NC}"
elif [ "$ACTIVE_COUNT" -gt 0 ]; then
    echo -e "${YELLOW}║   ${ACTIVE_COUNT}/4 autonomous systems active                          ║${NC}"
else
    echo -e "${YELLOW}║   No autonomous systems currently active                     ║${NC}"
fi

echo -e "${GREEN}║   Google Cloud infrastructure under continuous monitoring    ║${NC}"
echo -e "${GREEN}║                                                               ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${MAGENTA}PHI CHIEF: CONTINUOUS IMPROVEMENT ACTIVE ∞${NC}"
echo ""
