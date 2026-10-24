// Run: node --test tests/preview-handoff.test.cjs
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { createHash, webcrypto } = require('node:crypto');
const { test } = require('node:test');
const root = path.join(__dirname, '..');
const html = fs.readFileSync(path.join(root, 'squarespace/demo-1-final.html'), 'utf8');
const source = html.match(/<script>([\s\S]*?)<\/script>/)[1];
const ids = ['f5-download-demo', 'f5-download-demo-2', 'f5-download-demo-3', 'f5-download-saas-preview'];

function setup(crypto = webcrypto) {
  let requests = 0;
  const nodes = new Map([...ids, 'f5-download-status'].map(id => [id, {
    disabled: false, attributes: {}, listeners: {}, textContent: '',
    setAttribute(name, value) { this.attributes[name] = value; },
    addEventListener(name, callback) { this.listeners[name] = callback; },
  }]));
  const context = vm.createContext({
    crypto, Uint8Array, document: { getElementById: id => nodes.get(id) },
    fetch() { requests++; throw Error('Pending preview must not fetch anything.'); },
  });
  // Expose the lexical integrity helper to tests only, without production hooks.
  const instrumented = source.replace(/\}\)\(\);\s*$/, 'globalThis.__verifyPreviewBytes = verifyPreviewBytes;\n})();');
  assert.notEqual(instrumented, source);
  vm.runInContext(instrumented, context);
  return { nodes, verify: context.__verifyPreviewBytes, get requests() { return requests; } };
}

test('all preview buttons are disabled before and after script execution', () => {
  const buttons = [...html.matchAll(/<button\b([\s\S]*?)>/g)].map(match => match[1]);
  const demo = setup();
  for (const id of ids) {
    const attributes = buttons.find(value => value.includes(`id="${id}"`));
    assert.match(attributes, /\bdisabled\b/);
    assert.match(attributes, /aria-disabled="true"/);
    const node = demo.nodes.get(id);
    assert.equal(node.disabled, true);
    assert.equal(node.attributes['aria-disabled'], 'true');
    node.listeners.click(); // Programmatic dispatch must also stay closed.
    assert.match(node.textContent, /Pending/);
  }
  assert.equal(demo.requests, 0);
  assert.match(demo.nodes.get('f5-download-status').textContent, /No download URL is active/);
  assert.doesNotMatch(source, /\bfetch\s*\(|createObjectURL|window\.open|source\.length/);
});

test('integrity helper accepts only the exact expected ZIP bytes and size', async () => {
  const demo = setup();
  const bytes = new Uint8Array(Buffer.from('synthetic ZIP bytes for integrity acceptance'));
  const hash = createHash('sha256').update(bytes).digest('hex');
  assert.equal(await demo.verify(bytes, hash, bytes.byteLength), bytes);
  const tampered = Uint8Array.from(bytes);
  tampered[0] ^= 1;
  await assert.rejects(demo.verify(tampered, hash, bytes.byteLength), /checksum mismatch/);
  await assert.rejects(demo.verify(bytes, hash, bytes.byteLength + 1), /identity/);
  await assert.rejects(demo.verify(bytes, 'not-a-digest', bytes.byteLength), /identity/);
  await assert.rejects(demo.verify(bytes, hash, 1048577), /identity/);
  await assert.rejects(setup(null).verify(bytes, hash, bytes.byteLength), /verification is unavailable/);
  assert.equal(demo.requests, 0);
});

test('release record and handoff contain no invented Google acceptance or download URL', () => {
  const status = JSON.parse(fs.readFileSync(path.join(root, 'demo/assets/offline-preview-download.json')));
  const handoff = JSON.parse(fs.readFileSync(path.join(root, 'squarespace/demo-1-v2.6-handoff.json')));
  assert.equal(status.publicationState, 'PENDING_GOOGLE_CERTIFICATION');
  assert.equal(status.publicUrl, null);
  assert.equal(status.googleDeployment.certification, 'PENDING');
  assert.equal(status.googleDeployment.acceptedCertificateUrl, null);
  assert.equal(status.googleDeployment.acceptedCertificateSha256, null);
  assert.equal(handoff.publicDownloadUrl, null);
  assert.equal(handoff.acceptedGoogleCertificateUrl, null);
  assert.equal(handoff.automaticDeploymentAuthorized, false);
  assert.equal(handoff.nativeProductOrSaasCertificationClaimed, false);
});

test('immutable Squarespace source, moving alias, build marker, and handoff hash agree', () => {
  const handoff = JSON.parse(fs.readFileSync(path.join(root, 'squarespace/demo-1-v2.6-handoff.json')));
  const moving = fs.readFileSync(path.join(root, handoff.movingAlias));
  const immutable = fs.readFileSync(path.join(root, handoff.canonicalSource));
  assert.deepEqual(moving, immutable);
  assert.equal(createHash('sha256').update(moving).digest('hex'), handoff.sha256);
  assert.ok(html.includes(`data-build="${handoff.build}"`));
  assert.match(html, /Google first: deployment certification pending/);
  assert.match(html, /Core and SaaS\s+completion are not certified/);
  assert.doesNotMatch(html, /Commercial Runtime Verified|Governed release complete|has completed the governed release path/);
});

test('suite preview is separate and cannot activate through either pending release record', () => {
  const handoff = JSON.parse(fs.readFileSync(path.join(root, 'squarespace/demo-1-v2.6-handoff.json')));
  const suite = JSON.parse(fs.readFileSync(path.join(root, 'demo/assets/saas-offline-preview-download.json')));
  assert.equal(handoff.previewReleaseRecords.length, 2);
  assert.deepEqual(handoff.previewReleaseRecords.map(record => record.kind), ['dominion-os', 'saas-suite']);
  assert.ok(handoff.previewReleaseRecords.every(record => record.publicUrl === null));
  assert.equal(suite.publicUrl, null);
  assert.equal(suite.googleDeployment.certification, 'PENDING');
  assert.equal(suite.exactArtifactAcceptance, 'PENDING');
  assert.equal(suite.actualSaasImplementationIncluded, false);
  assert.equal(suite.generalAvailabilityClaim, false);
  assert.match(html, /13 SaaS module examples/);
  assert.match(html, /neutral civic modes/);
  const demo = setup();
  demo.nodes.get('f5-download-saas-preview').listeners.click();
  assert.equal(demo.nodes.get('f5-download-saas-preview').disabled, true);
  assert.equal(demo.nodes.get('f5-download-saas-preview').textContent, 'SaaS Suite Preview - Pending');
  assert.equal(demo.requests, 0);
});
