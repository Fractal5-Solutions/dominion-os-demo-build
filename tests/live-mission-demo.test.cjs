const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const test = require('node:test');
const vm = require('node:vm');
const {createHash} = require('node:crypto');

const html = fs.readFileSync(path.join(__dirname, '../demo/live-mission-demo.html'), 'utf8');
const script = html.match(/<script>([\s\S]*?)<\/script>/)[1];

// Execute the shipped script with a controlled clock and minimal DOM. Browser
// walkthroughs separately validate native focus, layout and button activation.
function load(mode = 'business', autoplay = false) {
  const nodes = new Map([['log', {innerHTML: '<div><b>System</b> Demo workspace loaded.</div>'}]]);
  const timers = new Map();
  let timerId = 0;
  let keydown;
  const tabs = ['business', 'politics'].map(value => ({
    dataset: {mode: value},
    classList: {
      active: value === 'business',
      add() { this.active = true; },
      remove() { this.active = false; },
      toggle(_name, active) { this.active = active; },
    },
  }));
  const context = vm.createContext({
    URLSearchParams,
    window: {location: {search: `?mode=${mode}&autoplay=${autoplay ? '1' : '0'}`}},
    document: {
      getElementById(id) {
        if (!nodes.has(id)) nodes.set(id, {innerHTML: '', textContent: ''});
        return nodes.get(id);
      },
      querySelectorAll(selector) { assert.equal(selector, '.tab'); return tabs; },
      addEventListener(name, callback) { assert.equal(name, 'keydown'); keydown = callback; },
    },
    setInterval(callback) { timers.set(++timerId, callback); return timerId; },
    clearInterval(id) { timers.delete(id); },
  });
  vm.runInContext(script, context);
  const run = code => vm.runInContext(code, context);
  return {
    run, tabs, timers,
    state: () => nodes.get('state').textContent,
    mission: () => nodes.get('mission').innerHTML,
    log: () => nodes.get('log').innerHTML,
    tick: () => { for (const callback of [...timers.values()]) callback(); },
    key(key, extra = {}) {
      let prevented = false;
      keydown({key, target: {closest: () => null}, preventDefault() { prevented = true; }, ...extra});
      return prevented;
    },
  };
}

for (const mode of ['business', 'politics']) {
  test(`${mode}: full explicit walkthrough produces its own synthetic receipt`, () => {
    const demo = load(mode);
    assert.equal(demo.state(), 'MISSION');
    for (const state of ['SITUATION', 'INTELLIGENCE', 'OPTIONS', 'DECISION']) {
      demo.run('next()');
      assert.equal(demo.state(), state);
    }
    demo.run('approve()');
    assert.equal(demo.state(), 'EXECUTION');
    demo.run('next()');
    assert.equal(demo.state(), 'EVIDENCE');
    assert.match(demo.mission(), mode === 'business' ? /DEMO-BUS-001/ : /DEMO-POL-001/);
    assert.match(demo.mission(), /EXTERNAL CONNECTOR: NOT CLAIMED LIVE IN THIS BUILD/);
    assert.doesNotMatch(demo.mission(), mode === 'business' ? /DEMO-POL-001/ : /DEMO-BUS-001/);
  });

  test(`${mode}: autoplay stops at authority and cannot undo a held decision`, () => {
    const demo = load(mode, true);
    const queuedCallback = [...demo.timers.values()][0];
    for (let i = 0; i < 4; i++) demo.tick();
    assert.equal(demo.state(), 'DECISION');
    assert.equal(demo.timers.size, 0);
    demo.run('reject()');
    queuedCallback(); // Also reject an already queued timer after cancellation.
    demo.tick();
    assert.equal(demo.state(), 'DECISION');
    assert.doesNotMatch(demo.log(), /approval recorded/);
    assert.match(demo.log(), /Decision held/);
    demo.run('approve()');
    assert.equal(demo.state(), 'EXECUTION');
  });

  test(`${mode}: forward navigation never grants approval`, () => {
    const demo = load(mode);
    for (let i = 0; i < 4; i++) demo.key('ArrowRight');
    demo.run('next()');
    demo.key(' ');
    demo.key('ArrowRight');
    assert.equal(demo.state(), 'DECISION');
    assert.doesNotMatch(demo.log(), /approval recorded/);
  });

  test(`${mode}: reset cancels playback and returns a clean canonical mission`, () => {
    const demo = load(mode, true);
    demo.tick();
    demo.key('r');
    assert.equal(demo.timers.size, 0);
    demo.tick();
    assert.equal(demo.state(), 'MISSION');
    assert.equal(demo.log(), '<div><b>System</b> Demo workspace reset.</div>');
    assert.equal(demo.run('approved'), false);
  });

  test(`${mode}: revisiting decision requires fresh explicit approval`, () => {
    const demo = load(mode);
    for (let i = 0; i < 4; i++) demo.run('next()');
    demo.run('approve()');
    demo.key('ArrowLeft');
    demo.key('ArrowRight');
    assert.equal(demo.state(), 'DECISION');
    assert.equal(demo.run('approved'), false);
  });
}

test('switching contexts cancels playback and discards previous authority and logs', () => {
  const demo = load('business', true);
  demo.tick();
  demo.tabs[1].onclick();
  assert.equal(demo.timers.size, 0);
  assert.equal(demo.state(), 'MISSION');
  assert.match(demo.mission(), /Legislative Session Readiness/);
  assert.doesNotMatch(demo.mission(), /Northstar/);
  assert.equal(demo.log(), '<div><b>System</b> Demo workspace reset.</div>');
  assert.equal(demo.tabs[1].classList.active, true);
  demo.key('b');
  assert.match(demo.mission(), /Northstar/);
  assert.equal(demo.tabs[0].classList.active, true);
});

test('shortcuts preserve native focused-control activation and browser modifiers', () => {
  const demo = load();
  for (const key of [' ', 'ArrowRight', 'r', 'b', 'p']) {
    assert.equal(demo.key(key, {target: {closest: selector => selector.includes('input') ? {tagName: 'INPUT'} : null}}), false);
    assert.equal(demo.key(key, {ctrlKey: true}), false);
    assert.equal(demo.key(key, {metaKey: true}), false);
    assert.equal(demo.key(key, {altKey: true}), false);
    assert.equal(demo.key(key, {repeat: true}), false);
  }
  assert.equal(demo.key(' ', {target: {closest: selector => selector === 'button,a' ? {tagName: 'BUTTON'} : null}}), false);
  assert.equal(demo.state(), 'MISSION');
});

test('reset shortcut still works after a focused Hold button', () => {
  const demo = load();
  for (let i = 0; i < 4; i++) demo.run('next()');
  demo.run('reject()');
  demo.key('r', {target: {closest: selector => selector === 'button,a' ? {tagName: 'BUTTON'} : null}});
  assert.equal(demo.state(), 'MISSION');
});

test('approval outside the decision stage does not jump or create evidence', () => {
  const demo = load();
  demo.run('approve()');
  assert.equal(demo.state(), 'MISSION');
  assert.doesNotMatch(demo.log(), /approval recorded/);
});

test('interactive receipt binds current bytes independently of historical films', () => {
  const manifest = JSON.parse(fs.readFileSync(path.join(__dirname, '../demo/assets/live-mission-video-manifest.json'), 'utf8'));
  assert.equal(manifest.interactive_public_demo.source_html_sha256, createHash('sha256').update(html).digest('hex'));
  assert.equal(manifest.interactive_public_demo.external_connector_claim, 'not_live');
  assert.equal(manifest.sources.public_demo.html_sha256, '5789702b1fabcb20b48bcdf81bef7e32ff723f9b135199ad82588d5edbda831d');
});
