const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const vm = require('node:vm');
const source = readFileSync(new URL('../Sources/Sidebar.js', `file://${__filename}`), 'utf8');

function element({ main = false, parent = null, original = null } = {}) {
  return {
    isConnected: true,
    parentElement: parent,
    attributes: { style: original },
    style: { setProperty(key, value) { this[key] = value; } },
    getAttribute(name) { return this.attributes[name] ?? null; },
    setAttribute(name, value) { this.attributes[name] = value; },
    removeAttribute(name) { delete this.attributes[name]; },
    querySelector() { return main ? {} : null; }
  };
}
function run({ host = 'www.perplexity.ai', elements = [], button = null } = {}) {
  let observer;
  const context = {
    location: { hostname: host }, window: {},
    document: {
      documentElement: {},
      querySelectorAll() { return elements; },
      querySelector() { return button; }
    },
    MutationObserver: class {
      constructor(callback) { observer = callback; }
      observe() {}
    },
    requestAnimationFrame(callback) { callback(); },
    getComputedStyle() { return { display: 'grid' }; }
  };
  vm.runInNewContext(source, context);
  return { state: context.window.__activeTaskSidebar, context, mutate: () => observer() };
}
test('does nothing on non-Perplexity pages', () => {
  assert.equal(run({ host: 'accounts.google.com' }).state, undefined);
  assert.equal(run({ host: 'evilperplexity.ai' }).state, undefined);
});
test('hides a recognized sidebar', () => {
  const node = element();
  run({ elements: [node] });
  assert.equal(node.style.display, 'none');
});
test('never hides a wrapper containing main content', () => {
  const node = element({ main: true });
  const { state } = run({ elements: [node] });
  assert.equal(state.hidden.size, 0);
});
test('restores the exact inline style when disabled', () => {
  const node = element({ original: 'color: red' });
  const { state } = run({ elements: [node] });
  state.setEnabled(false);
  assert.equal(node.attributes.style, 'color: red');
  assert.equal(state.hidden.size, 0);
});
test('removes style attribute if it was absent before', () => {
  const node = element();
  const { state } = run({ elements: [node] });
  state.setEnabled(false);
  assert.equal(node.attributes.style, undefined);
});
test('repairs only a direct two-column grid and restores it', () => {
  const parent = element({ original: 'display: grid' });
  parent.children = [{}, {}];
  const { state } = run({ elements: [element({ parent })] });
  assert.equal(parent.style['grid-template-columns'], 'minmax(0, 1fr)');
  state.setEnabled(false);
  assert.equal(parent.attributes.style, 'display: grid');
});
test('uses explicit collapse button as a fallback', () => {
  let clicks = 0;
  run({ button: { getClientRects: () => [{}], click: () => clicks++ } });
  assert.equal(clicks, 1);
});
test('SPA mutations apply hiding to newly mounted sidebar', () => {
  const elements = [];
  const { state, mutate } = run({ elements });
  elements.push(element());
  mutate();
  assert.equal(state.hidden.size, 1);
});
test('reinitialization reuses the observer and state', () => {
  const { state, context } = run();
  state.setEnabled(false);
  vm.runInNewContext(source, context);
  assert.equal(context.window.__activeTaskSidebar, state);
  assert.equal(state.enabled, false);
});
test('disabled bootstrap never collapses the site sidebar', () => {
  let clicks = 0;
  const { context } = run({ host: 'example.com' });
  context.location.hostname = 'www.perplexity.ai';
  context.window.__activeTaskSidebarEnabled = false;
  context.document.querySelector = () => ({ getClientRects: () => [{}], click: () => clicks++ });
  vm.runInNewContext(source, context);
  assert.equal(clicks, 0);
  assert.equal(context.window.__activeTaskSidebar.enabled, false);
});
