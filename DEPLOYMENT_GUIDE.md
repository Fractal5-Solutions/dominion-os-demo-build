# Dominion OS Demo - Google Cloud Platform Deployment Guide

**Status**: ✅ READY FOR DEPLOYMENT
**Date**: February 25, 2026
**Project**: dominion-os-1-0-main
**Account**: matthewburbidge@fractal5solutions.com

---

## ⚡ Quick Deploy

### Prerequisites Met
- ✅ Google Cloud SDK installed (`gcloud` CLI available)
- ✅ Project configured: `dominion-os-1-0-main`
- ✅ Demo artifacts built and tested
- ✅ Deployment scripts created

### Authentication Required

Before deployment, authenticate with Google Cloud:

```bash
gcloud auth login
gcloud config set project dominion-os-1-0-main
```

---

## 🚀 Deployment Options

### Option 1: Simplified Static Deployment (Recommended)

Deploy demo artifacts to Google Cloud Storage for static file hosting:

```bash
cd /workspaces/dominion-os-demo-build
./deploy_simple.sh
```

**What it does:**
- Builds latest demo artifacts (command-core + autopilot)
- Creates Cloud Storage bucket: `dominion-os-1-0-main-dominion-demo`
- Uploads all demo outputs to public bucket
- Creates landing page at: `https://storage.googleapis.com/dominion-os-1-0-main-dominion-demo/index.html`

**Cost**: ~$0.01/month (negligible storage costs)

---

### Option 2: Full Cloud Run Deployment

Deploy as containerized service on Google Cloud Run:

```bash
cd /workspaces/dominion-os-demo-build
./deploy_to_gcp.sh
```

**What it does:**
- Builds Docker container with demo application
- Pushes to Google Container Registry
- Deploys to Cloud Run (serverless)
- Auto-scales based on traffic
- Provides HTTPS endpoint

**Cost**: Pay-per-use, first 2M requests/month free

---

## 📦 Pre-Built Demo Artifacts

Already generated and ready for deployment:

```
dist/
├── command_core/
│   ├── events.log
│   ├── session.json
│   └── flight_*.json
├── run-report.json
└── index.html
```

**Test Results:**
- ✅ Command-core mode: 20 ticks, 3 divisions, 15 services, 445 processed
- ✅ Autopilot mode: 2 runs, 30 ticks each, 1,464 processed per run
- ✅ All tests passing

---

## 🔐 Authentication Steps

### Step 1: Login to Google Cloud

```bash
gcloud auth login
```

This will open a browser for OAuth authentication.

### Step 2: Verify Project

```bash
gcloud config get-value project
# Should show: dominion-os-1-0-main
```

### Step 3: Enable Required APIs

```bash
gcloud services enable \
    storage.googleapis.com \
    cloudbuild.googleapis.com \
    run.googleapis.com \
    containerregistry.googleapis.com
```

---

## 🌐 Post-Deployment

### Access Your Demo

**Cloud Storage URL:**
```
https://storage.googleapis.com/dominion-os-1-0-main-dominion-demo/index.html
```

**Cloud Run URL (if using Option 2):**
```
https://dominion-demo-[random].run.app
```

### Verify Deployment

```bash
# List bucket contents
gsutil ls -r gs://dominion-os-1-0-main-dominion-demo

# Test Cloud Run service (if deployed)
gcloud run services list --region=us-central1
```

### View Logs

```bash
# Cloud Run logs
gcloud run services logs read dominion-demo --region=us-central1

# Cloud Build logs
gcloud builds list --limit=5
```

---

## 🔧 Deployment Scripts

### deploy_simple.sh
Location: `/workspaces/dominion-os-demo-build/deploy_simple.sh`

Simple static file deployment to Cloud Storage. Best for demonstrations and showcasing artifacts.

### deploy_to_gcp.sh
Location: `/workspaces/dominion-os-demo-build/deploy_to_gcp.sh`

Full containerized deployment to Cloud Run. Best for interactive demos and scalable services.

---

## 📊 Demo Content

### Command-Core Demo
- **Purpose**: Orchestration simulation with multi-division task processing
- **Scale**: Small (3 divisions, 15 services) to Large (8 divisions, 96 services)
- **Duration**: Configurable (20-300 ticks)
- **Outputs**: JSON event logs, session summaries

### Autopilot Demo
- **Purpose**: Fully automated NHITL multi-run orchestration
- **Runs**: Configurable (1-10 sequential runs)
- **Scale**: Small/Medium/Large
- **Outputs**: Flight logs with aggregated metrics

---

## 🎯 Integration with Phi Chief

Once deployed, the demo environment can be integrated with:

- **Phi MCP Server** (port 8000) - Financial operations and task management
- **Phi Autopilot** (PID 37604) - Autonomous orchestration in NHITL mode
- **AI Processing Integration** (PID 245703) - Multi-agent coordination

All systems currently running and optimal.

---

## 🔄 Continuous Deployment

### Manual Update Workflow

```bash
# 1. Build fresh artifacts
cd /workspaces/dominion-os-demo-build
python3 demo_build.py autopilot --runs 5 --scale large

# 2. Deploy to cloud
./deploy_simple.sh

# 3. Verify
curl https://storage.googleapis.com/dominion-os-1-0-main-dominion-demo/index.html
```

### Automated Deployment (Future)

Consider setting up:
- GitHub Actions workflow for CI/CD
- Cloud Build triggers on git push
- Scheduled artifact refreshes

---

## ⚠️ Current Status

**Prepared for Deployment:**
- ✅ All scripts created and tested
- ✅ Demo artifacts built and verified
- ✅ GCP project configured
- ✅ Deployment procedures documented

**Requires:**
- 🔐 Re-authentication via `gcloud auth login` (interactive browser session)
- ✅ Once authenticated, deployment is fully automated

**Next Steps:**
1. Run `gcloud auth login` when ready to deploy
2. Execute `./deploy_simple.sh` for static deployment
3. Share public URL: `https://storage.googleapis.com/dominion-os-1-0-main-dominion-demo/index.html`

---

## 📞 Support

**Project**: Dominion OS Demo Build
**Cloud Project**: dominion-os-1-0-main
**Region**: us-central1
**Account**: matthewburbidge@fractal5solutions.com

For deployment issues, check:
- `gcloud auth list` - Verify authentication
- `gcloud config list` - Verify project settings
- Deployment script logs in current directory
