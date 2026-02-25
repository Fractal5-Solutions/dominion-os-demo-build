#!/bin/bash
# Simplified Deployment: Static file server for demo artifacts
# Author: Dominion OS Deployment Systems
# Date: February 25, 2026

set -e

echo "======================================================================="
echo "  DOMINION OS DEMO - SIMPLIFIED CLOUD DEPLOYMENT"
echo "======================================================================="

PROJECT_ID="${GCP_PROJECT_ID:-dominion-os-1-0-main}"
REGION="${GCP_REGION:-us-central1}"
BUCKET_NAME="${PROJECT_ID}-dominion-demo"

echo "Project: $PROJECT_ID"
echo "Region: $REGION"
echo "Bucket: gs://$BUCKET_NAME"
echo ""

# Set project
gcloud config set project "$PROJECT_ID"

# Enable APIs
echo "✅ Enabling required APIs..."
gcloud services enable storage.googleapis.com --quiet

# Build demo artifacts
echo ""
echo "✅ Building demo artifacts..."
cd "$(dirname "$0")"
python3 demo_build.py command-core --duration 100 --scale large --no-ui
python3 demo_build.py autopilot --duration 100 --scale large --runs 3

# Create bucket if doesn't exist
echo ""
echo "✅ Creating/verifying Cloud Storage bucket..."
gsutil mb -p "$PROJECT_ID" -l "$REGION" "gs://$BUCKET_NAME" 2>/dev/null || echo "   Bucket already exists"

# Make bucket public
gsutil iam ch allUsers:objectViewer "gs://$BUCKET_NAME"

# Upload artifacts
echo ""
echo "✅ Uploading demo artifacts to Cloud Storage..."
gsutil -m rsync -r dist/ "gs://$BUCKET_NAME/demo/"

# Create index.html
cat > dist/index.html << 'EOF'
<!DOCTYPE html>
<html>
<head>
    <title>Dominion OS Demo</title>
    <style>
        body { font-family: Arial; max-width: 1200px; margin: 50px auto; padding: 20px; }
        h1 { color: #1a73e8; }
        .demo-link { display: block; margin: 10px 0; padding: 10px; background: #f1f3f4; border-radius: 5px; }
        .demo-link:hover { background: #e8eaed; }
    </style>
</head>
<body>
    <h1>🚀 Dominion OS Demo - Cloud Deployment</h1>
    <p>Welcome to the Dominion OS demonstration environment.</p>

    <h2>📊 Demo Artifacts</h2>
    <div>
        <a class="demo-link" href="demo/command_core/">Command Core Demo Outputs</a>
        <a class="demo-link" href="demo/run-report.json">Latest Run Report</a>
    </div>

    <h2>📈 System Status</h2>
    <p>All Dominion OS systems operational and aligned.</p>

    <footer style="margin-top: 50px; color: #666; border-top: 1px solid #ddd; padding-top: 20px;">
        <p>Dominion OS © 2026 Fractal5 Solutions</p>
    </footer>
</body>
</html>
EOF

gsutil cp dist/index.html "gs://$BUCKET_NAME/index.html"
gsutil setmeta -h "Content-Type:text/html" "gs://$BUCKET_NAME/index.html"

# Get public URL
PUBLIC_URL="https://storage.googleapis.com/$BUCKET_NAME/index.html"

echo ""
echo "======================================================================="
echo "  DEPLOYMENT COMPLETE!"
echo "======================================================================="
echo ""
echo "🌐 Demo URL: $PUBLIC_URL"
echo "📦 Bucket: gs://$BUCKET_NAME"
echo ""
echo "View files:"
echo "  gsutil ls -r gs://$BUCKET_NAME"
echo ""
echo "======================================================================="
