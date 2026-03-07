#!/bin/bash
# Deploy Relationship Applications to Google Cloud

echo "☁️  Deploying relationship applications to Google Cloud Run..."

PROJECT_ID="dominion-os-1-0-main"
REGION="us-central1"
REPO_ROOT="/workspaces/dominion-os-demo-build"

# Deploy CRM Application
echo "Deploying CRM application..."
gcloud run deploy dominion-crm \
  --source "$REPO_ROOT/crm_service" \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,APOLLO_API_KEY=$APOLLO_API_KEY" \
  --memory 1Gi \
  --cpu 1 \
  --max-instances 10 \
  --min-instances 0

# Deploy BIMS Application
echo "Deploying BIMS application..."
gcloud run deploy dominion-bims \
  --source "$REPO_ROOT/bims_service" \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,GMAIL_API_KEY=$GMAIL_API_KEY,GOOGLE_DRIVE_API_KEY=$GOOGLE_DRIVE_API_KEY" \
  --memory 2Gi \
  --cpu 2 \
  --max-instances 10 \
  --min-instances 0

# Deploy Relationship API
echo "Deploying Relationship API..."
gcloud run deploy dominion-relationships \
  --source "$REPO_ROOT/relationships_service" \
  --platform managed \
  --region $REGION \
  --project $PROJECT_ID \
  --allow-unauthenticated \
  --set-env-vars "ENVIRONMENT=production,APOLLO_API_KEY=$APOLLO_API_KEY,GMAIL_API_KEY=$GMAIL_API_KEY" \
  --memory 1Gi \
  --cpu 1 \
  --max-instances 5 \
  --min-instances 0

echo "✅ Applications deployed successfully!"
