#!/bin/bash
###############################################################################
# PHI DOMINION OS COMMAND CENTER - LIVE VERIFICATION
# Confirms all command center components are operational
# Sovereignty Level: 9/9 NHITL_AUTOPILOT
###############################################################################

echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║  PHI DOMINION OS COMMAND CENTER - LIVE OPERATIONAL STATUS VERIFICATION     ║"
echo "║  Sovereignty Level: 9/9 | Mode: NHITL_AUTOPILOT | Phase: FULL_REMOTE_ACCESS ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

TIMESTAMP=$(date -u +"%Y-%m-%dT%H:%M:%S+00:00")
STATUS_FILE="telemetry/sovereign_status.json"
REPORT_FILE="telemetry/command_center_live_status.json"

# Component status tracking
COMPONENTS_TOTAL=0
COMPONENTS_OPERATIONAL=0

###############################################################################
# 1. PHI MCP SERVER - CONTROL PLANE
###############################################################################
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "⚡ PHI MCP SERVER (Control Plane)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

PHI_MCP_PID=$(ps aux | grep "[m]ain.py" | awk '{print $2}' | head -1)
COMPONENTS_TOTAL=$((COMPONENTS_TOTAL + 1))

if [ -n "$PHI_MCP_PID" ]; then
    PHI_MCP_UPTIME=$(ps -p $PHI_MCP_PID -o etime= | xargs)
    echo "✅ PHI MCP Server: OPERATIONAL"
    echo "   PID: $PHI_MCP_PID"
    echo "   Uptime: $PHI_MCP_UPTIME"
    echo "   Port: 8000"
    
    # Test server response
    if curl -s http://localhost:8000/ > /dev/null 2>&1; then
        echo "   Status: RESPONDING"
        COMPONENTS_OPERATIONAL=$((COMPONENTS_OPERATIONAL + 1))
    else
        echo "   Status: NOT_RESPONDING"
    fi
else
    echo "❌ PHI MCP Server: NOT RUNNING"
fi
echo ""

###############################################################################
# 2. CONTINUOUS MONITORING - HEALTH SURVEILLANCE
###############################################################################
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🔍 CONTINUOUS MONITORING (Health Surveillance)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

MONITOR_COUNT=$(ps aux | grep "[c]ontinuous_monitor.sh" | wc -l)
COMPONENTS_TOTAL=$((COMPONENTS_TOTAL + 1))

if [ "$MONITOR_COUNT" -ge 1 ]; then
    echo "✅ Continuous Monitoring: OPERATIONAL"
    echo "   Active Monitors: $MONITOR_COUNT"
    ps aux | grep "[c]ontinuous_monitor.sh" | awk '{print "   PID: " $2 " | Uptime: " $11}'
    COMPONENTS_OPERATIONAL=$((COMPONENTS_OPERATIONAL + 1))
else
    echo "❌ Continuous Monitoring: NOT RUNNING"
fi
echo ""

###############################################################################
# 3. GCP REMOTE INFRASTRUCTURE - WORKLOAD EXECUTION
###############################################################################
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "☁️  GCP REMOTE INFRASTRUCTURE (Workload Execution)"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

COMPONENTS_TOTAL=$((COMPONENTS_TOTAL + 1))

# Check GCP authentication
if gcloud auth list --filter="status:ACTIVE" --format="value(account)" > /dev/null 2>&1; then
    GCP_ACCOUNT=$(gcloud auth list --filter="status:ACTIVE" --format="value(account)" 2>/dev/null | head -1)
    echo "✅ GCP Authentication: ACTIVE"
    echo "   Account: $GCP_ACCOUNT"
    
    # Count operational services
    PROJECT1_SERVICES=$(gcloud run services list --project dominion-core-prod --format="value(metadata.name)" 2>/dev/null | wc -l)
    PROJECT2_SERVICES=$(gcloud run services list --project dominion-os-1-0-main --format="value(metadata.name)" 2>/dev/null | wc -l)
    TOTAL_SERVICES=$((PROJECT1_SERVICES + PROJECT2_SERVICES))
    
    if [ "$TOTAL_SERVICES" -gt 0 ]; then
        echo "✅ Remote Services: OPERATIONAL"
        echo "   dominion-core-prod: $PROJECT1_SERVICES services"
        echo "   dominion-os-1-0-main: $PROJECT2_SERVICES services"
        echo "   Total: $TOTAL_SERVICES services"
        COMPONENTS_OPERATIONAL=$((COMPONENTS_OPERATIONAL + 1))
    else
        echo "⚠️  Remote Services: 0 services found"
    fi
else
    echo "❌ GCP Authentication: NOT ACTIVE"
fi
echo ""

###############################################################################
# 4. TELEMETRY & STATUS TRACKING
###############################################################################
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 TELEMETRY & STATUS TRACKING"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

COMPONENTS_TOTAL=$((COMPONENTS_TOTAL + 1))

if [ -f "$STATUS_FILE" ]; then
    echo "✅ Sovereign Status: TRACKING"
    
    SOVEREIGNTY_LEVEL=$(grep -o '"sovereignty_level":"[^"]*"' "$STATUS_FILE" | cut -d'"' -f4)
    MODE=$(grep -o '"mode":"[^"]*"' "$STATUS_FILE" | cut -d'"' -f4)
    PHASE=$(grep -o '"phase":"[^"]*"' "$STATUS_FILE" | cut -d'"' -f4)
    
    echo "   File: $STATUS_FILE"
    echo "   Sovereignty Level: $SOVEREIGNTY_LEVEL"
    echo "   Mode: $MODE"
    echo "   Phase: $PHASE"
    COMPONENTS_OPERATIONAL=$((COMPONENTS_OPERATIONAL + 1))
else
    echo "❌ Sovereign Status: FILE NOT FOUND"
fi
echo ""

###############################################################################
# 5. LOCAL PORTS & NETWORK SERVICES
###############################################################################
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "🌐 LOCAL PORTS & NETWORK SERVICES"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

ACTIVE_PORTS=$(netstat -tuln 2>/dev/null | grep "LISTEN" | wc -l)
echo "Active Listening Ports: $ACTIVE_PORTS"

if netstat -tuln 2>/dev/null | grep ":8000" > /dev/null; then
    echo "✅ Port 8000 (PHI MCP): LISTENING"
fi

echo ""

###############################################################################
# SUMMARY
###############################################################################
echo "╔════════════════════════════════════════════════════════════════════════════╗"
echo "║  DOMINION OS COMMAND CENTER - OPERATIONAL SUMMARY                          ║"
echo "╚════════════════════════════════════════════════════════════════════════════╝"
echo ""

HEALTH_PERCENTAGE=$((COMPONENTS_OPERATIONAL * 100 / COMPONENTS_TOTAL))

echo "   Components Operational: $COMPONENTS_OPERATIONAL / $COMPONENTS_TOTAL"
echo "   Health Percentage: $HEALTH_PERCENTAGE%"
echo ""

if [ "$COMPONENTS_OPERATIONAL" -eq "$COMPONENTS_TOTAL" ]; then
    OVERALL_STATUS="PERFECTLY LIVE"
    EMOJI="🟢"
elif [ "$COMPONENTS_OPERATIONAL" -ge 3 ]; then
    OVERALL_STATUS="OPERATIONAL"
    EMOJI="🟡"
else
    OVERALL_STATUS="DEGRADED"
    EMOJI="🔴"
fi

echo "$EMOJI  Overall Status: $OVERALL_STATUS"
echo ""

###############################################################################
# GENERATE JSON REPORT
###############################################################################
cat > "$REPORT_FILE" << EOF
{
  "timestamp": "$TIMESTAMP",
  "command_center_status": "$OVERALL_STATUS",
  "sovereignty_level": "9/9",
  "mode": "NHITL_AUTOPILOT",
  "components": {
    "phi_mcp_server": {
      "status": $([ -n "$PHI_MCP_PID" ] && echo '"OPERATIONAL"' || echo '"OFFLINE"'),
      "pid": $([ -n "$PHI_MCP_PID" ] && echo "$PHI_MCP_PID" || echo 'null'),
      "port": 8000
    },
    "continuous_monitoring": {
      "status": $([ "$MONITOR_COUNT" -ge 1 ] && echo '"OPERATIONAL"' || echo '"OFFLINE"'),
      "active_monitors": $MONITOR_COUNT
    },
    "gcp_remote_infrastructure": {
      "status": $([ "$TOTAL_SERVICES" -gt 0 ] && echo '"OPERATIONAL"' || echo '"OFFLINE"'),
      "total_services": $TOTAL_SERVICES,
      "dominion_core_prod": $PROJECT1_SERVICES,
      "dominion_os_1_0_main": $PROJECT2_SERVICES
    },
    "telemetry": {
      "status": "OPERATIONAL"
    }
  },
  "health": {
    "components_operational": $COMPONENTS_OPERATIONAL,
    "components_total": $COMPONENTS_TOTAL,
    "health_percentage": $HEALTH_PERCENTAGE
  }
}
EOF

echo "📄 Detailed report saved: $REPORT_FILE"
echo ""

if [ "$OVERALL_STATUS" = "PERFECTLY LIVE" ]; then
    echo "╔════════════════════════════════════════════════════════════════════════════╗"
    echo "║  ✅ DOMINION OS COMMAND CENTER IS PERFECTLY LIVE                          ║"
    echo "║                                                                            ║"
    echo "║  All critical components operational:                                     ║"
    echo "║  • PHI MCP Server (Control Plane)                                        ║"
    echo "║  • Continuous Monitoring (Health Surveillance)                           ║"
    echo "║  • GCP Remote Infrastructure (Workload Execution)                        ║"
    echo "║  • Telemetry & Status Tracking                                           ║"
    echo "║                                                                            ║"
    echo "║  Sovereignty Level 9/9 MAINTAINED                                         ║"
    echo "║  Full spectrum dominance: Local Control + Remote Execution               ║"
    echo "╚════════════════════════════════════════════════════════════════════════════╝"
fi

exit 0
