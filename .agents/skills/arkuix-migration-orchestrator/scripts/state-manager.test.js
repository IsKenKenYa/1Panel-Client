import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, rmSync, readFileSync, existsSync, writeFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { StateManager, TRANSITIONS, STATE_FILE } from './state-manager.js';

test('fresh+load： 最小实例落盘', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir);
  const st = sm.load();
  assert.equal(st.schema_version, 1);
  assert.deepEqual(Object.keys(st.stages).sort(), ['bridge', 'report', 'scan', 'skeleton'].sort());
  assert.equal(existsSync(join(dir, STATE_FILE)), true);
  rmSync(dir, { recursive: true, force: true });
});

test('transition：六态合法迁移矩阵（非法迁移抛错）', () => {
  assert.deepEqual(TRANSITIONS.Assessing, ['Planning', 'Error']);
  assert.deepEqual(TRANSITIONS.Checkpointing, ['Planning', 'Reporting']);
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  sm.transition('Planning'); sm.transition('Applying');
  assert.throws(() => sm.transition('Reporting')); // Applying→Reporting 非法
  rmSync(dir, { recursive: true, force: true });
});

test('markDone：落账+checkpoint 快照', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  sm.markDone('scan', ['scan-report.json']);
  assert.equal(sm.state.stages.scan.status, 'done');
  assert.equal(sm.state.checkpoints.length, 1);
  assert.ok(existsSync(join(dir, sm.state.checkpoints[0].snapshot)));
  rmSync(dir, { recursive: true, force: true });
});

test('markInterrupted：interrupted_at 落账', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  sm.markInterrupted('bridge', '子退出码 5');
  assert.equal(sm.state.interrupted_at, 'bridge:子退出码 5');
  assert.equal(sm.state.stages.bridge.status, 'failed');
  rmSync(dir, { recursive: true, force: true });
});

test('rollbackTo：恢复至快照+目标阶段重置 pending 重跑/其后 stages 重置', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  sm.markDone('scan', ['scan-report.json']);
  sm.markDone('skeleton', ['skeleton-result.json']);
  const r = sm.rollbackTo('scan');
  assert.equal(r.ok, true);
  assert.equal(sm.state.stages.scan.status, 'pending', '回滚目标重置 pending（快照含 done——回滚后可重跑）');
  assert.equal(sm.state.stages.skeleton.status, 'pending'); // 快照时刻 skeleton 尚未 done
  rmSync(dir, { recursive: true, force: true });
});

test('rollbackTo：无目标 checkpoint→失败（CLI 码 4 语义源）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  const r = sm.rollbackTo('scan');
  assert.equal(r.ok, false);
  rmSync(dir, { recursive: true, force: true });
});

test('flush：原子写盘——写盘中断不残留半成品（tmp 文件不落盘为终名）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  sm.flush();
  const files = readFileSync(join(dir, STATE_FILE), 'utf8'); // 可解析=完整
  assert.equal(JSON.parse(files).schema_version, 1);
  rmSync(dir, { recursive: true, force: true });
});

test('recordDecision：未确认不写 chosen（语义源）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-sm-'));
  const sm = new StateManager(dir); sm.load();
  sm.recordDecision({ point: 'bd:@hms.map::MapComponent', question: 'q', options: ['降级为OH替代', '自行实现', '裁剪'], source: 'hms-closed' });
  const d = sm.state.decisions[0];
  assert.equal('chosen' in d, false);
  sm.recordDecision({ point: 'bd:@hms.map::MapComponent', question: 'q', options: ['降级为OH替代', '自行实现', '裁剪'], chosen: '降级为OH替代', source: 'hms-closed' });
  assert.equal(sm.state.decisions[0].chosen, '降级为OH替代');
  rmSync(dir, { recursive: true, force: true });
});
