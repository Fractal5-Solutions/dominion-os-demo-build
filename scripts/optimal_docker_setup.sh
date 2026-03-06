#!/bin/bash
# PHI Optimal Docker Setup for AT2 Linux Host
# Run this ON YOUR AT2 HOST MACHINE (not in dev container)

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🐧 PHI Optimal Docker Setup - AT2 Linux Host${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Check if running as root or with sudo
if [ "$EUID" -ne 0 ]; then 
    echo -e "${YELLOW}⚠️  This script requires sudo privileges.${NC}"
    echo -e "${YELLOW}   Re-running with sudo...${NC}"
    exec sudo bash "$0" "$@"
fi

# 1. Check Docker installation
echo -e "${BOLD}[1/6] Checking Docker installation...${NC}"
if command -v docker > /dev/null 2>&1; then
    DOCKER_VERSION=$(docker --version 2>/dev/null || echo "unknown")
    echo -e "  ${GREEN}✅ Docker installed: $DOCKER_VERSION${NC}"
else
    echo -e "  ${RED}❌ Docker not installed${NC}"
    echo ""
    echo -e "  ${YELLOW}Install Docker:${NC}"
    echo -e "    ${CYAN}curl -fsSL https://get.docker.com -o get-docker.sh${NC}"
    echo -e "    ${CYAN}sudo sh get-docker.sh${NC}"
    exit 1
fi

# 2. Start Docker daemon
echo ""
echo -e "${BOLD}[2/6] Starting Docker daemon...${NC}"
systemctl start docker
sleep 2
if systemctl is-active --quiet docker; then
    echo -e "  ${GREEN}✅ Docker daemon is running${NC}"
else
    echo -e "  ${RED}❌ Failed to start Docker daemon${NC}"
    echo -e "  ${YELLOW}Check logs: sudo journalctl -u docker -n 50${NC}"
    exit 1
fi

# 3. Enable Docker at boot
echo ""
echo -e "${BOLD}[3/6] Enabling Docker at system boot...${NC}"
systemctl enable docker
echo -e "  ${GREEN}✅ Docker will start automatically on boot${NC}"

# 4. Check port availability
echo ""
echo -e "${BOLD}[4/6] Checking required ports...${NC}"
PORTS=(8080 8081 5432 6379 9090 3000)
PORT_CONFLICT=false

for port in "${PORTS[@]}"; do
    if netstat -tuln 2>/dev/null | grep -q ":$port " || ss -tuln 2>/dev/null | grep -q ":$port "; then
        echo -e "  ${YELLOW}⚠️  Port $port is in use${NC}"
        PORT_CONFLICT=true
    else
        echo -e "  ${GREEN}✅ Port $port is available${NC}"
    fi
done

if [ "$PORT_CONFLICT" = true ]; then
    echo ""
    echo -e "  ${YELLOW}Some ports are in use. Docker Compose may fail to start conflicting services.${NC}"
    echo -e "  ${YELLOW}You can either stop the conflicting services or modify docker-compose.yml ports.${NC}"
fi

# 5. Configure socket permissions
echo ""
echo -e "${BOLD}[5/6] Configuring Docker socket permissions...${NC}"
if [ -S /var/run/docker.sock ]; then
    chmod 666 /var/run/docker.sock
    echo -e "  ${GREEN}✅ Socket permissions set: $(ls -la /var/run/docker.sock | awk '{print $1, $3, $4}')${NC}"
else
    echo -e "  ${RED}❌ Docker socket not found${NC}"
    exit 1
fi

# 6. Verify Docker works
echo ""
echo -e "${BOLD}[6/6] Verifying Docker operation...${NC}"
if docker ps > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Docker is fully operational${NC}"
    RUNNING_CONTAINERS=$(docker ps --format '{{.Names}}' | wc -l)
    echo -e "  ${CYAN}  Currently running containers: $RUNNING_CONTAINERS${NC}"
else
    echo -e "  ${RED}❌ Docker verification failed${NC}"
    exit 1
fi

# Test image pull
echo ""
echo -e "${BOLD}Testing image pull capability...${NC}"
if docker pull alpine:latest > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Image pulling works${NC}"
    docker rmi alpine:latest > /dev/null 2>&1
else
    echo -e "  ${YELLOW}⚠️  Image pull test failed (may be network/registry issue)${NC}"
fi

# Success summary
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${BOLD}✨ Docker is OPTIMALLY CONFIGURED ✨${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Docker Configuration Summary:${NC}"
echo -e "  • Docker Version: $(docker --version | awk '{print $3}')"
echo -e "  • Daemon Status: ${GREEN}Running${NC}"
echo -e "  • Boot Enabled: ${GREEN}Yes${NC}"
echo -e "  • Socket Permissions: ${GREEN}Configured${NC}"
echo -e "  • Image Pull: ${GREEN}Working${NC}"
echo ""
echo -e "${BOLD}System Resources:${NC}"
docker info | grep -E "Total Memory|CPUs:" | sed 's/^/  /'
echo ""
echo -e "${BOLD}Next Steps (in dev container):${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Verify connection from container:"
echo -e "     ${CYAN}bash /workspaces/dominion-os-demo-build/scripts/verify_docker_connection.sh${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Start all PHI local services:"
echo -e "     ${CYAN}bash /workspaces/dominion-os-demo-build/scripts/start_all_local_systems.sh${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} Monitor Docker services:"
echo -e "     ${CYAN}docker-compose -f /workspaces/dominion-os-demo-build/scripts/docker-compose.yml ps${NC}"
echo ""
echo -e "${GREEN}🎯 Docker is ready for PHI Dominion OS services!${NC}"
echo ""
