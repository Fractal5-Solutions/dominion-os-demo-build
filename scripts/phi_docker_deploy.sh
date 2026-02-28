#!/bin/bash
# PHI Expenditure Docker Deployment Script
# Complete containerized deployment with PostgreSQL

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   PHI EXPENDITURE - DOCKER DEPLOYMENT                 ║"
echo "║   PostgreSQL + Dashboard + AI Optimizer               ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

cd "$SCRIPT_DIR"

# Create Docker network
echo -e "${BLUE}🌐 Creating Docker network...${NC}"
docker network create phi_network 2>/dev/null || echo -e "${YELLOW}⚠ Network already exists${NC}"

# Start PostgreSQL
echo ""
echo -e "${BLUE}🗄️  Starting PostgreSQL database...${NC}"
docker rm -f phi-expenditure-db 2>/dev/null || true
docker run -d \
    --name phi-expenditure-db \
    --network phi_network \
    -e POSTGRES_USER=phi_admin \
    -e POSTGRES_PASSWORD=secure_password_phi_2026 \
    -e POSTGRES_DB=expenditures \
    -p 5432:5432 \
    postgres:14-alpine

echo -e "${BLUE}⏳ Waiting for database to be ready...${NC}"
sleep 10

# Build dashboard image
echo ""
echo -e "${BLUE}📦 Building dashboard image...${NC}"
docker build -t phi-expenditure-dashboard -f Dockerfile.expenditure .

# Start dashboard
echo ""
echo -e "${BLUE}🚀 Starting dashboard...${NC}"
docker rm -f phi-expenditure-dashboard 2>/dev/null || true
docker run -d \
    --name phi-expenditure-dashboard \
    --network phi_network \
    -e EXPENDITURE_DB="postgresql://phi_admin:secure_password_phi_2026@phi-expenditure-db:5432/expenditures" \
    -e FLASK_SECRET_KEY="phi_secret_key_2026_production_change_me" \
    -p 5000:5000 \
    -v "$(pwd)/../telemetry:/app/telemetry" \
    phi-expenditure-dashboard

echo ""
echo -e "${BLUE}⏳ Waiting for dashboard to be ready...${NC}"
sleep 5

# Check container status
echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Deployment Complete${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}📊 Container Status:${NC}"
docker ps --filter "name=phi-expenditure" --format "table {{.Names}}\t{{.Status}}\t{{.Ports}}"

echo ""
echo -e "${YELLOW}🌐 Access Points:${NC}"
echo -e "  Dashboard: ${GREEN}http://localhost:5000${NC}"
echo -e "  Database:  ${GREEN}localhost:5432${NC}"
echo ""
echo -e "${YELLOW}💾 Database Credentials:${NC}"
echo -e "  Host:     postgres (internal) / localhost (external)"
echo -e "  Database: expenditures"
echo -e "  User:     phi_admin"
echo -e "  Password: secure_password_phi_2026"
echo ""
echo -e "${YELLOW}📋 Management Commands:${NC}"
echo -e "  View dashboard logs: ${CYAN}docker logs -f phi-expenditure-dashboard${NC}"
echo -e "  View database logs:  ${CYAN}docker logs -f phi-expenditure-db${NC}"
echo -e "  Stop services:       ${CYAN}docker stop phi-expenditure-dashboard phi-expenditure-db${NC}"
echo -e "  Remove services:     ${CYAN}docker rm phi-expenditure-dashboard phi-expenditure-db${NC}"
echo -e "  Shell access:        ${CYAN}docker exec -it phi-expenditure-dashboard bash${NC}"
echo -e "  DB access:           ${CYAN}docker exec -it phi-expenditure-db psql -U phi_admin -d expenditures${NC}"
echo ""
echo -e "${YELLOW}🧪 Test AI Optimizer:${NC}"
echo -e "  ${CYAN}docker exec phi-expenditure-dashboard python3 phi_expenditure_ai_optimizer.py --test${NC}"
echo ""
echo -e "${GREEN}✓ System ready for use!${NC}"
