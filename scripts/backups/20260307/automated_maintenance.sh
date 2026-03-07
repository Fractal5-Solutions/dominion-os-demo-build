#!/bin/bash

# PHI Automated Maintenance Script
# Runs comprehensive maintenance daily to maintain optimal state

echo "=========================================="
echo "PHI AUTOMATED MAINTENANCE - $(date)"
echo "=========================================="

cd /workspaces/dominion-os-demo-build/scripts
source .venv/bin/activate

# Run comprehensive maintenance
./phi_optimal_maintenance_plan.sh

# Verify all services are still running
./phi_status.sh > logs/automated_maintenance_$(date +%Y%m%d).log

echo "=========================================="
echo "MAINTENANCE COMPLETE - $(date)"
echo "=========================================="