import { test } from 'node:test';
import assert from 'node:assert/strict';
import { planStages, missingPreconditions, pendingStages } from './scheduler.js';
import { StateManager } from './state-manager.js';
import { mkdtempSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';

const stateOf = (over = {}) => {
  const s = StateManager.fresh();
  return { ...s, stages: { ...s.stages, ...over } };
};

test('planStages：默认全流程且固定序', () => {
  const p = planStages(null);
  assert.deepEqual(p.stages, ['scan', 'skeleton', 'bridge', 'report']);
});

test('planStages：子集保序（乱序输入→固定执行序）', () => {
  const p = planStages(['bridge', 'scan']);
  assert.deepEqual(p.stages, ['scan', 'bridge']);
});

test('planStages：非法阶段名→失败（码 2 语义源）', () => {
  assert.equal(planStages(['scanx']).ok, false);
  assert.equal(planStages([]).ok, false);
});

test('missingPreconditions：仅选 bridge 无 scan 产物→缺失（码 3/场景 5）', () => {
  const m = missingPreconditions(['bridge'], stateOf());
  assert.equal(m.length, 1);
  assert.ok(m[0].includes('bridge 需要 scan'));
});

test('missingPreconditions：上游已在计划内或已 done→无缺失', () => {
  assert.deepEqual(missingPreconditions(['scan', 'bridge'], stateOf()), []);
  assert.deepEqual(missingPreconditions(['bridge'], stateOf({ scan: { status: 'done', artifacts: [] } })), []);
});

test('pendingStages：续跑跳过 done/skipped', () => {
  const st = stateOf({ scan: { status: 'done', artifacts: [] }, report: { status: 'skipped', artifacts: [] } });
  assert.deepEqual(pendingStages(['scan', 'skeleton', 'bridge', 'report'], st), ['skeleton', 'bridge']);
});
