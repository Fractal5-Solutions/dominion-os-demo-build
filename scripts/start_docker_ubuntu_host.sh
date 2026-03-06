#!/bin/bash
# PHI Docker Startup - Ubuntu AT2 Host
# Run this script ON YOUR AT2 UBUNTU HOST (not in dev container)

echo "════════════════════════════════════════════════════════════"
echo "  🐳 Starting Docker on Ubuntu AT2 Host"
echo "════════════════════════════════════════════════════════════"
echo ""

# Check if Docker is installed
if ! command -v docker &> /dev/null; then
    echo "❌ Docker is not installed on this Ubuntu host!"
    echo ""
    echo "Install Docker with:"
    echo "  curl -fsSL https://get.docker.com -o get-docker.sh"
    echo "  sudo sh get-docker.sh"
    exit 1
fi

echo "✅ Docker is installed: $(docker --version)"
echo ""

# Start Docker daemon
echo "🚀 Starting Docker daemon..."
sudo systemctl start docker

# Wait a moment for startup
sleep 2

# Check status
echo ""
echo "📊 Docker daemon status:"
sudo systemctl status docker --no-pager | head -10
echo ""

# Enable Docker at boot (recommended)
echo "⚙️  Enabling Docker to start at boot..."
sudo systemctl enable docker
echo ""

# Test Docker
echo "🧪 Testing Docker..."
if sudo docker ps > /dev/null 2>&1; then
    echo "✅ Docker is RUNNING and accessible!"
    echo ""
    sudo docker ps
    echo ""
    echo "════════════════════════════════════════════════════════════"
    echo "  ✨ SUCCESS! Docker is now running on AT2 Ubuntu host"
    echo "════════════════════════════════════════════════════════════"
    echo ""
    echo "The socket will be forwarded into your dev container."
    echo "Wait 10-20 seconds, then return to your dev container and"
    echo "PHI will automatically detect Docker and start all services!"
    echo ""
else
    echo "❌ Docker started but not responding properly"
    echo ""
    echo "Check logs with:"
    echo "  sudo journalctl -u docker -n 50"
    exit 1
fi
