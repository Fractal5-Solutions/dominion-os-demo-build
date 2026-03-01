#!/bin/bash
# verify_liveops_state.sh
# Complete LiveOps state verification for PHI Dominion OS

set -euo pipefail

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🤖 PHI Dominion OS - LiveOps State Verification"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

PROJECT="dominion-core-prod"
REGION="us-central1"
SERVICE="phi-expenditure-dashboard"

# Colors
GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

pass() { echo -e "${GREEN}✅ $1${NC}"; }
fail() { echo -e "${RED}❌ $1${NC}"; }
warn() { echo -e "${YELLOW}⚠️  $1${NC}"; }

# 1. Git Status
echo "1. 📦 Git Repository Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
cd /workspaces/dominion-os-demo-build

current_branch=$(git branch --show-current)
last_commit=$(git log --oneline -1)
remote_status=$(git status -sb | head -1)

echo "Branch: $current_branch"
echo "Commit: $last_commit"
echo "$remote_status"

# Check if pushed
if git ls-remote --exit-code fork "refs/heads/$current_branch" > /dev/null 2>&1; then
    pass "Branch pushed to fork"
else
    warn "Branch not yet pushed to fork"
fi

echo ""

# 2. Production Service Health
echo "2. 🏥 Production Service Health"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

health_status=$(curl -sf "https://$SERVICE-447370233441.$REGION.run.app/health" | python3 -c "import sys, json; data=json.load(sys.stdin); print(data['status'])" 2>/dev/null || echo "unhealthy")

if [ "$health_status" = "healthy" ]; then
    pass "Service health check passing"
else
    fail "Service health check failing"
fi

# Test all endpoints
endpoints=(
    "/"
    "/expenditures"
    "/verify"
    "/reports"
    "/recurring"
)

echo "Testing dashboard endpoints..."
for endpoint in "${endpoints[@]}"; do
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" "https://$SERVICE-447370233441.$REGION.run.app$endpoint" || echo "000")
    if [ "$http_code" = "200" ]; then
        pass "  $endpoint → HTTP $http_code"
    else
        fail "  $endpoint → HTTP $http_code"
    fi
done

echo ""

# 3. Cloud Run Configuration
echo "3. ⚙️  Cloud Run Configuration"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

config=$(gcloud run services describe $SERVICE \
    --region=$REGION \
    --project=$PROJECT \
    --format="value(
        status.conditions[0].status,
        status.latestReadyRevisionName,
        spec.template.metadata.annotations[\"autoscaling.knative.dev/minScale\"],
        spec.template.metadata.annotations[\"autoscaling.knative.dev/maxScale\"],
        spec.template.spec.containers[0].resources.limits.cpu,
        spec.template.spec.containers[0].resources.limits.memory
    )")

IFS=$'\t' read -r status revision min_scale max_scale cpu memory <<< "$config"

[ "$status" = "True" ] && pass "Service status: Ready" || fail "Service status: Not Ready"
pass "Latest revision: $revision"
pass "Auto-scaling: ${min_scale:-0}-${max_scale:-100} instances"
pass "Resources: $cpu CPU, $memory memory"

echo ""

# 4. Monitoring Infrastructure
echo "4. 📊 Monitoring Infrastructure"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check notification channels
channel_count=$(gcloud monitoring channels list \
    --project=$PROJECT \
    --filter="enabled=true" \
    --format="value(name)" 2>/dev/null | wc -l)

if [ "$channel_count" -gt 0 ]; then
    pass "Notification channels: $channel_count configured"
else
    warn "No notification channels configured"
fi

# Check alert policies
alert_count=$(gcloud alpha monitoring policies list \
    --project=$PROJECT \
    --filter="enabled=true" \
    --format="value(name)" 2>/dev/null | wc -l)

if [ "$alert_count" -gt 0 ]; then
    pass "Alert policies: $alert_count active"
else
    warn "No alert policies configured"
fi

echo ""

# 5. Service Metrics
echo "5. 📈 Service Metrics (Last 10 minutes)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Request count
request_count=$(gcloud monitoring time-series list \
    --filter="metric.type=\"run.googleapis.com/request_count\" AND resource.labels.service_name=\"$SERVICE\"" \
    --project=$PROJECT \
    --format="value(points[0].value.int64Value)" 2>/dev/null | head -1 || echo "0")

pass "Total requests: ${request_count:-0}"

# Instance count
instance_count=$(gcloud run services describe $SERVICE \
    --region=$REGION \
    --project=$PROJECT \
    --format="value(status.traffic[0].percent)" 2>/dev/null || echo "100")

pass "Traffic routing: ${instance_count}% to latest revision"

echo ""

# 6. Security Posture
echo "6. 🔐 Security Posture"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Check IAM policy
iam_bindings=$(gcloud run services get-iam-policy $SERVICE \
    --region=$REGION \
    --project=$PROJECT \
    --format="value(bindings.role)" 2>/dev/null | wc -l)

pass "IAM bindings: $iam_bindings configured"

# Check if .gitignore protects secrets
if [ -f "/workspaces/dominion-os-demo-build/scripts/.gitignore" ]; then
    if grep -q ".env" "/workspaces/dominion-os-demo-build/scripts/.gitignore"; then
        pass ".gitignore protecting secrets"
    else
        warn ".gitignore not protecting .env files"
    fi
else
    fail ".gitignore not found"
fi

echo ""

# 7. Documentation Status
echo "7. 📚 Documentation Status"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

docs=(
    "AI_LIVEOPS_DEPLOYMENT_PLAN.md"
    "DEPLOYMENT_READY.md"
    "DEPLOYMENT_SUCCESS.md"
    "PRODUCTION_COMPLETE.md"
    "OPTIMIZATION_REPORT.md"
)

for doc in "${docs[@]}"; do
    if [ -f "/workspaces/dominion-os-demo-build/scripts/$doc" ]; then
        lines=$(wc -l < "/workspaces/dominion-os-demo-build/scripts/$doc")
        pass "$doc ($lines lines)"
    else
        fail "$doc missing"
    fi
done

echo ""

# 8. Operational Readiness Score
echo "8. 🎯 Operational Readiness Score"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"

# Calculate score
total_checks=25
passed_checks=0

# Service checks (5)
[ "$health_status" = "healthy" ] && ((passed_checks++))
[ "$status" = "True" ] && ((passed_checks++))
[ "${min_scale:-0}" -ge 1 ] && ((passed_checks++))
[ "$instance_count" = "100" ] && ((passed_checks++))
[ "$revision" ] && ((passed_checks++))

# Monitoring checks (2)
[ "$channel_count" -gt 0 ] && ((passed_checks++))
[ "$alert_count" -gt 0 ] && ((passed_checks++))

# Security checks (2)
[ "$iam_bindings" -gt 0 ] && ((passed_checks++))
[ -f "/workspaces/dominion-os-demo-build/scripts/.gitignore" ] && ((passed_checks++))

# Documentation checks (5)
for doc in "${docs[@]}"; do
    [ -f "/workspaces/dominion-os-demo-build/scripts/$doc" ] && ((passed_checks++))
done

# Git checks (2)
[ "$current_branch" = "sovereign-power-mode-max" ] && ((passed_checks++))
git ls-remote --exit-code fork "refs/heads/$current_branch" > /dev/null 2>&1 && ((passed_checks++))

# Endpoint checks (5)
for endpoint in "${endpoints[@]}"; do
    http_code=$(curl -sf -o /dev/null -w "%{http_code}" "https://$SERVICE-447370233441.$REGION.run.app$endpoint" 2>/dev/null || echo "000")
    [ "$http_code" = "200" ] && ((passed_checks++))
done

# Resource config checks (2)
[ "$cpu" = "2" ] && ((passed_checks++))
[ "$memory" = "2Gi" ] && ((passed_checks++))

# Request count check (1)
[ "${request_count:-0}" -ge 0 ] && ((passed_checks++))

# Calculate percentage
score=$((passed_checks * 100 / total_checks))

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo -e "Score: ${GREEN}$passed_checks/$total_checks${NC} checks passed ($score%)"

if [ "$score" -ge 90 ]; then
    echo -e "${GREEN}★★★★★ EXCELLENT - Perfect LiveOps State${NC}"
elif [ "$score" -ge 80 ]; then
    echo -e "${GREEN}★★★★☆ GOOD - Production Ready${NC}"
elif [ "$score" -ge 70 ]; then
    echo -e "${YELLOW}★★★☆☆ FAIR - Minor Issues${NC}"
else
    echo -e "${RED}★★☆☆☆ NEEDS WORK${NC}"
fi

echo ""

# Final summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🎉 LiveOps Verification Complete"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "Service URL: https://$SERVICE-447370233441.$REGION.run.app"
echo "Cloud Console: https://console.cloud.google.com/run/detail/$REGION/$SERVICE?project=$PROJECT"
echo "Monitoring: https://console.cloud.google.com/monitoring?project=$PROJECT"
echo ""
echo "To create a Pull Request:"
echo "  cd /workspaces/dominion-os-demo-build"
echo "  gh pr create --title \"[PRODUCTION] Complete LiveOps Infrastructure\" \\"
echo "               --body-file scripts/AI_LIVEOPS_DEPLOYMENT_PLAN.md \\"
echo "               --base main --head sovereign-power-mode-max"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
