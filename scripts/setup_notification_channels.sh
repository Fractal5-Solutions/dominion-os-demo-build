#!/bin/bash
# PHI Chief - Notification Channels Setup
# Dominion OS Infrastructure Monitoring
# Created: 2026-02-26

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "PHI CHIEF - NOTIFICATION CHANNELS SETUP"
echo "========================================"
echo ""

PROJECT1="dominion-os-1-0-main"
PROJECT2="dominion-core-prod"
EMAIL="matthewburbidge@fractal5solutions.com"

# Create email notification channels
echo -e "${BLUE}[1/3] Creating Email Notification Channels...${NC}"

echo "  Creating email channel for project1..."
gcloud alpha monitoring channels create \
  --project=$PROJECT1 \
  --display-name="PHI Chief Email Alerts" \
  --type=email \
  --channel-labels=email_address=$EMAIL \
  2>/dev/null || echo "  (already exists or error)"

echo "  Creating email channel for project2..."
gcloud alpha monitoring channels create \
  --project=$PROJECT2 \
  --display-name="PHI Chief Email Alerts" \
  --type=email \
  --channel-labels=email_address=$EMAIL \
  2>/dev/null || echo "  (already exists or error)"

echo -e "${GREEN}✅ Email notification channels configured${NC}"
echo ""

# Get channel IDs for linking to policies
echo -e "${BLUE}[2/3] Retrieving Notification Channel IDs...${NC}"

CHANNEL_ID_P1=$(gcloud alpha monitoring channels list \
  --project=$PROJECT1 \
  --filter="displayName:'PHI Chief Email Alerts'" \
  --format="value(name)" 2>/dev/null | head -1)

CHANNEL_ID_P2=$(gcloud alpha monitoring channels list \
  --project=$PROJECT2 \
  --filter="displayName:'PHI Chief Email Alerts'" \
  --format="value(name)" 2>/dev/null | head -1)

if [ -n "$CHANNEL_ID_P1" ]; then
  echo "  Project 1 Channel: $CHANNEL_ID_P1"
else
  echo "  ⚠️  Project 1 Channel not found"
fi

if [ -n "$CHANNEL_ID_P2" ]; then
  echo "  Project 2 Channel: $CHANNEL_ID_P2"
else
  echo "  ⚠️  Project 2 Channel not found"
fi

echo ""

# Update existing alert policies with notification channels
echo -e "${BLUE}[3/3] Linking Alert Policies to Notification Channels...${NC}"

if [ -n "$CHANNEL_ID_P1" ]; then
  echo "  Updating alert policies for project1..."

  # Get all policy IDs
  POLICY_IDS=$(gcloud alpha monitoring policies list \
    --project=$PROJECT1 \
    --format="value(name)" 2>/dev/null)

  for POLICY_ID in $POLICY_IDS; do
    echo "    Updating policy: $(basename $POLICY_ID)"
    gcloud alpha monitoring policies update "$POLICY_ID" \
      --project=$PROJECT1 \
      --notification-channels="$CHANNEL_ID_P1" \
      2>/dev/null || echo "      (update failed or already configured)"
  done
fi

if [ -n "$CHANNEL_ID_P2" ]; then
  echo "  Updating alert policies for project2..."

  # Get all policy IDs
  POLICY_IDS=$(gcloud alpha monitoring policies list \
    --project=$PROJECT2 \
    --format="value(name)" 2>/dev/null)

  for POLICY_ID in $POLICY_IDS; do
    echo "    Updating policy: $(basename $POLICY_ID)"
    gcloud alpha monitoring policies update "$POLICY_ID" \
      --project=$PROJECT2 \
      --notification-channels="$CHANNEL_ID_P2" \
      2>/dev/null || echo "      (update failed or already configured)"
  done
fi

echo -e "${GREEN}✅ Alert policies linked to notification channels${NC}"
echo ""

# Verification
echo "========================================"
echo "NOTIFICATION CHANNELS CONFIGURED"
echo "========================================"
echo ""
echo "Notification Channels:"
echo ""

echo "Project 1 (dominion-os-1-0-main):"
gcloud alpha monitoring channels list \
  --project=$PROJECT1 \
  --format="table(displayName,type,labels)" 2>/dev/null || echo "  (no channels found)"

echo ""
echo "Project 2 (dominion-core-prod):"
gcloud alpha monitoring channels list \
  --project=$PROJECT2 \
  --format="table(displayName,type,labels)" 2>/dev/null || echo "  (no channels found)"

echo ""
echo "Alert Policies with Notifications:"
echo ""

echo "Project 1:"
gcloud alpha monitoring policies list \
  --project=$PROJECT1 \
  --format="table(displayName,notificationChannels)" 2>/dev/null | head -10

echo ""
echo "Project 2:"
gcloud alpha monitoring policies list \
  --project=$PROJECT2 \
  --format="table(displayName,notificationChannels)" 2>/dev/null | head -10

echo ""
echo -e "${GREEN}✅ Notification channels setup complete!${NC}"
echo ""
echo "Email alerts will be sent to: $EMAIL"
echo ""
echo "========================================"
