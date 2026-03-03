#!/bin/bash
# phi_oauth_server_repair.sh - Repair script for phi-oauth-server
# This script rebuilds and redeploys the OAuth server with production fixes

set -euo pipefail

PROJECT_ID="${PROJECT_ID:-dominion-core-prod}"
REGION="${REGION:-us-central1}"
SERVICE_NAME="phi-oauth-server"
SERVICE_ACCOUNT="dominion-runtime@${PROJECT_ID}.iam.gserviceaccount.com"

# Color codes
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${BLUE}[$(date +'%Y-%m-%d %H:%M:%S')]${NC} $*"
}

success() {
    echo -e "${GREEN}✓${NC} $*"
}

warning() {
    echo -e "${YELLOW}⚠${NC} $*"
}

error() {
    echo -e "${RED}✗${NC} $*"
}

echo "╔════════════════════════════════════════════════════════════╗"
echo "║         PHI OAuth Server Repair & Redeployment            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

log "Navigating to OAuth server directory..."
cd "$(dirname "$0")/oauth_server" || cd oauth_server || {
    error "Could not find oauth_server directory"
    exit 1
}

log "Verifying fixes applied..."

# Check if health endpoint exists
if grep -q "/health" app.py; then
    success "Health endpoint present in app.py"
else
    error "Health endpoint missing! Running fix..."

    # Backup original
    cp app.py app.py.backup

    # Add health endpoint after the "# Routes" comment
    awk '/# Routes/ {
        print $0
        print ""
        print "@app.route(\"/health\")"
        print "def health():"
        print "    \"\"\"Health check endpoint for Cloud Run\"\"\""
        print "    return jsonify({\"status\": \"healthy\", \"service\": \"phi-oauth-server\", \"timestamp\": datetime.utcnow().isoformat()}), 200"
        print ""
        next
    }
    {print}' app.py.backup > app.py

    success "Added health endpoint to app.py"
fi

# Check if gunicorn is in requirements
if grep -q "gunicorn" requirements.txt; then
    success "Gunicorn present in requirements.txt"
else
    warning "Adding gunicorn to requirements.txt..."
    echo "gunicorn==21.2.0" >> requirements.txt
    success "Added gunicorn to requirements.txt"
fi

# Check Dockerfile
if grep -q "gunicorn" Dockerfile; then
    success "Dockerfile configured for gunicorn"
else
    warning "Updating Dockerfile to use gunicorn..."

    # Backup and update Dockerfile
    cp Dockerfile Dockerfile.backup

    sed -i 's|CMD \["python", "app.py"\]|CMD exec gunicorn --bind :\${PORT:-8080} --workers 2 --threads 4 --worker-class gthread --timeout 300 --keep-alive 5 --log-level info --access-logfile - --error-logfile - app:app|g' Dockerfile

    sed -i 's|http://localhost:5000/health|http://localhost:\${PORT:-8080}/health|g' Dockerfile

    success "Updated Dockerfile"
fi

log "Deploying to Cloud Run..."

# Deploy with appropriate settings
if gcloud run deploy "$SERVICE_NAME" \
    --source=. \
    --region="$REGION" \
    --project="$PROJECT_ID" \
    --platform=managed \
    --allow-unauthenticated \
    --service-account="$SERVICE_ACCOUNT" \
    --memory=2Gi \
    --cpu=1 \
    --concurrency=100 \
    --min-instances=1 \
    --max-instances=10 \
    --timeout=300s \
    --execution-environment=gen2 \
    --quiet; then

    success "Deployment successful!"

    # Get service URL
    SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format='value(status.url)' 2>/dev/null || echo "")

    if [ -n "$SERVICE_URL" ]; then
        log "Service URL: $SERVICE_URL"

        # Test health endpoint
        log "Testing health endpoint..."
        sleep 5

        if curl -sf "${SERVICE_URL}/health" -o /dev/null; then
            success "Health check PASSED! Service is operational"

            # Display health response
            echo ""
            log "Health endpoint response:"
            curl -s "${SERVICE_URL}/health" | python3 -m json.tool || curl -s "${SERVICE_URL}/health"
            echo ""
        else
            warning "Health check did not respond yet. Service may still be starting up."
            log "Check status with: gcloud run services describe $SERVICE_NAME --region=$REGION --project=$PROJECT_ID"
        fi
    fi

    echo ""
    success "PHI OAuth Server repair complete!"

    # Verify service status
    log "Verifying service status..."
    STATUS=$(gcloud run services describe "$SERVICE_NAME" \
        --region="$REGION" \
        --project="$PROJECT_ID" \
        --format='value(status.conditions[0].status)' 2>/dev/null || echo "Unknown")

    if [ "$STATUS" = "True" ]; then
        success "Service status: OPERATIONAL (True)"
    else
        warning "Service status: $STATUS"
        log "Checking recent logs..."
        gcloud logging read \
            "resource.type=cloud_run_revision AND resource.labels.service_name=$SERVICE_NAME" \
            --limit=10 \
            --project="$PROJECT_ID" \
            --format="table(timestamp,severity,textPayload)" \
            2>/dev/null || true
    fi

else
    error "Deployment failed!"
    log "Check Cloud Run permissions and IAM roles"
    exit 1
fi

echo ""
log "Repair script complete!"
log "View service: https://console.cloud.google.com/run/detail/$REGION/$SERVICE_NAME?project=$PROJECT_ID"

exit 0
