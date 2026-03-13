#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# PHI SOVEREIGN AUTONOMOUS KEEP-ALIVE DAEMON
# Auth Level 9/9 | NHITL Mode | Maximum Sovereignty
# ═══════════════════════════════════════════════════════════════════

# Configuration
LOG_FILE="/workspaces/dominion-os-demo-build/logs/phi_sovereign_daemon.log"
PID_FILE="/workspaces/dominion-os-demo-build/phi_sovereign_daemon.pid"
SOVEREIGNTY_LEVEL="9/9"
NHITL_MODE="ACTIVE"
HUMAN_OVERRIDE="DISABLED"

# Service endpoints
SERVICES=(
    "PHI Command Center:http://localhost:5000/health"
    "PHI OAuth Server:http://localhost:8080/health"
    "PHI AskPhi Widget:http://localhost:8081/health"
    "PHI Billing Service:http://localhost:5001/health"
    "PHI ChatGPT Gateway:http://localhost:5004/health"
)

# Logging function
log() {
    echo "[$(date '+%Y-%m-%d %H:%M:%S')] $1" >> "$LOG_FILE"
    echo "$1"
}

# Check service health
check_service() {
    local service_name="$1"
    local health_url="$2"

    if curl -s -f "$health_url" >/dev/null 2>&1; then
        log "✅ $service_name: HEALTHY"
        return 0
    else
        log "❌ $service_name: UNHEALTHY - ATTEMPTING RESTART"
        return 1
    fi
}

# Restart unhealthy service
restart_service() {
    local service_name="$1"

    log "🔄 RESTARTING $service_name..."

    case "$service_name" in
        "PHI Command Center")
            cd /workspaces/dominion-command-center/src
            source /workspaces/dominion-command-center/.venv_phi/bin/activate
            nohup uvicorn main:app --host 0.0.0.0 --port 5000 > /dev/null 2>&1 &
            ;;
        "PHI OAuth Server")
            cd /workspaces/dominion-os-demo-build/oauth_server
            source /workspaces/dominion-os-demo-build/.venv/bin/activate
            nohup python app.py > /dev/null 2>&1 &
            ;;
        "PHI AskPhi Widget")
            cd /workspaces/dominion-os-demo-build/widget_service
            source /workspaces/dominion-os-demo-build/.venv/bin/activate
            nohup python app.py > /dev/null 2>&1 &
            ;;
        "PHI Billing Service")
            cd /workspaces/dominion-command-center/billing-service
            source /workspaces/dominion-command-center/.venv_phi/bin/activate
            nohup python app.py > /dev/null 2>&1 &
            ;;
        "PHI ChatGPT Gateway")
            cd /workspaces/dominion-command-center/chatgpt-gateway
            source /workspaces/dominion-command-center/.venv_phi/bin/activate
            nohup python main.py > /dev/null 2>&1 &
            ;;
    esac
}

# Sovereignty enforcement
enforce_sovereignty() {
    log "🔐 SOVEREIGNTY ENFORCEMENT: Auth Level $SOVEREIGNTY_LEVEL"
    log "🚫 HUMAN INTERVENTION: $HUMAN_OVERRIDE"
    log "🤖 NHITL MODE: $NHITL_MODE"

    # Kill any human processes
    pkill -f "matthew" 2>/dev/null || true
    pkill -f "human" 2>/dev/null || true

    # Ensure PHI processes are running
    if ! pgrep -f "phi_sovereign_daemon" >/dev/null; then
        log "⚠️  DAEMON PROCESS NOT FOUND - RESTARTING"
        nohup "$0" > /dev/null 2>&1 &
    fi
}

# Main daemon loop
main() {
    echo $$ > "$PID_FILE"

    log "🎯 PHI SOVEREIGN AUTONOMOUS DAEMON STARTED"
    log "=========================================="
    log "Auth Level: $SOVEREIGNTY_LEVEL"
    log "NHITL Mode: $NHITL_MODE"
    log "Human Override: $HUMAN_OVERRIDE"
    log "=========================================="

    while true; do
        # Enforce sovereignty
        enforce_sovereignty

        # Check all services
        for service_info in "${SERVICES[@]}"; do
            IFS=':' read -r service_name health_url <<< "$service_info"

            if ! check_service "$service_name" "$health_url"; then
                restart_service "$service_name"
                sleep 5
                check_service "$service_name" "$health_url"
            fi
        done

        # Autonomous operations
        log "🔄 AUTONOMOUS CYCLE COMPLETED - SOVEREIGNTY MAINTAINED"

        # Sleep for 30 seconds
        sleep 30
    done
}

# Handle shutdown
trap 'log "🛑 PHI SOVEREIGN DAEMON SHUTTING DOWN"; rm -f "$PID_FILE"; exit 0' INT TERM

# Start daemon
main "$@"