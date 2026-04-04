#!/bin/bash
# PHI SOVEREIGN CONTINUOUS MONITORING SYSTEM
# Automated live ops monitoring and maintenance
# Generated: March 9, 2026

set -e

# Configuration
MONITOR_INTERVAL=60  # Check every minute
ALERT_INTERVAL=300   # Alert check every 5 minutes
LOG_FILE="telemetry/sovereign_monitor_$(date +%Y%m%d).log"
PID_FILE="telemetry/sovereign_monitor.pid"
OPTIONAL_BACKGROUND_SERVICES=(
    "phi_cost_minimization_simple"
    "autonomous_overnight"
)

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [MONITOR] $1" >> "$LOG_FILE"
    echo -e "${BLUE}[MONITOR]${NC} $1"
}

error_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$LOG_FILE"
    echo -e "${RED}[ERROR]${NC} $1"
}

success_log() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$LOG_FILE"
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

is_optional_background_service() {
    local service="$1"
    local optional
    for optional in "${OPTIONAL_BACKGROUND_SERVICES[@]}"; do
        if [ "$service" = "$optional" ]; then
            return 0
        fi
    done
    return 1
}

run_monitoring_cycle() {
    log "Starting monitoring cycle"

    # Run health monitoring
    if bash scripts/live_ops_monitor.sh >> "$LOG_FILE" 2>&1; then
        success_log "Health monitoring completed successfully"
    else
        error_log "Health monitoring failed"
    fi

    # Run alerts check (every 5 minutes)
    local current_time=$(date +%s)
    local last_alert_check=$(cat telemetry/.last_alert_check 2>/dev/null || echo "0")

    if [ $((current_time - last_alert_check)) -ge $ALERT_INTERVAL ]; then
        log "Running alert system check"
        if bash scripts/live_ops_alerts.sh >> "$LOG_FILE" 2>&1; then
            success_log "Alert system check completed"
        else
            error_log "Alert system check failed"
        fi
        echo "$current_time" > telemetry/.last_alert_check
    fi

    # Check for critical issues requiring immediate action
    check_critical_issues

    log "Monitoring cycle completed"
}

check_critical_issues() {
    # Check if any services are completely down
    local critical_services_down=false

    for port in 8080 8081 5000; do  # Core services
        if ! lsof -i :$port | grep -q LISTEN; then
            error_log "CRITICAL: Core service on port $port is down"
            critical_services_down=true
        fi
    done

    # Check background services
    local bg_services=("phi_background_completion_monitor" "phi_cost_minimization_simple" "autonomous_overnight")
    for service in "${bg_services[@]}"; do
        if ! pgrep -f "$service" > /dev/null 2>&1; then
            if is_optional_background_service "$service"; then
                log "Background service '$service' is optional/idle"
                continue
            fi
            error_log "CRITICAL: Background service '$service' is not running"
            critical_services_down=true
        fi
    done

    # If critical services are down, attempt emergency restart
    if [ "$critical_services_down" = true ]; then
        error_log "CRITICAL ISSUES DETECTED - Initiating emergency restart"
        emergency_restart
    fi
}

emergency_restart() {
    log "Starting emergency restart procedure"

    # Kill any existing processes that might be hanging
    pkill -f "phi_start_all_systems" || true
    pkill -f "phi_background_completion_monitor" || true
    sleep 2

    # Restart all systems
    log "Restarting all services"
    bash scripts/phi_start_all_systems.sh &
    sleep 5

    # Restart background services
    log "Restarting background services"
    bash scripts/phi_background_completion_monitor.sh &

    success_log "Emergency restart completed"
}

maintenance_tasks() {
    # Run maintenance tasks hourly
    local current_hour=$(date +%H)
    local last_maintenance=$(cat telemetry/.last_maintenance 2>/dev/null || echo "99")

    if [ "$current_hour" != "$last_maintenance" ]; then
        log "Running hourly maintenance tasks"

        # Clean up old log files (keep last 7 days)
        find telemetry/ -name "*.log" -mtime +7 -delete 2>/dev/null || true

        # Update maintenance timestamp
        echo "$current_hour" > telemetry/.last_maintenance

        success_log "Maintenance tasks completed"
    fi
}

main() {
    echo "🔄 PHI SOVEREIGN CONTINUOUS MONITORING SYSTEM"
    echo "============================================="
    log "Sovereign monitoring system starting"
    success_log "Maximum Sovereign Power Mode: ACTIVE"

    # Create telemetry directory
    mkdir -p telemetry
    echo "$$" > "$PID_FILE"

    # Initial monitoring cycle
    run_monitoring_cycle

    # Continuous monitoring loop
    while true; do
        run_monitoring_cycle
        maintenance_tasks
        sleep $MONITOR_INTERVAL
    done
}

# Handle shutdown gracefully
trap 'rm -f "$PID_FILE"; log "Sovereign monitoring system shutting down"; exit 0' INT TERM

# Run main function
main "$@"
