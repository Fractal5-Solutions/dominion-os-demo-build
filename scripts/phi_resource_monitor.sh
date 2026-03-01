#!/bin/bash
# PHI Resource Monitoring & Alerting System
# Monitors Docker container resources and sends alerts when thresholds exceeded

set -euo pipefail

# Source common utilities
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
if [ -f "${SCRIPT_DIR}/phi_common.sh" ]; then
    source "${SCRIPT_DIR}/phi_common.sh"
else
    # Fallback if common utilities not available
    RED='\033[0;31m'
    GREEN='\033[0;32m'
    YELLOW='\033[1;33m'
    NC='\033[0m'
    error() { echo -e "${RED}❌ $1${NC}"; }
    warning() { echo -e "${YELLOW}⚠️  $1${NC}"; }
    success() { echo -e "${GREEN}✅ $1${NC}"; }
    info() { echo "$1"; }
fi

# Configuration
TELEMETRY_DIR="${TELEMETRY_DIR:-${SCRIPT_DIR}/telemetry}"
ALERT_LOG="${TELEMETRY_DIR}/resource_alerts.log"
CPU_THRESHOLD="${ALERT_CPU_THRESHOLD:-80}"
MEMORY_THRESHOLD="${ALERT_MEMORY_THRESHOLD:-85}"
DISK_THRESHOLD="${ALERT_DISK_THRESHOLD:-90}"
MONITORING_INTERVAL="${MONITORING_INTERVAL:-60}"

# Ensure telemetry directory exists
mkdir -p "${TELEMETRY_DIR}"

# Print banner
echo "=========================================================================="
echo "🔍 PHI Resource Monitor - Dominion OS"
echo "=========================================================================="
echo "  CPU Threshold: ${CPU_THRESHOLD}%"
echo "  Memory Threshold: ${MEMORY_THRESHOLD}%"
echo "  Disk Threshold: ${DISK_THRESHOLD}%"
echo "  Monitoring Interval: ${MONITORING_INTERVAL}s"
echo "  Alert Log: ${ALERT_LOG}"
echo "=========================================================================="
echo ""

# Function to check Docker container resources
check_container_resources() {
    local container_name="$1"

    # Check if container exists and is running
    if ! docker ps --format '{{.Names}}' | grep -q "^${container_name}$"; then
        warning "Container ${container_name} not running"
        return 1
    fi

    # Get container stats (non-streaming, single snapshot)
    local stats=$(docker stats "${container_name}" --no-stream --format "{{.CPUPerc}}|{{.MemPerc}}|{{.MemUsage}}" 2>/dev/null)

    if [ -z "$stats" ]; then
        error "Failed to get stats for ${container_name}"
        return 1
    fi

    # Parse stats
    local cpu_perc=$(echo "$stats" | cut -d'|' -f1 | tr -d '%')
    local mem_perc=$(echo "$stats" | cut -d'|' -f2 | tr -d '%')
    local mem_usage=$(echo "$stats" | cut -d'|' -f3)

    # Convert to integers (remove decimal points)
    cpu_perc=${cpu_perc%.*}
    mem_perc=${mem_perc%.*}

    # Display current status
    info "📊 ${container_name}:"
    info "   CPU: ${cpu_perc}% | Memory: ${mem_perc}% (${mem_usage})"

    # Check thresholds and alert
    local alert_triggered=false

    if [ "${cpu_perc}" -gt "${CPU_THRESHOLD}" ]; then
        warning "   ⚠️  HIGH CPU: ${cpu_perc}% (threshold: ${CPU_THRESHOLD}%)"
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ALERT: ${container_name} CPU at ${cpu_perc}%" >> "${ALERT_LOG}"
        alert_triggered=true
    fi

    if [ "${mem_perc}" -gt "${MEMORY_THRESHOLD}" ]; then
        warning "   ⚠️  HIGH MEMORY: ${mem_perc}% (threshold: ${MEMORY_THRESHOLD}%)"
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ALERT: ${container_name} Memory at ${mem_perc}%" >> "${ALERT_LOG}"
        alert_triggered=true
    fi

    if [ "$alert_triggered" = false ]; then
        success "   ✅ Resources within limits"
    fi

    echo ""
}

# Function to check disk usage
check_disk_usage() {
    info "💾 Disk Usage:"

    # Check root filesystem
    local disk_usage=$(df -h / | awk 'NR==2 {print $5}' | tr -d '%')
    local disk_avail=$(df -h / | awk 'NR==2 {print $4}')

    info "   Root: ${disk_usage}% used (${disk_avail} available)"

    if [ "${disk_usage}" -gt "${DISK_THRESHOLD}" ]; then
        warning "   ⚠️  HIGH DISK USAGE: ${disk_usage}% (threshold: ${DISK_THRESHOLD}%)"
        echo "[$(date -u +"%Y-%m-%d %H:%M:%S UTC")] ALERT: Disk usage at ${disk_usage}%" >> "${ALERT_LOG}"
    else
        success "   ✅ Disk usage within limits"
    fi

    echo ""
}

# Function to check Docker volumes
check_docker_volumes() {
    info "📦 Docker Volume Usage:"

    local volumes=$(docker volume ls --format '{{.Name}}' 2>/dev/null | grep phi || true)

    if [ -z "$volumes" ]; then
        info "   No PHI volumes found"
        return
    fi

    while IFS= read -r volume; do
        local volume_path=$(docker volume inspect "$volume" --format '{{.Mountpoint}}' 2>/dev/null)
        if [ -n "$volume_path" ]; then
            local volume_size=$(du -sh "$volume_path" 2>/dev/null | awk '{print $1}' || echo "N/A")
            info "   ${volume}: ${volume_size}"
        fi
    done <<< "$volumes"

    echo ""
}

# Main monitoring loop
info "🚀 Starting continuous monitoring (Ctrl+C to stop)..."
echo ""

while true; do
    echo "----------------------------------------------------------------------"
    echo "📅 $(date -u +"%Y-%m-%d %H:%M:%S UTC")"
    echo "----------------------------------------------------------------------"
    echo ""

    # Monitor PHI containers
    check_container_resources "phi-expenditure-db" || true
    check_container_resources "phi-expenditure-dashboard" || true

    # Check disk usage
    check_disk_usage

    # Check Docker volumes
    check_docker_volumes

    # Write status to telemetry
    cat > "${TELEMETRY_DIR}/resource_status.json" << EOF
{
  "timestamp": "$(date -u +"%Y-%m-%dT%H:%M:%SZ")",
  "containers_monitored": ["phi-expenditure-db", "phi-expenditure-dashboard"],
  "thresholds": {
    "cpu": ${CPU_THRESHOLD},
    "memory": ${MEMORY_THRESHOLD},
    "disk": ${DISK_THRESHOLD}
  },
  "monitoring_active": true
}
EOF

    info "💤 Sleeping for ${MONITORING_INTERVAL}s..."
    echo ""
    sleep "${MONITORING_INTERVAL}"
done
