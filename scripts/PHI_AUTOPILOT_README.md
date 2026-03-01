# PHI Expenditure System - Full Autopilot Mode

## 🚀 Overview

The PHI Expenditure Tracking System is now fully autonomous with:
- **Continuous Gmail ingestion** - Automated extraction every hour
- **AI-optimized pipeline** - Intelligent categorization, vendor normalization, confidence scoring
- **Health monitoring** - Auto-restart on failure
- **Multi-deployment support** - Local, Docker, Systemd, Cloud Run

## 🎯 Quick Start - Deploy Autopilot

### Option 1: One-Command Deploy (Recommended)
```bash
./scripts/phi_expenditure_master_control.sh deploy local 3600
```

This will:
1. ✅ Check all dependencies (Python, PostgreSQL, packages)
2. ✅ Initialize database with tables and indexes
3. ✅ Configure AI optimization features
4. ✅ Start continuous ingestion service (every hour)
5. ✅ Deploy dashboard on http://localhost:5000
6. ✅ Start health monitoring with auto-restart

### Option 2: Step-by-Step

```bash
# 1. Set environment variables
export EXPENDITURE_DB="postgresql://phi_admin:your_password@localhost:5432/expenditures"
export FLASK_SECRET_KEY=$(openssl rand -hex 32)

# 2. Initialize database
python3 scripts/init_expenditure_database.py

# 3. Generate sample data (optional, for testing)
python3 scripts/generate_sample_data.py --count 150

# 4. Deploy autopilot
./scripts/phi_expenditure_master_control.sh deploy local 3600
```

## 📡 Master Control Commands

The master control script provides complete system management:

```bash
# Deployment
./scripts/phi_expenditure_master_control.sh deploy <mode> <interval> <ai_opt>
  # Modes: local, docker, systemd, cloud-run
  # Interval: seconds between ingestion cycles (default: 3600 = 1 hour)
  # AI opt: enabled or disabled (default: enabled)

# Service Management
./scripts/phi_expenditure_master_control.sh start      # Start all services
./scripts/phi_expenditure_master_control.sh stop       # Stop all services
./scripts/phi_expenditure_master_control.sh restart    # Restart all services

# Monitoring
./scripts/phi_expenditure_master_control.sh status     # System status
./scripts/phi_expenditure_master_control.sh health     # Health check
./scripts/phi_expenditure_master_control.sh logs       # Tail all logs
./scripts/phi_expenditure_master_control.sh stats      # Operational stats

# Maintenance
./scripts/phi_expenditure_master_control.sh test       # Run tests
./scripts/phi_expenditure_master_control.sh cleanup    # Clean and stop
```

## 🤖 AI-Optimized Pipeline Features

### 1. Vendor Normalization
- Fuzzy matching for vendor names
- Automatic consolidation (e.g., "Google Cloud", "GCP", "G Suite" → "Google")
- Confidence scoring for normalization accuracy

### 2. Category Prediction
- Pattern-based categorization using keywords and known vendors
- Categories: Cloud Services, Software Subscriptions, Marketing, Professional Services, Office & Facilities, Telecommunications, Insurance, Domain & Hosting, Payment Processing, Development Tools
- Confidence threshold: 85% for auto-categorization

### 3. Confidence Tuning
- Multi-factor confidence scoring (vendor, amount, date, description, invoice)
- Three levels: HIGH (≥90%), MEDIUM (≥70%), LOW (<70%)
- **Auto-verification** for HIGH confidence items (no human review needed)

### 4. Amount Validation
- Outlier detection using IQR (Interquartile Range)
- Reasonable range validation (0 < amount < $1,000,000)
- Historical comparison when data available

### 5. Tax Calculation
- Auto-detect region and apply correct tax rate
- Canadian provinces supported (HST, PST+GST, QST+GST, GST)
- Default: 13% HST (Ontario)

## 📊 Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                     MASTER CONTROL                              │
│            phi_expenditure_master_control.sh                    │
└─────────────────────┬───────────────────────────────────────────┘
                      │
        ┌─────────────┼─────────────┬─────────────────┐
        │             │             │                 │
        ▼             ▼             ▼                 ▼
┌───────────────┐ ┌──────────┐ ┌──────────────┐ ┌──────────────┐
│   DASHBOARD   │ │ INGESTION│ │ HEALTH MON.  │ │ AI OPTIMIZER │
│   Flask App   │ │  Service │ │   Auto-      │ │  Pipeline    │
│   :5000       │ │  Hourly  │ │   Restart    │ │  Features    │
└───────┬───────┘ └────┬─────┘ └──────┬───────┘ └──────┬───────┘
        │              │               │                │
        │              ▼               │                │
        │       ┌──────────────┐       │                │
        │       │ Gmail API    │       │                │
        │       │ Extractor    │◄──────┼────────────────┘
        │       └──────┬───────┘       │
        │              │               │
        └──────────────┼───────────────┘
                       │
                       ▼
              ┌────────────────┐
              │  PostgreSQL    │
              │  Database      │
              │  expenditures  │
              └────────────────┘
```

## 🔄 Continuous Ingestion

The system runs continuous extraction cycles:

1. **Every N seconds** (configurable, default: 3600 = 1 hour)
2. **Gmail API scan** - Search for invoices, receipts, bills
3. **AI optimization** - Apply vendor normalization, category prediction, confidence scoring
4. **Database insert** - Store with metadata and confidence levels
5. **Auto-verify** - HIGH confidence items verified automatically
6. **Log metrics** - Track success rate, processing time, error count

### Ingestion Logs
```bash
# View real-time ingestion activity
tail -f telemetry/ingestion.log

# Check last ingestion status
cat telemetry/last_ingestion.json
```

## 💓 Health Monitoring

Auto-restart on failure ensures 24/7 uptime:

```bash
# Health check runs every 60 seconds
# Components monitored:
#   - PostgreSQL database connection
#   - Dashboard HTTP endpoint
#   - Ingestion service process

# If unhealthy -> automatic restart
# Logs all actions to telemetry/health_monitor.log
```

### View Health Status
```bash
./scripts/phi_expenditure_master_control.sh health

# Output includes:
# - Component status (healthy/unhealthy/stopped)
# - Last check timestamp
# - Uptime metrics
# - Processing statistics
```

## 🎛️ Configuration

### AI Optimization Config
Location: `scripts/ai_optimization_config.json`

```json
{
  "enabled": true,
  "features": {
    "confidence_tuning": {
      "enabled": true,
      "thresholds": {"high": 0.9, "medium": 0.7, "low": 0.5},
      "auto_verify_high": true
    },
    "category_prediction": {
      "enabled": true,
      "confidence_threshold": 0.85
    },
    "vendor_normalization": {
      "enabled": true,
      "fuzzy_matching": true
    },
    "amount_validation": {
      "enabled": true,
      "outlier_detection": true
    },
    "tax_calculation": {
      "enabled": true,
      "default_rate": 0.13
    }
  }
}
```

### Ingestion Interval

```bash
# Every 30 minutes
./scripts/phi_expenditure_master_control.sh deploy local 1800

# Every 2 hours
./scripts/phi_expenditure_master_control.sh deploy local 7200

# Every 15 minutes (aggressive)
./scripts/phi_expenditure_master_control.sh deploy local 900
```

## 🐳 Docker Deployment

```bash
# Deploy with Docker
./scripts/phi_expenditure_master_control.sh deploy docker 3600

# Manually run Docker
docker build -t phi-expenditure -f scripts/Dockerfile.expenditure scripts/
docker run -d -p 5000:5000 \
  -e EXPENDITURE_DB="postgresql://..." \
  -e FLASK_SECRET_KEY="..." \
  phi-expenditure
```

## ⚙️ Systemd Service

```bash
# Generate systemd service file
./scripts/phi_expenditure_master_control.sh deploy systemd

# Then install:
sudo mv /tmp/phi-expenditure.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable phi-expenditure
sudo systemctl start phi-expenditure

# Manage with systemctl
sudo systemctl status phi-expenditure
sudo systemctl restart phi-expenditure
sudo journalctl -u phi-expenditure -f
```

## ☁️ Google Cloud Run

```bash
# Deploy to Cloud Run
gcloud run deploy phi-expenditure-dashboard \
  --source scripts/ \
  --platform managed \
  --region us-central1 \
  --allow-unauthenticated \
  --set-env-vars EXPENDITURE_DB="postgresql://..." \
  --set-env-vars FLASK_SECRET_KEY="..."
```

## 📈 Operational Statistics

View real-time stats:

```bash
./scripts/phi_expenditure_master_control.sh stats

# Shows:
# - Total expenditures and verification status
# - Confidence level distribution (HIGH/MEDIUM/LOW)
# - Top 10 vendors by spending
# - Recent activity (last 7 days)
# - Average amounts by confidence level
```

## 🎮 Dashboard Access

Once deployed, access the dashboard at:
```
http://localhost:5000
```

### Pages:
- **Dashboard** - Summary stats, charts, top vendors
- **Expenditures** - Search, filter, view details, export CSV
- **Verify Queue** - Pending LOW confidence items
- **Reports** - Category breakdown, monthly trends, exports (CSV, QuickBooks)
- **Recurring** - Subscriptions and recurring expenses

## 🗂️ Telemetry Files

All logs and status files stored in `telemetry/`:

```
telemetry/
├── expenditure_autopilot.log      # Master autopilot log
├── expenditure_health.json        # Current health status
├── expenditure_status.json        # Deployment status
├── dashboard.log                  # Flask dashboard logs
├── dashboard.pid                  # Dashboard process ID
├── ingestion.log                  # Extraction logs
├── ingestion.pid                  # Ingestion process ID
├── ingestion_service.log          # Service wrapper logs
├── health_monitor.log             # Health check logs
├── health_monitor.pid             # Health monitor process ID
├── health_status.json             # Detailed health data
└── last_ingestion.json            # Last extraction status
```

## 🔒 Security Considerations

For production deployment:

1. **Change default credentials**
   ```bash
   export EXPENDITURE_DB="postgresql://secure_user:strong_password@localhost/expenditures"
   export FLASK_SECRET_KEY=$(openssl rand -hex 32)
   ```

2. **Enable HTTPS** - Use reverse proxy (nginx, Caddy) or Cloud Run

3. **Add authentication** - Implement login system (OAuth, LDAP, JWT)

4. **Rate limiting** - Install flask-limiter for API protection

5. **Restrict database** - Firewall rules, localhost-only, VPN access

6. **Encrypt credentials** - Gmail OAuth token.json should have 600 permissions

7. **Regular backups**
   ```bash
   pg_dump $EXPENDITURE_DB > backup_$(date +%Y%m%d).sql
   ```

## 🛠️ Troubleshooting

### Dashboard not starting
```bash
# Check logs
tail -f telemetry/dashboard.log

# Verify database connection
psql "$EXPENDITURE_DB" -c "SELECT 1"

# Restart
./scripts/phi_expenditure_master_control.sh restart
```

### Ingestion not working
```bash
# Check Gmail OAuth
ls -la scripts/token.json

# Re-authorize if needed
python3 scripts/phi_expenditure_extractor.py

# Check logs
tail -f telemetry/ingestion.log
```

### Health monitor not restarting services
```bash
# Check health monitor status
cat telemetry/health_status.json | jq

# Restart health monitor
./scripts/phi_expenditure_master_control.sh stop
./scripts/phi_expenditure_master_control.sh start
```

## 📚 Related Documentation

- `DEPLOYMENT_GUIDE.md` - Detailed deployment instructions
- `DASHBOARD_QUICKSTART.md` - Dashboard usage guide
- `PHI_EXPENDITURE_IMPLEMENTATION_REPORT.md` - System architecture

## 🎯 Next Steps

1. **Deploy locally** - Test with sample data
   ```bash
   ./scripts/phi_expenditure_master_control.sh deploy local 3600
   ```

2. **Configure Gmail OAuth** - Enable real extraction
   ```bash
   python3 scripts/phi_expenditure_extractor.py
   ```

3. **Verify first extraction** - Check dashboard at http://localhost:5000/verify

4. **Monitor health** - Watch logs and health status
   ```bash
   ./scripts/phi_expenditure_master_control.sh logs
   ```

5. **Production deployment** - Move to Docker or Cloud Run when ready

## 🤝 Support

For issues or questions:
- Check logs in `telemetry/`
- Run system tests: `./scripts/phi_expenditure_master_control.sh test`
- View status: `./scripts/phi_expenditure_master_control.sh status`

---

**PHI Chief - Autonomous Financial Intelligence Platform**
*No Human In The Loop (NHITL) Mode Operational* 🚀
