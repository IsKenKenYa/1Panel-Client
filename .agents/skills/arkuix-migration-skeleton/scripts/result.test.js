import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderJson, renderMarkdown, renderVerificationAssists } from './result.js';

function sample(platform = 'both') {
  return {
    schema_version: 1,
    mode: 'modify',
    platform,
    android_shell: '.arkui-x/android',
    ios_shell: '.arkui-x/ios',
    shared_arkts_dir: 'entry',
    environment: {
      android: { ready: true, missing: [] },
      ios: { ready: false, missing: ['CocoaPods'] },
      arkui_x_sdk: { detected: true, version: '26.0.0', modify_available: true }
    }
  };
}

test('renderJson：键序固定，platform 在场，environment 含 arkui_x_sdk', () => {
  const parsed = JSON.parse(renderJson(sample()));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir', 'environment']);
  assert.deepEqual(Object.keys(parsed.environment), ['android', 'ios', 'arkui_x_sdk']);
  assert.deepEqual(parsed.environment.arkui_x_sdk, { detected: true, version: '26.0.0', modify_available: true });
});

test('renderJson：platform=android 时 ios_shell 不出现（条件输出）', () => {
  const parsed = JSON.parse(renderJson(sample('android')));
  assert.equal(parsed.platform, 'android');
  assert.ok(parsed.android_shell);
  assert.equal(parsed.ios_shell, undefined);
  const parsedIos = JSON.parse(renderJson(sample('ios')));
  assert.equal(parsedIos.android_shell, undefined);
  assert.ok(parsedIos.ios_shell);
});

test('renderJson：new 模式 migrated_modules 在场（键序固定、条目键序 name/target/files）；modify 不输出', () => {
  const withModules = { ...sample(), mode: 'new', migrated_modules: [
    { name: 'entry', target: 'entry', files: 79 },
    { name: 'common', target: 'common', files: 12 }
  ] };
  const parsed = JSON.parse(renderJson(withModules));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir', 'migrated_modules', 'environment']);
  assert.deepEqual(parsed.migrated_modules, [
    { name: 'entry', target: 'entry', files: 79 },
    { name: 'common', target: 'common', files: 12 }
  ]);
  const noModules = JSON.parse(renderJson(sample()));
  assert.equal(noModules.migrated_modules, undefined, 'modify（无迁入）不应输出该字段');
  const emptyModules = JSON.parse(renderJson({ ...sample(), migrated_modules: [] }));
  assert.equal(emptyModules.migrated_modules, undefined, '空数组同样不输出');
});

test('renderJson/Markdown：ace_warnings 非空沉淀（键序在 migrated_modules 后）+ 报告"编译前必办"段；空不输出', () => {
  const warn = "WARN: arkui-x project must delete the 'useNormalizedOHMUrl' Setting Items in build-profile.json5";
  const withWarn = { ...sample(), mode: 'modify', migrated_modules: [{ name: 'entry', target: 'entry', files: 3 }], ace_warnings: [warn] };
  const parsed = JSON.parse(renderJson(withWarn));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir',
    'migrated_modules', 'ace_warnings', 'environment']);
  assert.deepEqual(parsed.ace_warnings, [warn]);
  const md = renderMarkdown(withWarn, { aceWarnings: [warn] });
  assert.match(md, /ace 迁移提示（编译前必办/);
  assert.match(md, /useNormalizedOHMUrl/);
  assert.equal(JSON.parse(renderJson(sample())).ace_warnings, undefined, '无 WARN 不输出字段');
  const mdNoWarn = renderMarkdown(sample(), {});
  assert.doesNotMatch(mdNoWarn, /编译前必办/);
});

test('renderJson 确定性：同输入两次渲染一致；missing 稳定排序', () => {
  const a = sample();
  a.environment.ios.missing = ['Xcode', 'CocoaPods'];
  const b = sample();
  b.environment.ios.missing = ['CocoaPods', 'Xcode'];
  assert.equal(renderJson(a), renderJson(b), '乱序 missing 应归一');
});

test('报告：环境未就绪标注补验（骨架不受影响）', () => {
  const md = renderMarkdown(sample(), {});
  assert.match(md, /iOS 环境未就绪，需在对应环境补验/);
  assert.match(md, /骨架文件已按所选平台生成，不受环境影响/);
  assert.match(md, /CocoaPods/);
});

test('报告：平台选项与 ArkUI-X SDK 状态呈现', () => {
  const md = renderMarkdown(sample('android'), {});
  assert.match(md, /仅 Android/);
  assert.match(md, /ArkUI-X SDK/);
  assert.match(md, /检出（版本 26\.0\.0/);
  assert.match(md, /（未选，platform 不含 iOS）/);
});

test('验证辅助：仅就绪且所选平台生成（baseDir 拼接绝对路径）', () => {
  const assists = renderVerificationAssists(sample(), '/proj', { platform: 'linux' });
  assert.deepEqual(Object.keys(assists).sort(),
    ['verification/android-build.txt', 'verification/verify-android.sh']);
  assert.match(assists['verification/android-build.txt'], /cd \/proj\/\.arkui-x\/android/);
  assert.match(assists['verification/android-build.txt'], /\.\/gradlew assembleDebug/);
  assert.match(assists['verification/verify-android.sh'], /回填/);
  // platform=ios：android 就绪也不生成（未选平台）
  const iosOnly = renderVerificationAssists(sample('ios'), '/proj', { platform: 'linux' });
  assert.deepEqual(Object.keys(iosOnly), []);
});

test('验证辅助：win32 → gradlew.bat 命令与 .bat 脚本（不含 .sh）', () => {
  const assists = renderVerificationAssists(sample(), 'C:/proj', { platform: 'win32' });
  assert.deepEqual(Object.keys(assists).sort(),
    ['verification/android-build.txt', 'verification/verify-android.bat']);
  assert.match(assists['verification/android-build.txt'], /cd \/d C:\/proj\/\.arkui-x\/android/);
  assert.match(assists['verification/android-build.txt'], /gradlew\.bat assembleDebug/);
  assert.match(assists['verification/verify-android.bat'], /call gradlew\.bat assembleDebug/);
  assert.ok(!('verification/verify-android.sh' in assists));
});

test('报告：迁入统计呈现', () => {
  const md = renderMarkdown(sample(), { migration: { filesMoved: 12, ignored: ['oh_modules'] } });
  assert.match(md, /12 个文件已原样搬移/);
  assert.match(md, /oh_modules/);
});

test('报告：实际改动文件清单呈现（modify 成功路径）', () => {
  const md = renderMarkdown(sample(), { changedFiles: ['.arkui-x/android/build.gradle'] });
  assert.match(md, /实际改动文件清单/);
  assert.match(md, /\.arkui-x\/android\/build\.gradle/);
});

test('renderJson/Markdown：platform_baseline 非空输出（键序在 migrated_modules 后、ace_warnings 前）+ 报告"平台版本基线"段；空不输出', () => {
  const pb = { android: { min_sdk: 26, target_sdk: 33, compile_sdk: 33 }, ios: { deployment_target: '10.0' } };
  const withPb = { ...sample(), mode: 'new', migrated_modules: [{ name: 'entry', target: 'entry', files: 3 }], platform_baseline: pb };
  const parsed = JSON.parse(renderJson(withPb));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir',
    'migrated_modules', 'platform_baseline', 'environment']);
  assert.deepEqual(parsed.platform_baseline, pb);
  const md = renderMarkdown(withPb, {});
  assert.match(md, /平台版本基线（适用版本下限）/);
  assert.match(md, /minSdkVersion 26/);
  assert.match(md, /deployment target 10\.0/);
  assert.match(md, /升级 ArkUI-X SDK \/ Android SDK \/ Xcode/);
  assert.equal(JSON.parse(renderJson(sample())).platform_baseline, undefined, '未提取到基线不输出字段');
  assert.doesNotMatch(renderMarkdown(sample(), {}), /平台版本基线/);
});

test('platform_baseline 单侧裁剪：platform=android 仅 android 侧；min_sdk 缺失则整侧省略', () => {
  const androidOnly = { ...sample('android'), platform_baseline: { android: { min_sdk: 26 } } };
  const parsed = JSON.parse(renderJson(androidOnly));
  assert.deepEqual(parsed.platform_baseline, { android: { min_sdk: 26 } });
});

test('renderJson/Markdown：config_migration 输出（键序在 platform_baseline 后）+ 报告"配置文件迁移"段；缺席不输出', () => {
  const cm = {
    decision: 'yes',
    merged: [{ file: 'build-profile.json5', action: 'merge', keys: ['app.signingConfigs（整组替换）'] }],
    copied: ['code-linter.json5'],
    kept_template: [{ file: 'hvigorfile.ts', reason: 'arkui-x 专用任务导出（AppTasksForArkUIX）——覆盖破坏跨平台编译' }],
    verification: { ok: true, missing: [], unexpected_changes: [] },
  };
  const withCm = { ...sample(), mode: 'new', config_migration: cm };
  const parsed = JSON.parse(renderJson(withCm));
  assert.deepEqual(Object.keys(parsed), [
    'schema_version', 'mode', 'platform', 'android_shell', 'ios_shell', 'shared_arkts_dir',
    'platform_baseline', 'config_migration', 'environment'].filter((k) => k !== 'platform_baseline'));
  assert.deepEqual(parsed.config_migration, cm);
  const md = renderMarkdown(withCm, {});
  assert.match(md, /配置文件迁移（new 模式）/);
  assert.match(md, /已合并迁入（白名单策略）/);
  assert.match(md, /保留模板 hvigorfile\.ts/);
  assert.match(md, /校验（不遗漏\/不多改）：通过/);
  assert.equal(JSON.parse(renderJson(sample())).config_migration, undefined, 'modify 不输出该字段');
  assert.doesNotMatch(renderMarkdown(sample(), {}), /配置文件迁移/);
});

test('报告零源码正文（渲染仅白名单字段）', () => {
  const md = renderMarkdown(sample(), {});
  assert.doesNotMatch(md, /struct Index|build\(\)|@Component/);
});

test('Compile SDK 版本选择：platform_baseline.openharmony 透传 + 报告 OpenHarmony 基线行', () => {
  const pb = { openharmony: { compile_sdk_version: '24', runtime_os: 'OpenHarmony', model_version: '6.1.1' }, android: { min_sdk: 26 } };
  const parsed = JSON.parse(renderJson({ ...sample('android'), platform_baseline: pb }));
  assert.deepEqual(parsed.platform_baseline.openharmony, pb.openharmony);
  const md = renderMarkdown({ ...sample('android'), platform_baseline: pb }, {});
  assert.match(md, /OpenHarmony：compileSdkVersion 24（runtimeOS OpenHarmony），hvigor modelVersion 6\.1\.1/);
});
