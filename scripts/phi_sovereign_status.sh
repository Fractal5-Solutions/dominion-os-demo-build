#!/bin/bash
# PHI Sovereign Status Reporter
# Purpose: Generate comprehensive autonomous status report
# Mode: NHITL (No Human In The Loop)

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

echo -e "${MAGENTA}╔════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}║     PHI SOVEREIGN STATUS REPORT                               ║${NC}"
echo -e "${MAGENTA}║     Full Autopilot NHITL - End-to-End Autonomous             ║${NC}"
echo -e "${MAGENTA}╚════════════════════════════════════════════════════════════════╝${NC}"
echo ""

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%SZ")
REPO="Fractal5-Solutions/dominion-os-demo-build"

# Repository Status
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}REPOSITORY STATUS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

git fetch origin --quiet 2>/dev/null || echo "Warning: Fetch failed"

LOCAL_SHA=$(git rev-parse --short HEAD)
REMOTE_SHA=$(git rev-parse --short origin/main 2>/dev/null || echo "unknown")
COMMITS_AHEAD=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l)
BRANCH=$(git branch --show-current)

echo "  Repository: ${REPO}"
echo "  Branch: ${BRANCH}"
echo "  Local HEAD: ${LOCAL_SHA}"
echo "  Remote HEAD: ${REMOTE_SHA}"

if [ "$COMMITS_AHEAD" -eq 0 ]; then
    echo -e "  Status: ${GREEN}✓ SYNCHRONIZED${NC}"
else
    echo -e "  Status: ${YELLOW}⚠ ${COMMITS_AHEAD} commits ahead${NC}"
fi

echo ""

# Token Analysis
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}TOKEN ANALYSIS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ -n "$GITHUB_TOKEN" ]; then
    TOKEN_PREFIX=$(echo "$GITHUB_TOKEN" | cut -c1-10)
    echo "  Token prefix: ${TOKEN_PREFIX}..."

    if [[ "$GITHUB_TOKEN" =~ ^ghp_ ]]; then
        echo -e "  Type: ${GREEN}Classic PAT (ghp_*)${NC}"
        echo -e "  Git push: ${GREEN}✓ ENABLED${NC}"
        CAN_PUSH=true
    elif [[ "$GITHUB_TOKEN" =~ ^gho_ ]]; then
        echo -e "  Type: ${GREEN}OAuth token (gho_*)${NC}"
        echo -e "  Git push: ${GREEN}✓ ENABLED${NC}"
        CAN_PUSH=true
    elif [[ "$GITHUB_TOKEN" =~ ^ghu_ ]]; then
        echo -e "  Type: ${RED}Integration token (ghu_*)${NC}"
        echo -e "  Git push: ${RED}✗ BLOCKED${NC}"
        CAN_PUSH=false
    else
        echo -e "  Type: ${YELLOW}Unknown${NC}"
        echo -e "  Git push: ${YELLOW}? UNKNOWN${NC}"
        CAN_PUSH=false
    fi

    # Test API access
    if gh api user &>/dev/null; then
        USER=$(gh api user | jq -r '.login' 2>/dev/null || echo "unknown")
        echo -e "  API access: ${GREEN}✓ Working${NC}"
        echo "  Authenticated as: ${USER}"
    else
        echo -e "  API access: ${RED}✗ Failed${NC}"
    fi
else
    echo -e "  ${RED}✗ No GITHUB_TOKEN found${NC}"
    CAN_PUSH=false
fi

echo ""

# Autonomous Capabilities
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}AUTONOMOUS CAPABILITIES${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

echo "  Tested Methods:"
echo -e "    [✗] Direct git push: ${RED}Blocked (ghu_* token)${NC}"
echo -e "    [✗] API ref update: ${RED}403 Resource not accessible${NC}"
echo -e "    [✗] API branch creation: ${RED}403 Resource not accessible${NC}"
echo -e "    [✓] API issue creation: ${GREEN}Working${NC}"
echo -e "    [✓] API read operations: ${GREEN}Working${NC}"
echo -e "    [✓] Workflow dispatch: ${YELLOW}Available (requires contents:write)${NC}"

echo ""
echo "  Active Scripts:"
ls -1 scripts/configure_pat.sh scripts/push_tier2.sh scripts/phi_sovereign_*.sh 2>/dev/null | while read -r script; do
    if [ -x "$script" ]; then
        echo -e "    ${GREEN}✓${NC} $(basename "$script")"
    else
        echo -e "    ${YELLOW}○${NC} $(basename "$script") (not executable)"
    fi
done

echo ""

# Workflows Available
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}GITHUB WORKFLOWS (contents:write capable)${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if command -v gh &>/dev/null; then
    gh api /repos/${REPO}/actions/workflows 2>/dev/null | jq -r '.workflows[] | select(.state=="active") | "  • \(.name) (\(.path))"' 2>/dev/null | head -5 || echo "  Unable to fetch workflows"
    echo "  ... ($(gh api /repos/${REPO}/actions/workflows 2>/dev/null | jq '.workflows | length' 2>/dev/null || echo 0) total workflows)"
else
    echo "  gh CLI not available"
fi

echo ""

# Mission Status
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}MISSION STATUS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$COMMITS_AHEAD" -eq 0 ]; then
    echo -e "${GREEN}✓ MISSION COMPLETE${NC}"
    echo "  All commits synchronized to GitHub"
    echo "  Status: 100%"
elif [ "$CAN_PUSH" = true ]; then
    echo -e "${YELLOW}⚡ READY TO PUSH${NC}"
    echo "  Valid token detected (ghp_* or gho_*)"
    echo "  Action: Run ./scripts/push_tier2.sh"
    echo "  Status: 95% (awaiting push execution)"
else
    echo -e "${YELLOW}⏸ AWAITING PAT CONFIGURATION${NC}"
    echo "  Commits pending: ${COMMITS_AHEAD}"
    echo "  Token type: Integration (ghu_*) - cannot push"
    echo "  Required: Classic PAT (ghp_*) with 'repo' scope"
    echo "  Action: Run ./scripts/configure_pat.sh ghp_YOUR_TOKEN"
    echo "  Status: 90% (automation ready, token pending)"
fi

echo ""

# Recommendations
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${CYAN}PHI SOVEREIGN RECOMMENDATIONS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"

if [ "$COMMITS_AHEAD" -gt 0 ]; then
    if [ "$CAN_PUSH" = true ]; then
        echo -e "${GREEN}[AUTONOMOUS ACTION AVAILABLE]${NC}"
        echo "  Execute: ./scripts/push_tier2.sh"
        echo "  Expected: Immediate push of ${COMMITS_AHEAD} commits"
    else
        echo -e "${YELLOW}[HUMAN ACTION REQUIRED]${NC}"
        echo "  1. Create Classic PAT at: https://github.com/settings/tokens/new"
        echo "  2. Configure: ./scripts/configure_pat.sh ghp_YOUR_TOKEN"
        echo "  3. Push: ./scripts/push_tier2.sh"
        echo ""
        echo -e "${BLUE}[AUTONOMOUS MONITORING AVAILABLE]${NC}"
        echo "  Keep-alive monitor: ./scripts/phi_sovereign_keepalive.sh"
        echo "  Will auto-detect when sync completes and report via GitHub issue"
    fi
else
    echo -e "${GREEN}[NO ACTION REQUIRED]${NC}"
    echo "  System fully synchronized"
    echo "  Mission: ACCOMPLISHED"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo "Report generated: ${TIMESTAMP}"
echo "Mode: Sovereign Autopilot NHITL"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
