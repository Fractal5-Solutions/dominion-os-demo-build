# 🚀 Dominion OS - Cloud Deployment Quick Reference

**Optimized Google Cloud Code Integration for Continuous Deployment**

## 📁 Key Configuration Files

| File | Purpose | Status |
|------|---------|--------|
| `Dockerfile` | Multi-stage optimized container build | ✅ Optimized |
| `.dockerignore` | Build optimization (smaller images) | ✅ Optimized |
| `skaffold.yaml` | Deployment automation config | ✅ Optimized |
| `service.yaml` | Cloud Run service definition | ✅ Optimized |
| `cloudbuild.yaml` | CI/CD pipeline configuration | ✅ Optimized |
| `.cloudcode/config.json` | VS Code Cloud Code settings | ✅ Optimized |
| `.vscode/tasks.json` | Quick deployment tasks | ✅ Optimized |
| `.vscode/settings.json` | IDE integration settings | ✅ Optimized |

## ⚡ VS Code Tasks (Ctrl+Shift+P → Tasks: Run Task)

### **Deployment Tasks**
- `Cloud Code: Deploy to Cloud Run (Dev)` - Development deployment with hot reload
- `Cloud Code: Deploy to Cloud Run (Prod)` - Production deployment
- `GCP: Full Stack Deploy` - Complete deployment pipeline
- `Cloud Build: Submit Build` - Trigger Cloud Build CI/CD

### **Development Tasks**
- `Skaffold: Dev Mode (Hot Reload)` - Real-time code sync to Cloud Run
- `Docker: Build Image Locally` - Build container locally
- `Docker: Run Local Container` - Test container locally on port 8080

### **Validation Tasks**
- `GCP: Validate Auth & Project` - Check authentication status
- `GCP: Validate Deployment Readiness` - Comprehensive readiness check
- `GCP: Setup Complete Environment` - Initialize Cloud Code integration

### **Monitoring Tasks**
- `Cloud Run: View Logs` - View recent service logs
- `Demo: Run tests` - Execute test suite

## 🐛 Debug Configurations (F5)

- **Cloud Code: Debug on Cloud Run** - Remote debugging on deployed service
- **Cloud Code: Debug Locally** - Local Kubernetes debugging
- **Python: Current File** - Standard Python debugging
- **Python: Pytest All** - Debug test suite

## 🔧 Command Line Tools

### **Quick Deploy**
```bash
# Development environment
skaffold run --profile=dev

# Production environment  
skaffold run --profile=prod

# Development with hot reload
skaffold dev --profile=dev --port-forward
```

### **Cloud Build CI/CD**
```bash
# Submit build to Cloud Build
gcloud builds submit --config cloudbuild.yaml

# View build history
gcloud builds list --limit=10

# View build logs
gcloud builds log <BUILD_ID>
```

### **Docker Local Testing**
```bash
# Build image
docker build -t dominion-demo:latest .

# Run container
docker run -p 8080:8080 -e PORT=8080 dominion-demo:latest

# Access locally
curl http://localhost:8080/health
```

### **Cloud Run Management**
```bash
# Deploy service
gcloud run deploy dominion-demo-service \
  --image gcr.io/dominion-core-prod/dominion-demo:latest \
  --region us-central1 \
  --platform managed

# View logs
gcloud run logs read dominion-demo-service \
  --region us-central1 \
  --limit 50

# Get service URL
gcloud run services describe dominion-demo-service \
  --region us-central1 \
  --format 'value(status.url)'

# List revisions
gcloud run revisions list \
  --service dominion-demo-service \
  --region us-central1
```

## 📊 Optimization Features Enabled

### **Container Optimizations**
- ✅ Multi-stage Docker build (smaller images)
- ✅ Layer caching for faster builds
- ✅ Non-root user for security
- ✅ BuildKit inline cache
- ✅ Optimized .dockerignore (97 excluded patterns)

### **Cloud Run Optimizations**
- ✅ Gen2 execution environment
- ✅ CPU boost enabled (faster cold starts)
- ✅ No CPU throttling (better performance)
- ✅ Autoscaling (1-100 instances)
- ✅ 250 concurrent requests per instance
- ✅ 4Gi memory, 2000m CPU
- ✅ Session affinity enabled
- ✅ Comprehensive health checks

### **Build Optimizations**
- ✅ Parallel builds enabled
- ✅ Build caching (GCR)
- ✅ High-CPU build machines (E2_HIGHCPU_8)
- ✅ Fast build timeout (20-30 min)
- ✅ Cloud logging only (faster)

### **Development Optimizations**
- ✅ Hot reload in dev mode
- ✅ Port forwarding (8080)
- ✅ Real-time log streaming
- ✅ Automatic project detection
- ✅ File sync for Python/YAML/JSON

## 🔐 Security Features

- ✅ Non-root container user
- ✅ Vulnerability scanning enabled
- ✅ Minimal base image (python:3.12-slim)
- ✅ No telemetry data collection
- ✅ Secure environment variables
- ✅ Service account authentication

## 📈 Monitoring & Observability

### **Built-in Health Checks**
- **Startup Probe:** `/health` endpoint, 10s interval
- **Readiness Probe:** `/health` endpoint, 10s interval  
- **Liveness Probe:** `/health` endpoint, 30s interval

### **Logging**
```bash
# Stream logs in real-time
gcloud run logs tail dominion-demo-service --region us-central1

# View logs in VS Code
# Output panel → Cloud Code → Logs
```

### **Metrics**
- Request count and latency
- Instance count and utilization
- Memory and CPU usage
- Error rates

## 🚦 Deployment Workflow

### **Recommended Development Workflow**

1. **Code locally** with auto-save enabled
2. **Run Skaffold Dev Mode** (`Skaffold: Dev Mode` task)
3. **Code syncs automatically** to Cloud Run
4. **Test changes** in real-time
5. **View logs** in VS Code Output panel

### **Production Deployment Workflow**

1. **Commit code** to Git
2. **Run tests** locally or in CI
3. **Submit to Cloud Build** (`Cloud Build: Submit Build` task)
4. **Automated deployment** to Cloud Run
5. **Smoke test** runs automatically
6. **Monitor** via Cloud Console

### **Local Testing Workflow**

1. **Build Docker image** (`Docker: Build Image Locally` task)
2. **Run container** (`Docker: Run Local Container` task)
3. **Test on localhost:8080**
4. **Iterate and rebuild**

## 🎯 Performance Targets

| Metric | Target | Status |
|--------|--------|--------|
| Cold start time | < 2s | ✅ CPU boost enabled |
| Build time | < 5 min | ✅ Caching enabled |
| Deploy time | < 2 min | ✅ Optimized pipeline |
| Container size | < 500MB | ✅ Multi-stage build |
| Max concurrency | 250/instance | ✅ Configured |
| Autoscale range | 1-100 | ✅ Configured |

## 🔗 Useful Links

- **Cloud Console:** https://console.cloud.google.com/run?project=dominion-core-prod
- **Container Registry:** https://console.cloud.google.com/gcr/images/dominion-core-prod
- **Cloud Build:** https://console.cloud.google.com/cloud-build/builds?project=dominion-core-prod
- **Logs Explorer:** https://console.cloud.google.com/logs/query?project=dominion-core-prod

## 💡 Pro Tips

1. **Use dev profile** for rapid iteration with hot reload
2. **Use prod profile** for production-like testing
3. **Use local profile** for offline development
4. **Enable port forwarding** to test deployed services locally
5. **Stream logs** in dev mode to see real-time output
6. **Tag images** with commit SHA for easy rollback
7. **Monitor build cache** to ensure cache is working
8. **Use Cloud Build** for consistent CI/CD

## 🆘 Troubleshooting

### **Build fails**
```bash
# Check Docker build locally
docker build -t test .

# Check .dockerignore patterns
cat .dockerignore
```

### **Deploy fails**
```bash
# Validate auth
gcloud auth list

# Check project access
gcloud projects describe dominion-core-prod

# Verify APIs enabled
gcloud services list --enabled
```

### **Service not responding**
```bash
# Check service status
gcloud run services describe dominion-demo-service --region us-central1

# Check logs
gcloud run logs read dominion-demo-service --region us-central1 --limit 100
```

### **Skaffold issues**
```bash
# Check Skaffold config
skaffold diagnose

# Run with verbose logging
skaffold run -v debug
```

## 📝 Environment Variables

Auto-configured in terminal:
- `GOOGLE_CLOUD_PROJECT=dominion-core-prod`
- `GOOGLE_CLOUD_REGION=us-central1`
- `SKAFFOLD_DEFAULT_REPO=gcr.io/dominion-core-prod`
- `CLOUDCODE_TELEMETRY_OPTOUT=true`
- `DOCKER_BUILDKIT=1`

## ✅ Deployment Checklist

Before final push:
- [ ] All tests passing
- [ ] Local Docker build successful
- [ ] Skaffold dev mode working
- [ ] GCP authentication valid
- [ ] Project access confirmed
- [ ] Required APIs enabled
- [ ] Health endpoints working
- [ ] Environment variables set
- [ ] Logs accessible
- [ ] Network connectivity confirmed

---

**Status:** ✅ All optimizations applied  
**Last Updated:** 2026-02-28  
**Configuration Version:** 1.0.0  
**Ready for:** Continuous Deployment

**Quick Start:** `Ctrl+Shift+P` → `Tasks: Run Task` → `GCP: Validate Deployment Readiness`
