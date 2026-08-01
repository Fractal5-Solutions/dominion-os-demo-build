# BlueWave Signal public page

This folder stages the public `/signal` Squarespace Code Block for BlueWave Action Group.

## Current release

- Version: `signal-squarespace-v2`
- Stage: public pre-launch
- Series: **Conversations for a Country Worth Building**
- Primary publishing platform: Substack
- Public route: `/signal`

## Squarespace publication

Use the complete contents of `signal.code.html` as the single Code Block payload for `/signal`.

The new conversation-series feature is integrated inside `#bw-signal`, immediately after the hero and before the flagship-show placeholder. It uses the approved Squarespace CDN image at its native 16:9 ratio with `object-fit: contain`; do not crop it or restyle its embedded typography.

Before publication:

1. Back up the current live Code Block.
2. Replace the whole block with `signal.code.html`; do not paste only fragments of its CSS or markup.
3. Preview desktop, tablet, and mobile.
4. Confirm the image loads without cropping or horizontal overflow.
5. Confirm the three intake links arrive at `/#contact` with their query parameters intact.
6. Confirm keyboard focus is visible and reduced-motion mode does not animate buttons.
7. Publish only after the preview passes.

Rollback is one operation: restore the backed-up Code Block.

## Public boundary

The page is intentionally guest-neutral. Do not name or imply a confirmed guest until written acceptance, recording details, and publication permissions are settled. Do not expose private systems, sensitive records, internal endpoints, analytics identifiers, or unpublished media.

Substack, YouTube, podcast directories, and RSS should be described as live only when their public URLs resolve.

## Validation

Run from the repository root:

```bash
python .github/scripts/proof_bluewave_signal.py
```

The proof checks the approved image URL, 16:9 uncropped treatment, page placement, guest-neutral posture, accessible text, relative intake links, configuration agreement, and absence of forbidden public material.
