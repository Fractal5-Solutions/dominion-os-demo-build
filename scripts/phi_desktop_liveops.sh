#!/bin/bash
# PHI Desktop LiveOps - Perfected Docker Deployment
# Purpose: One-command startup for complete PHI system with Docker
# Optimized for desktop development and operations

set -e

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
BOLD='\033[1m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

# Banner
clear
echo -e "${MAGENTA}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║   ██████╗ ██╗  ██╗██╗    ██████╗ ███████╗███████╗██╗  ██╗████████╗ ██████╗ ██████╗  ║
║   ██╔══██╗██║  ██║██║    ██╔══██╗██╔════╝██╔════╝██║ ██╔╝╚══██╔══╝██╔═══██╗██╔══██╗ ║
║   ██████╔╝███████║██║    ██║  ██║█████╗  ███████╗█████╔╝    ██║   ██║   ██║██████╔╝ ║
║   ██╔═══╝ ██╔══██║██║    ██║  ██║██╔══╝  ╚════██║██╔═██╗    ██║   ██║   ██║██╔═══╝  ║
║   ██║     ██║  ██║██║    ██████╔╝███████╗███████║██║  ██╗   ██║   ╚██████╔╝██║      ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝    ╚═════╝ ╚══════╝╚══════╝╚═╝  ╚═╝   ╚═╝    ╚═════╝ ╚═╝      ║
║                                                                       ║
║               LIVE OPERATIONS - PERFECTED DESKTOP EDITION            ║
║          AI-Powered Expenditure Tracking | Full Autopilot           ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} ${BLUE}Initializing PHI Desktop LiveOps...${NC}"
echo ""

# Step 1: Pre-flight checks
echo -e "${YELLOW}━━━ PHASE 1: PRE-FLIGHT CHECKS ━━━${NC}"

# Check Docker
echo -e "${CYAN}[1/5]${NC} Checking Docker availability..."
if ! command -v docker &> /dev/null; then
    echo -e "${RED}✗ Docker not found!${NC}"
    echo -e "${YELLOW}Please install Docker Desktop: https://www.docker.com/products/docker-desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker found: $(docker --version)${NC}"

# Check Docker Compose
echo -e "${CYAN}[2/5]${NC} Checking Docker Compose..."
if ! docker compose version &> /dev/null; then
    echo -e "${RED}✗ Docker Compose not available!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker Compose: $(docker compose version)${NC}"

# Check if Docker daemon is running
echo -e "${CYAN}[3/5]${NC} Verifying Docker daemon..."
if ! docker info &> /dev/null; then
    echo -e "${RED}✗ Docker daemon not running!${NC}"
    echo -e "${YELLOW}Please start Docker Desktop${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Docker daemon active${NC}"

# Check environment file
echo -e "${CYAN}[4/5]${NC} Checking environment configuration..."
if [ ! -f ".env" ]; then
    echo -e "${YELLOW}⚠ No .env file found, creating from template...${NC}"
    if [ -f "config.env.template" ]; then
        cp config.env.template .env
        echo -e "${GREEN}✓ Created .env from template${NC}"
    else
        echo -e "${YELLOW}⚠ No template found, creating minimal .env${NC}"
        cat > .env <<'ENVEOF'
# PHI Expenditure System Configuration
POSTGRES_USER=phi_admin
POSTGRES_PASSWORD=secure_password_phi_2026
POSTGRES_DB=expenditures
POSTGRES_PORT=5432
DASHBOARD_PORT=5000
FLASK_SECRET_KEY=change_me_in_production
FLASK_DEBUG=false
DEMO_MODE=false
ENVEOF
    fi
else
    echo -e "${GREEN}✓ Environment file found${NC}"
fi

# Create required directories
echo -e "${CYAN}[5/5]${NC} Setting up directories..."
mkdir -p telemetry backups data
echo -e "${GREEN}✓ Directories ready${NC}"

echo ""
echo -e "${YELLOW}━━━ PHASE 2: DOCKER SERVICES ━━━${NC}"

# Stop any existing containers
echo -e "${CYAN}[1/3]${NC} Cleaning up old containers..."
docker compose down 2>/dev/null || true
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Build images
echo -e "${CYAN}[2/3]${NC} Building Docker images..."
docker compose build --quiet
echo -e "${GREEN}✓ Images built${NC}"

# Start services
echo -e "${CYAN}[3/3]${NC} Starting services..."
docker compose up -d
echo -e "${GREEN}✓ Services started${NC}"

echo ""
echo -e "${YELLOW}━━━ PHASE 3: HEALTH VERIFICATION ━━━${NC}"

# Wait for database
echo -n -e "${CYAN}[1/3]${NC} Waiting for PostgreSQL"
for i in {1..30}; do
    if docker compose exec -T postgres pg_isready -U phi_admin &>/dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
if [ $i -eq 30 ]; then
    echo -e " ${RED}✗ Timeout${NC}"
    exit 1
fi

# Wait for dashboard
echo -n -e "${CYAN}[2/3]${NC} Waiting for Dashboard"
for i in {1..30}; do
    if curl -s http://localhost:5000/health &>/dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    echo -n "."
    sleep 1
done
if [ $i -eq 30 ]; then
    echo -e " ${YELLOW}⚠ Dashboard may need more time${NC}"
fi

# Initialize database
echo -e "${CYAN}[3/3]${NC} Initializing database schema..."
if docker compose exec -T dashboard python3 init_expenditure_database.py &>/dev/null; then
    echo -e "${GREEN}✓ Database initialized${NC}"
else
    echo -e "${YELLOW}⚠ Database may already be initialized${NC}"
fi

echo ""
echo -e "${MAGENTA}${BOLD}"
echo "╔═══════════════════════════════════════════════════════════════════════╗"
echo "║                                                                       ║"
echo "║                     ✨ DEPLOYMENT COMPLETE ✨                        ║"
echo "║                                                                       ║"
echo "╚═══════════════════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Status display
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${BOLD}📊 SYSTEM STATUS${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Container status
echo -e "${YELLOW}🐳 Docker Containers:${NC}"
docker compose ps --format "table {{.Name}}\t{{.Status}}\t{{.Ports}}" | tail -n +2 | while IFS=$'\t' read -r name status ports; do
    if [[ $status == *"Up"* ]]; then
        echo -e "  ${GREEN}●${NC} ${name}: ${GREEN}Running${NC}"
        if [ -n "$ports" ]; then
            echo -e "    ${CYAN}↳${NC} Ports: ${ports}"
        fi
    else
        echo -e "  ${RED}●${NC} ${name}: ${status}"
    fi
done

echo ""
echo -e "${YELLOW}🌐 Access Points:${NC}"
echo -e "  ${GREEN}●${NC} Dashboard:  ${CYAN}http://localhost:5000${NC}"
echo -e "  ${GREEN}●${NC} Database:   ${CYAN}localhost:5432${NC}"
echo -e "  ${GREEN}●${NC} API Health: ${CYAN}http://localhost:5000/health${NC}"

echo ""
echo -e "${YELLOW}💾 Database:${NC}"
echo -e "  Host:     ${CYAN}localhost${NC} (external) | ${CYAN}postgres${NC} (internal)"
echo -e "  Database: ${CYAN}expenditures${NC}"
echo -e "  User:     ${CYAN}phi_admin${NC}"
echo -e "  Password: ${CYAN}(see .env)${NC}"

echo ""
echo -e "${YELLOW}📋 Management Commands:${NC}"
echo -e "  ${CYAN}docker compose logs -f${NC}              # Watch all logs"
echo -e "  ${CYAN}docker compose logs -f dashboard${NC}    # Watch dashboard logs"
echo -e "  ${CYAN}docker compose stop${NC}                 # Stop services"
echo -e "  ${CYAN}docker compose start${NC}                # Start services"
echo -e "  ${CYAN}docker compose down${NC}                 # Stop and remove"
echo -e "  ${CYAN}docker compose restart${NC}              # Restart all"

echo ""
echo -e "${YELLOW}🔧 Quick Actions:${NC}"
echo -e "  ${CYAN}docker exec -it phi-expenditure-dashboard bash${NC}     # Shell access"
echo -e "  ${CYAN}docker exec -it phi-expenditure-db psql -U phi_admin -d expenditures${NC}"
echo -e "  ${CYAN}docker compose exec dashboard python3 generate_sample_data.py${NC}"

echo ""
echo -e "${YELLOW}📊 View Dashboard:${NC}"
echo -e "  ${GREEN}${BOLD}Open your browser to: http://localhost:5000${NC}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}✓ PHI Desktop LiveOps is ready for use!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""

# Optional: Open browser
if command -v xdg-open &> /dev/null; then
    echo -e "${YELLOW}Would you like to open the dashboard in your browser? (y/n)${NC}"
    read -t 10 -n 1 open_browser || open_browser="n"
    echo ""
    if [ "$open_browser" = "y" ] || [ "$open_browser" = "Y" ]; then
        xdg-open http://localhost:5000 &>/dev/null || true
    fi
fi

# Keep monitoring in foreground (optional)
if [ "${1:-}" = "--monitor" ]; then
    echo -e "${CYAN}Entering monitoring mode... (Ctrl+C to exit)${NC}"
    echo ""
    docker compose logs -f
fi
