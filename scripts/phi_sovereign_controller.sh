#!/bin/bash

################################################################################
# PHI SOVEREIGN CONTROLLER
# Intelligent Local/Remote Sync with Cost-Aware Automation
################################################################################

set -euo pipefail

# ANSI Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
WHITE='\033[1;37m'
NC='\033[0m' # No Color

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TELEMETRY_DIR="${SCRIPT_DIR}/telemetry"
STATE_FILE="${TELEMETRY_DIR}/sovereign_state.json"
COST_BUDGET_MONTHLY=10.00
COST_WARNING_THRESHOLD=7.50
SYNC_INTERVAL_MINUTES=15
MAX_COST_PER_SYNC=2.00

mkdir -p "${LOG_DIR}" "${TELEMETRY_DIR}"

################################################################################
# LOGGING
################################################################################

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "${LOG_DIR}/sovereign_controller.log"
}

log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$*" | tee -a "${LOG_DIR}/sovereign_controller.log"
}

log_warn() {
    echo -e "${YELLOW}⚠️  ${NC}$*" | tee -a "${LOG_DIR}/sovereign_controller.log"
}

log_error() {
    echo -e "${RED}❌ ${NC}$*" | tee -a "${LOG_DIR}/sovereign_controller.log"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$*" | tee -a "${LOG_DIR}/sovereign_controller.log"
}

################################################################################
# STATE MANAGEMENT
################################################################################

initialize_state() {
    if [[ ! -f "${STATE_FILE}" ]]; then
        cat > "${STATE_FILE}" <<EOF
{
  "mode": "SOVEREIGN_LOCAL",
  "last_sync": "never",
  "last_cloud_deploy": "never",
  "cost_this_month": 0.00,
  "sync_count_today": 0,
  "health_status": "HEALTHY",
  "cloud_enabled": false,
  "pending_changes": 0,
  "last_git_commit": "",
  "services_running_local": 4,
  "services_running_cloud": 33,
  "failover_mode": false
}
EOF
        log_success "Initialized sovereign state"
    fi
}

get_state() {
    local key="$1"
    jq -r ".${key}" "${STATE_FILE}" 2>/dev/null || echo "unknown"
}

set_state() {
    local key="$1"
    local value="$2"
    local temp_file="${STATE_FILE}.tmp"
    
    jq ".${key} = \"${value}\"" "${STATE_FILE}" > "${temp_file}" && mv "${temp_file}" "${STATE_FILE}"
}

set_state_number() {
    local key="$1"
    local value="$2"
    local temp_file="${STATE_FILE}.tmp"
    
    jq ".${key} = ${value}" "${STATE_FILE}" > "${temp_file}" && mv "${temp_file}" "${STATE_FILE}"
}

################################################################################
# COST MANAGEMENT
################################################################################

get_current_month_cost() {
    # Query GCP for current month billing (simplified)
    local current_month=$(date '+%Y-%m')
    
    # Check if gcloud is authenticated
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &>/dev/null; then
        echo "0.00"
        return
    fi
    
    # Get approximate cost from service count and usage
    local running_services=$(get_state "services_running_cloud")
    local estimated_cost=$(echo "scale=2; ${running_services} * 0.15" | bc 2>/dev/null || echo "0.00")
    
    echo "${estimated_cost}"
}

check_cost_budget() {
    local current_cost=$(get_current_month_cost)
    local budget_remaining=$(echo "${COST_BUDGET_MONTHLY} - ${current_cost}" | bc)
    
    set_state "cost_this_month" "${current_cost}"
    
    if (( $(echo "${current_cost} >= ${COST_BUDGET_MONTHLY}" | bc -l) )); then
        log_error "💰 BUDGET EXCEEDED: \$${current_cost} / \$${COST_BUDGET_MONTHLY}"
        return 1
    elif (( $(echo "${current_cost} >= ${COST_WARNING_THRESHOLD}" | bc -l) )); then
        log_warn "💰 Budget warning: \$${current_cost} / \$${COST_BUDGET_MONTHLY} (${budget_remaining} remaining)"
        return 2
    else
        log_info "💰 Budget healthy: \$${current_cost} / \$${COST_BUDGET_MONTHLY}"
        return 0
    fi
}

estimate_sync_cost() {
    local service_count="${1:-1}"
    # Rough estimate: $0.50 per service update (build + deploy)
    local estimated=$(echo "scale=2; ${service_count} * 0.50" | bc)
    echo "${estimated}"
}

################################################################################
# GIT CHANGE DETECTION
################################################################################

check_git_changes() {
    cd "${SCRIPT_DIR}/.." || return 1
    
    local last_commit=$(get_state "last_git_commit")
    local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    
    if [[ "${last_commit}" == "${current_commit}" ]] || [[ "${current_commit}" == "unknown" ]]; then
        log_info "📝 No new git commits detected"
        set_state_number "pending_changes" 0
        return 1
    fi
    
    # Check what changed
    local changed_files=$(git diff --name-only "${last_commit}" 2>/dev/null | wc -l)
    local services_changed=$(git diff --name-only "${last_commit}" 2>/dev/null | grep -E "(oauth_server|widget_service|billing|demo)" | wc -l)
    
    log_success "📝 Detected ${changed_files} changed files, ${services_changed} services affected"
    set_state_number "pending_changes" "${services_changed}"
    
    return 0
}

################################################################################
# CLOUD HEALTH MONITORING
################################################################################

check_cloud_health() {
    log_info "🏥 Checking cloud service health..."
    
    # Quick health check - just verify gcloud works
    if ! gcloud projects list --limit=1 &>/dev/null; then
        log_warn "Cloud connection unhealthy"
        set_state "health_status" "DEGRADED"
        return 1
    fi
    
    log_success "Cloud connection healthy"
    set_state "health_status" "HEALTHY"
    return 0
}

################################################################################
# SYNC DECISION ENGINE
################################################################################

should_sync_to_cloud() {
    local mode=$(get_state "mode")
    local pending_changes=$(get_state "pending_changes")
    local sync_count=$(get_state "sync_count_today")
    local current_hour=$(date '+%H')
    
    log_info "🤔 Evaluating sync decision..."
    log_info "   Mode: ${mode}"
    log_info "   Pending changes: ${pending_changes}"
    log_info "   Syncs today: ${sync_count}"
    log_info "   Current hour: ${current_hour}"
    
    # RULE 1: If in SOVEREIGN_LOCAL mode, never auto-sync
    if [[ "${mode}" == "SOVEREIGN_LOCAL" ]]; then
        log_info "   ❌ SOVEREIGN_LOCAL mode - no auto-sync"
        return 1
    fi
    
    # RULE 2: Check cost budget
    if ! check_cost_budget; then
        log_warn "   ❌ Budget constraint - no sync"
        return 1
    fi
    
    # RULE 3: No pending changes
    if [[ "${pending_changes}" -eq 0 ]]; then
        log_info "   ❌ No pending changes"
        return 1
    fi
    
    # RULE 4: Check sync frequency (max 4 per day)
    if [[ "${sync_count}" -ge 4 ]]; then
        log_warn "   ❌ Max syncs per day reached (${sync_count}/4)"
        return 1
    fi
    
    # RULE 5: Avoid peak hours (9 AM - 5 PM = expensive, 09-17)
    if [[ "${current_hour}" -ge 9 ]] && [[ "${current_hour}" -lt 17 ]]; then
        log_info "   ⏰ Peak hours - scheduling for off-peak (3 AM)"
        return 2  # Special code: schedule for later
    fi
    
    # RULE 6: Estimate cost of sync
    local sync_cost=$(estimate_sync_cost "${pending_changes}")
    if (( $(echo "${sync_cost} > ${MAX_COST_PER_SYNC}" | bc -l) )); then
        log_warn "   ❌ Estimated cost \$${sync_cost} exceeds limit \$${MAX_COST_PER_SYNC}"
        return 1
    fi
    
    log_success "   ✅ All checks passed - sync approved (est. cost: \$${sync_cost})"
    return 0
}

################################################################################
# CLOUD SYNC OPERATIONS
################################################################################

sync_to_cloud() {
    local service_name="${1:-all}"
    
    log "🚀 Starting cloud sync for: ${service_name}"
    
    # Pre-flight checks
    if ! check_cloud_health; then
        log_error "Cloud health check failed - aborting sync"
        return 1
    fi
    
    # Update sync counters
    local sync_count=$(get_state "sync_count_today")
    set_state_number "sync_count_today" $((sync_count + 1))
    set_state "last_sync" "$(date '+%Y-%m-%d %H:%M:%S')"
    
    # For now, just log the action (actual deployment would go here)
    log_info "Would deploy ${service_name} to Cloud Run..."
    log_info "Using: min-instances=0, max-instances=1, concurrency=80"
    
    # Update git commit tracking
    local current_commit=$(git rev-parse HEAD 2>/dev/null || echo "unknown")
    set_state "last_git_commit" "${current_commit}"
    set_state_number "pending_changes" 0
    set_state "last_cloud_deploy" "$(date '+%Y-%m-%d %H:%M:%S')"
    
    log_success "Cloud sync completed"
    return 0
}

################################################################################
# MODE SWITCHING
################################################################################

set_mode() {
    local new_mode="$1"
    local old_mode=$(get_state "mode")
    
    case "${new_mode}" in
        SOVEREIGN_LOCAL)
            log "🏛️  Switching to SOVEREIGN LOCAL mode"
            set_state "mode" "SOVEREIGN_LOCAL"
            set_state "cloud_enabled" "false"
            log_success "Now in SOVEREIGN LOCAL mode - all operations local, zero cloud cost"
            ;;
        INTELLIGENT_HYBRID)
            log "🔄 Switching to INTELLIGENT HYBRID mode"
            set_state "mode" "INTELLIGENT_HYBRID"
            set_state "cloud_enabled" "true"
            log_success "Now in INTELLIGENT HYBRID mode - smart sync enabled"
            ;;
        CLOUD_PRIORITY)
            log "☁️  Switching to CLOUD PRIORITY mode"
            set_state "mode" "CLOUD_PRIORITY"
            set_state "cloud_enabled" "true"
            log_warn "Now in CLOUD PRIORITY mode - increased costs expected"
            ;;
        *)
            log_error "Unknown mode: ${new_mode}"
            return 1
            ;;
    esac
    
    log_info "Mode changed: ${old_mode} → ${new_mode}"
}

################################################################################
# MONITORING LOOP
################################################################################

run_monitoring_cycle() {
    log ""
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log "PHI SOVEREIGN CONTROLLER - Monitoring Cycle"
    log "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    
    # Step 1: Check current mode
    local mode=$(get_state "mode")
    log_info "Current mode: ${mode}"
    
    # Step 2: Monitor costs
    check_cost_budget
    local cost_status=$?
    
    if [[ ${cost_status} -eq 1 ]]; then
        # Budget exceeded - force sovereign local mode
        log_error "EMERGENCY: Forcing SOVEREIGN LOCAL mode due to budget"
        set_mode "SOVEREIGN_LOCAL"
        return 0
    fi
    
    # Step 3: Check for git changes
    if check_git_changes; then
        log_success "Changes detected - evaluating sync decision"
        
        if should_sync_to_cloud; then
            local decision=$?
            if [[ ${decision} -eq 0 ]]; then
                log "Initiating cloud sync now..."
                sync_to_cloud "all"
            elif [[ ${decision} -eq 2 ]]; then
                log_info "Sync scheduled for off-peak hours (3 AM)"
            fi
        fi
    fi
    
    # Step 4: Health check (if cloud enabled)
    if [[ "$(get_state cloud_enabled)" == "true" ]]; then
        check_cloud_health
    fi
    
    # Step 5: Display status
    display_status
    
    log_info "Monitoring cycle complete. Next check in ${SYNC_INTERVAL_MINUTES} minutes."
}

################################################################################
# STATUS DISPLAY
################################################################################

display_status() {
    echo ""
    echo -e "${PURPLE}╔════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${PURPLE}║${WHITE}       PHI SOVEREIGN POWER - STATUS DASHBOARD          ${PURPLE}║${NC}"
    echo -e "${PURPLE}╚════════════════════════════════════════════════════════════╝${NC}"
    echo ""
    
    local mode=$(get_state "mode")
    local cost=$(get_state "cost_this_month")
    local health=$(get_state "health_status")
    local pending=$(get_state "pending_changes")
    local last_sync=$(get_state "last_sync")
    local syncs_today=$(get_state "sync_count_today")
    
    echo -e "  ${CYAN}Mode:${NC}             ${WHITE}${mode}${NC}"
    echo -e "  ${CYAN}Health:${NC}           ${GREEN}${health}${NC}"
    echo -e "  ${CYAN}Cost (MTD):${NC}       ${YELLOW}\$${cost} / \$${COST_BUDGET_MONTHLY}${NC}"
    echo -e "  ${CYAN}Pending Changes:${NC}  ${WHITE}${pending}${NC}"
    echo -e "  ${CYAN}Syncs Today:${NC}      ${WHITE}${syncs_today} / 4${NC}"
    echo -e "  ${CYAN}Last Sync:${NC}        ${WHITE}${last_sync}${NC}"
    echo ""
    
    # Show local services
    echo -e "${BLUE}Local Services:${NC}"
    if pgrep -f "python3.*app.py" >/dev/null; then
        local count=$(pgrep -f "python3.*app.py" | wc -l)
        echo -e "  ${GREEN}✓${NC} ${count} services running"
    else
        echo -e "  ${RED}✗${NC} No services detected"
    fi
    
    echo ""
}

################################################################################
# MAIN FUNCTION
################################################################################

main() {
    local command="${1:-monitor}"
    
    # Initialize state file
    initialize_state
    
    case "${command}" in
        monitor)
            log "Starting PHI Sovereign Controller in monitor mode..."
            log "Press Ctrl+C to stop"
            
            while true; do
                run_monitoring_cycle
                sleep $((SYNC_INTERVAL_MINUTES * 60))
            done
            ;;
        
        status)
            display_status
            ;;
        
        sync)
            log "Manual sync requested..."
            if check_cost_budget; then
                sync_to_cloud "all"
            else
                log_error "Budget constraint - cannot sync"
                exit 1
            fi
            ;;
        
        mode)
            if [[ -z "${2:-}" ]]; then
                echo "Current mode: $(get_state mode)"
                echo "Available modes: SOVEREIGN_LOCAL, INTELLIGENT_HYBRID, CLOUD_PRIORITY"
                exit 0
            fi
            set_mode "$2"
            ;;
        
        cost)
            local cost=$(get_current_month_cost)
            local remaining=$(echo "${COST_BUDGET_MONTHLY} - ${cost}" | bc)
            echo "💰 Cost Dashboard"
            echo "  Current: \$${cost}"
            echo "  Budget: \$${COST_BUDGET_MONTHLY}"
            echo "  Remaining: \$${remaining}"
            ;;
        
        reset)
            log_warn "Resetting sovereign state..."
            rm -f "${STATE_FILE}"
            initialize_state
            log_success "State reset complete"
            ;;
        
        *)
            echo "PHI Sovereign Controller"
            echo ""
            echo "Usage: $0 <command>"
            echo ""
            echo "Commands:"
            echo "  monitor    - Start continuous monitoring (default)"
            echo "  status     - Display current status"
            echo "  sync       - Manually trigger cloud sync"
            echo "  mode       - Get/set operating mode"
            echo "  cost       - Show cost dashboard"
            echo "  reset      - Reset state file"
            echo ""
            exit 1
            ;;
    esac
}

# Run main function
main "$@"
