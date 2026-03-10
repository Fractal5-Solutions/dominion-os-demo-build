#!/bin/bash
###############################################################################
# Dev Container Post-Attach Script
# Runs when VS Code attaches to the container (user opens workspace)
###############################################################################

echo "👤 VS Code Attached - Welcome to Dominion OS!"
echo "=============================================="

cd /workspaces/dominion-os-demo-build

# Activate virtual environment
if [ -f ".venv/bin/activate" ]; then
    source .venv/bin/activate
fi

# Display current PHI status
if [ -f "scripts/phi_status.sh" ]; then
    echo ""
    echo "📊 Current PHI System Status:"
    echo "=============================="
    bash scripts/phi_status.sh
fi

# Show helpful commands
echo ""
echo "🎯 Quick Commands:"
echo "=================="
echo "  Start all services:  bash scripts/phi_quick_start.sh"
echo "  System status:       bash scripts/phi_status.sh"
echo "  Safe shutdown:       bash scripts/phi_safe_shutdown.sh"
echo "  Activate max mode:   bash activate_max_sovereign_mode.sh"
echo ""

# Check for important notifications
if [ -f "scripts/telemetry/sovereign_status.json" ]; then
    echo "📡 Sovereign Status:"
    jq -r '"  Mode: \(.mode) | Level: \(.sovereignty_level) | Status: \(.status)"' scripts/telemetry/sovereign_status.json 2>/dev/null || true
    echo ""
fi

echo "✅ Ready for development!"
echo ""
