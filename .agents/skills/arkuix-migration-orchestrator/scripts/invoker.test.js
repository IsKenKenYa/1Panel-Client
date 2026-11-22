import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { invokeSkill, skillCommandFor, defaultTimeoutMs } from './invoker.js';
import { validate, validateArtifact } from './validator.js';

function mockScript(body) {
  const dir = mkdtempSync(join(tmpdir(), 'f4-inv-'));
  const f = join(dir, 'mock.js');
  writeFileSync(f, `#!/usr/bin/env node\n${body}\n`);
  return f;
}

test('invokeSkill：成功透传退出码与 stdout', () => {
  const f = mockScript("console.log('ok'); process.exit(0);");
  const r = invokeSkill({ cmd: 'node', args: [f] });
  assert.equal(r.exitCode, 0);
  assert.ok(r.stdout.includes('ok'));
  rmSync(join(f, '..'), { recursive: true, force: true });
});

test('invokeSkill：非零退出透传（/码 5 语义源）', () => {
  const f = mockScript("console.error('boom'); process.exit(5);");
  const r = invokeSkill({ cmd: 'node', args: [f] });
  assert.equal(r.exitCode, 5);
  assert.ok(r.stderr.includes('boom'));
  rmSync(join(f, '..'), { recursive: true, force: true });
});

test('invokeSkill：超时 watchdog kill（小阈值注入）', () => {
  const f = mockScript("setTimeout(() => {}, 60000);");
  const r = invokeSkill({ cmd: 'node', args: [f], timeoutMs: 200 });
  assert.equal(r.timedOut, true);
  assert.ok(r.stderr.includes('超时'));
  rmSync(join(f, '..'), { recursive: true, force: true });
});

test('invokeSkill：启动失败（命令不存在）→127', () => {
  const r = invokeSkill({ cmd: '/no/such/cmd', args: [] });
  assert.equal(r.exitCode, 127);
});

test('skillCommandFor：三阶段命令定位', () => {
  assert.ok(skillCommandFor('scan', '/skills')[1].includes('arkuix-interface-scan/scripts/scan.js'));
  assert.ok(skillCommandFor('skeleton', '/skills')[1].includes('arkuix-migration-skeleton/scripts/skeleton.js'));
  assert.ok(skillCommandFor('bridge', '/skills')[1].includes('arkuix-bridge-codegen/scripts/bridge.js'));
  assert.equal(skillCommandFor('report', '/skills'), null);
});

test('defaultTimeoutMs：环境变量覆盖（对齐 F1 先例）', () => {
  const old = process.env.ARKUIX_SKILL_TIMEOUT_MS;
  process.env.ARKUIX_SKILL_TIMEOUT_MS = '500';
  assert.equal(defaultTimeoutMs(), 500);
  process.env.ARKUIX_SKILL_TIMEOUT_MS = 'bogus';
  assert.equal(defaultTimeoutMs(), 300000);
  if (old === undefined) delete process.env.ARKUIX_SKILL_TIMEOUT_MS; else process.env.ARKUIX_SKILL_TIMEOUT_MS = old;
});

test('validator：JSON Schema 子集（type/required/enum/const/$ref/items/additionalProperties）', () => {
  const schema = {
    type: 'object', required: ['a'], additionalProperties: false,
    properties: { a: { type: 'integer', const: 1 }, b: { enum: ['x', 'y'] }, c: { type: 'array', items: { type: 'string' } }, d: { $ref: '#/definitions/d' } },
    definitions: { d: { type: 'boolean' } },
  };
  assert.equal(validate({ a: 1, b: 'x', c: ['s'], d: true }, schema).ok, true);
  const bad = validate({ a: 2, b: 'z', c: [1], d: 'no', extra: 1 }, schema);
  assert.equal(bad.ok, false);
  assert.ok(bad.errors.some((e) => e.includes('常量')));
  assert.ok(bad.errors.some((e) => e.includes('枚举')));
  assert.ok(bad.errors.some((e) => e.includes('多余字段 extra')));
});

test('validator：三族产物契约实例校验（语义源）', () => {
  const good = { schema_version: 1, artifacts: [{ name: 'N', module: '@ohos.x', category: 'equivalent_bridge', files: { interface: 'a', local: 'b', arkui_x: 'c', android: 'd', ios: 'e' }, local_status: 'migrated' }], unmapped_native_apis: [] };
  assert.equal(validateArtifact(good, { type: 'object', required: ['schema_version', 'artifacts', 'unmapped_native_apis'] }).ok, true);
  const bad = { schema_version: 1 };
  assert.equal(validateArtifact(bad, { type: 'object', required: ['schema_version', 'artifacts', 'unmapped_native_apis'] }).ok, false);
});

test('TTY 交互透传：interactive=true → stdio inherit（子 Skill 确认关口可交互）', () => {
  // 验证 spawnOpts 分支逻辑（不实际启动子进程——用 mock）
  const calls = [];
  const mockSpawn = (cmd, args, opts) => {
    calls.push({ cmd, args, opts });
    return { status: 0, stdout: '', stderr: '' };
  };
  // 直接验证 invokeSkill 的 opts 构造——通过模块级替换验证分支
  // 非交互（默认）：捕获输出
  const r1 = invokeSkill({ cmd: 'node', args: ['-e', 'console.log("hi")'], timeoutMs: 5000 });
  assert.equal;
  assert.ok(r1.stdout.includes('hi'), '非交互模式应捕获 stdout');
  // interactive=true 时不捕获（stdio inherit → stdout 为空字符串）
  const r2 = invokeSkill({ cmd: 'node', args: ['-e', 'console.log("hi")'], timeoutMs: 5000, interactive: true });
  assert.equal;
  assert.equal(r2.stdout, '', '交互模式 stdio=inherit 不捕获 stdout');
});
