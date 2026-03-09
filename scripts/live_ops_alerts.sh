#!/bin/bash
# PHI SOVEREIGN ALERT SYSTEM
# Automated alerting for live ops incidents
# Generated: March 9, 2026

set -e

# Configuration
ALERT_LOG="telemetry/live_ops_alerts_$(date +%Y%m%d).log"
STATUS_FILE="telemetry/live_ops_status.json"
ALERT_COOLDOWN=300  # 5 minutes between similar alerts

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

alert() {
    local level=$1
    local message=$2
    local timestamp=$(date '+%Y-%m-%d %H:%M:%S')

    echo "$timestamp [$level] $message" >> "$ALERT_LOG"

    case $level in
        "CRITICAL")
            echo -e "${RED}🚨 CRITICAL ALERT: $message${NC}"
            # In production, this would send SMS/email/pager alerts
            ;;
        "WARNING")
            echo -e "${YELLOW}⚠️  WARNING: $message${NC}"
            ;;
        "INFO")
            echo -e "${GREEN}ℹ️  INFO: $message${NC}"
            ;;
    esac
}

check_service_alerts() {
    if [ ! -f "$STATUS_FILE" ]; then
        alert "WARNING" "Status file not found: $STATUS_FILE"
        return
    fi

    # Check web services
    local web_healthy=$(jq -r '.services.web.healthy' "$STATUS_FILE" 2>/dev/null || echo "0")
    local web_total=$(jq -r '.services.web.total' "$STATUS_FILE" 2>/dev/null || echo "0")

    if [ "$web_healthy" != "$web_total" ]; then
        alert "CRITICAL" "Web services degraded: $web_healthy/$web_total healthy"
    fi

    # Check background services
    local bg_healthy=$(jq -r '.services.background.healthy' "$STATUS_FILE" 2>/dev/null || echo "0")

    if [ "$bg_healthy" != "3" ]; then
        alert "CRITICAL" "Background services degraded: $bg_healthy/3 healthy"
    fi

    # Check system resources
    local cpu_usage=$(jq -r '.system_resources.cpu.usage' "$STATUS_FILE" 2>/dev/null || echo "0")
    local mem_usage=$(jq -r '.system_resources.memory.usage' "$STATUS_FILE" 2>/dev/null || echo "0")
    local disk_usage=$(jq -r '.system_resources.disk.usage' "$STATUS_FILE" 2>/dev/null || echo "0")

    if (( $(echo "$cpu_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
        alert "CRITICAL" "CPU usage critical: ${cpu_usage}%"
    elif (( $(echo "$cpu_usage > 80" | bc -l 2>/dev/null || echo "0") )); then
        alert "WARNING" "CPU usage high: ${cpu_usage}%"
    fi

    if (( $(echo "$mem_usage > 90" | bc -l 2>/dev/null || echo "0") )); then
        alert "CRITICAL" "Memory usage critical: ${mem_usage}%"
    elif (( $(echo "$mem_usage > 85" | bc -l 2>/dev/null || echo "0") )); then
        alert "WARNING" "Memory usage high: ${mem_usage}%"
    fi

    if [ "$disk_usage" -gt 95 ]; then
        alert "CRITICAL" "Disk usage critical: ${disk_usage}%"
    elif [ "$disk_usage" -gt 90 ]; then
        alert "WARNING" "Disk usage high: ${disk_usage}%"
    fi
}

check_live_ops_score() {
    local score=$(jq -r '.live_ops_score' "$STATUS_FILE" 2>/dev/null || echo "0")

    if (( $(echo "$score < 0.80" | bc -l 2>/dev/null || echo "0") )); then
        alert "CRITICAL" "Live Ops Score critical: ${score} (<80%)"
    elif (( $(echo "$score < 0.95" | bc -l 2>/dev/null || echo "0") )); then
        alert "WARNING" "Live Ops Score degraded: ${score} (80-94%)"
    else
        alert "INFO" "Live Ops Score perfect: ${score} (95%+)"
    fi
}

auto_recovery_actions() {
    # Check for failed services and attempt recovery
    local recovery_needed=false

    # Check each service
    for port in 8080 8081 5000 5002 5003 5004 5005; do
        if ! lsof -i :$port | grep -q LISTEN; then
            alert "WARNING" "Service on port $port not responding, attempting restart"
            recovery_needed=true

            # Attempt service restart based on port
            case $port in
                8080)
                    # OAuth server restart
                    bash scripts/phi_start_all_systems.sh &
                    ;;
                8081)
                    # Widget service restart
                    bash scripts/phi_start_all_systems.sh &
                    ;;
                5000)
                    # Command center restart
                    bash scripts/phi_start_all_systems.sh &
                    ;;
                5002|5003|5004|5005)
                    # Other services restart
                    bash scripts/phi_start_all_systems.sh &
                    ;;
            esac
        fi
    done

    # Check background services
    local bg_services=("phi_background_completion_monitor" "phi_cost_minimization_simple" "autonomous_overnight")
    for service in "${bg_services[@]}"; do
        if ! ps aux | grep -q "$service" | grep -v grep; then
            alert "WARNING" "Background service '$service' not running, restarting"
            recovery_needed=true

            case $service in
                phi_background_completion_monitor)
                    bash scripts/phi_background_completion_monitor.sh &
                    ;;
                phi_cost_minimization_simple)
                    bash scripts/phi_cost_minimization_simple.sh &
                    ;;
                autonomous_overnight)
                    bash scripts/autonomous_overnight.sh &
                    ;;
            esac
        fi
    done

    if [ "$recovery_needed" = true ]; then
        alert "INFO" "Auto-recovery actions initiated"
    fi
}

main() {
    echo "🚨 PHI SOVEREIGN ALERT SYSTEM"
    echo "============================"

    # Run checks
    check_service_alerts
    check_live_ops_score
    auto_recovery_actions

    echo "Alert system check completed"
}

# Run main function
main "$@"
