#!/bin/bash
# Apply branch protection to all unprotected repositories

export GH_TOKEN="YOUR_GITHUB_TOKEN"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     Applying Branch Protection to Unprotected Repositories        ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Date: $(date)"
echo "Organization: Fractal5-Solutions"
echo ""

# List of unprotected repositories (from audit)
UNPROTECTED_REPOS=(
  "dominion-os-1.0-gcloud"
  "dominion-3.0"
  "dominion-machine-language"
  "dominion-machine-maker"
  "dominion-machine-simulator"
  "dominion-neural-processing-unit"
  "dominion-gateway"
  "dominion-cybernetics"
  "dominion-os-1.0-desktop-linux"
  "dominion-os-1.0-desktop-pc"
  "dominion-os-1.0-politics"
  "dominion-os-1.0-desktop-mac"
  "fractal5-mobile-android"
  "dominion-os-2.0"
  "dominion-cloud-computer"
  "dominion-ai-gpu-local"
  "dominion-autocoder"
  "dominion-2083"
)

CONFIG_FILE="/workspaces/dominion-os-demo-build/scripts/branch-protection-standard.json"

if [ ! -f "$CONFIG_FILE" ]; then
  echo "❌ ERROR: Configuration file not found: $CONFIG_FILE"
  exit 1
fi

echo "Using configuration: $CONFIG_FILE"
echo "Total repositories to protect: ${#UNPROTECTED_REPOS[@]}"
echo ""
echo "⚠️  This will enable branch protection with:"
echo "   - Required pull request reviews (1 approver)"
echo "   - Code owner review required"
echo "   - Dismiss stale reviews"
echo "   - Required linear history"
echo "   - Block force pushes"
echo "   - Block deletions"
echo "   - Enforce for administrators"
echo ""

SUCCESS=0
FAILED=0
FAILED_REPOS=()

for REPO in "${UNPROTECTED_REPOS[@]}"; do
  echo -n "[$((SUCCESS + FAILED + 1))/${#UNPROTECTED_REPOS[@]}] Protecting $REPO ... "

  # Get default branch
  DEFAULT_BRANCH=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/Fractal5-Solutions/$REPO" | jq -r '.default_branch')

  if [ "$DEFAULT_BRANCH" = "null" ] || [ -z "$DEFAULT_BRANCH" ]; then
    echo "⚠️  SKIPPED (no default branch)"
    FAILED=$((FAILED + 1))
    FAILED_REPOS+=("$REPO (no default branch)")
    continue
  fi

  # Apply protection
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -X PUT \
    -H "Authorization: token $GH_TOKEN" \
    -H "Accept: application/vnd.github.v3+json" \
    "https://api.github.com/repos/Fractal5-Solutions/$REPO/branches/$DEFAULT_BRANCH/protection" \
    -d @"$CONFIG_FILE")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ SUCCESS"
    SUCCESS=$((SUCCESS + 1))
  else
    echo "❌ FAILED (HTTP $HTTP_CODE)"
    FAILED=$((FAILED + 1))
    FAILED_REPOS+=("$REPO (HTTP $HTTP_CODE)")
  fi

  # Small delay to avoid rate limiting
  sleep 0.5
done

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "                      APPLICATION SUMMARY                            "
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "Total Repositories Processed: ${#UNPROTECTED_REPOS[@]}"
echo "  ✅ Successfully Protected: $SUCCESS"
echo "  ❌ Failed: $FAILED"
echo ""

if [ $FAILED -gt 0 ]; then
  echo "❌ FAILED REPOSITORIES:"
  for REPO in "${FAILED_REPOS[@]}"; do
    echo "   - $REPO"
  done
  echo ""
fi

# Calculate new total protection coverage
TOTAL_REPOS=23
PREVIOUSLY_PROTECTED=3  # dominion-command-center, dominion-AGI, dominion-os-demo-build
NEW_TOTAL=$((PREVIOUSLY_PROTECTED + SUCCESS))
COVERAGE=$(( (NEW_TOTAL * 100) / TOTAL_REPOS ))

echo "📊 New Overall Coverage:"
echo "   Protected: $NEW_TOTAL / $TOTAL_REPOS repositories ($COVERAGE%)"
echo ""

if [ $SUCCESS -gt 0 ]; then
  echo "✅ Branch protection successfully applied to $SUCCESS repositories"
fi

if [ $FAILED -eq 0 ]; then
  echo "✅ All repositories now protected!"
  echo ""
  echo "🎯 COMPLIANCE STATUS: EXCELLENT"
else
  echo "⚠️  Review failed repositories and apply protection manually if needed"
fi

echo ""
echo "════════════════════════════════════════════════════════════════════"
