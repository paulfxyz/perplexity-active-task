/* Active Task | MIT License
 * Parser adapted from Paul Fleury's MIT-licensed pplx-cost-transparency.
 * This app uses the newly specified NET rate, not that project's old rate.
 */
(function (root) {
  'use strict';
  const CREDIT_PACK = 10_000;
  const PACK_PRICE_USD = 600;
  const USD_PER_CREDIT = PACK_PRICE_USD / CREDIT_PACK;
  const formatter = new Intl.NumberFormat('en-US', {
    style: 'currency', currency: 'USD', minimumFractionDigits: 2, maximumFractionDigits: 2
  });
  function parseNumber(text) {
    if (typeof text !== 'string') return null;
    let amount = text.replace(/[\u00a0\u202f]/g, ' ').replace(/[\u2018\u2019]/g, "'").trim();
    if (/^\d+(?:\.\d+)?$/.test(amount)) {
      // Plain decimal.
    } else if (/^\d{1,3}(?:,\d{3})+(?:\.\d+)?$/.test(amount)) {
      amount = amount.replace(/,/g, '');
    } else if (/^\d{1,3}([' ])\d{3}(?:\1\d{3})*(?:[.,]\d+)?$/.test(amount)) {
      amount = amount.replace(/[' ]/g, '').replace(',', '.');
    } else if (/^\d+,\d{1,2}$/.test(amount)) {
      amount = amount.replace(',', '.');
    } else return null;
    const value = Number(amount);
    return Number.isFinite(value) && value >= 0 && value <= Number.MAX_SAFE_INTEGER ? value : null;
  }
  function parseCredits(text) {
    if (typeof text !== 'string') return null;
    const match = text.trim().match(/^(.+?)\s+credits?$/i);
    return parseNumber(match ? match[1] : text);
  }
  function formatCost(credits) {
    if (!Number.isFinite(credits) || credits < 0 || credits > Number.MAX_SAFE_INTEGER) return 'Unavailable';
    const equivalent = credits * USD_PER_CREDIT;
    if (!Number.isFinite(equivalent)) return 'Unavailable';
    if (equivalent > 0 && equivalent < 0.01) return '<US$0.01';
    return formatter.format(equivalent).replace(/^\$/, 'US$');
  }
  const api = Object.freeze({ CREDIT_PACK, PACK_PRICE_USD, USD_PER_CREDIT, parseNumber, parseCredits, formatCost });
  if (typeof module === 'object' && module.exports) module.exports = api;
  else root.ActiveTaskCost = api;
})(globalThis);
