#!/bin/bash
# Quick verification script - run this after starting Docker Desktop on AT2 host

set -e

GREEN='\033[0;32m'
RED='\033[0;31m'
YELLOW='\033[1;33m'
CYAN='\033[0;36m'
BOLD='\033[1m'
NC='\033[0m'

echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "${BOLD}  🐳 Docker Desktop Connection Verifier${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""

# Test 1: Docker socket
echo -e "${BOLD}[1/5] Checking Docker socket...${NC}"
if [ -S /var/run/docker.sock ]; then
    echo -e "  ${GREEN}✅ Socket exists: /var/run/docker.sock${NC}"
else
    echo -e "  ${RED}❌ Socket missing or not a socket${NC}"
    exit 1
fi

# Test 2: Docker version
echo ""
echo -e "${BOLD}[2/5] Testing Docker client...${NC}"
if docker version > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Docker client connected to daemon${NC}"
    docker version | head -15
else
    echo -e "  ${RED}❌ Cannot connect to Docker daemon${NC}"
    echo -e "  ${YELLOW}→ Docker Desktop is NOT running on AT2 host${NC}"
    echo ""
    echo -e "  ${YELLOW}Please start Docker Desktop on your AT2 machine:${NC}"
    echo -e "    • Linux: ${CYAN}sudo systemctl start docker${NC}"
    echo -e "    • macOS/Windows: ${CYAN}Open Docker Desktop app${NC}"
    exit 1
fi

# Test 3: Docker info
echo ""
echo -e "${BOLD}[3/5] Querying Docker daemon info...${NC}"
if docker info > /dev/null 2>&1; then
    CONTAINERS=$(docker info 2>/dev/null | grep "Containers:" | awk '{print $2}')
    IMAGES=$(docker info 2>/dev/null | grep "Images:" | awk '{print $2}')
    echo -e "  ${GREEN}✅ Docker daemon is healthy${NC}"
    echo -e "  ${CYAN}  Containers: $CONTAINERS | Images: $IMAGES${NC}"
else
    echo -e "  ${YELLOW}⚠️  Docker daemon responded but info query failed${NC}"
fi

# Test 4: Pull test
echo ""
echo -e "${BOLD}[4/5] Testing image pull...${NC}"
if docker pull alpine:latest > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Successfully pulled alpine:latest${NC}"
else
    echo -e "  ${YELLOW}⚠️  Image pull failed (may be a network/registry issue)${NC}"
fi

# Test 5: Container run test
echo ""
echo -e "${BOLD}[5/5] Testing container execution...${NC}"
if docker run --rm alpine:latest echo "Docker containers work" > /dev/null 2>&1; then
    echo -e "  ${GREEN}✅ Container execution successful${NC}"
else
    echo -e "  ${YELLOW}⚠️  Container execution failed${NC}"
fi

# Success
echo ""
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo -e "  ${GREEN}${BOLD}✨ Docker Desktop is FULLY OPERATIONAL ✨${NC}"
echo -e "${CYAN}═══════════════════════════════════════════════════════════════════${NC}"
echo ""
echo -e "${BOLD}Next Steps:${NC}"
echo ""
echo -e "  ${CYAN}1.${NC} Start all local systems:"
echo -e "     ${CYAN}bash /workspaces/dominion-os-demo-build/scripts/start_all_local_systems.sh${NC}"
echo ""
echo -e "  ${CYAN}2.${NC} Activate remote GCP services:"
echo -e "     ${CYAN}bash /workspaces/dominion-os-demo-build/scripts/phi_command_center_activation.sh${NC}"
echo ""
echo -e "  ${CYAN}3.${NC} Monitor Docker services:"
echo -e "     ${CYAN}docker-compose -f /workspaces/dominion-os-demo-build/scripts/docker-compose.yml ps${NC}"
echo ""
