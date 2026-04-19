# Dominion OS 1.0 GCP Sandbox Gate Report

- Generated (UTC): `2026-04-19T21:56:03.1781378Z`
- Bundle: `D:\phi-ops\github\dominion-os-demo-build\reports\release-receipts\GCP_SANDBOX_GATES_2026-04-19T21-43-41Z`
- Score: `20/20` (`100%`), all_passed=`True`

## Gate Table

| ID | Gate | Pass | Summary |
|---|---|---|---|
| M01 | Active gcloud account | YES | accounts=1 |
| M02 | Active project aligned | YES | active_project=dominion-marketplace-prod |
| M03 | Billing enabled | YES | billing_enabled=True |
| M04 | Required APIs enabled | YES | missing=0 |
| M05 | Latest release render succeeded | YES | render_state=SUCCEEDED |
| M06 | Latest rollout succeeded to target | YES | state=SUCCEEDED target=prod-marketplace |
| M07 | Cloud Run service Ready=True | YES | ready=True |
| M08 | Cloud Run latest revision 100% traffic | YES | latest_traffic_pct=100 |
| M09 | Private exposure posture | YES | public_invoker=False ingress=internal-and-cloud-load-balancing |
| M10 | Runtime service account exists | YES | service_account=dominion-runtime@dominion-marketplace-prod.iam.gserviceaccount.com |
| M11 | Image digest pinned | YES | digest_pinned=True |
| M12 | Ceiling performance profile active | YES | minScale=1 maxScale=100 cpu_throttling=false |
| D01 | Demo repo is public | YES | visibility=PUBLIC |
| D02 | Public demo zip download responds 200 | YES | status=200 |
| D03 | Public /demo responds 200 | YES | status=200 |
| D04 | Public /store responds 200 | YES | status=200 |
| D05 | Demo health endpoint is reachable (www=200 or canonical runtime 200/302) | YES | www_status=404 canonical_status=302 |
| D06 | Public demo download surface is reachable | YES | store_links=0 zip_status=200 |
| D07 | Public demo payload allowlist passes | YES | included_count=16 |
| D08 | Required sandbox Cloud Run services are Ready | YES | missing=0 not_ready=0 |

## Notes

- M* gates = marketplace technical readiness checks.
- D* gates = public demo/download checks.
- Raw command receipts are in raw/.
