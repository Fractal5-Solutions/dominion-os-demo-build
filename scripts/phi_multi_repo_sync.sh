#!/bin/bash
# PHI Multi-Repository Autonomous Sync
# Monitors and syncs ALL repositories with pending commits
# Part of the Sovereign Mode NHITL infrastructure

set -euo pipefail

# Configuration
REPOS=(
    "/workspaces/dominion-os-demo-build"
    "/workspaces/dominion-command-center"
)
CHECK_INTERVAL=60
MAX_ITERATIONS=0  # 0 = infinite

echo "═══════════════════════════════════════════════════════"
echo "  🎯 PHI MULTI-REPO AUTONOMOUS SYNC - ACTIVATED"
echo "═══════════════════════════════════════════════════════"
echo ""
echo "Monitoring $(echo "${REPOS[@]}" | wc -w) repositories"
echo "Check interval: ${CHECK_INTERVAL}s"
echo "Mode: Continuous (NHITL)"
echo ""
echo "Repositories:"
for repo in "${REPOS[@]}"; do
    echo "  • $(basename "$repo")"
done
echo ""
echo "═══════════════════════════════════════════════════════"
echo ""

iteration=0
while [ $MAX_ITERATIONS -eq 0 ] || [ $iteration -lt $MAX_ITERATIONS ]; do
    iteration=$((iteration + 1))
    timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "[$timestamp] 🔍 Iteration $iteration - Scanning repositories..."

    # Check token type
    TOKEN_TYPE="unknown"
    CAN_PUSH="NO"

    if [[ "${GITHUB_TOKEN:-}" =~ ^ghp_ ]] || [[ "${GITHUB_TOKEN:-}" =~ ^gho_ ]]; then
        TOKEN_TYPE="Classic PAT"
        CAN_PUSH="YES"
    elif [[ "${GITHUB_TOKEN:-}" =~ ^ghu_ ]]; then
        TOKEN_TYPE="Integration"
        CAN_PUSH="NO"
    fi

    echo "  Token: $TOKEN_TYPE | Push capability: $CAN_PUSH"

    # Track total commits and successful pushes
    total_commits=0
    total_synced=0
    repos_with_commits=()

    # Scan all repositories
    for repo in "${REPOS[@]}"; do
        if [ ! -d "$repo/.git" ]; then
            continue
        fi

        cd "$repo"
        repo_name=$(basename "$repo")

        # Fetch latest (silent)
        git fetch origin main --quiet 2>/dev/null || true

        # Count commits ahead
        COMMITS_AHEAD=$(git log origin/main..HEAD --oneline 2>/dev/null | wc -l || echo "0")

        if [ "$COMMITS_AHEAD" -gt 0 ]; then
            total_commits=$((total_commits + COMMITS_AHEAD))
            repos_with_commits+=("$repo_name:$COMMITS_AHEAD")
            echo "    📦 $repo_name: $COMMITS_AHEAD commits pending"

            # Attempt push if capable
            if [ "$CAN_PUSH" = "YES" ]; then
                echo "    🚀 Pushing $repo_name..."
                if git push origin main 2>&1; then
                    echo "    ✅ $repo_name synced successfully"
                    total_synced=$((total_synced + 1))
                else
                    echo "    ⚠️  $repo_name push failed"
                fi
            fi
        fi
    done

    # Status summary
    if [ "$total_commits" -eq 0 ]; then
        echo "  ✅ All repositories in sync"

        if [ "$CAN_PUSH" = "YES" ]; then
            echo ""
            echo "═══════════════════════════════════════════════════════"
            echo "  ✅ MISSION COMPLETE - ALL REPOS SYNCED"
            echo "═══════════════════════════════════════════════════════"
            echo ""
            echo "All repositories successfully synchronized:"
            for repo in "${REPOS[@]}"; do
                echo "  ✓ $(basename "$repo")"
            done
            echo ""
            echo "Autonomous sync terminating successfully."

            # Create success notification
            cd /workspaces/dominion-os-demo-build
            gh api -X POST "/repos/Fractal5-Solutions/dominion-os-demo-build/issues" \
                -f title="[PHI Multi-Repo] ✓ All Repositories Synced" \
                -f body="**Multi-Repository Autonomous Sync Complete**

All Dominion repositories successfully synchronized:
- dominion-os-demo-build: ✓ Synced
- dominion-command-center: ✓ Synced

**System Status:**
- Token: Classic PAT
- Mode: NHITL Autonomous
- Duration: $((iteration * CHECK_INTERVAL))s
- Iterations: $iteration

Mission accomplished. No human intervention required." \
                2>/dev/null || echo "  (Notification creation skipped)"

            exit 0
        fi
    else
        echo "  📊 Total: $total_commits commits across ${#repos_with_commits[@]} repos"

        if [ "$CAN_PUSH" = "NO" ]; then
            echo "  ⏸️  Awaiting Classic PAT for autonomous push"
        elif [ "$total_synced" -gt 0 ]; then
            echo "  ✅ Synced $total_synced repos this iteration"
        fi
    fi

    echo ""

    # Wait for next iteration
    if [ $MAX_ITERATIONS -eq 0 ] || [ $iteration -lt $MAX_ITERATIONS ]; then
        sleep $CHECK_INTERVAL
    fi
done

echo "═══════════════════════════════════════════════════════"
echo "  Multi-repo sync monitor exiting after $iteration iterations"
echo "═══════════════════════════════════════════════════════"
