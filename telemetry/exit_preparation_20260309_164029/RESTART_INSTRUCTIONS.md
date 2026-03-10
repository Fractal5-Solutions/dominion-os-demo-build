# PHI SYSTEM RESTART INSTRUCTIONS

## Quick Start
```bash
cd /workspaces/dominion-os-demo-build
source .venv/bin/activate
bash scripts/phi_start_all_systems.sh
```

## Verify System After Restart
```bash
# Check all services
bash scripts/phi_complete_status.sh

# Verify perfection
python3 scripts/phi_perfect_system_verification.py

# Monitor live ops
bash scripts/live_ops_monitor.sh
```

## Service Ports
- 5000: Command Center (BIMS)
- 5002: Alt Demo
- 5003: Demo App
- 5004: Sidecar Service
- 5005: ChatGPT Gateway
- 8080: OAuth Server
- 8081: AskPHI Widget

## Expected State After Restart
- Live Ops Score: 1.00 (100%)
- Sovereign Mode: MAXIMUM_ACTIVE
- Authority Level: 9/9
- Certification: GOLD
- All 7 web services: HEALTHY
- Background processes: RUNNING

## If Issues Occur
1. Check logs in telemetry/
2. Verify ports are free: `lsof -i :8080 -i :8081 -i :5000 -i :5002 -i :5003 -i :5004 -i :5005`
3. Restart individual services if needed
4. Run verification: `python3 scripts/phi_perfect_system_verification.py`

## Support
All configuration preserved in: telemetry/exit_preparation_*/
