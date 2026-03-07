#!/bin/bash

################################################################################
# PHI CLOUD SYNC ENGINE
# Cost-Optimized Cloud Run Deployment with Zero-Downtime Updates
################################################################################

set -euo pipefail

# Configuration
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOG_DIR="${SCRIPT_DIR}/logs"
TELEMETRY_DIR="${SCRIPT_DIR}/telemetry"

# GCP Configuration
GCP_REGION="${GCP_REGION:-us-central1}"
PROJECT_ID_MAIN="dominion-os-1-0-main"
PROJECT_ID_PROD="dominion-core-prod"

# Deployment Defaults (Cost-Optimized)
MIN_INSTANCES=0
MAX_INSTANCES=1
MEMORY="512Mi"
CPU="1.0"
TIMEOUT="300s"
CONCURRENCY=80

# Colors
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
NC='\033[0m'

mkdir -p "${LOG_DIR}" "${TELEMETRY_DIR}"

################################################################################
# LOGGING
################################################################################

log() {
    echo -e "${GREEN}[$(date '+%Y-%m-%d %H:%M:%S')]${NC} $*" | tee -a "${LOG_DIR}/cloud_sync.log"
}

log_info() {
    echo -e "${BLUE}ℹ️  ${NC}$*" | tee -a "${LOG_DIR}/cloud_sync.log"
}

log_warn() {
    echo -e "${YELLOW}⚠️  ${NC}$*" | tee -a "${LOG_DIR}/cloud_sync.log"
}

log_error() {
    echo -e "${RED}❌ ${NC}$*" | tee -a "${LOG_DIR}/cloud_sync.log"
}

log_success() {
    echo -e "${GREEN}✅ ${NC}$*" | tee -a "${LOG_DIR}/cloud_sync.log"
}

################################################################################
# COST MANAGEMENT
################################################################################

estimate_deployment_cost() {
    local service_name="$1"
    
    # Cost factors with min-instances=0:
    # - Build: ~$0.10 per build
    # - Storage: ~$0.02 per image
    # - Run: $0 when idle (min-instances=0)
    # - Requests: First 2M free, then $0.00001 per request
    
    local build_cost=0.10
    local storage_cost=0.02
    local total=$(echo "${build_cost} + ${storage_cost}" | bc)
    
    echo "${total}"
}

################################################################################
# SERVICE VALIDATION
################################################################################

validate_service() {
    local service_dir="$1"
    
    log_info "Validating ${service_dir}..."
    
    if [[ ! -d "${service_dir}" ]]; then
        log_error "Service directory not found: ${service_dir}"
        return 1
    fi
    
    if [[ ! -f "${service_dir}/app.py" ]]; then
        log_error "app.py not found in ${service_dir}"
        return 1
    fi
    
    log_success "Service validation passed"
    return 0
}

################################################################################
# CLOUD RUN OPERATIONS
################################################################################

deploy_service() {
    local service_name="$1"
    local service_dir="$2"
    local project_id="${3:-${PROJECT_ID_MAIN}}"
    
    log "🚀 Deploying ${service_name} to Cloud Run..."
    log_info "   Project: ${project_id}"
    log_info "   Config: min=${MIN_INSTANCES}, max=${MAX_INSTANCES}, mem=${MEMORY}"
    
    if ! validate_service "${service_dir}"; then
        return 1
    fi
    
    local cost=$(estimate_deployment_cost "${service_name}")
    log_info "   Estimated cost: \$${cost}"
    
    cd "${service_dir}"
    
    if gcloud run deploy "${service_name}" \
        --source . \
        --platform managed \
        --region "${GCP_REGION}" \
        --project "${project_id}" \
        --allow-unauthenticated \
        --min-instances "${MIN_INSTANCES}" \
        --max-instances "${MAX_INSTANCES}" \
        --memory "${MEMORY}" \
        --cpu "${CPU}" \
        --timeout "${TIMEOUT}" \
        --concurrency "${CONCURRENCY}" \
        --quiet 2>&1 | tee -a "${LOG_DIR}/deploy_${service_name}.log"; then
        
        log_success "Deployed: ${service_name}"
        echo "$(date '+%Y-%m-%d %H:%M:%S'),${service_name},${project_id},${cost},SUCCESS" >> "${TELEMETRY_DIR}/deployments.csv"
        return 0
    else
        log_error "Failed: ${service_name}"
        return 1
    fi
}

pause_service() {
    local service_name="$1"
    local project_id="$2"
    
    log "⏸️  Pausing ${service_name}..."
    
    gcloud run services update "${service_name}" \
        --project "${project_id}" \
        --region "${GCP_REGION}" \
        --min-instances 0 \
        --max-instances 0 \
        --quiet
    
    log_success "Service paused"
}

resume_service() {
    local service_name="$1"
    local project_id="$2"
    
    log "▶️  Resuming ${service_name}..."
    
    gcloud run services update "${service_name}" \
        --project "${project_id}" \
        --region "${GCP_REGION}" \
        --min-instances "${MIN_INSTANCES}" \
        --max-instances "${MAX_INSTANCES}" \
        --quiet
    
    log_success "Service resumed"
}

################################################################################
# MAIN
################################################################################

main() {
    local command="${1:-help}"
    
    case "${command}" in
        deploy)
            deploy_service "${2}" "${3}" "${4:-${PROJECT_ID_MAIN}}"
            ;;
        pause)
            pause_service "${2}" "${3:-${PROJECT_ID_MAIN}}"
            ;;
        resume)
            resume_service "${2}" "${3:-${PROJECT_ID_MAIN}}"
            ;;
        estimate)
            local cost=$(estimate_deployment_cost "${2:-service}")
            echo "Estimated cost: \$${cost}"
            ;;
        *)
            echo "PHI Cloud Sync Engine"
            echo ""
            echo "Usage: $0 <command> [options]"
            echo ""
            echo "Commands:"
            echo "  deploy <name> <dir> [project]  - Deploy service"
            echo "  pause <name> [project]         - Pause service (scale to 0)"
            echo "  resume <name> [project]        - Resume service"
            echo "  estimate <name>                - Estimate cost"
            echo ""
            exit 0
            ;;
    esac
}

main "$@"
