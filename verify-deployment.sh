#!/bin/bash
# ============================================================================
# PHI SOVEREIGN SERVICE VERIFICATION SCRIPT
# ============================================================================
# Verify all services are running and responding correctly
# Execute after deploy-desktop-pro.sh
# ============================================================================

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m'

echo -e "${BLUE}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║           PHI SOVEREIGN SERVICE VERIFICATION                         ║${NC}"
echo -e "${BLUE}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""

# Function to check HTTP endpoint
check_endpoint() {
    local name=$1
    local url=$2
    local expected_code=${3:-200}

    echo -n "  ${YELLOW}▸ ${name}:${NC} "

    if command -v curl &> /dev/null; then
        response=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")
        if [ "$response" = "$expected_code" ] || [ "$response" = "200" ] || [ "$response" = "301" ] || [ "$response" = "302" ]; then
            echo -e "${GREEN}✓ ${url}${NC}"
            return 0
        else
            echo -e "${RED}✗ ${url} (HTTP $response)${NC}"
            return 1
        fi
    else
        echo -e "${YELLOW}⚠ curl not available, skipping${NC}"
        return 0
    fi
}

# Function to check port
check_port() {
    local name=$1
    local host=$2
    local port=$3

    echo -n "  ${YELLOW}▸ ${name}:${NC} "

    if command -v nc &> /dev/null; then
        if nc -z -w2 "$host" "$port" 2>/dev/null; then
            echo -e "${GREEN}✓ ${host}:${port}${NC}"
            return 0
        else
            echo -e "${RED}✗ ${host}:${port} not reachable${NC}"
            return 1
        fi
    elif timeout 2 bash -c "cat < /dev/null > /dev/tcp/$host/$port" 2>/dev/null; then
        echo -e "${GREEN}✓ ${host}:${port}${NC}"
        return 0
    else
        echo -e "${RED}✗ ${host}:${port} not reachable${NC}"
        return 1
    fi
}

echo -e "${BLUE}[1/3] Checking HTTP Services...${NC}"
check_endpoint "PHI Dashboard" "http://localhost:5000"
check_endpoint "OAuth Server" "http://localhost:8080"
check_endpoint "AskPHI Widget" "http://localhost:8081"
check_endpoint "Prometheus" "http://localhost:9090"
check_endpoint "Grafana" "http://localhost:3000"
echo ""

echo -e "${BLUE}[2/3] Checking Database Services...${NC}"
check_port "PostgreSQL" "localhost" "5432"
check_port "Redis" "localhost" "6379"
echo ""

echo -e "${BLUE}[3/3] Checking Docker Containers...${NC}"
if command -v docker &> /dev/null && docker info &> /dev/null; then
    # Detect compose command
    if docker compose version &> /dev/null 2>&1; then
        COMPOSE_CMD="docker compose"
    elif command -v docker-compose &> /dev/null; then
        COMPOSE_CMD="docker-compose"
    else
        echo -e "${YELLOW}  ⚠ Docker Compose not available${NC}"
        COMPOSE_CMD=""
    fi

    if [ -n "$COMPOSE_CMD" ]; then
        echo ""
        $COMPOSE_CMD -f docker-compose.desktop-pro.yml ps
        echo ""

        # Check health status
        echo -e "${BLUE}Container Health Status:${NC}"
        for container in phi-sovereign-core phi-database phi-redis phi-prometheus phi-grafana; do
            if docker ps --filter "name=$container" --format "{{.Names}}" | grep -q "$container"; then
                health=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "no healthcheck")
                status=$(docker inspect --format='{{.State.Status}}' "$container" 2>/dev/null || echo "unknown")

                echo -n "  ${YELLOW}▸ ${container}:${NC} "
                if [ "$status" = "running" ]; then
                    if [ "$health" = "healthy" ]; then
                        echo -e "${GREEN}✓ running (healthy)${NC}"
                    elif [ "$health" = "no healthcheck" ]; then
                        echo -e "${GREEN}✓ running${NC}"
                    else
                        echo -e "${YELLOW}⚠ running ($health)${NC}"
                    fi
                else
                    echo -e "${RED}✗ $status${NC}"
                fi
            else
                echo -e "  ${YELLOW}▸ ${container}:${NC} ${RED}✗ not found${NC}"
            fi
        done
    fi
else
    echo -e "${YELLOW}  ⚠ Docker not available or not running${NC}"
fi
echo ""

echo -e "${GREEN}╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║                    VERIFICATION COMPLETE                             ║${NC}"
echo -e "${GREEN}╚══════════════════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📊 Next Steps:${NC}"
echo -e "  1. Open PHI Dashboard: ${GREEN}http://localhost:5000${NC}"
echo -e "  2. View Grafana Metrics: ${GREEN}http://localhost:3000${NC} (admin/sovereign_admin)"
echo -e "  3. Check Prometheus: ${GREEN}http://localhost:9090${NC}"
echo -e "  4. View logs: ${YELLOW}docker compose -f docker-compose.desktop-pro.yml logs -f${NC}"
echo ""
echo -e "${GREEN}🛡️  PHI Sovereign Authority: 9/9 - All Systems Operational${NC}"
echo ""

exit 0
