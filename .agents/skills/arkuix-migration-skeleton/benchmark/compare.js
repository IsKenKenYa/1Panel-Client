#!/usr/bin/env node
/**
 * 全量验收（对应入口）：
 * 1. modify 成功（默认=归档自修改，零 ace 依赖）→ 按平台选项的 .arkui-x 壳 + SkeletonResult
 *    1b. --ace-modify 成功（mock-ace 工具路径对齐验证WARN 沉淀）
 * 2. modify 平台三取值
 * 3. new 平台三取值 + 迁入完整性
 * 4. modify 失败 → 失败原因 + 改用 new 建议 + 退出码 5（ace-modify 路径）
 * 5. 超时：--timeout-ms 与 ARKUIX_ACE_TIMEOUT_MS 覆盖生效（ace-modify 路径）
 * 6. SDK 低版本 + --ace-modify → 拒绝提示 + 退出码 4 + 零写（边界场景 8）；
 *    SDK 低版本 + 默认归档 modify → 不受门槛（归档注入不依赖 ace）
 * 7. 覆盖确认三分支（skip=0/overwrite=产出/abort=6）+ 非交互缺省 abort
 * 8. 计划确认：非 TTY 无 --yes → 退出码 6；模型拒绝 → 退出码 3——归档/ace 两路径同守卫
 * 9. 参数非法值 → 退出码 2（非交互部分）
 * 10. 全参数组合零交互
 * 11. 3 次一致性
 * 12. 离线静态检查
 * 13级归档 modify 场景矩阵：模块类型 hvigorfile 权威映射（har 不动/hsp→HspTasks/hap→HapTasks/
 *     app→AppTasksForArkUIX）、占位符注入（project_path/arkuiXSdkPath）、local.properties、
 *     hvigor-config 插件注入、归档无 hvigor-wrapper.js/hvigorw（对齐 ace create API≥12 布局）、幂等
 */
import { spawnSync } from 'node:child_process';
import { readFileSync, readdirSync, existsSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { fileURLToPath } from 'node:url';
import { dirname, join, relative } from 'node:path';

const ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const BENCH = join(ROOT, 'benchmark');
const SKELETON = join(ROOT, 'scripts', 'skeleton.js');
const MOCK_ACE = join(BENCH, 'mock-ace', 'ace.js');
const expected = JSON.parse(readFileSync(join(BENCH, 'expected-metrics.json'), 'utf8'));

let failures = 0;
function check(ok, label, detail = '') {
  console.log(`${ok ? '✔' : '✖'} ${label}${ok || !detail ? '' : ` — ${detail}`}`);
  if (!ok) failures++;
}

function run(args, env = {}) {
  return spawnSync(process.execPath, [SKELETON, ...args], {
    encoding: 'utf8',
    env: { ...process.env, ...env }
  });
}

const aceArgs = ['--ace-bin', MOCK_ACE];
const EXIT = expected.exit_codes;

function readResult(outDir) {
  return JSON.parse(readFileSync(join(outDir, 'skeleton-result.json'), 'utf8'));
}

function snapshotDir(root) {
  const entries = [];
  walk(root).forEach((f) => {
    entries.push(`${relative(root, f)}:${createHash('sha256').update(readFileSync(f)).digest('hex')}`);
  });
  return entries.sort().join('|');
}

function walk(dir) {
  const files = [];
  if (!existsSync(dir)) return files;
  for (const e of readdirSync(dir, { withFileTypes: true })) {
    const full = join(dir, e.name);
    if (e.isDirectory()) files.push(...walk(full));
    else if (e.isFile()) files.push(full);
  }
  return files;
}

const stageFixture = join(BENCH, 'fixture-stage-project');
const faFixture = join(BENCH, 'fixture-fa-project');
const mixedFixture = join(BENCH, 'fixture-mixedmods-project');
const stageReport = join(BENCH, 'scan-reports', 'stage.json');
const faReport = join(BENCH, 'scan-reports', 'fa.json');

function freshCopy(name) {
  const dir = join(BENCH, name);
  rmSync(dir, { recursive: true, force: true });
  cpDir(stageFixture, dir);
  return dir;
}

// ── 1. modify 成功（platform=both；默认=归档自修改） ──────
const stageWork = freshCopy('.tmp-stage-work');
{
  const out = join(BENCH, '.tmp-out-modify');
  rmSync(out, { recursive: true, force: true });
  const runRes = run([stageWork, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes',
    '--ace-bin', '/no/such/ace']);
  check(runRes.status === EXIT.ok, 'modify 成功退出码 0（默认归档路径，假 ace 佐证零 ace 依赖）', runRes.stderr);
  const result = readResult(out);
  check(result.mode === expected.modify.mode, 'SkeletonResult.mode=modify');
  check(result.platform === expected.modify.platform, 'platform=both 记录所选平台');
  check(result.android_shell === expected.modify.android_shell, 'android_shell 相对路径 .arkui-x/android', result.android_shell);
  check(result.ios_shell === expected.modify.ios_shell, 'ios_shell 相对路径 .arkui-x/ios', result.ios_shell);
  check(result.shared_arkts_dir === expected.modify.shared_arkts_dir, 'shared_arkts_dir=entry（相对工程根）');
  check(result.platform_baseline && result.platform_baseline.android
    && result.platform_baseline.android.min_sdk === 26 && result.platform_baseline.android.compile_sdk === 33
    && result.platform_baseline.ios && result.platform_baseline.ios.deployment_target === '10.0',
  'platform_baseline 实测提取（归档 Android minSdk 26/compileSdk 33、iOS 10.0）', JSON.stringify(result.platform_baseline));
  check(existsSync(join(stageWork, '.arkui-x', 'android', 'build.gradle')), '.arkui-x/android 产物在场');
  check(existsSync(join(stageWork, '.arkui-x', 'ios')), '.arkui-x/ios 产物在场');
  check((runRes.stdout || '').includes('实际改动文件清单'), 'modify 成功路径输出实际改动清单（归档路径同守卫）');
  check((runRes.stdout || '').includes('已从归档注入跨平台壳'), '归档注入提示输出');
  check(existsSync(join(out, 'migration-skeleton-report.md')), '骨架报告产出');
}

// ── 1b. --ace-modify 成功（mock-ace 工具路径WARN 沉淀） ──────────
{
  const work = freshCopy('.tmp-stage-acemod');
  const out = join(BENCH, '.tmp-out-acemod');
  rmSync(out, { recursive: true, force: true });
  const runRes = run([work, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes',
    '--ace-modify', ...aceArgs]);
  check(runRes.status === EXIT.ok, '--ace-modify 退出码 0（工具路径保留）', runRes.stderr);
  const result = readResult(out);
  check(result.environment && result.environment.arkui_x_sdk
    && result.environment.arkui_x_sdk.detected === true
    && result.environment.arkui_x_sdk.modify_available === true,
    'environment.arkui_x_sdk 检出且 modify_available（26.0.0 ≥ API 22）');
  check(Array.isArray(result.ace_warnings) && result.ace_warnings.some((w) => w.includes('useNormalizedOHMUrl')),
    '--ace-modify 沉淀 ace_warnings（useNormalizedOHMUrl 必办）', JSON.stringify(result.ace_warnings));
  const modReport = readFileSync(join(out, 'migration-skeleton-report.md'), 'utf8');
  check(/ace 迁移提示（编译前必办/.test(modReport) && modReport.includes('useNormalizedOHMUrl'),
    '报告含"ace 迁移提示（编译前必办）"段');
  rmSync(work, { recursive: true, force: true });
}

// ── 2. modify 平台三取值 ─────────────────────────────────
for (const platform of ['both', 'android', 'ios']) {
  const work = freshCopy(`.tmp-stage-p-${platform}`);
  const out = join(BENCH, `.tmp-out-p-${platform}`);
  rmSync(out, { recursive: true, force: true });
  const runRes = run([work, '--scan-report', stageReport, '--mode', 'modify', '--platform', platform,
    '--out', out, '--yes', ...aceArgs]);
  check(runRes.status === EXIT.ok, `modify --platform=${platform} 退出码 0`, runRes.stderr);
  const result = readResult(out);
  check(result.platform === platform, `platform=${platform} 记录`);
  const androidShellExists = existsSync(join(work, '.arkui-x', 'android'));
  const iosShellExists = existsSync(join(work, '.arkui-x', 'ios'));
  if (platform === 'both') {
    check(androidShellExists && iosShellExists, 'both → 双平台壳在场');
    check(result.android_shell && result.ios_shell, 'both → 两壳字段必填');
  } else if (platform === 'android') {
    check(androidShellExists && !iosShellExists, 'android → 仅 android 壳', `a=${androidShellExists} i=${iosShellExists}`);
    check(result.android_shell === expected.modify.platform_cases.android.android_shell
      && result.ios_shell === undefined, 'android → android_shell 必填、ios_shell 不出现');
  } else {
    check(iosShellExists && !androidShellExists, 'ios → 仅 ios 壳', `a=${androidShellExists} i=${iosShellExists}`);
    check(result.ios_shell === expected.modify.platform_cases.ios.ios_shell
      && result.android_shell === undefined, 'ios → ios_shell 必填、android_shell 不出现');
  }
  rmSync(work, { recursive: true, force: true });
}

// ── 3. modify 失败（ace-modify 工具路径） ────────────────────────
{
  const failWork = freshCopy('.tmp-stage-fail');
  const out = join(BENCH, '.tmp-out-fail');
  rmSync(out, { recursive: true, force: true });
  const runRes = run([failWork, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes',
    '--ace-modify', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'fail' });
  check(runRes.status === EXIT.tool_fail, `modify 失败退出码 ${EXIT.tool_fail}`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes('建议改用 new'), '输出建议改用 new 模式', runRes.stderr);
  check((runRes.stderr || '').includes('ace modify 失败'), '输出失败原因');
  check(!existsSync(join(out, 'skeleton-result.json')), '失败路径不产出 SkeletonResult');
  rmSync(failWork, { recursive: true, force: true });
}

// ── 4. modify 前置失败（缺三件套） ─────────────────────────────────────
{
  const incomplete = join(BENCH, '.tmp-stage-incomplete');
  rmSync(incomplete, { recursive: true, force: true });
  mkdirSync(join(incomplete, 'AppScope'), { recursive: true });
  writeFileSync(join(incomplete, 'AppScope', 'app.json5'), '{}');
  const runRes = run([incomplete, '--scan-report', stageReport, '--mode', 'modify', '--yes', ...aceArgs]);
  check(runRes.status === EXIT.usage, '前置校验：缺三件套退出码 2（输入无效）');
  check((runRes.stderr || '').includes('工程不完整'), '前置校验：提示工程不完整', runRes.stderr);
  check(!existsSync(join(incomplete, '.arkui-x')), '前置校验：零产出');
}

// ── 5. 超时：--timeout-ms 透传 + ARKUIX_ACE_TIMEOUT_MS 覆盖生效（ace-modify 路径） ──
{
  const timeoutWork = freshCopy('.tmp-stage-timeout');
  const runRes = run([timeoutWork, '--scan-report', stageReport, '--mode', 'modify', '--yes',
    '--timeout-ms', '1', '--ace-modify', ...aceArgs], { MOCK_ACE_BEHAVIOR: 'timeout' });
  check(runRes.status === EXIT.tool_timeout, `--timeout-ms=1 超时路径退出码 ${EXIT.tool_timeout}`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes('>1ms'), '超时失败消息含实际阈值（>1ms）', runRes.stderr);
  const invalid = run([stageFixture, '--scan-report', stageReport, '--timeout-ms', 'abc']);
  check(invalid.status === EXIT.usage && (invalid.stderr || '').includes('正整数毫秒'), '非法 --timeout-ms 拒绝（码 2）');

  // 环境变量覆盖：小阈值注入验证生效（design：非法值回默认并警告）
  const envWork = freshCopy('.tmp-stage-envtimeout');
  const envRun = run([envWork, '--scan-report', stageReport, '--mode', 'modify', '--yes', '--ace-modify', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'timeout', ARKUIX_ACE_TIMEOUT_MS: '100' });
  check(envRun.status === EXIT.tool_timeout, 'ARKUIX_ACE_TIMEOUT_MS=100 覆盖生效（超时触发）', `status=${envRun.status}`);
  check((envRun.stderr || '').includes('>100ms'), '环境变量超时消息含覆盖阈值（>100ms）', envRun.stderr);
  const envWarnWork = freshCopy('.tmp-stage-envwarn');
  const envInvalid = run([envWarnWork, '--scan-report', stageReport, '--mode', 'modify', '--yes', '--ace-modify', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'fail', ARKUIX_ACE_TIMEOUT_MS: 'bogus' });
  check((envInvalid.stderr || '').includes('ARKUIX_ACE_TIMEOUT_MS 非法值'), '非法环境值警告后回默认', envInvalid.stderr);
  rmSync(timeoutWork, { recursive: true, force: true });
  rmSync(envWork, { recursive: true, force: true });
  rmSync(envWarnWork, { recursive: true, force: true });
}

// ── 6. SDK 低版本 + --ace-modify → 拒绝（边界，退出码 4，零写）；归档路径不受门槛 ──
{
  const lowWork = freshCopy('.tmp-stage-low');
  const before = snapshotDir(lowWork);
  const runRes = run([lowWork, '--scan-report', stageReport, '--mode', 'modify', '--yes', '--ace-modify', ...aceArgs],
    { MOCK_ACE_VERSION: '21' });
  check(runRes.status === EXIT.env_low_sdk, `场景8: SDK<API22 + --ace-modify 退出码 ${EXIT.env_low_sdk}`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes('ace modify 不可用'), '拒绝提示在场', runRes.stderr);
  check((runRes.stderr || '').includes('21'), '提示含检出版本', runRes.stderr);
  check((runRes.stderr || '').includes('new'), '提示含改用 new 建议');
  check(snapshotDir(lowWork) === before, '拒绝路径零写');
  rmSync(lowWork, { recursive: true, force: true });
}
{ // 语义：SDK 低版本（或 ace 缺失）+ 默认归档 modify → 不受门槛（归档注入不依赖 ace）
  const lowArchWork = freshCopy('.tmp-stage-lowarch');
  const out = join(BENCH, '.tmp-out-lowarch');
  rmSync(out, { recursive: true, force: true });
  const lowArchRun = run([lowArchWork, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes',
    '--ace-bin', '/no/such/ace'], { MOCK_ACE_VERSION: '21' });
  check(lowArchRun.status === EXIT.ok, 'SDK 缺失不阻断默认归档 modify（modify_available 门槛仅限 ace 工具路径）', lowArchRun.stderr);
  check(existsSync(join(lowArchWork, '.arkui-x', 'arkui-x-config.json5')), '归档路径正常注入 .arkui-x 壳');
  check(readResult(out).environment.arkui_x_sdk.modify_available === false, 'environment 如实记录 modify_available=false');
  // new 模式不受门槛阻断
  const newOut = join(BENCH, '.tmp-out-lownew');
  rmSync(newOut, { recursive: true, force: true });
  const newRun = run([lowArchWork, '--scan-report', stageReport, '--mode', 'new', '--out', newOut, '--yes', '--migrate-configs', 'no', '--compile-sdk', '26.0.0', ...aceArgs],
    { MOCK_ACE_VERSION: '21' });
  check(newRun.status === EXIT.ok, 'SDK 低版本不阻断 new 模式', newRun.stderr);
  check(readResult(newOut).environment.arkui_x_sdk.modify_available === false, 'new 路径 environment 记录 modify_available=false');
  rmSync(lowArchWork, { recursive: true, force: true });
  rmSync(out, { recursive: true, force: true });
  rmSync(newOut, { recursive: true, force: true });
}

// ── 7. new 成功 + 平台三取值 + 迁入完整性 ────────────────
for (const platform of ['both', 'android', 'ios']) {
  const out = join(BENCH, `.tmp-out-new-${platform}`);
  rmSync(out, { recursive: true, force: true });
  const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--platform', platform,
    '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--out', out, '--yes', ...aceArgs]);
  check(runRes.status === EXIT.ok, `new --platform=${platform} 退出码 0`, runRes.stderr);
  const result = readResult(out);
  check(result.mode === expected.new.mode && result.platform === platform, `mode=new platform=${platform}`);
  check(existsSync(join(out, '.arkui-x', 'android')) === (platform !== 'ios'), `android 壳在 .arkui-x/ 按平台生成/裁剪（${platform}）`);
  check(existsSync(join(out, '.arkui-x', 'ios')) === (platform !== 'android'), `ios 壳在 .arkui-x/ 按平台生成/裁剪（${platform}）`);
  if (platform === 'android') check(result.ios_shell === undefined, 'new+android → ios_shell 不出现');
  if (platform === 'ios') check(result.android_shell === undefined, 'new+ios → android_shell 不出现');
  if (platform !== 'ios') check(result.android_shell === '.arkui-x/android', '壳路径=.arkui-x/android（ace 26.0.0 布局）', result.android_shell);
  const sharedSrc = join(out, 'entry', 'src', 'main');
  const srcMain = join(stageFixture, 'entry', 'src', 'main');
  let migrationOk = true;
  const detail = [];
  for (const rel of expected.new.migrated_rels) {
    const from = join(srcMain, rel);
    const to = join(sharedSrc, rel);
    if (!existsSync(to)) { migrationOk = false; detail.push(`缺失 ${rel}`); continue; }
    if (hashOf(from) !== hashOf(to)) { migrationOk = false; detail.push(`改写 ${rel}`); }
  }
  check(migrationOk, '迁入文件集合+内容哈希一致', detail.join('; '));
  check(walk(sharedSrc).length >= expected.new.migrated_files, '迁入数量', `实际 ${walk(sharedSrc).length}`);
  check(existsSync(join(out, 'migration-skeleton-report.md')), '报告产出');
  check(result.shared_arkts_dir === 'entry', 'new shared_arkts_dir 相对输出目录（entry）', result.shared_arkts_dir);
}

// ── 7b. --migrate-configs 强确认门 + yes 合并/校验 + 参数校验 ───────────
{
  // 强确认门：new 模式非 TTY 缺参数 → 码 6 零产出 + 指引
  const gateOut = join(BENCH, '.tmp-out-mcgate');
  rmSync(gateOut, { recursive: true, force: true });
  const gateRun = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', gateOut, '--yes', ...aceArgs]);
  check(gateRun.status === EXIT.user_abort, 'new 非 TTY 缺 --migrate-configs → 码 6（强确认门不代答）', `status=${gateRun.status}`);
  check((gateRun.stderr || '').includes('--migrate-configs <yes|no>'), '指引含参数形态', gateRun.stderr);
  check((gateRun.stderr || '').includes('migrate_configs=yes|no'), '指引含编排器 --answer 通道');
  check(!existsSync(join(gateOut, 'skeleton-result.json')), '门中止零产出');

  // 参数校验：非法值 → 码 2；modify 模式误用 → 码 2
  const badVal = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', join(BENCH, '.tmp-mc-bad'),
    '--migrate-configs', 'maybe', '--yes', ...aceArgs]);
  check(badVal.status === EXIT.usage && (badVal.stderr || '').includes('yes/no'), '--migrate-configs 非法值 → 码 2', badVal.stderr);
  const misMod = run([stageFixture, '--scan-report', stageReport, '--mode', 'modify', '--out', join(BENCH, '.tmp-mc-mod'),
    '--migrate-configs', 'yes', '--compile-sdk', '26.0.0', '--yes', ...aceArgs]);
  check(misMod.status === EXIT.usage && (misMod.stderr || '').includes('仅适用于 new'), 'modify 误用 → 码 2', misMod.stderr);

  // no：维持现状（不合并、config_migration.decision=no 落账）——归档物化路径（真实 scaffold 配置面）
  const noOut = join(BENCH, '.tmp-out-mcno');
  rmSync(noOut, { recursive: true, force: true });
  const noRun = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', noOut, '--scaffold-from',
    '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', '--ace-bin', '/no/such/ace']);
  check(noRun.status === EXIT.ok, '--migrate-configs no 退出码 0', noRun.stderr);
  const noResult = readResult(noOut);
  check(noResult.config_migration && noResult.config_migration.decision === 'no', 'config_migration.decision=no 落账');
  check(!readFileSync(join(noOut, 'oh-package.json5'), 'utf8').includes('@ohos/axios'), 'no 不合并源依赖');

  // yes：白名单合并 + 遗漏/多改校验通过 + 产物字段与报告段（归档物化路径——真实 scaffold 配置面）
  const yesOut = join(BENCH, '.tmp-out-mcyes');
  rmSync(yesOut, { recursive: true, force: true });
  const yesRun = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', yesOut, '--scaffold-from',
    '--migrate-configs', 'yes', '--compile-sdk', '26.0.0', '--yes', '--ace-bin', '/no/such/ace']);
  check(yesRun.status === EXIT.ok, '--migrate-configs yes 退出码 0（合并+校验通过）', yesRun.stderr);
  const yesResult = readResult(yesOut);
  const cm = yesResult.config_migration;
  check(cm && cm.decision === 'yes', 'config_migration.decision=yes 落账');
  check(cm.verification && cm.verification.ok === true, '遗漏/多改双向校验通过', JSON.stringify(cm.verification));
  check((cm.kept_template ?? []).some((k) => k.file === 'hvigorfile.ts' && k.reason.length > 0), '保留模板项逐条有原因');
  const yesBp = JSON.parse(readFileSync(join(yesOut, 'build-profile.json5'), 'utf8'));
  check(yesBp.app.products[0].compileSdkVersion === '26.0.0' && yesBp.app.products[0].compatibleSdkVersion === '5.0.5(17)',
    '版本三元组保留语义——compile=所选 26.0.0，源 compatibleSdkVersion 5.0.5(17) 保留不抬升（17<=26 关系成立；target/target 键由物化层统一计算，合并不触碰）');
  check((yesBp.app.signingConfigs ?? []).some((s) => s.name === 'default'), '源 signingConfigs 落齐（不遗漏）');
  check(yesBp.app.products[0].deliveryWithHap === true, '源 products 业务字段落齐');
  const yesPkg = JSON.parse(readFileSync(join(yesOut, 'oh-package.json5'), 'utf8'));
  check(yesPkg.modelVersion === '26.0.0', 'modelVersion 不变量');
  check(yesPkg.dependencies['@ohos/axios'] === '^2.2.0', '源依赖落齐');
  const yesEntryPkg = JSON.parse(readFileSync(join(yesOut, 'entry', 'oh-package.json5'), 'utf8'));
  check(yesEntryPkg.dependencies['@ohos/axios'] === '^2.2.0', 'entry 源依赖落齐');
  const yesApp = JSON.parse(readFileSync(join(yesOut, 'AppScope', 'app.json5'), 'utf8'));
  check(yesApp.app.versionCode === 2000000 && yesApp.app.vendor === 'benchvendor', 'app.json5 标量落齐');
  check(yesApp.app.bundleName === 'com.example.arkuixapp', 'bundleName 保留 scaffold 定制版');
  const yesMd = readFileSync(join(yesOut, 'migration-skeleton-report.md'), 'utf8');
  check(yesMd.includes('### 配置文件迁移（new 模式）'), '报告"配置文件迁移"段在场');
  check(yesMd.includes('保留模板 hvigorfile.ts'), '报告列保留模板项');
  check((yesRun.stdout || '').includes('校验通过：无遗漏、无多改'), '完成提示含校验结论');

  // no 场景报告仅渲染决策行，不渲染合并明细（保留模板/校验行缺席）
  const noMd = readFileSync(join(noOut, 'migration-skeleton-report.md'), 'utf8');
  check(noMd.includes('决策：不迁移'), 'no 场景决策行在场（审计）');
  check(!noMd.includes('保留模板') && !noMd.includes('校验（不遗漏'), 'no 场景不渲染配置迁移明细行');
}

// ── 7c. Compile SDK 版本选择（强确认门 + 版本六元组替换 + 产物基线落账） ───────────
{
  // 强门：非 TTY 缺 --compile-sdk → 码 6 零产出 + 指引（含最高/源工程版本推荐）
  const csGateOut = join(BENCH, '.tmp-out-csgate');
  rmSync(csGateOut, { recursive: true, force: true });
  const csGate = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', csGateOut, '--yes',
    '--migrate-configs', 'no', '--scaffold-from', ...aceArgs]);
  check(csGate.status === EXIT.user_abort, '版本门: new 缺 --compile-sdk → 码 6（不代答）', `status=${csGate.status}`);
  check((csGate.stderr || '').includes('--compile-sdk <版本>'), '版本门: 指引含参数形态', csGate.stderr);
  check((csGate.stderr || '').includes('源工程版本 17'), '版本门: 指引含源工程版本推荐（fixture compatibleSdkVersion 5.0.5(17) → 17）');
  check((csGate.stderr || '').includes('compile_sdk='), '版本门: 指引含编排器 --answer 通道');
  check(!existsSync(join(csGateOut, 'skeleton-result.json')), '版本门: 零产出');

  // 未收录版本 → 码 2 + 支持清单；modify 误用 → 码 2
  const csBad = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', join(BENCH, '.tmp-cs-bad'),
    '--migrate-configs', 'no', '--compile-sdk', '25', '--yes', ...aceArgs]);
  check(csBad.status === EXIT.usage && (csBad.stderr || '').includes('支持版本'), '版本: 未收录 25 → 码 2 + 支持清单', csBad.stderr);
  const csMis = run([stageFixture, '--scan-report', stageReport, '--mode', 'modify', '--compile-sdk', '24', '--yes', ...aceArgs]);
  check(csMis.status === EXIT.usage && (csMis.stderr || '').includes('仅适用于 new'), '版本: modify 误用 → 码 2', csMis.stderr);

  // 选 24 归档物化：六元组替换（OpenHarmony 形态数字）+ 断言 + 基线落账
  const cs24Out = join(BENCH, '.tmp-out-cs24');
  rmSync(cs24Out, { recursive: true, force: true });
  const cs24 = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', cs24Out, '--scaffold-from',
    '--migrate-configs', 'no', '--compile-sdk', '24', '--yes', '--ace-bin', '/no/such/ace']);
  check(cs24.status === EXIT.ok, '版本: --compile-sdk 24 物化退出码 0', cs24.stderr);
  check((cs24.stdout || '').includes('Compile SDK 24'), '版本: 完成提示含所选版本');
  const cs24Bp = JSON.parse(readFileSync(join(cs24Out, 'build-profile.json5'), 'utf8'));
  check(cs24Bp.app.products[0].compileSdkVersion === 24 && cs24Bp.app.products[0].compatibleSdkVersion === '5.0.5(17)',
    '版本: OpenHarmony 形态数字 compileSdk=24；源 compatible 5.0.5(17)（apiLevel 17）<=24 保留不抬升（三值关系成立，形态沿用源写法）');
  check(cs24Bp.app.products[0].runtimeOS === 'OpenHarmony', '版本: runtimeOS 恒 OpenHarmony（与版本正交）');
  const cs24Hc = JSON.parse(readFileSync(join(cs24Out, 'hvigor', 'hvigor-config.json5'), 'utf8'));
  check(cs24Hc.modelVersion === '6.1.1' && cs24Hc.dependencies['@ohos/hvigor-ohos-arkui-x-plugin'] === '4.24.2',
    '版本: hvigor-config modelVersion=6.1.1 + 插件 4.24.2（ON 表）');
  const cs24Pkg = JSON.parse(readFileSync(join(cs24Out, 'oh-package.json5'), 'utf8'));
  check(cs24Pkg.modelVersion === '6.1.1', '版本: 根 oh-package modelVersion=6.1.1');
  const cs24Result = readResult(cs24Out);
  check(cs24Result.platform_baseline?.openharmony?.compile_sdk_version === '24'
    && cs24Result.platform_baseline?.openharmony?.model_version === '6.1.1',
    '版本: platform_baseline.openharmony 实测落账', JSON.stringify(cs24Result.platform_baseline?.openharmony));

  // 全形态输入反查（6.1.0(23) → 23）
  const csFullOut = join(BENCH, '.tmp-out-csfull');
  rmSync(csFullOut, { recursive: true, force: true });
  const csFull = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', csFullOut, '--scaffold-from',
    '--migrate-configs', 'no', '--compile-sdk', '6.1.0(23)', '--yes', '--ace-bin', '/no/such/ace']);
  check(csFull.status === EXIT.ok && (csFull.stdout || '').includes('Compile SDK 23'), '版本: 全形态 6.1.0(23) 反查为 23', csFull.stderr);
  const csFullBp = JSON.parse(readFileSync(join(csFullOut, 'build-profile.json5'), 'utf8'));
  check(csFullBp.app.products[0].compileSdkVersion === 23, '版本: 23 数字形态落盘');
}

// ── 8. 覆盖确认三分支（skip=0/overwrite=产出/abort=6） ───────────
{
  const mkNonEmpty = () => {
    const out = join(BENCH, '.tmp-out-nonempty');
    rmSync(out, { recursive: true, force: true });
    mkdirSync(out, { recursive: true });
    writeFileSync(join(out, 'keep.txt'), 'x');
    return out;
  };
  // skip：零变更不产出 + 退出码 0 + stdout 明示
  {
    const out = mkNonEmpty();
    const before = snapshotDir(out);
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out,
      '--confirm-overwrite', 'skip', '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', ...aceArgs]);
    check(runRes.status === EXIT.skip, `skip 分支退出码 ${EXIT.skip}（编排方可继续的良性结束）`, `status=${runRes.status}`);
    check((runRes.stdout || '').includes('已跳过本次骨架生成'), 'skip stdout 明示');
    check(snapshotDir(out) === before, 'skip 目录零变更');
    check(!existsSync(join(out, 'skeleton-result.json')), 'skip 不产出 SkeletonResult');
  }
  // abort：非 0 + 零新增
  {
    const out = mkNonEmpty();
    const before = snapshotDir(out);
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out,
      '--confirm-overwrite', 'abort', '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', ...aceArgs]);
    check(runRes.status === EXIT.user_abort, `abort 分支退出码 ${EXIT.user_abort}`, `status=${runRes.status}`);
    check((runRes.stderr || '').includes('用户中止'), 'abort stderr 用户中止');
    check(snapshotDir(out) === before, 'abort 确认前零新文件');
  }
  // overwrite：确认后正常产出
  {
    const out = mkNonEmpty();
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out,
      '--confirm-overwrite', 'overwrite', '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', ...aceArgs]);
    check(runRes.status === EXIT.ok, 'overwrite 分支确认后正常产出', runRes.stderr);
    check(existsSync(join(out, 'skeleton-result.json')), 'overwrite 产出 SkeletonResult');
  }
  // 非交互缺省 = abort
  {
    const out = mkNonEmpty();
    const before = snapshotDir(out);
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out, '--migrate-configs', 'no', '--compile-sdk', '26.0.0', ...aceArgs]);
    check(runRes.status === EXIT.user_abort, '非 TTY 未提供参数缺省按中止（码 6）', `status=${runRes.status}`);
    check(snapshotDir(out) === before, '缺省中止目录零新增');
  }
}

// ── 9. 计划确认（非 TTY 无 --yes → 6）与模型拒绝（3） ──────────────────
{
  const planWork = freshCopy('.tmp-stage-plan');
  const runRes = run([planWork, '--scan-report', stageReport, '--mode', 'modify', ...aceArgs]);
  check(runRes.status === EXIT.user_abort, '非 TTY modify 无 --yes 按用户中止（码 6）', `status=${runRes.status}`);
  check(!existsSync(join(planWork, '.arkui-x')), '计划确认中止零写');
  rmSync(planWork, { recursive: true, force: true });
}
{
  const before = snapshotDir(faFixture);
  const runRes = run([faFixture, '--scan-report', faReport, '--mode', 'modify', '--yes', ...aceArgs]);
  check(runRes.status === EXIT.model, `FA 拒绝退出码 ${EXIT.model}（模型拒绝）`, `status=${runRes.status}`);
  check((runRes.stderr || '').includes(expected.rejects.fa_message), 'FA 不支持提示', runRes.stderr);
  check(snapshotDir(faFixture) === before, 'FA fixture 目录零变更');
}
{
  const missing = run([stageFixture, '--scan-report', join(BENCH, 'no-such.json'), '--mode', 'modify', '--yes', ...aceArgs]);
  check(missing.status === EXIT.model, `ScanReport 缺失退出码 ${EXIT.model}`, `status=${missing.status}`);
  check((missing.stderr || '').includes(expected.rejects.unknown_message), '引导先运行 F2', missing.stderr);

  const unknownReport = join(BENCH, '.tmp-unknown-report.json');
  writeFileSync(unknownReport, JSON.stringify({ schema_version: 1, project_model: 'unknown' }));
  const unknown = run([stageFixture, '--scan-report', unknownReport, '--mode', 'modify', '--yes', ...aceArgs]);
  check(unknown.status === EXIT.model && (unknown.stderr || '').includes(expected.rejects.unknown_message),
    'project_model=unknown 引导 F2（码 3）');
  check(!existsSync(join(stageFixture, '.arkui-x')), 'unknown 路径零写（stage fixture 原件未触碰）');
}

// ── 10. 参数非法值 → 退出码 2（非交互部分） ──────────────────────
{
  const badPlatform = run([stageFixture, '--scan-report', stageReport, '--mode', 'modify', '--platform', 'windows', '--yes', ...aceArgs]);
  check(badPlatform.status === EXIT.usage && (badPlatform.stderr || '').includes('both/android/ios'),
    '--platform 非法值 → 码 2', badPlatform.stderr);
  const badMode = run([stageFixture, '--scan-report', stageReport, '--mode', 'rebuild', '--yes', ...aceArgs]);
  check(badMode.status === EXIT.usage, '--mode 非法值 → 码 2');
  const badConfirm = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', join(BENCH, '.tmp-x'),
    '--confirm-overwrite', 'force', ...aceArgs]);
  check(badConfirm.status === EXIT.usage && (badConfirm.stderr || '').includes('skip/overwrite/abort'),
    '--confirm-overwrite 非法值 → 码 2', badConfirm.stderr);
  const noMode = run([stageFixture, '--scan-report', stageReport, ...aceArgs]);
  check(noMode.status === EXIT.usage, '非 TTY 缺 --mode → 码 2（design 参数表必填）');
}

// ── 11全参数组合（modify/new 各 1，零交互，预置非空目录触发覆盖确认路径） ──
{
  // modify：--mode + --platform + --confirm-overwrite + --yes 全参数（默认归档路径）
  const comboWork = freshCopy('.tmp-stage-combo');
  const modOut = join(BENCH, '.tmp-out-combo-mod');
  rmSync(modOut, { recursive: true, force: true });
  const modRes = run([comboWork, '--scan-report', stageReport, '--mode', 'modify', '--platform', 'android',
    '--confirm-overwrite', 'overwrite', '--out', modOut, '--yes', ...aceArgs]);
  check(modRes.status === EXIT.ok, 'modify 全参数组合退出码 0（零交互，默认归档）', modRes.stderr);
  const modResult = readResult(modOut);
  check(modResult.mode === 'modify' && modResult.platform === 'android', 'modify 组合结果与交互路径等价（mode/platform）');
  check(modResult.ios_shell === undefined, 'modify+android → ios_shell 不出现');
  check((modRes.stdout || '').includes('已从归档注入跨平台壳'), '归档路径提示在场（mock-ace 未被调用）');
  rmSync(comboWork, { recursive: true, force: true });

  // new：预置非空目录触发覆盖确认路径（--confirm-overwrite overwrite 显式跳过询问）
  const newOut = join(BENCH, '.tmp-out-combo-new');
  rmSync(newOut, { recursive: true, force: true });
  mkdirSync(newOut, { recursive: true });
  writeFileSync(join(newOut, 'keep.txt'), 'x');
  const newRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--platform', 'ios',
    '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--confirm-overwrite', 'overwrite', '--out', newOut, '--yes', ...aceArgs]);
  check(newRes.status === EXIT.ok, 'new 全参数组合退出码 0（非空目录经 overwrite 参数零交互通过）', newRes.stderr);
  const newResult = readResult(newOut);
  check(newResult.mode === 'new' && newResult.platform === 'ios', 'new 组合结果与交互路径等价');
  check(newResult.android_shell === undefined, 'new+ios → android_shell 不出现');
}

// ── 11.5 回退改动清单多模块幂等 ───
{ // 预置 scaffold → 跳过 create 直接迁入（假 ace 佐证未调用 ace）
  const pre = join(BENCH, '.tmp-out-prefab');
  rmSync(pre, { recursive: true, force: true });
  mkdirSync(join(pre, '.arkui-x', 'android'), { recursive: true });
  mkdirSync(join(pre, '.arkui-x', 'ios'), { recursive: true });
  mkdirSync(join(pre, 'entry', 'src', 'main'), { recursive: true });
  const prefabRun = run([stageFixture, '--scan-report', stageReport, '--mode', 'new',
    '--out', pre, '--confirm-overwrite', 'overwrite', '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', '--ace-bin', '/no/such/ace']);
  check(prefabRun.status === EXIT.ok, 'scaffold 在场跳过 create 直接迁入（假 ace 佐证未调用 ace）', prefabRun.stderr);
  check((prefabRun.stdout || '').includes('跳过 ace create'), '跳过提示输出');
  check(existsSync(join(pre, 'entry', 'src', 'main', 'ets', 'Index.ets')), '迁入完成'); // success-rewrite → 改动清单含既有文件改写（--ace-modify 工具路径）
  const rwWork = freshCopy('.tmp-stage-rewrite');
  const rwOut = join(BENCH, '.tmp-out-rewrite');
  rmSync(rwOut, { recursive: true, force: true });
  const rwRun = run([rwWork, '--scan-report', stageReport, '--mode', 'modify', '--out', rwOut, '--yes',
    '--ace-modify', ...aceArgs],
    { MOCK_ACE_BEHAVIOR: 'success-rewrite' });
  check(rwRun.status === EXIT.ok, 'success-rewrite 退出码 0', rwRun.stderr);
  check(/~ hvigorfile\.ts/.test(rwRun.stdout || ''), '改动清单含既有文件改写（~ hvigorfile.ts）');
  check(/\+ \.arkui-x\//.test(rwRun.stdout || ''), '改动清单含新增（+ .arkui-x/…）');
  rmSync(rwWork, { recursive: true, force: true }); // 多模块 fixture → 逐模块迁入
  const mmOut = join(BENCH, '.tmp-out-multimod');
  rmSync(mmOut, { recursive: true, force: true });
  const mmRun = run([join(BENCH, 'fixture-multimodule-project'), '--scan-report', stageReport,
    '--mode', 'new', '--out', mmOut, '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', ...aceArgs]);
  check(mmRun.status === EXIT.ok, '多模块工程 new 退出码 0', mmRun.stderr);
  check(existsSync(join(mmOut, 'entry', 'src', 'main', 'ets', 'EntryIndex.ets')), 'entry 模块迁入');
  check(existsSync(join(mmOut, 'feature', 'src', 'main', 'ets', 'Feature.ets')), 'feature 模块迁入（业务名 entry 布局）'); // 根治：--scaffold-from 归档物化（零 ace 交互，SDK 26.0.0 确定性）
  const archOut = join(BENCH, '.tmp-out-archive');
  rmSync(archOut, { recursive: true, force: true });
  const archRun = run([join(BENCH, 'fixture-multimodule-project'), '--scan-report', stageReport,
    '--mode', 'new', '--out', archOut, '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', '--scaffold-from',
    '--project-name', 'benchapp', '--bundle-name', 'com.bench.app', '--ace-bin', '/no/such/ace']);
  check(archRun.status === EXIT.ok, '归档物化 new 退出码 0（不依赖 ace）', archRun.stderr);
  check(/"compileSdkVersion": "26\.0\.0"/.test(readFileSync(join(archOut, 'build-profile.json5'), 'utf8')),
    '归档物化 compileSdkVersion 确定性 26.0.0');
  check(readFileSync(join(archOut, 'AppScope/app.json5'), 'utf8').includes('"bundleName": "com.bench.app"'),
    '归档物化 bundleName 变量替换');
  check(existsSync(join(archOut, '.arkui-x/android/app/src/main/java/com/bench/app/EntryEntryAbilityActivity.java')),
    'java 包目录按 bundleName 重组');
  check(existsSync(join(archOut, 'feature', 'src', 'main', 'ets', 'Feature.ets')), '归档路径迁入正常');
  rmSync(archOut, { recursive: true, force: true }); // 幂等重跑（modify 后二跑，假 ace 佐证跳过 ace 调用）
  const idemWork = freshCopy('.tmp-stage-idem');
  const o1 = join(BENCH, '.tmp-out-idem1');
  rmSync(o1, { recursive: true, force: true });
  run([idemWork, '--scan-report', stageReport, '--mode', 'modify', '--out', o1, '--yes', ...aceArgs]);
  const o2 = join(BENCH, '.tmp-out-idem2');
  rmSync(o2, { recursive: true, force: true });
  const idemRun = run([idemWork, '--scan-report', stageReport, '--mode', 'modify', '--out', o2, '--yes', '--ace-bin', '/no/such/ace']);
  check(idemRun.status === EXIT.ok, '已 modify 工程幂等重跑（假 ace 佐证跳过 ace 调用）', idemRun.stderr);
  check((idemRun.stdout || '').includes('幂等重跑'), '幂等跳过提示');
  check(existsSync(join(o2, 'skeleton-result.json')), '幂等路径产出 SkeletonResult');
  rmSync(idemWork, { recursive: true, force: true });
}

// ── 12. 3 次一致性（new 全新目录+路径归一化） ─────────────
{
  const runs = [];
  let allOk = true;
  for (let i = 0; i < 3; i++) {
    const out = join(BENCH, `.tmp-out-rerun-${i}`);
    rmSync(out, { recursive: true, force: true });
    const runRes = run([stageFixture, '--scan-report', stageReport, '--mode', 'new', '--out', out, '--migrate-configs', 'no', '--compile-sdk', '26.0.0', '--yes', ...aceArgs]);
    if (runRes.status !== 0) { allOk = false; check(false, `第 ${i + 1} 次运行失败`, runRes.stderr); break; }
    runs.push(normalize(readResult(out), out));
  }
  if (runs.length === 3) {
    check(allOk && JSON.stringify(runs[0]) === JSON.stringify(runs[1]) && JSON.stringify(runs[1]) === JSON.stringify(runs[2]),
      '3 次 SkeletonResult 语义一致（路径前缀归一化）');
  }
}

// ── 13. 离线静态检查 ───────────────────────────────────────────
{
  const NET_RE = /require\(['"](?:net|http|https|dns|tls|fetch)['"]\)|\bfetch\s*\(|import\s+['"]node:(?:net|http|https|dns|tls)['"]/;
  const offenders = [];
  for (const dir of ['scripts', 'benchmark']) {
    walk(join(ROOT, dir)).forEach((f) => {
      if (!f.endsWith('.js') || f.endsWith('.test.js') || f.endsWith('compare.js') || f.endsWith('ace.js')) return;
      if (NET_RE.test(readFileSync(f, 'utf8'))) offenders.push(relative(ROOT, f));
    });
  }
  check(offenders.length === 0, '交付物零网络 API 引用', offenders.join(', '));
}

// ── 13级归档 modify 场景矩阵（模块类型权威映射/占位符/local.properties/hvigor 布局/幂等） ──
{
  // 假 SDK 布局（确定性）：--ace-bin 指向假 ArkUI-X SDK 布局中的 ace 文件；ARKUIX_SDK_DIR=假 OH SDK
  const fakeRoot = join(BENCH, '.tmp-fake-sdks');
  rmSync(fakeRoot, { recursive: true, force: true });
  const fakeX = join(fakeRoot, 'xsdk');
  const fakeOh = join(fakeRoot, 'ohsdk');
  mkdirSync(join(fakeX, '26.0.0', 'arkui-x', 'toolchains', 'bin'), { recursive: true });
  mkdirSync(join(fakeOh, '26.0.0', 'ets'), { recursive: true });
  writeFileSync(join(fakeX, '26.0.0', 'arkui-x', 'toolchains', 'bin', 'ace'), '#!/bin/sh\n');
  const fakeAce = join(fakeX, '26.0.0', 'arkui-x', 'toolchains', 'bin', 'ace');

  const work = join(BENCH, '.tmp-mixed-work');
  rmSync(work, { recursive: true, force: true });
  cpDir(mixedFixture, work);
  const out = join(BENCH, '.tmp-out-mixed');
  rmSync(out, { recursive: true, force: true });
  const runRes = run([work, '--scan-report', stageReport, '--mode', 'modify', '--out', out, '--yes',
    '--ace-bin', fakeAce], { ARKUIX_SDK_DIR: fakeOh });
  check(runRes.status === EXIT.ok, '混合模块工程归档 modify 退出码 0（假 ace 路径佐证零 ace 执行）', runRes.stderr);

  // 13a. hvigorfile 权威映射（对齐 ace modify TASK_TYPE_MAP + 插件真实导出面）
  const hvigorOf = (m) => readFileSync(join(work, m, 'hvigorfile.ts'), 'utf8');
  check(hvigorOf('.').includes("export { AppTasksForArkUIX } from '@ohos/hvigor-ohos-arkui-x-plugin'"),
    'rewire: 根 hvigorfile appTasks→AppTasksForArkUIX');
  check(hvigorOf('entry').includes("export { HapTasks } from '@ohos/hvigor-ohos-arkui-x-plugin'"),
    'rewire: entry hvigorfile hapTasks→HapTasks');
  check(hvigorOf('feature').includes("export { HapTasks } from '@ohos/hvigor-ohos-arkui-x-plugin'"),
    'rewire: feature hvigorfile hapTasks→HapTasks');
  check(hvigorOf('shared').includes("export { HspTasks } from '@ohos/hvigor-ohos-arkui-x-plugin'"),
    'rewire: shared hvigorfile hspTasks→HspTasks');
  check(hvigorOf('har').includes('export { harTasks } from "@ohos/hvigor-ohos-plugin"')
    && !hvigorOf('har').includes('arkui-x-plugin'),
  'har 模块 hvigorfile 原样保留（插件无 HarTasksForArkUIX 导出）');

  // 13b. hvigor-config 插件注入（modelVersion 工程追加；保留既有 ohos-plugin 依赖）
  const hvigorConfig = readFileSync(join(work, 'hvigor', 'hvigor-config.json5'), 'utf8');
  check(hvigorConfig.includes('"@ohos/hvigor-ohos-arkui-x-plugin"') && hvigorConfig.includes('"@ohos/hvigor-ohos-plugin"'),
    'config: hvigor-config 注入 arkui-x 插件且保留 ohos-plugin（har 模块仍需）');
  check(hvigorConfig.includes('"modelVersion"'), 'config: modelVersion 形态保留');

  // 13c. buildArkTS 占位符注入（project_path + arkuiXSdkPath 均替换）
  const buildArk = readFileSync(join(work, '.arkui-x', 'android', 'buildArkTS'), 'utf8');
  check(!buildArk.includes('__PROJECT_PATH__') && !buildArk.includes('__ARKUIX_SDK_PATH__'),
    'buildArkTS 占位符全替换（含 modify 路径 project_path）');
  check(buildArk.includes(`project_path="${work}"`), 'project_path=工程根（模板引号形态）', buildArk.split('\n').find((l) => l.includes('project_path')));
  check(buildArk.includes(join(fakeX, '26.0.0', 'arkui-x')), 'arkuiXSdkPath 从 --ace-bin 路径推导');

  // 13d. local.properties（nodejs.dir/arkui-x.dir/sdk.dir；arkui-x.dir=SDK 根）
  // win32 下值按 ace 转义规则写（\ → \\、: → \:）——期望值同规则镜像，断言跨平台一致
  const localProps = readFileSync(join(work, 'local.properties'), 'utf8');
  check(/^nodejs\.dir=/m.test(localProps) && /^arkui-x\.dir=/m.test(localProps) && /^sdk\.dir=/m.test(localProps),
    'local.properties 三键齐备（hvigor 直跑前置）', localProps);
  check(localProps.includes(`arkui-x.dir=${propertiesEscaped(fakeX)}`), 'arkui-x.dir=SDK 根（licenses 所在层，非版本子目录）', localProps);
  check(localProps.includes(`sdk.dir=${propertiesEscaped(fakeOh)}`), 'sdk.dir 取 ARKUIX_SDK_DIR 的 OH SDK 形态（双语义按形态路由）', localProps);

  // 13e. 归档 hvigor 布局对齐 ace create（API≥12 删 wrapper 三件——旧 wrapper Node24/hvigor6 三重不兼容）
  check(!existsSync(join(work, 'hvigor', 'hvigor-wrapper.js')) && !existsSync(join(work, 'hvigorw')) && !existsSync(join(work, 'hvigorw.bat')),
    '归档注入不含 hvigor-wrapper.js/hvigorw/hvigorw.bat（hvigorw 自举由 ace build IDE sync/DevEco 提供）');

  // 13f. platform 裁剪 + bundleName 替换
  check(existsSync(join(work, '.arkui-x', 'android')) && existsSync(join(work, '.arkui-x', 'ios')),
    'both 平台双壳注入');
  const gradle = readFileSync(join(work, '.arkui-x', 'android', 'app', 'build.gradle'), 'utf8');
  check(gradle.includes('com.example.skeleton'), 'bundleName 从 AppScope/app.json5 传导至 Android 壳', gradle.slice(0, 200));

  // 13g. 幂等重跑（二跑零 hvigorfile 改写、hvigor-config 不重复注入）
  const out2 = join(BENCH, '.tmp-out-mixed2');
  rmSync(out2, { recursive: true, force: true });
  const rerun = run([work, '--scan-report', stageReport, '--mode', 'modify', '--out', out2, '--yes',
    '--ace-bin', fakeAce], { ARKUIX_SDK_DIR: fakeOh });
  check(rerun.status === EXIT.ok, 'idem: 已 modify 工程幂等重跑退出码 0', rerun.stderr);
  check((rerun.stdout || '').includes('幂等重跑'), 'idem: 幂等提示输出');
  const cfg2 = readFileSync(join(work, 'hvigor', 'hvigor-config.json5'), 'utf8');
  check((cfg2.match(/@ohos\/hvigor-ohos-arkui-x-plugin/g) || []).length === 1, 'idem: 插件依赖不重复注入');

  // 13h. ARKUIX_SDK_DIR 双语义防误用（OH SDK 形态不作 ArkUI-X SDK 使用——占位符保留）
  const work2 = join(BENCH, '.tmp-mixed-ohenv');
  rmSync(work2, { recursive: true, force: true });
  cpDir(mixedFixture, work2);
  const out3 = join(BENCH, '.tmp-out-mixed-ohenv');
  rmSync(out3, { recursive: true, force: true });
  const ohEnvRun = run([work2, '--scan-report', stageReport, '--mode', 'modify', '--out', out3, '--yes',
    '--ace-bin', '/no/such/ace'], { ARKUIX_SDK_DIR: fakeOh });
  check(ohEnvRun.status === EXIT.ok, 'OH SDK 形态 ARKUIX_SDK_DIR 不阻断归档 modify', ohEnvRun.stderr);
  const buildArk2 = readFileSync(join(work2, '.arkui-x', 'android', 'buildArkTS'), 'utf8');
  check(buildArk2.includes('__ARKUIX_SDK_PATH__'),
    'OH SDK 路径不误写入 buildArkTS（占位符保留 + envNote 提示）');
  check((ohEnvRun.stdout || '').includes('ArkUI-X SDK 路径未检出'), '占位符保留的 envNote 提示输出');

  rmSync(fakeRoot, { recursive: true, force: true });
  rmSync(work, { recursive: true, force: true });
  rmSync(work2, { recursive: true, force: true });
  rmSync(out, { recursive: true, force: true });
  rmSync(out2, { recursive: true, force: true });
  rmSync(out3, { recursive: true, force: true });
}

// ── 14. fixture 原件零污染（收口） ─────────────────────────────────
{
  check(!existsSync(join(stageFixture, '.arkui-x')) && !existsSync(join(stageFixture, 'local.properties')),
    'stage fixture 原件未触碰（无 .arkui-x / local.properties）');
  check(!existsSync(join(mixedFixture, '.arkui-x')) && !existsSync(join(mixedFixture, 'local.properties')),
    'mixed fixture 原件未触碰');
}


// ── 清理 ───────────────────────────────────────────────────────────────
for (const dir of ['.tmp-stage-work', '.tmp-stage-timeout', '.tmp-stage-envtimeout', '.tmp-stage-envwarn', '.tmp-stage-low', '.tmp-stage-lowarch', '.tmp-stage-combo', '.tmp-stage-acemod',
  '.tmp-out-modify', '.tmp-out-acemod', '.tmp-out-combo-mod', '.tmp-out-combo-new', '.tmp-stage-fail', '.tmp-out-fail', '.tmp-stage-incomplete',
  '.tmp-out-new-both', '.tmp-out-new-android', '.tmp-out-new-ios', '.tmp-out-lownew', '.tmp-out-nonempty',
  '.tmp-out-rerun-0', '.tmp-out-rerun-1', '.tmp-out-rerun-2', '.tmp-out-prefab', '.tmp-out-rewrite', '.tmp-out-multimod', '.tmp-out-idem1', '.tmp-out-idem2', '.tmp-stage-rewrite', '.tmp-stage-idem']) {
  rmSync(join(BENCH, dir), { recursive: true, force: true });
}
for (const platform of ['both', 'android', 'ios']) {
  rmSync(join(BENCH, `.tmp-stage-p-${platform}`), { recursive: true, force: true });
  rmSync(join(BENCH, `.tmp-out-p-${platform}`), { recursive: true, force: true });
}
rmSync(join(BENCH, '.tmp-unknown-report.json'), { force: true });

// 收尾：统一清扫全部临时产物（按 .tmp- 前缀全量匹配，新增场景无需登记清单）
for (const tmp of readdirSync(BENCH).filter((f) => f.startsWith('.tmp-'))) {
  rmSync(join(BENCH, tmp), { recursive: true, force: true });
}

console.log(failures === 0 ? '\n全部验收项 PASS' : `\n${failures} 项 FAIL`);
process.exit(failures === 0 ? 0 : 1);

function normalize(result, outDir) {
  const json = JSON.stringify(result);
  return json.split(outDir).join('<OUT>');
}

function hashOf(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}

/** local.properties 值的期望形态（镜像 scaffold.js writeLocalProperties 的 win32 转义规则） */
function propertiesEscaped(p) {
  // 与 writeLocalProperties 同款转义（仅转义不改写分隔符；POSIX 平台分支零改动）
  return process.platform === 'win32'
    ? String(p).replace(/\\/g, '\\\\').replace(/:/g, '\\:')
    : String(p);
}

function cpDir(from, to) {
  mkdirSync(to, { recursive: true });
  walk(from).forEach((f) => {
    const rel = relative(from, f);
    const dest = join(to, rel);
    mkdirSync(dirname(dest), { recursive: true });
    writeFileSync(dest, readFileSync(f));
  });
}
