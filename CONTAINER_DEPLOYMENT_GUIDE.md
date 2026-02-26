# Container Deployment Guide - Dominion OS 1.0

**Date**: February 25, 2026
**Status**: Work In Progress
**Fractal5 Solutions** | dominion-os-1-0-main

______________________________________________________________________

## 🎯 Overview

This guide documents the strategy for deploying missing container images to Google Cloud Run services. Two services currently require container images:

1. **dominion-os-api** - API service (image not found)
1. **dominion-security-framework** - Security framework service (image not found)

______________________________________________________________________

## 📊 Current Service Status

### ✅ Services with Active Images (7/9)

- askphi-chatbot
- dominion-ai-gateway
- dominion-f5-gateway
- dominion-monitoring-dashboard
- dominion-os-1-0
- dominion-phi-ui
- dominion-revenue-automation

### ⚠️ Services Missing Images (2/9)

- dominion-os-api
- dominion-security-framework

______________________________________________________________________

## 🔧 Deployment Strategies

### Option A: Build from Source (Recommended if Dockerfiles exist)

```bash
# 1. Navigate to service directory
cd path/to/dominion-os-api

# 2. Build Docker image
docker build -t us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-api:latest .

# 3. Authenticate with Artifact Registry
gcloud auth configure-docker us-central1-docker.pkg.dev

# 4. Push to Artifact Registry
docker push us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-api:latest

# 5. Update Cloud Run service
gcloud run services update dominion-os-api \
  --image=us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-api:latest \
  --region=us-central1

# Repeat for dominion-security-framework
```

### Option B: Use Existing Base Image

```bash
# Update services to use existing working image as base
gcloud run services update dominion-os-api \
  --image=us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-1-0:latest \
  --region=us-central1 \
  --set-env-vars="SERVICE_MODE=api"

gcloud run services update dominion-security-framework \
  --image=us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-1-0:latest \
  --region=us-central1 \
  --set-env-vars="SERVICE_MODE=security"
```

### Option C: Create Minimal Service Stubs

```dockerfile
# Dockerfile for dominion-os-api
FROM python:3.12-alpine
WORKDIR /app
COPY requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt
COPY app/ ./app/
CMD ["python", "-m", "uvicorn", "app.main:app", "--host", "0.0.0.0", "--port", "8080"]
```

______________________________________________________________________

## 📋 Prerequisites

### Required Tools

- Docker installed and running
- gcloud CLI authenticated
- Access to Artifact Registry
- Source code repositories

### Required Permissions

- Artifact Registry Writer
- Cloud Run Admin
- Service Account User

### Authentication Check

```bash
# Verify authentication
gcloud auth list
gcloud auth configure-docker us-central1-docker.pkg.dev

# Verify Artifact Registry access
gcloud artifacts repositories list --location=us-central1
```

______________________________________________________________________

## 🚀 Step-by-Step Deployment

### For dominion-os-api

```bash
# 1. Check if source exists
ls -la ../dominion-os-1.0/ | grep api

# 2. If Dockerfile exists, build it
cd ../dominion-os-1.0/services/api/
docker build -t us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-api:latest .

# 3. Push to registry
docker push us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-api:latest

# 4. Verify image in registry
gcloud artifacts docker images list \
  us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion \
  --include-tags

# 5. Update Cloud Run service
gcloud run services update dominion-os-api \
  --image=us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-os-api:latest \
  --region=us-central1 \
  --allow-unauthenticated

# 6. Verify deployment
gcloud run services describe dominion-os-api --region=us-central1
```

### For dominion-security-framework

```bash
# Follow same steps as above, replacing service name
cd ../dominion-os-1.0/services/security/
docker build -t us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-security-framework:latest .
docker push us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-security-framework:latest

gcloud run services update dominion-security-framework \
  --image=us-central1-docker.pkg.dev/dominion-os-1-0-main/dominion/dominion-security-framework:latest \
  --region=us-central1 \
  --allow-unauthenticated
```

______________________________________________________________________

## ✅ Verification

### Check Service Status

```bash
# List all services
gcloud run services list --region=us-central1

# Check specific service
gcloud run services describe dominion-os-api --region=us-central1 --format=json | jq '.status.conditions'

# Test endpoint
curl https://dominion-os-api-66ymegzkya-uc.a.run.app/healthz
```

### Monitor Logs

```bash
# Real-time logs
gcloud run services logs tail dominion-os-api --region=us-central1

# Recent errors
gcloud run services logs read dominion-os-api \
  --region=us-central1 \
  --limit=50 \
  --format="table(timestamp,severity,textPayload)"
```

______________________________________________________________________

## 🔒 Security Considerations

1. **Service Account**: Each service should have dedicated service account
1. **IAM Policies**: Follow principle of least privilege
1. **Secrets**: Use Secret Manager for sensitive data
1. **Network**: Consider VPC connector for private resources
1. **Authentication**: Configure IAM or Identity Platform

______________________________________________________________________

## 📝 Next Steps

### Immediate Actions

1. Locate source repositories for missing services
1. Verify Dockerfile existence and configuration
1. Build and test images locally
1. Deploy to staging environment first
1. Promote to production after validation

### Future Improvements

1. Automate builds with Cloud Build triggers
1. Implement CI/CD pipeline
1. Add health check endpoints
1. Configure auto-scaling parameters
1. Set up monitoring and alerting

______________________________________________________________________

## 🎯 Success Criteria

- [ ] Both services show "READY" status in Cloud Run
- [ ] Health check endpoints return 200 OK
- [ ] Services are accessible via URLs
- [ ] Logs show no critical errors
- [ ] Services integrate with existing stack
- [ ] Performance meets SLA requirements

______________________________________________________________________

## 📞 Support

**Primary Contact**: <matthewburbidge@fractal5solutions.com>
**Project**: dominion-os-1-0-main
**Region**: us-central1
**Documentation**: DEPLOYMENT_GUIDE.md

______________________________________________________________________

**Status**: Ready for implementation when source repositories are available.
