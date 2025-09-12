
> **Compliance:** See [Guardrails](GUARDRAILS.md) for enforced repo & release protections.
# Dominion OS Demo Build

This repository contains the **compiled public demo build** of Dominion OS 1.0.  
It includes only **minified, non-editable assets** for display and testing purposes.  
No source code or proprietary development files are included.

For full details about Dominion OS, visit:  
➡ [Fractal5 Solutions – Dominion OS](https://www.fractal5solutions.com/dominion-os)

For the live demo experience, go to:  
➡ [Dominion OS Public Demo](https://fractal5-solutions.github.io/dominion-os-1.0/)

---

© Fractal5 Solutions Inc. All rights reserved.

Status badge placeholder
`n![CI](https://github.com/Fractal5-Solutions/dominion-os-demo-build/actions/workflows/ci.yml/badge.svg)

## Terrain Viewer (Local API)

- Start the Dominion API at `http://localhost:8080` (see `dominion-os-1.0/README.md`).
- Open `http://localhost:8080/viewer/index.html?job_id={job_id}` to preview the ingested heightmap via WebGL2.
- The API serves the viewer for same-origin asset fetches under `/v1/gis/...`.

### Observability (contract)

- When the API is started with `DOMINION_ENABLE_TELEMETRY=1`, it exposes Prometheus metrics at `GET /metrics`.
- The viewer does not emit telemetry by default. To integrate browser traces, configure your deployment to serve an OTLP collector and inject a lightweight Web SDK snippet in `web/terrain-viewer/index.html`.
- Egress from the API is denied by default (loopback only) and must not be required by viewer assets.
