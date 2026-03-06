# GCR Permission Blocker - Requires Admin Action

## Status
**BLOCKER**: Image builds failing for development services

## Issue
Cloud Build can create Docker images successfully but cannot push to Google Container Registry (GCR).

### Error
```
denied: Permission 'artifactregistry.repositories.uploadArtifacts' denied on resource
ERROR: retry budget exhausted (10 attempts): step exited with non-zero status: 1
```

### Affected Services
- `phi-oauth-server` (dominion-os-1-0-main)
- `phi-askphi-widget` (dominion-os-1-0-main)

## Required Fix
**Admin/Owner must grant Cloud Build service account GCR upload permissions:**

```bash
# Get project number
PROJECT_NUMBER=$(gcloud projects describe dominion-os-1-0-main --format='value(projectNumber)')

# Grant permissions
gcloud projects add-iam-policy-binding dominion-os-1-0-main \
  --member="serviceAccount:${PROJECT_NUMBER}@cloudbuild.gserviceaccount.com" \
  --role="roles/artifactregistry.writer"
```

## Impact
- Production OAuth server: IAM permissions fixed, awaiting redeploy ⏳
- Development services: Cannot deploy until images are built ❌
- Current health: 89% (25/28 services operational)
- Target health: 100%

## Workaround
Production OAuth can be fixed without new images by redeploying existing image with updated IAM bindings.

## Timestamp
2026-03-06T19:37:00+00:00

## Continuous Drive Status
PHI Continuous Drive is active and monitoring. Will automatically proceed once permissions are granted.
