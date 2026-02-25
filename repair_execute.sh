#!/bin/bash
# PHI REPAIR PROTOCOL: DEPLOYMENT AUTHENTICATION
# Repair and execute sovereign deployment

echo "=== PHI REPAIR PROTOCOL: AUTHENTICATION ==="
echo "Target: 54 commits to Fractal5-Solutions/dominion-os-demo-build"
echo "Mode: REPAIR & EXECUTE"
echo ""

# Check if token is provided
if [ -z "$1" ]; then
    echo "ERROR: Personal Access Token required for repair"
    echo ""
    echo "REPAIR PROCESS:"
    echo "1. Visit: https://github.com/settings/tokens"
    echo "2. Check token: dominion-phi-execute"
    echo "3. Ensure scope: ✅ repo (full control)"
    echo "4. If missing scope: Delete & recreate token"
    echo "5. Run: ./repair_execute.sh YOUR_TOKEN"
    echo ""
    echo "ALTERNATIVE: Create new token"
    echo "- URL: https://github.com/settings/tokens/new"
    echo "- Name: dominion-phi-repair"
    echo "- Scope: ✅ repo"
    echo "- Generate → Copy → Run script"
    exit 1
fi

TOKEN="$1"
echo "Token provided: ${#TOKEN} characters"
echo "Testing authentication..."
echo ""

# Test authentication with a simple API call
echo "=== TESTING AUTHENTICATION ==="
curl -H "Authorization: token $TOKEN" -H "Accept: application/vnd.github.v3+json" https://api.github.com/user -s | jq -r '.login' 2>/dev/null || echo "Authentication test failed"

echo ""
echo "=== EXECUTING SOVEREIGN PUSH ==="
echo "Pushing 54 commits..."

# Execute the push
env -u GITHUB_TOKEN git push "https://$TOKEN@github.com/Fractal5-Solutions/dominion-os-demo-build.git" main

# Check result
EXIT_CODE=$?
echo ""
if [ $EXIT_CODE -eq 0 ]; then
    echo "=== REPAIR SUCCESSFUL ==="
    echo "✅ Authentication repaired"
    echo "✅ 54 commits deployed"
    echo "✅ PHI sovereignty maintained"
    echo "✅ Mission complete"
    echo ""
    git status -sb
    echo ""
    echo "VERIFICATION: Check https://github.com/Fractal5-Solutions/dominion-os-demo-build"
else
    echo "=== REPAIR FAILED ==="
    echo "❌ Authentication still failing"
    echo "❌ Check token scope and permissions"
    echo "❌ Try creating a new token with 'repo' scope"
    exit 1
fi
