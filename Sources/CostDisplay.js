/* Active Task | MIT License
 * Semantic DOM approach inspired by paulfxyz/pplx-cost-transparency.
 * Runs in WebKit's isolated world. No network, cookies, or native bridge.
 */
(() => {
  'use strict';
  if (globalThis.ActiveTaskCostDisplay) return;
  let instance;
  function start(environment = {}) {
    const page = environment.location || location;
    if (page.hostname !== 'perplexity.ai' && !page.hostname.endsWith('.perplexity.ai')) return;
    if (instance) return instance;
    const money = globalThis.ActiveTaskCost;
    if (!money) return;
    const ANCHOR = 'button[aria-label="About session usage" i]';
    const OWN = '[data-at-cost-row], [data-at-cost-org]';
    const ORG_LABEL = /^Available\s+(?:org|organization|organisation)\s+credits$/i;
    const RATE = `US$${money.PACK_PRICE_USD.toLocaleString('en-US')} net / ${money.CREDIT_PACK.toLocaleString('en-US')} credits = US$${money.USD_PER_CREDIT} per credit. Account-specific estimate, not an invoice.`;
    const sessions = new Map();
    const organizations = new Map();
    let queued = false;
    let suspended = false;
    let lastPath = '';
    const isSession = () => /^\/computer\/tasks\/[^/]+\/?$/.test(page.pathname);
    const isOrganization = () => /^\/account\/org\/credits-usage\/?$/.test(page.pathname);
    const owned = node => (node.nodeType === Node.ELEMENT_NODE ? node : node.parentElement)?.closest(OWN);
    const style = (node, rules) => Object.assign(node.style, rules);
    function sourceFor(anchor) {
      const native = anchor.closest('.group\\/context-pane-row');
      if (native && native.children.length <= 4 && native.lastElementChild &&
          !native.lastElementChild.contains(anchor)) return native;
      let row = anchor.parentElement;
      for (let depth = 0; row && depth < 6; depth++, row = row.parentElement) {
        const value = row.lastElementChild;
        if (row.children.length >= 2 && row.children.length <= 4 && value &&
            !value.contains(anchor) && !value.querySelector('a, button, input') &&
            row.querySelectorAll(ANCHOR).length === 1 &&
            /Session\s+usage/i.test(row.textContent) && row.textContent.length < 160 &&
            (money.parseCredits(value.textContent) !== null ||
             /^(?:Loading[.…]*|Unavailable|[-…]|\s*)$/i.test(value.textContent.trim()))) return row;
      }
      return null;
    }
    function makeSession(source) {
      const row = document.createElement('div');
      row.className = source.className;
      row.setAttribute('data-at-cost-row', '');
      row.setAttribute('role', 'group');
      row.setAttribute('aria-label', 'Estimated session cost in US dollars');
      style(row, { display: 'flex', alignItems: 'center', gap: '8px', padding: '8px',
                   fontSize: '14px', lineHeight: '20px' });
      const icon = document.createElement('span');
      icon.textContent = '$';
      icon.setAttribute('aria-hidden', 'true');
      style(icon, { flex: '0 0 16px', textAlign: 'center' });
      const label = document.createElement('div');
      label.textContent = 'Cost equivalent';
      style(label, { flex: '1 1 auto', minWidth: '0' });
      const value = document.createElement('div');
      value.className = source.lastElementChild.className;
      value.setAttribute('data-at-cost-value', '');
      value.setAttribute('aria-live', 'polite');
      value.setAttribute('aria-atomic', 'true');
      value.setAttribute('dir', 'ltr');
      style(value, { flex: '0 0 auto', marginInlineStart: 'auto', whiteSpace: 'nowrap',
                     textAlign: 'right', fontVariantNumeric: 'tabular-nums' });
      row.append(icon, label, value);
      return { row, value };
    }
    function rawText(node) {
      if (node.nodeType === Node.TEXT_NODE) return node.nodeValue;
      if (node.nodeType !== Node.ELEMENT_NODE || node.matches(OWN)) return '';
      return Array.from(node.childNodes, rawText).join('');
    }
    function organizationSources() {
      const result = new Map();
      if (!isOrganization() || !document.body) return result;
      const walker = document.createTreeWalker(document.body, NodeFilter.SHOW_TEXT);
      let text;
      while ((text = walker.nextNode())) {
        if (!ORG_LABEL.test(text.nodeValue.trim()) || owned(text)) continue;
        const label = text.parentElement;
        for (const block of [label.nextElementSibling, label.parentElement?.nextElementSibling]) {
          if (!block || block.matches('a,button,input,select,table') ||
              block.querySelector('a,button,input,select,table')) continue;
          let source = block;
          while (true) {
            const children = Array.from(source.children).filter(child => !child.matches(OWN));
            if (children.length !== 1 || !/^(DIV|SPAN|P)$/.test(children[0].tagName)) break;
            source = children[0];
          }
          const raw = rawText(source).trim();
          if (raw.length > 80 || source.contains(label)) continue;
          if (money.parseNumber(raw) === null && !/^(?:Loading[.…]*|[-…]|\s*)$/i.test(raw)) continue;
          result.set(source, label);
          break;
        }
      }
      return result;
    }
    function sync() {
      queued = false;
      if (suspended) return;
      lastPath = page.pathname;
      const sources = new Set();
      if (isSession()) for (const anchor of document.querySelectorAll(ANCHOR)) {
        const source = sourceFor(anchor);
        if (source && !owned(source)) sources.add(source);
      }
      for (const [source, mount] of sessions) if (!sources.has(source) || !source.isConnected) {
        mount.row.remove(); sessions.delete(source);
      }
      for (const source of sources) {
        let mount = sessions.get(source);
        if (!mount) { mount = makeSession(source); sessions.set(source, mount); }
        if (source.nextElementSibling !== mount.row) source.after(mount.row);
        const credits = money.parseCredits(source.lastElementChild.textContent.trim());
        const next = credits === null ? 'Unavailable' : money.formatCost(credits);
        if (mount.value.textContent !== next) mount.value.textContent = next;
        const title = `Estimated equivalent of session credits USED. ${RATE} Follows only the displayed count and its reporting delay.`;
        if (mount.row.title !== title) mount.row.title = title;
      }
      const orgSources = organizationSources();
      for (const [source, mount] of organizations) if (!orgSources.has(source) || !source.isConnected) {
        mount.row.remove(); organizations.delete(source);
      }
      for (const [source, label] of orgSources) {
        let mount = organizations.get(source);
        if (!mount) {
          const row = document.createElement('span');
          row.setAttribute('data-at-cost-org', '');
          row.setAttribute('aria-live', 'polite');
          row.setAttribute('aria-atomic', 'true');
          row.setAttribute('dir', 'ltr');
          style(row, { display: 'inline', marginInlineStart: '0.35em',
                       whiteSpace: 'nowrap', font: 'inherit', fontVariantNumeric: 'tabular-nums' });
          mount = { row, label };
          organizations.set(source, mount);
        }
        const credits = money.parseNumber(rawText(source).trim());
        const next = credits === null ? '(Unavailable)' : `(${money.formatCost(credits)})`;
        if (mount.row.textContent !== next) mount.row.textContent = next;
        const title = `Cost equivalent of the available organization credit pool, NOT money spent or cash redeemable. ${RATE}`;
        if (mount.row.title !== title) {
          mount.row.title = title;
          mount.row.setAttribute('aria-label', title);
        }
        if (mount.row.parentElement !== source) source.append(mount.row);
      }
    }
    function schedule() {
      if (queued || suspended) return;
      queued = true;
      queueMicrotask(sync);
    }
    function changed(records) {
      if (suspended) return;
      if (page.pathname !== lastPath) { schedule(); return; }
      for (const record of records) {
        if (owned(record.target)) continue;
        for (const [source, { row }] of sessions) {
          if (!source.isConnected || !row.isConnected || source.contains(record.target)) { schedule(); return; }
        }
        for (const [source, { row, label }] of organizations) {
          if (!source.isConnected || !row.isConnected || !label.isConnected ||
              source.contains(record.target) || label.contains(record.target)) { schedule(); return; }
        }
        if (isOrganization()) { schedule(); return; }
        if (record.type === 'attributes' && record.target.matches?.(ANCHOR)) { schedule(); return; }
        for (const node of record.addedNodes || []) {
          if (owned(node)) continue;
          if (node.nodeType === Node.ELEMENT_NODE && (node.matches(ANCHOR) || node.querySelector(ANCHOR))) {
            schedule(); return;
          }
        }
      }
    }
    const observer = new MutationObserver(changed);
    function observe() {
      observer.observe(document.documentElement, {
        subtree: true, childList: true, characterData: true, attributes: true, attributeFilter: ['aria-label']
      });
    }
    observe();
    window.addEventListener('popstate', schedule);
    window.addEventListener('pagehide', () => { suspended = true; observer.disconnect(); });
    window.addEventListener('pageshow', () => { suspended = false; observe(); schedule(); });
    document.addEventListener('visibilitychange', () => { if (!document.hidden) schedule(); });
    instance = { refresh: sync };
    schedule();
    return instance;
  }
  globalThis.ActiveTaskCostDisplay = Object.freeze({ start });
  start();
})();
