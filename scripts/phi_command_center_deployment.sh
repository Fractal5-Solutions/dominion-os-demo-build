#!/bin/bash
# ═══════════════════════════════════════════════════════════════════
# PHI COMMAND CENTER DEPLOYMENT TO GCP
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

# Configuration
GCP_PROJECT="dominion-core-prod"
REGION="us-central1"

# Logging function
log() {
    echo -e "${BLUE}[DEPLOYMENT]${NC} $1"
}

success() {
    echo -e "${GREEN}✅ $1${NC}"
}

error() {
    echo -e "${RED}❌ $1${NC}" >&2
}

# Verify GCP authentication
verify_gcp_auth() {
    log "Verifying GCP authentication..."

    if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" > /dev/null 2>&1; then
        error "GCP authentication required"
        echo "Please run: gcloud auth login"
        exit 1
    fi

    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    success "Authenticated as: $ACCOUNT"
}

# Enable required APIs
enable_apis() {
    log "Enabling required GCP APIs..."

    gcloud config set project "$GCP_PROJECT" --quiet
    gcloud services enable run.googleapis.com
    gcloud services enable containerregistry.googleapis.com
    gcloud services enable cloudbuild.googleapis.com

    success "GCP APIs enabled"
}

# Deploy Command Center
deploy_command_center() {
    log "Deploying PHI Command Center..."

    # Create command center directory with files
    mkdir -p command_center
    cd command_center

    # Copy main.py from src
    cp ../src/main.py .
    cp ../src/requirements.txt .

    # Create templates directory
    mkdir -p templates
    cp ../src/templates/index.html templates/

    # Create Dockerfile
    cat > Dockerfile << 'EOF'
FROM python:3.12-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update && apt-get install -y \
    gcc \
    curl \
    && rm -rf /var/lib/apt/lists/*

# Install Python dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

# Copy application
COPY . .

# Create non-root user
RUN useradd --create-home --shell /bin/bash app \
    && chown -R app:app /app
USER app

# Health check
HEALTHCHECK --interval=30s --timeout=10s --start-period=5s --retries=3 \
    CMD curl -f http://localhost:5000/health || exit 1

# Expose port
EXPOSE 5000

# Run application
CMD ["python", "main.py"]
EOF

    # Build container image
    log "Building container image for PHI Command Center..."
    gcloud builds submit --tag "gcr.io/$GCP_PROJECT/phi-command-center" --timeout=600 .

    # Deploy to Cloud Run
    log "Deploying PHI Command Center to Cloud Run..."
    gcloud run deploy "phi-command-center" \
        --image "gcr.io/$GCP_PROJECT/phi-command-center" \
        --platform managed \
        --region "$REGION" \
        --allow-unauthenticated \
        --port 5000 \
        --memory 1Gi \
        --cpu 1 \
        --max-instances 10 \
        --concurrency 80 \
        --timeout 300 \
        --set-env-vars "PHI_DEPLOYED=true" \
        --set-env-vars "ENVIRONMENT=production" \
        --quiet

    # Get service URL
    SERVICE_URL=$(gcloud run services describe "phi-command-center" --region="$REGION" --format="value(status.url)")
    success "PHI Command Center deployed to: $SERVICE_URL"

    cd ..
}

# Verify deployment
verify_deployment() {
    log "Verifying PHI Command Center deployment..."

    gcloud config set project "$GCP_PROJECT" --quiet

    if gcloud run services describe "phi-command-center" --region="$REGION" --format="value(status.conditions[0].status)" 2>/dev/null | grep -q "True"; then
        SERVICE_URL=$(gcloud run services describe "phi-command-center" --region="$REGION" --format="value(status.url)")
        success "PHI Command Center: $SERVICE_URL"
        echo ""
        echo -e "${GREEN}🎯 PHI COMMAND CENTER SUCCESSFULLY DEPLOYED TO GCP${NC}"
        echo -e "${MAGENTA}🔐 SOVEREIGNTY MAINTAINED | POWER MAXIMUM | OPERATIONS LIVE${NC}"
    else
        error "PHI Command Center deployment failed"
        exit 1
    fi
}

# Main execution
main() {
    echo -e "${MAGENTA}╔══════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${MAGENTA}║        PHI COMMAND CENTER DEPLOYMENT TO GCP                    ║${NC}"
    echo -e "${MAGENTA}║        Auth Level 9/9 | Sovereign Power | Live Operations      ║${NC}"
    echo -e "${MAGENTA}╚══════════════════════════════════════════════════════════════════╝${NC}"
    echo ""

    log "PHI Command Center Deployment to GCP initiated"

    # Pre-deployment checks
    verify_gcp_auth
    enable_apis

    # Deploy command center
    deploy_command_center

    # Verify deployment
    verify_deployment

    log "PHI Command Center Deployment completed successfully"
}

# Run main function
main "$@"