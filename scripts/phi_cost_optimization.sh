#!/bin/bash
# PHI Chief Autonomous Cost Optimization Script
# Target: $50-100/month savings through rightsizing over-provisioned services
# Execution: Autonomous NHITL operations under PHI sovereignty

set -e

echo "⚡ PHI CHIEF AUTONOMOUS COST OPTIMIZATION"
echo "========================================"
echo "Target: \$50-100/month savings through service rightsizing"
echo "Execution: NHITL autonomous operations"
echo "Timestamp: $(date)"
echo ""

# Function to update service memory
update_memory() {
    local project=$1
    local service=$2
    local memory=$3
    local region=${4:-us-central1}

    echo "🔧 Updating $service in $project to $memory memory..."
    gcloud run services update $service \
        --project $project \
        --region $region \
        --memory $memory \
        --quiet
    echo "✅ $service updated to $memory"
    echo ""
}

# Function to update service CPU
update_cpu() {
    local project=$1
    local service=$2
    local cpu=$3
    local region=${4:-us-central1}

    echo "🔧 Updating $service in $project to $cpu CPU..."
    gcloud run services update $service \
        --project $project \
        --region $region \
        --cpu $cpu \
        --quiet
    echo "✅ $service updated to $cpu CPU"
    echo ""
}

echo "🎯 PHASE 1: P1 PROJECT OPTIMIZATION (dominion-os-1-0-main)"
echo "========================================================="

# P1 Optimizations - High impact services
update_memory "dominion-os-1-0-main" "dominion-ai-gateway" "2Gi"  # 4Gi → 2Gi (50% reduction)
update_memory "dominion-os-1-0-main" "dominion-monitoring-dashboard" "1Gi"  # 2Gi → 1Gi (50% reduction)

echo "🎯 PHASE 2: P2 PROJECT OPTIMIZATION (dominion-core-prod)"
echo "======================================================="

# P2 Optimizations - Core services
update_memory "dominion-core-prod" "dominion-ai-gateway" "1Gi"  # 2Gi → 1Gi (50% reduction)
update_memory "dominion-core-prod" "dominion-os-1-0-101" "1Gi"  # 2Gi → 1Gi (50% reduction)
update_memory "dominion-core-prod" "dominion-os" "512Mi"  # 1Gi → 512Mi (50% reduction)
update_cpu "dominion-core-prod" "dominion-os" "1"  # 2 CPU → 1 CPU (50% reduction)

echo "📊 COST OPTIMIZATION COMPLETE"
echo "============================"
echo "Services Rightsized:"
echo "• P1 dominion-ai-gateway: 4Gi → 2Gi"
echo "• P1 dominion-monitoring-dashboard: 2Gi → 1Gi"
echo "• P2 dominion-ai-gateway: 2Gi → 1Gi"
echo "• P2 dominion-os-1-0-101: 2Gi → 1Gi"
echo "• P2 dominion-os: 1Gi+2CPU → 512Mi+1CPU"
echo ""
echo "💰 Estimated Monthly Savings: \$50-100"
echo "⚡ PHI Chief Autonomous Execution: Complete"
echo "🔐 Sovereignty Status: Maximum autonomous control maintained"
echo ""

# Verification
echo "🔍 VERIFICATION: Current Service Configurations"
echo "=============================================="
echo "P1 Services (dominion-os-1-0-main):"
gcloud run services list --project dominion-os-1-0-main --region us-central1 \
    --format "table(name,spec.template.spec.containers[0].resources.limits.memory,spec.template.spec.containers[0].resources.limits.cpu)"

echo ""
echo "P2 Services (dominion-core-prod):"
gcloud run services list --project dominion-core-prod --region us-central1 \
    --format "table(name,spec.template.spec.containers[0].resources.limits.memory,spec.template.spec.containers[0].resources.limits.cpu)"

echo ""
echo "✅ PHI CHIEF COST OPTIMIZATION: MISSION ACCOMPLISHED"
echo "Timestamp: $(date)"
