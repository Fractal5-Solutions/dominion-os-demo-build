#!/bin/bash
###############################################################################
# PHI Perfect Autonomous Shutdown
# Gracefully shuts down all autonomous systems and sovereign processes
# For clean shutdown of 24/7 continuous operation
###############################################################################

set -e

# Colors
RED='\033[0;31m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
GOLD='\033[38;5;220m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TELEMETRY_DIR="$SCRIPT_DIR/telemetry"

SHUTDOWN_LOG="$LOG_DIR/autonomous_shutdown_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$SHUTDOWN_LOG"
}

sovereign_announce() {
    echo ""
    echo -e "${GOLD}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GOLD}${BOLD}║  $1${NC}"
    echo -e "${GOLD}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    log "SOVEREIGN: $1"
}

sovereign_announce "PHI AUTONOMOUS SHUTDOWN - GRACEFUL POWER DOWN"

log "Initiating graceful autonomous shutdown..."

# Signal shutdown to sovereign processes
touch /tmp/.stop-nhitl-loop
log "NHITL loop stop signal sent"

# Update status to shutting down
cat > "$TELEMETRY_DIR/autonomous_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "AUTONOMOUS_NHITL",
  "sovereignty_level": "9/9",
  "status": "SHUTTING_DOWN",
  "shutdown_log": "$SHUTDOWN_LOG"
}
EOF

echo ""
echo -e "${CYAN}━━━ PHASE 1: Stop Sovereign Processes ━━━${NC}"

# Stop sovereign keepalive
if [ -f "$LOG_DIR/sovereign_keepalive.pid" ]; then
    PID=$(cat "$LOG_DIR/sovereign_keepalive.pid")
    if ps -p "$PID" > /dev/null 2>&1; then
        log "Stopping Sovereign Keepalive (PID: $PID)..."
        kill "$PID" 2>/dev/null || true
        echo -e "${YELLOW}⏹  Sovereign Keepalive stopped${NC}"
    fi
    rm -f "$LOG_DIR/sovereign_keepalive.pid"
fi

# Stop other sovereign processes
pkill -f "phi_sovereign_autopilot_nhitl" 2>/dev/null || true
pkill -f "phi_background_completion_monitor" 2>/dev/null || true
pkill -f "autonomous_overnight" 2>/dev/null || true

sleep 2

echo ""
echo -e "${CYAN}━━━ PHASE 2: Stop Background Services ━━━${NC}"

# Stop Channel Connect
if [ -f "$SCRIPT_DIR/phi_channel_connect.sh" ]; then
    log "Stopping Channel Connect..."
    bash "$SCRIPT_DIR/phi_channel_connect.sh" stop 2>/dev/null || true
    echo -e "${YELLOW}⏹  Channel Connect stopped${NC}"
fi

# Stop Google Workspace Integration
pkill -f "phi_google_workspace" 2>/dev/null || true
echo -e "${YELLOW}⏹  Google Workspace Integration stopped${NC}"

# Stop cost optimization
pkill -f "phi_cost_minimization" 2>/dev/null || true

sleep 2

echo ""
echo -e "${CYAN}━━━ PHASE 3: Stop Core Services ━━━${NC}"

# Function to stop service by PID file
stop_service_by_pid() {
    local service_name="$1"
    local pid_file="$2"

    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        if ps -p "$PID" > /dev/null 2>&1; then
            log "Stopping $service_name (PID: $PID)..."
            kill "$PID" 2>/dev/null || true

            # Wait up to 10 seconds for graceful shutdown
            for i in {1..10}; do
                if ! ps -p "$PID" > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done

            # Force kill if still running
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID" 2>/dev/null || true
            fi

            echo -e "${YELLOW}⏹  $service_name stopped${NC}"
        fi
        rm -f "$pid_file"
    fi
}

# Stop services
stop_service_by_pid "Command Center" "$LOG_DIR/command_center.pid"
stop_service_by_pid "Billing Service" "$LOG_DIR/billing_service.pid"
stop_service_by_pid "OAuth Server" "$LOG_DIR/oauth_server.pid"
stop_service_by_pid "Widget Service" "$LOG_DIR/widget_service.pid"

# Fallback: kill any remaining Python app processes
pkill -f "python3 app.py" 2>/dev/null || true

sleep 2

echo ""
echo -e "${CYAN}━━━ PHASE 4: Cleanup ━━━${NC}"

# Remove autonomous mode flag
rm -f /tmp/phi_autonomous_mode.flag
log "Autonomous mode flag removed"

# Archive logs
ARCHIVE_DIR="$TELEMETRY_DIR/shutdown_$(date +%Y%m%d_%H%M%S)"
mkdir -p "$ARCHIVE_DIR"

# Copy final state
cp "$TELEMETRY_DIR/autonomous_status.json" "$ARCHIVE_DIR/" 2>/dev/null || true
cp "$TELEMETRY_DIR/sovereign_status.json" "$ARCHIVE_DIR/" 2>/dev/null || true
cp "$LOG_DIR"/*.log "$ARCHIVE_DIR/" 2>/dev/null || true

log "Logs archived to $ARCHIVE_DIR"

# Update final status
cat > "$TELEMETRY_DIR/autonomous_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "SHUTDOWN",
  "sovereignty_level": "0/9",
  "status": "STOPPED",
  "shutdown_log": "$SHUTDOWN_LOG",
  "archive": "$ARCHIVE_DIR"
}
EOF

echo ""
sovereign_announce "AUTONOMOUS SHUTDOWN COMPLETE"
echo ""
echo -e "${BLUE}All services stopped gracefully.${NC}"
echo -e "${BLUE}Logs archived: $ARCHIVE_DIR${NC}"
echo -e "${BLUE}To restart: bash $SCRIPT_DIR/phi_perfect_autonomous_startup.sh${NC}"
echo ""

log "Autonomous shutdown complete"

exit 0
