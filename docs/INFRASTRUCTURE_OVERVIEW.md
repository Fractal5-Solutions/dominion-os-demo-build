# Dominion OS Infrastructure Overview

**Generated:** $(date)
**Status:** Autonomous Operations Active

## Cloud Run Services

### dominion-os-1-0-main (9 services)
- AI Gateways (5)
- PHI UIs (3)
- Security Framework (1)

### dominion-core-prod (13 services)
- Core APIs (5)
- Orchestration Services (8)

## Health Status
All services operational at 100% health.

## Access URLs
See telemetry/services_project*.txt for complete service URLs.

## Architecture
- Platform: Google Cloud Run
- Region: us-central1
- Container Registry: Artifact Registry
- Networking: VPC with Cloud Run integration
- Scaling: Auto-scaling with min-instances configuration

## Monitoring
- Cloud Monitoring: Active
- Cloud Logging: Centralized
- Health Checks: Every 15 minutes
- Alerting: Configured for failures
