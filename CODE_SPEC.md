# CODE_SPEC

## Scope
This repository exposes a public demo surface for Dominion OS and companion services.

## Service Contracts

### command-core (`command_core.py`)
- `GET /` : HTML page. Returns JSON when `Accept: application/json`.
- `GET /health`, `/healthz`, `/ready`, `/_ah/health` : returns health payload with release metadata.
- `GET /status` : returns topology/status payload.
- `GET /api/products`, `/api/v1/products` : returns list of product specs from `products/*/spec.json`.
- `GET /api/products/{slug}` : returns one product spec for a safe slug.
- `GET /api/demo/experience`, `/api/v1/demo/experience` : returns demo-experience payload.
- `GET /api/v1/topology` : returns topology payload.

### widget-service (`widget_service/app.py`)
- `GET /` : widget shell HTML.
- `GET /api/bootstrap` : returns runtime profile for widget.
- `POST /api/chat` : chat request/response endpoint.
- `GET /health`, `/ready` : service health payload.

### oauth-server (`oauth_server/app.py`)
- `GET /` : OAuth home page.
- `GET /auth/github` : starts GitHub OAuth flow.
- `GET /auth/callback` : OAuth callback handler.
- `POST /api/chat` : authenticated chat endpoint.
- `GET /health`, `/ready` : service health payload.

## Data Contracts
- Product spec files: `products/<slug>/spec.json`.
- Required product fields: `slug`, `name`.
- Health payload includes: `status`, `service`, `release`.
- Topology payload includes: `version`, `services`, `generated_at`.

## Security/Validation Requirements
- Product slug must be validated before lookup.
- OAuth error redirection tokens must be sanitized.
- Health endpoints must not expose stack traces.
- Public demo surface must remain within allowed paths validated by `scripts/verify_public_demo_surface.py`.
