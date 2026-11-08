const { test } = require('node:test');
const assert = require('node:assert/strict');
const { readFileSync } = require('node:fs');
const { join } = require('node:path');
const { JSDOM } = require('jsdom');
const source = readFileSync(join(__dirname, '../Sources/TaskCount.js'), 'utf8');
const row = (id, title = 'Example session') => `<div role="row" data-session-id="${id}"><div role="cell"><button role="checkbox" aria-label="Select session" aria-checked="false"></button>${title}</div><div role="cell">Now</div><div role="cell"><button aria-label="Session options">Options</button></div></div>`;
const chrome = `<div role="tablist" aria-label="Session dashboard tabs"><button role="tab" aria-selected="true">Sessions</button><button role="tab" aria-selected="false">Unread</button></div><button>Status: Active</button><button>Project</button>`;
const four = `${chrome}<button aria-expanded="true">Pinned</button><div role="table" aria-label="Pinned">${row('one')}${row('two')}${row('three')}</div><button aria-expanded="true">Today</button><div role="table" aria-label="Today">${row('four')}<div role="row"><div role="cell"></div></div></div>`;
function setup(html = four, url = 'https://www.perplexity.ai/computer/tasks?status=active') {
  const dom = new JSDOM(html, { url, runScripts: 'outside-only' });
  dom.window.eval(source);
  return { dom, doc: dom.window.document, read: () => JSON.parse(JSON.stringify(dom.window.ActiveTaskCount.read())) };
}
function using(html, body, url) {
  const context = setup(html, url);
  try { body(context); } finally { context.dom.window.close(); }
}
test('three pinned plus one ordinary session produce 4, not the loading sentinel', () => {
  using(four, ({ read }) => assert.deepEqual(read(), { version: 1, status: 'ready', count: 4, lowerBound: false }));
});
test('read follows live insertion, removal, and completion instead of fixing the value to 4', () => {
  using(four, ({ read, doc }) => {
    doc.querySelector('[data-session-id=four]').remove();
    assert.equal(read().count, 3);
    doc.querySelector('[role=table]').insertAdjacentHTML('beforeend', row('five') + row('six'));
    assert.equal(read().count, 5);
  });
});
test('counts multi-digit lists without truncation', () => {
  using(chrome + `<div role="table">${Array.from({ length: 12 }, (_, i) => row(String(i))).join('')}</div>`,
    ({ read }) => assert.equal(read().count, 12));
});
test('ignores sidebar links, navigation tables, dialogs and menu clones', () => {
  using(four + `<nav><div role="table">${row('side')}</div><button aria-expanded="false">Pinned</button></nav><div role="dialog"><div role="table">${row('dialog')}</div></div><div role="menu"><div role="table">${row('menu')}</div></div>`,
    ({ read }) => assert.equal(read().count, 4));
});
test('ignores the composer attachment button rather than treating it as a collapsed group', () => {
  using(four + '<button aria-expanded="false" aria-label="Add files, plugins, and more"></button>',
    ({ read }) => assert.equal(read().count, 4));
});
test('ignores hidden stale rows but not a row with a hidden hover-selection checkbox', () => {
  using(four + `<div hidden role="table">${row('hidden')}</div>`, ({ read, doc }) => {
    doc.querySelector('[role=checkbox]').style.display = 'none';
    assert.equal(read().count, 4);
  });
});
test('deduplicates explicit session identifiers, not repeated titles', () => {
  using(chrome + `<div role="table">${row('same')}${row('same')}${row('different')}</div>`,
    ({ read }) => assert.equal(read().count, 2));
});
test('supports session-link deduplication when explicit identifiers are absent', () => {
  using(chrome + `<div role="table">${row('one').replace('data-session-id="one"', '').replace('Example session', '<a href="/session/example">Example</a>')}${row('two').replace('data-session-id="two"', '').replace('Example session', '<a href="/session/example">Example</a>')}</div>`,
    ({ read }) => assert.equal(read().count, 1));
});
test('confirmed empty active dashboard produces a genuine zero', () => {
  using(chrome + '<p>No active sessions yet</p>', ({ read }) => assert.equal(read().count, 0));
});
test('empty/loading markup never invents zero', () => {
  using(chrome, ({ read }) => assert.equal(read().status, 'unknown'));
  using('', ({ read }) => assert.equal(read().status, 'unknown'));
});
test('busy page is unavailable, not an old exact count', () => {
  using(four + '<div aria-busy="true"></div>', ({ read }) => assert.equal(read().reason, 'loading'));
});
test('sign-in screen and offline state never become zero', () => {
  using(four + '<button>Sign in</button>', ({ read }) => assert.equal(read().reason, 'auth'));
  using(four, ({ read, dom }) => {
    Object.defineProperty(dom.window.navigator, 'onLine', { value: false });
    assert.equal(read().reason, 'offline');
  });
});
test('rejects unrelated origins, detail pages, missing/other status, and project URL filters', () => {
  for (const url of [
    'https://evilperplexity.ai/computer/tasks?status=active',
    'https://accounts.google.com/computer/tasks?status=active',
    'https://www.perplexity.ai/computer/tasks/example',
    'https://www.perplexity.ai/account/org/credits-usage',
    'https://www.perplexity.ai/computer/tasks',
    'https://www.perplexity.ai/computer/tasks?status=completed',
    'https://www.perplexity.ai/computer/tasks?status=active&project=example'
  ]) using(four, ({ read }) => assert.equal(read().status, 'unknown', url), url);
});
test('rejects a selected project or Unread tab even if the URL still looks global', () => {
  using(four.replace('<button>Project</button>', '<button>Project: Example</button>'),
    ({ read }) => assert.equal(read().reason, 'filtered'));
  using(four.replace('aria-selected="true">Sessions', 'aria-selected="false">Sessions').replace('aria-selected="false">Unread', 'aria-selected="true">Unread'),
    ({ read }) => assert.equal(read().reason, 'filtered'));
});
test('read never opens a collapsed group; only the separate monitor helper expands it', () => {
  using(four.replace('aria-expanded="true">Pinned', 'aria-expanded="false">Pinned'), ({ read, doc, dom }) => {
    let clicks = 0;
    const button = [...doc.querySelectorAll('button')].find(b => b.textContent === 'Pinned');
    button.addEventListener('click', () => { clicks++; button.setAttribute('aria-expanded', 'true'); });
    assert.equal(read().reason, 'collapsed');
    assert.equal(clicks, 0);
    assert.equal(dom.window.ActiveTaskCount.expandGroups(), 1);
    assert.equal(clicks, 1);
    assert.equal(read().count, 4);
  });
});
test('large or explicitly paginated lists are marked as lower bounds', () => {
  using(chrome + `<div role="table">${Array.from({ length: 50 }, (_, i) => row(String(i))).join('')}</div>`,
    ({ read }) => assert.equal(read().lowerBound, true));
  using(four + '<button>Load more sessions</button>', ({ read }) => assert.equal(read().lowerBound, true));
  using(four.replace('role="table" aria-label="Today"', 'role="table" aria-label="Today" aria-rowcount="100"'),
    ({ read }) => assert.equal(read().lowerBound, true));
});
test('reader changes no original content and makes no fetch requests', () => {
  using(four, ({ read, doc, dom }) => {
    const before = doc.body.innerHTML;
    dom.window.fetch = () => { throw Error('No API calls permitted'); };
    assert.equal(read().count, 4);
    assert.equal(doc.body.innerHTML, before);
  });
});
test('repeated script injection is idempotent', () => {
  using(four, ({ read, dom }) => {
    const previous = dom.window.ActiveTaskCount;
    dom.window.eval(source);
    assert.equal(previous, dom.window.ActiveTaskCount);
    assert.equal(read().count, 4);
  });
});
