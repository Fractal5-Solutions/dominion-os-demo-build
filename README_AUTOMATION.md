PHI Automation & Continuous Monitoring

This repository includes GitHub Actions and local systemd examples to automate PHI monitoring and repository tasks.

Workflows added:
- `.github/workflows/phi-automation-monitor.yml` - runs every 15 minutes and executes monitor scripts (read-only checks on GitHub runners).
- `.github/workflows/phi-create-pr.yml` - automatically opens a PR to `main` when branches matching `phi-*` are pushed.
- `.github/workflows/phi-status-report.yml` - runs on push to `main` and can be triggered manually to collect status artifacts.

Local continuous running:
- `systemd/phi-continuous-monitor.service` - systemd unit example to run `scripts/telemetry/continuous_monitor.sh` continuously on a Linux host.

How to enable locally:

1. Copy service file to systemd folder (as root):

```bash
sudo cp systemd/phi-continuous-monitor.service /etc/systemd/system/
sudo systemctl daemon-reload
sudo systemctl enable --now phi-continuous-monitor.service
```

2. Check logs:

```bash
journalctl -u phi-continuous-monitor -f
```

Notes:
- GitHub Actions run in ephemeral runners; scripts that start long-lived local services won't persist there. The monitor workflows perform checks, collect logs, and upload artifacts.
- If you want GitHub to take action (create issues, open PRs), ensure repository secrets and permissions are configured appropriately.

Host preparation for local Docker-based runs:

```bash
sudo /workspaces/dominion-os-demo-build/host_docker_iptables_bootstrap.sh
```

- Run that on the Linux host OS, not from inside a dev container or Codespace.
- The default `STACK_PROFILE` is `local`, which opens only the host ports used by `docker-compose.yml`: `22 3000 5432 6379 8080 8081 9090`.
- Use `STACK_PROFILE=production` for `docker-compose.production.yml`.
- Use `STACK_PROFILE=mcp` for `docker-compose-mcp.yml`.
- Combine profiles if the host runs more than one stack, for example: `sudo STACK_PROFILE="local,mcp" /workspaces/dominion-os-demo-build/host_docker_iptables_bootstrap.sh`
- Override the port set directly only when needed, for example: `sudo ALLOWED_TCP_PORTS="22 8080 9090" /workspaces/dominion-os-demo-build/host_docker_iptables_bootstrap.sh`
