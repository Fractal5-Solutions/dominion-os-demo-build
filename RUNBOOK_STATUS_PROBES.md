# Status Probe Runbook Note

## Scope

- Endpoint: `/status`
- Endpoint: `/api/v1/topology`

## Minimum Spend Default

Minimum Spend Mode is active. Default demo health checks must be lightweight and must not trigger remote cloud, AI, inbox, repository, or telemetry scans.

## Probe Semantics

- Default behavior: no probes are executed.
- `?probe=local`: executes local service probes only.
- `?probe=remote`: executes remote project probes only.
- `?probe=all`: executes both local and remote probes.
- Backward compatibility: `?probe=true` and `?probe=1` map to local probes.

## Operational Guidance

- Use default `/status` for low-latency public demo health and inventory checks.
- Use `?probe=local` during operator diagnostics when validating local dependencies.
- Use `?probe=remote` or `?probe=all` only when remote telemetry verification is deliberately required.
- Do not wire remote probes into public page loads, background timers, uptime checks, or scheduled jobs by default.
- For `/demo-1`, prefer cached or static proof assets unless an operator intentionally runs a live verification.

## Verification Examples

- `http://127.0.0.1:5000/status`
- `http://127.0.0.1:5000/status?probe=local`
- `http://127.0.0.1:5000/api/v1/topology?probe=all`
