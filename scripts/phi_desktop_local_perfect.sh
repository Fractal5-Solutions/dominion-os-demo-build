#!/bin/bash
# PHI Desktop LiveOps - Perfected Local Deployment
# Purpose: One-command startup for complete PHI system (No Docker Required)
# Optimized for desktop development with SQLite backend

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

# Export environment variables for SQLite mode
export EXPENDITURE_DB="sqlite:///${SCRIPT_DIR}/data/expenditures.db"
export FLASK_SECRET_KEY="${FLASK_SECRET_KEY:-$(openssl rand -hex 32 2>/dev/null || echo "phi_secret_key_2026")}"
export FLASK_ENV="development"
export FLASK_DEBUG="true"

# Banner
clear
echo -e "${MAGENTA}${BOLD}"
cat << "EOF"
╔═══════════════════════════════════════════════════════════════════════╗
║                                                                       ║
║   ██████╗ ██╗  ██╗██╗    ██╗      ██████╗  ██████╗ █████╗ ██╗             ║
║   ██╔══██╗██║  ██║██║    ██║      ██╔═══██╗██╔════╝██╔══██╗██║             ║
║   ██████╔╝███████║██║    ██║      ██║   ██║██║     ███████║██║             ║
║   ██╔═══╝ ██╔══██║██║    ██║      ██║   ██║██║     ██╔══██║██║             ║
║   ██║     ██║  ██║██║    ███████╗ ╚██████╔╝╚██████╗██║  ██║███████╗        ║
║   ╚═╝     ╚═╝  ╚═╝╚═╝    ╚══════╝  ╚═════╝  ╚═════╝╚═╝  ╚═╝╚══════╝        ║
║                                                                       ║
║               LIVE OPERATIONS - PERFECTED LOCAL EDITION              ║
║          AI-Powered Expenditure Tracking | SQLite Backend            ║
║                                                                       ║
╚═══════════════════════════════════════════════════════════════════════╝
EOF
echo -e "${NC}"

echo -e "${CYAN}[$(date '+%H:%M:%S')]${NC} ${BLUE}Initializing PHI Local LiveOps...${NC}"
echo ""

# Step 1: Pre-flight checks
echo -e "${YELLOW}━━━ PHASE 1: ENVIRONMENT SETUP ━━━${NC}"

# Check Python
echo -e "${CYAN}[1/5]${NC} Checking Python..."
if ! command -v python3 &> /dev/null; then
    echo -e "${RED}✗ Python3 not found!${NC}"
    exit 1
fi
echo -e "${GREEN}✓ Python: $(python3 --version)${NC}"

# Create/activate virtual environment
echo -e "${CYAN}[2/5]${NC} Setting up virtual environment..."
if [ ! -d ".venv" ]; then
    echo -e "${YELLOW}  Creating new virtual environment...${NC}"
    python3 -m venv .venv
fi
source .venv/bin/activate
echo -e "${GREEN}✓ Virtual environment activated${NC}"

# Install dependencies
echo -e "${CYAN}[3/5]${NC} Installing Python dependencies..."
pip install -q --upgrade pip 2>/dev/null || true
if pip install -q -r requirements.txt 2>/dev/null; then
    echo -e "${GREEN}✓ Dependencies installed${NC}"
else
    echo -e "${YELLOW}⚠ Some dependencies may have issues, continuing...${NC}"
fi

# Create directories
echo -e "${CYAN}[4/5]${NC} Creating required directories..."
mkdir -p data telemetry backups logs
echo -e "${GREEN}✓ Directories ready${NC}"

# Check if database exists
echo -e "${CYAN}[5/5]${NC} Checking database..."
DB_EXISTS=false
if [ -f "data/expenditures.db" ]; then
    echo -e "${GREEN}✓ Database found${NC}"
    DB_EXISTS=true
else
    echo -e "${YELLOW}⚠ Database not found, will initialize${NC}"
fi

echo ""
echo -e "${YELLOW}━━━ PHASE 2: DATABASE INITIALIZATION ━━━${NC}"

if [ "$DB_EXISTS" = false ]; then
    echo -e "${CYAN}[1/1]${NC} Creating database schema..."

    # Create initialization script for SQLite
    cat > init_db_sqlite.py <<'PYEOF'
#!/usr/bin/env python3
import os
from sqlalchemy import create_engine, text

db_url = os.environ.get('EXPENDITURE_DB', 'sqlite:///./data/expenditures.db')
engine = create_engine(db_url)

with engine.connect() as conn:
    # Expenditures table
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS expenditures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vendor TEXT NOT NULL,
            amount REAL NOT NULL,
            date TEXT NOT NULL,
            description TEXT,
            invoice_number TEXT,
            category TEXT DEFAULT 'Uncategorized',
            confidence TEXT DEFAULT 'LOW',
            confidence_score REAL DEFAULT 0.5,
            verified INTEGER DEFAULT 0,
            verified_by TEXT,
            verified_at TEXT,
            tax_amount REAL,
            tax_type TEXT,
            ai_metadata TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """))

    # Vendors table
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS vendors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            category TEXT,
            contact_email TEXT,
            notes TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """))

    conn.commit()
    print("✓ Database initialized successfully")

PYEOF

    python3 init_db_sqlite.py
    if [ $? -eq 0 ]; then
        echo -e "${GREEN}✓ Database schema created${NC}"
    else
        echo -e "${RED}✗ Database initialization failed${NC}"
        exit 1
    fi

    # Generate sample data
    echo -e "${CYAN}Generating sample data...${NC}"
    if [ -f "generate_sample_data.py" ]; then
        python3 generate_sample_data.py --count 25 2>/dev/null || echo -e "${YELLOW}⚠ Sample data generation skipped${NC}"
    fi
else
    echo -e "${CYAN}[1/1]${NC} Database already initialized, skipping..."
fi

echo ""
echo -e "${YELLOW}━━━ PHASE 3: SERVICE STARTUP ━━━${NC}"

# Kill any existing processes
echo -e "${CYAN}[1/3]${NC} Cleaning up old processes..."
pkill -f "expenditure_dashboard.py" 2>/dev/null || true
pkill -f "phi_expenditure_autopilot" 2>/dev/null || true
sleep 2
echo -e "${GREEN}✓ Cleanup complete${NC}"

# Start dashboard in background
echo -e "${CYAN}[2/3]${NC} Starting expenditure dashboard..."
nohup python3 expenditure_dashboard.py > logs/dashboard.log 2>&1 &
DASHBOARD_PID=$!
echo $DASHBOARD_PID > telemetry/dashboard.pid
echo -e "${GREEN}✓ Dashboard started (PID: $DASHBOARD_PID)${NC}"

# Wait for dashboard to be ready
echo -n -e "${CYAN}[3/3]${NC} Waiting for dashboard"
for i in {1..30}; do
    if curl -s http://localhost:5000/health &>/dev/null; then
        echo -e " ${GREEN}✓${NC}"
        break
    fi
    if ! ps -p $DASHBOARD_PID > /dev/null; then
        echo -e " ${RED}✗ Dashboard crashed${NC}"
        echo -e "${YELLOW}Check logs: tail -f logs/dashboard.log${NC}"
        exit 1
    fi
    echo -n "."
    sleep 1
done

echo ""
echo -e "${YELLOW}━━━ PHASE 4: HEALTH CHECK ━━━${NC}"

# Test database connectivity
echo -e "${CYAN}[1/2]${NC} Testing database..."
python3 <<'TESTEOF'
import os
from sqlalchemy import create_engine, text
db_url = os.environ.get('EXPENDITURE_DB')
try:
    engine = create_engine(db_url)
    with engine.connect() as conn:
        result = conn.execute(text("SELECT COUNT(*) FROM expenditures")).scalar()
        print(f"✓ Database: {result} expenditures found")
except Exception as e:
    print(f"✗ Database error: {e}")
    exit(1)
TESTEOF

if [ $? -eq 0 ]; then
    echo -e "${GREEN}✓ Database healthy${NC}"
else
    echo -e "${RED}✗ Database check failed${NC}"
fi

# Test dashboard
echo -e "${CYAN}[2/2]${NC} Testing dashboard API..."
if curl -s http://localhost:5000/api/expenditures | grep -q "expenditures" 2>/dev/null; then
    echo -e "${GREEN}✓ Dashboard API responding${NC}"
else
    echo -e "${YELLOW}⚠ Dashboard may still be starting${NC}"
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

# Process status
echo -e "${YELLOW}🔄 Running Services:${NC}"
if ps -p $DASHBOARD_PID > /dev/null; then
    echo -e "  ${GREEN}●${NC} Dashboard: ${GREEN}Running${NC} (PID: $DASHBOARD_PID)"
else
    echo -e "  ${RED}●${NC} Dashboard: ${RED}Stopped${NC}"
fi

echo ""
echo -e "${YELLOW}🌐 Access Points:${NC}"
echo -e "  ${GREEN}●${NC} Dashboard:  ${CYAN}http://localhost:5000${NC}"
echo -e "  ${GREEN}●${NC} API:        ${CYAN}http://localhost:5000/api/expenditures${NC}"
echo -e "  ${GREEN}●${NC} Health:     ${CYAN}http://localhost:5000/health${NC}"

echo ""
echo -e "${YELLOW}💾 Database:${NC}"
echo -e "  Type:     ${CYAN}SQLite${NC}"
echo -e "  Location: ${CYAN}${SCRIPT_DIR}/data/expenditures.db${NC}"
echo -e "  Size:     ${CYAN}$(du -h data/expenditures.db 2>/dev/null | cut -f1 || echo "N/A")${NC}"

echo ""
echo -e "${YELLOW}📋 Management Commands:${NC}"
echo -e "  ${CYAN}tail -f logs/dashboard.log${NC}           # Watch dashboard logs"
echo -e "  ${CYAN}curl http://localhost:5000/api/stats${NC}  # Get statistics"
echo -e "  ${CYAN}kill \$(cat telemetry/dashboard.pid)${NC}    # Stop dashboard"
echo -e "  ${CYAN}sqlite3 data/expenditures.db${NC}         # Open database"

echo ""
echo -e "${YELLOW}🔧 Quick Actions:${NC}"
echo -e "  ${CYAN}python3 generate_sample_data.py --count 50${NC}  # Add more sample data"
echo -e "  ${CYAN}python3 expenditure_exports.py${NC}              # Export to Excel"
echo -e "  ${CYAN}python3 phi_expenditure_ai_optimizer.py${NC}     # Run AI optimizer"

echo ""
echo -e "${YELLOW}📊 View Dashboard:${NC}"
echo -e "  ${GREEN}${BOLD}Open your browser to: http://localhost:5000${NC}"

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}${BOLD}✓ PHI Local LiveOps is ready for use!${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}To stop all services:${NC} ${CYAN}kill \$(cat telemetry/dashboard.pid)${NC}"
echo ""

# Optional: Follow logs
if [ "${1:-}" = "--monitor" ]; then
    echo -e "${CYAN}Entering monitoring mode... (Ctrl+C to exit)${NC}"
    echo ""
    tail -f logs/dashboard.log
fi
