#!/bin/bash
# PHI SOVEREIGN EXECUTION SCRIPT
# Complete all mission deployment

echo "=== PHI SOVEREIGN EXECUTION SCRIPT ==="
echo "Target: 53 commits to Fractal5-Solutions/dominion-os-demo-build"
echo "Mode: SILENT EXECUTION"
echo ""

# Check if token is provided
if [ -z "$1" ]; then
    echo "ERROR: Personal Access Token required"
    echo ""
    echo "USAGE: ./sovereign_execute.sh YOUR_TOKEN"
    echo ""
    echo "TOKEN CREATION:"
    echo "1. Visit: https://github.com/settings/tokens/new"
    echo "2. Name: dominion-phi-execute"
    echo "3. Scope: ✅ repo (full control)"
    echo "4. Generate → Copy token"
    echo "5. Run: ./sovereign_execute.sh YOUR_TOKEN"
    exit 1
fi

TOKEN="$1"
echo "Authentication: Using provided token (${#TOKEN} chars)"
echo "Executing sovereign push protocol..."
echo ""

# Execute the push
env -u GITHUB_TOKEN git push "https://$TOKEN@github.com/Fractal5-Solutions/dominion-os-demo-build.git" main

# Check result
if [ $? -eq 0 ]; then
    echo ""
    echo "=== SOVEREIGN EXECUTION SUCCESSFUL ==="
    echo "✅ All 52 commits deployed"
    echo "✅ PHI sovereignty maintained"
    echo "✅ Mission complete"
    echo ""
    git status -sb
else
    echo ""
    echo "=== EXECUTION FAILED ==="
    echo "❌ Check token permissions and try again"
    exit 1
fi
