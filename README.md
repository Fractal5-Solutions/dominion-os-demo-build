# Dominion OS Demo Build

![Demo](https://img.shields.io/badge/Demo-Ready-brightgreen)
[![Dominion OS](https://img.shields.io/badge/Depends%20on-dominion--os--1.0-blue)](https://github.com/Fractal5-Solutions/dominion-os-1.0)
![Cloud Run](https://img.shields.io/badge/Deployed-Google%20Cloud%20Run-4285F4?logo=googlecloud&logoColor=white)
![License](https://img.shields.io/badge/license-Commercial-blue)

## 🏗️ Architecture Overview

**This is Tier 2: Public Demo & Showcase Interface**

Dominion OS operates as a two-tier system:

- **Tier 1 (dominion-os-1.0):** Private control plane - Matthew's superuser "eye in the sky" with complete access to all dashboards, monitoring, and 22 production services across 2 GCP projects
- **Tier 2 (dominion-os-demo-build):** This public repository - Provides AskPhi interface, demo experience, and /demo page for public consumption

For complete architecture details, see [DOMINION_ARCHITECTURE.md](DOMINION_ARCHITECTURE.md).

---

## Overview

This repo demonstrates consuming the sibling [`dominion-os-1.0`](https://github.com/Fractal5-Solutions/dominion-os-1.0) toy kernel to:

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
