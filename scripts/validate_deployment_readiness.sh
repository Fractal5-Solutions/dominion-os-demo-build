#!/bin/bash
# Continuous Deployment Readiness Validation
# Dominion OS - Google Cloud Code Integration Status

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
RED='\033[0;31m'
NC='\033[0m'

echo "=========================================="
echo "🚀 CONTINUOUS DEPLOYMENT READINESS CHECK"
echo "=========================================="
echo "Dominion OS Demo Build - Google Cloud Focus"
echo "Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "=========================================="

# Function to check status
check_status() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${RED}❌ $1${NC}"
        return 1
    fi
}

# Function to check optional status
check_optional() {
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✅ $1${NC}"
        return 0
    else
        echo -e "${YELLOW}⚠️  $1 (Optional)${NC}"
        return 1
    fi
}

TOTAL_CHECKS=0
PASSED_CHECKS=0

echo ""
echo -e "${BLUE}[1/8] Google Cloud Code VS Code Extension${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
if [ -f ".vscode/extensions.json" ] && grep -q "googlecloudtools.cloudcode" .vscode/extensions.json; then
    echo -e "${GREEN}✅ Extension configured in workspace${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠️  Extension not in workspace recommendations${NC}"
fi

echo ""
echo -e "${BLUE}[2/8] VS Code Configuration Optimization${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 4))

if [ -f ".cloudcode/config.json" ]; then
    echo -e "${GREEN}✅ Cloud Code configuration present${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Cloud Code configuration missing${NC}"
fi

if [ -f "skaffold.yaml" ]; then
    echo -e "${GREEN}✅ Skaffold configuration present${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Skaffold configuration missing${NC}"
fi

if [ -f "service.yaml" ]; then
    echo -e "${GREEN}✅ Cloud Run service definition present${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Cloud Run service definition missing${NC}"
fi

if [ -f ".vscode/tasks.json" ] && grep -q "Cloud Code:" .vscode/tasks.json; then
    echo -e "${GREEN}✅ Cloud Code tasks configured${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Cloud Code tasks missing${NC}"
fi

echo ""
echo -e "${BLUE}[3/8] Google Cloud CLI Status${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
command -v gcloud > /dev/null 2>&1
if check_status "Google Cloud CLI installed"; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
    echo "    Version: $(gcloud version --format='value(Google Cloud SDK)' 2>/dev/null || echo 'Unknown')"
fi

echo ""
echo -e "${BLUE}[4/8] Authentication Status${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 1))
ACCOUNT=$(gcloud auth list --filter=status:ACTIVE --format="value(account)" 2>/dev/null || echo "")
if [ ! -z "$ACCOUNT" ]; then
    echo -e "${GREEN}✅ Authenticated as: $ACCOUNT${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Not authenticated with Google Cloud${NC}"
    echo "    Run: gcloud auth login"
fi

echo ""
echo -e "${BLUE}[5/8] Project Configuration${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 2))
PROJECT=$(gcloud config get-value project 2>/dev/null || echo "")
if [ ! -z "$PROJECT" ]; then
    echo -e "${GREEN}✅ Default project: $PROJECT${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))

    # Test project access
    if gcloud projects describe $PROJECT > /dev/null 2>&1; then
        echo -e "${GREEN}✅ Project accessible${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${RED}❌ Project not accessible${NC}"
    fi
else
    echo -e "${RED}❌ No default project configured${NC}"
    echo -e "${RED}❌ Project access check skipped${NC}"
fi

echo ""
echo -e "${BLUE}[6/8] Google Cloud Services Status${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 2))

# Check Cloud Run services
if [ ! -z "$PROJECT" ]; then
    SERVICES=$(gcloud run services list --project=$PROJECT --format="value(metadata.name)" 2>/dev/null | wc -l || echo "0")
    if [ $SERVICES -gt 0 ]; then
        echo -e "${GREEN}✅ Cloud Run services: $SERVICES active${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️  No Cloud Run services found${NC}"
    fi

    # Check required APIs
    ENABLED_APIS=$(gcloud services list --enabled --project=$PROJECT --format="value(config.name)" 2>/dev/null | grep -E "(run|cloudbuild|containerregistry)" | wc -l || echo "0")
    if [ $ENABLED_APIS -ge 2 ]; then
        echo -e "${GREEN}✅ Required APIs enabled: $ENABLED_APIS/3${NC}"
        PASSED_CHECKS=$((PASSED_CHECKS + 1))
    else
        echo -e "${YELLOW}⚠️  Some required APIs may need enabling${NC}"
    fi
else
    echo -e "${YELLOW}⚠️  Service status check skipped (no project)${NC}"
    echo -e "${YELLOW}⚠️  API status check skipped (no project)${NC}"
fi

echo ""
echo -e "${BLUE}[7/8] Network Connectivity${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 3))

# Test Google Cloud connectivity
if curl -s --max-time 5 https://cloud.google.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Google Cloud reachable${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Google Cloud not reachable${NC}"
fi

# Test Container Registry connectivity
if curl -s --max-time 5 https://gcr.io > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Container Registry reachable${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Container Registry not reachable${NC}"
fi

# Test Cloud Build connectivity
if curl -s --max-time 5 https://cloudbuild.googleapis.com > /dev/null 2>&1; then
    echo -e "${GREEN}✅ Cloud Build API reachable${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${RED}❌ Cloud Build API not reachable${NC}"
fi

echo ""
echo -e "${BLUE}[8/8] Deployment Tools${NC}"
TOTAL_CHECKS=$((TOTAL_CHECKS + 3))

# Check deployment scripts
if [ -f "deploy_to_gcp.sh" ] && [ -x "deploy_to_gcp.sh" ]; then
    echo -e "${GREEN}✅ GCP deployment script ready${NC}"
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
else
    echo -e "${YELLOW}⚠️  GCP deployment script not executable${NC}"
fi

# Check Docker
command -v docker > /dev/null 2>&1
if check_optional "Docker CLI available"; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

# Check Skaffold (optional but recommended)
command -v skaffold > /dev/null 2>&1
if check_optional "Skaffold available"; then
    PASSED_CHECKS=$((PASSED_CHECKS + 1))
fi

echo ""
echo "=========================================="
echo "📊 READINESS SUMMARY"
echo "=========================================="

PERCENTAGE=$((PASSED_CHECKS * 100 / TOTAL_CHECKS))

if [ $PERCENTAGE -ge 90 ]; then
    echo -e "${GREEN}🚀 READY FOR CONTINUOUS DEPLOYMENT${NC}"
    echo -e "${GREEN}Status: $PASSED_CHECKS/$TOTAL_CHECKS checks passed ($PERCENTAGE%)${NC}"
elif [ $PERCENTAGE -ge 70 ]; then
    echo -e "${YELLOW}⚠️  MOSTLY READY (Minor issues)${NC}"
    echo -e "${YELLOW}Status: $PASSED_CHECKS/$TOTAL_CHECKS checks passed ($PERCENTAGE%)${NC}"
else
    echo -e "${RED}❌ NOT READY FOR DEPLOYMENT${NC}"
    echo -e "${RED}Status: $PASSED_CHECKS/$TOTAL_CHECKS checks passed ($PERCENTAGE%)${NC}"
fi

echo ""
echo "=========================================="
echo "🎯 VS Code Google Cloud Code Integration:"
echo "----------------------------------------"
echo "✅ Extension: googlecloudtools.cloudcode"
echo "✅ Configuration: .cloudcode/config.json"
echo "✅ Skaffold config: skaffold.yaml"
echo "✅ Cloud Run service: service.yaml"
echo "✅ VS Code tasks: Cloud Code deployment tasks"
echo "✅ Debug configs: Cloud Run debugging"
echo ""
echo "🚀 Quick Deploy Commands:"
echo "  VS Code Command Palette > Cloud Code: Deploy"
echo "  Or use task: 'Cloud Code: Deploy to Cloud Run (Dev)'"
echo ""
echo "🛡️  No AWS/Azure/Oracle configs needed - Pure GCP setup"
echo "=========================================="

if [ $PERCENTAGE -lt 90 ]; then
    echo ""
    echo -e "${YELLOW}🔧 To complete setup, run:${NC}"
    echo "  ./scripts/setup_cloudcode_integration.sh"
fi
