import { test } from 'node:test';
import assert from 'node:assert/strict';
import { confirmScanBuckets, resolveMigrateConfigs, resolveCompileSdk } from './skeleton.js';

function fakeReadline(answers) {
  const q = [];
  return {
    readline: {
      question: async (prompt) => { q.push(prompt); return answers.shift() ?? ''; },
      close: () => {}
    },
    prompts: q
  };
}

function docOf(buckets) {
  return { project_model: 'stage', adaptation: buckets };
}

test('--yes 跳过逐桶确认（仍打印全桶摘要）；非 TTY 无 --yes → 退出码 6', async () => {
  const doc = docOf({ full_direct: [{ module: '@ohos.router', symbol: 'router', reason: 'r' }], unknown: [] });
  let logs = [];
  const origLog = console.log; console.log = (...a) => logs.push(a.join(' '));
  try {
    const r = await confirmScanBuckets(doc, '/x/f2-out/scan-report.json', { yes: true });
    assert.equal(r, 'ok');
    assert.ok(logs.some((l) => l.includes('完整直用（full_direct） 1')), '摘要含桶计数');
    assert.ok(logs.some((l) => l.includes('--yes：跳过逐桶确认')));
    assert.ok(logs.some((l) => l.includes('migration-advice.md')), '提示报告路径');
    //  交互序修正：非 TTY 未确认 → 零产出 exit 6（与  SDK 确认同款强制）
    const origErr2 = console.error; console.error = (...a) => logs.push(a.join(' '));
    const origExit2 = process.exit;
    let exitCode2 = null;
    process.exit = (c) => { exitCode2 = c; throw new Error('__exit2__'); };
    try {
      await confirmScanBuckets(doc, '/x/scan-report.json', {}, { isTTY: false });
      assert.fail('应 exit 6');
    } catch (e) { assert.match(String(e), /__exit2__/); }
    process.exit = origExit2; console.error = origErr2;
    assert.equal(exitCode2, 6, '非 TTY 未确认退出码 6');
    assert.ok(logs.some((l) => l.includes('呈报块')), '输出预格式化呈报块');
    assert.ok(logs.some((l) => l.includes('【⑦ unknown（待人工确认）】共 0 条')), '呈报块含 unknown 桶行');
    assert.ok(logs.some((l) => l.includes('呈报块结束')), '呈报块闭合');
  } finally {
    console.log = origLog;
  }
});

test('风险序逐桶（unknown 先于 full_direct）；y 逐桶确认；a 剩余全确认；空桶跳过', async () => {
  const doc = docOf({
    unknown: [{ module: '@kit.X', symbol: 'x', reason: '未知' }],
    full_direct: [{ module: '@ohos.a', symbol: 'a1', reason: 'r' }, { module: '@ohos.b', symbol: 'b1', reason: 'r2' }]
  });
  const { readline, prompts } = fakeReadline(['y', 'a']);
  let logs = [];
  const origLog = console.log; console.log = (...a) => logs.push(a.join(' '));
  try {
    const r = await confirmScanBuckets(doc, '/x/scan-report.json', {}, { isTTY: true, readline });
    assert.equal(r, 'ok');
    const order = logs.findIndex((l) => l.includes('unknown（待人工确认）'));
    const orderFd = logs.findIndex((l) => l.includes('（2）① 完整直用'));
    assert.ok(order >= 0 && orderFd > order, 'unknown 先确认、full_direct 其后（风险序）');
    assert.equal(prompts.length, 2, '两个非空桶各问一次（空桶不问）');
    assert.ok(logs.some((l) => l.includes('剩余桶全部确认')), 'a 键生效');
  } finally { console.log = origLog; }
});

test('n 中止 → 退出码 6 + 复核指引；无效输入重问', async () => {
  const doc = docOf({ unknown: [{ module: '@kit.X', symbol: 'x', reason: '未知' }] });
  const { readline } = fakeReadline(['bad', 'n']);
  const origLog = console.log, origErr = console.error;
  const logs = [];
  console.log = (...a) => logs.push(a.join(' '));
  console.error = (...a) => logs.push(a.join(' '));
  let exitCode = null;
  const origExit = process.exit;
  process.exit = (c) => { exitCode = c; throw new Error('__exit__'); };
  try {
    await confirmScanBuckets(doc, '/x/scan-report.json', {}, { isTTY: true, readline });
    assert.fail('应中止');
  } catch (e) {
    assert.match(String(e), /__exit__/);
  } finally {
    process.exit = origExit; console.log = origLog; console.error = origErr;
  }
  assert.equal(exitCode, 6);
  assert.ok(logs.some((l) => l.includes('输入无效')), '无效输入重问提示');
  assert.ok(logs.some((l) => l.includes('复核') && l.includes('migration-advice.md')), '中止给复核指引');
});

// ── new 模式配置迁移强确认门 ─────────────────────────────────
test('resolveMigrateConfigs：显式参数直通（yes/no）；非 TTY 缺参 → 退出码 6 + 指引', async () => {
  assert.equal(await resolveMigrateConfigs({ migrateConfigs: 'yes' }), 'yes');
  assert.equal(await resolveMigrateConfigs({ migrateConfigs: 'no' }), 'no');
  const logs = [];
  const origErr = console.error;
  console.error = (...a) => logs.push(a.join(' '));
  let exitCode = null;
  const origExit = process.exit;
  process.exit = (c) => { exitCode = c; throw new Error('__exit__'); };
  try {
    await resolveMigrateConfigs({}, { isTTY: false });
    assert.fail('应 exit 6');
  } catch (e) {
    assert.match(String(e), /__exit__/);
  } finally {
    process.exit = origExit; console.error = origErr;
  }
  assert.equal(exitCode, 6, '非 TTY 缺参=用户中止（强确认门，不代答）');
  assert.ok(logs.some((l) => l.includes('--migrate-configs <yes|no>')), '指引含参数形态');
  assert.ok(logs.some((l) => l.includes('migrate_configs=yes|no')), '指引含编排器 --answer 通道');
  assert.ok(logs.some((l) => l.includes('遗漏/多改')), '指引说明双向校验');
});

test('resolveMigrateConfigs：TTY 询问——空回车默认 no、y=yes、q=中止码 6', async () => {
  const mkRl = (answers) => ({
    readline: { question: async () => answers.shift() ?? '', close: () => {} }
  });
  assert.equal(await resolveMigrateConfigs({}, { isTTY: true, ...mkRl(['']) }), 'no', '空回车=默认不合并');
  assert.equal(await resolveMigrateConfigs({}, { isTTY: true, ...mkRl(['y']) }), 'yes');
  assert.equal(await resolveMigrateConfigs({}, { isTTY: true, ...mkRl(['n']) }), 'no');
  let exitCode = null;
  const origExit = process.exit;
  const origErr = console.error;
  console.error = () => {};
  process.exit = (c) => { exitCode = c; throw new Error('__exit__'); };
  try {
    await resolveMigrateConfigs({}, { isTTY: true, ...mkRl(['q']) });
    assert.fail('应中止');
  } catch (e) {
    assert.match(String(e), /__exit__/);
  } finally {
    process.exit = origExit; console.error = origErr;
  }
  assert.equal(exitCode, 6);
});

// ── Compile SDK 版本强确认门（new 模式必答；推荐序：最高优先，其次源工程版本） ──
test('resolveCompileSdk：显式参数直通（版本键/全形态）；非 TTY 缺参 → 退出码 6 + 指引（含源工程版本推荐）', async () => {
  assert.equal((await resolveCompileSdk({ compileSdk: '24' }, '/nonexistent')).key, '24');
  assert.equal((await resolveCompileSdk({ compileSdk: '6.1.0(23)' }, '/nonexistent')).key, '23', '全形态反查');
  // 源工程版本探测进指引：构造 compatibleSdkVersion 6.1.0(23) 的源根
  const { mkdtempSync, writeFileSync, rmSync } = await import('node:fs');
  const { join } = await import('node:path');
  const { tmpdir } = await import('node:os');
  const src = mkdtempSync(join(tmpdir(), 'f1-csdk-src-'));
  writeFileSync(join(src, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default", "compatibleSdkVersion": "6.1.0(23)" }] } }');
  const logs = [];
  const origErr = console.error;
  console.error = (...a) => logs.push(a.join(' '));
  let exitCode = null;
  const origExit = process.exit;
  process.exit = (c) => { exitCode = c; throw new Error('__exit__'); };
  try {
    await resolveCompileSdk({}, src, { isTTY: false });
    assert.fail('应 exit 6');
  } catch (e) {
    assert.match(String(e), /__exit__/);
  } finally {
    process.exit = origExit; console.error = origErr;
  }
  assert.equal(exitCode, 6, '非 TTY 缺参=用户中止（强门不代答）');
  assert.ok(logs.some((l) => l.includes('--compile-sdk <版本>')), '指引含参数形态');
  assert.ok(logs.some((l) => l.includes('源工程版本 23')), '指引含源工程版本推荐（实测 6.1.0(23)）');
  assert.ok(logs.some((l) => l.includes('26.0.0')), '指引含最高版本推荐');
  assert.ok(logs.some((l) => l.includes('compile_sdk=')), '指引含编排器 --answer 通道');
  rmSync(src, { recursive: true, force: true });
});

test('resolveCompileSdk：TTY 询问——回车=最高 26.0.0、编号/版本键选择、q=中止码 6、3 次无效=中止', async () => {
  const mkRl = (answers) => ({
    readline: { question: async () => answers.shift() ?? '', close: () => {} }
  });
  assert.equal((await resolveCompileSdk({}, '/nonexistent', { isTTY: true, ...mkRl(['']) })).key, '26.0.0', '回车=最高');
  assert.equal((await resolveCompileSdk({}, '/nonexistent', { isTTY: true, ...mkRl(['15']) })).key, '24', '编号 15=24');
  assert.equal((await resolveCompileSdk({}, '/nonexistent', { isTTY: true, ...mkRl(['22']) })).key, '22', '版本键直选');
  let exitCode = null;
  const origExit = process.exit;
  const origErr = console.error;
  console.error = () => {};
  process.exit = (c) => { exitCode = c; throw new Error('__exit__'); };
  try {
    await resolveCompileSdk({}, '/nonexistent', { isTTY: true, ...mkRl(['q']) });
    assert.fail('应中止');
  } catch (e) { assert.match(String(e), /__exit__/); }
  assert.equal(exitCode, 6, 'q 中止');
  try {
    await resolveCompileSdk({}, '/nonexistent', { isTTY: true, ...mkRl(['bogus', 'alsobad', 'nope']) });
    assert.fail('应中止');
  } catch (e) { assert.match(String(e), /__exit__/); }
  assert.equal(exitCode, 6, '连续 3 次无效输入中止');
  process.exit = origExit; console.error = origErr;
});
