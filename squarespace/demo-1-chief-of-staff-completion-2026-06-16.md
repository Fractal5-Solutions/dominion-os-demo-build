# /demo-1 Chief of Staff recommendation completion - 2026-06-16

Scope: public Squarespace bridge for Dominion OS + SaaS Suite 4G cloud demo experience, with Politics in Business positioning.

Branch: `commercial-readiness-hardening` / PR #137.

## Completed in `demo-1-chief-of-staff-additive-block-2026-06-16.html`

1. Preserve `/demo-1` instead of rebuilding it.
   - The existing canonical bridge remains the base.
   - This is an additive block, not a design replacement.

2. Add Politics in Business proof strip.
   - Adds public-safe copy for policy, campaign, stakeholder, communications, executive, procurement, and organizational command workflows.
   - Includes a boundary note separating Fractal5 systems/infrastructure from civic advocacy/lobbying-service claims.

3. Add guided demo scenarios.
   - Business SaaS Command.
   - Politics Configuration.
   - Executive Proof Review.
   - Each includes a copyable prompt and a live demo/status route.

4. Keep Cloud Run as primary until branded domain is verified.
   - `demo.fractal5solutions.com` must not be promoted as primary until DNS and TLS resolve cleanly.
   - Endpoint manifest update text is included as a paste instruction.

5. Explain zero counters.
   - Adds a buyer-safe explanation that counters such as `healthChecks`, `streamEvents`, and `uptime` may be cold-start or session-local instruments, not production traffic totals.

6. Preserve the public-safe boundary.
   - No private endpoints.
   - No secrets.
   - No source-code exposure.
   - No customer data.
   - No payment systems.
   - No private operational console.

7. Add verification language.
   - Directs users to verify the current `generatedAt` timestamp through public Health and Status JSON.

8. Add procurement-safe CTA.
   - Recommends changing `Contact Fractal5` to `Request Controlled Access` while preserving the safe contact anchor.

9. Preserve Fractal5 / Blue Wave separation.
   - Politics positioning is framed as governed systems/infrastructure, not civic advocacy services.

10. Add “what this is / what this is not.”
   - Defines the public demo as a proof surface, not the production console.

## Deployment note

Because the repository is protected, direct commits to `main` are blocked. The implementation was added to the open hardening branch `commercial-readiness-hardening`, associated with PR #137.

To publish to Squarespace:

1. Open the current `/demo-1` Code Block.
2. Keep the existing canonical page code.
3. Paste `squarespace/demo-1-chief-of-staff-additive-block-2026-06-16.html` below the current hero/live-proof section and before the demo assets section.
4. Update the endpoint manifest pre block with: `Branded demo domain: pending DNS/TLS verification before use as primary`.
5. Change the final CTA label from `Contact Fractal5` to `Request Controlled Access`, preserving `https://www.fractal5solutions.com/#contact`.
6. Publish.
7. Verify public page, live demo, health JSON, status JSON, sample data, demo package, and receipts.

## Guardrail

Do not switch primary demo links from `https://demo-reduwyf2ra-uc.a.run.app/demo` to `https://demo.fractal5solutions.com/demo` until DNS, TLS, redirect behavior, and runtime route health are all verified from an external network.
