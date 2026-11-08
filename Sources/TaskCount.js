/* Active Task | MIT. Aggregate DOM reader only; no account APIs, storage or bridge. */
(() => {
  'use strict';
  if (globalThis.ActiveTaskCount) return;
  const unknown = reason => ({ version: 1, status: 'unknown', reason });
  const excluded = element => element.closest('nav, [role="navigation"], [role="dialog"], [role="menu"]');
  const visible = element => {
    for (let node = element; node && node.nodeType === 1; node = node.parentElement) {
      if (node.hidden || node.getAttribute('aria-hidden') === 'true') return false;
      const style = getComputedStyle(node);
      if (style.display === 'none' || style.visibility === 'hidden') return false;
    }
    return true;
  };
  const groupName = /^(Pinned|Today|Yesterday|Earlier|Older|This week|Last week|This month|Last month|(?:Previous|Last) \d+ days|(?:January|February|March|April|May|June|July|August|September|October|November|December)(?: \d{4})?)$/i;
  function collapsedGroups() {
    const labels = new Set([...document.querySelectorAll('[role="table"][aria-label]')]
      .map(table => table.getAttribute('aria-label')));
    return [...document.querySelectorAll('button[aria-expanded="false"]:not([aria-haspopup])')]
      .filter(button => !excluded(button) && visible(button) &&
        (groupName.test(button.textContent.trim()) || labels.has(button.textContent.trim())));
  }
  function expandGroups() {
    // Called ONLY in the dedicated background view, never on the user's page.
    let opened = 0;
    for (const button of collapsedGroups()) {
      button.click();
      opened++;
    }
    return opened;
  }
  function read(environment = {}) {
    const page = environment.location || location;
    if (page.hostname !== 'perplexity.ai' && page.hostname !== 'www.perplexity.ai') return unknown('origin');
    if (!/^\/computer\/tasks\/?$/.test(page.pathname)) return unknown('route');
    const params = new URLSearchParams(page.search);
    if (params.get('status') !== 'active' || [...params.keys()].some(key => key !== 'status')) return unknown('filtered');
    if (navigator.onLine === false) return unknown('offline');
    if ([...document.querySelectorAll('button, a')].some(element => visible(element) &&
        /^(?:Sign in|Log in)$/i.test(element.textContent.trim()))) return unknown('auth');
    const tabs = document.querySelector('[role="tablist"][aria-label="Session dashboard tabs"]');
    if (!tabs || !visible(tabs)) return unknown('loading');
    const selected = tabs.querySelector('[role="tab"][aria-selected="true"]');
    if (!selected || selected.textContent.trim() !== 'Sessions') return unknown('filtered');
    const buttons = [...document.querySelectorAll('button')].filter(button => !excluded(button) && visible(button));
    if (!buttons.some(button => /^Status:\s*Active$/i.test(button.textContent.trim()))) return unknown('filtered');
    // Do not allow a collection/project filter to silently reduce the global count.
    if (!buttons.some(button => button.textContent.trim() === 'Project')) return unknown('filtered');
    if (collapsedGroups().length) return unknown('collapsed');
    if ([...document.querySelectorAll('[aria-busy="true"], [role="progressbar"]')]
        .some(element => !excluded(element) && visible(element))) return unknown('loading');
    const tables = [...document.querySelectorAll('[role="table"]')].filter(table => !excluded(table) && visible(table));
    const rows = tables.flatMap(table => [...table.querySelectorAll('[role="row"]')])
      .filter(row => visible(row) && row.querySelectorAll('[role="cell"]').length >= 2 &&
        row.querySelector('[role="checkbox"][aria-label="Select session"]'));
    const keys = new Set();
    let count = 0;
    for (const row of rows) {
      const key = row.getAttribute('data-session-id') || row.getAttribute('data-task-id') ||
        row.querySelector('a[href^="/session/"], a[href^="/computer/tasks/"]')?.getAttribute('href');
      if (key && keys.has(key)) continue;
      if (key) keys.add(key);
      count++;
    }
    if (count === 0) {
      const empty = [...document.querySelectorAll('[role="status"], [data-testid*="empty"], h1, h2, h3, p')]
        .some(element => !excluded(element) && visible(element) &&
          /^(?:No (?:active )?(?:sessions|tasks)(?: found| yet)?[.!]?|No results(?: found)?[.!]?)$/i.test(element.textContent.trim()));
      if (!empty) return unknown('loading');
    }
    // Large lists may be paginated/virtualized. Never imply their loaded subset
    // is an exact total. A bare number is intended for the small active list.
    const declared = tables.map(table => Number(table.getAttribute('aria-rowcount'))).filter(n => Number.isFinite(n) && n > count);
    const more = buttons.some(button => /^(?:Load|Show) more(?: sessions| tasks)?$/i.test(button.textContent.trim()));
    return { version: 1, status: 'ready', count, lowerBound: count >= 50 || declared.length > 0 || more };
  }
  globalThis.ActiveTaskCount = Object.freeze({ read, expandGroups });
})();
