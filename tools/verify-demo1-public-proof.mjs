#!/usr/bin/env node
/*
 * Dominion OS /demo-1 public proof verifier.
 * Public-safe: fetches only public URLs declared in demo/assets/demo-1-watchlist.json
 * and demo/assets/demo-manifest.json. Emits a JSON receipt. No secrets required.
 */

import fs from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.cwd();
const WATCHLIST_PATH = path.join(ROOT, 'demo/assets/demo-1-watchlist.json');
const MANIFEST_PATH = path.join(ROOT, 'demo/assets/demo-manifest.json');
const OUT_DIR = process.env.OUT_DIR || path.join(ROOT, 'out/demo1-public-proof');
const STRICT = String(process.env.PROBE_STRICT || 'false').toLowerCase() === 'true';
const TIMEOUT_MS = Number(process.env.PROBE_TIMEOUT_MS || 20000);

function nowIso() {
  return new Date().toISOString();
}

async function readJson(filePath) {
  const raw = await fs.readFile(filePath, 'utf8');
  return JSON.parse(raw);
}

function isHttpsUrl(value) {
  if (typeof value !== 'string' || !value.startsWith('https://')) return false;
  try {
    const parsed = new URL(value);
    return parsed.protocol === 'https:';
  } catch {
    return false;
  }
}

function flattenUrls(watchlist, manifest) {
  const urls = [];
  function add(name, url, kind, options = {}) {
    if (isHttpsUrl(url)) {
      urls.push({ name, url, kind, ...options });
    }
  }
  add('page.demo1', watchlist.page?.url, 'html');
  for (const [key, value] of Object.entries(watchlist.runtime || {})) {
    if (key !== 'name') add(`runtime.${key}`, value, key === 'health' || key === 'status' ? 'json' : 'html');
  }
  for (const [key, value] of Object.entries(watchlist.sourceServedAssets || {})) {
    if (key === 'poster') add(`asset.${key}`, value, 'svg');
    else if (key === 'squarespaceCode') add(`asset.${key}`, value, 'html');
    else add(`asset.${key}`, value, 'json');
  }
  add('asset.videoMp4', manifest?.assets?.videoMp4, 'mp4', { optionalWhenNull: true });
  return urls;
}

async function readResponseBody(res, kind) {
  if (kind === 'mp4') return '';
  const text = await res.text();
  return text.slice(0, 750000);
}

function resultFromResponse(res, body = '', error = null) {
  const contentLength = res.headers?.get?.('content-length') || null;
  return {
    ok: res.ok,
    status: res.status,
    contentType: res.headers?.get?.('content-type') || '',
    contentLength: contentLength ? Number(contentLength) : null,
    bytes: body ? Buffer.byteLength(body) : Number(contentLength || 0),
    error,
    body
  };
}

async function fetchWithTimeout(url, kind) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    if (kind === 'mp4') {
      const head = await fetch(url, {
        method: 'HEAD',
        redirect: 'follow',
        signal: controller.signal,
        headers: { 'user-agent': 'fractal5-demo1-public-proof/1.1' }
      });
      if (head.ok || head.status !== 405) return resultFromResponse(head);

      const range = await fetch(url, {
        method: 'GET',
        redirect: 'follow',
        signal: controller.signal,
        headers: {
          'user-agent': 'fractal5-demo1-public-proof/1.1',
          range: 'bytes=0-0'
        }
      });
      return resultFromResponse(range);
    }

    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: { 'user-agent': 'fractal5-demo1-public-proof/1.1' }
    });
    const body = await readResponseBody(res, kind);
    return resultFromResponse(res, body);
  } catch (error) {
    return {
      ok: false,
      status: 0,
      contentType: '',
      contentLength: null,
      bytes: 0,
      error: error?.message || String(error),
      body: ''
    };
  } finally {
    clearTimeout(timeout);
  }
}

function includesAll(body, assertions) {
  return assertions.map((assertion) => ({ assertion, pass: body.includes(assertion) }));
}

function statusPass(kind, status) {
  if (kind === 'mp4') return status === 200 || status === 206;
  return status === 200;
}

function contentTypePass(kind, contentType, url = '') {
  const type = String(contentType || '').toLowerCase();
  if (kind === 'json') return type.includes('json') || type.includes('text/plain');
  if (kind === 'svg') return type.includes('svg') || type.includes('xml') || type.includes('text/plain');
  if (kind === 'mp4') return type.includes('video/mp4') || (type.includes('application/octet-stream') && String(url).toLowerCase().includes('.mp4'));
  return type.includes('html') || type.includes('text/plain');
}

function mp4EvidencePass(result, manifest) {
  const directMp4 = manifest?.assets?.videoMp4 || null;
  if (!directMp4) return false;
  if (!result) return false;
  return Boolean(result.ok && statusPass('mp4', result.status) && result.contentTypePass);
}

function deriveVerdict(results, assertionResults, claimDriftResults, manifest) {
  const routeFailures = results.filter((r) => !r.ok || !statusPass(r.kind, r.status));
  const typeFailures = results.filter((r) => !r.contentTypePass);
  const assertionFailures = assertionResults.filter((r) => !r.pass);
  const claimDriftFailures = claimDriftResults.filter((r) => !r.pass);
  const directMp4 = manifest?.assets?.videoMp4 || null;
  const mp4Result = results.find((r) => r.name === 'asset.videoMp4') || null;

  if (routeFailures.length > 0) return 'RED';
  if (typeFailures.length > 0) return 'AMBER';
  if (assertionFailures.length > 0) return 'AMBER';
  if (directMp4 && !mp4EvidencePass(mp4Result, manifest)) return 'AMBER';
  if (!directMp4 && claimDriftFailures.length > 0) return 'AMBER';
  return 'GREEN';
}

async function main() {
  const watchlist = await readJson(WATCHLIST_PATH);
  const manifest = await readJson(MANIFEST_PATH);
  const urls = flattenUrls(watchlist, manifest);

  const results = [];
  for (const item of urls) {
    const fetched = await fetchWithTimeout(item.url, item.kind);
    results.push({
      name: item.name,
      url: item.url,
      kind: item.kind,
      ok: fetched.ok,
      status: fetched.status,
      statusPass: statusPass(item.kind, fetched.status),
      contentType: fetched.contentType,
      contentLength: fetched.contentLength,
      bytes: fetched.bytes,
      error: fetched.error || null,
      contentTypePass: contentTypePass(item.kind, fetched.contentType, item.url)
    });
    item.body = fetched.body;
  }

  const demo1 = urls.find((u) => u.name === 'page.demo1')?.body || '';
  const demoRuntime = urls.find((u) => u.name === 'runtime.demo')?.body || '';

  const requiredAssertions = (watchlist.requiredAssertions || [])
    .map((text) => String(text).replace(/^page contains\s+/i, '').replace(/^`|`$/g, ''));
  const hardeningAssertions = watchlist.requiredHardeningAssertions || [];
  const assertionResults = [
    ...includesAll(demo1, requiredAssertions),
    ...includesAll(demo1, hardeningAssertions)
  ];

  const forbiddenWhenNoMp4 = watchlist.claimDriftChecks?.forbiddenWhenManifestVideoMp4Null || [];
  const directMp4 = manifest?.assets?.videoMp4 || null;
  const claimDriftResults = forbiddenWhenNoMp4.map((needle) => ({
    assertion: `runtime.demo must not contain ${needle} while assets.videoMp4 is null`,
    pass: Boolean(directMp4) || !demoRuntime.includes(needle)
  }));

  const mp4Result = results.find((r) => r.name === 'asset.videoMp4') || null;
  const directMp4Verified = mp4EvidencePass(mp4Result, manifest);
  const verdict = deriveVerdict(results, assertionResults, claimDriftResults, manifest);
  const receipt = {
    schema: 'f5.demo1.public-proof.receipt.v1',
    generatedAt: nowIso(),
    strict: STRICT,
    verdict,
    manifestVideoMp4: directMp4,
    manifestVideoMp4Verified: directMp4Verified,
    fullCommercialGreenAllowed: Boolean(manifest?.claimControl?.fullCommercialGreenAllowed),
    summary: {
      urlsChecked: results.length,
      failedUrls: results.filter((r) => !r.ok || !r.statusPass).length,
      failedAssertions: assertionResults.filter((r) => !r.pass).length,
      claimDriftFailures: claimDriftResults.filter((r) => !r.pass).length,
      directMp4Checked: Boolean(directMp4),
      directMp4Verified
    },
    results,
    assertionResults,
    claimDriftResults,
    claimControl: {
      allowControlledPreview: verdict !== 'RED',
      allowDirectMp4Claim: directMp4Verified,
      allowFullCommercialGreen: Boolean(manifest?.claimControl?.fullCommercialGreenAllowed) && verdict === 'GREEN'
    }
  };

  await fs.mkdir(OUT_DIR, { recursive: true });
  const outputPath = path.join(OUT_DIR, 'latest-probe.json');
  await fs.writeFile(outputPath, `${JSON.stringify(receipt, null, 2)}\n`, 'utf8');
  console.log(JSON.stringify(receipt, null, 2));

  if (STRICT && verdict !== 'GREEN') {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
