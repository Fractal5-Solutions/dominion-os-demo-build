# PHI Expenditure Dashboard - Quick Start Guide

## Overview

The PHI Expenditure Dashboard is a web-based interface for viewing, verifying, and reporting on financial data extracted from Gmail and cloud storage.

**Tech Stack**: Flask (Python) + Bootstrap 5 + Chart.js

---

## Installation

### 1. Install Dependencies

```bash
pip install flask sqlalchemy psycopg2-binary
```

### 2. Configure Database

Set the database connection string:

```bash
export EXPENDITURE_DB="postgresql://phi_admin:password@localhost:5432/expenditures"
```

Or update `expenditure_dashboard.py` line 35.

### 3. Run Dashboard

```bash
python3 expenditure_dashboard.py
```

Access at: **http://localhost:5000**

---

## Features

### 📊 Dashboard (`/`)
- **Current Month** spending total & count
- **Year-to-Date** total & verification status
- **Category Breakdown** - Doughnut chart showing spending by category
- **Company Split** - Bar chart comparing spend across companies
- **Top 10 Vendors** - Table with amounts and percentages

### 📋 Expenditures List (`/expenditures`)
- **Filterable Table** - Search by date range, company, category, verification status
- **Detail View** - Click any expenditure to see full details (invoice #, tax, source, audit trail)
- **Export Options** - CSV download (coming soon)

### ✅ Verification Queue (`/verify`)
- **Human Review** - LOW confidence extractions shown first, sorted by amount
- **One-Click Verify** - Approve expenditures with single button click
- **Edit Before Verify** - Update fields if AI extraction was incorrect

### 📈 Reports (`/reports`)
- **Category Report** - Spending breakdown by category with top items
- **Monthly Trend** - 12-month line chart with transaction counts
- **Export Formats** - CSV, Excel, QuickBooks IIF (coming soon)

### 🔄 Recurring Expenses (`/recurring`)
- **Subscription Tracker** - All active recurring expenditures
- **Due Soon Alerts** - Highlight subscriptions due within 7 days
- **Monthly Cost** - Calculate total monthly subscription costs

---

## API Endpoints

### GET `/api/summary`
Dashboard summary statistics
- Returns: current_month, ytd, top_vendors, by_category, by_company, verification

### GET `/api/expenditures`
List expenditures with filters
- Params: `start_date`, `end_date`, `company`, `category`, `verified`, `limit`
- Returns: Array of expenditure objects

### GET `/api/expenditures/<id>`
Get detailed expenditure information
- Returns: Full expenditure object with all fields

### GET `/api/pending_verification`
Get expenditures requiring human verification
- Returns: Array of unverified LOW confidence expenditures

### POST `/api/verify/<id>`
Mark expenditure as verified
- Body: `{"verified_by": "Matthew Dillon", "updates": {}}`
- Returns: Success confirmation

### GET `/api/report/category`
Category spending report
- Params: `start_date`, `end_date`, `company`
- Returns: Categories with totals, counts, averages

### GET `/api/report/monthly_trend`
Monthly spending trend (last 12 months)
- Params: `company`
- Returns: Monthly data with totals and counts

### GET `/api/recurring`
Get active recurring expenditures
- Returns: Array of recurring expenses with monthly total

---

## File Structure

```
scripts/
├── expenditure_dashboard.py          # Flask app (main server)
├── expenditure_models.py              # Database models
├── phi_expenditure_extractor.py      # Gmail extraction engine
└── templates/                         # HTML templates
    ├── dashboard.html                 # Main dashboard
    ├── expenditures.html              # Expenditure list
    ├── verify.html                    # Verification queue
    ├── reports.html                   # Reports & exports
    └── recurring.html                 # Recurring expenses
```

---

## Usage Examples

### View Current Month Spending
1. Navigate to http://localhost:5000
2. See "Current Month" card with total and transaction count
3. View category breakdown in doughnut chart

### Verify Pending Expenditures
1. Go to **Verify** tab
2. Review LOW confidence extractions (sorted by amount)
3. Click **Verify** to approve
4. Card animates away and pending count decreases

### Generate Category Report
1. Go to **Reports** tab
2. Click **Generate** under "Category Report"
3. View table with totals, counts, percentages
4. See top 5 items per category

### Export to QuickBooks
1. Go to **Reports** > **Export Data**
2. Select date range and company
3. Click **QuickBooks IIF**
4. Download file for import into QuickBooks

---

## Configuration

### Environment Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `EXPENDITURE_DB` | PostgreSQL connection string | `postgresql://phi_admin:secure_password@localhost:5432/expenditures` |
| `FLASK_SECRET_KEY` | Flask session secret | `phi-dominion-os-2026` |
| `FLASK_ENV` | Development/production mode | `development` |

### Database Setup

Before running the dashboard, create database tables:

```python
from expenditure_models import ExpenditureDatabase

db = ExpenditureDatabase("postgresql://...")
db.create_tables()
```

---

## Development

### Run in Debug Mode

```bash
export FLASK_ENV=development
python3 expenditure_dashboard.py
```

Debug mode enables:
- Auto-reload on file changes
- Detailed error messages
- Interactive debugger

### Add Custom Routes

Edit `expenditure_dashboard.py` and add new Flask routes:

```python
@app.route('/custom')
def custom_page():
    return render_template('custom.html')
```

### Customize Charts

Charts use Chart.js. Edit templates and modify chart options:

```javascript
new Chart(canvas, {
    type: 'line',
    data: { labels: [...], datasets: [...] },
    options: { responsive: true, ... }
});
```

---

## Security

### Production Deployment

1. **Change SECRET_KEY**: Generate secure random key
   ```bash
   export FLASK_SECRET_KEY=$(python3 -c "import secrets; print(secrets.token_hex(32))")
   ```

2. **Enable HTTPS**: Use reverse proxy (nginx) with SSL certificate

3. **Add Authentication**: Implement login system with sessions

4. **Set Database Password**: Use strong PostgreSQL password

5. **Restrict Network Access**: Firewall rules for database port

### Access Control

Currently, the dashboard has no authentication. In production:
- Add login page with username/password
- Implement session management
- Restrict `/verify` route to Matthew only
- Add role-based permissions (admin, viewer)

---

## Troubleshooting

### Database Connection Error
```
Error: could not connect to server
```
**Solution**: Check PostgreSQL is running and connection string is correct

### Templates Not Found
```
Error: TemplateNotFound: dashboard.html
```
**Solution**: Ensure `templates/` directory exists in same folder as `expenditure_dashboard.py`

### Charts Not Rendering
**Solution**: Check browser console for JavaScript errors. Ensure Chart.js CDN is accessible.

### No Data Showing
**Solution**: Run `phi_expenditure_extractor.py` first to populate database with expenditures

---

## Next Steps

1. **Phase 1**: Configure Gmail OAuth and extract first batch of invoices
2. **Phase 2**: Populate database with 100+ expenditures for testing
3. **Phase 3**: Add authentication system for production deployment
4. **Phase 4**: Implement CSV/Excel/QuickBooks export functions
5. **Phase 5**: Deploy to cloud server (Google Cloud Run or Azure App Service)

---

## Support

- **Documentation**: [PHI_EXPENDITURE_IMPLEMENTATION_REPORT.md](PHI_EXPENDITURE_IMPLEMENTATION_REPORT.md)
- **Source Code**: `/workspaces/dominion-os-demo-build/scripts/`
- **Contact**: PHI Chief via Dominion OS CLI

---

**Status**: IMPLEMENTATION READY  
**Version**: 1.0  
**Last Updated**: February 27, 2026
