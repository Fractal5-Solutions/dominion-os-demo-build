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
const PROOF_MODE = String(process.env.PROOF_MODE || 'live').toLowerCase();
const TIMEOUT_MS = Number(process.env.PROBE_TIMEOUT_MS || 20000);
const GITHUB_REPOSITORY = String(process.env.GITHUB_REPOSITORY || '');
const GITHUB_SHA = String(process.env.GITHUB_SHA || '');
const PROOF_SOURCE_SHA = String(process.env.PROOF_SOURCE_SHA || GITHUB_SHA || '');

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

function urlPathEndsWith(value, suffix) {
  try {
    return new URL(value).pathname.toLowerCase().endsWith(String(suffix).toLowerCase());
  } catch {
    return false;
  }
}

function pinRawGithubUrlToProofSha(url) {
  if (!GITHUB_REPOSITORY || !PROOF_SOURCE_SHA || !isHttpsUrl(url)) return url;
  try {
    const parsed = new URL(url);
    if (parsed.hostname !== 'raw.githubusercontent.com') return url;
    const parts = parsed.pathname.split('/').filter(Boolean);
    if (parts.length < 4) return url;
    const [owner, repo, _ref, ...fileParts] = parts;
    const candidateRepo = `${owner}/${repo}`.toLowerCase();
    if (candidateRepo !== GITHUB_REPOSITORY.toLowerCase()) return url;
    return `https://raw.githubusercontent.com/${owner}/${repo}/${PROOF_SOURCE_SHA}/${fileParts.join('/')}`;
  } catch {
    return url;
  }
}

function flattenUrls(watchlist, manifest) {
  const urls = [];
  function add(name, url, kind, options = {}) {
    if (isHttpsUrl(url)) {
      urls.push({ name, url, kind, validUrl: true });
      return;
    }
    if (options.requiredWhenPresent && url) {
      urls.push({ name, url: String(url), kind, validUrl: false });
    }
  }
  add('page.demo1', watchlist.page?.url, 'html');
  for (const [key, value] of Object.entries(watchlist.runtime || {})) {
    if (key !== 'name') add(`runtime.${key}`, value, key === 'health' || key === 'status' ? 'json' : 'html');
  }
  for (const [key, value] of Object.entries(watchlist.sourceServedAssets || {})) {
    const sourceServedUrl = pinRawGithubUrlToProofSha(value);
    if (key === 'poster') add(`asset.${key}`, sourceServedUrl, 'svg');
    else if (key === 'squarespaceCode') add(`asset.${key}`, sourceServedUrl, 'html');
    else add(`asset.${key}`, sourceServedUrl, 'json');
  }
  add('asset.videoMp4', manifest?.assets?.videoMp4, 'mp4', { requiredWhenPresent: true });
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
        headers: { 'user-agent': 'fractal5-demo1-public-proof/1.3' }
      });
      if (res.status === 405) {
        res = await fetch(url, {
          method: 'GET',
          redirect: 'follow',
          signal: controller.signal,
          headers: {
            'user-agent': 'fractal5-demo1-public-proof/1.3',
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
      headers: { 'user-agent': 'fractal5-demo1-public-proof/1.3' }
    });
    const body = (await res.text()).slice(0, 750000);
    return responseResult(res, body);
  } catch (error) {
    return responseResult(null, '', error?.message || String(error));
  } finally {
    clearTimeout(timeout);
  }
}

function includesAll(body, assertions, target) {
  return assertions.map((assertion) => ({ assertion, target, pass: body.includes(assertion) }));
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
    return type.includes('video/mp4') || (type.includes('application/octet-stream') && urlPathEndsWith(url, '.mp4'));
  }
  return type.includes('html') || type.includes('text/plain');
}

function mp4EvidencePass(result, manifest) {
  const directMp4 = manifest?.assets?.videoMp4 || null;
  return Boolean(directMp4 && result?.validUrl !== false && result?.ok && result?.statusPass && result?.contentTypePass);
}

function deriveVerdict(results, assertionResults, claimDriftResults, directMp4Verified) {
  if (results.some((r) => !r.ok || !r.statusPass)) return 'RED';
  if (results.some((r) => !r.contentTypePass)) return 'AMBER';
  if (assertionResults.some((r) => !r.pass)) return 'AMBER';
  if (claimDriftResults.some((r) => !r.pass)) return 'AMBER';
  if (results.some((r) => r.kind === 'mp4') && !directMp4Verified) return 'AMBER';
  return 'GREEN';
}

function derivePrIntegrityVerdict(results, assertionResults) {
  const sourceResults = results.filter((r) => r.name.startsWith('asset.'));
  const sourceAssertions = assertionResults.filter((r) => r.target === 'source:squarespace/demo-1-final.html');
  if (sourceResults.some((r) => !r.ok || !r.statusPass || !r.contentTypePass)) return 'RED';
  if (sourceAssertions.some((r) => !r.pass)) return 'RED';
  return 'GREEN';
}

async function main() {
  const watchlist = await readJson(WATCHLIST_PATH);
  const manifest = await readJson(MANIFEST_PATH);
  const urls = flattenUrls(watchlist, manifest);

  const results = [];
  for (const item of urls) {
    if (item.validUrl === false) {
      results.push({
        name: item.name,
        url: item.url,
        kind: item.kind,
        validUrl: false,
        ok: false,
        status: 0,
        statusPass: false,
        contentType: '',
        contentLength: null,
        bytes: 0,
        error: 'invalid or non-HTTPS URL',
        contentTypePass: false
      });
      continue;
    }
    const fetched = await fetchWithTimeout(item.url, item.kind);
    results.push({
      name: item.name,
      url: item.url,
      kind: item.kind,
      validUrl: item.validUrl,
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
  const hardenedSource = results.find((r) => r.name === 'asset.squarespaceCode')?.body || '';
  const requiredAssertions = (watchlist.requiredAssertions || [])
    .map((text) => String(text).replace(/^page contains\s+/i, '').replace(/^`|`$/g, ''));
  const hardeningAssertions = (watchlist.requiredHardeningAssertions || [])
    .map((text) => String(text).replace(/^page contains\s+/i, '').replace(/^`|`$/g, ''));
  const assertionResults = [
    ...includesAll(demo1, requiredAssertions, 'live:/demo-1'),
    ...includesAll(hardenedSource, hardeningAssertions, 'source:squarespace/demo-1-final.html')
  ];

  const directMp4 = manifest?.assets?.videoMp4 || null;
  const runtimeLower = demoRuntime.toLowerCase();
  const forbiddenWhenNoMp4 = watchlist.claimDriftChecks?.forbiddenWhenManifestVideoMp4Null || [];
  const claimDriftResults = forbiddenWhenNoMp4.map((needle) => ({
    assertion: `runtime.demo must not contain ${needle} while assets.videoMp4 is null`,
    target: 'runtime:/demo',
    pass: Boolean(directMp4) || !runtimeLower.includes(String(needle).toLowerCase())
  }));

  const mp4Result = results.find((r) => r.name === 'asset.videoMp4') || null;
  const directMp4Verified = mp4EvidencePass(mp4Result, manifest);
  const verdict = deriveVerdict(results, assertionResults, claimDriftResults, directMp4Verified);
  const prIntegrityVerdict = derivePrIntegrityVerdict(results, assertionResults);

  const receipt = {
    schema: 'f5.demo1.public-proof.receipt.v3',
    generatedAt: nowIso(),
    strict: STRICT,
    proofMode: PROOF_MODE,
    verifierVersion: '1.3-pr-integrity-separated-from-live-readiness',
    proofSourceSha: PROOF_SOURCE_SHA || null,
    verdict,
    prIntegrityVerdict,
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

  if (STRICT) {
    if (PROOF_MODE === 'pr' && prIntegrityVerdict !== 'GREEN') process.exitCode = 1;
    if (PROOF_MODE !== 'pr' && verdict !== 'GREEN') process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
