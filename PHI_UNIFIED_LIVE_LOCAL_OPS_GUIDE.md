# PHI Unified Live Local Ops Automation Guide

This guide documents the unified automation process for achieving perfect live local operations using the provided script and supporting files.

---

## 1. Prerequisites
- Ensure all required scripts are present in `/workspaces/dominion-os-demo-build/scripts/`.
- Install Python 3 and required dependencies (if any).
- Ensure Docker is installed if using containerized services.
- Set up a `.env` file in the project root with all required API keys:
  - `APOLLO_API_KEY`, `GMAIL_API_KEY`, `GOOGLE_DRIVE_API_KEY`, `DROPBOX_API_KEY`
- Authenticate with GCP for remote operations:
  - `gcloud auth login`

---

## 2. Starting All Core Services
Run:
```bash
bash /workspaces/dominion-os-demo-build/scripts/phi_quick_start.sh
```

---

## 3. Running the Unified Automation Script
Run:
```bash
bash /workspaces/dominion-os-demo-build/scripts/phi_unified_live_local_ops.sh
```
This script will:
- Check system and process health
- Optimize AI model selection and cost
- Run performance and SLO monitoring
- Execute autonomous and sovereign operations
- Harden security
- Integrate and verify all relationships
- Synchronize and verify file/repo status

---

## 4. Troubleshooting
- If any phase fails, check the output for missing dependencies, API keys, or authentication issues.
- For GCP errors, re-authenticate with `gcloud auth login`.
- For missing services, ensure all scripts are executable and present.
- For repo cleanliness, commit and push all changes.

---

## 5. Maintenance
- Update the `.env` file as needed for new integrations.
- Periodically rerun the script to ensure ongoing perfection.
- Review logs and status reports for any issues.

---

**For questions or handoff, this guide and the automation script provide a complete, repeatable process for perfect live local ops.**
