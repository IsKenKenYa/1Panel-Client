import { test } from 'node:test';
import assert from 'node:assert/strict';
import { seedRules } from './curator-seed.js';

function docOf(rules) {
  return { meta: {}, rules };
}

test('播种：仅模块级整标生成 full_direct；已有条目跳过；部分标记不播种', () => {
  const doc = docOf([{ module: '@ohos.router', symbol: null, category: 'reduced_direct', reason: 'r', advice: 'a' }]);
  const markIndex = new Map([
    ['@ohos.router', { moduleMarked: true, symbols: new Map() }],          // 已有条目 → 跳过
    ['@ohos.full', { moduleMarked: true, symbols: new Map() }],            // 整标 → 播种
    ['@ohos.partial', { moduleMarked: false, symbols: new Map([['a', true], ['b', false]]) }] // 部分标记 → 统计不播种
  ]);
  const { seeded, partialModules } = seedRules(doc, markIndex, { sourceLabel: 'OH SDK TEST' });
  assert.equal(seeded.length, 1);
  assert.equal(seeded[0].module, '@ohos.full');
  assert.equal(seeded[0].category, 'full_direct');
  assert.match(seeded[0].reason, /播种/);
  assert.equal(partialModules.length, 1);
  assert.match(partialModules[0], /@ohos.partial/);
});

test('播种幂等：对已播种文档重跑零新增', () => {
  const doc = docOf([]);
  const markIndex = new Map([['@ohos.full', { moduleMarked: true, symbols: new Map() }]]);
  const first = seedRules(doc, markIndex, { sourceLabel: 'X' });
  doc.rules.push(...first.seeded);
  const second = seedRules(doc, markIndex, { sourceLabel: 'X' });
  assert.equal(second.seeded.length, 0);
});
