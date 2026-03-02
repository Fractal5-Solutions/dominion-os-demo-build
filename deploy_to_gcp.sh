#!/bin/bash
# Dominion OS Demo - Google Cloud Platform Deployment Script
# Author: Dominion OS Deployment Systems
# Date: February 25, 2026

set -e  # Exit on error

echo "======================================================================="
echo "  DOMINION OS DEMO - GOOGLE CLOUD PLATFORM DEPLOYMENT"
echo "======================================================================="

# Configuration
PROJECT_ID="${GCP_PROJECT_ID:-dominion-os-1-0-main}"
REGION="${GCP_REGION:-us-central1}"
SERVICE_NAME="dominion-demo"
IMAGE_NAME="gcr.io/${PROJECT_ID}/dominion-demo:latest"

echo "Project ID: $PROJECT_ID"
echo "Region: $REGION"
echo "Service Name: $SERVICE_NAME"
echo "Image: $IMAGE_NAME"
echo ""

# Step 1: Verify gcloud authentication
echo "✅ Step 1: Verifying Google Cloud authentication..."
if ! gcloud auth list 2>&1 | grep -q "ACTIVE"; then
    echo "❌ ERROR: Not authenticated with Google Cloud"
    echo "Run: gcloud auth login"
    exit 1
fi
ACCOUNT=$(gcloud config get-value account 2>/dev/null)
echo "   Authenticated as: $ACCOUNT"

# Step 2: Set project
echo ""
echo "✅ Step 2: Setting Google Cloud project..."
gcloud config set project "$PROJECT_ID"

# Step 3: Enable required APIs
echo ""
echo "✅ Step 3: Enabling required Google Cloud APIs..."
gcloud services enable \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    containerregistry.googleapis.com \
    --quiet || echo "   (APIs may already be enabled)"

# Step 4: Build demo artifacts locally
echo ""
echo "✅ Step 4: Building demo artifacts..."
cd "$(dirname "$0")"
python3 demo_build.py command-core --duration 50 --scale large --no-ui
echo "   ✓ Command-core demo artifacts built"

# Step 5: Create Dockerfile if not exists
echo ""
echo "✅ Step 5: Preparing Docker container..."
if [ ! -f "Dockerfile" ]; then
    cat > Dockerfile << 'EOF'
FROM python:3.12-slim

WORKDIR /app

# Install dependencies
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt || echo "No requirements.txt, skipping"

# Copy application code
COPY . .

# Expose port
ENV PORT=8080
EXPOSE 8080

# Run demo server
CMD ["python3", "-m", "http.server", "8080", "--directory", "dist"]
EOF
    echo "   ✓ Dockerfile created"
else
    echo "   ✓ Dockerfile already exists"
fi

# Step 6: Build and push Docker image
echo ""
echo "✅ Step 6: Building Docker image..."
docker build -t "$IMAGE_NAME" .
echo "   ✓ Docker image built"

echo ""
echo "✅ Step 7: Pushing image to Google Container Registry..."
docker push "$IMAGE_NAME"
echo "   ✓ Image pushed to GCR"

# Step 8: Deploy to Cloud Run
echo ""
echo "✅ Step 8: Deploying to Google Cloud Run..."
gcloud run deploy "$SERVICE_NAME" \
    --image "$IMAGE_NAME" \
    --platform managed \
    --region "$REGION" \
    --allow-unauthenticated \
    --memory 512Mi \
    --cpu 1 \
    --timeout 300 \
    --max-instances 10 \
    --quiet

# Step 9: Get service URL
echo ""
echo "✅ Step 9: Retrieving service URL..."
SERVICE_URL=$(gcloud run services describe "$SERVICE_NAME" \
    --platform managed \
    --region "$REGION" \
    --format 'value(status.url)')

echo ""
echo "======================================================================="
echo "  DEPLOYMENT COMPLETE!"
echo "======================================================================="
echo ""
echo "🌐 Service URL: $SERVICE_URL"
echo "📦 Image: $IMAGE_NAME"
echo "🔧 Service Name: $SERVICE_NAME"
echo "📍 Region: $REGION"
echo ""
echo "Test your deployment:"
echo "  curl $SERVICE_URL"
echo ""
echo "View logs:"
echo "  gcloud run services logs read $SERVICE_NAME --region=$REGION"
echo ""
echo "Manage service:"
echo "  gcloud run services describe $SERVICE_NAME --region=$REGION"
echo ""
echo "======================================================================="
