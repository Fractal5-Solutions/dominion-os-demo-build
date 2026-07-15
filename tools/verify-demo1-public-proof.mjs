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
  return JSON.parse(await fs.readFile(filePath, 'utf8'));
}

function isHttpsUrl(value) {
  if (typeof value !== 'string' || !value.startsWith('https://')) return false;
  try {
    return new URL(value).protocol === 'https:';
  } catch {
    return false;
  }
}

function flattenUrls(watchlist, manifest) {
  const urls = [];
  function add(name, url, kind) {
    if (isHttpsUrl(url)) urls.push({ name, url, kind });
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
  add('asset.videoMp4', manifest?.assets?.videoMp4, 'mp4');
  return urls;
}

function responseResult(res, body = '', error = null) {
  const contentLength = res?.headers?.get?.('content-length') || null;
  return {
    ok: Boolean(res?.ok),
    status: Number(res?.status || 0),
    contentType: res?.headers?.get?.('content-type') || '',
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
      let res = await fetch(url, {
        method: 'HEAD',
        redirect: 'follow',
        signal: controller.signal,
        headers: { 'user-agent': 'fractal5-demo1-public-proof/1.2' }
      });
      if (res.status === 405) {
        res = await fetch(url, {
          method: 'GET',
          redirect: 'follow',
          signal: controller.signal,
          headers: {
            'user-agent': 'fractal5-demo1-public-proof/1.2',
            range: 'bytes=0-0'
          }
        });
      }
      return responseResult(res);
    }

    const res = await fetch(url, {
      method: 'GET',
      redirect: 'follow',
      signal: controller.signal,
      headers: { 'user-agent': 'fractal5-demo1-public-proof/1.2' }
    });
    const body = (await res.text()).slice(0, 750000);
    return responseResult(res, body);
  } catch (error) {
    return responseResult(null, '', error?.message || String(error));
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
  if (kind === 'mp4') {
    return type.includes('video/mp4') || (type.includes('application/octet-stream') && String(url).toLowerCase().includes('.mp4'));
  }
  return type.includes('html') || type.includes('text/plain');
}

function mp4EvidencePass(result, manifest) {
  const directMp4 = manifest?.assets?.videoMp4 || null;
  return Boolean(directMp4 && result?.ok && result?.statusPass && result?.contentTypePass);
}

function deriveVerdict(results, assertionResults, claimDriftResults, directMp4Verified) {
  if (results.some((r) => !r.ok || !r.statusPass)) return 'RED';
  if (results.some((r) => !r.contentTypePass)) return 'AMBER';
  if (assertionResults.some((r) => !r.pass)) return 'AMBER';
  if (claimDriftResults.some((r) => !r.pass)) return 'AMBER';
  if (results.some((r) => r.kind === 'mp4') && !directMp4Verified) return 'AMBER';
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
      contentTypePass: contentTypePass(item.kind, fetched.contentType, item.url),
      body: fetched.body
    });
  }

  const demo1 = results.find((r) => r.name === 'page.demo1')?.body || '';
  const demoRuntime = results.find((r) => r.name === 'runtime.demo')?.body || '';
  const requiredAssertions = (watchlist.requiredAssertions || [])
    .map((text) => String(text).replace(/^page contains\s+/i, '').replace(/^`|`$/g, ''));
  const assertionResults = [
    ...includesAll(demo1, requiredAssertions),
    ...includesAll(demo1, watchlist.requiredHardeningAssertions || [])
  ];

  const directMp4 = manifest?.assets?.videoMp4 || null;
  const runtimeLower = demoRuntime.toLowerCase();
  const forbiddenWhenNoMp4 = watchlist.claimDriftChecks?.forbiddenWhenManifestVideoMp4Null || [];
  const claimDriftResults = forbiddenWhenNoMp4.map((needle) => ({
    assertion: `runtime.demo must not contain ${needle} while assets.videoMp4 is null`,
    pass: Boolean(directMp4) || !runtimeLower.includes(String(needle).toLowerCase())
  }));

  const mp4Result = results.find((r) => r.name === 'asset.videoMp4') || null;
  const directMp4Verified = mp4EvidencePass(mp4Result, manifest);
  const verdict = deriveVerdict(results, assertionResults, claimDriftResults, directMp4Verified);

  const receipt = {
    schema: 'f5.demo1.public-proof.receipt.v2',
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
    results: results.map(({ body, ...result }) => result),
    assertionResults,
    claimDriftResults,
    claimControl: {
      allowControlledPreview: verdict !== 'RED',
      allowDirectMp4Claim: directMp4Verified,
      allowFullCommercialGreen: Boolean(manifest?.claimControl?.fullCommercialGreenAllowed) && verdict === 'GREEN'
    }
  };

  await fs.mkdir(OUT_DIR, { recursive: true });
  await fs.writeFile(path.join(OUT_DIR, 'latest-probe.json'), `${JSON.stringify(receipt, null, 2)}\n`, 'utf8');
  console.log(JSON.stringify(receipt, null, 2));

  if (STRICT && verdict !== 'GREEN') process.exitCode = 1;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
