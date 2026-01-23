# Dominion OS Demo Build - Commercial Edition

> **Commercial Product** - Enterprise-ready AI orchestration platform
> **License**: Proprietary (Fractal5-Solutions)
> **Marketplace**: Available on GCP, AWS, Azure

# Dominion OS Demo Build - Commercial Edition

> **Commercial Product** - Enterprise-ready AI orchestration platform
> **License**: Proprietary (Fractal5-Solutions)
> **Marketplace**: Available on GCP, AWS, Azure

# Dominion OS Demo Build - Commercial Edition

> **Commercial Product** - Enterprise-ready AI orchestration platform
> **License**: Proprietary (Fractal5-Solutions)
> **Marketplace**: Available on GCP, AWS, Azure

# Dominion OS Demo Build - Commercial Edition

> **Commercial Product** - Enterprise-ready AI orchestration platform
> **License**: Proprietary (Fractal5-Solutions)
> **Marketplace**: Available on GCP, AWS, Azure

# Dominion OS Demo Build

![Demo](https://img.shields.io/badge/Demo-Ready-brightgreen)
[![Dominion OS](https://img.shields.io/badge/Depends%20on-dominion--os--1.0-blue)](https://github.com/Fractal5-Solutions/dominion-os-1.0)
![Cloud Run](https://img.shields.io/badge/Deployed-Google%20Cloud%20Run-4285F4?logo=googlecloud&logoColor=white)
![License](https://img.shields.io/badge/license-Commercial-blue)

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

Container (Cloud Run / local Docker)

- Build: `docker build -t dominion-os-demo-build .`
- Run: `docker run --rm -p 8080:8080 dominion-os-demo-build`
- Health: `curl -fsS http://localhost:8080/healthz`

Note: This repo vendors the minimal `dominion_os` toy kernel so the demo can run standalone. If you prefer
to use a sibling checkout of `dominion-os-1.0`, set `DOMINION_OS_PATH` to that repo root.
