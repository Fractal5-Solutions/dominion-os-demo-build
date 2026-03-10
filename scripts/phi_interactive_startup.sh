#!/bin/bash
###############################################################################
# PHI Interactive Startup (VS Code Mode)
# Starts services for interactive development when VS Code is active
# Optimized for development workflow with hot-reload and debugging
###############################################################################

set -e

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

# Directories
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="$SCRIPT_DIR/logs"
TELEMETRY_DIR="$SCRIPT_DIR/telemetry"
mkdir -p "$LOG_DIR" "$TELEMETRY_DIR"

STARTUP_LOG="$LOG_DIR/interactive_startup_$(date +%Y%m%d_%H%M%S).log"

# Remove autonomous flag (this is interactive mode)
rm -f /tmp/phi_autonomous_mode.flag

log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" | tee -a "$STARTUP_LOG"
}

echo ""
echo -e "${MAGENTA}${BOLD}╔═══════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${MAGENTA}${BOLD}║      PHI INTERACTIVE STARTUP - VS Code Development Mode          ║${NC}"
echo -e "${MAGENTA}${BOLD}╚═══════════════════════════════════════════════════════════════════╝${NC}"
echo ""

log "Starting interactive development mode..."

# Update status
cat > "$TELEMETRY_DIR/interactive_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "INTERACTIVE_VSCODE",
  "sovereignty_level": "9/9",
  "status": "STARTING",
  "user_active": true,
  "startup_log": "$STARTUP_LOG"
}
EOF

echo -e "${CYAN}━━━ PHASE 1: Environment Setup ━━━${NC}"

# Activate virtual environment
if [ -f "$SCRIPT_DIR/.venv/bin/activate" ]; then
    source "$SCRIPT_DIR/.venv/bin/activate"
    echo -e "${GREEN}✓ Virtual environment activated${NC}"
    log "Virtual environment activated"
else
    echo -e "${YELLOW}⚠  No virtual environment found${NC}"
    log "WARNING: No virtual environment"
fi

# Check dominion-command-center
if [ -d "/workspaces/dominion-command-center" ]; then
    echo -e "${GREEN}✓ Dominion Command Center available${NC}"
else
    echo -e "${YELLOW}⚠  Dominion Command Center not found${NC}"
fi

echo ""
echo -e "${CYAN}━━━ PHASE 2: Start Development Services ━━━${NC}"

# Function to start service with console output for debugging
start_dev_service() {
    local name="$1"
    local path="$2"
    local port="$3"
    local working_dir="$(dirname "$path")"

    if [ ! -f "$path" ]; then
        echo -e "${YELLOW}⚠  $name not found - skipping${NC}"
        return 1
    fi

    # Check if already running
    if lsof -ti:$port > /dev/null 2>&1; then
        echo -e "${GREEN}✓ $name already running on port $port${NC}"
        return 0
    fi

    echo "  Starting $name on port $port..."
    cd "$working_dir"

    # Start with Flask debug mode for development
    export FLASK_ENV=development
    export FLASK_DEBUG=1
    export PORT=$port

    nohup python3 app.py > "$LOG_DIR/${name// /_}.log" 2>&1 &
    local pid=$!
    echo $pid > "$LOG_DIR/${name// /_}.pid"

    sleep 2

    if ps -p $pid > /dev/null 2>&1; then
        if lsof -ti:$port > /dev/null 2>&1; then
            echo -e "${GREEN}✓ $name started (PID: $pid, Port: $port)${NC}"
            log "$name started successfully"
            return 0
        else
            echo -e "${YELLOW}⚠  $name process running but port not ready${NC}"
            log "WARNING: $name port not ready"
        fi
    else
        echo -e "${RED}✗ $name failed to start${NC}"
        log "ERROR: $name failed to start"
        return 1
    fi
}

# Start core services
start_dev_service "Command Center" "/workspaces/dominion-command-center/demo/app.py" "5000"
start_dev_service "Billing Service" "/workspaces/dominion-command-center/billing-service/app.py" "5001"
start_dev_service "OAuth Server" "/workspaces/dominion-os-demo-build/oauth_server/app.py" "8080"
start_dev_service "Widget Service" "/workspaces/dominion-os-demo-build/widget_service/app.py" "8081"

cd "$SCRIPT_DIR"

echo ""
echo -e "${CYAN}━━━ PHASE 3: Optional Background Services ━━━${NC}"
echo -e "${BLUE}ℹ  Background services available but not auto-started in dev mode${NC}"
echo -e "${BLUE}   Start manually if needed:${NC}"
echo -e "${BLUE}   - bash phi_channel_connect.sh start${NC}"
echo -e "${BLUE}   - bash phi_google_workspace.sh start${NC}"

echo ""
echo -e "${CYAN}━━━ PHASE 4: Development Ready ━━━${NC}"

# Count active services
ACTIVE_COUNT=0
for port in 5000 5001 8080 8081; do
    if lsof -ti:$port > /dev/null 2>&1; then
        ((ACTIVE_COUNT++))
    fi
done

# Update status
cat > "$TELEMETRY_DIR/interactive_status.json" <<EOF
{
  "timestamp": "$(date -Iseconds)",
  "mode": "INTERACTIVE_VSCODE",
  "sovereignty_level": "9/9",
  "status": "OPERATIONAL",
  "user_active": true,
  "active_services": $ACTIVE_COUNT,
  "startup_log": "$STARTUP_LOG"
}
EOF

echo ""
echo -e "${MAGENTA}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${GREEN}✅ Development Environment Ready!${NC}"
echo ""
echo -e "${BOLD}Active Services: $ACTIVE_COUNT${NC}"
echo ""
echo "🌐 Service URLs:"
echo "  • Command Center (BIMS): http://localhost:5000"
echo "  • Billing Service:        http://localhost:5001"
echo "  • OAuth Server:           http://localhost:8080"
echo "  • Widget Service:         http://localhost:8081"
echo ""
echo "📊 Quick Commands:"
echo "  • Status check:    bash phi_status.sh"
echo "  • Stop services:   bash phi_interactive_shutdown.sh"
echo "  • View logs:       tail -f logs/*.log"
echo ""
echo -e "${BLUE}💡 Tip: Services run in debug mode for hot-reload development${NC}"
echo -e "${MAGENTA}${BOLD}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

log "Interactive startup complete - $ACTIVE_COUNT services operational"

exit 0
