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

function flattenUrls(watchlist) {
  const urls = [];
  function add(name, url, kind) {
    if (typeof url === 'string' && url.startsWith('https://')) {
      urls.push({ name, url, kind });
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
  return urls;
}

async function fetchWithTimeout(url) {
  const controller = new AbortController();
  const timeout = setTimeout(() => controller.abort(), TIMEOUT_MS);
  try {
    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: { 'user-agent': 'fractal5-demo1-public-proof/1.0' }
    });
    const text = await res.text();
    return {
      ok: res.ok,
      status: res.status,
      contentType: res.headers.get('content-type') || '',
      bytes: Buffer.byteLength(text),
      body: text.slice(0, 750000)
    };
  } catch (error) {
    return {
      ok: false,
      status: 0,
      contentType: '',
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

function contentTypePass(kind, contentType) {
  if (kind === 'json') return contentType.includes('json') || contentType.includes('text/plain');
  if (kind === 'svg') return contentType.includes('svg') || contentType.includes('xml') || contentType.includes('text/plain');
  return contentType.includes('html') || contentType.includes('text/plain');
}

function deriveVerdict(results, assertionResults, claimDriftResults, manifest) {
  const routeFailures = results.filter((r) => !r.ok || r.status !== 200);
  const typeFailures = results.filter((r) => !contentTypePass(r.kind, r.contentType));
  const assertionFailures = assertionResults.filter((r) => !r.pass);
  const claimDriftFailures = claimDriftResults.filter((r) => !r.pass);
  const directMp4 = manifest?.assets?.videoMp4 || null;

  if (routeFailures.length > 0) return 'RED';
  if (typeFailures.length > 0) return 'AMBER';
  if (assertionFailures.length > 0) return 'AMBER';
  if (!directMp4 && claimDriftFailures.length > 0) return 'AMBER';
  return 'GREEN';
}

async function main() {
  const watchlist = await readJson(WATCHLIST_PATH);
  const manifest = await readJson(MANIFEST_PATH);
  const urls = flattenUrls(watchlist);

  const results = [];
  for (const item of urls) {
    const fetched = await fetchWithTimeout(item.url);
    results.push({
      name: item.name,
      url: item.url,
      kind: item.kind,
      ok: fetched.ok,
      status: fetched.status,
      contentType: fetched.contentType,
      bytes: fetched.bytes,
      error: fetched.error || null,
      contentTypePass: contentTypePass(item.kind, fetched.contentType)
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

  const verdict = deriveVerdict(results, assertionResults, claimDriftResults, manifest);
  const receipt = {
    schema: 'f5.demo1.public-proof.receipt.v1',
    generatedAt: nowIso(),
    strict: STRICT,
    verdict,
    manifestVideoMp4: directMp4,
    fullCommercialGreenAllowed: Boolean(manifest?.claimControl?.fullCommercialGreenAllowed),
    summary: {
      urlsChecked: results.length,
      failedUrls: results.filter((r) => !r.ok || r.status !== 200).length,
      failedAssertions: assertionResults.filter((r) => !r.pass).length,
      claimDriftFailures: claimDriftResults.filter((r) => !r.pass).length
    },
    results,
    assertionResults,
    claimDriftResults,
    claimControl: {
      allowControlledPreview: verdict !== 'RED',
      allowDirectMp4Claim: Boolean(directMp4),
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
