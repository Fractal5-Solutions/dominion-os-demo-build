#!/bin/bash
# PHI SOVEREIGN LIVE OPS MONITORING SYSTEM
# Continuous health monitoring and alerting for all services
# Generated: March 9, 2026

set -e

# Configuration
LOG_DIR="telemetry"
HEALTH_LOG="$LOG_DIR/live_ops_health_$(date +%Y%m%d).log"
ALERT_LOG="$LOG_DIR/live_ops_alerts_$(date +%Y%m%d).log"
STATUS_FILE="$LOG_DIR/live_ops_status.json"

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

# Service endpoints
SERVICES=(
    "oauth:8080"
    "widget:8081"
    "command_center:5000"
    "alt_demo:5002"
    "demo:5003"
    "sidecar:5004"
    "chatgpt_gateway:5005"
)

# Create log directory
mkdir -p "$LOG_DIR"

log_info() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [INFO] $1" >> "$HEALTH_LOG"
    echo -e "${BLUE}[INFO]${NC} $1"
}

log_warn() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" >> "$HEALTH_LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [WARN] $1" >> "$ALERT_LOG"
    echo -e "${YELLOW}[WARN]${NC} $1"
}

log_error() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$HEALTH_LOG"
    echo "$(date '+%Y-%m-%d %H:%M:%S') [ERROR] $1" >> "$ALERT_LOG"
    echo -e "${RED}[ERROR]${NC} $1"
}

log_success() {
    echo "$(date '+%Y-%m-%d %H:%M:%S') [SUCCESS] $1" >> "$HEALTH_LOG"
    echo -e "${GREEN}[SUCCESS]${NC} $1"
}

check_service_health() {
    local service=$1
    local port=$2
    local name=$3

    # Check if port is listening
    if lsof -i :$port | grep -q LISTEN; then
        # Check health endpoint
        if curl -s -f "http://localhost:$port/health" > /dev/null 2>&1; then
            log_success "$name ($port): HEALTHY"
            return 0
        else
            log_warn "$name ($port): PORT OPEN but health endpoint failed"
            return 1
        fi
    else
        log_error "$name ($port): PORT NOT LISTENING"
        return 2
    fi
}

check_background_services() {
    local bg_services=("phi_background_completion_monitor" "phi_cost_minimization_simple" "autonomous_overnight")
    local total_bg=0
    local healthy_bg=0

    for service in "${bg_services[@]}"; do
        local count=$(ps aux | grep -c "$service" | grep -v grep)
        total_bg=$((total_bg + 1))

        if [ "$count" -gt 0 ]; then
            healthy_bg=$((healthy_bg + 1))
            log_success "Background service '$service': RUNNING ($count processes)"
        else
            log_error "Background service '$service': NOT RUNNING"
        fi
    done

    echo "$healthy_bg/$total_bg"
}

check_system_resources() {
    # CPU usage
    local cpu_usage=$(top -bn1 | grep "Cpu(s)" | sed "s/.*, *\([0-9.]*\)%* id.*/\1/" | awk '{print 100 - $1}')
    local cpu_status="HEALTHY"
    if (( $(echo "$cpu_usage > 80" | bc -l) )); then
        cpu_status="HIGH"
        log_warn "CPU usage: ${cpu_usage}% (HIGH)"
    else
        log_info "CPU usage: ${cpu_usage}%"
    fi

    # Memory usage
    local mem_usage=$(free | grep Mem | awk '{printf "%.2f", $3/$2 * 100.0}')
    local mem_status="HEALTHY"
    if (( $(echo "$mem_usage > 85" | bc -l) )); then
        mem_status="HIGH"
        log_warn "Memory usage: ${mem_usage}% (HIGH)"
    else
        log_info "Memory usage: ${mem_usage}%"
    fi

    # Disk usage
    local disk_usage=$(df / | tail -1 | awk '{print $5}' | sed 's/%//')
    local disk_status="HEALTHY"
    if [ "$disk_usage" -gt 90 ]; then
        disk_status="CRITICAL"
        log_error "Disk usage: ${disk_usage}% (CRITICAL)"
    elif [ "$disk_usage" -gt 80 ]; then
        disk_status="HIGH"
        log_warn "Disk usage: ${disk_usage}% (HIGH)"
    else
        log_info "Disk usage: ${disk_usage}%"
    fi

    echo "{\"cpu\": {\"usage\": $cpu_usage, \"status\": \"$cpu_status\"}, \"memory\": {\"usage\": $mem_usage, \"status\": \"$mem_status\"}, \"disk\": {\"usage\": $disk_usage, \"status\": \"$disk_status\"}}"
}

generate_status_report() {
    local web_healthy=0
    local web_total=0
    local bg_healthy_bg=$(check_background_services)
    local resources=$(check_system_resources)

    # Check web services
    for service_info in "${SERVICES[@]}"; do
        IFS=':' read -r name port <<< "$service_info"
        web_total=$((web_total + 1))

        if check_service_health "$name" "$port" "$name"; then
            web_healthy=$((web_healthy + 1))
        fi
    done

    # Generate JSON status
    cat > "$STATUS_FILE" << EOF
{
  "timestamp": "$(date -Iseconds)",
  "live_ops_score": "$(( (web_healthy * 100 + $(echo $bg_healthy_bg | cut -d'/' -f1) * 100) / (web_total + 3) ))/100",
  "services": {
    "web": {
      "healthy": $web_healthy,
      "total": $web_total,
      "status": "$([ $web_healthy -eq $web_total ] && echo "PERFECT" || echo "DEGRADED")"
    },
    "background": {
      "healthy": $(echo $bg_healthy_bg | cut -d'/' -f1),
      "total": 3,
      "status": "$([ $(echo $bg_healthy_bg | cut -d'/' -f1) -eq 3 ] && echo "PERFECT" || echo "DEGRADED")"
    }
  },
  "system_resources": $resources,
  "sovereign_mode": "MAXIMUM_ACTIVE",
  "authority_level": "9/9"
}
EOF

    log_info "Status report generated: $STATUS_FILE"
}

main() {
    echo "🔍 PHI SOVEREIGN LIVE OPS MONITORING SYSTEM"
    echo "=========================================="
    log_info "Starting live ops monitoring cycle"

    generate_status_report

    # Check overall health
    local live_ops_score=$(jq -r '.live_ops_score' "$STATUS_FILE" 2>/dev/null || echo "0")
    if (( $(echo "$live_ops_score >= 0.95" | bc -l) )); then
        log_success "LIVE OPS SCORE: ${live_ops_score} - PERFECT (95%+)"
    elif (( $(echo "$live_ops_score >= 0.80" | bc -l) )); then
        log_warn "LIVE OPS SCORE: ${live_ops_score} - GOOD (80-94%)"
    else
        log_error "LIVE OPS SCORE: ${live_ops_score} - DEGRADED (<80%)"
    fi

    log_info "Live ops monitoring cycle completed"
}

# Run main function
main "$@"
