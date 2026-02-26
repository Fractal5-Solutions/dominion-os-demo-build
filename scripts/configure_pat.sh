#!/bin/bash
# PHI Chief: Optimized PAT Configuration & Verification Script
# Purpose: Configure GitHub Personal Access Token for full git operations
# Usage: ./configure_pat.sh [token]

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

echo "╔═══════════════════════════════════════════════════════════════╗"
echo "║      PHI Chief: GitHub PAT Configuration & Optimizer         ║"
echo "╚═══════════════════════════════════════════════════════════════╝"
echo ""

# Check if token provided as argument
if [ -n "$1" ]; then
    NEW_TOKEN="$1"
    echo -e "${BLUE}Token provided as argument${NC}"
elif [ -n "$GITHUB_TOKEN" ]; then
    echo -e "${YELLOW}Current GITHUB_TOKEN detected${NC}"
    NEW_TOKEN="$GITHUB_TOKEN"
else
    echo -e "${RED}No token provided${NC}"
    echo ""
    echo "Usage:"
    echo "  $0 ghp_your_token_here"
    echo ""
    echo "Or export it first:"
    echo "  export GITHUB_TOKEN=ghp_your_token_here"
    echo "  $0"
    echo ""
    exit 1
fi

# Verify token format
if [[ "$NEW_TOKEN" =~ ^ghp_ ]]; then
    echo -e "${GREEN}✓ Valid PAT format detected (ghp_*)${NC}"
elif [[ "$NEW_TOKEN" =~ ^gho_ ]]; then
    echo -e "${GREEN}✓ Valid OAuth token format detected (gho_*)${NC}"
elif [[ "$NEW_TOKEN" =~ ^ghu_ ]]; then
    echo -e "${RED}✗ Integration token detected (ghu_*) - Limited scope${NC}"
    echo -e "${YELLOW}This token may not work for git push operations${NC}"
else
    echo -e "${YELLOW}⚠ Unrecognized token format - Proceeding anyway${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 1: Testing Token Authentication"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test API access
echo -n "Testing GitHub API access... "
USER_LOGIN=$(curl -s -H "Authorization: token $NEW_TOKEN" https://api.github.com/user | jq -r '.login' 2>/dev/null)

if [ "$USER_LOGIN" != "null" ] && [ -n "$USER_LOGIN" ]; then
    echo -e "${GREEN}✓ Success${NC}"
    echo "  User: $USER_LOGIN"
else
    echo -e "${RED}✗ Failed${NC}"
    echo "  Token may be invalid or expired"
    exit 1
fi

# Check token scopes
echo -n "Checking token scopes... "
SCOPES=$(curl -s -I -H "Authorization: token $NEW_TOKEN" https://api.github.com/user 2>/dev/null | grep -i "x-oauth-scopes:" | cut -d: -f2- | xargs)

if [ -z "$SCOPES" ]; then
    echo -e "${YELLOW}⚠ No scopes visible (may be fine-grained token)${NC}"
else
    echo -e "${GREEN}✓ Scopes: $SCOPES${NC}"

    # Verify required scopes
    if [[ "$SCOPES" == *"repo"* ]]; then
        echo -e "  ${GREEN}✓ repo scope present${NC}"
    else
        echo -e "  ${YELLOW}⚠ repo scope missing - git push may fail${NC}"
    fi
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 2: Testing Repository Access"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Test dominion-os-demo-build access
echo -n "Testing dominion-os-demo-build access... "
REPO_ACCESS=$(curl -s -H "Authorization: token $NEW_TOKEN" https://api.github.com/repos/Fractal5-Solutions/dominion-os-demo-build | jq -r '.permissions.push' 2>/dev/null)

if [ "$REPO_ACCESS" == "true" ]; then
    echo -e "${GREEN}✓ Push access confirmed${NC}"
else
    echo -e "${RED}✗ No push access${NC}"
    echo "  Token may lack required permissions"
    exit 1
fi

# Test dominion-command-center access
echo -n "Testing dominion-command-center access... "
CMD_CENTER_ACCESS=$(curl -s -H "Authorization: token $NEW_TOKEN" https://api.github.com/repos/Fractal5-Solutions/dominion-command-center | jq -r '.permissions.push' 2>/dev/null)

if [ "$CMD_CENTER_ACCESS" == "true" ]; then
    echo -e "${GREEN}✓ Push access confirmed${NC}"
else
    echo -e "${YELLOW}⚠ No push access to command center${NC}"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 3: Configuring Token"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Export to current session
export GITHUB_TOKEN="$NEW_TOKEN"
echo -e "${GREEN}✓ Token exported to current session${NC}"

# Add to .bashrc for persistence
if ! grep -q "export GITHUB_TOKEN=ghp_" ~/.bashrc 2>/dev/null; then
    echo "export GITHUB_TOKEN=$NEW_TOKEN" >> ~/.bashrc
    echo -e "${GREEN}✓ Token added to ~/.bashrc (persistent)${NC}"
else
    echo -e "${YELLOW}⚠ Token already in ~/.bashrc (not updated)${NC}"
    echo "  Run: sed -i 's/export GITHUB_TOKEN=.*/export GITHUB_TOKEN=$NEW_TOKEN/' ~/.bashrc"
fi

# Configure git credential store
echo "https://${USER_LOGIN}:${NEW_TOKEN}@github.com" > ~/.git-credentials-new
chmod 600 ~/.git-credentials-new

if [ -f ~/.git-credentials ]; then
    # Backup existing
    cp ~/.git-credentials ~/.git-credentials.backup
    echo -e "${GREEN}✓ Backed up existing credentials${NC}"
fi

# Update with new token
mv ~/.git-credentials-new ~/.git-credentials
git config --global credential.helper store
echo -e "${GREEN}✓ Git credential store updated${NC}"

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "STEP 4: Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Verify gh CLI sees the token
echo -n "Verifying gh CLI authentication... "
if gh auth status 2>&1 | grep -q "Logged in"; then
    echo -e "${GREEN}✓ Authenticated${NC}"
else
    echo -e "${YELLOW}⚠ gh CLI may not see the new token${NC}"
    echo "  Run: gh auth login"
fi

# Test git ls-remote (simulates push check)
echo -n "Testing git remote access... "
if git ls-remote https://github.com/Fractal5-Solutions/dominion-os-demo-build.git HEAD &>/dev/null; then
    echo -e "${GREEN}✓ Remote access working${NC}"
else
    echo -e "${RED}✗ Cannot access remote${NC}"
    echo "  Token may still lack push permissions"
    exit 1
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "✓ CONFIGURATION COMPLETE"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Next Steps:"
echo ""
echo "1. Push Tier 2 commits (41 pending):"
echo "   cd /workspaces/dominion-os-demo-build"
echo "   git push origin main"
echo ""
echo "2. Verify on GitHub:"
echo "   https://github.com/Fractal5-Solutions/dominion-os-demo-build/commits/main"
echo ""
echo "3. For new sessions, token is persistent via:"
echo "   - ~/.bashrc (auto-loaded)"
echo "   - ~/.git-credentials (auto-used by git)"
echo ""
echo -e "${BLUE}Token configured successfully for user: $USER_LOGIN${NC}"
echo ""
