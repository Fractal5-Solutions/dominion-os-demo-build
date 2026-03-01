#!/bin/bash
# PHI Expenditure Local Deployment (SQLite - No Docker/PostgreSQL Required)
# Quick start for development and testing

set -e

GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
MAGENTA='\033[0;35m'
NC='\033[0m'

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
TELEMETRY_DIR="${SCRIPT_DIR}/../telemetry"

echo -e "${CYAN}"
echo "╔════════════════════════════════════════════════════════╗"
echo "║   PHI EXPENDITURE - LOCAL DEPLOYMENT                  ║"
echo "║   SQLite Database | No Docker Required                ║"
echo "╚════════════════════════════════════════════════════════╝"
echo -e "${NC}"

# Create directories
mkdir -p "$TELEMETRY_DIR"
mkdir -p "${SCRIPT_DIR}/data"

# Set environment for SQLite
export EXPENDITURE_DB="sqlite:///${SCRIPT_DIR}/data/expenditures.db"
export FLASK_SECRET_KEY="${FLASK_SECRET_KEY:-$(openssl rand -hex 32)}"
export FLASK_ENV="development"

echo -e "${BLUE}📦 Checking Python dependencies...${NC}"
cd "$SCRIPT_DIR"

# Check if requirements are installed
if ! python3 -c "import flask, sqlalchemy" 2>/dev/null; then
    echo -e "${YELLOW}⚠ Installing Python dependencies...${NC}"
    pip3 install -q flask sqlalchemy openpyxl 2>/dev/null || \
        pip3 install --user -q flask sqlalchemy openpyxl
fi

echo -e "${GREEN}✓ Python dependencies ready${NC}"

echo ""
echo -e "${BLUE}🗄️  Initializing SQLite database...${NC}"

# Create SQLite-compatible init script
cat > "${SCRIPT_DIR}/init_expenditure_database_sqlite.py" <<'INIT_EOF'
#!/usr/bin/env python3
"""Initialize SQLite database for PHI Expenditure Tracking"""

import os
from pathlib import Path
from sqlalchemy import create_engine, text

# Get database URL from environment
db_url = os.environ.get('EXPENDITURE_DB', 'sqlite:///./data/expenditures.db')
print(f"Connecting to: {db_url}")

# Create engine
engine = create_engine(db_url)

# Create tables
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
            vendor_confidence REAL,
            category_confidence REAL,
            ai_metadata TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP,
            updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """))

    # Vendors table
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS vendors (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            name TEXT UNIQUE NOT NULL,
            category TEXT,
            contact_email TEXT,
            contact_phone TEXT,
            notes TEXT,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """))

    # Audit log table
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS audit_log (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            expenditure_id INTEGER,
            action TEXT NOT NULL,
            old_value TEXT,
            new_value TEXT,
            changed_by TEXT NOT NULL,
            changed_at TEXT DEFAULT CURRENT_TIMESTAMP,
            FOREIGN KEY (expenditure_id) REFERENCES expenditures(id)
        )
    """))

    # Recurring expenditures table
    conn.execute(text("""
        CREATE TABLE IF NOT EXISTS recurring_expenditures (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            vendor TEXT NOT NULL,
            amount REAL NOT NULL,
            frequency TEXT NOT NULL,
            category TEXT,
            description TEXT,
            next_date TEXT NOT NULL,
            active INTEGER DEFAULT 1,
            created_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
    """))

    conn.commit()
    print("✓ Database initialized successfully")

print("\n✓ SQLite database ready!")
print(f"  Location: {db_url.replace('sqlite:///', '')}")
INIT_EOF

python3 "${SCRIPT_DIR}/init_expenditure_database_sqlite.py"

echo ""
echo -e "${BLUE}🤖 Testing AI Optimizer...${NC}"
python3 "${SCRIPT_DIR}/phi_expenditure_ai_optimizer.py" --test 2>&1 | grep -E "(Testing|Input|Output|vendor|confidence|verified)" | head -20

echo ""
echo -e "${BLUE}🌐 Starting dashboard...${NC}"

# Kill any existing dashboard
pkill -f "python3.*expenditure_dashboard" 2>/dev/null || true
sleep 1

# Start dashboard in background
nohup python3 "${SCRIPT_DIR}/expenditure_dashboard.py" > "${TELEMETRY_DIR}/dashboard.log" 2>&1 &
DASHBOARD_PID=$!
echo "$DASHBOARD_PID" > "${TELEMETRY_DIR}/dashboard.pid"

echo -e "${YELLOW}⏳ Waiting for dashboard to start...${NC}"
sleep 3

# Check if dashboard is running
if ps -p $DASHBOARD_PID > /dev/null; then
    echo -e "${GREEN}✓ Dashboard started (PID: ${DASHBOARD_PID})${NC}"
else
    echo -e "${YELLOW}⚠ Dashboard may not have started, checking logs...${NC}"
    tail -20 "${TELEMETRY_DIR}/dashboard.log"
fi

echo ""
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo -e "${GREEN}✅ Local Deployment Complete${NC}"
echo -e "${CYAN}━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━${NC}"
echo ""
echo -e "${YELLOW}🌐 Access Points:${NC}"
echo -e "  Dashboard:  ${GREEN}http://localhost:5000${NC}"
echo -e "  Database:   ${GREEN}${SCRIPT_DIR}/data/expenditures.db${NC}"
echo ""
echo -e "${YELLOW}📋 Management Commands:${NC}"
echo -e "  View logs:      ${CYAN}tail -f ${TELEMETRY_DIR}/dashboard.log${NC}"
echo -e "  Stop dashboard: ${CYAN}kill \$(cat ${TELEMETRY_DIR}/dashboard.pid)${NC}"
echo -e "  Check status:   ${CYAN}ps -p \$(cat ${TELEMETRY_DIR}/dashboard.pid)${NC}"
echo -e "  View database:  ${CYAN}sqlite3 ${SCRIPT_DIR}/data/expenditures.db${NC}"
echo ""
echo -e "${YELLOW}🧪 Test Commands:${NC}"
echo -e "  AI Optimizer:   ${CYAN}python3 ${SCRIPT_DIR}/phi_expenditure_ai_optimizer.py --test${NC}"
echo -e "  System Status:  ${CYAN}${SCRIPT_DIR}/phi_expenditure_master_control.sh status${NC}"
echo ""
echo -e "${GREEN}✓ Ready for use!${NC}"
echo ""
