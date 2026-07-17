#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.cwd();
const CONTRACT_PATH = path.join(ROOT, 'demo/assets/full-commercial-launch-contract.json');
const OUT_DIR = process.env.OUT_DIR || path.join(ROOT, 'out/full-commercial-launch');
const MODE = String(process.env.LAUNCH_PROOF_MODE || 'package').toLowerCase();

const nowIso = () => new Date().toISOString();
const readJson = async (p) => JSON.parse(await fs.readFile(p, 'utf8'));

async function exists(relativePath) {
  try {
    const stat = await fs.stat(path.join(ROOT, relativePath));
    return stat.isFile() && stat.size > 0;
  } catch {
    return false;
  }
}

function collectExternalBlockers(contract) {
  return Object.entries(contract.gates || {})
    .filter(([, gate]) => String(gate.status || '').startsWith('BLOCKED_'))
    .map(([name, gate]) => ({ name, status: gate.status, requiredReceipt: gate.requiredReceipt || null }));
}

async function main() {
  const contract = await readJson(CONTRACT_PATH);
  const documentChecks = [];
  for (const relativePath of contract.requiredDocuments || []) {
    documentChecks.push({ path: relativePath, pass: await exists(relativePath) });
  }

  const packageIntegrity = documentChecks.every((item) => item.pass)
    && contract.commercialMode === 'controlled-invoice-only'
    && contract.selfServeCheckoutClaimed === false
    && contract.customerPortalClaimed === false
    && contract.autonomousSelfHealingClaimed === false;

  const externalBlockers = collectExternalBlockers(contract);
  const liveGreen = packageIntegrity
    && externalBlockers.length === 0
    && contract.claimControl?.controlledInvoiceOnlyCommercialLaunchAllowed === true;

  const receipt = {
    schema: 'f5.dominion.full-commercial-launch-receipt.v1',
    generatedAt: nowIso(),
    mode: MODE,
    packageIntegrityVerdict: packageIntegrity ? 'GREEN' : 'RED',
    commercialLaunchVerdict: liveGreen ? 'GREEN' : 'AMBER_BLOCKED',
    documentChecks,
    externalBlockers,
    claimControl: contract.claimControl || {}
  };

  await fs.mkdir(OUT_DIR, { recursive: true });
  await fs.writeFile(path.join(OUT_DIR, 'latest.json'), `${JSON.stringify(receipt, null, 2)}\n`, 'utf8');
  console.log(JSON.stringify(receipt, null, 2));

  if (!packageIntegrity) process.exitCode = 1;
  if (MODE === 'live' && !liveGreen) process.exitCode = 2;
}

main().catch((error) => {
  console.error(error);
  process.exit(1);
});
