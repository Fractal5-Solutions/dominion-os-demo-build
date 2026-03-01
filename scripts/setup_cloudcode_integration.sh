#!/bin/bash
# Google Cloud Code Startup Integration
# Ensures optimal VS Code integration for continuous deployment

set -e

echo "🚀 Initializing Google Cloud Code Integration..."

# Check VS Code Cloud Code extension
echo "📦 Verifying Google Cloud Code extension..."
if command -v code &> /dev/null; then
    if ! code --list-extensions | grep -q "googlecloudtools.cloudcode"; then
        echo "⚠️  Google Cloud Code extension not installed"
        echo "Installing Google Cloud Code extension..."
        code --install-extension googlecloudtools.cloudcode
    else
        echo "✅ Google Cloud Code extension installed"
    fi
fi

# Verify GCP CLI and configuration
echo "🔐 Verifying Google Cloud CLI configuration..."
if ! command -v gcloud &> /dev/null; then
    echo "❌ Google Cloud CLI not found. Install from: https://cloud.google.com/sdk/docs/install"
    exit 1
fi

echo "✅ Google Cloud CLI found: $(gcloud version --format='value(Google Cloud SDK)')"

# Check authentication
if ! gcloud auth list --filter=status:ACTIVE --format="value(account)" &> /dev/null; then
    echo "⚠️  GCP authentication required"
    echo "Run: gcloud auth login"
    echo "Then: gcloud auth application-default login"
else
    ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)")
    echo "✅ Authenticated as: $ACCOUNT"
fi

# Set default project if configured
if [ -f ".cloudcode/config.json" ]; then
    PROJECT_ID=$(grep -o '"projectId": "[^"]*"' .cloudcode/config.json | cut -d'"' -f4)
    if [ ! -z "$PROJECT_ID" ]; then
        echo "🔧 Setting default project: $PROJECT_ID"
        gcloud config set project "$PROJECT_ID" --quiet
        echo "✅ Project set: $PROJECT_ID"
    fi
fi

# Verify Skaffold installation
echo "🔧 Checking Skaffold installation..."
if ! command -v skaffold &> /dev/null; then
    echo "📦 Installing Skaffold..."
    curl -Lo skaffold https://storage.googleapis.com/skaffold/releases/latest/skaffold-linux-amd64
    chmod +x skaffold
    sudo mv skaffold /usr/local/bin
    echo "✅ Skaffold installed"
else
    echo "✅ Skaffold found: $(skaffold version)"
fi

# Enable required APIs
echo "🔌 Enabling required Google Cloud APIs..."
gcloud services enable cloudbuild.googleapis.com --quiet || echo "  (API may already be enabled)"
gcloud services enable run.googleapis.com --quiet || echo "  (API may already be enabled)"
gcloud services enable containerregistry.googleapis.com --quiet || echo "  (API may already be enabled)"

echo ""
echo "✅ Google Cloud Code integration ready!"
echo "📋 Available VS Code tasks:"
echo "   - Cloud Code: Deploy to Cloud Run (Dev)"
echo "   - Cloud Code: Deploy to Cloud Run (Prod)"
echo "   - GCP: Validate Auth & Project"
echo "   - GCP: Full Stack Deploy"
echo ""
echo "🐛 Debug configurations available:"
echo "   - Cloud Code: Debug on Cloud Run"
echo "   - Cloud Code: Debug Locally"
echo ""
echo "🚀 Ready for continuous deployment operations!"
