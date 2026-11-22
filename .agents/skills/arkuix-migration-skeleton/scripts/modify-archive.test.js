import { test } from 'node:test';
import assert from 'node:assert/strict';
import { existsSync, mkdirSync, readFileSync, rmSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { modifyFromArchive } from './skeleton.js';
import { writeLocalProperties } from './scaffold.js';
import { arkuiXSdkPathsFromAce, arkuiXSdkPathsFromEnv, detectOhosSdkRoot, resolveAceBinPath } from './env-detector.js';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const ARCHIVE = join(ROOT, 'assets', 'scaffold-26.0.0');

function mkProject(dir, modules = {}) {
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(join(dir, 'AppScope'), { recursive: true });
  writeFileSync(join(dir, 'AppScope', 'app.json5'), JSON.stringify({ app: { bundleName: 'com.example.proj' } }));
  writeFileSync(join(dir, 'build-profile.json5'), JSON.stringify({
    app: { products: [{ name: 'default' }] },
    modules: Object.keys(modules).map((name) => ({ name, srcPath: `./${name}` }))
  }));
  writeFileSync(join(dir, 'oh-package.json5'), '{}');
  writeFileSync(join(dir, 'hvigorfile.ts'), 'export { appTasks } from "@ohos/hvigor-ohos-plugin";');
  for (const [name, task] of Object.entries(modules)) {
    mkdirSync(join(dir, name), { recursive: true });
    writeFileSync(join(dir, name, 'hvigorfile.ts'), `export { ${task} } from "@ohos/hvigor-ohos-plugin";`);
  }
  return dir;
}

const TMP = join(ROOT, 'benchmark', '.tmp-modarch-test');

test('/rewire：模块类型 hvigorfile 权威映射（app→AppTasksForArkUIX/hap→HapTasks/hsp→HspTasks/har 原样）', () => {
  const dir = mkProject(join(TMP, 'mixed'), { entry: 'hapTasks', feature: 'hapTasks', har: 'harTasks', shared: 'hspTasks' });
  const res = modifyFromArchive(dir, ARCHIVE, { platform: 'both' });
  assert.ok(res.ok, res.reason);
  const hv = (m) => readFileSync(join(dir, m, 'hvigorfile.ts'), 'utf8');
  assert.match(hv('.'), /export \{ AppTasksForArkUIX \} from '@ohos\/hvigor-ohos-arkui-x-plugin'/);
  assert.match(hv('entry'), /export \{ HapTasks \} from '@ohos\/hvigor-ohos-arkui-x-plugin'/);
  assert.match(hv('feature'), /export \{ HapTasks \} from '@ohos\/hvigor-ohos-arkui-x-plugin'/);
  assert.match(hv('shared'), /export \{ HspTasks \} from '@ohos\/hvigor-ohos-arkui-x-plugin'/);
  assert.equal(hv('har'), 'export { harTasks } from "@ohos/hvigor-ohos-plugin";', 'har 模块必须原样保留（插件无 HarTasksForArkUIX 导出）');
  assert.equal(res.modulesRewired, 4);
  assert.equal(res.modulesSkipped, 1, 'har 跳过计数');
});

test('/rewire：无已知任务导出的 hvigorfile 不动（对齐 ace 逐项 search 语义）', () => {
  const dir = mkProject(join(TMP, 'weird'), { entry: 'hapTasks', misc: 'customTasks' });
  const res = modifyFromArchive(dir, ARCHIVE, {});
  assert.ok(res.ok, res.reason);
  assert.equal(readFileSync(join(dir, 'misc', 'hvigorfile.ts'), 'utf8'), 'export { customTasks } from "@ohos/hvigor-ohos-plugin";');
});

test('/idem：二跑 hvigorfile 跳过（含 arkui-x-plugin 即幂等）+ hvigor-config 不重复注入', () => {
  const dir = mkProject(join(TMP, 'idem'), { entry: 'hapTasks' });
  const first = modifyFromArchive(dir, ARCHIVE, {});
  assert.ok(first.ok, first.reason);
  const configAfterFirst = readFileSync(join(dir, 'hvigor', 'hvigor-config.json5'), 'utf8');
  const second = modifyFromArchive(dir, ARCHIVE, {});
  assert.ok(second.ok, second.reason);
  assert.equal(second.modulesRewired, 0, '二跑无 hvigorfile 改写');
  const configAfterSecond = readFileSync(join(dir, 'hvigor', 'hvigor-config.json5'), 'utf8');
  assert.equal((configAfterSecond.match(/@ohos\/hvigor-ohos-arkui-x-plugin/g) || []).length,
    (configAfterFirst.match(/@ohos\/hvigor-ohos-arkui-x-plugin/g) || []).length, '插件依赖不重复');
});

test('platform 裁剪（android → 仅 android 壳）', () => {
  const dir = mkProject(join(TMP, 'platform'), { entry: 'hapTasks' });
  const res = modifyFromArchive(dir, ARCHIVE, { platform: 'android' });
  assert.ok(res.ok, res.reason);
  assert.ok(existsSync(join(dir, '.arkui-x', 'android')));
  assert.ok(!existsSync(join(dir, '.arkui-x', 'ios')));
});

test('buildArkTS 占位符注入（project_path 恒替换；SDK 路径传入才替换，缺则保留+envNote）', () => {
  const dir = mkProject(join(TMP, 'placeholders'), { entry: 'hapTasks' });
  const res = modifyFromArchive(dir, ARCHIVE, { arkuiXSdkPath: '/fake/xsdk/26.0.0/arkui-x' });
  assert.ok(res.ok, res.reason);
  const bat = readFileSync(join(dir, '.arkui-x', 'android', 'buildArkTS.bat'), 'utf8');
  assert.ok(!bat.includes('__PROJECT_PATH__'), 'project_path 必替换');
  assert.ok(bat.includes('/fake/xsdk/26.0.0/arkui-x'), 'SDK 路径替换');
  const dir2 = mkProject(join(TMP, 'placeholders2'), { entry: 'hapTasks' });
  const res2 = modifyFromArchive(dir2, ARCHIVE, {});
  assert.ok(res2.ok, res2.reason);
  const sh = readFileSync(join(dir2, '.arkui-x', 'ios', 'buildArkTS.sh'), 'utf8');
  assert.ok(!sh.includes('__PROJECT_PATH__'), 'project_path 恒替换');
  assert.ok(sh.includes('__ARKUIX_SDK_PATH__'), 'SDK 未检出保留占位符');
  assert.ok((res2.envNote || []).some((n) => n.includes('ArkUI-X SDK 路径未检出')), 'envNote 提示在场');
});

test('local.properties 生成（三键/根级路径/在场不覆盖）', () => {
  const dir = mkProject(join(TMP, 'localprops'), { entry: 'hapTasks' });
  const res = modifyFromArchive(dir, ARCHIVE, {
    arkuiXSdkRoot: '/fake/xsdk', ohosSdkRoot: '/fake/ohsdk'
  });
  assert.ok(res.ok, res.reason);
  const lp = readFileSync(join(dir, 'local.properties'), 'utf8');
  assert.match(lp, /^nodejs\.dir=/m);
  assert.ok(lp.includes('arkui-x.dir=/fake/xsdk'), 'arkui-x.dir=SDK 根（licenses 层）');
  assert.ok(lp.includes('sdk.dir=/fake/ohsdk'));
  assert.ok((res.envNote || []).some((n) => n.includes('local.properties 已生成')));
  // 在场不覆盖（ace pme 同语义）
  writeFileSync(join(dir, 'local.properties'), 'nodejs.dir=/keep\n');
  modifyFromArchive(dir, ARCHIVE, { arkuiXSdkRoot: '/fake/xsdk' });
  assert.equal(readFileSync(join(dir, 'local.properties'), 'utf8'), 'nodejs.dir=/keep\n');
});

test('/config：hvigor-config 缺文件时按 26.0.0 形态新建；bundleName 传导（补 JSON.parse）', () => {
  const dir = mkProject(join(TMP, 'config'), { entry: 'hapTasks' });
  const res = modifyFromArchive(dir, ARCHIVE, {});
  assert.ok(res.ok, res.reason);
  const cfg = JSON.parse(readFileSync(join(dir, 'hvigor', 'hvigor-config.json5'), 'utf8'));
  assert.equal(cfg.dependencies['@ohos/hvigor-ohos-arkui-x-plugin'], '4.24.2');
  const gradle = readFileSync(join(dir, '.arkui-x', 'android', 'app', 'build.gradle'), 'utf8');
  assert.ok(gradle.includes('com.example.proj'), 'bundleName 从 AppScope/app.json5 传导');
});

test('/config：旧 hvigorVersion 形态不注入插件（envNote 警示）', () => {
  const dir = mkProject(join(TMP, 'oldhvigor'), { entry: 'hapTasks' });
  mkdirSync(join(dir, 'hvigor'), { recursive: true });
  writeFileSync(join(dir, 'hvigor', 'hvigor-config.json5'), JSON.stringify({
    hvigorVersion: '4.1.2',
    dependencies: { '@ohos/hvigor-ohos-plugin': '4.1.2' }
  }));
  const res = modifyFromArchive(dir, ARCHIVE, {});
  assert.ok(res.ok, res.reason);
  const cfg = readFileSync(join(dir, 'hvigor', 'hvigor-config.json5'), 'utf8');
  assert.ok(!cfg.includes('arkui-x-plugin'), '旧形态不注入');
  assert.ok((res.envNote || []).some((n) => n.includes('hvigorVersion 形态')));
});

test('/失败：归档缺 .arkui-x → 显式失败', () => {
  const badArchive = join(TMP, 'bad-archive');
  rmSync(badArchive, { recursive: true, force: true });
  mkdirSync(badArchive, { recursive: true });
  const dir = mkProject(join(TMP, 'badarch'), { entry: 'hapTasks' });
  const res = modifyFromArchive(dir, badArchive, {});
  assert.equal(res.ok, false);
  assert.match(res.reason, /缺 \.arkui-x\//);
});

test('归档布局对齐 ace create（无 hvigor-wrapper.js/hvigorw/hvigorw.bat）', () => {
  assert.ok(!existsSync(join(ARCHIVE, 'hvigor', 'hvigor-wrapper.js')), '归档不含 hvigor-wrapper.js');
  assert.ok(!existsSync(join(ARCHIVE, 'hvigorw')), '归档不含 hvigorw');
  assert.ok(!existsSync(join(ARCHIVE, 'hvigorw.bat')), '归档不含 hvigorw.bat');
});

test('ARKUIX_SDK_DIR 形态路由（版本级/根级 ArkUI-X 接受；OH SDK 拒绝）', () => {
  const fake = join(TMP, 'envsdks');
  rmSync(fake, { recursive: true, force: true });
  // ArkUI-X 版本级布局
  mkdirSync(join(fake, 'xver', 'arkui-x'), { recursive: true });
  assert.deepEqual(arkuiXSdkPathsFromEnv(join(fake, 'xver')), { sdkPath: join(fake, 'xver', 'arkui-x'), sdkRoot: fake });
  // ArkUI-X 根级布局（版本子目录）
  mkdirSync(join(fake, 'xroot', '26.0.0', 'arkui-x'), { recursive: true });
  assert.deepEqual(arkuiXSdkPathsFromEnv(join(fake, 'xroot')), { sdkPath: join(fake, 'xroot', '26.0.0', 'arkui-x'), sdkRoot: join(fake, 'xroot') });
  // OH SDK 布局（ets/ 无 arkui-x）→ 拒绝
  mkdirSync(join(fake, 'ohver', 'ets'), { recursive: true });
  assert.deepEqual(arkuiXSdkPathsFromEnv(join(fake, 'ohver')), { sdkPath: '', sdkRoot: '' });
  assert.equal(arkuiXSdkPathsFromEnv(undefined).sdkPath, '');
});

test('ace 路径推导（arkuiXSdkPathsFromAce 版本级/根级两形态）', () => {
  const mac = '/Users/x/ArkUI-X/Sdk/26.0.0/arkui-x/toolchains/bin/ace';
  assert.deepEqual(arkuiXSdkPathsFromAce(mac), {
    sdkPath: '/Users/x/ArkUI-X/Sdk/26.0.0/arkui-x', sdkRoot: '/Users/x/ArkUI-X/Sdk'
  });
  const win = 'D:\\ArkUI-X\\Sdk\\26.0.0\\arkui-x\\toolchains\\bin\\ace.cmd';
  assert.deepEqual(arkuiXSdkPathsFromAce(win), {
    sdkPath: 'D:\\ArkUI-X\\Sdk\\26.0.0\\arkui-x', sdkRoot: 'D:\\ArkUI-X\\Sdk' // 字面量断言（跨平台确定——保留 Windows 输入的分隔符风格）
  });
  assert.deepEqual(arkuiXSdkPathsFromAce('/usr/bin/ace'), { sdkPath: '', sdkRoot: '' }, '形态不匹配返回空');
});

test('detectOhosSdkRoot（ARKUIX_SDK_DIR 版本级→根级；OH 根级直取；未检出空串）', () => {
  const fake = join(TMP, 'ohsdks');
  rmSync(fake, { recursive: true, force: true });
  mkdirSync(join(fake, '26', 'ets'), { recursive: true });            // OH 版本级（数字版本目录形态）
  mkdirSync(join(fake, 'root', '26.0.0', 'ets'), { recursive: true }); // OH 根级
  assert.equal(detectOhosSdkRoot({ ARKUIX_SDK_DIR: join(fake, '26') }), fake, '版本级→上级为根');
  assert.equal(detectOhosSdkRoot({ ARKUIX_SDK_DIR: join(fake, 'root') }), join(fake, 'root'), '根级直取');
  // 未命中注入假 home（隔离本机真实 SDK 安装路径）
  assert.equal(detectOhosSdkRoot({ ARKUIX_SDK_DIR: join(fake, 'nope') }, join(TMP, 'nohome')), '', '未命中不误报');
});

test('resolveAceBinPath（显式路径直取；PATH 扫描；未检出空串）', () => {
  const fake = join(TMP, 'pathscan');
  rmSync(fake, { recursive: true, force: true });
  mkdirSync(fake, { recursive: true });
  const aceFile = join(fake, 'ace');
  writeFileSync(aceFile, '#!/bin/sh\n');
  assert.equal(resolveAceBinPath(aceFile, {}), aceFile, '显式路径');
  assert.equal(resolveAceBinPath('ace', { PATH: fake }), aceFile, 'PATH 扫描命中');
  assert.equal(resolveAceBinPath('ace', { PATH: join(fake, 'empty') }), '', 'PATH 未命中');
});

test('writeLocalProperties（win32 转义/在场不覆盖/缺根不写）', () => {
  const dir = join(TMP, 'lp');
  rmSync(dir, { recursive: true, force: true });
  mkdirSync(dir, { recursive: true });
  assert.equal(writeLocalProperties(dir, {}, {}), false, '缺 arkuiXSdkRoot 不写');
  assert.ok(writeLocalProperties(dir, { arkuiXSdkRoot: '/x/sdk', ohosSdkRoot: '/oh/sdk' }));
  const content = readFileSync(join(dir, 'local.properties'), 'utf8');
  assert.match(content, /nodejs\.dir=.+\narkui-x\.dir=\/x\/sdk\nsdk\.dir=\/oh\/sdk\n/);
  assert.equal(writeLocalProperties(dir, { arkuiXSdkRoot: '/other' }), false, '在场不覆盖');
  const dir2 = join(TMP, 'lp-win');
  rmSync(dir2, { recursive: true, force: true });
  mkdirSync(dir2, { recursive: true });
  writeLocalProperties(dir2, { arkuiXSdkRoot: 'D:\\ArkUI-X\\Sdk', ohosSdkRoot: 'C:\\Users\\x\\Sdk' }, { platform: 'win32' });
  const win = readFileSync(join(dir2, 'local.properties'), 'utf8');
  assert.match(win, /arkui-x\.dir=D\\:\\\\ArkUI-X\\\\Sdk/);
});

test('多模块装配——modules/moduleLists 按工程真实模块回写（har 不入列）', () => {
  // 多模块工程：entry + phone/watch(feature) + common(har) + shared(shared)
  const dir = mkProject(join(TMP, 'assem'), { entry: 'hapTasks' });
  const bpDoc = JSON.parse(readFileSync(join(dir, 'build-profile.json5'), 'utf8'));
  for (const [name, type] of [['phone', 'feature'], ['watch', 'feature'], ['common', 'har'], ['shared', 'shared']]) {
    mkdirSync(join(dir, name, 'src', 'main'), { recursive: true });
    writeFileSync(join(dir, name, 'hvigorfile.ts'),
      `export { ${type === 'har' ? 'harTasks' : type === 'shared' ? 'hspTasks' : 'hapTasks'} } from "@ohos/hvigor-ohos-plugin";`);
    writeFileSync(join(dir, name, 'src', 'main', 'module.json5'),
      `{ "module": { "name": "${name}", "type": "${type}" } }`);
    bpDoc.modules.push({ name, srcPath: `./${name}` });
  }
  writeFileSync(join(dir, 'build-profile.json5'), JSON.stringify(bpDoc, null, 2));
  mkdirSync(join(dir, 'entry', 'src', 'main'), { recursive: true });
  writeFileSync(join(dir, 'entry', 'src', 'main', 'module.json5'),
    '{ "module": { "name": "entry", "type": "entry" } }');

  const res = modifyFromArchive(dir, ARCHIVE, {});
  assert.ok(res.ok, res.reason);
  const buildArk = readFileSync(join(dir, '.arkui-x', 'android', 'buildArkTS'), 'utf8');
  const m = buildArk.match(/moduleLists=([^\n#]+)/);
  assert.ok(m, 'moduleLists 行在场');
  assert.equal(m[1].trim(), 'entry,phone,watch,shared', 'har(common) 不入列');
  const bat = readFileSync(join(dir, '.arkui-x', 'android', 'buildArkTS.bat'), 'utf8');
  assert.ok(bat.includes('moduleLists=entry,phone,watch,shared'), 'bat 同步回写');
  const cfg = readFileSync(join(dir, '.arkui-x', 'arkui-x-config.json5'), 'utf8');
  assert.ok(cfg.includes('"phone"') && cfg.includes('"watch"') && cfg.includes('"shared"'), 'arkui-x-config modules 回写');
  assert.ok(!/"common"/.test(cfg), 'har 模块名不进 modules');
  assert.ok((res.envNote || []).some((n) => n.includes('模块装配')), 'envNote 模块装配提示');

  // 单 entry 工程：保持归档默认（moduleLists=entry），零扰动
  const single = mkProject(join(TMP, 'assem-single'), { entry: 'hapTasks' });
  mkdirSync(join(single, 'entry', 'src', 'main'), { recursive: true });
  writeFileSync(join(single, 'entry', 'src', 'main', 'module.json5'),
    '{ "module": { "name": "entry", "type": "entry" } }');
  const res2 = modifyFromArchive(single, ARCHIVE, {});
  assert.ok(res2.ok, res2.reason);
  const ba2 = readFileSync(join(single, '.arkui-x', 'android', 'buildArkTS'), 'utf8');
  assert.ok(/moduleLists=entry\b/.test(ba2), '单 entry 工程保持 moduleLists=entry（零扰动）');
  assert.ok(!(res2.envNote || []).some((n) => n.includes('模块装配')), '单 entry 不产生装配提示');
});

test('收尾：清理临时目录', () => {
  rmSync(TMP, { recursive: true, force: true });
});
