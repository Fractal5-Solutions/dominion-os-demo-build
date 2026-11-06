# Dominion OS 1.0 — Windows + Google Universe commercial-grade evaluation release
**Decision date:** 2026-11-06. **State:** EXECUTION PLAN / RELEASE BLOCKED. **Authority:** no production release, no public website paste, no IAM/billing, no protected OS 1.0 change.

## Product definition
Two customer delivery families only: (1) signed Windows x64 native evaluation, (2) authenticated Google Cloud + Google Workspace evaluation. Each exposes Business and neutral Politics workflows and the **actual certified** Dominion OS 1.0/SaaS Suite capabilities. Reuse the native Command Center, evidence, approvals and orchestration contracts; don't replicate them as marketing animations. Show the 13-module catalogue but do not imply all 13 are GA, installed, connected, or certified. Label simulated versus operational features visibly.

### Business mission acceptance
A fictional enterprise board decides whether to expand into BC. Present mission capture, provenance-linked evidence, contradictory finance/operations assumptions, options with sensitivity, named approval, bounded execution simulation, immutable receipt, reset and export. Any genuine CRM, Google Sheets/Drive, Calendar or Gmail access requires specifically reviewed read scopes, per-user OAuth authorization and separate negative tests; Gmail send, spending and other external mutations default DENY.

### Politics mission acceptance
A fictional neutral legislative and public-policy preparedness mission: evidence, sources, contradictions, organizational coordination, approved decision and provenance receipt. No voter profiling, sensitive campaign data, personalized persuasion, automated outreach or unreviewed real political connectors. Politics native binary release requires separate policy and product authorization.

### Windows release sequence (owner: desktop release lane)
1. Reuse `Fractal5-Solutions/dominion-os-1.0-desktop-pc` and draft PR #82; confirm exact, minimal Windows x64 application payload and license/chain of title. Do not embed proprietary backends, keys, production connectors or model weights.
2. Bind both mission packs to immutable edition/module authorizations. Server-verifiable signed seven-day evaluation entitlement with explicit offline grace; clock rollback/expired/altered token/expired lease/disabled module/revocation negatives must deny protected actions. Full offline instant revocation cannot be guaranteed.
3. Build and freeze exact EXE/MSI or approved installer + ZIP digest, SBOM, dependency/secret scan and Defender results. Sign exact installer and executable through configured Azure Artifact Signing; independently verify publisher, timestamp, SHA-256 and signing-chain status.
4. Clean Windows 11 x64 acceptance: install, launch, both domains, mission evidence, update, repair, uninstall, restart, non-admin runtime, no unexpected network egress, expiry and recovery. Record independent machine receipts, not merely CI claims.
5. Public binary download stays disabled until exact-artifact signed release certificate and explicit principal publication approval. No site change or unsigned link.

### Google Universe release sequence (owner: governed GCP provider)
1. Repair and attest fixed PHI provider SDK/identity Gate Two without borrowing profile credentials, bypassing IAM, or deploying to a different project.
2. Separate Google Cloud-hosted GUI/service access from Google Workspace connectors. Workspace OAuth requires explicit least-privilege per-user consent and scope review for Drive/Docs/Sheets, Calendar and Gmail (read-only by default); do not claim connector functionality not independently tested.
3. Enforce named MFA identity, tenant isolation, signed seven-day scoped entitlement and revocation, server quotas and cost kill switch, egress allowlist, logging without raw user data. Initial data: user-owned low-sensitivity CSV/TXT/JSON only, 10MiB/file, 50MiB/tenant, 24-hour file TTL, 50 read-only runs.
4. Real low-sensitivity test uploads require consent, quarantine, malware/DLP screening, scoped access, provenance and purge receipt. Test cross-tenant IDOR, over-quota, expired tokens, missing consent, content injection, malformed files, backups and deletion.
5. Review actual region, IAM, Cloud Run revisions and image digest, Cloud billing budget, browser/API E2E, legal/privacy terms and customer offboarding; only then provide certified customer login link. No live public upload beforehand.
6. Customer-owned Google Cloud deployment is an independent paid-resource path, not automatically the free hosted trial.

### Demonstration-page acceptance
Live `/demo-1` (inspected Nov 6) already offers certified synthetic browser and offline HTML and correctly withholds installers and cloud logins. Preserve its full live functionality and existing Fractal5 Canon. A future one-shot Squarespace edit must be based on a fresh copy of the **live** page, retain working Business/Politics/video/download experiences and route only Windows + Google Universe; no AWS/OCI/macOS/Linux deployment promises. Show per-format available versus preview status, evidence receipts, downloadable signed digest only when GREEN, and no fake sign-in. The principal remains the final Squarespace publisher.

## Release assertions
The public contract `demo/assets/windows-google-evaluation-readiness.v1.json` remains fail-closed. It is descriptive and cannot by itself authorize publication. Windows and Google can only turn GREEN with independent immutable exact-artifact/runtime certificates, current signoff and explicit publication authority. Do not set a boolean to true as a substitute for evidence.

## Current evidence
- Public synthetic website: `docs/DEMO1_V44_LIVE_CANON_GREEN_RECEIPT.md` — verified live and Windows portable HTML acceptance, *not* native/cloud certification.
- Windows: `dominion-os-1.0-desktop-pc` PR #82, Windows issue #50; unsigned artifact and entitlement blocked.
- Cloud: `dominion-os-1.0-gcloud` PR #19, DCC #1933; design-only own-data evaluation.
- PHI status 2026-11-06: local APEX_GREEN; GCP Gate Two BLOCKED_EXTERNAL (`pinned-gcloud-version-not-proven`), and latest DMI1 release promotion receipt FAILED.
- No customer data processing or funded cloud runtime is authorized by this plan.
