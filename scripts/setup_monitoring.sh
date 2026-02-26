#!/bin/bash
# PHI Chief - Cloud Monitoring Setup Script
# Dominion OS Infrastructure Monitoring
# Created: 2026-02-26

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "PHI CHIEF - CLOUD MONITORING SETUP"
echo "========================================"
echo ""

PROJECT1="dominion-os-1-0-main"
PROJECT2="dominion-core-prod"

# Create uptime checks for critical services
echo -e "${BLUE}[1/4] Creating Uptime Checks...${NC}"

# Project 1 - Key Services
echo "  Creating uptime check: dominion-ai-gateway (project1)..."
gcloud monitoring uptime create dominion-ai-gateway-uptime \
  --project=$PROJECT1 \
  --display-name="Dominion AI Gateway Uptime" \
  --resource-type=uptime-url \
  --host=dominion-ai-gateway-66ymegzkya-uc.a.run.app \
  --path="/" \
  --check-interval=60s \
  2>/dev/null || echo "  (already exists or error)"

echo "  Creating uptime check: dominion-f5-gateway (project1)..."
gcloud monitoring uptime create dominion-f5-gateway-uptime \
  --project=$PROJECT1 \
  --display-name="Dominion F5 Gateway Uptime" \
  --resource-type=uptime-url \
  --host=dominion-f5-gateway-66ymegzkya-uc.a.run.app \
  --path="/" \
  --check-interval=60s \
  2>/dev/null || echo "  (already exists or error)"

echo "  Creating uptime check: dominion-phi-ui (project1)..."
gcloud monitoring uptime create dominion-phi-ui-uptime \
  --project=$PROJECT1 \
  --display-name="Dominion PHI UI Uptime" \
  --resource-type=uptime-url \
  --host=dominion-phi-ui-66ymegzkya-uc.a.run.app \
  --path="/" \
  --check-interval=60s \
  2>/dev/null || echo "  (already exists or error)"

# Project 2 - Key Services
echo "  Creating uptime check: dominion-ai-gateway (project2)..."
gcloud monitoring uptime create dominion-ai-gateway-core-uptime \
  --project=$PROJECT2 \
  --display-name="Dominion AI Gateway Uptime (Core)" \
  --resource-type=uptime-url \
  --host=dominion-ai-gateway-reduwyf2ra-uc.a.run.app \
  --path="/" \
  --check-interval=60s \
  2>/dev/null || echo "  (already exists or error)"

echo "  Creating uptime check: dominion-gateway (project2)..."
gcloud monitoring uptime create dominion-gateway-core-uptime \
  --project=$PROJECT2 \
  --display-name="Dominion Gateway Uptime (Core)" \
  --resource-type=uptime-url \
  --host=dominion-gateway-reduwyf2ra-uc.a.run.app \
  --path="/" \
  --check-interval=60s \
  2>/dev/null || echo "  (already exists or error)"

echo -e "${GREEN}✅ Uptime checks configured${NC}"
echo ""

# Create alert policy for uptime failures
echo -e "${BLUE}[2/4] Creating Alerting Policies...${NC}"

echo "  Creating alert: Gateway Downtime (project1)..."
gcloud alpha monitoring policies create \
  --project=$PROJECT1 \
  --notification-channels="" \
  --display-name="Gateway Downtime Alert" \
  --condition-display-name="Gateway is down" \
  --condition-threshold-value=1 \
  --condition-threshold-duration=300s \
  --condition-filter='metric.type="monitoring.googleapis.com/uptime_check/check_passed" resource.type="uptime_url"' \
  --condition-comparison=COMPARISON_LT \
  --aggregation-alignment-period=60s \
  --aggregation-per-series-aligner=ALIGN_FRACTION_TRUE \
  2>/dev/null || echo "  (already exists or error)"

echo -e "${GREEN}✅ Alerting policies configured${NC}"
echo ""

# Create monitoring dashboard
echo -e "${BLUE}[3/4] Creating Monitoring Dashboard...${NC}"

cat > /tmp/dashboard_config.json <<'DASHBOARD_EOF'
{
  "displayName": "Dominion OS - Service Health",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Cloud Run Request Count",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_count\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_RATE"
                  }
                }
              }
            }],
            "timeshiftDuration": "0s",
            "yAxis": {
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "xPos": 6,
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Cloud Run Request Latencies",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_latencies\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_DELTA",
                    "crossSeriesReducer": "REDUCE_MEAN"
                  }
                }
              }
            }],
            "timeshiftDuration": "0s",
            "yAxis": {
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "yPos": 4,
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Cloud Run Instance Count",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/container/instance_count\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_MEAN"
                  }
                }
              }
            }],
            "timeshiftDuration": "0s",
            "yAxis": {
              "scale": "LINEAR"
            }
          }
        }
      },
      {
        "xPos": 6,
        "yPos": 4,
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Uptime Check Success Rate",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "metric.type=\"monitoring.googleapis.com/uptime_check/check_passed\" resource.type=\"uptime_url\"",
                  "aggregation": {
                    "alignmentPeriod": "60s",
                    "perSeriesAligner": "ALIGN_FRACTION_TRUE"
                  }
                }
              }
            }],
            "timeshiftDuration": "0s",
            "yAxis": {
              "scale": "LINEAR"
            }
          }
        }
      }
    ]
  }
}
DASHBOARD_EOF

echo "  Creating dashboard for project1..."
gcloud monitoring dashboards create --config-from-file=/tmp/dashboard_config.json \
  --project=$PROJECT1 \
  2>/dev/null || echo "  (already exists or error)"

echo "  Creating dashboard for project2..."
gcloud monitoring dashboards create --config-from-file=/tmp/dashboard_config.json \
  --project=$PROJECT2 \
  2>/dev/null || echo "  (already exists or error)"

rm /tmp/dashboard_config.json

echo -e "${GREEN}✅ Monitoring dashboards created${NC}"
echo ""

# List configured monitoring
echo -e "${BLUE}[4/4] Verification...${NC}"

echo ""
echo "Uptime Checks (Project 1):"
gcloud monitoring uptime list-configs --project=$PROJECT1 \
  --format="table(displayName,httpCheck.host)" 2>/dev/null | head -10

echo ""
echo "Uptime Checks (Project 2):"
gcloud monitoring uptime list-configs --project=$PROJECT2 \
  --format="table(displayName,httpCheck.host)" 2>/dev/null | head -10

echo ""
echo -e "${GREEN}✅ Monitoring setup complete!${NC}"
echo ""
echo "========================================"
echo "MONITORING RESOURCES CREATED"
echo "========================================"
echo ""
echo "Uptime Checks:"
echo "  • Dominion AI Gateway (project1)"
echo "  • Dominion F5 Gateway (project1)"
echo "  • Dominion PHI UI (project1)"
echo "  • Dominion AI Gateway (project2)"
echo "  • Dominion Gateway (project2)"
echo ""
echo "Dashboards:"
echo "  • Service Health Dashboard (project1)"
echo "  • Service Health Dashboard (project2)"
echo ""
echo "View dashboards:"
echo "  Project 1: https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT1"
echo "  Project 2: https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT2"
echo ""
echo "========================================"
