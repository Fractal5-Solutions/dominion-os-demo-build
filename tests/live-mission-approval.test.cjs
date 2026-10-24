// Run with: node --test tests/live-mission-approval.test.cjs
// Execute the shipped inline script with a minimal DOM and controllable timers.
// This verifies behavior without browser dependencies or external requests.
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const vm = require('node:vm');
const { test } = require('node:test');

const html = fs.readFileSync(path.join(__dirname, '..', 'demo', 'live-mission-demo.html'), 'utf8');
const scripts = [...html.matchAll(/<script\b[^>]*>([\s\S]*?)<\/script>/g)];
assert.equal(scripts.length, 1, 'Inspect any new script dependency before extending this harness.');
const source = scripts[0][1];

function createDemo(query = '') {
  const nodes = new Map([['log', { innerHTML: '<div><b>System</b> Demo workspace loaded.</div>' }]]);
  const listeners = new Map();
  const timers = new Map();
  let timerId = 0;
  const tabs = ['business', 'politics'].map(mode => {
    const classes = new Set(mode === 'business' ? ['active'] : []);
    return {
      dataset: { mode },
      classList: {
        add: name => classes.add(name),
        remove: name => classes.delete(name),
        toggle(name, enabled) { enabled ? classes.add(name) : classes.delete(name); },
        contains: name => classes.has(name),
      },
    };
  });
  const context = vm.createContext({
    URLSearchParams,
    Date,
    window: { location: { search: query } },
    document: {
      getElementById(id) {
        if (!nodes.has(id)) nodes.set(id, { innerHTML: '', textContent: '' });
        return nodes.get(id);
      },
      querySelectorAll(selector) {
        assert.equal(selector, '.tab');
        return tabs;
      },
      addEventListener: (type, listener) => listeners.set(type, listener),
    },
    setInterval(callback) { timers.set(++timerId, callback); return timerId; },
    clearInterval: id => timers.delete(id),
  });
  vm.runInContext(source, context, { filename: 'live-mission-demo.html' });
  const run = code => vm.runInContext(code, context);
  return {
    run,
    get state() { return JSON.parse(run('JSON.stringify({mode,idx,approved,held})')); },
    get mission() { return nodes.get('mission').innerHTML; },
    get log() { return nodes.get('log').innerHTML; },
    get note() { return nodes.get('stateNote').textContent; },
    get timerCount() { return timers.size; },
    get activeMode() { return tabs.find(tab => tab.classList.contains('active')).dataset.mode; },
    tick(count = 1) {
      for (let i = 0; i < count; i++) {
        for (const [id, callback] of [...timers]) if (timers.has(id)) callback();
      }
    },
    switchMode(mode) { tabs.find(tab => tab.dataset.mode === mode).onclick(); },
    key(key, ancestorSelector = null, modifiers = {}) {
      const target = { closest: selector => ancestorSelector && selector.split(',').map(s => s.trim()).includes(ancestorSelector) ? target : null };
      const event = { key, target, defaultPrevented: false, preventDefault() { this.defaultPrevented = true; }, ...modifiers };
      listeners.get('keydown')(event);
      return event.defaultPrevented;
    },
  };
}

for (const mode of ['business', 'politics']) {
  const otherMode = mode === 'business' ? 'politics' : 'business';

  test(`${mode}: query selects the requested mission and tab`, () => {
    const demo = createDemo(`?mode=${mode.toUpperCase()}`);
    assert.deepEqual(demo.state, { mode, idx: 0, approved: false, held: false });
    assert.equal(demo.activeMode, mode);
  });

  test(`${mode}: autoplay pauses at Decision without recording approval`, () => {
    const demo = createDemo(`?mode=${mode}&autoplay=1`);
    demo.tick(4);
    assert.deepEqual(demo.state, { mode, idx: 4, approved: false, held: false });
    assert.equal(demo.timerCount, 0);
    demo.tick(20);
    assert.equal(demo.state.idx, 4);
    assert.doesNotMatch(demo.log, /approval recorded/i);
    assert.match(demo.note, /explicit simulated approval/i);
  });

  test(`${mode}: Hold persists through ticks, restart attempts, and navigation`, () => {
    const demo = createDemo(`?mode=${mode}&autoplay=1`);
    demo.tick(4);
    demo.run('reject();startAutoplay()');
    demo.tick(20);
    demo.key('ArrowLeft');
    demo.run('next()');
    demo.key('ArrowRight');
    demo.key(' ');
    assert.deepEqual(demo.state, { mode, idx: 4, approved: false, held: true });
    assert.equal(demo.timerCount, 0);
    assert.match(demo.note, /decision held/i);
    assert.doesNotMatch(demo.log, /approval recorded/i);
  });

  test(`${mode}: generic navigation cannot cross the unapproved decision`, () => {
    const demo = createDemo(`?mode=${mode}`);
    demo.run('next();next();next();next()');
    for (let i = 0; i < 3; i++) {
      demo.run('next()');
      demo.key('ArrowRight');
      demo.key(' ');
    }
    assert.equal(demo.state.idx, 4);
    assert.equal(demo.state.approved, false);
    assert.doesNotMatch(demo.mission, /Simulated decision receipt/);
  });

  test(`${mode}: explicit approval produces only a simulated receipt`, () => {
    const demo = createDemo(`?mode=${mode}&autoplay=1`);
    demo.tick(4);
    demo.run('reject();approve()');
    assert.deepEqual(demo.state, { mode, idx: 5, approved: true, held: false });
    assert.match(demo.log, /Simulated (CEO|leadership) approval recorded/);
    assert.match(demo.log, /No real authority or external action/);
    demo.tick(2);
    assert.equal(demo.state.idx, 6);
    assert.equal(demo.timerCount, 0);
    assert.match(demo.mission, /SIMULATED RECEIPT — NO REAL AUTHORITY OR EXTERNAL ACTION/);
    assert.match(demo.mission, /EXTERNAL CONNECTOR: NOT CLAIMED LIVE IN THIS BUILD/);
  });

  test(`${mode}: shortcuts preserve native activation and editable controls`, () => {
    const demo = createDemo(`?mode=${mode}`);
    demo.run('next();next();next();next()');
    for (const selector of ['button', 'input', 'select', 'textarea', 'a[href]', '[contenteditable]', "[role='button']"]) {
      for (const key of [' ', 'Enter', 'ArrowRight', 'ArrowLeft', 'r', 'b', 'p']) {
        assert.equal(demo.key(key, selector), false, `${selector}: ${key} must retain its native event`);
        assert.deepEqual(demo.state, { mode, idx: 4, approved: false, held: false });
      }
    }
    for (const modifiers of [{ ctrlKey: true }, { altKey: true }, { metaKey: true }, { defaultPrevented: true }]) {
      demo.key('r', null, modifiers);
      assert.equal(demo.state.idx, 4);
    }
  });

  test(`${mode}: reset clears Hold and approval and restarts one autoplay timer`, () => {
    const demo = createDemo(`?mode=${mode}&autoplay=1`);
    demo.tick(4);
    demo.run('reject();resetFlow()');
    assert.deepEqual(demo.state, { mode, idx: 0, approved: false, held: false });
    assert.equal(demo.timerCount, 1);
    assert.doesNotMatch(demo.log, /decision held/i);
    demo.tick(4);
    demo.run('approve();resetFlow()');
    assert.equal(demo.state.approved, false);
    assert.equal(demo.timerCount, 1);
    demo.tick();
    assert.equal(demo.state.idx, 1, 'Only one timer advances the mission.');
  });

  test(`${mode}: tab and keyboard mode changes clear mission authority state`, () => {
    const demo = createDemo(`?mode=${mode}&autoplay=1`);
    demo.tick(4);
    demo.run('reject()');
    demo.switchMode(otherMode);
    assert.deepEqual(demo.state, { mode: otherMode, idx: 0, approved: false, held: false });
    assert.equal(demo.activeMode, otherMode);
    assert.equal(demo.timerCount, 1);
    demo.tick(4);
    demo.run('approve()');
    demo.key(mode[0]);
    assert.deepEqual(demo.state, { mode, idx: 0, approved: false, held: false });
    assert.equal(demo.activeMode, mode);
    assert.equal(demo.timerCount, 1);
  });
}

test('unknown modes fail to the synthetic business default', () => {
  const demo = createDemo('?mode=unknown');
  assert.equal(demo.state.mode, 'business');
  assert.equal(demo.activeMode, 'business');
  assert.equal(demo.timerCount, 0);
});

test('business receipt reconciles with the visible synthetic sources and intelligence cards', () => {
  const demo = createDemo('?mode=business');
  demo.run('next()');
  const sourceCount = [...demo.mission.matchAll(/<tr>/g)].length - 1;
  demo.run('next()');
  const conflictCount = [...demo.mission.matchAll(/class="state conflicted"/g)].length;
  const unknownCount = [...demo.mission.matchAll(/class="state unknown"/g)].length;
  assert.ok(conflictCount > 0 && unknownCount > 0, 'The scenario exposes its conflict and unknown cards.');
  demo.run('next();next();approve();next()');
  assert.match(demo.mission, new RegExp(`EVIDENCE: ${sourceCount} synthetic sources`));
  assert.match(demo.mission, new RegExp(`MATERIAL CONFLICTS: ${conflictCount}(?:\\n|<)`));
  assert.match(demo.mission, new RegExp(`OPEN UNCERTAINTIES: ${unknownCount}(?:\\n|<)`));
});

test('politics receipt reconciles with the visible synthetic sources, change, and assigned workstreams', () => {
  const demo = createDemo('?mode=politics');
  demo.run('next()');
  const sourceCount = [...demo.mission.matchAll(/<tr>/g)].length - 1;
  demo.run('next()');
  const changeCount = [...demo.mission.matchAll(/class="state confirmed">NEW<\/div>/g)].length;
  const conflictCount = [...demo.mission.matchAll(/class="state conflicted"/g)].length;
  demo.run('next();next();approve()');
  const assignedCount = [...demo.mission.matchAll(/class="state confirmed">ASSIGNED<\/div>/g)].length;
  for (const workstream of ['Fiscal analysis', 'Stakeholder review', 'Legislative briefing']) {
    assert.match(demo.mission, new RegExp(`<h3>${workstream}</h3><p class="small">Synthetic `));
  }
  assert.equal(assignedCount, 3);
  demo.run('next()');
  assert.match(demo.mission, new RegExp(`AUTHORITATIVE SOURCES: ${sourceCount} synthetic sources`));
  assert.match(demo.mission, new RegExp(`MATERIAL CHANGES: ${changeCount}(?:\\n|<)`));
  assert.match(demo.mission, new RegExp(`SOURCE CONFLICTS: ${conflictCount}(?:\\n|<)`));
  assert.match(demo.mission, new RegExp(`SIMULATED AUTHORIZED WORKSTREAMS: ${assignedCount}(?:\\n|<)`));
  assert.match(demo.mission, /POLITICAL POSITION: NOT SELECTED BY SYSTEM/);
});

test('the mission remains self-contained with no external execution surface', () => {
  assert.doesNotMatch(source, /\b(?:fetch|XMLHttpRequest|WebSocket|sendBeacon|importScripts)\s*\(/);
  assert.doesNotMatch(html, /\b(?:src|href|action)\s*=/i);
  assert.match(html, /Approvals and receipts are simulated and grant no real authority/);
  assert.match(html, /No customer data, confidential party data, voter targeting, production mutation/);
});
