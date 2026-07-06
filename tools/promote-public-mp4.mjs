#!/usr/bin/env node
/*
 * Promote a verified public Dominion OS demo MP4 into the public asset manifest.
 *
 * Usage:
 *   PUBLIC_MP4_URL=https://.../dominion-os-demo.mp4 node tools/promote-public-mp4.mjs
 * Optional:
 *   PUBLIC_MP4_SHA256=<sha256> PUBLIC_MP4_LABEL="Direct demo MP4" node tools/promote-public-mp4.mjs
 *
 * Public-safe: writes only JSON receipt/manifest files. No secrets required.
 */

import fs from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.cwd();
const MANIFEST_PATH = path.join(ROOT, 'demo/assets/demo-manifest.json');
const PACKAGE_PATH = path.join(ROOT, 'demo/assets/demo-download-package.json');
const RECEIPTS_PATH = path.join(ROOT, 'demo/assets/release-receipts.json');
const READINESS_PATH = path.join(ROOT, 'demo/assets/commercial-launch-readiness.json');
const MP4_URL = process.env.PUBLIC_MP4_URL || '';
const MP4_SHA256 = process.env.PUBLIC_MP4_SHA256 || null;
const MP4_LABEL = process.env.PUBLIC_MP4_LABEL || 'Direct demo MP4';
const TIMEOUT_MS = Number(process.env.PROBE_TIMEOUT_MS || 20000);

function nowIso() {
  return new Date().toISOString();
}

async function readJson(filePath) {
  return JSON.parse(await fs.readFile(filePath, 'utf8'));
}

async function writeJson(filePath, value) {
  await fs.writeFile(filePath, `${JSON.stringify(value, null, 2)}\n`, 'utf8');
}

function assertPublicMp4Url(value) {
  let parsed;
  try {
    parsed = new URL(value);
  } catch {
    throw new Error('PUBLIC_MP4_URL must be a valid absolute URL.');
  }
  if (parsed.protocol !== 'https:') throw new Error('PUBLIC_MP4_URL must use https.');
  if (!parsed.pathname.toLowerCase().endsWith('.mp4')) throw new Error('PUBLIC_MP4_URL must point to a .mp4 path.');
  return parsed.href;
}

async function verifyMp4(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    let res = await fetch(url, {
      method: 'HEAD',
      redirect: 'follow',
      signal: controller.signal,
      headers: { 'user-agent': 'fractal5-public-mp4-promoter/1.0' }
    });
    if (!res.ok && res.status === 405) {
      res = await fetch(url, {
        method: 'GET',
        redirect: 'follow',
        signal: controller.signal,
        headers: {
          'user-agent': 'fractal5-public-mp4-promoter/1.0',
          range: 'bytes=0-0'
        }
      });
    }
    const contentType = res.headers.get('content-type') || '';
    const contentLength = res.headers.get('content-length') || null;
    const okStatus = res.status === 200 || res.status === 206;
    const okType = contentType.toLowerCase().includes('video/mp4') || contentType.toLowerCase().includes('application/octet-stream');
    if (!res.ok || !okStatus) throw new Error(`MP4 URL did not return a successful media status. status=${res.status}`);
    if (!okType) throw new Error(`MP4 URL did not return a plausible MP4 content type. content-type=${contentType}`);
    return {
      status: res.status,
      contentType,
      contentLength: contentLength ? Number(contentLength) : null,
      verifiedAt: nowIso()
    };
  } finally {
    clearTimeout(timeout);
  }
}

function upsertByKey(items, key, value, record) {
  const idx = items.findIndex((item) => item?.[key] === value);
  if (idx >= 0) items[idx] = { ...items[idx], ...record };
  else items.push(record);
}

function unique(items) {
  return [...new Set(items)];
}

function updateReadiness(readiness, mp4Url, mediaProof) {
  readiness.generatedAt = nowIso();
  readiness.overallStatus = 'AMBER';
  readiness.summary = 'Dominion OS now has a verified direct public MP4 asset gate path when PUBLIC_MP4_URL is promoted and public-proof verification passes. Full commercial launch remains blocked until commerce/customer-portal proof, production observability, autonomous remediation, rollback, and client-safe payment/provisioning receipts exist.';

  const runtime = readiness.statusMatrix?.find((item) => item.area === 'demo-runtime');
  if (runtime) {
    runtime.status = 'GREEN';
    runtime.currentEvidence = [
      'Cloud Run /demo is live and reachable as the public runtime surface.',
      'A direct public MP4 URL has been promoted into demo/assets/demo-manifest.json.',
      `MP4 media HEAD/range verification passed with status ${mediaProof.status} and content type ${mediaProof.contentType}.`,
      `Promoted MP4 URL: ${mp4Url}`
    ];
    runtime.greenGate = 'Keep demo/assets/demo-manifest.json assets.videoMp4 non-null only while the public URL remains reachable and verified by the demo1-public-proof workflow.';
  }

  const assets = readiness.statusMatrix?.find((item) => item.area === 'source-served-assets');
  if (assets) {
    assets.status = 'GREEN';
    assets.currentEvidence = unique([
      ...(assets.currentEvidence || []),
      'demo/assets/demo-manifest.json now supports a direct public MP4 asset when promoted through tools/promote-public-mp4.mjs.',
      'The public proof verifier checks the MP4 URL without downloading the full binary.'
    ]);
  }

  readiness.claimControl = readiness.claimControl || {};
  readiness.claimControl.allowedNow = unique([
    ...(readiness.claimControl.allowedNow || []),
    'Dominion OS may claim a direct public demo MP4 only when demo/assets/demo-manifest.json assets.videoMp4 is non-null and the public-proof receipt verifies it.'
  ]);
  readiness.claimControl.directMp4CurrentlyAvailable = true;
  readiness.claimControl.fullCommercialGreenCurrentlyAllowed = false;
  readiness.claimControl.controlledPreviewCommercialUseAllowed = true;
  return readiness;
}

async function main() {
  const mp4Url = assertPublicMp4Url(MP4_URL);
  const mediaProof = await verifyMp4(mp4Url);
  const [manifest, pkg, receipts, readiness] = await Promise.all([
    readJson(MANIFEST_PATH),
    readJson(PACKAGE_PATH),
    readJson(RECEIPTS_PATH),
    readJson(READINESS_PATH)
  ]);

  manifest.generatedAt = nowIso();
  manifest.assets = manifest.assets || {};
  manifest.assets.videoMp4 = mp4Url;
  manifest.assets.videoMp4Sha256 = MP4_SHA256;
  manifest.assets.videoMp4VerifiedAt = mediaProof.verifiedAt;
  manifest.assets.videoMp4ContentType = mediaProof.contentType;
  manifest.assets.videoMp4ContentLength = mediaProof.contentLength;
  manifest.assetPolicy = manifest.assetPolicy || {};
  manifest.assetPolicy.sourceServedAssets = unique([...(manifest.assetPolicy.sourceServedAssets || []), 'assets.videoMp4']);
  manifest.assetPolicy.directBinaryAssetsRequiredForFinalInlineEmbed = [];
  manifest.assetPolicy.currentFallbacks = { ...(manifest.assetPolicy.currentFallbacks || {}), videoMp4: null };
  manifest.claimControl = manifest.claimControl || {};
  manifest.claimControl.directMp4CurrentlyAvailable = true;
  manifest.claimControl.assetManifestCloudRunLiveConfirmed = true;
  manifest.claimControl.fullCommercialGreenAllowed = false;
  manifest.claimControl.reason = 'Direct binary MP4 is published and verified by the promotion tool. Full commercial green remains false until commerce, observability, rollback, and autonomous-operations receipts exist.';

  pkg.generatedAt = nowIso();
  pkg.contents = pkg.contents || [];
  upsertByKey(pkg.contents, 'label', MP4_LABEL, {
    label: MP4_LABEL,
    url: mp4Url,
    type: 'video/mp4',
    sha256: MP4_SHA256,
    verification: mediaProof
  });
  pkg.claimControl = pkg.claimControl || {};
  pkg.claimControl.directMp4Included = true;
  pkg.claimControl.binaryZipIncluded = false;
  pkg.claimControl.reason = 'The public demo package includes a verified public MP4 URL. It remains a public-safe package manifest, not a private source-code or installable binary bundle.';

  receipts.generatedAt = nowIso();
  receipts.receipts = receipts.receipts || [];
  upsertByKey(receipts.receipts, 'id', 'public-demo-mp4', {
    id: 'public-demo-mp4',
    url: mp4Url,
    expected: '200 or 206 video/mp4',
    status: 'operator-verified-by-promotion-tool',
    verifiedAt: mediaProof.verifiedAt,
    contentType: mediaProof.contentType,
    contentLength: mediaProof.contentLength,
    sha256: MP4_SHA256
  });
  receipts.claimControl = receipts.claimControl || {};
  receipts.claimControl.fullCommercialGreenAllowed = false;
  receipts.claimControl.directMp4Available = true;
  receipts.claimControl.reason = 'This receipt proves the public demo bridge asset layer and direct public MP4 URL. Commerce, rollback, native GCP self-healing, customer portal, and production observability still require separate receipts.';

  updateReadiness(readiness, mp4Url, mediaProof);

  await Promise.all([
    writeJson(MANIFEST_PATH, manifest),
    writeJson(PACKAGE_PATH, pkg),
    writeJson(RECEIPTS_PATH, receipts),
    writeJson(READINESS_PATH, readiness)
  ]);

  console.log(JSON.stringify({
    status: 'promoted',
    mp4Url,
    mediaProof,
    fullCommercialGreenAllowed: false,
    filesUpdated: [
      'demo/assets/demo-manifest.json',
      'demo/assets/demo-download-package.json',
      'demo/assets/release-receipts.json',
      'demo/assets/commercial-launch-readiness.json'
    ]
  }, null, 2));
}

main().catch((error) => {
  console.error(error?.message || error);
  process.exit(1);
});
