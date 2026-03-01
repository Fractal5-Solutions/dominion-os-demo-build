#!/bin/bash
# Audit remaining 19 repositories for branch protection status

export GH_TOKEN="YOUR_GITHUB_TOKEN"

echo "╔════════════════════════════════════════════════════════════════════╗"
echo "║     Branch Protection Audit - Remaining 19 Repositories           ║"
echo "╚════════════════════════════════════════════════════════════════════╝"
echo ""
echo "Date: $(date)"
echo "Organization: Fractal5-Solutions"
echo ""

# List of repositories to audit (excluding already checked ones)
REPOS=(
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
  "dominion-os-demo-build"
)

PROTECTED=0
NOT_PROTECTED=0
NO_BRANCH=0
ERROR=0

PROTECTED_REPOS=()
NOT_PROTECTED_REPOS=()
NO_BRANCH_REPOS=()

echo "Checking ${#REPOS[@]} repositories..."
echo ""

for REPO in "${REPOS[@]}"; do
  echo -n "[$((PROTECTED + NOT_PROTECTED + NO_BRANCH + ERROR + 1))/${#REPOS[@]}] $REPO ... "

  # First check if repo has a default branch
  BRANCH_INFO=$(curl -s -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/Fractal5-Solutions/$REPO" | jq -r '.default_branch')

  if [ "$BRANCH_INFO" = "null" ] || [ -z "$BRANCH_INFO" ]; then
    echo "⚠️  NO DEFAULT BRANCH"
    NO_BRANCH=$((NO_BRANCH + 1))
    NO_BRANCH_REPOS+=("$REPO")
    continue
  fi

  # Check branch protection
  HTTP_CODE=$(curl -s -o /dev/null -w "%{http_code}" \
    -H "Authorization: token $GH_TOKEN" \
    "https://api.github.com/repos/Fractal5-Solutions/$REPO/branches/$BRANCH_INFO/protection")

  if [ "$HTTP_CODE" = "200" ]; then
    echo "✅ PROTECTED"
    PROTECTED=$((PROTECTED + 1))
    PROTECTED_REPOS+=("$REPO")
  elif [ "$HTTP_CODE" = "404" ]; then
    echo "❌ NOT PROTECTED"
    NOT_PROTECTED=$((NOT_PROTECTED + 1))
    NOT_PROTECTED_REPOS+=("$REPO")
  else
    echo "⚠️  ERROR (HTTP $HTTP_CODE)"
    ERROR=$((ERROR + 1))
  fi
done

echo ""
echo "════════════════════════════════════════════════════════════════════"
echo "                          AUDIT SUMMARY                              "
echo "════════════════════════════════════════════════════════════════════"
echo ""
echo "Total Repositories Audited: ${#REPOS[@]}"
echo "  ✅ Protected: $PROTECTED"
echo "  ❌ Not Protected: $NOT_PROTECTED"
echo "  ⚠️  No Default Branch: $NO_BRANCH"
echo "  ⚠️  Errors: $ERROR"
echo ""

if [ $PROTECTED -gt 0 ]; then
  echo "✅ PROTECTED REPOSITORIES ($PROTECTED):"
  for REPO in "${PROTECTED_REPOS[@]}"; do
    echo "   - $REPO"
  done
  echo ""
fi

if [ $NOT_PROTECTED -gt 0 ]; then
  echo "❌ NOT PROTECTED REPOSITORIES ($NOT_PROTECTED):"
  for REPO in "${NOT_PROTECTED_REPOS[@]}"; do
    echo "   - $REPO"
  done
  echo ""
fi

if [ $NO_BRANCH -gt 0 ]; then
  echo "⚠️  NO DEFAULT BRANCH ($NO_BRANCH):"
  for REPO in "${NO_BRANCH_REPOS[@]}"; do
    echo "   - $REPO"
  done
  echo ""
fi

echo "════════════════════════════════════════════════════════════════════"
echo ""

# Calculate total protection coverage
TOTAL_CHECKED=23  # Total repos in Fractal5-Solutions
TOTAL_PROTECTED=$((PROTECTED + 2))  # +2 for Crystal-Architect and dominion-AGI already done
COVERAGE=$(( (TOTAL_PROTECTED * 100) / TOTAL_CHECKED ))

echo "📊 Overall Coverage:"
echo "   Protected: $TOTAL_PROTECTED / $TOTAL_CHECKED repositories ($COVERAGE%)"
echo ""

if [ $NOT_PROTECTED -gt 0 ]; then
  echo "🚨 ACTION REQUIRED:"
  echo "   $NOT_PROTECTED repositories need branch protection enabled"
  echo ""
  echo "   Run: ./apply_protection_to_unprotected.sh"
fi

echo "✅ Audit complete"
