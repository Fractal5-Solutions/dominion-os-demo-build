#!/bin/bash
# PHI Codespace Rebuild Monitor
# Monitors the rebuild process and verifies Docker availability

echo "╔══════════════════════════════════════════════════════════════════╗"
echo "║         PHI CODESPACE REBUILD & DOCKER MONITOR                  ║"
echo "╚══════════════════════════════════════════════════════════════════╝"
echo ""

# Function to check Docker availability
check_docker() {
    if docker info &>/dev/null; then
        return 0
    else
        return 1
    fi
}

# Function to check if dockerd is running
check_dockerd() {
    if pgrep -f dockerd &>/dev/null; then
        return 0
    else
        return 1
    fi
}

echo "📋 Pre-Rebuild Status:"
echo "   • Timestamp: $(date '+%Y-%m-%d %H:%M:%S')"
echo "   • Codespace: ${CODESPACE_NAME:-unknown}"
echo "   • Current Image: $(cat /etc/alpine-release 2>/dev/null || echo 'unknown')"
echo ""

if check_docker; then
    echo "   ✅ Docker: OPERATIONAL"
    docker version --format '      Client: {{.Client.Version}}, Server: {{.Server.Version}}'
else
    echo "   ❌ Docker: NOT AVAILABLE"
    if [ -e /var/run/docker.sock ]; then
        echo "      Socket exists but no daemon"
    fi
fi
echo ""

echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔄 REBUILD INSTRUCTIONS:"
echo ""
echo "   1. Press: Ctrl+Shift+P (or ⌘+Shift+P on Mac)"
echo "   2. Type: Codespaces: Rebuild Container"
echo "   3. Press: Enter to confirm"
echo ""
echo "   ⏱️  Rebuild will take approximately 3-5 minutes"
echo "   🔧 New features being installed:"
echo "      • Docker-in-Docker (moby + docker-compose v2)"
echo "      • Python 3.11"
echo "      • Google Cloud CLI"
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Wait for user to initiate rebuild
echo "⏸️  Waiting for rebuild to start..."
echo "   (This script will detect when the environment changes)"
echo ""

# Monitor loop - checks every 5 seconds
INITIAL_BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown")
WAIT_COUNT=0
MAX_WAIT=360  # 30 minutes max

while [ $WAIT_COUNT -lt $MAX_WAIT ]; do
    CURRENT_BOOT_ID=$(cat /proc/sys/kernel/random/boot_id 2>/dev/null || echo "unknown")
    
    # Check if environment has been rebuilt (boot_id changes or Docker becomes available)
    if [ "$INITIAL_BOOT_ID" != "$CURRENT_BOOT_ID" ] || check_docker; then
        echo ""
        echo "🔄 Environment change detected!"
        break
    fi
    
    # Visual progress indicator
    if [ $((WAIT_COUNT % 12)) -eq 0 ]; then
        MINS=$((WAIT_COUNT / 12))
        echo "   ⏱️  Waiting ${MINS}m... (Press Ctrl+C if rebuild already started in another terminal)"
    fi
    
    sleep 5
    WAIT_COUNT=$((WAIT_COUNT + 1))
done

# Give the system a moment to stabilize after rebuild
sleep 3

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""
echo "🔍 POST-REBUILD VERIFICATION:"
echo ""

# Check dockerd process
echo "1️⃣  Checking Docker daemon..."
if check_dockerd; then
    DOCKERD_PID=$(pgrep -f dockerd)
    echo "   ✅ dockerd running (PID: $DOCKERD_PID)"
else
    echo "   ❌ dockerd not found"
    echo "      Attempting to start Docker daemon..."
    
    # Try to start Docker if it's not running
    if command -v systemctl &>/dev/null; then
        sudo systemctl start docker 2>/dev/null && echo "   ✅ Started via systemctl"
    elif command -v service &>/dev/null; then
        sudo service docker start 2>/dev/null && echo "   ✅ Started via service"
    fi
    sleep 2
fi

# Check Docker client connectivity
echo ""
echo "2️⃣  Checking Docker client connectivity..."
if check_docker; then
    echo "   ✅ Docker client can connect to daemon"
    docker version --format '      Client: {{.Client.Version}}'
    docker version --format '      Server: {{.Server.Version}}'
else
    echo "   ❌ Docker client cannot connect"
    echo "      This may resolve after a few more seconds..."
fi

# Check Docker socket
echo ""
echo "3️⃣  Checking Docker socket..."
if [ -S /var/run/docker.sock ]; then
    SOCKET_PERMS=$(ls -l /var/run/docker.sock | awk '{print $1, $3, $4}')
    echo "   ✅ Socket exists: $SOCKET_PERMS"
else
    echo "   ❌ Socket not found at /var/run/docker.sock"
fi

# Test Docker functionality
echo ""
echo "4️⃣  Testing Docker functionality..."
if docker ps &>/dev/null; then
    echo "   ✅ Docker ps command successful"
    CONTAINER_COUNT=$(docker ps -q | wc -l)
    echo "      Running containers: $CONTAINER_COUNT"
else
    echo "   ⚠️  Docker ps command failed (daemon may still be initializing)"
fi

# Check Python environment
echo ""
echo "5️⃣  Checking Python environment..."
if command -v python3 &>/dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    echo "   ✅ Python ${PYTHON_VERSION} available"
else
    echo "   ⚠️  Python not found in PATH"
fi

# Check gcloud CLI
echo ""
echo "6️⃣  Checking Google Cloud CLI..."
if command -v gcloud &>/dev/null; then
    GCLOUD_VERSION=$(gcloud version --format='value(core)' 2>/dev/null || echo "installed")
    echo "   ✅ gcloud CLI ${GCLOUD_VERSION} available"
else
    echo "   ⚠️  gcloud not found in PATH"
fi

echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo ""

# Final Docker verification
if check_docker; then
    echo "✅ REBUILD SUCCESSFUL - Docker is operational!"
    echo ""
    echo "📋 Next Steps:"
    echo "   1. Run: cd /workspaces/dominion-os-demo-build/scripts"
    echo "   2. Run: ./start_all_local_systems.sh"
    echo "   3. Verify all 28 services operational"
    echo ""
    echo "🎯 Expected Services After Start:"
    echo "   • PHI MCP Server (port 8000) - Should already be running"
    echo "   • PHI OAuth Server (port 8080) - Starting via Docker Compose"
    echo "   • PHI AskPhi Widget (port 8081) - Starting via Docker Compose"
    echo "   • PostgreSQL 15 (port 5432) - Starting via Docker Compose"
    echo "   • Redis 7 (port 6379) - Starting via Docker Compose"
    echo "   • Prometheus (port 9090) - Starting via Docker Compose"
    echo "   • Grafana (port 3000) - Starting via Docker Compose"
    echo "   • 24 GCP Services - Already operational"
    echo ""
    exit 0
else
    echo "⚠️  DOCKER NOT YET AVAILABLE"
    echo ""
    echo "This can happen if:"
    echo "   • Rebuild is still in progress"
    echo "   • Docker daemon is still initializing"
    echo "   • Manual Docker start is needed"
    echo ""
    echo "🔧 Troubleshooting:"
    echo "   1. Wait 30 seconds and run: docker info"
    echo "   2. If still failing, try: sudo systemctl start docker"
    echo "   3. Check logs: journalctl -u docker --no-pager | tail -50"
    echo "   4. Re-run this monitor: ./phi_rebuild_monitor.sh"
    echo ""
    exit 1
fi
