#!/usr/bin/env node
import fs from 'node:fs/promises';
import path from 'node:path';

const ROOT = process.cwd();
const CONTRACT_PATH = path.join(ROOT, 'demo/assets/full-commercial-launch-contract.json');
const OUT_DIR = process.env.OUT_DIR || path.join(ROOT, 'out/full-commercial-launch');
const MODE = String(process.env.LAUNCH_PROOF_MODE || 'package').toLowerCase();

const REQUIRED_DOCUMENTS = [
  'docs/commercial/INVOICE_ONLY_SALES_MOTION.md',
  'docs/commercial/CUSTOMER_LIFECYCLE.md',
  'docs/operations/INCIDENT_RESPONSE_AND_ROLLBACK.md'
];

const REQUIRED_LIVE_GATES = [
  'authoritativePublicRuntimeCutover',
  'invoiceProcurement',
  'customerLifecycle',
  'observabilityAlerting',
  'rollbackIncidentResponse'
];

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

function gateIsReceiptBackedGreen(gate) {
  if (!gate || gate.status !== 'GREEN') return false;
  const evidence = gate.evidence || gate.receipt || gate.receiptPath || gate.publicReceipt;
  return typeof evidence === 'string' && evidence.trim().length > 0;
}

async function main() {
  const contract = await readJson(CONTRACT_PATH);
  const configuredDocuments = contract.requiredDocuments;
  const requiredDocumentContractValid = Array.isArray(configuredDocuments)
    && configuredDocuments.length === REQUIRED_DOCUMENTS.length
    && REQUIRED_DOCUMENTS.every((item) => configuredDocuments.includes(item));

  const documentChecks = [];
  for (const relativePath of REQUIRED_DOCUMENTS) {
    documentChecks.push({
      path: relativePath,
      declared: Array.isArray(configuredDocuments) && configuredDocuments.includes(relativePath),
      pass: await exists(relativePath)
    });
  }

  const claimControl = contract.claimControl || {};
  const launchFlagsFailClosed = claimControl.controlledInvoiceOnlyCommercialLaunchAllowed === false
    && claimControl.fullSelfServeSaasLaunchAllowed === false
    && claimControl.fullCommercialGreenAllowed === false;

  const packageIntegrity = requiredDocumentContractValid
    && documentChecks.every((item) => item.declared && item.pass)
    && contract.commercialMode === 'controlled-invoice-only'
    && contract.selfServeCheckoutClaimed === false
    && contract.customerPortalClaimed === false
    && contract.autonomousSelfHealingClaimed === false
    && (MODE === 'live' || launchFlagsFailClosed);

  const liveGateChecks = REQUIRED_LIVE_GATES.map((name) => {
    const gate = contract.gates?.[name];
    return {
      name,
      status: gate?.status || 'MISSING',
      evidence: gate?.evidence || gate?.receipt || gate?.receiptPath || gate?.publicReceipt || null,
      pass: gateIsReceiptBackedGreen(gate)
    };
  });

  const externalBlockers = liveGateChecks
    .filter((gate) => !gate.pass)
    .map((gate) => ({
      name: gate.name,
      status: gate.status,
      requiredReceipt: contract.gates?.[gate.name]?.requiredReceipt || null
    }));

  const liveEvidenceGreen = packageIntegrity && liveGateChecks.every((gate) => gate.pass);
  const promotionFlagSet = claimControl.controlledInvoiceOnlyCommercialLaunchAllowed === true;
  const incompatibleClaimsRemainFalse = claimControl.fullSelfServeSaasLaunchAllowed === false
    && claimControl.fullCommercialGreenAllowed === false;
  const liveGreen = liveEvidenceGreen && promotionFlagSet && incompatibleClaimsRemainFalse;

  const receipt = {
    schema: 'f5.dominion.full-commercial-launch-receipt.v2',
    generatedAt: nowIso(),
    mode: MODE,
    packageIntegrityVerdict: packageIntegrity ? 'GREEN' : 'RED',
    liveEvidenceVerdict: liveEvidenceGreen ? 'GREEN' : 'AMBER_BLOCKED',
    commercialLaunchVerdict: liveGreen ? 'GREEN' : 'AMBER_BLOCKED',
    requiredDocumentContractValid,
    launchFlagsFailClosed,
    promotionFlagSet,
    documentChecks,
    liveGateChecks,
    externalBlockers,
    claimControl
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
