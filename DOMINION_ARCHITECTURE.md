# Dominion OS Architecture - Complete System Overview

**Established:** February 26, 2026
**Authority:** Matthew Burbidge (<matthewburbidge@fractal5solutions.com>)
**Status:** Production & Public Demo Active
**Architecture Type:** Two-Tier Sovereign AI System

---

## 🎯 Executive Summary

Dominion OS operates as a **two-tier architecture** separating the private control plane from public-facing demo interfaces:

1. **dominion-os-1.0** - Private Control Plane ("Eye in the Sky")
2. **dominion-os-demo-build** - Public Demo & Showcase Interface

---

## 🏗️ TIER 1: dominion-os-1.0 (Private Control Plane)

### Purpose

**Superuser "Eye in the Sky" - Complete Business & Software Ecosystem Oversight**

The main operational system providing Matthew Burbidge with:

- **Complete Infrastructure Visibility** - All dashboards, metrics, logs
- **All Access Permissions** - Unrestricted control across all systems
- **Full Monitoring Stack** - Real-time health, cost, performance tracking
- **Autonomous Operations** - PHI Chief AI agent with sovereign authority
- **Production Services** - 22 active Cloud Run services across 2 GCP projects

### Infrastructure Components

#### GCP Project 1: dominion-os-1-0-main (9 services)

**AI Gateways (2):**

- `dominion-ai-gateway` - Primary AI gateway for model orchestration
- `dominion-f5-gateway` - F5 integration gateway

**PHI User Interfaces (1):**

- `dominion-phi-ui` - Development PHI interface
- `askphi-chatbot` - PHI chatbot service

**Core APIs (2):**

- `dominion-os-api` - Core API service (activated Feb 26)
- `dominion-os-1-0` - Core OS runtime

**Operations & Monitoring (4):**

- `dominion-monitoring-dashboard` - Observability dashboard
- `dominion-revenue-automation` - Revenue operations
- `dominion-security-framework` - Security framework (placeholder)

#### GCP Project 2: dominion-core-prod (13 services)

**Production Gateways (1):**

- `dominion-gateway` - Production gateway (recently updated)

**Core APIs (3):**

- `dominion-api` - Dominion API
- `api` - Core API endpoint
- `dominion-os` (x3 instances) - OS runtime instances

**AI Services (2):**

- `dominion-ai-gateway` - Core AI gateway
- `dominion-f5-gateway` - Core F5 gateway

**Orchestration (3):**

- `dominion-os-1-0-101` - OS orchestration
- `dominion-phi-ui` - Production PHI UI
- `dominion-chief-of-staff` - Operations management (placeholder)

**Demo Services (3):**

- `demo` - Demo environment
- `dominion-demo` - Dominion demo
- `dominion-os-demo` - OS demo

**Utility (1):**

- `pipeline` - Pipeline service

### Monitoring & Observability

**Cloud Monitoring Dashboards (3):**

1. **Service Health Dashboard** - Real-time service status, latency, error rates
2. **Cost & Resource Utilization** - Spend tracking, CPU/memory utilization
3. **SLO Compliance & Error Budget** - Service level objectives, budget burn

**Uptime Checks (5):**

- Dominion AI Gateway (both projects)
- Dominion F5 Gateway (dominion-os-1-0-main)
- Dominion PHI UI (dominion-os-1-0-main)
- Dominion PHI UI (dominion-core-prod)

**Alerting Policies:**

- Service downtime detection (SMS/Email)
- Error rate thresholds (99.5% uptime SLO)
- Cost anomaly detection
- Performance degradation warnings

**Access URLs:**

- **Dashboards:** <https://console.cloud.google.com/monitoring/dashboards?project=dominion-os-1-0-main>
- **Uptime Checks:** <https://console.cloud.google.com/monitoring/uptime?project=dominion-os-1-0-main>
- **Alerting:** <https://console.cloud.google.com/monitoring/alerting?project=dominion-os-1-0-main>
- **Cost Management:** <https://console.cloud.google.com/billing>
- **IAM & Admin:** <https://console.cloud.google.com/iam-admin>

### Superuser Access

**Matthew Burbidge's Authority:**

- **Permission Level:** MAXIMUM (unrestricted)
- **Infrastructure Control:** FULL (owner permissions on all GCP projects)
- **Monitoring Access:** ALL dashboards, metrics, logs, traces
- **Financial Authorization:** UNLIMITED (billing, budgets, cost controls)
- **Security Governance:** ABSOLUTE (IAM, policies, encryption keys)
- **Deployment Authority:** UNRESTRICTED (deploy, rollback, scale any service)
- **AI Orchestration:** SOVEREIGN (PHI Chief delegation and override)

**Authentication Methods:**

- GitHub SSH keys
- GitHub Personal Access Token (repo, admin:org, workflow scopes)
- GCP Owner role on both projects
- Email verification

**Reference Documentation:**

- [config/superuser-authority.json](config/superuser-authority.json)
- [SECURITY_GOVERNANCE.md](SECURITY_GOVERNANCE.md)
- [SUPERUSER_HARDENING_PLAN.md](SUPERUSER_HARDENING_PLAN.md)

### Repository

**Location:** `../dominion-os-1.0` (private repository)
**Type:** Private production codebase
**Access:** Matthew Burbidge only (superuser)
**Purpose:** Core infrastructure, service definitions, deployment configurations

---

## 🌐 TIER 2: dominion-os-demo-build (Public Demo)

### Purpose

**Public-Facing Demo & Showcase Interface**

This repository provides public access to Dominion OS capabilities through:

- **AskPhi Public Interface** - Conversational AI demo
- **Demo Experience** - Interactive feature showcase
- **/demo Page** - Public landing page and documentation

### Repository

**Location:** `/workspaces/dominion-os-demo-build` (current repository)
**Type:** Public demonstration codebase
**GitHub:** <https://github.com/Fractal5-Solutions/dominion-os-demo-build>
**Access:** Public (Matthew Burbidge as sole code owner via @Fractal5-X)

### Components

**Demo Build System:**

- `demo_build.py` - Builds demo artifacts from dominion-os-1.0
- `command_core.py` - Core command orchestration for demos
- Test suite (9 tests) - Validates demo functionality

**Public Demo Services:**

- `askphi-chatbot` - Public AskPhi conversational interface
  - URL: <https://askphi-chatbot-829831815576.us-central1.run.app>
- `dominion-demo` - Main demo environment
  - URL: <https://dominion-demo-447370233441.us-central1.run.app>
- `demo` - Additional demo instance
  - URL: <https://demo-447370233441.us-central1.run.app>

**Public Storage:**

- Bucket: `gs://dominion-os-1-0-main-dominion-demo/`
- Index page: `gs://dominion-os-1-0-main-dominion-demo/index.html`
- Demo artifacts: Event logs, flight data, sovereignty reports

**Reference Documentation:**

- [README.md](README.md) - Project overview
- [DEMO_PAGE_README.md](DEMO_PAGE_README.md) - Demo page guide
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions

### Access Control

**Code Ownership:**

- **Owner:** Matthew Burbidge (@Fractal5-X)
- **Authority:** COMPLETE (via .github/CODEOWNERS)
- **Review Requirements:** Sole approver for all changes
- **Branch Protection:** Main branch protected (pending setup)

**Public Access:**

- **Repository:** Public read access
- **Demo Services:** Public HTTP/HTTPS access
- **AskPhi:** Public conversational interface
- **Documentation:** Public visibility

---

## 🔐 Security & Access Model

### Separation of Concerns

| Aspect | dominion-os-1.0 (Private) | dominion-os-demo-build (Public) |
|--------|---------------------------|----------------------------------|
| **Visibility** | Matthew only (superuser) | Public |
| **Infrastructure Control** | Full GCP owner permissions | Read-only references |
| **Monitoring Dashboards** | All dashboards & alerts | None (builds from main) |
| **Service Deployment** | Unrestricted deployment authority | Demo services only |
| **Code Access** | Private repository | Public repository |
| **Financial Data** | Full billing & cost access | No financial access |
| **Security Keys** | Master encryption keys | No key access |
| **AI Orchestration** | PHI Chief with autonomous authority | Demo-scoped AI only |

### Data Flow

```
dominion-os-1.0 (Private Control Plane)
    ↓ (builds demo artifacts)
dominion-os-demo-build (Public Demo)
    ↓ (deploys to)
Public Demo Services (askphi-chatbot, dominion-demo)
    ↓ (accessible by)
Public Users
```

**Build Process:**

1. dominion-os-1.0 contains production code and configurations
2. demo_build.py in dominion-os-demo-build references ../dominion-os-1.0
3. Build artifacts generated for public consumption
4. Public demo services deployed with limited scope
5. No production secrets or credentials in public demo

---

## 🎛️ Operational Command Structure

### Matthew Burbidge (Superuser)

**Role:** "Eye in the Sky" - Complete oversight
**Systems:** Both tiers (full access to private, owner of public)
**Dashboards:** All monitoring, cost, performance, security dashboards
**Authority:** MAXIMUM across all domains

**Daily Operations:**

- Access all dashboards via GCP Console
- Monitor 22 services across 2 projects
- Review cost tracking and optimization opportunities
- Override PHI Chief decisions when needed
- Deploy/rollback any service
- Modify security policies
- Review audit logs

### PHI Chief (AI Agent)

**Role:** Autonomous operations agent
**Authority:** SOVEREIGN (within delegated scope)
**Reporting To:** Matthew Burbidge
**Override:** Owner only

**Autonomous Capabilities:**

- Overnight operations and health checks
- Service deployment and scaling
- Monitoring configuration
- Cost optimization recommendations
- Incident response (within runbooks)
- Documentation generation

---

## 📊 System Health & Status

### Current Infrastructure State

**Overall Health:** 100% (22/22 services operational) ✅

**Project 1 (dominion-os-1-0-main):** 9/9 operational ✅
**Project 2 (dominion-core-prod):** 13/13 operational ✅

**Last Health Check:** February 26, 2026
**Uptime SLO:** 99.5% target
**Error Budget:** Within limits

### Recent Operations

- **Feb 26, 2026:** Superuser hardening framework established
- **Feb 26, 2026:** All 3 corporations configured (Fractal5 Solutions Inc, Blue Wave Action Group Inc, Plane4 Grain Inc)
- **Feb 26, 2026:** Code ownership assigned to @Fractal5-X
- **Feb 26, 2026:** Comprehensive monitoring deployed (3 dashboards, 5 uptime checks)
- **Feb 26, 2026:** Service repairs completed (dominion-os-api activated, dominion-security-framework repaired)

---

## 🚀 Quick Access Commands

### Matthew's Superuser Access

```bash
# Authenticate to GCP
gcloud auth login

# Switch to dominion-os-1-0-main project
gcloud config set project dominion-os-1-0-main

# View all services
gcloud run services list --project=dominion-os-1-0-main
gcloud run services list --project=dominion-core-prod

# Access monitoring
open "https://console.cloud.google.com/monitoring/dashboards?project=dominion-os-1-0-main"

# Check costs
open "https://console.cloud.google.com/billing"

# Review audit logs
gcloud logging read "protoPayload.authenticationInfo.principalEmail:matthewburbidge@fractal5solutions.com" --limit 50
```

### Demo Build & Deployment

```bash
# Navigate to demo build repo
cd /workspaces/dominion-os-demo-build

# Activate virtual environment
source .venv/bin/activate

# Run tests
pytest -q

# Build demo
python demo_build.py

# Deploy to GCP
bash deploy_to_gcp.sh
```

---

## 📈 Cost & Resource Tracking

**Monthly Cloud Run Costs:** ~$150-200/month (estimated)
**Optimization Target:** $50-100/month savings identified
**Billing Alerts:** Configured for anomalies
**Budget:** Monitored via Cost & Resource Utilization Dashboard

**Cost Optimization Opportunities:**

- Right-size container instances
- Optimize min-instances settings
- Move infrequent services to on-demand scaling
- Consolidate duplicate services
- Archive unused demo environments

---

## 🔄 System Integration Points

### Between Tiers

**dominion-os-1.0 → dominion-os-demo-build:**

- Build dependencies (bootstrap scripts, configs)
- Demo artifact generation
- Public documentation generation

**dominion-os-demo-build → Public:**

- AskPhi chatbot deployment
- Demo page hosting
- Public API endpoints (limited scope)

### External Services

**GitHub:**

- Code repositories (private + public)
- CI/CD via GitHub Actions
- Branch protection and CODEOWNERS
- Issue tracking and project management

**Google Cloud Platform:**

- Cloud Run (22 services)
- Artifact Registry (container images)
- Cloud Storage (demo artifacts)
- Cloud Monitoring (dashboards, alerts)
- Cloud Logging (centralized logs)
- Cloud IAM (access control)
- Cloud Billing (cost tracking)

---

## 📝 Governance & Compliance

**Security Framework:** [SECURITY_GOVERNANCE.md](SECURITY_GOVERNANCE.md)
**Implementation Plan:** [SUPERUSER_HARDENING_PLAN.md](SUPERUSER_HARDENING_PLAN.md)
**Quick Reference:** [SUPERUSER_QUICKREF.md](SUPERUSER_QUICKREF.md)

**Compliance Targets:**

- SOC 2 Type 2 (target Q3 2026)
- ISO 27001 (target Q4 2026)
- Sovereign AI Security Standard (active)

**Audit Requirements:**

- All superuser actions logged
- Infrastructure changes tracked
- Code merges recorded
- Financial transactions audited
- Security policy changes alerted

---

## ✅ Architecture Confirmation

**CONFIRMED:** Dominion OS is optimally configured with:

✅ **dominion-os-1.0** = Matthew's superuser "eye in the sky"

- All access permissions across 22 services
- All dashboards (health, cost, SLO)
- Complete business & software ecosystem visibility
- Unrestricted control and monitoring

✅ **dominion-os-demo-build** = Public demo repository

- Public AskPhi interface
- Demo Experience showcase
- /demo page deployment
- Limited scope for public consumption

✅ **Superuser Authority** = Maximum permissions established

- Matthew Burbidge as sole owner across 3 corporations
- 100% code ownership via @Fractal5-X
- MAXIMUM authority level in all domains
- Complete security governance framework

---

## 📚 Related Documentation

### Security & Governance

- [SECURITY_GOVERNANCE.md](SECURITY_GOVERNANCE.md) - Complete governance framework
- [SUPERUSER_HARDENING_PLAN.md](SUPERUSER_HARDENING_PLAN.md) - Implementation roadmap
- [SUPERUSER_QUICKREF.md](SUPERUSER_QUICKREF.md) - Daily operations guide
- [GUARDRAILS.md](GUARDRAILS.md) - System guardrails and constraints
- [PHI_ACCOUNTABILITY_FRAMEWORK.md](PHI_ACCOUNTABILITY_FRAMEWORK.md) - AI agent accountability

### Infrastructure & Operations

- [docs/INFRASTRUCTURE_OVERVIEW.md](docs/INFRASTRUCTURE_OVERVIEW.md) - Infrastructure details
- [docs/MONITORING_SETUP.md](docs/MONITORING_SETUP.md) - Monitoring configuration
- [SMOOTH_SYSTEMS_COMPLETE.md](SMOOTH_SYSTEMS_COMPLETE.md) - System health report
- [START_ALL_READY.md](START_ALL_READY.md) - Startup procedures
- [DEPLOYMENT_GUIDE.md](DEPLOYMENT_GUIDE.md) - Deployment instructions

### Configuration Files

- [config/superuser-authority.json](config/superuser-authority.json) - Superuser definition
- [config/organizational-authority.json](config/organizational-authority.json) - Corporate structure
- [.github/CODEOWNERS](.github/CODEOWNERS) - Code ownership assignments

### Business & Strategy

- [BUSINESS_TRIAD_DOCTRINE.md](BUSINESS_TRIAD_DOCTRINE.md) - Business strategy
- [PHI_AUTONOMOUS_RECOMMENDATIONS.md](PHI_AUTONOMOUS_RECOMMENDATIONS.md) - AI recommendations

---

**Document Version:** 1.0.0
**Last Updated:** February 26, 2026
**Maintained By:** Matthew Burbidge (<matthewburbidge@fractal5solutions.com>)
**Authority:** SOVEREIGN (sole owner across all Dominion OS systems)
