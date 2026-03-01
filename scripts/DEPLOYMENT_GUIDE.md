# PHI Expenditure Tracking System - Deployment Guide

**Status**: COMPLETE ✅  
**Version**: 1.0  
**Date**: February 27, 2026  
**Author**: PHI Chief

---

## 🎯 Quick Start (Development/Testing)

This guide walks through setting up the complete expenditure tracking system on a local machine.

### Prerequisites

- Python 3.9+
- PostgreSQL 13+
- Gmail account with OAuth credentials

### Step 1: Install PostgreSQL

**macOS (via Homebrew):**
```bash
brew install postgresql@14
brew services start postgresql@14
```

**Ubuntu/Debian:**
```bash
sudo apt update
sudo apt install postgresql postgresql-contrib
sudo systemctl start postgresql
```

**Windows:**
Download installer from https://www.postgresql.org/download/windows/

### Step 2: Create Database

```bash
# Connect to PostgreSQL
psql postgres

# Create user and database
CREATE USER phi_admin WITH PASSWORD 'your_secure_password_here';
CREATE DATABASE expenditures OWNER phi_admin;
GRANT ALL PRIVILEGES ON DATABASE expenditures TO phi_admin;
\q
```

### Step 3: Install Python Dependencies

```bash
cd /workspaces/dominion-os-demo-build/scripts

pip install flask sqlalchemy psycopg2-binary google-auth google-auth-oauthlib google-api-python-client cryptography
```

### Step 4: Set Environment Variables

**Linux/macOS:**
```bash
export EXPENDITURE_DB="postgresql://phi_admin:your_secure_password_here@localhost:5432/expenditures"
export FLASK_SECRET_KEY="$(python3 -c 'import secrets; print(secrets.token_hex(32))')"
```

**Windows (PowerShell):**
```powershell
$env:EXPENDITURE_DB="postgresql://phi_admin:your_secure_password_here@localhost:5432/expenditures"
$env:FLASK_SECRET_KEY=(python -c "import secrets; print(secrets.token_hex(32))")
```

### Step 5: Initialize Database

```bash
python3 init_expenditure_database.py
```

**Expected Output:**
```
======================================================================
PHI EXPENDITURE TRACKING SYSTEM - DATABASE INITIALIZATION
======================================================================

📊 Database: postgresql://phi_admin:****@localhost:5432/expenditures

🔌 Connecting to database...
✓ Connected successfully

🏗️  Creating database schema...

✓ All tables created successfully:
  • expenditures
  • expenditure_audit_log
  • vendors
  • recurring_expenditures
  • budget_allocations

📇 Creating indexes for performance...
✓ Indexes created

🔍 Verifying database schema...
  ✓ expenditures: 0 rows
  ✓ expenditure_audit_log: 0 rows
  ✓ vendors: 0 rows
  ✓ recurring_expenditures: 0 rows
  ✓ budget_allocations: 0 rows

======================================================================
✅ DATABASE INITIALIZATION COMPLETE
======================================================================
```

### Step 6: Generate Sample Data (Testing)

```bash
python3 generate_sample_data.py --count 150 --recurring 15
```

**Expected Output:**
```
======================================================================
PHI EXPENDITURE SYSTEM - SAMPLE DATA GENERATOR
======================================================================

🔌 Connecting to database...
✓ Connected

🎲 Generating 150 sample expenditures...

  ✓ Created 20/150 expenditures...
  ✓ Created 40/150 expenditures...
  ... (continues)

✅ Created 150 expenditures

🔄 Generating 15 recurring expenses...

✅ Created 15 recurring expenses

======================================================================
📊 DATABASE SUMMARY
======================================================================

Total Expenditures: 150

By Company:
  • Fractal5 Solutions Inc: 52 (127,345.67 CAD)
  • Blue Wave Action Group Inc: 48 (98,234.12 CAD)
  • Plane4 Grain Inc: 50 (105,678.90 CAD)

Verified: 135
Pending Verification: 15

By Confidence:
  • HIGH: 90
  • MEDIUM: 45
  • LOW: 15

Active Recurring Expenses: 15

======================================================================
✅ SAMPLE DATA GENERATION COMPLETE
======================================================================
```

### Step 7: Launch Dashboard

```bash
python3 expenditure_dashboard.py
```

**Expected Output:**
```
======================================================================
PHI EXPENDITURE TRACKING DASHBOARD
======================================================================

🌐 Starting Flask server...
   Local:   http://localhost:5000
   Network: http://0.0.0.0:5000

📊 Available routes:
   /                - Dashboard home
   /expenditures    - Expenditure list
   /verify          - Human verification
   /reports         - Reports & exports
   /recurring       - Recurring expenses

Press Ctrl+C to stop
======================================================================
 * Running on all addresses (0.0.0.0)
 * Running on http://127.0.0.1:5000
 * Running on http://192.168.1.100:5000
```

### Step 8: Access Dashboard

Open browser to **http://localhost:5000**

---

## 🔐 Gmail OAuth Setup (Production)

To extract expenditure data from Gmail, configure OAuth 2.0 credentials:

### 1. Create Google Cloud Project

1. Go to https://console.cloud.google.com
2. Create new project: "PHI Expenditure Tracker"
3. Enable Gmail API:
   - Navigation Menu → APIs & Services → Library
   - Search "Gmail API"
   - Click "Enable"

### 2. Create OAuth Credentials

1. APIs & Services → Credentials
2. Click "+ CREATE CREDENTIALS" → OAuth client ID
3. Application type: Desktop app
4. Name: "PHI Expenditure Extractor"
5. Click "Create"
6. Download JSON file as `credentials.json`

### 3. Configure Extractor

```bash
# Place credentials in config directory
mkdir -p config/gmail_oauth
mv ~/Downloads/credentials.json config/gmail_oauth/

# Set environment variable
export GMAIL_CREDENTIALS_PATH="config/gmail_oauth/credentials.json"
```

### 4. First Run (Authorization)

```bash
python3 phi_expenditure_extractor.py
```

This will:
- Open browser for OAuth consent
- Request Gmail read permissions
- Generate `token.json` for future use
- Extract expenditures from Gmail

---

## 📊 Dashboard Features

### 1. **Main Dashboard** (`/`)
- Current month spending & YTD totals
- Category breakdown (doughnut chart)
- Company comparison (bar chart)
- Top 10 vendors by spending
- Verification status overview

### 2. **Expenditures List** (`/expenditures`)
- Filterable table (date, company, category, verified status)
- Detail modal with full expenditure info
- CSV export button
- Pagination support

### 3. **Verification Queue** (`/verify`)
- Human review interface for LOW confidence extractions
- Sorted by amount (high-value first)
- One-click verify or edit before verifying
- Real-time pending count

### 4. **Reports** (`/reports`)
- **Category Report**: Spending breakdown by category
- **Monthly Trend**: 12-month spending analysis
- **CSV Export**: Download filtered data
- **QuickBooks Export**: IIF format for accounting import

### 5. **Recurring Expenses** (`/recurring`)
- All active subscriptions
- Due-soon alerts (within 7 days)
- Total monthly cost calculation
- Auto-renew indicators

---

## 💾 Export Formats

### CSV Export
- All key fields included (date, vendor, amount, category, etc.)
- Compatible with Excel/Google Sheets
- Proper date/currency formatting

**Usage:**
1. Go to Reports or Expenditures page
2. Select date range and company filter
3. Click "CSV" export button
4. File downloads automatically

### QuickBooks IIF Export
- Intuit Interchange Format for QuickBooks Desktop
- Creates CHECK transactions with proper splits
- Includes tax amounts in separate split lines
- Maps categories to QuickBooks expense accounts

**Usage:**
1. Go to Reports page
2. Select date range and company filter
3. Click "QuickBooks IIF" button
4. Import IIF file into QuickBooks Desktop

---

## 🔧 Troubleshooting

### Database Connection Errors

**Error:** `could not connect to server`

**Solutions:**
- Verify PostgreSQL is running: `pg_isready`
- Check connection string environment variable
- Ensure firewall allows port 5432
- Test connection: `psql $EXPENDITURE_DB`

### Gmail OAuth Errors

**Error:** `invalid_grant: Token has been expired or revoked`

**Solutions:**
- Delete `token.json`
- Re-run extractor to re-authorize
- Check OAuth consent screen settings
- Ensure Gmail API is enabled

### Dashboard Not Loading Data

**Error:** Dashboard shows "No data" or loading spinner indefinitely

**Solutions:**
- Verify database contains data: `python3 -c "from expenditure_models import *; db = ExpenditureDatabase(os.environ['EXPENDITURE_DB']); print(db.get_expenditure_count())"`
- Check browser console for JavaScript errors
- Verify Flask server is running without errors
- Check database connection in server logs

### Export Not Working

**Error:** Export button downloads empty file or shows 500 error

**Solutions:**
- Check Flask server logs for Python errors
- Verify date range contains data
- Ensure `expenditure_exports` module is imported correctly
- Test export programmatically: `from expenditure_exports import *; ...`

---

## 🚀 Production Deployment

### Option 1: Docker Container

**Dockerfile:**
```dockerfile
FROM python:3.11-slim

WORKDIR /app

COPY scripts/requirements.txt .
RUN pip install --no-cache-dir -r requirements.txt

COPY scripts/ .

EXPOSE 5000

CMD ["gunicorn", "--bind", "0.0.0.0:5000", "--workers", "4", "expenditure_dashboard:app"]
```

**Build & Run:**
```bash
docker build -t phi-expenditure-dashboard .
docker run -d -p 5000:5000 \
  -e EXPENDITURE_DB="postgresql://..." \
  -e FLASK_SECRET_KEY="..." \
  phi-expenditure-dashboard
```

### Option 2: Systemd Service (Linux)

**Service File:** `/etc/systemd/system/phi-expenditure.service`
```ini
[Unit]
Description=PHI Expenditure Dashboard
After=network.target postgresql.service

[Service]
Type=simple
User=phi
WorkingDirectory=/opt/phi-expenditure/scripts
Environment="EXPENDITURE_DB=postgresql://..."
Environment="FLASK_SECRET_KEY=..."
ExecStart=/usr/bin/python3 expenditure_dashboard.py
Restart=always

[Install]
WantedBy=multi-user.target
```

**Enable & Start:**
```bash
sudo systemctl daemon-reload
sudo systemctl enable phi-expenditure
sudo systemctl start phi-expenditure
sudo systemctl status phi-expenditure
```

### Option 3: Cloud Deployment (Google Cloud Run)

**Deploy Command:**
```bash
gcloud run deploy phi-expenditure \
  --source . \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars EXPENDITURE_DB="postgresql://..." \
  --set-env-vars FLASK_SECRET_KEY="..."
```

---

## 📈 Performance Optimization

### Database Indexes
All recommended indexes are created automatically by `init_expenditure_database.py`:
- Date range queries: `idx_expenditures_date`
- Company filtering: `idx_expenditures_company`
- Category analysis: `idx_expenditures_category`
- Verification workflow: `idx_expenditures_verified_confidence`

### Caching (Future Enhancement)
Consider adding Redis for:
- Dashboard summary statistics (5-minute cache)
- Top vendors list (15-minute cache)
- Monthly trend data (1-hour cache)

### Pagination
API endpoints support `limit` parameter:
```
GET /api/expenditures?limit=50&offset=0
```

---

## 🔒 Security Considerations

### Production Checklist
- [ ] Change default `FLASK_SECRET_KEY` to random 32-byte value
- [ ] Enable HTTPS with SSL certificate (Let's Encrypt)
- [ ] Use strong PostgreSQL password (20+ characters)
- [ ] Restrict database access to localhost or VPN
- [ ] Add authentication system (OAuth, LDAP, or JWT)
- [ ] Enable Flask session security:
  ```python
  app.config['SESSION_COOKIE_SECURE'] = True  # HTTPS only
  app.config['SESSION_COOKIE_HTTPONLY'] = True
  app.config['SESSION_COOKIE_SAMESITE'] = 'Strict'
  ```
- [ ] Add rate limiting for API endpoints
- [ ] Enable audit logging for all verification actions
- [ ] Encrypt credentials.json and token.json

---

## 📞 Support & Maintenance

### Database Backups
```bash
# Backup database
pg_dump $EXPENDITURE_DB > expenditures_backup_$(date +%Y%m%d).sql

# Restore database
psql $EXPENDITURE_DB < expenditures_backup_20260227.sql
```

### Logs
- Flask logs: stdout (redirect to file: `python3 expenditure_dashboard.py > logs/dashboard.log 2>&1`)
- PostgreSQL logs: `/var/log/postgresql/postgresql-14-main.log`
- Gmail extractor logs: stdout (use `>> logs/extractor.log`)

### Monitoring
- Check dashboard health: `curl http://localhost:5000/`
- Database connection test: `psql $EXPENDITURE_DB -c "SELECT 1;"`
- Disk space: `df -h`
- PostgreSQL connections: `SELECT count(*) FROM pg_stat_activity;`

---

## 🎓 Next Steps

1. **Phase 1** (Week 1): Local testing with sample data
2. **Phase 2** (Week 2): Gmail OAuth setup + first real extraction
3. **Phase 3** (Week 3): Verify 50+ expenditures, refine categories
4. **Phase 4** (Week 4): Production deployment with HTTPS
5. **Phase 5** (Month 2): Automated daily extraction cron job
6. **Phase 6** (Month 3): Excel export + budget variance tracking

---

**Documentation Version**: 1.0  
**Last Updated**: February 27, 2026  
**Prepared by**: PHI Chief, Dominion OS
