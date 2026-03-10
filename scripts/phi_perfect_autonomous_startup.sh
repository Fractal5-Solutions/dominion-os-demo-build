#!/bin/bash
###############################################################################
# PHI Perfect Autonomous Startup
# Starts all systems in full 9/9 sovereign autopilot NHITL mode
# For 24/7 continuous operation without VS Code
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
GOLD='\033[38;5;220m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TELEMETRY_DIR="$SCRIPT_DIR/telemetry"
mkdir -p "$LOG_DIR" "$TELEMETRY_DIR"

STARTUP_LOG="$LOG_DIR/autonomous_startup_$(date +%Y%m%d_%H%M%S).log"

# Mark autonomous mode
touch /tmp/phi_autonomous_mode.flag
rm -f /tmp/.stop-nhitl-loop 2>/dev/null || true

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$STARTUP_LOG"
}

sovereign_announce() {
    echo ""
    echo -e "${GOLD}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GOLD}${BOLD}║  $1${NC}"
    echo -e "${GOLD}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log "SOVEREIGN: $1"
}

sovereign_announce "PHI AUTONOMOUS STARTUP - 9/9 SOVEREIGN POWER NHITL"

log "Starting autonomous mode with full sovereign authority..."

# Update status
cat > "$TELEMETRY_DIR/autonomous_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "AUTONOMOUS_NHITL",
  "sovereignty_level": "9/9",
  "status": "STARTING",
  "startup_log": "$STARTUP_LOG"
}
EOF

echo -e "${CYAN}━━━ PHASE 1: Activate Virtual Environment ━━━${NC}"
if [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
    log "Virtual environment activated"
else
    log "WARNING: No virtual environment found"
fi

echo ""
echo -e "${CYAN}━━━ PHASE 2: Start Core Services ━━━${NC}"

# Start Command Center Demo
if [ -f "/workspaces/dominion-command-center/demo/app.py" ]; then
    log "Starting Command Center Demo..."
    cd /workspaces/dominion-command-center/demo
    nohup python3 app.py > "$LOG_DIR/command_center.log" 2>&1 &
    echo $! > "$LOG_DIR/command_center.pid"
    echo -e "${GREEN}✓ Command Center started (PID: $!)${NC}"
fi

# Start Billing Service
if [ -f "/workspaces/dominion-command-center/billing-service/app.py" ]; then
    log "Starting Billing Service..."
    cd /workspaces/dominion-command-center/billing-service
    nohup python3 app.py > "$LOG_DIR/billing_service.log" 2>&1 &
    echo $! > "$LOG_DIR/billing_service.pid"
    echo -e "${GREEN}✓ Billing Service started (PID: $!)${NC}"
fi

# Start OAuth Server
if [ -f "/workspaces/dominion-os-demo-build/oauth_server/app.py" ]; then
    log "Starting OAuth Server..."
    cd /workspaces/dominion-os-demo-build/oauth_server
    nohup python3 app.py > "$LOG_DIR/oauth_server.log" 2>&1 &
    echo $! > "$LOG_DIR/oauth_server.pid"
    echo -e "${GREEN}✓ OAuth Server started (PID: $!)${NC}"
fi

# Start Widget Service
if [ -f "/workspaces/dominion-os-demo-build/widget_service/app.py" ]; then
    log "Starting Widget Service..."
    cd /workspaces/dominion-os-demo-build/widget_service
    nohup python3 app.py > "$LOG_DIR/widget_service.log" 2>&1 &
    echo $! > "$LOG_DIR/widget_service.pid"
    echo -e "${GREEN}✓ Widget Service started (PID: $!)${NC}"
fi

cd "$SCRIPT_DIR"

sleep 3

echo ""
echo -e "${CYAN}━━━ PHASE 3: Start Sovereign Autopilot ━━━${NC}"

# Start Sovereign Keepalive (NHITL master controller)
if [ -f "$SCRIPT_DIR/phi_sovereign_keepalive.sh" ]; then
    log "Starting Sovereign Keepalive..."
    nohup bash "$SCRIPT_DIR/phi_sovereign_keepalive.sh" > "$LOG_DIR/sovereign_keepalive.log" 2>&1 &
    echo $! > "$LOG_DIR/sovereign_keepalive.pid"
    echo -e "${GREEN}✓ Sovereign Keepalive started (PID: $!)${NC}"
fi

sleep 2

echo ""
echo -e "${CYAN}━━━ PHASE 4: Start Background Services ━━━${NC}"

# Start Channel Connect
if [ -f "$SCRIPT_DIR/phi_channel_connect.sh" ]; then
    log "Starting Channel Connect..."
    nohup bash "$SCRIPT_DIR/phi_channel_connect.sh" start > "$LOG_DIR/channel_connect.log" 2>&1 &
    echo -e "${GREEN}✓ Channel Connect started${NC}"
fi

# Start Google Workspace Integration
if [ -f "$SCRIPT_DIR/phi_google_workspace.sh" ]; then
    log "Starting Google Workspace Integration..."
    nohup bash "$SCRIPT_DIR/phi_google_workspace.sh" start > "$LOG_DIR/google_workspace.log" 2>&1 &
    echo -e "${GREEN}✓ Google Workspace Integration started${NC}"
fi

sleep 2

echo ""
echo -e "${CYAN}━━━ PHASE 5: Verification ━━━${NC}"

# Count active services
ACTIVE_COUNT=0
for port in 5000 5001 8080 8081; do
    if lsof -ti:$port > /dev/null 2>&1; then
        ((ACTIVE_COUNT++))
        echo -e "${GREEN}✓ Port $port active${NC}"
    fi
done

# Update final status
cat > "$TELEMETRY_DIR/autonomous_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "AUTONOMOUS_NHITL",
  "sovereignty_level": "9/9",
  "status": "OPERATIONAL",
  "active_services": $ACTIVE_COUNT,
  "startup_log": "$STARTUP_LOG",
  "pid_files": [
    "$(ls -1 $LOG_DIR/*.pid 2>/dev/null | tr '\n' ',' || echo '')"
  ]
}
EOF

echo ""
sovereign_announce "AUTONOMOUS MODE OPERATIONAL - 9/9 SOVEREIGN POWER"
echo ""
echo -e "${MAGENTA}Active Services: ${BOLD}$ACTIVE_COUNT${NC}"
echo -e "${MAGENTA}Mode: ${BOLD}NHITL Autopilot${NC}"
echo -e "${MAGENTA}Authority: ${BOLD}9/9 Maximum Sovereign Power${NC}"
echo ""
echo -e "${BLUE}System running in continuous autonomous mode.${NC}"
echo -e "${BLUE}To stop: bash $SCRIPT_DIR/phi_perfect_autonomous_shutdown.sh${NC}"
echo ""

log "Autonomous startup complete - $ACTIVE_COUNT services operational"

exit 0
