#!/bin/bash
# ═══════════════════════════════════════════════════════════════
# MCP SERVICES FULL DEPLOYMENT SCRIPT
# Automates complete deployment and verification on Docker Desktop Pro
# Unified deployment automation for GCloud, Azure, and Local (Docker Desktop Pro)
# Usage: ./deploy_mcp_full.sh [gcloud|azure|local]
# ═══════════════════════════════════════════════════════════════

set -e  # Exit on error

# Deployment target selection
DEPLOY_TARGET="local" # default
if [ "$1" == "gcloud" ]; then
    DEPLOY_TARGET="gcloud"
elif [ "$1" == "azure" ]; then
    DEPLOY_TARGET="azure"
fi

print_header "Selected deployment target: $DEPLOY_TARGET"

if [ "$DEPLOY_TARGET" == "local" ]; then
    # ...existing code for Docker Desktop Pro deployment...
    print_header "MCP SERVICES DEPLOYMENT - Docker Desktop Pro"
    echo "Started: $(date)"
    echo ""
    # ...existing code...
elif [ "$DEPLOY_TARGET" == "gcloud" ]; then
    print_header "GCloud Deployment Phase"
    print_info "Deploying MCP services to Google Cloud Run..."
    PROJECT_ID="dominion-os-1-0-main"
    REGION="us-central1"
    # Example: Deploy CRM
    gcloud run deploy dominion-crm \
      --source . \
      --platform managed \
      --region $REGION \
      --project $PROJECT_ID \
      --allow-unauthenticated \
      --set-env-vars "APOLLO_API_KEY=$APOLLO_API_KEY" \
      --memory 1Gi \
      --cpu 1 \
      --max-instances 10
    # ...repeat for other services as needed...
    print_success "GCloud deployment complete"
elif [ "$DEPLOY_TARGET" == "azure" ]; then
    print_header "Azure Deployment Phase"
    print_info "Deploying MCP services to Azure Container Apps..."
    RESOURCE_GROUP="dominion-os-rg"
    LOCATION="eastus"
    # Example: Deploy CRM
    az containerapp create \
      --name dominion-crm \
      --resource-group $RESOURCE_GROUP \
      --image dominion-crm:latest \
      --environment dominion-env \
      --cpu 1 --memory 1Gi \
      --env-vars APOLLO_API_KEY=$APOLLO_API_KEY \
      --ingress external \
      --target-port 8080
    # ...repeat for other services as needed...
    print_success "Azure deployment complete"
else
    print_error "Unknown deployment target: $DEPLOY_TARGET"
    exit 1
fi
