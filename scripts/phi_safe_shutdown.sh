#!/bin/bash
# Safe shutdown of PHI system

echo "🛑 Initiating safe PHI system shutdown..."

# Gracefully stop background processes
echo "  Stopping background processes..."
pkill -f "phi_background_completion_monitor" 2>/dev/null || true
pkill -f "phi_cost_minimization_simple" 2>/dev/null || true
pkill -f "autonomous_overnight" 2>/dev/null || true

# Give processes time to clean up
sleep 2

# Stop web services
echo "  Stopping web services..."
pkill -f "python3 app.py" 2>/dev/null || true
pkill -f "oauth_server" 2>/dev/null || true

sleep 1

echo "✅ PHI system shutdown complete"
echo "ℹ️  To restart: bash scripts/phi_start_all_systems.sh"
