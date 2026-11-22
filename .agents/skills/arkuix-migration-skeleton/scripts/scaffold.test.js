import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, chmodSync, existsSync, readdirSync, readFileSync, copyFileSync, cpSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { checkOutputDir, decideOnNonEmpty, createScaffold, readPlatformBaseline } from './scaffold.js';
import { resolveVersionEntry } from './sdk-versions.js';
import { looseJson5 } from './migrate.js';
import { assembleModules } from './skeleton.js';
const SKILL_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');
import { migrateSources, verifyMigration } from './migrate.js';

/** mock ace create（6 题交互仿真 + .arkui-x 真实布局）。
 * 文件名带 .js 后缀：spawnAce 对 .js 走 node 可执行启动——
 * Windows 无法直接执行无扩展名 shebang 脚本，macOS/Linux 同样兼容 */
function makeMockCreateAce(root) {
  const dir = join(root, 'mock-bin');
  mkdirSync(dir, { recursive: true });
  const file = join(dir, 'ace.js');
  writeFileSync(file, `#!/usr/bin/env node
const { mkdirSync, writeFileSync } = require('node:fs');
const { join } = require('node:path');
let input = '';
process.stdin.on('data', (d) => { input += d; });
process.stdin.on('end', () => {
  if (input.split('\\n').length < 6) {
    console.log('? Please select the Complie SDk (1: 10; 2: 11; 3: 12; 14: 23; 16: 26.0.0): ');
    process.exit(1);
  }
  const out = process.argv[3];
  mkdirSync(join(out, '.arkui-x/android/app'), { recursive: true });
  writeFileSync(join(out, '.arkui-x/android/build.gradle'), '// gradle\\n');
  mkdirSync(join(out, '.arkui-x/ios/app'), { recursive: true });
  mkdirSync(join(out, 'entry/src/main'), { recursive: true });
  console.log('create success');
});
`, 'utf8');
  chmodSync(file, 0o755);
  return file;
}

function makeSourceProject() {
  const root = mkdtempSync(join(tmpdir(), 'f1-migrate-'));
  const files = {
    'entry/src/main/module.json5': '{"module":{"name":"entry"}}\n',
    'entry/src/main/ets/Index.ets': '@Entry\n@Component\nstruct Index {}\n',
    'entry/src/main/ets/pages/Detail.ets': '@Component\nstruct Detail {}\n',
    'entry/src/main/resources/base/media/icon.png': 'binary-ish\n',
    'entry/src/main/oh_modules/dep/index.ets': 'should-not-migrate\n',
    'AppScope/app.json5': '{}\n'
  };
  for (const [rel, content] of Object.entries(files)) {
    const file = join(root, rel);
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, content, 'utf8');
  }
  return root;
}

test('checkOutputDir：不存在/空/非空 三态', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const absent = join(root, 'a');
  const empty = join(root, 'b');
  mkdirSync(empty);
  const nonEmpty = join(root, 'c');
  mkdirSync(nonEmpty);
  writeFileSync(join(nonEmpty, 'x.txt'), 'x');
  assert.deepEqual(checkOutputDir(absent), { exists: false, nonEmpty: false });
  assert.deepEqual(checkOutputDir(empty), { exists: true, nonEmpty: false });
  assert.deepEqual(checkOutputDir(nonEmpty), { exists: true, nonEmpty: true });
  rmSync(root, { recursive: true, force: true });
});

test('decideOnNonEmpty：跳过/覆盖/中止；无效应答返回 null（重新询问）', () => {
  assert.equal(decideOnNonEmpty('s'), 'skip');
  assert.equal(decideOnNonEmpty('y'), 'overwrite');
  assert.equal(decideOnNonEmpty('q'), 'abort');
  assert.equal(decideOnNonEmpty('x'), null, '无效应答应返回 null 由调用方重新询问');
  assert.equal(decideOnNonEmpty('maybe'), null);
});

test('mock ace create（6 题仿真+菜单发现）→ .arkui-x/{android,ios} + entry 断言', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const ace = makeMockCreateAce(root);
  const outDir = join(root, 'out-project');
  const result = createScaffold(outDir, { aceBin: ace });
  assert.equal(result.ok, true, result.reason);
  assert.ok(existsSync(join(outDir, '.arkui-x', 'android')), '壳在 .arkui-x/ 下');
  assert.ok(existsSync(join(outDir, '.arkui-x', 'ios')));
  assert.equal(result.sharedArktsDir, join(outDir, 'entry'));
  assert.equal(result.legacy, false);
  rmSync(root, { recursive: true, force: true });
});

test('scaffold 已在场 → 跳过 create（假 aceBin 不可用仍成功）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const outDir = join(root, 'pre-made');
  mkdirSync(join(outDir, '.arkui-x', 'android'), { recursive: true });
  mkdirSync(join(outDir, '.arkui-x', 'ios'), { recursive: true });
  mkdirSync(join(outDir, 'entry', 'src', 'main'), { recursive: true });
  const result = createScaffold(outDir, { aceBin: '/no/such/ace' });
  assert.equal(result.ok, true, result.reason);
  assert.equal(result.skippedCreate, true, '在场即跳过 ace create');
  rmSync(root, { recursive: true, force: true });
});

test('createScaffold：按所选平台裁剪未选平台壳（.arkui-x 布局）', () => {
  const rootA = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const aceA = makeMockCreateAce(rootA);
  const outA = join(rootA, 'out-android');
  createScaffold(outA, { aceBin: aceA, platform: 'android' });
  assert.ok(existsSync(join(outA, '.arkui-x', 'android')), 'android 壳在场');
  assert.ok(!existsSync(join(outA, '.arkui-x', 'ios')), 'ios 壳应被裁剪');

  const rootI = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const aceI = makeMockCreateAce(rootI);
  const outI = join(rootI, 'out-ios');
  createScaffold(outI, { aceBin: aceI, platform: 'ios' });
  assert.ok(existsSync(join(outI, '.arkui-x', 'ios')), 'ios 壳在场');
  assert.ok(!existsSync(join(outI, '.arkui-x', 'android')), 'android 壳应被裁剪');

  rmSync(rootA, { recursive: true, force: true });
  rmSync(rootI, { recursive: true, force: true });
});

test('createScaffold：ace create 失败 → 失败原因', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-scaffold-'));
  const result = createScaffold(join(root, 'o'), { aceBin: '/no/such/ace' });
  assert.equal(result.ok, false);
  assert.match(result.reason, /ace 命令不可用/);
  rmSync(root, { recursive: true, force: true });
});

test('migrateSources（新 API）：entry 模块迁至 <out>/entry/src/main + 哈希一致 + oh_modules 排除', () => {
  const srcRoot = makeSourceProject();
  const outDir = mkdtempSync(join(tmpdir(), 'f1-out-'));
  const migration = migrateSources(srcRoot, outDir);

  assert.equal(migration.ok, true, migration.reason);
  assert.equal(migration.filesMoved, 4, 'module.json5 + 2 ets + 1 resource');
  assert.deepEqual(migration.modules, [{ name: 'entry', files: 4, target: 'entry' }]);
  for (const rel of ['module.json5', 'ets/Index.ets', 'ets/pages/Detail.ets', 'resources/base/media/icon.png']) {
    assert.ok(existsSync(join(outDir, 'entry', 'src', 'main', rel)), `缺失 ${rel}`);
  }
  assert.ok(!existsSync(join(outDir, 'entry', 'src', 'main', 'oh_modules')), 'oh_modules 不得迁入');

  const verification = verifyMigration(srcRoot, outDir, migration);
  assert.equal(verification.ok, true, verification.reason);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('多模块（业务名 entry + feature）按 build-profile modules 逐模块迁入', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-multi-'));
  const files = {
    'build-profile.json5': '{ "modules": [{ "name": "entry", "srcPath": "./entry" }, { "name": "feature", "srcPath": "./feature" }] }\n',
    'entry/src/main/module.json5': '{}\n',
    'entry/src/main/ets/Index.ets': 'struct I {}\n',
    'feature/src/main/module.json5': '{}\n',
    'feature/src/main/ets/Feature.ets': 'struct F {}\n'
  };
  for (const [rel, content] of Object.entries(files)) {
    const file = join(srcRoot, rel);
    mkdirSync(join(file, '..'), { recursive: true });
    writeFileSync(file, content, 'utf8');
  }
  const outDir = mkdtempSync(join(tmpdir(), 'f1-multi-out-'));
  const migration = migrateSources(srcRoot, outDir);
  assert.equal(migration.ok, true, migration.reason);
  assert.equal(migration.filesMoved, 4);
  assert.ok(existsSync(join(outDir, 'entry', 'src', 'main', 'ets', 'Index.ets')));
  assert.ok(existsSync(join(outDir, 'feature', 'src', 'main', 'ets', 'Feature.ets')), 'feature 模块迁入');
  assert.equal(verifyMigration(srcRoot, outDir, migration).ok, true);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('verifyMigration：内容被改写 → 校验失败', () => {
  const srcRoot = makeSourceProject();
  const outDir = mkdtempSync(join(tmpdir(), 'f1-out-'));
  const migration = migrateSources(srcRoot, outDir);
  writeFileSync(join(outDir, 'entry', 'src', 'main', 'ets', 'Index.ets'), 'tampered\n', 'utf8');
  const verification = verifyMigration(srcRoot, outDir, migration);
  assert.equal(verification.ok, false);
  assert.match(verification.reason, /内容被改写/);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('零迁入 → ok=false 显式失败（不静默伪成功）', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-migrate-'));
  const outDir = mkdtempSync(join(tmpdir(), 'f1-out-'));
  const migration = migrateSources(srcRoot, outDir);
  assert.equal(migration.filesMoved, 0);
  assert.equal(migration.ok, false, '零迁入必须显式失败');
  assert.match(migration.reason, /无可迁入源码/);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

// ──根治：归档 scaffold 物化 ───
import { materializeFromArchive, ARCHIVE_DEFAULTS } from './scaffold.js';
import { readFileSync as rf, existsSync as ex, rmSync as rm2, readdirSync as rd } from 'node:fs';

test('materialize：变量替换（项目名/bundleName/iOS 显示名）+ java 包目录重组 + 双平台保留', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-arch-'));
  const archive = join(SKILL_ROOT, 'assets', 'scaffold-26.0.0');
  const out = join(root, 'out');
  const r = materializeFromArchive(archive, out, { name: 'myapp', bundle: 'com.demo.myapp', platform: 'both', ohpmPath: '/opt/ohpm', arkuiXSdkPath: '/opt/arkui-x' });
  assert.equal(r.ok, true, r.reason);
  assert.equal(rf(join(out, 'AppScope/app.json5'), 'utf8').includes('"bundleName": "com.demo.myapp"'), true);
  assert.equal(rf(join(out, 'oh-package.json5'), 'utf8').includes('"name": "myapp"'), true);
  assert.equal(ex(join(out, '.arkui-x/android/app/src/main/java/com/demo/myapp/EntryEntryAbilityActivity.java')), true, 'java 包目录按新 bundle 重组');
  assert.equal(ex(join(out, '.arkui-x/android/app/src/main/java/com/example/arkuixapp')), false, '旧包目录清除');
  assert.match(rf(join(out, '.arkui-x/android/buildArkTS'), 'utf8'), /project_path=".*out"/, '环境路径注入');
  assert.equal(rf(join(out, '.arkui-x/android/buildArkTS'), 'utf8').includes('__OHPM_PATH__'), false);
  assert.equal(ex(join(out, '.arkui-x/android')), true, '双平台保留 android');
  assert.equal(ex(join(out, '.arkui-x/ios')), true, '双平台保留 ios');
  assert.match(rf(join(out, 'build-profile.json5'), 'utf8'), /"compileSdkVersion": "26\.0\.0"/, 'SDK 固定 26.0.0');
  assert.deepEqual(JSON.parse(rf(join(out, '.projectInfo'), 'utf8')).platforms, ['android', 'ios']);
  rm2(root, { recursive: true, force: true });
});

test('materialize：platform=ios 裁剪 android 壳 + .projectInfo 重写；非法归档拒绝', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-arch-'));
  const archive = join(SKILL_ROOT, 'assets', 'scaffold-26.0.0');
  const out = join(root, 'out');
  const r = materializeFromArchive(archive, out, { platform: 'ios' });
  assert.equal(r.ok, true, r.reason);
  assert.equal(ex(join(out, '.arkui-x/android')), false, 'ios-only 裁剪 android');
  assert.equal(ex(join(out, '.arkui-x/ios')), true);
  assert.deepEqual(JSON.parse(rf(join(out, '.projectInfo'), 'utf8')).platforms, ['ios']);
  assert.match(rf(join(out, '.arkui-x/ios/buildArkTS.sh'), 'utf8'), /__OHPM_PATH__/, '未提供 ohpm 路径→保留占位');
  assert.ok((r.envNote || []).some((n) => n.includes('ohpm')), 'envNote 提示占位符');
  // 非法归档目录
  const bad = materializeFromArchive(join(root, 'no-such'), join(root, 'o2'), {});
  assert.equal(bad.ok, false);
  // 非法项目名
  const badName = materializeFromArchive(archive, join(root, 'o3'), { name: '9bad name' });
  assert.equal(badName.ok, false);
  rm2(root, { recursive: true, force: true });
});

test('N1G2-r2：嵌套模块级文件补迁 + 裸/file: 依赖改写 + 三处装配进编译集', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-n1-'));
  const files = {
    'build-profile.json5': '{ "modules": [{ "name": "entry", "srcPath": "./entry" }, { "name": "base", "srcPath": "./commons/base" }, { "name": "biz", "srcPath": "./features/biz" }] }\n',
    'entry/src/main/ets/Index.ets': 'struct I {}\n',
    'commons/base/src/main/ets/A.ets': 'export const a = 1;\n',
    'commons/base/build-profile.json5': '{}\n',
    'commons/base/oh-package.json5': '{ "name": "base", "dependencies": {} }\n',
    'features/biz/src/main/ets/B.ets': 'export const b = 2;\n',
    'features/biz/oh-package.json5': '{ "name": "biz", "dependencies": { "base": "file:../../commons/base", "shared": "../shared-x" } }\n',
    'features/biz/hvigorfile.ts': 'export default {}\n',
    'features/biz/Index.ets': 'export * from "./src/main/ets/B.ets";\n',
  };
  for (const [rel, content] of Object.entries(files)) {
    const file = join(srcRoot, rel);
    mkdirSync(join(file, '..'), { recursive: true });
    writeFileSync(file, content);
  }
  const outDir = mkdtempSync(join(tmpdir(), 'f1-n1-out-'));
  const migration = migrateSources(srcRoot, outDir);
  assert.equal(migration.ok, true, migration.reason);
  // G2-r2：嵌套 srcPath（commons/base、features/biz）模块级文件补迁（模块根由 mod.path 回溯）
  for (const f of ['base/build-profile.json5', 'base/oh-package.json5', 'biz/oh-package.json5', 'biz/hvigorfile.ts', 'biz/Index.ets']) {
    assert.ok(existsSync(join(outDir, f)), `模块级文件缺失 ${f}`);
  } // file:../../commons/base → file:../base（改写）；../shared-x（非迁移目标）→ 原样保留
  const bizPkg = JSON.parse(readFileSync(join(outDir, 'biz/oh-package.json5'), 'utf8'));
  assert.equal(bizPkg.dependencies.base, 'file:../base');
  assert.equal(bizPkg.dependencies.shared, '../shared-x');
  // N1：三处装配
  mkdirSync(join(outDir, '.arkui-x/android'), { recursive: true });
  writeFileSync(join(outDir, '.arkui-x/android/buildArkTS'), '#!/bin/bash\nmoduleLists=entry\n');
  writeFileSync(join(outDir, '.arkui-x/arkui-x-config.json5'), '{ "crossplatform": true, "modules": ["entry"] }\n');
  mkdirSync(join(outDir, 'entry'), { recursive: true });
  writeFileSync(join(outDir, 'entry/oh-package.json5'), '{ "name": "entry", "version": "1.0.0", "dependencies": {} }\n');
  assembleModules(outDir, migration.modules);
  const buildArkTS = readFileSync(join(outDir, '.arkui-x/android/buildArkTS'), 'utf8');
  assert.ok(buildArkTS.includes('moduleLists=entry,base,biz'), buildArkTS);
  const cfgRaw = readFileSync(join(outDir, '.arkui-x/arkui-x-config.json5'), 'utf8');
  const cfg = JSON.parse(cfgRaw.replace(/\/\/[^\n]*/g, '')); // json5 注释剥除（带行注释）
  assert.deepEqual(cfg.modules, ['entry', 'base', 'biz']); // 默认写入 buildOption.ignoreCrossPlatform（11706007 降警告）
  assert.equal(cfg.buildOption?.ignoreCrossPlatform, true, cfgRaw);
  const entryPkg = JSON.parse(readFileSync(join(outDir, 'entry/oh-package.json5'), 'utf8'));
  assert.equal(entryPkg.dependencies.base, 'file:../base');
  assert.equal(entryPkg.dependencies.biz, 'file:../biz');
  // 迁移校验仍通过（改写文件以最终内容入账）
  const v = verifyMigration(srcRoot, outDir, migration);
  assert.equal(v.ok, true, v.reason);
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('assembleModules 默认注入 ignoreCrossPlatform；--strict-crossplatform 关闭；幂等', () => {
  const outDir = mkdtempSync(join(tmpdir(), 'f1-icp-'));
  mkdirSync(join(outDir, '.arkui-x'), { recursive: true });
  writeFileSync(join(outDir, '.arkui-x/arkui-x-config.json5'), '{ "crossplatform": true, "modules": ["entry"] }\n');
  const mods = [{ name: 'base' }];
  let r = assembleModules(outDir, mods);
  let cfg = readFileSync(join(outDir, '.arkui-x/arkui-x-config.json5'), 'utf8');
  assert.ok(cfg.includes('"ignoreCrossPlatform": true'), '默认注入');
  assert.ok(cfg.includes('11706007 降警告'), '带标注');
  // 幂等：再跑不重复注入
  assembleModules(outDir, mods);
  cfg = readFileSync(join(outDir, '.arkui-x/arkui-x-config.json5'), 'utf8');
  assert.equal((cfg.match(/ignoreCrossPlatform/g) ?? []).length, 1, '幂等');
  // 严格模式：不注入
  const out2 = mkdtempSync(join(tmpdir(), 'f1-icp2-'));
  mkdirSync(join(out2, '.arkui-x'), { recursive: true });
  writeFileSync(join(out2, '.arkui-x/arkui-x-config.json5'), '{ "crossplatform": true, "modules": ["entry"] }\n');
  assembleModules(out2, mods, { strictCrossplatform: true });
  assert.ok(!readFileSync(join(out2, '.arkui-x/arkui-x-config.json5'), 'utf8').includes('ignoreCrossPlatform'), '严格模式关闭');
  rmSync(outDir, { recursive: true, force: true });
  rmSync(out2, { recursive: true, force: true });
});

test('readPlatformBaseline：build.gradle/pbxproj 实测提取 + 平台裁剪 + 缺失省略（适用版本澄清数据源）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-baseline-'));
  // 仅 Android 侧
  mkdirSync(join(root, '.arkui-x', 'android', 'app'), { recursive: true });
  writeFileSync(join(root, '.arkui-x', 'android', 'app', 'build.gradle'),
    'android {\n  compileSdkVersion 33\n  defaultConfig { minSdkVersion 26\n    targetSdkVersion 33 }\n}\n', 'utf8');
  assert.deepEqual(readPlatformBaseline(root, 'both'), {
    android: { min_sdk: 26, target_sdk: 33, compile_sdk: 33 }
  }, 'ios 侧缺失时省略');
  assert.deepEqual(readPlatformBaseline(root, 'android'), {
    android: { min_sdk: 26, target_sdk: 33, compile_sdk: 33 }
  });
  // 补 iOS 侧（pbxproj 多处同值取首个）
  mkdirSync(join(root, '.arkui-x', 'ios', 'app.xcodeproj'), { recursive: true });
  writeFileSync(join(root, '.arkui-x', 'ios', 'app.xcodeproj', 'project.pbxproj'),
    'buildSettings = {\n IPHONEOS_DEPLOYMENT_TARGET = 10.0;\n};\n IPHONEOS_DEPLOYMENT_TARGET = 10.0;\n', 'utf8');
  assert.deepEqual(readPlatformBaseline(root, 'ios'), { ios: { deployment_target: '10.0' } }, 'platform=ios 裁剪 android 侧');
  assert.deepEqual(readPlatformBaseline(root, 'both'), {
    android: { min_sdk: 26, target_sdk: 33, compile_sdk: 33 },
    ios: { deployment_target: '10.0' }
  });
  // minSdk 缺失 → android 侧整体省略（min_sdk 为必要项）
  const noMin = mkdtempSync(join(tmpdir(), 'f1-baseline-nomin-'));
  mkdirSync(join(noMin, '.arkui-x', 'android', 'app'), { recursive: true });
  writeFileSync(join(noMin, '.arkui-x', 'android', 'app', 'build.gradle'), 'targetSdkVersion 33\n', 'utf8');
  assert.equal(readPlatformBaseline(noMin, 'android'), null, 'minSdk 缺失 → 侧省略且两侧皆无 → null');
  // 全无 → null（产物不输出字段）
  assert.equal(readPlatformBaseline(join(root, 'nonexistent'), 'both'), null);
  rmSync(root, { recursive: true, force: true });
  rmSync(noMin, { recursive: true, force: true });
});

// ── Compile SDK 版本选择：物化六元组替换 + 断言版本感知 + 基线 openharmony 侧 ──
test('materializeFromArchive sdkVersion=24 → 六元组替换（OpenHarmony 形态数字 compileSdk）+ 断言按所选版本', () => {
  const out = mkdtempSync(join(tmpdir(), 'f1-csdk24-'));
  const r = materializeFromArchive(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), out, {
    platform: 'both', sdkVersion: resolveVersionEntry('24'),
  });
  assert.equal(r.ok, true, r.reason);
  const bp = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8'));
  assert.deepEqual(bp.app.products[0].compileSdkVersion, 24, 'OpenHarmony 形态：数字 apiLevel');
  assert.deepEqual(bp.app.products[0].compatibleSdkVersion, 24);
  assert.equal(bp.app.products[0].runtimeOS, 'OpenHarmony', 'runtimeOS 与源工程同步（未传源形态=缺省 OpenHarmony）');
  const pkg = JSON.parse(readFileSync(join(out, 'oh-package.json5'), 'utf8'));
  assert.equal(pkg.modelVersion, '6.1.1', '根 oh-package modelVersion=ON(24)');
  const hc = JSON.parse(readFileSync(join(out, 'hvigor', 'hvigor-config.json5'), 'utf8'));
  assert.equal(hc.modelVersion, '6.1.1');
  assert.equal(hc.dependencies['@ohos/hvigor-ohos-arkui-x-plugin'], '4.24.2', '插件版本=ON(24)');
  // platform_baseline.openharmony 实测提取
  const pb = readPlatformBaseline(out, 'both');
  assert.equal(pb.openharmony.compile_sdk_version, '24');
  assert.equal(pb.openharmony.runtime_os, 'OpenHarmony');
  assert.equal(pb.openharmony.model_version, '6.1.1');
  rmSync(out, { recursive: true, force: true });
});

test('materializeFromArchive sdkVersion=26.0.0（默认键）→ 字符串形态；缺省 sdkVersion 零替换保持归档值', () => {
  const outA = mkdtempSync(join(tmpdir(), 'f1-csdk26-'));
  const a = materializeFromArchive(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), outA, { sdkVersion: resolveVersionEntry('26.0.0') });
  assert.equal(a.ok, true, a.reason);
  const bpA = JSON.parse(readFileSync(join(outA, 'build-profile.json5'), 'utf8'));
  assert.equal(bpA.app.products[0].compileSdkVersion, '26.0.0', '26.0.0 写字符串');
  rmSync(outA, { recursive: true, force: true });
  const outB = mkdtempSync(join(tmpdir(), 'f1-csdk-def-'));
  const b = materializeFromArchive(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), outB, {});
  assert.equal(b.ok, true, b.reason);
  const bpB = JSON.parse(looseJson5(readFileSync(join(outB, 'build-profile.json5'), 'utf8'))); // 归档原生 JSON5（尾逗号）
  assert.equal(bpB.app.products[0].compileSdkVersion, '26.0.0', '缺省零替换');
  rmSync(outB, { recursive: true, force: true });
});

test('materializeFromArchive 断言版本感知：归档被改坏（compileSdk 与所选不符）→ 拒绝物化', () => {
  const archive = mkdtempSync(join(tmpdir(), 'f1-csdk-badarch-'));
  cpDirArchive(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), archive);
  const bpFile = join(archive, 'build-profile.json5');
  writeFileSync(bpFile, readFileSync(bpFile, 'utf8').replace('"compileSdkVersion": "26.0.0"', '"compileSdkVersion": "9.9.9"'));
  const out = mkdtempSync(join(tmpdir(), 'f1-csdk-badout-'));
  const r = materializeFromArchive(archive, out, {}); // 缺省路径——断言=归档完整性守卫（带 sdkVersion 时替换会归一化，防篡改仅在缺省路径生效）
  assert.equal(r.ok, false);
  assert.ok(r.reason.includes('拒绝物化'), r.reason);
  rmSync(archive, { recursive: true, force: true });
  rmSync(out, { recursive: true, force: true });
});

function cpDirArchive(src, dst) {
  mkdirSync(dst, { recursive: true });
  for (const e of readdirSync(src, { withFileTypes: true })) {
    const from = join(src, e.name);
    const to = join(dst, e.name);
    if (e.isDirectory()) cpDirArchive(from, to);
    else copyFileSync(from, to);
  }
}


// ── runtimeOS 与源工程同步：HarmonyOS 形态保留 + 版本写法分流（全形态串）+ 基线如实落账 ──
test('materializeFromArchive runtimeOS=HarmonyOS + sdkVersion=17 → 全形态版本串 + runtimeOS 保留 + 断言按形态', () => {
  const out = mkdtempSync(join(tmpdir(), 'f1-hmos17-'));
  const r = materializeFromArchive(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), out, {
    platform: 'both', sdkVersion: resolveVersionEntry('17'), runtimeOS: 'HarmonyOS',
  });
  assert.equal(r.ok, true, r.reason);
  const bp = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8'));
  assert.equal(bp.app.products[0].runtimeOS, 'HarmonyOS', '源工程 HarmonyOS 形态保留');
  assert.equal(bp.app.products[0].compileSdkVersion, '5.0.5(17)', 'HarmonyOS 形态：全形态串（ON 表 compileSdkVersion）');
  assert.equal(bp.app.products[0].compatibleSdkVersion, '5.0.5(17)');
  const pb = readPlatformBaseline(out, 'both');
  assert.equal(pb.openharmony.runtime_os, 'HarmonyOS', '基线如实落账实际形态');
  assert.equal(pb.openharmony.compile_sdk_version, '5.0.5(17)', '基线为实测提取——HarmonyOS 形态如实落账全形态串（版本键语义由 decisions.compile_sdk 承载）');
  rmSync(out, { recursive: true, force: true });
});

test('materializeFromArchive runtimeOS=HarmonyOS 且缺省版本 → 仅同步 runtimeOS，版本保持归档 26.0.0（两形态写法一致）', () => {
  const out = mkdtempSync(join(tmpdir(), 'f1-hmosdef-'));
  const r = materializeFromArchive(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), out, {
    platform: 'both', runtimeOS: 'HarmonyOS',
  });
  assert.equal(r.ok, true, r.reason);
  const bp = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8'));
  assert.equal(bp.app.products[0].runtimeOS, 'HarmonyOS');
  assert.equal(bp.app.products[0].compileSdkVersion, '26.0.0', '缺省版本零替换（26.0.0 两形态写法一致）');
  rmSync(out, { recursive: true, force: true });
});


// ── 版本三元组：保留源值 + 越界钳制（compatible <= target <= compile 恒成立；不无故抬升兼容基线）──
function mkArchiveWithTarget(targetVal) {
  const arc = mkdtempSync(join(tmpdir(), 'f1-arc-tri-'));
  cpSync(join(SKILL_ROOT, 'assets', 'scaffold-26.0.0'), arc, { recursive: true });
  const bpArc = join(arc, 'build-profile.json5');
  const doc = JSON.parse(looseJson5(readFileSync(bpArc, 'utf8')));
  if (targetVal !== undefined) doc.app.products[0].targetSdkVersion = targetVal;
  writeFileSync(bpArc, JSON.stringify(doc, null, 2) + '\n');
  return arc;
}

test('三元组保留：源 compatible(17)/target(20) 均在区间 → 选 compile 24 时三值递增保留（不抬升兼容基线）', () => {
  const arc = mkArchiveWithTarget();
  const out = mkdtempSync(join(tmpdir(), 'f1-tri-keep-'));
  const r = materializeFromArchive(arc, out, { platform: 'both', sdkVersion: resolveVersionEntry('24'),
    sourceSdkVersions: { compatibleSdkVersion: 17, targetSdkVersion: 20 } });
  assert.equal(r.ok, true, r.reason);
  const p = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8')).app.products[0];
  assert.deepEqual([p.compatibleSdkVersion, p.targetSdkVersion, p.compileSdkVersion], [17, 20, 24], '源值全保留（17<=20<=24）');
  rmSync(arc, { recursive: true, force: true }); rmSync(out, { recursive: true, force: true });
});

test('三元组钳制：源 target(20) > 所选 compile(17) → target 钳到 compile；HarmonyOS 形态全形态串同款', () => {
  const arc = mkArchiveWithTarget('26.0.0'); // 归档带 target 键 → 产物保留该键
  const out = mkdtempSync(join(tmpdir(), 'f1-tri-clamp-'));
  const r = materializeFromArchive(arc, out, { platform: 'both', sdkVersion: resolveVersionEntry('17'),
    runtimeOS: 'HarmonyOS', sourceSdkVersions: { compatibleSdkVersion: '5.0.5(17)', targetSdkVersion: '5.1.1(20)' } });
  assert.equal(r.ok, true, r.reason);
  const p = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8')).app.products[0];
  assert.deepEqual([p.compatibleSdkVersion, p.targetSdkVersion, p.compileSdkVersion],
    ['5.0.5(17)', '5.0.5(17)', '5.0.5(17)'], 'target 20>17 钳到 compile；compatible=17 保留同值');
  rmSync(out, { recursive: true, force: true });
  // 源 target 低于 compatible → 钳到 compatible
  const out2 = mkdtempSync(join(tmpdir(), 'f1-tri-clamp2-'));
  const r2 = materializeFromArchive(arc, out2, { platform: 'both', sdkVersion: resolveVersionEntry('24'),
    sourceSdkVersions: { compatibleSdkVersion: 20, targetSdkVersion: 17 } });
  assert.equal(r2.ok, true, r2.reason);
  const p2 = JSON.parse(readFileSync(join(out2, 'build-profile.json5'), 'utf8')).app.products[0];
  assert.deepEqual([p2.compatibleSdkVersion, p2.targetSdkVersion, p2.compileSdkVersion], [20, 20, 24], 'target 17<compatible 20 钳到 compatible');
  rmSync(arc, { recursive: true, force: true }); rmSync(out2, { recursive: true, force: true });
});

test('三元组保守：源 compatible 不可解析/高于 compile → 取 compile；源缺 target 归档带键 → =compile；零替换归档关系破坏拒绝物化', () => {
  const arc = mkArchiveWithTarget('26.0.0');
  const out = mkdtempSync(join(tmpdir(), 'f1-tri-fb-'));
  const r = materializeFromArchive(arc, out, { platform: 'both', sdkVersion: resolveVersionEntry('24'),
    sourceSdkVersions: { compatibleSdkVersion: 'weird(?)', targetSdkVersion: 22 } });
  assert.equal(r.ok, true, r.reason);
  const p = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8')).app.products[0];
  assert.deepEqual([p.compatibleSdkVersion, p.targetSdkVersion, p.compileSdkVersion], [24, 24, 24], 'compatible 不可解析→compile(24)；target 22<compatible 24 正确钳上到 compatible——不破坏关系');
  rmSync(out, { recursive: true, force: true });
  const out2 = mkdtempSync(join(tmpdir(), 'f1-tri-fb2-'));
  const r2 = materializeFromArchive(arc, out2, { platform: 'both', sdkVersion: resolveVersionEntry('17'),
    sourceSdkVersions: {} }); // 源缺 target，归档带键 → target=compile=17
  assert.equal(r2.ok, true, r2.reason);
  const p2 = JSON.parse(readFileSync(join(out2, 'build-profile.json5'), 'utf8')).app.products[0];
  assert.deepEqual([p2.compatibleSdkVersion, p2.targetSdkVersion, p2.compileSdkVersion], [17, 17, 17], '源缺：compatible/target 均=compile');
  rmSync(out2, { recursive: true, force: true });
  // 零替换路径 + 归档三值被外部改坏 → 拒绝物化（fail-fast）
  const arcBad = mkArchiveWithTarget('5.1.1(20)'); // compile/compatible=26 < target=20? 20<26 合法！改 target 为 27 形态外值不可解析 → 拒绝
  const arcBad2 = mkArchiveWithTarget('27.0.0');
  const out3 = mkdtempSync(join(tmpdir(), 'f1-tri-bad-'));
  const r3 = materializeFromArchive(arcBad2, out3, { platform: 'both' });
  assert.equal(r3.ok, false, '不可解析 target 应拒绝');
  assert.ok(r3.reason.includes('拒绝物化'), r3.reason);
  rmSync(arcBad, { recursive: true, force: true }); rmSync(arcBad2, { recursive: true, force: true }); rmSync(out3, { recursive: true, force: true });
});
