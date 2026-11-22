import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { migrateConfigs, verifyConfigMigration } from './config-migrator.js';

/** 构造源工程（业务配置齐全）与 scaffold 形态输出目录 */
function makePair() {
  const base = mkdtempSync(join(tmpdir(), 'f1-cfgmig-'));
  const src = join(base, 'src');
  const out = join(base, 'out');
  const put = (root, rel, content) => {
    const file = join(root, rel);
    mkdirSync(dirname(file), { recursive: true });
    writeFileSync(file, content, 'utf8');
  };
  // 源工程（无引号键/注释/尾逗号——官方样例常态写法）
  put(src, 'build-profile.json5', `{
    // 签名与产物配置
    "app": {
      signingConfigs: [{ name: 'default', material: { cert: 'x' } },],
      products: [{ name: 'default', signingConfig: 'default', compatibleSdkVersion: '5.0.5(17)' }],
    },
    modules: [{ name: 'entry', srcPath: './entry' }],
  }`);
  put(src, 'oh-package.json5', `{
    "name": "srcapp",
    "dependencies": { "@ohos/axios": "^2.2.0", "lottie": "^3.0.0" },
    "overrides": { "hypium": "1.0.6" },
  }`);
  put(src, 'entry/oh-package.json5', `{
    "name": "entry",
    "dependencies": { "@ohos/axios": "^2.2.0" },
  }`);
  put(src, 'AppScope/app.json5', `{
    "app": {
      "bundleName": "com.example.srcapp",
      "vendor": "srcvendor",
      "versionCode": 2000000,
      "versionName": "2.0.0",
      "icon": "$media:src_icon",
      "label": "$string:src_app_name"
    }
  }`);
  put(src, 'code-linter.json5', '{ "files": ["**/*.ets"] }\n');
  put(src, '.gitignore', 'oh_modules\n');
  put(src, 'hvigorfile.ts', "export { appTasks } from '@ohos/hvigor-ohos-plugin';\n");
  put(src, 'hvigor/hvigor-config.json5', '{ "modelVersion": "5.0.5" }\n');
  put(src, 'entry/build-profile.json5', '{ "apiType": "stageMode" }\n');
  // scaffold 形态输出（归档键：compileSdkVersion 26.0.0/arkui-x 插件等）
  put(out, 'build-profile.json5', `{
    "app": {
      "signingConfigs": [],
      "products": [{ "name": "default" }]
    },
    "modules": [{ "name": "entry", "srcPath": "./entry" }],
    "compileSdkVersion": "26.0.0",
    "compatibleSdkVersion": "26.0.0",
    "runtimeOS": "OpenHarmony"
  }`);
  put(out, 'oh-package.json5', `{
    "name": "arkuixapp",
    "modelVersion": "26.0.0",
    "devDependencies": { "@ohos/hypium": "1.0.6" }
  }`);
  put(out, 'entry/oh-package.json5', '{\n  "name": "entry",\n  "version": "1.0.0",\n  "dependencies": {}\n}\n');
  put(out, 'AppScope/app.json5', `{
    "app": {
      "bundleName": "com.example.arkuixapp",
      "vendor": "example",
      "versionCode": 1000000,
      "versionName": "1.0.0",
      "icon": "$media:app_icon",
      "label": "$string:app_name"
    }
  }`);
  put(out, 'hvigorfile.ts', "export { AppTasksForArkUIX } from '@ohos/hvigor-ohos-arkui-x-plugin';\n");
  put(out, 'hvigor/hvigor-config.json5', '{ "modelVersion": "26.0.0", "dependencies": { "@ohos/hvigor-ohos-arkui-x-plugin": "4.24.2" } }\n');
  put(out, 'entry/build-profile.json5', '{ "apiType": "stageMode", "targets": [] }\n');
  return { base, src, out };
}

test('migrateConfigs：白名单合并 + 无冲突拷贝 + 保留模板清单', () => {
  const { base, src, out } = makePair();
  const report = migrateConfigs(src, out);
  // 根 build-profile：signingConfigs 整组替换 + products 深合并；arkui-x 键不动
  const bp = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8'));
  assert.equal(bp.compileSdkVersion, '26.0.0', 'compileSdkVersion 不变量');
  assert.equal(bp.runtimeOS, 'OpenHarmony');
  assert.deepEqual(bp.app.signingConfigs.map((s) => s.name), ['default'], 'signingConfigs 源整组替换');
  assert.equal(bp.app.products[0].signingConfig, 'default', 'products 源字段落齐');
  assert.equal(bp.app.products[0].name, 'default');
  assert.equal(bp.app.products[0].compatibleSdkVersion, undefined, 'products 版本键被排除（源 5.0.5(17) 不覆盖 scaffold 语义位）');
  // 根 oh-package：依赖合并、身份键保留
  const pkg = JSON.parse(readFileSync(join(out, 'oh-package.json5'), 'utf8'));
  assert.equal(pkg.modelVersion, '26.0.0', 'modelVersion 不变量');
  assert.equal(pkg.name, 'arkuixapp', 'name 不变量');
  assert.equal(pkg.dependencies['@ohos/axios'], '^2.2.0');
  assert.equal(pkg.overrides.hypium, '1.0.6');
  assert.equal(pkg.devDependencies['@ohos/hypium'], '1.0.6', 'scaffold 独有 devDep 保留');
  // entry oh-package
  const entryPkg = JSON.parse(readFileSync(join(out, 'entry', 'oh-package.json5'), 'utf8'));
  assert.equal(entryPkg.dependencies['@ohos/axios'], '^2.2.0');
  assert.equal(entryPkg.name, 'entry', 'entry name 不变量');
  // app.json5：标量覆盖、bundleName 保留 scaffold 定制版
  const app = JSON.parse(readFileSync(join(out, 'AppScope', 'app.json5'), 'utf8'));
  assert.equal(app.app.bundleName, 'com.example.arkuixapp', 'bundleName 保留 scaffold 定制版');
  assert.equal(app.app.versionCode, 2000000);
  assert.equal(app.app.icon, '$media:src_icon');
  assert.equal(app.app.vendor, 'srcvendor');
  // 无冲突拷贝
  assert.ok(existsSync(join(out, 'code-linter.json5')));
  assert.ok(existsSync(join(out, '.gitignore')));
  // 保留模板：内容仍是 arkui-x 形态
  assert.ok(readFileSync(join(out, 'hvigorfile.ts'), 'utf8').includes('AppTasksForArkUIX'));
  assert.ok(readFileSync(join(out, 'hvigor', 'hvigor-config.json5'), 'utf8').includes('arkui-x-plugin'));
  // 报告结构
  assert.ok(report.merged.some((m) => m.file === 'build-profile.json5'));
  assert.ok(report.merged.some((m) => m.file === 'entry/oh-package.json5'));
  assert.ok(report.copied.includes('code-linter.json5'));
  const keptFiles = report.kept_template.map((k) => k.file);
  assert.deepEqual(keptFiles.sort(), ['entry/build-profile.json5', 'hvigor/hvigor-config.json5', 'hvigorfile.ts'].sort());
  assert.ok(report.kept_template.every((k) => k.reason.length > 0), '保留项逐条有原因');
  rmSync(base, { recursive: true, force: true });
});

test('verifyConfigMigration：正常合并 → 双向校验通过（无遗漏、无多改）', () => {
  const { base, src, out } = makePair();
  const report = migrateConfigs(src, out);
  const verify = verifyConfigMigration(src, out, report);
  assert.equal(verify.ok, true, JSON.stringify({ m: verify.missing, u: verify.unexpected_changes }));
  rmSync(base, { recursive: true, force: true });
});

test('verifyConfigMigration：遗漏检出（合并后人为删掉一个依赖 → missing 非空）', () => {
  const { base, src, out } = makePair();
  const report = migrateConfigs(src, out);
  const pkgPath = join(out, 'oh-package.json5');
  const pkg = JSON.parse(readFileSync(pkgPath, 'utf8'));
  delete pkg.dependencies['lottie'];
  writeFileSync(pkgPath, JSON.stringify(pkg, null, 2) + '\n', 'utf8');
  const verify = verifyConfigMigration(src, out, report);
  assert.equal(verify.ok, false);
  assert.ok(verify.missing.some((m) => m.includes('dependencies.lottie')), JSON.stringify(verify.missing));
  rmSync(base, { recursive: true, force: true });
});

test('verifyConfigMigration：多改检出（白名单外改动/不变量被改 → unexpected 非空）', () => {
  const { base, src, out } = makePair();
  const report = migrateConfigs(src, out);
  const bpPath = join(out, 'build-profile.json5');
  const bp = JSON.parse(readFileSync(bpPath, 'utf8'));
  bp.compileSdkVersion = '5.0.5'; // 不变量被改（多改）
  bp.app.someRandomKey = true;    // 白名单外新增
  writeFileSync(bpPath, JSON.stringify(bp, null, 2) + '\n', 'utf8');
  const verify = verifyConfigMigration(src, out, report);
  assert.equal(verify.ok, false);
  assert.ok(verify.unexpected_changes.some((u) => u.includes('compileSdkVersion')), JSON.stringify(verify.unexpected_changes));
  assert.ok(verify.unexpected_changes.some((u) => u.includes('白名单外改动 app.someRandomKey')));
  rmSync(base, { recursive: true, force: true });
});

test('migrateConfigs：源缺配置文件 → 零合并零报错（幂等安全）；snapshot 仅记被改动文件', () => {
  const base = mkdtempSync(join(tmpdir(), 'f1-cfgmig-empty-'));
  const src = join(base, 'src');
  const out = join(base, 'out');
  mkdirSync(src, { recursive: true });
  mkdirSync(join(out, 'AppScope'), { recursive: true });
  writeFileSync(join(out, 'AppScope', 'app.json5'), '{ "app": { "bundleName": "com.example.arkuixapp" } }\n');
  const report = migrateConfigs(src, out);
  assert.equal(report.merged.length, 0);
  assert.equal(report.copied.length, 0);
  assert.equal(report.kept_template.length, 0);
  assert.equal(report.snapshots.size, 0);
  rmSync(base, { recursive: true, force: true });
});

test('拷贝项在场时不再覆盖（scaffold 侧已有同名文件 → 不拷贝）', () => {
  const { base, src, out } = makePair();
  writeFileSync(join(out, 'code-linter.json5'), '{ "existing": true }\n', 'utf8');
  const report = migrateConfigs(src, out);
  assert.ok(!report.copied.includes('code-linter.json5'), '在场不覆盖');
  assert.equal(JSON.parse(readFileSync(join(out, 'code-linter.json5'), 'utf8')).existing, true);
  rmSync(base, { recursive: true, force: true });
});


// ── 版本三元组保护：源 targetSdkVersion 不合入（防 compatible<=target<=compile 关系破坏与形态混搭）──
test('migrateConfigs：源 products 含 targetSdkVersion → 恒 scaffold 值不合入（版本三元组不变量）', () => {
  const { base, src, out } = makePair();
  const srcBp = join(src, 'build-profile.json5');
  writeFileSync(srcBp, JSON.stringify({
    app: { signingConfigs: [], products: [{ name: 'default', compileSdkVersion: '5.0.0(12)', targetSdkVersion: '5.1.1(20)', compatibleSdkVersion: '5.0.5(17)' }] },
    modules: [],
  }, null, 2) + '\n');
  const report = migrateConfigs(src, out);
  const v = verifyConfigMigration(src, out, report);
  assert.equal(v.ok, true, JSON.stringify({ m: v.missing, u: v.unexpected_changes }));
  const bp = JSON.parse(readFileSync(join(out, 'build-profile.json5'), 'utf8'));
  const p = bp.app.products[0];
  assert.equal(p.targetSdkVersion, undefined, '源 targetSdkVersion 不合入 products（排除清单——版本三元组恒 scaffold/版本替换写）');
  assert.equal(p.compileSdkVersion, undefined, '源 compileSdkVersion 同排除（既有语义回归）');
  assert.equal(bp.compileSdkVersion, '26.0.0', '顶层归档版本不变量不受影响');
  rmSync(base, { recursive: true, force: true });
});
