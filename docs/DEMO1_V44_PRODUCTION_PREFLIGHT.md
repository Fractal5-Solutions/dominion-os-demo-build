# Dominion OS /demo-1 v4.4 — Production Preflight

**2026-10-28 status: Prepublication test PASS; live Squarespace acceptance OPEN.**

## Exact publication source
- One-shot Squarespace code: squarespace/demo-1-v4-4-production-preflight.html
- Source SHA-256: 98e05dd1e8b6cfd0f46d4f5a9e600f5819c38ff2baa3f66ca28a16c110513dda
- Git blob SHA: a3bfc8cb1cd50046bf39945ec21541d2052f8f1b
- Portable offline Business + Politics source: demo/portable-public-mission-v4.3.html
- Portable SHA-256: c69dae845977ac1b91752967e2a0b72dcb520c520de9d380ea8ae24a8d155813

## Canon and source review
Source authority: APPROVED Fractal5 Website Canon v2 at DCC docs/canon/FRACTAL5_WEBSITE_CANON_V2.md. Inherited white background, Manrope, ink/graphite, bone components, restrained gold, readable measures, nonbreaking Dominion OS, full-page code root, no duplicate global Squarespace header/footer.

## Completed verification
- Local Chrome/Chromium production preflight: 125/125 checks PASS across 1440, 1200, 1024, 768, 430, 390 and 360px.
- Business and Politics preview modes, human-approval simulation, reset, keyboard Enter, primary CTA, video error/recovery fallback, download, and exact portable data equality verified.
- No network dependency for primary embedded Mission Console or portable HTML generation.
- Automated non-deploying PR-only GitHub workflow passed on exact newline-aligned source: [run #40771604229](https://github.com/Fractal5-Solutions/dominion-os-demo-build/actions/runs/40771604229), 104/104 browser/source checks PASS, reported SHA-256 98e05dd1e8b6cfd0f46d4f5a9e600f5819c38ff2baa3f66ca28a16c110513dda and portable hash c69dae845977ac1b91752967e2a0b72dcb520c520de9d380ea8ae24a8d155813. Earlier run #40771402113 also succeeded on prior text-equivalent source.
- Website links to hosted Business/Politics missions followed via live Squarespace page. Browser fetching of binary MP4 assets and true Windows file:// opening remain separate acceptance checks.

## V4.4 production changes
1. Primary hero action now navigates to the on-page client-side mission console, independent of the external hosted demo URL.
2. Both silent videos display explicit branded visual fallbacks when the public video host does not respond, and continue to offer text-based mission links.
3. The embedded offline demo downloads byte-exact synthetic HTML with restrictive network CSP and no installation or cloud credential requirements.
4. Free installable Windows and user-owned-data Google Cloud products remain marked planned and require independent commercial/security certificates.

## Principal publication and verification
1. Save a rollback copy of the existing live Squarespace code block.
2. Paste the complete v4.4 one-shot file into the existing /demo-1 code block, preview, and publish with principal authority.
3. With network-enabled Chromium/Playwright on a separate clean host, run: python scripts/accept_demo_page_live_v44.py --url https://www.fractal5solutions.com/demo-1
4. Independently validate video play/pause, site theme inheritance, all seven screen sizes, linked hosted Business and Politics missions, and offline downloaded HTML launched directly from Windows File Explorer with the network disconnected.
5. Retain dated receipts: published build marker, screenshot matrix, actual media URL HTTP results, offline open, downloads, accessibility review and publisher signoff. If a primary experience fails, roll back the saved page code.
6. Only after the live surface passes independently may /demo-1 be certified CANON GREEN. No automatic merging or Squarespace publication is authorized by this PR.

## Separate gates unchanged
- Windows free GUI installer: Publisher signing, installed lifecycle, IP/legal rights, signed entitlements, Politics approval. Windows PR #82.
- Google Cloud own-data Data Lab: authenticated provider, isolated tenant and data processing, privacy and consent, quotas and signed licence, data deletion, authorized funding, real E2E. GCloud PR #19; Command Center issue #1933.

**The previously live phrase 'Commercial Runtime Verified' is not itself proof of the customer's installable Windows or own-data cloud service.**
