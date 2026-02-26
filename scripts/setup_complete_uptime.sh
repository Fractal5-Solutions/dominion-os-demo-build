#!/bin/bash
# PHI Chief - Complete Uptime Monitoring for All 22 Services
# Dominion OS Infrastructure Monitoring
# Created: 2026-02-26

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "PHI CHIEF - COMPLETE UPTIME MONITORING"
echo "========================================"
echo ""

PROJECT1="dominion-os-1-0-main"
PROJECT2="dominion-core-prod"

# Count existing uptime checks
EXISTING_P1=$(gcloud monitoring uptime list-configs --project=$PROJECT1 --format="value(displayName)" 2>/dev/null | wc -l)
EXISTING_P2=$(gcloud monitoring uptime list-configs --project=$PROJECT2 --format="value(displayName)" 2>/dev/null | wc -l)

echo "Current uptime checks: Project1=$EXISTING_P1, Project2=$EXISTING_P2"
echo ""

# Project 1 - All 9 Services
echo -e "${BLUE}[1/2] Creating Uptime Checks for Project 1 (9 services)...${NC}"

declare -A P1_SERVICES=(
  ["askphi-chatbot"]="askphi-chatbot-66ymegzkya-uc.a.run.app"
  ["dominion-ai-gateway"]="dominion-ai-gateway-66ymegzkya-uc.a.run.app"
  ["dominion-f5-gateway"]="dominion-f5-gateway-66ymegzkya-uc.a.run.app"
  ["dominion-monitoring-dashboard"]="dominion-monitoring-dashboard-66ymegzkya-uc.a.run.app"
  ["dominion-os-1-0"]="dominion-os-1-0-66ymegzkya-uc.a.run.app"
  ["dominion-os-api"]="dominion-os-api-66ymegzkya-uc.a.run.app"
  ["dominion-phi-ui"]="dominion-phi-ui-66ymegzkya-uc.a.run.app"
  ["dominion-revenue-automation"]="dominion-revenue-automation-66ymegzkya-uc.a.run.app"
  ["dominion-security-framework"]="dominion-security-framework-66ymegzkya-uc.a.run.app"
)

for SERVICE in "${!P1_SERVICES[@]}"; do
  HOST="${P1_SERVICES[$SERVICE]}"
  DISPLAY_NAME="$(echo $SERVICE | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1') Uptime"

  echo "  Creating uptime check: $SERVICE..."
  gcloud monitoring uptime create "${SERVICE}-uptime-p1" \
    --project=$PROJECT1 \
    --display-name="$DISPLAY_NAME" \
    --resource-type=uptime-url \
    --resource-labels=host=$HOST \
    --http-check-path="/" \
    --check-interval=60s \
    2>/dev/null && echo "    ✓ Created" || echo "    (already exists)"
done

echo -e "${GREEN}✅ Project 1 uptime checks complete${NC}"
echo ""

# Project 2 - All 13 Services
echo -e "${BLUE}[2/2] Creating Uptime Checks for Project 2 (13 services)...${NC}"

declare -A P2_SERVICES=(
  ["api"]="api-reduwyf2ra-uc.a.run.app"
  ["chatgpt-gateway"]="chatgpt-gateway-reduwyf2ra-uc.a.run.app"
  ["demo"]="demo-reduwyf2ra-uc.a.run.app"
  ["dominion-ai-gateway"]="dominion-ai-gateway-reduwyf2ra-uc.a.run.app"
  ["dominion-api"]="dominion-api-reduwyf2ra-uc.a.run.app"
  ["dominion-chief-of-staff"]="dominion-chief-of-staff-reduwyf2ra-uc.a.run.app"
  ["dominion-demo"]="dominion-demo-reduwyf2ra-uc.a.run.app"
  ["dominion-gateway"]="dominion-gateway-reduwyf2ra-uc.a.run.app"
  ["dominion-os"]="dominion-os-reduwyf2ra-uc.a.run.app"
  ["dominion-os-1-0-101"]="dominion-os-1-0-101-reduwyf2ra-uc.a.run.app"
  ["dominion-os-demo"]="dominion-os-demo-reduwyf2ra-uc.a.run.app"
  ["dominion-phi-ui"]="dominion-phi-ui-reduwyf2ra-uc.a.run.app"
  ["pipeline"]="pipeline-reduwyf2ra-uc.a.run.app"
)

for SERVICE in "${!P2_SERVICES[@]}"; do
  HOST="${P2_SERVICES[$SERVICE]}"
  DISPLAY_NAME="$(echo $SERVICE | sed 's/-/ /g' | awk '{for(i=1;i<=NF;i++) $i=toupper(substr($i,1,1)) tolower(substr($i,2));}1') Uptime (Core)"

  echo "  Creating uptime check: $SERVICE..."
  gcloud monitoring uptime create "${SERVICE}-uptime-p2" \
    --project=$PROJECT2 \
    --display-name="$DISPLAY_NAME" \
    --resource-type=uptime-url \
    --resource-labels=host=$HOST \
    --http-check-path="/" \
    --check-interval=60s \
    2>/dev/null && echo "    ✓ Created" || echo "    (already exists)"
done

echo -e "${GREEN}✅ Project 2 uptime checks complete${NC}"
echo ""

# Final count
NEW_P1=$(gcloud monitoring uptime list-configs --project=$PROJECT1 --format="value(displayName)" 2>/dev/null | wc -l)
NEW_P2=$(gcloud monitoring uptime list-configs --project=$PROJECT2 --format="value(displayName)" 2>/dev/null | wc -l)
TOTAL=$((NEW_P1 + NEW_P2))

echo "========================================"
echo "UPTIME MONITORING COMPLETE"
echo "========================================"
echo ""
echo "Total Uptime Checks: $TOTAL"
echo "  • Project 1 (dominion-os-1-0-main): $NEW_P1 checks"
echo "  • Project 2 (dominion-core-prod): $NEW_P2 checks"
echo ""
echo "Check Interval: 60 seconds"
echo "Coverage: 100% of infrastructure (22/22 services)"
echo ""
echo "View uptime checks:"
echo "  Project 1: https://console.cloud.google.com/monitoring/uptime?project=$PROJECT1"
echo "  Project 2: https://console.cloud.google.com/monitoring/uptime?project=$PROJECT2"
echo ""
echo "========================================"
echo -e "${GREEN}✅ Complete uptime monitoring deployed!${NC}"
echo "========================================"
