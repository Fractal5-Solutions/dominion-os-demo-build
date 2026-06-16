#!/usr/bin/env node
/*
  Fractal5 /demo-1 live verifier

  Purpose:
  - Run from an unrestricted local/Ultimate Stack machine.
  - Verify the published Squarespace /demo-1 page contains the Chief of Staff block.
  - Verify public Cloud Run and demo-build asset routes respond.

  Usage, bundled Playwright Chromium:
    npm install -D playwright
    npx playwright install chromium
    node tools/verify-demo1-live.mjs

  Low-disk Windows fallback, installed Microsoft Edge:
    npm install -D playwright
    $env:BROWSER_CHANNEL="msedge"
    node tools/verify-demo1-live.mjs

  Low-disk Windows fallback, installed Google Chrome:
    npm install -D playwright
    $env:BROWSER_CHANNEL="chrome"
    node tools/verify-demo1-live.mjs

  Optional env:
    DEMO1_URL=https://www.fractal5solutions.com/demo-1
    DEMO_RUNTIME_URL=https://demo-reduwyf2ra-uc.a.run.app/demo
    DEMO_HEALTH_URL=https://demo-reduwyf2ra-uc.a.run.app/health
    DEMO_STATUS_URL=https://demo-reduwyf2ra-uc.a.run.app/status
    BROWSER_CHANNEL=msedge | chrome | chromium
    CHECK_BRANDED_DOMAIN=1
    BRANDED_DEMO_URL=https://demo.fractal5solutions.com/demo
*/

import { chromium } from 'playwright';

const DEMO1_URL = process.env.DEMO1_URL || 'https://www.fractal5solutions.com/demo-1';
const DEMO_RUNTIME_URL = process.env.DEMO_RUNTIME_URL || 'https://demo-reduwyf2ra-uc.a.run.app/demo';
const DEMO_HEALTH_URL = process.env.DEMO_HEALTH_URL || 'https://demo-reduwyf2ra-uc.a.run.app/health';
const DEMO_STATUS_URL = process.env.DEMO_STATUS_URL || 'https://demo-reduwyf2ra-uc.a.run.app/status';
const CHECK_BRANDED_DOMAIN = process.env.CHECK_BRANDED_DOMAIN === '1';
const BRANDED_DEMO_URL = process.env.BRANDED_DEMO_URL || 'https://demo.fractal5solutions.com/demo';
const BROWSER_CHANNEL = process.env.BROWSER_CHANNEL || '';

const ASSET_URLS = [
  'https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/demo-manifest.json',
  'https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/sample-data.json',
  'https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/demo-download-package.json',
  'https://raw.githubusercontent.com/Fractal5-Solutions/dominion-os-demo-build/main/demo/assets/release-receipts.json'
];

const REQUIRED_TEXT = [
  'DOMINION OS + SAAS SUITE',
  'Dominion OS, live on the cloud.',
  'Politics in Business',
  'Business SaaS Command',
  'Politics Configuration',
  'Executive Proof Review',
  'What zero counters mean',
  'This is a proof surface. It is not the production console.',
  'Request Controlled Access',
  'Branded demo domain: pending DNS/TLS verification before use as primary'
];

const REQUIRED_SELECTORS = [
  '#fractal5-demo1',
  '[data-version="2026-06-16-chief-of-staff-final"]',
  'a[href="https://demo-reduwyf2ra-uc.a.run.app/demo"]',
  'a[href="https://demo-reduwyf2ra-uc.a.run.app/health"]',
  'a[href="https://demo-reduwyf2ra-uc.a.run.app/status"]',
  'a[href="https://www.fractal5solutions.com/#contact"]',
  '.fractal5-copy-prompt'
];

const failures = [];
const results = [];

function record(name, ok, detail = '') {
  const row = { name, ok, detail };
  results.push(row);
  const prefix = ok ? 'PASS' : 'FAIL';
  console.log(`${prefix} ${name}${detail ? ` - ${detail}` : ''}`);
  if (!ok) failures.push(row);
}

function launchOptions() {
  const opts = { headless: true };
  if (BROWSER_CHANNEL) opts.channel = BROWSER_CHANNEL;
  return opts;
}

async function checkFetch(context, url, label, expectJson = false) {
  try {
    const response = await context.request.get(url, { timeout: 20000 });
    const status = response.status();
    record(`${label} HTTP`, status >= 200 && status < 300, `${status} ${url}`);
    if (expectJson && status >= 200 && status < 300) {
      const data = await response.json();
      record(`${label} JSON parse`, !!data && typeof data === 'object', Object.keys(data).slice(0, 8).join(', '));
      return data;
    }
  } catch (error) {
    record(`${label} HTTP`, false, `${url} :: ${error.message}`);
  }
  return null;
}

async function main() {
  if (BROWSER_CHANNEL) {
    console.log(`Using installed browser channel: ${BROWSER_CHANNEL}`);
  } else {
    console.log('Using bundled Playwright Chromium. Set BROWSER_CHANNEL=msedge or chrome to use an installed browser.');
  }

  const browser = await chromium.launch(launchOptions());
  const context = await browser.newContext({
    viewport: { width: 1440, height: 1200 },
    ignoreHTTPSErrors: false
  });
  const page = await context.newPage();

  try {
    const response = await page.goto(DEMO1_URL, { waitUntil: 'domcontentloaded', timeout: 30000 });
    const status = response ? response.status() : 0;
    record('/demo-1 page load', status >= 200 && status < 300, `${status} ${DEMO1_URL}`);

    await page.waitForTimeout(2000);
    const bodyText = await page.locator('body').innerText({ timeout: 10000 });
    for (const text of REQUIRED_TEXT) {
      record(`Text present: ${text}`, bodyText.includes(text));
    }

    for (const selector of REQUIRED_SELECTORS) {
      const count = await page.locator(selector).count();
      record(`Selector present: ${selector}`, count > 0, `count=${count}`);
    }

    const promptButtons = await page.locator('.fractal5-copy-prompt').count();
    record('Three copy prompt buttons', promptButtons === 3, `count=${promptButtons}`);

    const blankLinks = await page.locator('a[target="_blank"]').evaluateAll((links) => links.map((a) => ({
      href: a.getAttribute('href') || '',
      rel: a.getAttribute('rel') || '',
      referrerpolicy: a.getAttribute('referrerpolicy') || ''
    })));
    const badBlankLinks = blankLinks.filter((link) => !link.rel.includes('noopener') || !link.rel.includes('noreferrer') || link.referrerpolicy !== 'strict-origin-when-cross-origin');
    record('External link hardening', badBlankLinks.length === 0, `checked=${blankLinks.length}; bad=${badBlankLinks.length}`);

    const publicFacingF5 = bodyText.includes('F5 ') || bodyText.includes('F5-') || bodyText.includes('F5_');
    record('No public-facing F5 prefix drift', !publicFacingF5);
  } catch (error) {
    record('/demo-1 browser verification', false, error.message);
  }

  await checkFetch(context, DEMO_RUNTIME_URL, 'Cloud Run demo', false);
  const health = await checkFetch(context, DEMO_HEALTH_URL, 'Health endpoint', true);
  const status = await checkFetch(context, DEMO_STATUS_URL, 'Status endpoint', true);

  if (health) {
    record('Health status ok', health.status === 'ok' || health.status === 'ready' || health.ok === true, JSON.stringify(health).slice(0, 220));
  }
  if (status) {
    const statusText = String(status.status || status.state || '');
    record('Status endpoint has status/state', statusText.length > 0, statusText || JSON.stringify(status).slice(0, 220));
  }

  for (const url of ASSET_URLS) {
    const data = await checkFetch(context, url, `Asset ${url.split('/').pop()}`, true);
    if (data && url.endsWith('sample-data.json')) {
      const serialized = JSON.stringify(data);
      record('Sample data public-safe markers', serialized.includes('productionData') && serialized.includes('customerData') && serialized.includes('secrets') && serialized.includes('paymentData'));
    }
  }

  if (CHECK_BRANDED_DOMAIN) {
    await checkFetch(context, BRANDED_DEMO_URL, 'Branded demo domain', false);
  } else {
    record('Branded demo domain not promoted', true, 'CHECK_BRANDED_DOMAIN not set; Cloud Run remains primary');
  }

  await browser.close();

  const summary = {
    generatedAt: new Date().toISOString(),
    demo1Url: DEMO1_URL,
    runtimeUrl: DEMO_RUNTIME_URL,
    browserChannel: BROWSER_CHANNEL || 'bundled-chromium',
    failures: failures.length,
    results
  };
  console.log('\nJSON_SUMMARY_START');
  console.log(JSON.stringify(summary, null, 2));
  console.log('JSON_SUMMARY_END');

  if (failures.length > 0) {
    process.exitCode = 1;
  }
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
