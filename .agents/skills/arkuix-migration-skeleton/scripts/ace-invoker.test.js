import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdtempSync, mkdirSync, writeFileSync, rmSync, chmodSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { preflight, invokeModify, resolveTimeoutMs, PLATFORM_ANSWERS, DEFAULT_TIMEOUT_MS } from './ace-invoker.js';

function makeStageRoot() {
  const root = mkdtempSync(join(tmpdir(), 'f1-invoker-'));
  for (const f of ['build-profile.json5', 'oh-package.json5', 'hvigorfile.ts']) {
    writeFileSync(join(root, f), '{}\n', 'utf8');
  }
  return root;
}

/** 构造 mock ace 可执行脚本（模拟真实行为：读 stdin 平台选择 1/2/3 → 按选项产壳）。
 * 文件名带 .js 后缀：spawnAce 对 .js 走 node 可执行启动——
 * Windows 无法直接执行无扩展名 shebang 脚本，macOS/Linux 同样兼容 */
function makeMockAce(root, behavior) {
  const dir = join(root, 'mock-bin');
  mkdirSync(dir, { recursive: true });
  const file = join(dir, 'ace.js');
  const bodies = {
    success: `
const { mkdirSync, writeFileSync } = require('node:fs');
let input = '';
process.stdin.on('data', (d) => { input += d; });
process.stdin.on('end', () => {
  const answer = input.trim().charAt(0);
  const p = process.cwd();
  if (answer === '1' || answer === '2') {
    mkdirSync(require('node:path').join(p, '.arkui-x/android/app'), { recursive: true });
    writeFileSync(require('node:path').join(p, '.arkui-x/android/build.gradle'), '// gradle\\n');
  }
  if (answer === '1' || answer === '3') {
    mkdirSync(require('node:path').join(p, '.arkui-x/ios/app'), { recursive: true });
  }
  if (!['1','2','3'].includes(answer)) { console.error('no platform answer'); process.exit(3); }
  console.log('modify HarmonyOS project to ArkUI-X project success!');
  process.exit(0);
});
`,
    fail: `console.error('Error: Operation failed. Go to your project directory and try again.'); process.exit(1);`,
    timeout: `setTimeout(() => process.exit(0), 60000);`
  };
  writeFileSync(file, `#!/usr/bin/env node\n${bodies[behavior]}`, 'utf8');
  chmodSync(file, 0o755);
  return file;
}

test('平台应答映射：both→1 / android→2 / ios→3', () => {
  assert.deepEqual(PLATFORM_ANSWERS, { both: '1', android: '2', ios: '3' });
});

test('resolveTimeoutMs：显式参数 > ARKUIX_ACE_TIMEOUT_MS > 默认 300000；非法环境值回默认', () => {
  assert.equal(resolveTimeoutMs(1234, {}), 1234, '显式参数优先');
  assert.equal(resolveTimeoutMs(undefined, { ARKUIX_ACE_TIMEOUT_MS: '1500' }), 1500, '环境变量覆盖');
  assert.equal(resolveTimeoutMs(undefined, {}), DEFAULT_TIMEOUT_MS, '未设回默认');
  assert.equal(resolveTimeoutMs(undefined, { ARKUIX_ACE_TIMEOUT_MS: 'abc' }), DEFAULT_TIMEOUT_MS, '非法值回默认');
  assert.equal(resolveTimeoutMs(undefined, { ARKUIX_ACE_TIMEOUT_MS: '-5' }), DEFAULT_TIMEOUT_MS, '负值回默认');
  assert.equal(resolveTimeoutMs(undefined, { ARKUIX_ACE_TIMEOUT_MS: '' }), DEFAULT_TIMEOUT_MS, '空串回默认');
});

test('preflight：三件套齐 → ok', () => {
  const root = makeStageRoot();
  assert.equal(preflight(root).ok, true);
  rmSync(root, { recursive: true, force: true });
});

test('preflight：缺三件套 → missing 清单', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-invoker-'));
  const result = preflight(root);
  assert.equal(result.ok, false);
  assert.deepEqual(result.missing, ['build-profile.json5', 'oh-package.json5', 'hvigorfile.ts']);
  rmSync(root, { recursive: true, force: true });
});

test('modify 成功（both，应答 1）→ .arkui-x/{android,ios} 断言通过 + 改动清单', () => {
  const root = makeStageRoot();
  const ace = makeMockAce(root, 'success');
  const result = invokeModify(root, { aceBin: ace, platform: 'both' });
  assert.equal(result.ok, true, result.reason);
  assert.ok(result.artifacts.androidShell.endsWith('.arkui-x/android'));
  assert.ok(result.artifacts.iosShell.endsWith('.arkui-x/ios'));
  assert.match(result.stdout, /success!/);
  assert.ok(result.artifacts.changedFiles.some((f) => f.includes('build.gradle')), '成功路径输出实际改动清单');
  rmSync(root, { recursive: true, force: true });
});

test('modify platform=android（应答 2）→ 仅 android 壳断言', () => {
  const root = makeStageRoot();
  const ace = makeMockAce(root, 'success');
  const result = invokeModify(root, { aceBin: ace, platform: 'android' });
  assert.equal(result.ok, true, result.reason);
  assert.ok(existsSync(join(root, '.arkui-x', 'android')));
  assert.ok(!existsSync(join(root, '.arkui-x', 'ios')), '未选平台壳不要求在场');
  rmSync(root, { recursive: true, force: true });
});

test('modify platform=ios（应答 3）→ 仅 ios 壳断言', () => {
  const root = makeStageRoot();
  const ace = makeMockAce(root, 'success');
  const result = invokeModify(root, { aceBin: ace, platform: 'ios' });
  assert.equal(result.ok, true, result.reason);
  assert.ok(existsSync(join(root, '.arkui-x', 'ios')));
  assert.ok(!existsSync(join(root, '.arkui-x', 'android')));
  rmSync(root, { recursive: true, force: true });
});

test('modify 失败（非零退出）→ 失败原因（stderr 摘要），不产出成功结果', () => {
  const root = makeStageRoot();
  const ace = makeMockAce(root, 'fail');
  const result = invokeModify(root, { aceBin: ace });
  assert.equal(result.ok, false);
  assert.match(result.reason, /ace modify 失败（退出码 1）/);
  assert.match(result.reason, /Operation failed/);
  assert.equal(result.artifacts, undefined);
  rmSync(root, { recursive: true, force: true });
});

test('modify 超时 → 终止并报超时（阈值含实际值）', () => {
  const root = makeStageRoot();
  const ace = makeMockAce(root, 'timeout');
  const result = invokeModify(root, { aceBin: ace, timeoutMs: 500 });
  assert.equal(result.ok, false);
  assert.match(result.reason, /超时（>500ms）/);
  rmSync(root, { recursive: true, force: true });
});

test('ace 不可用 → 明确报因（--ace-bin 指引）', () => {
  const root = makeStageRoot();
  const result = invokeModify(root, { aceBin: join(root, 'no-such-ace') });
  assert.equal(result.ok, false);
  assert.match(result.reason, /ace 命令不可用/);
  rmSync(root, { recursive: true, force: true });
});

// ──：collectAceWarnings ───
import { collectAceWarnings } from './ace-invoker.js';

test('collectAceWarnings：stdout/stderr 含 WARN 行 → 提取（去重、去空）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-invoker-'));
  writeFileSync(join(root, 'build-profile.json5'), '{}\n');  // 无 useNormalizedOHMUrl → 静态复核不触发
  const out = collectAceWarnings(
    "INFO: keep going\nWARN: first must-do\nWARN: first must-do\n",
    "another line\nWARN: second must-do\n", root);
  assert.deepEqual(out, ['WARN: first must-do', 'WARN: second must-do']);
  rmSync(root, { recursive: true, force: true });
});

test('collectAceWarnings：TTY 透传（stdout 空）+ build-profile 含 useNormalizedOHMUrl → 静态复核补已知必办 WARN', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-invoker-'));
  writeFileSync(join(root, 'build-profile.json5'), '{ "buildOption": { "useNormalizedOHMUrl": true } }\n');
  const out = collectAceWarnings('', '（TTY 透传模式：输出已直达终端）', root);
  assert.equal(out.length, 1);
  assert.match(out[0], /useNormalizedOHMUrl/);
  rmSync(root, { recursive: true, force: true });
});

test('collectAceWarnings：无 WARN 且静态复核不命中 → 空数组；stdout 已含该 WARN 时不重复补', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-invoker-'));
  writeFileSync(join(root, 'build-profile.json5'), '{}\n');
  assert.deepEqual(collectAceWarnings('modify success!\n', '', root), []);
  writeFileSync(join(root, 'build-profile.json5'), '{ "useNormalizedOHMUrl": true }\n');
  const dedup = collectAceWarnings("WARN: arkui-x project must delete the 'useNormalizedOHMUrl' Setting Items in build-profile.json5\n", '', root);
  assert.equal(dedup.length, 1, 'stdout 已含同主题 WARN 不重复补');
  rmSync(root, { recursive: true, force: true });
});

// ──（Windows 实证）：spawnAce 统一启动封装 ───
import { spawnAce } from './ace-invoker.js';

test('spawnAce：.js 经 process.execPath 执行（跨平台 mock 可用）；win32 走 shell:true + 空格参数引号转义；非 win32 原样', () => {
  const calls = [];
  const fake = (cmd, a, b) => {
    // 兼容 spawnSync 两种形态：(cmd, args[], opts) 与 shell 模式 (cmdString, opts)
    const args = Array.isArray(a) ? a : undefined;
    const opts = Array.isArray(a) ? b : a;
    calls.push({ cmd, args, opts });
    return { status: 0, stdout: '' };
  };
  // .js → node 执行（平台无关）
  spawnAce('/x/mock-ace/ace.js', ['create', '/out dir'], { spawnSync: fake });
  assert.deepEqual(calls[0].args[0], '/x/mock-ace/ace.js');
  assert.equal(calls[0].cmd, process.execPath, 'mock .js 经 node 启动');
  // win32 + ace.cmd（真实在场文件、含空格名）→ shell:true,命令串含引号转义
  calls.length = 0;
  const sd30Root = mkdtempSync(join(tmpdir(), 'f1-sd30-'));
  const spacedCmd = join(sd30Root, 'my ace.cmd');
  writeFileSync(spacedCmd, '', 'utf8');
  spawnAce(spacedCmd, ['modify', '--project'], { platform: 'win32', spawnSync: fake });
  assert.equal(calls[0].opts.shell, true, 'win32 走 shell');
  assert.equal(calls[0].cmd, `"${spacedCmd}" modify --project`, '含空格路径加引号，其余参数原样拼接');
  // win32 + 路径形态不存在 → 合成 ENOENT（shell 模式下 cmd 仅给非零退出码无 error；归一为 posix spawn 同语义）
  calls.length = 0;
  const missing = spawnAce(join(sd30Root, 'no-such-ace.cmd'), ['check'], { platform: 'win32', spawnSync: fake });
  assert.equal(missing.error?.code, 'ENOENT', '合成 ENOENT（不可用语义跨平台一致）');
  assert.equal(calls.length, 0, '未进入 shell 启动');
  rmSync(sd30Root, { recursive: true, force: true });
  // win32 + 裸 ace（PATH 解析）→ 同样 shell
  calls.length = 0;
  spawnAce('ace', ['check'], { platform: 'win32', spawnSync: fake });
  assert.equal(calls[0].opts.shell, true);
  assert.equal(calls[0].cmd, 'ace check', '裸 ace 命令串拼接');
  // macOS/Linux → 原样数组形态、无 shell
  calls.length = 0;
  spawnAce('/usr/local/bin/ace', ['modify', '--project'], { platform: 'darwin', spawnSync: fake });
  assert.equal(calls[0].cmd, '/usr/local/bin/ace');
  assert.deepEqual(calls[0].args, ['modify', '--project']);
  assert.notEqual(calls[0].opts.shell, true, '非 win32 无 shell');
  // spawnOpts 透传（timeout/cwd/input）
  calls.length = 0;
  spawnAce('ace', ['modify', '--project'], { platform: 'darwin', spawnSync: fake, spawnOpts: { timeout: 5000, cwd: '/w' } });
  assert.equal(calls[0].opts.timeout, 5000);
  assert.equal(calls[0].opts.cwd, '/w');
});
