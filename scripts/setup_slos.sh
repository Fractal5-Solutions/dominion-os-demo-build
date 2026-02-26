#!/bin/bash
# PHI Chief - Service Level Objectives (SLO) Definition
# Dominion OS Critical Services Performance Targets
# Created: 2026-02-26

set -e

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "========================================"
echo "PHI CHIEF - SLO DEFINITION & DEPLOYMENT"
echo "========================================"
echo ""

PROJECT1="dominion-os-1-0-main"
PROJECT2="dominion-core-prod"

echo -e "${BLUE}[1/3] Creating SLOs for Critical Services...${NC}"
echo ""

# SLO 1: dominion-ai-gateway (Project 1) - Availability
echo "  Creating SLO: dominion-ai-gateway (P1) - Availability Target"
cat > /tmp/slo_gateway_p1_availability.json <<'SLO1_EOF'
{
  "displayName": "AI Gateway Availability (99.9%)",
  "serviceLevelIndicator": {
    "requestBased": {
      "goodTotalRatio": {
        "goodServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-ai-gateway\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"5xx\"",
        "totalServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-ai-gateway\" metric.type=\"run.googleapis.com/request_count\""
      }
    }
  },
  "goal": 0.999,
  "rollingPeriod": "2592000s"
}
SLO1_EOF

gcloud monitoring slos create \
  --service=dominion-ai-gateway \
  --config-from-file=/tmp/slo_gateway_p1_availability.json \
  --project=$PROJECT1 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# SLO 2: dominion-ai-gateway (Project 1) - Latency
echo "  Creating SLO: dominion-ai-gateway (P1) - Latency Target"
cat > /tmp/slo_gateway_p1_latency.json <<'SLO2_EOF'
{
  "displayName": "AI Gateway Latency (95% < 500ms)",
  "serviceLevelIndicator": {
    "requestBased": {
      "distributionCut": {
        "distributionFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-ai-gateway\" metric.type=\"run.googleapis.com/request_latencies\"",
        "range": {
          "max": 500
        }
      }
    }
  },
  "goal": 0.95,
  "rollingPeriod": "2592000s"
}
SLO2_EOF

gcloud monitoring slos create \
  --service=dominion-ai-gateway \
  --config-from-file=/tmp/slo_gateway_p1_latency.json \
  --project=$PROJECT1 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# SLO 3: dominion-phi-ui (Project 1) - Availability
echo "  Creating SLO: dominion-phi-ui (P1) - Availability Target"
cat > /tmp/slo_phi_ui_p1_availability.json <<'SLO3_EOF'
{
  "displayName": "PHI UI Availability (99.9%)",
  "serviceLevelIndicator": {
    "requestBased": {
      "goodTotalRatio": {
        "goodServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-phi-ui\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"5xx\"",
        "totalServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-phi-ui\" metric.type=\"run.googleapis.com/request_count\""
      }
    }
  },
  "goal": 0.999,
  "rollingPeriod": "2592000s"
}
SLO3_EOF

gcloud monitoring slos create \
  --service=dominion-phi-ui \
  --config-from-file=/tmp/slo_phi_ui_p1_availability.json \
  --project=$PROJECT1 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# SLO 4: dominion-os-api (Project 1) - Availability
echo "  Creating SLO: dominion-os-api (P1) - Availability Target"
cat > /tmp/slo_os_api_p1_availability.json <<'SLO4_EOF'
{
  "displayName": "OS API Availability (99.9%)",
  "serviceLevelIndicator": {
    "requestBased": {
      "goodTotalRatio": {
        "goodServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-os-api\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"5xx\"",
        "totalServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-os-api\" metric.type=\"run.googleapis.com/request_count\""
      }
    }
  },
  "goal": 0.999,
  "rollingPeriod": "2592000s"
}
SLO4_EOF

gcloud monitoring slos create \
  --service=dominion-os-api \
  --config-from-file=/tmp/slo_os_api_p1_availability.json \
  --project=$PROJECT1 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# SLO 5: dominion-gateway (Project 2) - Availability
echo "  Creating SLO: dominion-gateway (P2) - Availability Target"
cat > /tmp/slo_gateway_p2_availability.json <<'SLO5_EOF'
{
  "displayName": "Gateway Availability (99.9%)",
  "serviceLevelIndicator": {
    "requestBased": {
      "goodTotalRatio": {
        "goodServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-gateway\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"5xx\"",
        "totalServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-gateway\" metric.type=\"run.googleapis.com/request_count\""
      }
    }
  },
  "goal": 0.999,
  "rollingPeriod": "2592000s"
}
SLO5_EOF

gcloud monitoring slos create \
  --service=dominion-gateway \
  --config-from-file=/tmp/slo_gateway_p2_availability.json \
  --project=$PROJECT2 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# SLO 6: dominion-phi-ui (Project 2) - Availability
echo "  Creating SLO: dominion-phi-ui (P2) - Availability Target"
cat > /tmp/slo_phi_ui_p2_availability.json <<'SLO6_EOF'
{
  "displayName": "PHI UI Availability (99.9%)",
  "serviceLevelIndicator": {
    "requestBased": {
      "goodTotalRatio": {
        "goodServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-phi-ui\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"5xx\"",
        "totalServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-phi-ui\" metric.type=\"run.googleapis.com/request_count\""
      }
    }
  },
  "goal": 0.999,
  "rollingPeriod": "2592000s"
}
SLO6_EOF

gcloud monitoring slos create \
  --service=dominion-phi-ui \
  --config-from-file=/tmp/slo_phi_ui_p2_availability.json \
  --project=$PROJECT2 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# SLO 7: dominion-api (Project 2) - Availability
echo "  Creating SLO: dominion-api (P2) - Availability Target"
cat > /tmp/slo_api_p2_availability.json <<'SLO7_EOF'
{
  "displayName": "API Availability (99.9%)",
  "serviceLevelIndicator": {
    "requestBased": {
      "goodTotalRatio": {
        "goodServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-api\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class!=\"5xx\"",
        "totalServiceFilter": "resource.type=\"cloud_run_revision\" resource.label.service_name=\"dominion-api\" metric.type=\"run.googleapis.com/request_count\""
      }
    }
  },
  "goal": 0.999,
  "rollingPeriod": "2592000s"
}
SLO7_EOF

gcloud monitoring slos create \
  --service=dominion-api \
  --config-from-file=/tmp/slo_api_p2_availability.json \
  --project=$PROJECT2 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

# Clean up temp files
rm /tmp/slo_*.json

echo -e "${GREEN}✅ SLO creation complete${NC}"
echo ""

# Create SLO burn rate alerting policies
echo -e "${BLUE}[2/3] Creating SLO Burn Rate Alerts...${NC}"
echo ""

cat > /tmp/slo_burnrate_policy.json <<'BURNRATE_EOF'
{
  "displayName": "SLO Burn Rate Alert - Critical Services",
  "conditions": [{
    "displayName": "SLO error budget burn rate too high",
    "conditionThreshold": {
      "filter": "select_slo_burn_rate(\"projects/PROJECT_ID/services/*/serviceLevelObjectives/*\", 3600)",
      "comparison": "COMPARISON_GT",
      "thresholdValue": 10,
      "duration": "0s",
      "aggregations": [{
        "alignmentPeriod": "60s",
        "perSeriesAligner": "ALIGN_RATE"
      }]
    }
  }],
  "combiner": "OR",
  "enabled": true,
  "alertStrategy": {
    "autoClose": "604800s"
  }
}
BURNRATE_EOF

echo "  Creating burn rate alert for Project 1..."
sed "s/PROJECT_ID/$PROJECT1/g" /tmp/slo_burnrate_policy.json > /tmp/burnrate_p1.json
gcloud alpha monitoring policies create \
  --policy-from-file=/tmp/burnrate_p1.json \
  --project=$PROJECT1 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

echo "  Creating burn rate alert for Project 2..."
sed "s/PROJECT_ID/$PROJECT2/g" /tmp/slo_burnrate_policy.json > /tmp/burnrate_p2.json
gcloud alpha monitoring policies create \
  --policy-from-file=/tmp/burnrate_p2.json \
  --project=$PROJECT2 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

rm /tmp/slo_burnrate_policy.json /tmp/burnrate_*.json

echo -e "${GREEN}✅ Burn rate alerts configured${NC}"
echo ""

# Create SLO compliance dashboard
echo -e "${BLUE}[3/3] Creating SLO Compliance Dashboard...${NC}"
echo ""

cat > /tmp/slo_dashboard.json <<'SLODASH_EOF'
{
  "displayName": "Dominion OS - SLO Compliance & Error Budget",
  "mosaicLayout": {
    "columns": 12,
    "tiles": [
      {
        "width": 12,
        "height": 4,
        "widget": {
          "title": "SLO Compliance Overview",
          "text": {
            "content": "# Service Level Objectives\n\n**Target:** 99.9% availability across all critical services\n\n**Error Budget:** 43 minutes downtime per 30-day period\n\n**Services Monitored:**\n- dominion-ai-gateway\n- dominion-phi-ui\n- dominion-os-api\n- dominion-gateway\n- dominion-api\n\n**Review Schedule:** Weekly on Monday 10:00 UTC",
            "format": "MARKDOWN"
          }
        }
      },
      {
        "yPos": 4,
        "width": 6,
        "height": 4,
        "widget": {
          "title": "Error Budget Consumption Rate",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "select_slo_burn_rate(\"projects/*/services/*/serviceLevelObjectives/*\", 3600)",
                  "aggregation": {
                    "alignmentPeriod": "300s",
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
          "title": "5xx Error Rate (Impact on SLO)",
          "xyChart": {
            "dataSets": [{
              "timeSeriesQuery": {
                "timeSeriesFilter": {
                  "filter": "resource.type=\"cloud_run_revision\" metric.type=\"run.googleapis.com/request_count\" metric.label.response_code_class=\"5xx\"",
                  "aggregation": {
                    "alignmentPeriod": "300s",
                    "perSeriesAligner": "ALIGN_RATE",
                    "crossSeriesReducer": "REDUCE_SUM",
                    "groupByFields": ["resource.service_name"]
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
SLODASH_EOF

echo "  Creating SLO dashboard for Project 1..."
gcloud monitoring dashboards create \
  --config-from-file=/tmp/slo_dashboard.json \
  --project=$PROJECT1 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

echo "  Creating SLO dashboard for Project 2..."
gcloud monitoring dashboards create \
  --config-from-file=/tmp/slo_dashboard.json \
  --project=$PROJECT2 2>&1 | grep -q "Created" && echo "    ✓ Created" || echo "    (already exists or creation failed)"

rm /tmp/slo_dashboard.json

echo -e "${GREEN}✅ SLO dashboards created${NC}"
echo ""

echo "========================================"
echo "SLO DEPLOYMENT COMPLETE"
echo "========================================"
echo ""
echo "SLOs Defined:"
echo "  ✓ dominion-ai-gateway (P1) - 99.9% availability"
echo "  ✓ dominion-ai-gateway (P1) - 95% requests < 500ms"
echo "  ✓ dominion-phi-ui (P1) - 99.9% availability"
echo "  ✓ dominion-os-api (P1) - 99.9% availability"
echo "  ✓ dominion-gateway (P2) - 99.9% availability"
echo "  ✓ dominion-phi-ui (P2) - 99.9% availability"
echo "  ✓ dominion-api (P2) - 99.9% availability"
echo ""
echo "Performance Targets:"
echo "  • 99.9% availability = 43 minutes max downtime/30 days"
echo "  • 95% of requests complete in < 500ms"
echo "  • < 0.1% error rate (5xx responses)"
echo ""
echo "Alerting:"
echo "  • Burn rate alerts configured for both projects"
echo "  • Triggers when error budget consumption > 10x normal"
echo "  • Auto-closes alerts after 7 days"
echo ""
echo "Review Schedule:"
echo "  • Weekly SLO review: Monday 10:00 UTC"
echo "  • Monthly error budget analysis"
echo "  • Quarterly SLO target review"
echo ""
echo "Access SLO Dashboards:"
echo "  Project 1: https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT1"
echo "  Project 2: https://console.cloud.google.com/monitoring/dashboards?project=$PROJECT2"
echo ""
echo "========================================"
echo -e "${GREEN}✅ SLO definition complete!${NC}"
echo "========================================"
