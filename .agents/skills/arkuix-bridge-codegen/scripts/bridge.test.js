import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');

function runCli(args, cwd) {
  return spawnSync(process.execPath, [join(root, 'scripts/bridge.js'), ...args], { encoding: 'utf8', cwd });
}

test('CliEntry：③④非空→五件套+BridgeArtifact+报告产出，退出码 0（场景 1）', () => {
  const cwd = mkdtempSync(join(tmpdir(), 'f3-cli-'));
  const out = join(cwd, 'out');
  const r = runCli([join(root, 'benchmark/fixture-source-project'), '--scan-report', join(root, 'benchmark/fixture-scan-report/report.json'), '--out', out], cwd);
  assert.equal(r.status, 0, r.stderr);
  const bars = JSON.parse(readFileSync(join(out, 'bridge-artifact.json'), 'utf8'));
  assert.ok(bars.artifacts.length >= 2);
  rmSync(cwd, { recursive: true, force: true });
});

test('CliEntry：③④均空→"无需桥接接口"+空 artifacts，退出码 0（场景 2/）', () => {
  const cwd = mkdtempSync(join(tmpdir(), 'f3-cli-'));
  const out = join(cwd, 'out-empty');
  const r = runCli([join(root, 'benchmark/fixture-source-project'), '--scan-report', join(root, 'benchmark/fixture-scan-report/report-empty.json'), '--out', out], cwd);
  assert.equal(r.status, 0);
  assert.ok(r.stdout.includes('无需桥接接口'));
  const bars = JSON.parse(readFileSync(join(out, 'bridge-artifact.json'), 'utf8'));
  assert.deepEqual(bars.artifacts, []);
  rmSync(cwd, { recursive: true, force: true });
});

test('CliEntry：ScanReport 格式异常→提示+空产物+退出码 3（场景 3/）', () => {
  const cwd = mkdtempSync(join(tmpdir(), 'f3-cli-'));
  const out = join(cwd, 'out-broken');
  const r = runCli([join(root, 'benchmark/fixture-source-project'), '--scan-report', join(root, 'benchmark/fixture-scan-report/report-broken.json'), '--out', out], cwd);
  assert.equal(r.status, 3);
  assert.ok(r.stderr.includes('ScanReport格式异常'));
  const bars = JSON.parse(readFileSync(join(out, 'bridge-artifact.json'), 'utf8'));
  assert.deepEqual(bars.artifacts, []);
  rmSync(cwd, { recursive: true, force: true });
});

test('CliEntry：源工程不存在→退出码 2+stderr（场景 4）', () => {
  const cwd = mkdtempSync(join(tmpdir(), 'f3-cli-'));
  const r = runCli([join(cwd, 'no-such-project'), '--scan-report', join(root, 'benchmark/fixture-scan-report/report.json')], cwd);
  assert.equal(r.status, 2);
  assert.ok(r.stderr.length > 0);
  rmSync(cwd, { recursive: true, force: true });
});
