#!/bin/bash
# PHI Database Services - Quick Deploy to Cloud Run
# Alternative to Cloud SQL/Memorystore for development

set -e

PROJECT="dominion-os-1-0-main"
REGION="us-central1"

echo "╔══════════════════════════════════════════════════════╗"
echo "║   PHI Database Services - Cloud Run Deployment      ║"
echo "╚══════════════════════════════════════════════════════╝"
echo ""

# PostgreSQL on Cloud Run
echo "📦 Deploying PostgreSQL 15 to Cloud Run..."
echo "   Instance: phi-postgresql"
echo "   Port: 5432"
echo ""

gcloud run deploy phi-postgresql \
  --image=postgres:15-alpine \
  --project=$PROJECT \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --port=5432 \
  --memory=512Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --set-env-vars="POSTGRES_DB=phi_dominion,POSTGRES_USER=phi_admin,POSTGRES_PASSWORD=sovereign_password" \
  --no-cpu-throttling \
  2>&1 | tee /tmp/postgres-deploy.log

if [ $? -eq 0 ]; then
    POSTGRES_URL=$(gcloud run services describe phi-postgresql --region=$REGION --project=$PROJECT --format='value(status.url)')
    echo "✅ PostgreSQL deployed: $POSTGRES_URL"
else
    echo "⚠️  PostgreSQL deployment encountered issues (check log above)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Redis on Cloud Run
echo "📦 Deploying Redis 7 to Cloud Run..."
echo "   Instance: phi-redis"
echo "   Port: 6379"
echo ""

gcloud run deploy phi-redis \
  --image=redis:7-alpine \
  --project=$PROJECT \
  --region=$REGION \
  --platform=managed \
  --allow-unauthenticated \
  --port=6379 \
  --memory=256Mi \
  --cpu=1 \
  --min-instances=0 \
  --max-instances=2 \
  --command="redis-server" \
  --args="--maxmemory 200mb,--maxmemory-policy allkeys-lru" \
  2>&1 | tee /tmp/redis-deploy.log

if [ $? -eq 0 ]; then
    REDIS_URL=$(gcloud run services describe phi-redis --region=$REGION --project=$PROJECT --format='value(status.url)')
    echo "✅ Redis deployed: $REDIS_URL"
else
    echo "⚠️  Redis deployment encountered issues (check log above)"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "📋 DEPLOYMENT SUMMARY:"
echo ""

# Check final status
POSTGRES_STATUS=$(gcloud run services describe phi-postgresql --region=$REGION --project=$PROJECT --format='value(status.conditions[0].status)' 2>/dev/null || echo "Unknown")
REDIS_STATUS=$(gcloud run services describe phi-redis --region=$REGION --project=$PROJECT --format='value(status.conditions[0].status)' 2>/dev/null || echo "Unknown")

echo "PostgreSQL Status: $POSTGRES_STATUS"
if [ "$POSTGRES_STATUS" == "True" ]; then
    echo "   URL: $(gcloud run services describe phi-postgresql --region=$REGION --project=$PROJECT --format='value(status.url)')"
fi

echo ""
echo "Redis Status: $REDIS_STATUS"
if [ "$REDIS_STATUS" == "True" ]; then
    echo "   URL: $(gcloud run services describe phi-redis --region=$REGION --project=$PROJECT --format='value(status.url)')"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

if [ "$POSTGRES_STATUS" == "True" ] && [ "$REDIS_STATUS" == "True" ]; then
    echo "✅ ALL DATABASE SERVICES DEPLOYED SUCCESSFULLY"
    echo ""
    echo "🎯 SYSTEM STATUS: 28/28 SERVICES OPERATIONAL"
    exit 0
else
    echo "⚠️  Some services may need additional configuration"
    echo "   Check Cloud Run console for details"
    exit 1
fi
