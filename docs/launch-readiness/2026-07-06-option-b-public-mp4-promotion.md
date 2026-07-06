# Dominion OS Option B Public MP4 Promotion Gate — 2026-07-06

Generated: 2026-07-06T17:45:00Z  
Mode: Option B — make the MP4 claim true  
Repository: Fractal5-Solutions/dominion-os-demo-build

## Verdict

Option B is the stronger marketing path, but it is not a copywriting task. It requires a real public MP4 binary URL that can be independently verified.

As of this gate package, no real MP4 URL is inserted by default. The manifest must stay honest until a public MP4 exists.

## What this package adds

1. `tools/promote-public-mp4.mjs` — a public-safe promotion tool that:
   - requires `PUBLIC_MP4_URL`;
   - requires HTTPS;
   - requires a `.mp4` path;
   - verifies the public media URL by HEAD or range GET;
   - updates `demo/assets/demo-manifest.json`;
   - updates `demo/assets/demo-download-package.json`;
   - updates `demo/assets/release-receipts.json`;
   - updates `demo/assets/commercial-launch-readiness.json`;
   - keeps `fullCommercialGreenAllowed` false.

2. `tools/verify-demo1-public-proof.mjs` now:
   - reads `assets.videoMp4` from the manifest;
   - checks the MP4 URL when non-null;
   - uses HEAD/range probing for MP4 instead of downloading the full binary;
   - requires successful status and plausible MP4 content type before allowing the direct MP4 claim;
   - keeps full commercial green tied to separate claim-control proof.

3. `demo/assets/demo-1-watchlist.json` now names the Option B promotion gate and the direct MP4 evidence requirements.

## Required operator sequence

```bash
# 1. Capture or export the final live-action MP4.
# Required by existing phi-ops capture canon:
# - 1920x1080
# - 30 fps
# - H.264 MP4
# - live-action real build UI, not mockup

# 2. Publish the MP4 to a stable public HTTPS URL.
# Good targets include a GitHub Release asset, public Cloud Storage object,
# or equivalent public CDN URL. The URL must end in .mp4.

# 3. Promote it into the manifest.
PUBLIC_MP4_URL="https://example.com/path/dominion-os-demo.mp4" \
PUBLIC_MP4_SHA256="optional-sha256" \
node tools/promote-public-mp4.mjs

# 4. Run the proof verifier.
PROBE_STRICT=true node tools/verify-demo1-public-proof.mjs

# 5. Commit the generated JSON changes and preserve the probe receipt.
```

## Claim-control line

Allowed only after promotion and verifier pass:

> Dominion OS has a verified direct public demo MP4 available from the public demo manifest.

Still not allowed after MP4 alone:

> Full SaaS commerce is green, customer portal is green, production observability is green, native GCP self-healing is green, or full commercial stack is 100% green.

## Why this is the right gate

Option B should create proof, not perfume. The MP4 claim is commercially useful only if a prospect, operator, or auditor can open the manifest, see a public MP4 URL, and independently verify it without private credentials.

The storefront may get a brighter sign. The books still stay clean.
