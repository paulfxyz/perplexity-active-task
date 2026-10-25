const { test } = require('node:test');
const assert = require('node:assert/strict');
const fs = require('node:fs');
const path = require('node:path');
const { JSDOM } = require('jsdom');
const calculator = fs.readFileSync(path.join(__dirname, '../Sources/Cost.js'), 'utf8');
const display = fs.readFileSync(path.join(__dirname, '../Sources/CostDisplay.js'), 'utf8');
const session = value => `<section id="usage"><div class="group/context-pane-row"><span>icon</span><span>Session usage <button aria-label="About session usage">i</button></span><span id="credits">${value}</span></div></section>`;
const organization = (label = 'Available org credits', value = '10,000') =>
  `<section id="organization"><div><span>${label}</span></div><div id="pool">${value}</div></section><section><span>Monthly spend</span><div>320</div></section><section><span>Refill amount</span><div>50,000</div></section>`;
const tick = () => new Promise(resolve => setTimeout(resolve, 10));
async function setup(html, url = 'https://www.perplexity.ai/computer/tasks/sample') {
  const dom = new JSDOM(html, { url, runScripts: 'outside-only' });
  dom.window.eval(calculator);
  dom.window.eval(display);
  await tick();
  const close = dom.window.close.bind(dom.window);
  dom.window.close = () => {
    dom.window.dispatchEvent(new dom.window.Event('pagehide'));
    close();
  };
  return dom;
}

test('adds exactly one row immediately below native Session usage', async () => {
  const dom = await setup(session('218.77 credits'));
  try {
    const doc = dom.window.document;
    const row = doc.querySelector('[data-at-cost-row]');
    assert.equal(row.previousElementSibling.querySelector('#credits').textContent, '218.77 credits');
    assert.match(row.textContent, /Cost equivalentUS\$13\.13/);
    assert.match(row.title, /US\$600 net \/ 10,000 credits/);
    assert.match(row.title, /not an invoice/i);
    assert.equal(doc.querySelectorAll('[data-at-cost-row]').length, 1);
  } finally { dom.window.close(); }
});
test('updates after both text-node and subtree changes', async () => {
  const dom = await setup(session('100 credits'));
  try {
    const doc = dom.window.document;
    doc.querySelector('#credits').firstChild.nodeValue = '200 credits';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-value]').textContent, 'US$12.00');
    doc.querySelector('#credits').textContent = '1,000 credits';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-value]').textContent, 'US$60.00');
  } finally { dom.window.close(); }
});
test('does not duplicate rows after React remounts or script reinjection', async () => {
  const dom = await setup(session('100 credits'));
  try {
    const doc = dom.window.document;
    dom.window.eval(display);
    doc.querySelector('#usage').outerHTML = session('300 credits');
    await tick();
    assert.equal(doc.querySelectorAll('[data-at-cost-row]').length, 1);
    assert.equal(doc.querySelector('[data-at-cost-value]').textContent, 'US$18.00');
  } finally { dom.window.close(); }
});
test('removes and restores the row as the usage panel closes and opens', async () => {
  const dom = await setup(session('100 credits'));
  try {
    const doc = dom.window.document;
    doc.querySelector('#usage').remove();
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-row]'), null);
    doc.body.innerHTML = session('200 credits');
    await tick();
    assert.equal(doc.querySelectorAll('[data-at-cost-row]').length, 1);
  } finally { dom.window.close(); }
});
test('unreadable session values show Unavailable and recover', async () => {
  const dom = await setup(session('100 credits'));
  try {
    const doc = dom.window.document;
    doc.querySelector('#credits').textContent = '10k credits';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-value]').textContent, 'Unavailable');
    doc.querySelector('#credits').textContent = '0 credits';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-value]').textContent, 'US$0.00');
  } finally { dom.window.close(); }
});
test('adds available-pool equivalent without converting refill or spend totals', async () => {
  const dom = await setup(organization(), 'https://www.perplexity.ai/account/org/credits-usage');
  try {
    const doc = dom.window.document;
    assert.equal(doc.querySelectorAll('[data-at-cost-org]').length, 1);
    assert.equal(doc.querySelector('#pool').firstChild.nodeValue, '10,000');
    assert.equal(doc.querySelector('[data-at-cost-org]').textContent, '(US$600.00)');
    assert.match(doc.querySelector('[data-at-cost-org]').title, /NOT money spent/);
    assert.equal(doc.querySelector('[data-at-cost-row]'), null);
  } finally { dom.window.close(); }
});
test('supports the three explicit English organization label variants', async () => {
  for (const label of ['Available org credits', 'Available organization credits', 'Available organisation credits']) {
    const dom = await setup(organization(label), 'https://perplexity.ai/account/org/credits-usage');
    try { assert.equal(dom.window.document.querySelector('[data-at-cost-org]').textContent, '(US$600.00)'); }
    finally { dom.window.close(); }
  }
});
test('organization updates do not read their own dollar suffix', async () => {
  const dom = await setup(organization(), 'https://www.perplexity.ai/account/org/credits-usage');
  try {
    const doc = dom.window.document;
    doc.querySelector('#pool').firstChild.nodeValue = '5,000';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-org]').textContent, '(US$300.00)');
    doc.querySelector('#pool').textContent = '2,000';
    await tick();
    assert.equal(doc.querySelectorAll('[data-at-cost-org]').length, 1);
    assert.equal(doc.querySelector('[data-at-cost-org]').textContent, '(US$120.00)');
  } finally { dom.window.close(); }
});
test('loading pool shows Unavailable while compact unsupported values hide the suffix', async () => {
  const dom = await setup(organization(), 'https://www.perplexity.ai/account/org/credits-usage');
  try {
    const doc = dom.window.document;
    doc.querySelector('#pool').textContent = 'Loading…';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-org]').textContent, '(Unavailable)');
    doc.querySelector('#pool').textContent = '10k';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-org]'), null);
    doc.querySelector('#pool').textContent = '10,000';
    await tick();
    assert.equal(doc.querySelector('[data-at-cost-org]').textContent, '(US$600.00)');
  } finally { dom.window.close(); }
});
test('SPA navigation removes obsolete rows and mounts the correct display', async () => {
  const dom = await setup(session('100 credits'));
  try {
    dom.reconfigure({ url: 'https://www.perplexity.ai/account/org/credits-usage' });
    dom.window.document.body.innerHTML = organization();
    await tick();
    assert.equal(dom.window.document.querySelector('[data-at-cost-row]'), null);
    assert.equal(dom.window.document.querySelector('[data-at-cost-org]').textContent, '(US$600.00)');
    dom.reconfigure({ url: 'https://www.perplexity.ai/computer/tasks?status=active' });
    dom.window.dispatchEvent(new dom.window.PopStateEvent('popstate'));
    await tick();
    assert.equal(dom.window.document.querySelector('[data-at-cost-org]'), null);
  } finally { dom.window.close(); }
});
test('never modifies unrelated routes or origins', async () => {
  for (const url of [
    'https://www.perplexity.ai/computer/tasks?status=active',
    'https://www.perplexity.ai/account/settings',
    'https://accounts.google.com/computer/tasks/example',
    'https://evilperplexity.ai/computer/tasks/example'
  ]) {
    const dom = await setup(session('100 credits') + organization(), url);
    try { assert.equal(dom.window.document.querySelector('[data-at-cost-row], [data-at-cost-org]'), null); }
    finally { dom.window.close(); }
  }
});
test('bounded fallback handles a modest native row class change', async () => {
  const dom = await setup(session('100 credits').replace('group/context-pane-row', 'updated-row-class'));
  try { assert.equal(dom.window.document.querySelector('[data-at-cost-value]').textContent, 'US$6.00'); }
  finally { dom.window.close(); }
});
