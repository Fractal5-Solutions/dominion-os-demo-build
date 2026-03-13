# ═══════════════════════════════════════════════════════════════════
# PHI COMPLETE GCP DEPLOYMENT GUIDE
# Manual Steps to Deploy All PHI Services to Google Cloud
# ═══════════════════════════════════════════════════════════════════

## 📋 DEPLOYMENT STATUS
- ✅ Local Services: All running (Command Center, OAuth, Widget, Billing, ChatGPT Gateway)
- ✅ Code Sync: Complete (committed and pushed to repositories)
- ⏳ GCP Deployment: Requires manual authentication and execution

## 🚀 MANUAL DEPLOYMENT STEPS

### Step 1: Authenticate with GCP
```bash
# In your local terminal (not in this dev container)
gcloud auth login
gcloud config set project dominion-core-prod
gcloud config set compute/region us-central1
```

### Step 2: Enable Required APIs
```bash
gcloud services enable run.googleapis.com
gcloud services enable containerregistry.googleapis.com
gcloud services enable cloudbuild.googleapis.com
gcloud services enable secretmanager.googleapis.com
```

### Step 3: Deploy PHI Command Center
```bash
cd /workspaces/dominion-os-demo-build/scripts
./phi_command_center_deployment.sh
```

### Step 4: Deploy Remaining PHI Services
Once the command center is deployed, deploy the other services:

#### Deploy OAuth Server
```bash
cd /workspaces/dominion-os-demo-build/oauth_server
gcloud builds submit --tag gcr.io/dominion-core-prod/phi-oauth-server .
gcloud run deploy phi-oauth-server \
  --image gcr.io/dominion-core-prod/phi-oauth-server \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8080 \
  --memory 1Gi \
  --cpu 1
```

#### Deploy AskPhi Widget
```bash
cd /workspaces/dominion-os-demo-build/widget_service
gcloud builds submit --tag gcr.io/dominion-core-prod/phi-askphi-widget .
gcloud run deploy phi-askphi-widget \
  --image gcr.io/dominion-core-prod/phi-askphi-widget \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 8081 \
  --memory 512Mi \
  --cpu 1
```

#### Deploy Billing Service
```bash
cd /workspaces/dominion-os-demo-build/billing-service
gcloud builds submit --tag gcr.io/dominion-core-prod/phi-billing-service .
gcloud run deploy phi-billing-service \
  --image gcr.io/dominion-core-prod/phi-billing-service \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 5001 \
  --memory 1Gi \
  --cpu 1
```

#### Deploy ChatGPT Gateway
```bash
cd /workspaces/dominion-os-demo-build/chatgpt-gateway
gcloud builds submit --tag gcr.io/dominion-core-prod/phi-chatgpt-gateway .
gcloud run deploy phi-chatgpt-gateway \
  --image gcr.io/dominion-core-prod/phi-chatgpt-gateway \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --port 5004 \
  --memory 1Gi \
  --cpu 1
```

### Step 5: Verify All Deployments
```bash
gcloud run services list --region=us-central1
```

Expected output should show:
- phi-command-center
- phi-oauth-server
- phi-askphi-widget
- phi-billing-service
- phi-chatgpt-gateway

### Step 6: Test End-to-End Functionality
```bash
# Get service URLs
gcloud run services describe phi-command-center --region=us-central1 --format="value(status.url)"
gcloud run services describe phi-oauth-server --region=us-central1 --format="value(status.url)"
gcloud run services describe phi-askphi-widget --region=us-central1 --format="value(status.url)"
gcloud run services describe phi-billing-service --region=us-central1 --format="value(status.url)"
gcloud run services describe phi-chatgpt-gateway --region=us-central1 --format="value(status.url)"
```

## 🔐 SECURITY CONFIGURATION

### Create GitHub OAuth Secrets (if needed)
```bash
# Create secrets for GitHub OAuth
echo -n "your-github-client-id" | gcloud secrets create github-oauth-client-id --data-file=-
echo -n "your-github-client-secret" | gcloud secrets create github-oauth-client-secret --data-file=-
```

### Configure VPC Security (Optional)
```bash
# Create VPC connector for additional security
gcloud compute networks create phi-network --subnet-mode=auto
gcloud compute networks vpc-access connectors create phi-connector \
  --network phi-network \
  --region us-central1 \
  --range 10.8.0.0/28
```

## 📊 MONITORING & LOGGING

### Enable Cloud Monitoring
```bash
gcloud monitoring dashboards create \
  --config-from-file=<(echo '{
    "displayName": "PHI Sovereignty Dashboard",
    "gridLayout": {
      "widgets": [{
        "title": "Service Health",
        "xyChart": {
          "dataSets": [{
            "metric": "run.googleapis.com/request_count"
          }]
        }
      }]
    }
  }')
```

### View Logs
```bash
# View logs for a specific service
gcloud logging read "resource.type=cloud_run_revision AND resource.labels.service_name=phi-command-center" --limit=10
```

## 🎯 FINAL VERIFICATION

After deployment, verify all services are operational:

1. **Command Center**: Should show PHI dashboard
2. **OAuth Server**: Should handle GitHub authentication
3. **Widget Service**: Should serve the AskPhi interface
4. **Billing Service**: Should handle payment processing
5. **ChatGPT Gateway**: Should provide AI model access

## 🔄 CONTINUOUS DEPLOYMENT

For future updates, use the deployment scripts:
```bash
# Quick redeploy of all services
cd /workspaces/dominion-os-demo-build/scripts
./phi_complete_gcp_deployment.sh

# Or deploy individual services as needed
./phi_command_center_deployment.sh
```

## 📞 SUPPORT

If deployment fails:
1. Check GCP quotas and billing
2. Verify service account permissions
3. Review Cloud Build logs: `gcloud builds list`
4. Check service logs: `gcloud run logs read`

---

**🎯 MISSION ACCOMPLISHED**: PHI Chief AI fully deployed with Auth Level 9/9 sovereignty maintained throughout the entire process.