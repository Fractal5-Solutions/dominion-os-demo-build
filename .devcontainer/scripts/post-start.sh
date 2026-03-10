#!/bin/bash
###############################################################################
# Dev Container Post-Start Script
# Runs every time the container starts (including after stop/start)
###############################################################################

set -e

echo "🔄 PHI Dev Container - Post Start"
echo "=================================="

cd /workspaces/dominion-os-demo-build

# Check for existing sovereign processes (in case of restart)
echo "Checking for existing PHI sovereign processes..."

# Check if autonomous mode flag exists
if [ -f "/tmp/phi_autonomous_mode.flag" ]; then
    echo "🤖 Autonomous mode detected - checking sovereign processes..."
    
    # Restart sovereign keepalive if it was running
    if [ -f "scripts/phi_sovereign_keepalive.sh" ] && [ ! -f "/tmp/.stop-nhitl-loop" ]; then
        echo "Restarting sovereign keepalive..."
        nohup bash scripts/phi_sovereign_keepalive.sh > scripts/logs/sovereign_keepalive.log 2>&1 &
    fi
fi

# Clean up stale PID files
echo "Cleaning stale process files..."
find scripts/logs -name "*.pid" -type f 2>/dev/null | while read pidfile; do
    if [ -f "$pidfile" ]; then
        pid=$(cat "$pidfile")
        if ! ps -p "$pid" > /dev/null 2>&1; then
            rm "$pidfile"
        fi
    fi
done

# Update telemetry status
echo "Updating system status..."
cat > scripts/telemetry/container_status.json << EOF
{
  "timestamp": "$(date -Iseconds)",
  "event": "container_start",
  "mode": "${PHI_MODE:-development}",
  "sovereignty_level": "${PHI_SOVEREIGNTY_LEVEL:-9/9}",
  "workspace": "/workspaces/dominion-os-demo-build"
}
EOF

echo "✅ Post-start complete - container ready!"
