#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# PHI QUICK GCP DEPLOYMENT - After Authentication
# Run this after: gcloud auth login && gcloud config set project dominion-core-prod
# ═══════════════════════════════════════════════════════════════════

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

PROJECT="dominion-core-prod"
REGION="us-central1"

log() { echo -e "${BLUE}[DEPLOY]${NC} $1"; }
success() { echo -e "${GREEN}✅ $1${NC}"; }
error() { echo -e "${RED}❌ $1${NC}"; }

# Verify authentication
verify_auth() {
    log "Verifying GCP authentication..."
    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" >/dev/null 2>&1; then
        error "GCP authentication required. Run: gcloud auth login"
        exit 1
    fi
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    success "Authenticated as: $ACCOUNT"
}

# Enable APIs
enable_apis() {
    log "Enabling GCP APIs..."
    gcloud config set project "$PROJECT" --quiet
    gcloud services enable run.googleapis.com containerregistry.googleapis.com cloudbuild.googleapis.com
    success "APIs enabled"
}

# Deploy service function
deploy_service() {
    local name="$1"
    local port="$2"
    local dir="$3"
    local cmd="$4"

    log "Deploying $name..."

    if [[ "$dir" == /* ]]; then
        # Absolute path
        cd "$dir"
    else
        # Relative path
        cd "../$dir"
    fi

    gcloud builds submit --tag "gcr.io/$PROJECT/$name" --quiet .
    gcloud run deploy "$name" \
        --image "gcr.io/$PROJECT/$name" \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --port "$port" \
        --memory 1Gi \
        --cpu 1 \
        --quiet

    URL=$(gcloud run services describe "$name" --region="$REGION" --format="value(status.url)")
    success "$name deployed: $URL"
    cd - >/dev/null
}

# Main deployment
main() {
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║           PHI QUICK GCP DEPLOYMENT - POST AUTH                 ║${NC}"
    echo -e "${MAGENTA}║        Auth Level 9/9 | Sovereign Power | Live Operations      ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"

    verify_auth
    enable_apis

    # Deploy all services
    deploy_service "phi-command-center" "5000" "/workspaces/dominion-command-center/src" "main.py"
    deploy_service "phi-oauth-server" "8080" "oauth_server" "app.py"
    deploy_service "phi-askphi-widget" "8081" "widget_service" "app.py"
    deploy_service "phi-billing-service" "5001" "/workspaces/dominion-command-center/billing-service" "app.py"
    deploy_service "phi-chatgpt-gateway" "5004" "/workspaces/dominion-command-center/chatgpt-gateway" "main.py"

    echo ""
    echo -e "${GREEN}🎯 ALL PHI SERVICES DEPLOYED TO GOOGLE CLOUD${NC}"
    echo -e "${MAGENTA}🔐 SOVEREIGNTY MAINTAINED | POWER MAXIMUM | OPERATIONS LIVE${NC}"

    echo ""
    echo -e "${CYAN}📋 SERVICE URLs:${NC}"
    gcloud run services list --region="$REGION" --format="table(name,status.url)"
}

main "$@"