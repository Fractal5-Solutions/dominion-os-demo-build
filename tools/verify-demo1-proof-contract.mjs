#!/usr/bin/env node
import fs from 'node:fs/promises';

const repository = String(process.env.GITHUB_REPOSITORY || '');
const proofMode = String(process.env.PROOF_MODE || 'live').toLowerCase();
const proofSha = String(process.env.PROOF_SOURCE_SHA || process.env.GITHUB_SHA || '');
const watchlist = JSON.parse(await fs.readFile('demo/assets/demo-1-watchlist.json', 'utf8'));

const failures = [];
const requireNonEmpty = (name, value) => {
  if (!Array.isArray(value) || value.length === 0) failures.push(`${name} must be a non-empty array`);
};

requireNonEmpty('requiredAssertions', watchlist.requiredAssertions);
requireNonEmpty('requiredHardeningAssertions', watchlist.requiredHardeningAssertions);

if (proofMode === 'pr') {
  if (!repository) failures.push('GITHUB_REPOSITORY is required in PR mode');
  if (!proofSha) failures.push('PROOF_SOURCE_SHA is required in PR mode');
  const expectedPrefix = `https://raw.githubusercontent.com/${repository}/`;
  for (const [name, url] of Object.entries(watchlist.sourceServedAssets || {})) {
    if (typeof url !== 'string' || !url.startsWith(expectedPrefix)) {
      failures.push(`sourceServedAssets.${name} must belong to ${repository}`);
    }
  }
}

const receipt = {
  schema: 'f5.demo1.proof-contract.receipt.v1',
  generatedAt: new Date().toISOString(),
  proofMode,
  proofSourceSha: proofSha || null,
  repository: repository || null,
  liveAssertions: Array.isArray(watchlist.requiredAssertions) ? watchlist.requiredAssertions.length : 0,
  hardeningAssertions: Array.isArray(watchlist.requiredHardeningAssertions) ? watchlist.requiredHardeningAssertions.length : 0,
  pass: failures.length === 0,
  failures,
};

await fs.mkdir('out/demo1-public-proof', { recursive: true });
await fs.writeFile('out/demo1-public-proof/contract-guard.json', `${JSON.stringify(receipt, null, 2)}\n`);
console.log(JSON.stringify(receipt, null, 2));
if (!receipt.pass) process.exit(1);
