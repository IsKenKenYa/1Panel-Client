import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync, readdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { loadReport, check, rejectMessage } from './model-gate.js';
import { detectEnvironment } from './env-detector.js';

// ── ModelGate： 三分 +  零写 ──────────────────────────────

function writeReport(doc) {
  const dir = mkdtempSync(join(tmpdir(), 'f1-gate-'));
  const file = join(dir, 'scan-report.json');
  writeFileSync(file, JSON.stringify(doc), 'utf8');
  return { dir, file };
}

test('project_model=fa → reject_fa + 提示 + 目录零变更', () => {
  const { dir, file } = writeReport({ schema_version: 1, project_model: 'fa' });
  const before = readdirSync(dir).sort().join();
  const gate = check(loadReport(file));
  assert.equal(gate.verdict, 'reject_fa');
  assert.match(rejectMessage(gate), /FA 模型不支持，仅支持 Stage 模型/);
  assert.equal(readdirSync(dir).sort().join(), before, '拒绝路径零写');
  rmSync(dir, { recursive: true, force: true });
});

test('ScanReport 缺失 → reject_unknown + 引导 F2', () => {
  const gate = check(loadReport(join(tmpdir(), 'no-such-report.json')));
  assert.equal(gate.verdict, 'reject_unknown');
  assert.match(rejectMessage(gate), /请先运行 F2/);
});

test('不可解析 JSON → reject_unknown', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f1-gate-'));
  const file = join(dir, 'broken.json');
  writeFileSync(file, '{ not json', 'utf8');
  const gate = check(loadReport(file));
  assert.equal(gate.verdict, 'reject_unknown');
  rmSync(dir, { recursive: true, force: true });
});

test('project_model=unknown → reject_unknown', () => {
  const { dir, file } = writeReport({ schema_version: 1, project_model: 'unknown' });
  const gate = check(loadReport(file));
  assert.equal(gate.verdict, 'reject_unknown');
  rmSync(dir, { recursive: true, force: true });
});

test('缺 project_model 字段 / schema_version 不受支持 → reject_unknown', () => {
  const a = mkdtempSync(join(tmpdir(), 'f1-gate-'));
  const fa = join(a, 'a.json');
  writeFileSync(fa, JSON.stringify({ schema_version: 1 }), 'utf8');
  assert.equal(check(loadReport(fa)).verdict, 'reject_unknown');

  const b = mkdtempSync(join(tmpdir(), 'f1-gate-'));
  const fb = join(b, 'b.json');
  writeFileSync(fb, JSON.stringify({ schema_version: 2, project_model: 'stage' }), 'utf8');
  assert.equal(check(loadReport(fb)).verdict, 'reject_unknown');
  rmSync(a, { recursive: true, force: true });
  rmSync(b, { recursive: true, force: true });
});

test('stage → pass', () => {
  const { dir, file } = writeReport({ schema_version: 1, project_model: 'stage' });
  assert.equal(check(loadReport(file)).verdict, 'pass');
  rmSync(dir, { recursive: true, force: true });
});

// ── EnvDetector： 分项与容错 ─────────────────────────────────

function fakeRun(responses) {
  return (cmd, args) => {
    const key = `${cmd} ${args.join(' ')}`;
    return responses[key] || { status: 127, stdout: '' };
  };
}

test('全就绪（ace check 双平台 + 分项齐备）→ ready=true 且 missing 空', () => {
  const env = detectEnvironment({
    platform: 'darwin',
    aceCheckOutput: [
      '[√] ArkUI-X (26.0.0)',
      '[√] Android toolchains - develop for Android devices (Android SDK version 35.0.0)',
      '[√] Xcode - develop for iOS (Xcode 26.6)'
    ].join('\n'),
    run: fakeRun({
      'gradle --version': { status: 0, stdout: 'Gradle 8' },
      'java -version': { status: 0, stdout: 'openjdk 17' },
      'xcodebuild -version': { status: 0, stdout: 'Xcode 26.6' },
      'pod --version': { status: 0, stdout: '1.15' }
    })
  });
  assert.equal(env.android.ready, true);
  assert.deepEqual(env.android.missing, []);
  assert.equal(env.ios.ready, true);
  assert.deepEqual(env.ios.missing, []);
});

test('Android toolchains 缺失 + Gradle/JDK 缺 → missing 清单', () => {
  const env = detectEnvironment({
    platform: 'darwin',
    aceCheckOutput: '[X] Android toolchains\n[√] Xcode',
    run: fakeRun({
      'xcodebuild -version': { status: 0, stdout: 'Xcode 26.6' },
      'pod --version': { status: 0, stdout: '1.15' }
    })
  });
  assert.equal(env.android.ready, false);
  for (const name of ['Android SDK', 'Gradle', 'JDK']) {
    assert.ok(env.android.missing.includes(name), `missing 应含 ${name}: ${env.android.missing}`);
  }
  assert.equal(env.ios.ready, true);
});

test('非 macOS → ios.ready=false 且注明需 macOS（骨架仍双平台生成）', () => {
  const env = detectEnvironment({
    platform: 'linux',
    aceCheckOutput: '[√] Android toolchains',
    run: fakeRun({
      'gradle --version': { status: 0, stdout: 'Gradle 8' },
      'java -version': { status: 0, stdout: 'openjdk 17' }
    })
  });
  assert.equal(env.ios.ready, false);
  assert.ok(env.ios.missing.some((m) => m.includes('需 macOS')));
  assert.equal(env.android.ready, true);
});

test('容错：ace check 不可用 → 全独立探测兜底', () => {
  const env = detectEnvironment({
    platform: 'darwin',
    run: fakeRun({
      'gradle --version': { status: 0, stdout: 'Gradle 8' },
      'java -version': { status: 0, stdout: 'openjdk 17' },
      'xcodebuild -version': { status: 0, stdout: 'Xcode 26.6' },
      'pod --version': { status: 0, stdout: '1.15' }
    })
  });
  assert.equal(env.android.ready, true);
  assert.equal(env.ios.ready, true);
});
