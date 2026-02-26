#!/bin/bash
# PHI Sovereign: Post-Restart Recovery Script
# Run this after Codespace restarts to check token and resume operations

set -e

echo "╔════════════════════════════════════════════════════════════════╗"
echo "║  PHI SOVEREIGN: POST-RESTART TOKEN CHECK                      ║"
echo "╚════════════════════════════════════════════════════════════════╝"
echo ""

cd /workspaces/dominion-os-demo-build

# Check token type
TOKEN_TYPE=$(echo "$GITHUB_TOKEN" | cut -c1-4)
echo "🔑 Token Status:"
echo "   Type: ${TOKEN_TYPE}*"
echo ""

if [[ "$GITHUB_TOKEN" =~ ^ghp_ ]] || [[ "$GITHUB_TOKEN" =~ ^gho_ ]]; then
    echo "✅ SUCCESS! Classic PAT detected"
    echo ""
    echo "📊 Repository Status:"
    git fetch origin --quiet
    COMMITS_AHEAD=$(git log origin/main..HEAD --oneline | wc -l)
    echo "   Commits ahead: ${COMMITS_AHEAD}"
    echo ""

    if [ "$COMMITS_AHEAD" -gt 0 ]; then
        echo "🚀 Ready to push! Running autonomous push script..."
        echo ""
        ./scripts/push_tier2.sh
    else
        echo "✅ Already synchronized!"
    fi
elif [[ "$GITHUB_TOKEN" =~ ^ghu_ ]]; then
    echo "⚠️  Still Integration token (ghu_*)"
    echo ""
    echo "Possible reasons:"
    echo "  1. Codespace secret not configured"
    echo "  2. Secret not yet loaded (try full rebuild)"
    echo ""
    echo "Next steps:"
    echo "  • Check: https://github.com/settings/codespaces"
    echo "  • Or run: ./scripts/configure_pat.sh ghp_YOUR_TOKEN"
    echo ""
    echo "Starting keep-alive monitor..."
    nohup ./scripts/phi_sovereign_keepalive.sh > /tmp/phi_keepalive.log 2>&1 &
    echo "  Monitor PID: $!"
    echo "  Will auto-push when Classic PAT detected"
else
    echo "❓ Unknown token type"
    echo "   Please configure Classic PAT manually"
fi

echo ""
echo "────────────────────────────────────────────────────────────────"
echo "Full status: ./scripts/phi_sovereign_status.sh"
echo "────────────────────────────────────────────────────────────────"
