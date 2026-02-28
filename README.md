# Dominion OS Demo - Expenditure Dashboard

**Production-grade Flask application for financial expenditure tracking and visualization**

[![Cloud Build](https://img.shields.io/badge/build-passing-brightgreen)](https://console.cloud.google.com/cloud-build)
[![Cloud Run](https://img.shields.io/badge/Cloud%20Run-deployed-blue)](https://dominion-demo-service-reduwyf2ra-uc.a.run.app)
[![Python](https://img.shields.io/badge/python-3.12-blue)](https://www.python.org/)

## 🚀 Live Demo

**Service URL**: https://dominion-demo-service-reduwyf2ra-uc.a.run.app

The application runs in **DEMO_MODE** by default, providing sample data for demonstration purposes without requiring database setup.

## 📋 Features

- **Dashboard**: Real-time expenditure summaries with category breakdowns
- **Transaction Management**: View, filter, and verify expenditures
- **Reporting**: Monthly trends and category analysis
- **Recurring Tracking**: Monitor subscription and recurring expenses
- **Demo Mode**: Built-in sample data for testing and demonstrations
- **Cloud-Native**: Optimized for Google Cloud Run with auto-scaling

## 🏗️ Architecture

- **Backend**: Flask 3.1.3 + Gunicorn WSGI server (4 workers, 2 threads)
- **Database**: PostgreSQL with SQLAlchemy ORM (optional with demo mode)
- **Frontend**: Bootstrap 5 + Chart.js for visualizations
- **Container**: Docker multi-stage builds for minimal image size
- **Cloud**: Google Cloud Run Gen2 with Cloud Build CI/CD
- **Resource Config**: 4Gi memory, 2 CPU, 1-100 autoscaling

## 🛠️ Quick Start

### Prerequisites

- Python 3.12+
- Docker (for containerized deployment)
- Google Cloud SDK (for cloud deployment)

### Local Development

```bash
# Install dependencies
pip install -r requirements.txt

# Run in demo mode (no database required)
export DEMO_MODE=true
python scripts/expenditure_dashboard.py

# Access at http://localhost:5000
```

### Docker

```bash
# Build
docker build -t dominion-demo .

# Run
docker run -p 8080:8080 -e DEMO_MODE=true dominion-demo

# Access at http://localhost:8080
```

### Cloud Deployment

See [CLOUD_DEPLOYMENT_QUICKREF.md](CLOUD_DEPLOYMENT_QUICKREF.md) for detailed deployment instructions.

```bash
# Deploy to Cloud Run via Cloud Build
cd /workspaces/dominion-os-demo-build
gcloud builds submit --config=cloudbuild.yaml

# Or use direct deployment
gcloud run deploy dominion-demo-service \
  --source . \
  --region us-central1 \
  --memory 4Gi \
  --cpu 2
```

## ⚙️ Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `DEMO_MODE` | `true` | Enable demo mode with sample data |
| `EXPENDITURE_DB` | (local postgres) | PostgreSQL connection string |
| `FLASK_SECRET_KEY` | (auto-generated) | Flask session secret key |
| `PORT` | `8080` | Server port (Cloud Run uses 8080) |
| `WORKERS` | `4` | Gunicorn worker processes |
| `THREADS` | `2` | Threads per worker |
| `TIMEOUT` | `300` | Request timeout in seconds |
| `PROJECT_ID` | - | GCP project ID (auto-set in Cloud Run) |
| `REGION` | - | GCP region (auto-set in Cloud Run) |

See [.env.example](.env.example) for a complete configuration template.

### Demo Mode

When `DEMO_MODE=true` (default), the application:
- ✅ Generates realistic sample expenditure data
- ✅ Returns mock summaries and reports with ~$523K annual spend
- ✅ Works without database configuration
- ✅ Displays sample vendors (AWS, Microsoft, Google Cloud, GitHub, etc.)
- ✅ Shows expenditures across 3 companies with various categories

**Perfect for**: Demonstrations, testing, development, and POC scenarios

### Production Mode

To use with a real PostgreSQL database:

```bash
export DEMO_MODE=false
export EXPENDITURE_DB="postgresql://user:pass@host:5432/dbname"
export FLASK_SECRET_KEY="your-secure-secret-key"
python scripts/expenditure_dashboard.py
```

## 📁 Project Structure

```
dominion-os-demo-build/
├── scripts/
│   ├── expenditure_dashboard.py    # Main Flask application (858 lines)
│   ├── expenditure_models.py       # SQLAlchemy ORM models
│   ├── expenditure_exports.py      # CSV/QuickBooks export
│   ├── init_expenditure_database.py # Database initialization
│   ├── phi_expenditure_ai_optimizer.py # AI optimization
│   ├── phi_expenditure_extractor.py # Data extraction
│   └── generate_sample_data.py     # Test data generator
├── templates/                       # Jinja2 HTML templates
│   ├── dashboard.html              # Main dashboard
│   ├── expenditures.html           # Transaction list
│   ├── recurring.html              # Recurring expenses
│   ├── reports.html                # Reports & exports
│   └── verify.html                 # Human verification
├── Dockerfile                       # Multi-stage production build
├── cloudbuild.yaml                 # Cloud Build CI/CD pipeline
├── skaffold.yaml                   # Skaffold dev workflow
├── requirements.txt                # Python dependencies
├── .gitignore                      # Git exclusions
├── .gcloudignore                   # Cloud Build exclusions
└── README.md                       # This file
```

## 🔐 Security

- ✅ Non-root container user (`dominion:dominion`)
- ✅ Multi-stage Docker builds for minimal attack surface
- ✅ No hardcoded secrets in production deployment
- ✅ Environment variable configuration for sensitive data
- ✅ Health checks and monitoring
- ✅ Security scanning via GitHub Actions workflow
- ⚠️ Default development password in code (bypassed by DEMO_MODE)
- ⚠️ Set `FLASK_SECRET_KEY` via environment for production

## 📊 API Endpoints

### Summary & Dashboard
- `GET /` - Main dashboard HTML view
- `GET /api/summary` - Dashboard statistics (monthly, YTD, categories)
- `GET /health` - Health check endpoint (returns status, demo_mode, db_available)

### Expenditures
- `GET /api/expenditures` - List expenditures with filters (`limit`, `category`, `verified`)
- `GET /api/expenditures/<id>` - Get expenditure detail
- `POST /api/expenditures/<id>/verify` - Mark as human verified
- `GET /api/pending_verification` - Items pending review

### Reports
- `GET /api/report/category` - Category spending breakdown
- `GET /api/report/monthly_trend` - 12-month trend analysis
- `GET /api/recurring` - Recurring expenditures

### HTML Views
- `GET /expenditures` - Expenditure list page
- `GET /verify` - Human verification interface
- `GET /reports` - Reports & exports page
- `GET /recurring` - Recurring expenses page

## 🧪 Testing

```bash
# Python syntax validation
python -m py_compile scripts/*.py

# Code quality (if installed)
pylint scripts/*.py
black scripts/*.py --check

# Docker build test
docker build -t dominion-demo-test .

# Local smoke test
curl -I http://localhost:8080/health
```

## 📈 Monitoring

The application includes:
- **Health Check**: `/health` endpoint (status, demo_mode, db availability)
- **Structured Logging**: JSON logs to stdout/stderr
- **Cloud Run Metrics**: Request count, latency, errors, instance count
- **Gunicorn Access Logs**: HTTP request logging
- **Error Tracking**: Exception logging with stack traces

View logs:
```bash
gcloud run services logs read dominion-demo-service \
  --region us-central1 \
  --limit 100
```

## 🚢 Deployment History

| Revision | Status | Build ID | Timestamp | Notes |
|----------|--------|----------|-----------|-------|
| 00009-ftf | ✅ Active | 027e4650 | 2026-02-28 18:48 | Demo mode implementation |
| 00008-r2n | ✅ Success | b829d413 | 2026-02-28 | Fixed Python syntax errors |
| 00007-xxx | ✅ Success | various | 2026-02-28 | SQLAlchemy metadata fixes |
| 00001-006 | ❌ Failed | various | 2026-02-28 | Initial deployment iterations |

**Current Status**: ✅ Production Ready - All 16 build iterations completed successfully

## 📝 Additional Documentation

- [CLOUD_DEPLOYMENT_QUICKREF.md](CLOUD_DEPLOYMENT_QUICKREF.md) - Cloud deployment guide
- [OPTIMIZATION_COMPLETE.md](OPTIMIZATION_COMPLETE.md) - Build optimization summary
- [DEPLOYMENT_GUIDE.md](scripts/DEPLOYMENT_GUIDE.md) - Detailed deployment steps
- [PHI_EXPENDITURE_IMPLEMENTATION_REPORT.md](scripts/PHI_EXPENDITURE_IMPLEMENTATION_REPORT.md) - Implementation details

## 🤝 Contributing

This is a production demonstration project for Fractal5 Solutions.

**Branch Strategy**:
- `main` - Production-ready code
- `sovereign-power-mode-max` - Active development branch (current)

## 📄 License

Proprietary - Fractal5 Solutions © 2026

## 👥 Team

Developed by Fractal5 Solutions
- **Project**: Dominion OS
- **Component**: Expenditure Dashboard Demo
- **Repository**: Fractal5-Solutions/dominion-os-demo-build
- **Branch**: sovereign-power-mode-max

## 🔗 Links

- **Live Service**: https://dominion-demo-service-reduwyf2ra-uc.a.run.app
- **Cloud Console**: https://console.cloud.google.com/run/detail/us-central1/dominion-demo-service
- **Cloud Build**: https://console.cloud.google.com/cloud-build/builds?project=dominion-core-prod
- **GitHub**: https://github.com/Fractal5-Solutions/dominion-os-demo-build

---

**Status**: ✅ Production Ready - DEMO_MODE Active  
**Last Updated**: February 28, 2026  
**Build**: 027e4650-b2a1-41bd-b040-30e51e2330b7  
**Revision**: dominion-demo-service-00009-ftf
