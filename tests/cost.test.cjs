const { test } = require('node:test');
const assert = require('node:assert/strict');
const cost = require('../Sources/Cost.js');

test('uses the requested net purchase rate, not the older extension rate', () => {
  assert.equal(cost.CREDIT_PACK, 10_000);
  assert.equal(cost.PACK_PRICE_USD, 600);
  assert.equal(cost.USD_PER_CREDIT, 0.06);
});
for (const [credits, expected] of [
  [0, 'US$0.00'], [1, 'US$0.06'], [100, 'US$6.00'], [218.77, 'US$13.13'],
  [1_000, 'US$60.00'], [10_000, 'US$600.00'], [50_000, 'US$3,000.00'],
  [0.01, '<US$0.01']
]) test(`formats ${credits} credits as ${expected}`, () => assert.equal(cost.formatCost(credits), expected));
test('supports explicit grouped counts and decimal conventions', () => {
  for (const text of ['10,000', "10'000", '10’000', '10 000', '10\u202f000']) {
    assert.equal(cost.parseNumber(text), 10_000);
  }
  assert.equal(cost.parseNumber('218,77'), 218.77);
  assert.equal(cost.parseNumber('10 000,50'), 10_000.50);
  assert.equal(cost.parseCredits('218.77 credits'), 218.77);
  assert.equal(cost.parseCredits('1 credit'), 1);
  assert.equal(cost.parseCredits('218.77'), 218.77);
});
test('refuses compact, negative, ambiguous and malformed values', () => {
  for (const text of ['10k', '-1', '$600', '100-200', '1,23,456', '1e3', 'Loading…', '', 'NaN', 'Infinity']) {
    assert.equal(cost.parseNumber(text), null, text);
  }
  assert.equal(cost.parseCredits('100 tokens'), null);
  assert.equal(cost.parseCredits(null), null);
  assert.equal(cost.parseNumber('9007199254740992'), null);
});
test('unreadable is never presented as free', () => {
  for (const value of [null, undefined, NaN, Infinity, -1, Number.MAX_VALUE]) {
    assert.equal(cost.formatCost(value), 'Unavailable');
  }
});
