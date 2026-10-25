// Runs in WebKit's isolated content world, only on Perplexity's main frame.
// Reversible and deliberately conservative: never hide generic <nav> elements.
(() => {
  if (location.hostname !== 'perplexity.ai' &&
      !location.hostname.endsWith('.perplexity.ai')) return;
  const key = '__activeTaskSidebar';
  if (window[key]) { window[key].setEnabled(window[key].enabled); return; }
  const state = {
    enabled: window.__activeTaskSidebarEnabled !== false,
    hidden: new Map(),
    layouts: new Map(),
    scheduled: false,
    observer: null,
    setEnabled(enabled) {
      this.enabled = Boolean(enabled);
      if (!this.enabled) {
        for (const [element, old] of this.hidden) {
          if (old === null) element.removeAttribute('style');
          else element.setAttribute('style', old);
        }
        for (const [element, old] of this.layouts) {
          if (old === null) element.removeAttribute('style');
          else element.setAttribute('style', old);
        }
        this.hidden.clear();
        this.layouts.clear();
      } else this.apply();
    },
    apply() {
      if (!this.enabled) return;
      const selectors = [
        'aside[data-testid="sidebar"]',
        '[data-testid="desktop-sidebar"]',
        '[data-testid="sidebar"]',
        '[data-slot="sidebar"]',
        'aside[aria-label="Sidebar" i]',
        'nav[aria-label="Sidebar" i]',
        'aside[aria-label="Main navigation" i]',
        'nav[aria-label="Main navigation" i]',
        '#sidebar'
      ];
      for (const element of document.querySelectorAll(selectors.join(','))) {
        // Refuse large wrappers containing the actual task list.
        if (element.querySelector('main, [role="main"]')) continue;
        if (!this.hidden.has(element)) {
          this.hidden.set(element, element.getAttribute('style'));
          element.style.setProperty('display', 'none', 'important');
          element.style.setProperty('width', '0', 'important');
          element.style.setProperty('min-width', '0', 'important');
          const parent = element.parentElement;
          // Only repair a direct, two-column sidebar/content grid.
          if (parent && parent.children.length === 2 &&
              getComputedStyle(parent).display === 'grid') {
            if (!this.layouts.has(parent)) this.layouts.set(parent, parent.getAttribute('style'));
            parent.style.setProperty('grid-template-columns', 'minmax(0, 1fr)', 'important');
          }
        }
      }
      // If no stable sidebar hook exists, use the site's explicit collapse action.
      if (this.hidden.size === 0) {
        const close = document.querySelector(
          'button[aria-label="Close sidebar" i], button[aria-label="Collapse sidebar" i], ' +
          'button[title="Collapse sidebar" i]'
        );
        if (close && close.getClientRects().length) close.click();
      }
      // Avoid retaining discarded SPA nodes indefinitely.
      for (const element of this.hidden.keys()) if (!element.isConnected) this.hidden.delete(element);
      for (const element of this.layouts.keys()) if (!element.isConnected) this.layouts.delete(element);
    }
  };
  window[key] = state;
  state.observer = new MutationObserver(() => {
    if (!state.enabled || state.scheduled) return;
    state.scheduled = true;
    requestAnimationFrame(() => { state.scheduled = false; state.apply(); });
  });
  state.observer.observe(document.documentElement, { childList: true, subtree: true });
  state.apply();
})();
