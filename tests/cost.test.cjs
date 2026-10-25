const { test } = require('node:test');
const assert = require('node:assert/strict');
const cost = require('../Sources/Cost.js');

test('all three clarified credit packs imply the same net rate', () => {
  assert.equal(cost.CREDIT_PACK, 50_000);
  assert.equal(cost.PACK_PRICE_USD, 600);
  assert.equal(cost.USD_PER_CREDIT, 0.012);
  assert.equal(120 / 10_000, cost.USD_PER_CREDIT);
  assert.equal(600 / 50_000, cost.USD_PER_CREDIT);
  assert.equal(1_200 / 100_000, cost.USD_PER_CREDIT);
});
for (const [credits, expected] of [
  [0, 'US$0.00'], [1, 'US$0.01'], [100, 'US$1.20'], [218.77, 'US$2.63'],
  [1_000, 'US$12.00'], [10_000, 'US$120.00'], [50_000, 'US$600.00'],
  [100_000, 'US$1,200.00'], [11_688.38, 'US$140.26'], [11_717.13, 'US$140.61'],
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
