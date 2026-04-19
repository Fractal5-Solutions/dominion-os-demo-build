# Dominion OS 1.0: Product Details, Pricing, Technical Integration

Generated (UTC): 2026-04-19T21:56:03.2119821Z

## Product Details
- Product: Dominion OS 1.0 - Google Cloud
- Positioning: Sovereign AI business operating stack on GCP with public-safe demo and private control plane.
- Primary Public Surface: https://www.fractal5solutions.com/demo
- Public Download Surface: https://github.com/Fractal5-Solutions/dominion-os-demo-build/archive/refs/heads/main.zip
- Control Plane Source of Truth: dominion-command-center (private).

## Pricing
- Base SKU: DOM-OS-GCLOUD-001
- Monthly: USD 299
- Annual: USD 2999
- Support SLA target: 99.9% uptime, 4-hour response for commercial support.
- Packaging recommendation for Marketplace: 3 plans (Starter/Business/Enterprise) with enterprise negotiated support and onboarding.

## Technical Integration
- Marketplace project: dominion-marketplace-prod (us-central1)
- Cloud Deploy pipeline: dominion-os-pipeline, target: prod-marketplace
- Marketplace runtime service: dominion-bootstrap
- Sandbox project: f5-demo-sandbox (us-central1)
- Public repo visibility: PUBLIC (dominion-os-demo-build).
- Required APIs and Cloud Run readiness are validated in the gate report receipt bundle.
- Health gate uses canonical runtime boundary: www demo surface (200) or demo subdomain health endpoint (200/302 via IAP).
- Download gate requires reachable public demo artifact URL with optional in-page store discoverability.

## Final Recommendation
- Submission-ready technical core is present for marketplace stack.
- Optional conversion enhancement: add a visible Download Demo CTA on /store pointing to the public demo archive URL.
