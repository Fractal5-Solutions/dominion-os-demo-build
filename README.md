Dominion OS Demo Build

This repo demonstrates consuming the sibling `dominion-os-1.0` toy kernel to:

- Build a JSON image
- Run a demo and save outputs to `dist/`

Quickstart

- Build: `python demo_build.py build`
- Run demo: `python demo_build.py run`
- Tests: `python -m unittest`

Command Core (full experience)

- Run interactive dashboard (small scale):
  - `python demo_build.py command-core --duration 120 --scale small`
- Headless, generate artifacts only:
  - `python demo_build.py command-core --duration 100 --scale medium --no-ui`
- Artifacts are written to `dist/command_core/` as `events.log`, `session.json`, and `summary.txt`.

Autopilot (NHITL)

- Single automated run at large scale:
  - `python demo_build.py autopilot --scale large --duration 300`
- Multiple back-to-back runs with interval:
  - `python demo_build.py autopilot --scale medium --duration 120 --runs 3 --interval-ms 500`
- Output: flight summaries saved under `dist/command_core/flight_*.json`.

Note: This demo imports `dominion_os` from the sibling path `../dominion-os-1.0` without installing it. This keeps it network-free.
