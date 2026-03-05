#!/bin/bash
# PHI Environment Validator - Ensures Dev and Production are Perfect
# Validates all deployment modes: Local (SQLite), Docker (PostgreSQL), Production

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
RED='\033[0;31m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
VALIDATION_PASSED=true

echo -e "${CYAN}"
cat << "EOF"
╔════════════════════════════════════════════════════════════════════╗
║                                                                    ║
║   ██████╗ ██╗  ██╗██╗    ██╗   ██╗ █████╗ ██╗     ██╗██████╗      ║
║   ██╔══██╗██║  ██║██║    ██║   ██║██╔══██╗██║     ██║██╔══██╗     ║
║   ██████╔╝███████║██║    ██║   ██║███████║██║     ██║██║  ██║     ║
║   ██╔═══╝ ██╔══██║██║    ╚██╗ ██╔╝██╔══██║██║     ██║██║  ██║     ║
║   ██║     ██║  ██║██║     ╚████╔╝ ██║  ██║███████╗██║██████╔╝     ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝      ╚═══╝  ╚═╝  ╚═╝╚══════╝╚═╝╚═════╝      ║
║                                                                    ║
║              ENVIRONMENT VALIDATION & READINESS CHECK              ║
║                                                                    ║
╚════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

# Validation functions
check_pass() {
    echo -e "${GREEN}✓${NC} $1"
}

check_fail() {
    echo -e "${RED}✗${NC} $1"
    VALIDATION_PASSED=false
}

check_warn() {
    echo -e "${YELLOW}⚠${NC} $1"
}

check_info() {
    echo -e "${BLUE}ℹ${NC} $1"
}

section_header() {
    echo ""
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
    echo -e "${MAGENTA}$1${NC}"
    echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
}

# 1. System Requirements
section_header "1. SYSTEM REQUIREMENTS"

# Python
if command -v python3 &> /dev/null; then
    PYTHON_VERSION=$(python3 --version 2>&1 | awk '{print $2}')
    check_pass "Python: $PYTHON_VERSION"
else
    check_fail "Python 3 not found"
fi

# SQLite
if command -v sqlite3 &> /dev/null; then
    SQLITE_VERSION=$(sqlite3 --version | awk '{print $1}')
    check_pass "SQLite: $SQLITE_VERSION"
else
    check_warn "SQLite CLI not found (optional)"
fi

# Docker
if command -v docker &> /dev/null; then
    DOCKER_VERSION=$(docker --version | awk '{print $3}' | tr -d ',')
    check_pass "Docker: $DOCKER_VERSION"
    DOCKER_AVAILABLE=true
else
    check_warn "Docker not available (production deployment disabled)"
    DOCKER_AVAILABLE=false
fi

# PostgreSQL client
if command -v psql &> /dev/null; then
    PSQL_VERSION=$(psql --version | awk '{print $3}')
    check_pass "PostgreSQL Client: $PSQL_VERSION"
else
    check_warn "PostgreSQL client not found (optional)"
fi

# 2. Python Dependencies
section_header "2. PYTHON DEPENDENCIES"

cd "$SCRIPT_DIR"

# Check for virtual environment
if [ -d ".venv" ]; then
    check_pass "Virtual environment exists"
    source .venv/bin/activate 2>/dev/null || true
else
    check_warn "Virtual environment not found (will use system Python)"
fi

# Check required packages
REQUIRED_PACKAGES=("flask" "sqlalchemy" "openpyxl")
for package in "${REQUIRED_PACKAGES[@]}"; do
    if python3 -c "import $package" 2>/dev/null; then
        VERSION=$(python3 -c "import $package; print(getattr($package, '__version__', 'unknown'))" 2>/dev/null)
        check_pass "$package: $VERSION"
    else
        check_fail "$package not installed"
    fi
done

# 3. Directory Structure
section_header "3. DIRECTORY STRUCTURE"

REQUIRED_DIRS=("data" "logs" "telemetry" "exports")
for dir in "${REQUIRED_DIRS[@]}"; do
    if [ -d "$SCRIPT_DIR/$dir" ]; then
        SIZE=$(du -sh "$SCRIPT_DIR/$dir" 2>/dev/null | awk '{print $1}')
        check_pass "$dir/ exists ($SIZE)"
    else
        check_warn "$dir/ missing (will be created automatically)"
    fi
done

# 4. Configuration Files
section_header "4. CONFIGURATION FILES"

# Check for key scripts
REQUIRED_SCRIPTS=(
    "expenditure_dashboard.py"
    "expenditure_models.py"
    "phi_desktop_local_perfect.sh"
    "phi_local_deploy.sh"
    "phi_docker_deploy.sh"
    "phi_expenditure_ai_optimizer.py"
)

for script in "${REQUIRED_SCRIPTS[@]}"; do
    if [ -f "$SCRIPT_DIR/$script" ]; then
        check_pass "$script"
    else
        check_fail "$script missing"
    fi
done

# Check config template
if [ -f "$SCRIPT_DIR/config.env.template" ]; then
    check_pass "config.env.template"
else
    check_warn "config.env.template missing"
fi

# Check for .env
if [ -f "$SCRIPT_DIR/.env" ]; then
    check_info ".env found (using custom configuration)"
else
    check_info ".env not found (using defaults)"
fi

# 5. Database Status
section_header "5. DATABASE STATUS - LOCAL (SQLite)"

if [ -f "$SCRIPT_DIR/data/expenditures.db" ]; then
    DB_SIZE=$(ls -lh "$SCRIPT_DIR/data/expenditures.db" | awk '{print $5}')
    check_pass "Local database exists ($DB_SIZE)"

    # Check database integrity
    if sqlite3 "$SCRIPT_DIR/data/expenditures.db" "PRAGMA integrity_check;" | grep -q "ok"; then
        check_pass "Database integrity: OK"
    else
        check_fail "Database integrity check failed"
    fi

    # Count records
    RECORD_COUNT=$(sqlite3 "$SCRIPT_DIR/data/expenditures.db" "SELECT COUNT(*) FROM expenditures;" 2>/dev/null || echo "0")
    check_info "Records in database: $RECORD_COUNT"
else
    check_warn "Local database not initialized (run init_expenditure_database.py)"
fi

# 6. Running Services
section_header "6. RUNNING SERVICES"

# Check if dashboard is running
if curl -s http://localhost:5000/health &> /dev/null; then
    check_pass "Dashboard is running on port 5000"

    # Get health status
    HEALTH=$(curl -s http://localhost:5000/health)
    if echo "$HEALTH" | grep -q '"status": "healthy"'; then
        check_pass "Dashboard health: HEALTHY"
    else
        check_warn "Dashboard health check returned unexpected response"
    fi

    # Check process
    if pgrep -f "expenditure_dashboard.py" > /dev/null; then
        PID=$(pgrep -f "expenditure_dashboard.py" | head -1)
        check_info "Dashboard PID: $PID"
    fi
else
    check_info "Dashboard not running (use phi_desktop_local_perfect.sh to start)"
fi

# 7. Docker Environment (if available)
if [ "$DOCKER_AVAILABLE" = true ]; then
    section_header "7. DOCKER ENVIRONMENT - PRODUCTION"

    # Check for running containers
    if docker ps --filter "name=phi-expenditure" --format "{{.Names}}" 2>/dev/null | grep -q "phi-expenditure"; then
        check_pass "PHI Docker containers running"
        docker ps --filter "name=phi-expenditure" --format "  - {{.Names}}: {{.Status}}" 2>/dev/null
    else
        check_info "No PHI Docker containers running (use phi_docker_deploy.sh to deploy)"
    fi

    # Check for Docker images
    if docker images | grep -q "phi-expenditure-dashboard"; then
        check_pass "PHI Docker image built"
    else
        check_info "PHI Docker image not built (will be built on first deployment)"
    fi

    # Check Docker network
    if docker network ls 2>/dev/null | grep -q "phi_network"; then
        check_pass "Docker network 'phi_network' exists"
    else
        check_info "Docker network will be created on deployment"
    fi
fi

# 8. Deployment Readiness
section_header "8. DEPLOYMENT READINESS"

# Local deployment
if [ -f "$SCRIPT_DIR/expenditure_dashboard.py" ] && \
   python3 -c "import flask, sqlalchemy" 2>/dev/null; then
    check_pass "Local deployment: READY"
else
    check_fail "Local deployment: NOT READY (missing dependencies)"
fi

# Docker deployment
if [ "$DOCKER_AVAILABLE" = true ] && [ -f "$SCRIPT_DIR/Dockerfile.expenditure" ]; then
    check_pass "Docker deployment: READY"
else
    check_info "Docker deployment: NOT AVAILABLE"
fi

# AI Optimizer
if [ -f "$SCRIPT_DIR/phi_expenditure_ai_optimizer.py" ]; then
    check_pass "AI Optimizer: READY"
else
    check_fail "AI Optimizer: NOT FOUND"
fi

# 9. Security & Configuration
section_header "9. SECURITY & CONFIGURATION"

# Check for default passwords in config
if [ -f "$SCRIPT_DIR/.env" ]; then
    if grep -q "CHANGE_ME" "$SCRIPT_DIR/.env" 2>/dev/null; then
        check_warn "Default credentials found in .env (update before production deployment)"
    else
        check_pass "Configuration customized"
    fi
fi

# Check secret key
if [ -n "$FLASK_SECRET_KEY" ]; then
    check_pass "FLASK_SECRET_KEY is set"
else
    check_info "FLASK_SECRET_KEY will be generated automatically"
fi

# 10. Final Summary
section_header "10. VALIDATION SUMMARY"

echo ""
if [ "$VALIDATION_PASSED" = true ]; then
    echo -e "${GREEN}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║                     ✅ ALL CHECKS PASSED ✅                        ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}║            PHI is ready for development and production!            ║${NC}"
    echo -e "${GREEN}║                                                                    ║${NC}"
    echo -e "${GREEN}╚════════════════════════════════════════════════════════════════════╝${NC}"
else
    echo -e "${YELLOW}╔════════════════════════════════════════════════════════════════════╗${NC}"
    echo -e "${YELLOW}║                                                                    ║${NC}"
    echo -e "${YELLOW}║                 ⚠  VALIDATION COMPLETED WITH WARNINGS  ⚠          ║${NC}"
    echo -e "${YELLOW}║                                                                    ║${NC}"
    echo -e "${YELLOW}║      Please review the issues above before production deployment  ║${NC}"
    echo -e "${YELLOW}║                                                                    ║${NC}"
    echo -e "${YELLOW}╚════════════════════════════════════════════════════════════════════╝${NC}"
fi

echo ""
echo -e "${CYAN}Quick Start Commands:${NC}"
echo -e "  ${GREEN}Local Dev:${NC}        bash phi_desktop_local_perfect.sh"
echo -e "  ${GREEN}Docker Prod:${NC}      bash phi_docker_deploy.sh"
echo -e "  ${GREEN}AI Optimizer:${NC}     python3 phi_expenditure_ai_optimizer.py --test"
echo -e "  ${GREEN}Health Check:${NC}     curl http://localhost:5000/health"
echo ""

exit 0
