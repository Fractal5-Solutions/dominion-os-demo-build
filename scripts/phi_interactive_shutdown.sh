#!/bin/bash
###############################################################################
# PHI Interactive Shutdown (VS Code Mode)
# Gracefully stops services when user wants to end development session
# Preserves workspace state for quick restart
###############################################################################

set -e

# Colors
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TELEMETRY_DIR="$SCRIPT_DIR/telemetry"

SHUTDOWN_LOG="$LOG_DIR/interactive_shutdown_$(date +%Y%m%d_%H%M%S).log"

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$SHUTDOWN_LOG"
}

echo ""
echo -e "${MAGENTA}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}${BOLD}║      PHI INTERACTIVE SHUTDOWN - Graceful Stop                     ║${NC}"
echo -e "${MAGENTA}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Initiating interactive shutdown..."

# Update status
cat > "$TELEMETRY_DIR/interactive_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "INTERACTIVE_VSCODE",
  "status": "SHUTTING_DOWN",
  "shutdown_log": "$SHUTDOWN_LOG"
}
EOF

echo -e "${CYAN}━━━ Stopping Development Services ━━━${NC}"

# Function to stop service gracefully
stop_service() {
    local service_name="$1"
    local pid_file="$2"

    if [ -f "$pid_file" ]; then
        PID=$(cat "$pid_file")
        if ps -p "$PID" > /dev/null 2>&1; then
            echo "  Stopping $service_name (PID: $PID)..."
            kill "$PID" 2>/dev/null || true

            # Wait for graceful shutdown
            for i in {1..5}; do
                if ! ps -p "$PID" > /dev/null 2>&1; then
                    break
                fi
                sleep 1
            done

            # Force if needed
            if ps -p "$PID" > /dev/null 2>&1; then
                kill -9 "$PID" 2>/dev/null || true
            fi

            echo -e "${YELLOW}⏹  $service_name stopped${NC}"
            log "$service_name stopped"
        fi
        rm -f "$pid_file"
    fi
}

# Stop services
stop_service "Command Center" "$LOG_DIR/Command_Center.pid"
stop_service "Billing Service" "$LOG_DIR/Billing_Service.pid"
stop_service "OAuth Server" "$LOG_DIR/OAuth_Server.pid"
stop_service "Widget Service" "$LOG_DIR/Widget_Service.pid"

# Cleanup any remaining Python processes
pkill -f "python3 app.py" 2>/dev/null || true

echo ""
echo -e "${CYAN}━━━ Cleanup ━━━${NC}"

# Save final workspace state
cat > "$TELEMETRY_DIR/workspace_state.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "last_shutdown": "$(date -Iseconds)",
  "shutdown_type": "interactive",
  "can_quick_restart": true
}
EOF

log "Workspace state saved"

# Update final status
cat > "$TELEMETRY_DIR/interactive_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "STOPPED",
  "status": "READY_FOR_RESTART",
  "shutdown_log": "$SHUTDOWN_LOG"
}
EOF

echo ""
echo -e "${MAGENTA}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Shutdown Complete${NC}"
echo ""
echo -e "${BLUE}💡 Workspace state preserved for quick restart${NC}"
echo -e "${BLUE}   To restart: bash phi_interactive_startup.sh${NC}"
echo -e "${MAGENTA}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

log "Interactive shutdown complete"

exit 0
