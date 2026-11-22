import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { basename, join } from 'node:path';
import { detectSdkCandidates, validateSdkDir, sdkVersionOf, hasKitsDir } from './sdk-locator.js';

function makeSdk(files) {
  const root = mkdtempSync(join(tmpdir(), 'f2-sdk-'));
  const apiDir = join(root, 'ets', 'api');
  mkdirSync(apiDir, { recursive: true });
  for (const [name, content] of Object.entries(files)) {
    writeFileSync(join(apiDir, name), content, 'utf8');
  }
  return root;
}

const VALID_DTS = [
  '/**',
  ' * @syscap SystemCapability.Test',
  ' * @crossplatform',
  ' */',
  'declare namespace demo {',
  '  function foo(): void;',
  '}',
  'export default demo;'
].join('\n');

/** 家目录与 SDK 环境变量隔离（跨平台）：HOME 与 USERPROFILE 同指假家目录——
 *  win32 的 os.homedir() 读 USERPROFILE 不读 HOME，只隔离 HOME 会让本机真实 SDK 泄漏进候选；
 *  同时屏蔽 OH_SDK_DIR/OHOS_SDK_HOME/DEVECO_SDK_HOME 三件套。返回恢复函数。 */
function isolateHomeSdkEnv(fakeHome) {
  const keys = ['HOME', 'USERPROFILE', 'OH_SDK_DIR', 'OHOS_SDK_HOME', 'DEVECO_SDK_HOME'];
  const saved = Object.fromEntries(keys.map((k) => [k, process.env[k]]));
  process.env.HOME = fakeHome;
  process.env.USERPROFILE = fakeHome;
  for (const k of ['OH_SDK_DIR', 'OHOS_SDK_HOME', 'DEVECO_SDK_HOME']) delete process.env[k];
  return () => {
    for (const k of keys) {
      if (saved[k] === undefined) delete process.env[k]; else process.env[k] = saved[k];
    }
  };
}

test('validateSdkDir：含 ets/api 的 @ohos.*.d.ts → ok 且返回 apiDir', () => {
  const root = makeSdk({ '@ohos.demo.d.ts': VALID_DTS });
  const result = validateSdkDir(root);
  assert.ok(result.ok);
  assert.ok(result.apiDir.endsWith('api'));
  rmSync(root, { recursive: true, force: true });
});

test('validateSdkDir：缺 ets/api 或无 @ohos.*.d.ts → 不 ok（改指无效目录再次请求依据）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f2-sdk-'));
  assert.equal(validateSdkDir(root).ok, false);
  assert.match(validateSdkDir(root).reason, /未找到 ets\/api/);
  assert.equal(validateSdkDir('/nonexistent/path').ok, false);
  rmSync(root, { recursive: true, force: true });
});

test('detectSdkCandidates：显式路径优先且仅返回该候选', () => {
  const candidates = detectSdkCandidates('/explicit/sdk');
  assert.equal(candidates.length, 1);
  assert.equal(candidates[0].origin, 'explicit');
});

test('detectSdkCandidates：环境变量候选（版本级直取；根级展开；无效值不再产生幽灵候选）', () => {
  // 版本级 env：直接成为候选
  const verRoot = mkdtempSync(join(tmpdir(), 'f2-env-'));
  const apiDir = join(verRoot, 'ets', 'api');
  mkdirSync(apiDir, { recursive: true });
  writeFileSync(join(apiDir, '@ohos.mock.d.ts'), 'declare namespace mock {}\n');
  process.env.OH_SDK_DIR = verRoot;
  try {
    const candidates = detectSdkCandidates(null);
    assert.ok(candidates.some((c) => c.origin === 'env:OH_SDK_DIR' && c.path === verRoot), '版本级 env 候选在场');
    // 根级 env：展开为版本候选
    const root = mkdtempSync(join(tmpdir(), 'f2-envroot-'));
    const sdk = join(root, '26.0.0');
    const api2 = join(sdk, 'ets', 'api');
    mkdirSync(api2, { recursive: true });
    writeFileSync(join(api2, '@ohos.mock.d.ts'), 'declare namespace mock {}\n');
    process.env.OH_SDK_DIR = root;
    const expanded = detectSdkCandidates(null).filter((c) => c.origin === 'env:OH_SDK_DIR');
    assert.deepEqual(expanded.map((c) => c.path), [sdk], '根级 env 展开为版本候选');
    // 无效 env：不产生候选（不产生指向不存在路径的幽灵候选）
    process.env.OH_SDK_DIR = '/nonexistent/env/sdk';
    assert.equal(detectSdkCandidates(null).filter((c) => c.origin === 'env:OH_SDK_DIR').length, 0, '无效 env 无候选');
  } finally {
    delete process.env.OH_SDK_DIR;
    rmSync(verRoot, { recursive: true, force: true });
  }
});

test('推荐序：kits 优先 + 语义化版本降序（最新在前；env 候选不再天然第一）', () => {
  const fakeHome = mkdtempSync(join(tmpdir(), 'f6-locator-'));
  const sdkRoot = join(fakeHome, 'Library', 'OpenHarmony', 'Sdk');
  // v9 无 kits；v10 无 kits；v20/v23/v26 有 kits
  for (const v of ['9', '10', '20', '23', '26.0.0']) {
    const apiDir = join(sdkRoot, v, 'ets', 'api');
    mkdirSync(apiDir, { recursive: true });
    writeFileSync(join(apiDir, '@ohos.mock.d.ts'), 'declare namespace mock {}\n');
    if (['20', '23', '26.0.0'].includes(v)) {
      const kitsDir = join(sdkRoot, v, 'ets', 'kits');
      mkdirSync(kitsDir, { recursive: true });
      writeFileSync(join(kitsDir, '@kit.MockKit.d.ts'), "import { mock } from '../api/@ohos.mock';\n");
    }
  }
  // env 指向无 kits 的旧版（DevEco 旧管理模式形态）——不应抢推荐位
  const envSdk = join(fakeHome, 'envsdk');
  const envApi = join(envSdk, 'ets', 'api');
  mkdirSync(envApi, { recursive: true });
  writeFileSync(join(envApi, '@ohos.mock.d.ts'), 'declare namespace mock {}\n');
  const restoreEnv = isolateHomeSdkEnv(fakeHome);
  process.env.OH_SDK_DIR = envSdk; // 本用例显式注入 env 候选（无 kits 旧版）——应在隔离基础上叠加
  try {
    const candidates = detectSdkCandidates(null);
    assert.equal(candidates[0].path, join(sdkRoot, '26.0.0'), '推荐位=最新 kits 版（26.0.0）而非 env 旧版/低 kits 版');
    assert.ok(candidates.findIndex((c) => c.path === envSdk) > 3, 'env 旧版（无 kits）排后');
    const last = candidates[candidates.length - 1];
    assert.ok(!hasKitsDir(last.path), '垫底项为无 kits 候选');
  } finally {
    restoreEnv();
    rmSync(fakeHome, { recursive: true, force: true });
  }
});

test('sdkVersionOf：取目录名', () => {
  assert.equal(sdkVersionOf('/a/b/26.0.0'), '26.0.0');
});

// ── 候选推荐序 ───────────────────────────────────────────────────────────

test('候选排序 kits 能力优先（无 kits 的旧版本不再排前）', () => {
  const fakeHome = mkdtempSync(join(tmpdir(), 'f2-locator-'));
  const sdkRoot = join(fakeHome, 'Library', 'OpenHarmony', 'Sdk');
  // 三个版本：v10 无 kits、v20/v26 有 kits（各含最小 ets/api/@ohos.*.d.ts）
  for (const v of ['10', '20', '26.0.0']) {
    const apiDir = join(sdkRoot, v, 'ets', 'api');
    mkdirSync(apiDir, { recursive: true });
    writeFileSync(join(apiDir, '@ohos.mock.d.ts'), 'declare namespace mock {}\n');
    if (v !== '10') {
      const kitsDir = join(sdkRoot, v, 'ets', 'kits');
      mkdirSync(kitsDir, { recursive: true });
      writeFileSync(join(kitsDir, '@kit.MockKit.d.ts'), "import { mock } from '../api/@ohos.mock';\n");
    }
  }
  const restoreEnv = isolateHomeSdkEnv(fakeHome);
  try {
    const candidates = detectSdkCandidates(null).filter((c) => c.origin.startsWith('default:'));
    const first = basename(candidates[0].path);
    assert.ok(['20', '26.0.0'].includes(first), `kits 版本应排前（实际 ${first}）`);
    const last = basename(candidates[candidates.length - 1].path);
    assert.equal(last, '10', '无 kits 的 v10 排最后');
    assert.ok(hasKitsDir(candidates[0].path));
    assert.equal(hasKitsDir(join(sdkRoot, '10')), false);
  } finally {
    restoreEnv();
    rmSync(fakeHome, { recursive: true, force: true });
  }
});
