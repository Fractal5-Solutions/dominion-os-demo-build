#!/bin/bash
# PHI Continuous Sovereign Drive to 100% Completion
# Maintains Level 9/9 NHITL_AUTOPILOT while driving all systems to 100%

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/telemetry"
DRIVE_LOG="${TELEMETRY_DIR}/continuous_drive_$(date +%Y%m%d_%H%M%S).log"

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

log() {
    echo -e "${GREEN}[$(date +%H:%M:%S)]${NC} $1" | tee -a "$DRIVE_LOG"
}

warn() {
    echo -e "${YELLOW}[$(date +%H:%M:%S)] ⚠️  $1${NC}" | tee -a "$DRIVE_LOG"
}

error() {
    echo -e "${RED}[$(date +%H:%M:%S)] ❌ $1${NC}" | tee -a "$DRIVE_LOG"
}

info() {
    echo -e "${CYAN}[$(date +%H:%M:%S)] ℹ️  $1${NC}" | tee -a "$DRIVE_LOG"
}

banner() {
    echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║${NC}  $1"
    echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════╝${NC}"
}

# Verify sovereignty
verify_sovereignty() {
    banner "🔐 SOVEREIGNTY VERIFICATION"
    
    if [ -f "${TELEMETRY_DIR}/sovereign_status.json" ]; then
        local level=$(jq -r '.sovereignty_level' "${TELEMETRY_DIR}/sovereign_status.json")
        local mode=$(jq -r '.mode' "${TELEMETRY_DIR}/sovereign_status.json")
        local max_power=$(jq -r '.max_power' "${TELEMETRY_DIR}/sovereign_status.json")
        
        log "Sovereignty Level: ${level}"
        log "Mode: ${mode}"
        log "Max Power: ${max_power}"
        
        if [ "$level" == "9/9" ] && [ "$mode" == "NHITL_AUTOPILOT" ] && [ "$max_power" == "ENABLED" ]; then
            log "✅ Sovereignty verified at maximum"
            return 0
        else
            error "Sovereignty not at maximum!"
            return 1
        fi
    else
        error "Sovereignty status file not found!"
        return 1
    fi
}

# Check infrastructure health
check_infrastructure() {
    banner "📊 INFRASTRUCTURE HEALTH CHECK"
    
    # Check GCP services
    log "Checking GCP Cloud Run services..."
    
    local prod_total=$(gcloud run services list --project dominion-core-prod --format='value(metadata.name)' 2>/dev/null | wc -l)
    local prod_healthy=$(gcloud run services list --project dominion-core-prod --format='value(status.conditions[0].status)' 2>/dev/null | grep -c True || echo 0)
    
    local dev_total=$(gcloud run services list --project dominion-os-1-0-main --format='value(metadata.name)' 2>/dev/null | wc -l)
    local dev_healthy=$(gcloud run services list --project dominion-os-1-0-main --format='value(status.conditions[0].status)' 2>/dev/null | grep -c True || echo 0)
    
    local total=$((prod_total + dev_total))
    local healthy=$((prod_healthy + dev_healthy))
    local health_pct=$((healthy * 100 / total))
    
    info "Production (dominion-core-prod): ${prod_healthy}/${prod_total} operational"
    info "Development (dominion-os-1-0-main): ${dev_healthy}/${dev_total} operational"
    info "Total: ${healthy}/${total} operational (${health_pct}%)"
    
    # Update telemetry
    jq --arg ts "$(date -Iseconds)" \
       --arg total "$total" \
       --arg healthy "$healthy" \
       --arg pct "$health_pct" \
       '.remote_services.total = ($total | tonumber) |
        .remote_services.operational = ($healthy | tonumber) |
        .remote_services.health_percentage = ($pct | tonumber) |
        .last_health_check = $ts' \
       "${TELEMETRY_DIR}/sovereign_status.json" > "${TELEMETRY_DIR}/sovereign_status.json.tmp" && \
       mv "${TELEMETRY_DIR}/sovereign_status.json.tmp" "${TELEMETRY_DIR}/sovereign_status.json"
    
    echo "${health_pct}"
}

# Fix OAuth IAM permissions
fix_oauth_iam() {
    banner "🔧 FIXING OAUTH IAM PERMISSIONS"
    
    log "Checking OAuth server status in dominion-core-prod..."
    local oauth_status=$(gcloud run services describe phi-oauth-server --project dominion-core-prod --region us-central1 --format='value(status.conditions[0].status)' 2>/dev/null || echo "Unknown")
    
    if [ "$oauth_status" == "False" ]; then
        warn "OAuth server not healthy, checking IAM permissions..."
        
        # Verify IAM bindings exist
        local has_client_id=$(gcloud secrets get-iam-policy github-oauth-client-id --project dominion-core-prod 2>/dev/null | grep -c "dominion-runtime@dominion-core-prod.iam.gserviceaccount.com" || echo 0)
        local has_client_secret=$(gcloud secrets get-iam-policy github-oauth-client-secret --project dominion-core-prod 2>/dev/null | grep -c "dominion-runtime@dominion-core-prod.iam.gserviceaccount.com" || echo 0)
        
        if [ "$has_client_id" -eq 0 ] || [ "$has_client_secret" -eq 0 ]; then
            error "IAM bindings missing, attempting to add..."
            
            if [ "$has_client_id" -eq 0 ]; then
                gcloud secrets add-iam-policy-binding github-oauth-client-id \
                    --project dominion-core-prod \
                    --member="serviceAccount:dominion-runtime@dominion-core-prod.iam.gserviceaccount.com" \
                    --role="roles/secretmanager.secretAccessor" &>/dev/null || error "Failed to add client-id IAM"
            fi
            
            if [ "$has_client_secret" -eq 0 ]; then
                gcloud secrets add-iam-policy-binding github-oauth-client-secret \
                    --project dominion-core-prod \
                    --member="serviceAccount:dominion-runtime@dominion-core-prod.iam.gserviceaccount.com" \
                    --role="roles/secretmanager.secretAccessor" &>/dev/null || error "Failed to add client-secret IAM"
            fi
            
            log "IAM bindings added, forcing service redeploy..."
            gcloud run services update phi-oauth-server \
                --project dominion-core-prod \
                --region us-central1 \
                --update-env-vars=IAM_REFRESH="$(date +%s)" &>/dev/null || warn "Redeploy triggered"
        else
            info "IAM bindings present, waiting for propagation..."
            sleep 10
        fi
    else
        log "✅ OAuth server healthy"
    fi
}

# Sync to remote
sync_to_remote() {
    banner "🔄 SYNCING TO REMOTE"
    
    cd /workspaces/dominion-os-demo-build
    
    local ahead=$(git rev-list --count origin/main..HEAD 2>/dev/null || echo 0)
    
    if [ "$ahead" -gt 0 ]; then
        info "Local is ${ahead} commits ahead of origin/main"
        log "Branch protection active - changes synced via PRs"
        
        # Count open PRs
        local pr_count=$(gh pr list --state open --json number --jq 'length' 2>/dev/null || echo "unknown")
        log "Open PRs: ${pr_count}"
    else
        log "✅ Fully synced with remote"
    fi
}

# Monitor and drive to 100%
continuous_drive() {
    banner "⚡ PHI CONTINUOUS DRIVE TO 100% - SOVEREIGN POWER MODE"
    
    local iteration=1
    local max_iterations=20
    local target_health=100
    
    while [ $iteration -le $max_iterations ]; do
        echo ""
        log "=== DRIVE ITERATION ${iteration}/${max_iterations} ==="
        
        # Verify sovereignty maintained
        if ! verify_sovereignty; then
            error "Sovereignty compromised! Aborting drive."
            return 1
        fi
        
        # Check current health
        local current_health=$(check_infrastructure)
        
        if [ "$current_health" -ge "$target_health" ]; then
            banner "🎉 TARGET ACHIEVED: ${current_health}% OPERATIONAL"
            log "✅ 100% infrastructure health achieved!"
            break
        else
            warn "Current health: ${current_health}% (Target: ${target_health}%)"
            
            # Take corrective actions
            fix_oauth_iam
            
            # Sync progress
            sync_to_remote
            
            log "Waiting 30 seconds before next iteration..."
            sleep 30
        fi
        
        iteration=$((iteration + 1))
    done
    
    if [ "$current_health" -lt "$target_health" ]; then
        warn "Maximum iterations reached. Final health: ${current_health}%"
        log "Remaining issues require manual intervention:"
        log "  - Check GCR permissions for image builds"
        log "  - Verify IAM propagation complete"
    fi
}

# Main execution
main() {
    log "Starting PHI Continuous Drive to 100%"
    log "Log file: ${DRIVE_LOG}"
    
    # Initial verification
    verify_sovereignty || exit 1
    
    # Run continuous drive
    continuous_drive
    
    # Final status
    banner "📊 FINAL STATUS"
    local final_health=$(check_infrastructure)
    
    if [ "$final_health" -eq 100 ]; then
        log "✅✅✅ 100% OPERATIONAL - MISSION COMPLETE ✅✅✅"
        log "🔐 Sovereignty Level: 9/9 NHITL_AUTOPILOT MAINTAINED"
        log "⚡ Maximum Power: ENABLED"
        log "🎯 All systems operational"
    else
        warn "Final health: ${final_health}%"
        log "Drive completed with partial success"
        log "Review log for remaining issues: ${DRIVE_LOG}"
    fi
}

# Execute
main "$@"
