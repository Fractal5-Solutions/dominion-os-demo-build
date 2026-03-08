#!/bin/bash
# Dominion OS Demo - Cloud Build and Cloud Run deployment

set -euo pipefail

PROJECT_ID="${GCP_PROJECT_ID:-dominion-os-1-0-main}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="${SERVICE_NAME:-dominion-os-demo}"

echo "======================================================================="
echo "  DOMINION OS DEMO - CLOUD RUN DEPLOYMENT"
echo "======================================================================="
echo "Project ID:   $PROJECT_ID"
echo "Region:       $REGION"
echo "Service:      $SERVICE_NAME"
echo ""

if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" | grep -q '@'; then
    echo "ERROR: gcloud authentication is required"
    echo "Run: gcloud auth login"
    exit 1
fi

ACCOUNT="$(gcloud auth list --filter=status:ACTIVE --format='value(account)' | head -n 1)"
echo "Authenticated as: $ACCOUNT"

gcloud config set project "$PROJECT_ID" >/dev/null
gcloud services enable cloudbuild.googleapis.com run.googleapis.com containerregistry.googleapis.com --quiet

echo ""
echo "Submitting Cloud Build with Dockerfile.production..."
gcloud builds submit . \
    --config cloudbuild.yaml \
    --substitutions "_SERVICE_NAME=${SERVICE_NAME},_REGION=${REGION},_DOCKERFILE=Dockerfile.production,_BUILD_CONTEXT=."

SERVICE_URL="$(gcloud run services describe "$SERVICE_NAME" --region "$REGION" --format='value(status.url)')"

echo ""
echo "Deployment complete."
echo "Service URL: $SERVICE_URL"
echo "Health URL:  $SERVICE_URL/health"
echo ""
echo "Quick checks:"
echo "  curl $SERVICE_URL/health"
echo "  curl $SERVICE_URL/demo"
echo "  curl $SERVICE_URL/store"
