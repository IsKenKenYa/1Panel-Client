#!/usr/bin/env node
/**
 * F3 全量验收（对应入口，数据驱动 expected-metrics，对齐 F2 benchmark 形态）：
 * 主链逐接口逐件断言（五件内容/围栏/注解/聚合/契约）+ 空清单/格式异常/输入无效 +
 * 增量手改保留 + 源工程只读 + 离线白名单 + 3 次一致性。
 */
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, mkdirSync, writeFileSync, readFileSync, readdirSync, statSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, relative, sep } from 'node:path';
import { fileURLToPath } from 'node:url';
import { createHash } from 'node:crypto';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const expected = JSON.parse(readFileSync(join(root, 'benchmark/expected-metrics.json'), 'utf8'));
const node = process.execPath;
const cli = join(root, 'scripts/bridge.js');
const srcRoot = join(root, 'benchmark/fixture-source-project');
const reportPath = join(root, 'benchmark/fixture-scan-report/report.json');

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; } else { fail++; console.log(`  [FAIL] ${name}${detail ? ' — ' + detail : ''}`); }
}
const run = (args, cwd) => spawnSync(node, [cli, ...args], { encoding: 'utf8', cwd });
function tree(dir, base = dir) {
  const out = [];
  for (const e of readdirSync(dir)) {
    const f = join(dir, e);
    if (statSync(f).isDirectory()) out.push(...tree(f, base));
    else out.push(relative(base, f).split(sep).join('/')); // 归一 '/'（win32 relative 产生 '\\'，产物清单跨平台稳定）
  }
  return out.sort();
}
const text = (out, rel) => readFileSync(join(out, rel), 'utf8');

const work = mkdtempSync(join(tmpdir(), 'f3-bench-'));
const out1 = join(work, 'main');
const srcFile = join(srcRoot, 'entry/src/main/ets/pages/Index.ets');
const srcBefore = createHash('sha256').update(readFileSync(srcFile)).digest('hex');
const r1 = run([srcRoot, '--scan-report', reportPath, '--out', out1], work);
check(` 主链退出码 0`, r1.status === expected.main.exitCode, r1.stderr);

const bars = JSON.parse(text(out1, 'bridge-artifact.json'));
check(` artifacts=${expected.main.artifactCount}`, bars.artifacts.length === expected.main.artifactCount, `got ${bars.artifacts.length}`);
check(` unmapped_native_apis 精确一致`, JSON.stringify(bars.unmapped_native_apis) === JSON.stringify(expected.main.unmapped_native_apis));
check(` schema_version=1`, bars.schema_version === 1);
check(` 产物自检在场（checked=artifact 数）`, bars.audit && bars.audit.checked === expected.main.artifactCount
  && Array.isArray(bars.audit.deficient) && Array.isArray(bars.audit.suggestions), JSON.stringify(bars.audit).slice(0, 200));
check(` fixture 硬残缺=0（建议级可>0）`, bars.audit.deficient_count === 0, JSON.stringify(bars.audit.deficient));
check(` artifact 含 symbol 字段`, bars.artifacts.every((a) => typeof a.symbol === 'string' && a.symbol.length > 0));

const files = tree(out1);
for (const [name, exp] of Object.entries(expected.main.items)) {
  const art = bars.artifacts.find((a) => a.name === name);
  check(`${name} 在 BridgeArtifact 在场`, !!art);
  if (!art) continue;
  check(`${name} category=${exp.category}`, art.category === exp.category);
  check(`${name} local_status=${exp.local_status}`, art.local_status === exp.local_status);
  check(`${name} files 五件路径齐备`, ['interface', 'local', 'arkui_x', 'android', 'ios'].every((k) => typeof art.files[k] === 'string' && art.files[k].length > 0));
  for (const k of ['interface', 'local', 'arkui_x', 'android', 'ios']) {
    check(`${name} ${k} 件文件落盘`, files.includes(art.files[k].split('\\').join('/')));
  }
  const iosMRel = art.files.ios.replace(/\.h$/, '.m');
  check(`${name} ⑤.m 件文件落盘`, files.includes(iosMRel));
  const iText = text(out1, art.files.interface), lText = text(out1, art.files.local), aText = text(out1, art.files.arkui_x),
    dText = text(out1, art.files.android), hText = text(out1, art.files.ios), mText = text(out1, iosMRel);
  for (const s of exp.interface_contains ?? []) check(`${name} ①Interface 含「${s}」`, iText.includes(s));
  for (const s of exp.local_contains ?? []) check(`${name} ②Local 含「${s}」（迁移非空壳）`, lText.includes(s));
  for (const s of exp.arkux_contains ?? []) check(`${name} ③ArkUIX 含「${s}」`, aText.includes(s));
  for (const s of exp.android_contains ?? []) check(`${name} ④Android 含「${s}」`, dText.includes(s));
  for (const s of exp.iosh_contains ?? []) check(`${name} ⑤.h 含「${s}」`, hText.includes(s));
  for (const s of exp.iosm_contains ?? []) check(`${name} ⑤.m 含「${s}」`, mText.includes(s));
  if (exp.android_fence_pairs !== undefined) {
    const begins = (dText.match(/ARKUIX-BRIDGE-HANDOFF BEGIN/g) ?? []).length;
    const ends = (dText.match(/ARKUIX-BRIDGE-HANDOFF END/g) ?? []).length;
    check(`${name} ④围栏成对×${exp.android_fence_pairs}`, begins === exp.android_fence_pairs && ends === exp.android_fence_pairs, `begin=${begins} end=${ends}`);
  }
  check(`${name} ⑤.m 围栏成对`, (mText.match(/#pragma mark ARKUIX-BRIDGE-HANDOFF/g) ?? []).length === 2);
  if (exp.todo_annotation) {
    const t = exp.todo_annotation;
    const ann = `TODO(ARKUIX-BRIDGE): interface=${t.interface} platform=${t.platform} category=${t.category}`;
    const target = t.platform === 'android' ? dText : mText;
    check(`${name} 待补注解三要素（${t.platform}）`, target.includes(ann));
  }
  if (exp.unmapped) check(`${name} 列入 unmapped_native_apis`, bars.unmapped_native_apis.some((u) => u.startsWith(art.module)));
}

// 聚合：同接口两处引用仅一套五件套（边界）
const ifaceCount = files.filter((f) => f.endsWith('DeviceInfoUdidInterface.ets')).length;
check(`聚合：udid 双位置→单套①（count=${expected.main.aggregation.DeviceInfoUdid_files_interface_count}）`, ifaceCount === expected.main.aggregation.DeviceInfoUdid_files_interface_count);
check(`真相源：非③④符号不产契约（geo.getCurrentLocation）`, !files.some((f) => f.includes('Geolocation')));

// 源工程只读
check(`源工程只读（指纹一致）`, createHash('sha256').update(readFileSync(srcFile)).digest('hex') === srcBefore);
check(`报告 bridge-report.md 在场`, files.includes('bridge-report.md'));
const md = text(out1, 'bridge-report.md');
check(`报告含五件套清单段`, md.includes('五件套清单'));
check(`报告含 unmapped 待确认段`, md.includes('@ohos.nonsense::mysteryApi'));

// 空清单/格式异常/输入无效
const out2 = join(work, 'empty');
const r2 = run([srcRoot, '--scan-report', join(root, 'benchmark/fixture-scan-report/report-empty.json'), '--out', out2], work);
check(` 空清单：码 0+提示+空 artifacts`, r2.status === 0 && r2.stdout.includes(expected.empty.stdoutContains) && JSON.parse(text(out2, 'bridge-artifact.json')).artifacts.length === 0);
check(` 输出目录零五件套`, !tree(out2).some((f) => f.includes('commons/') || f.includes('.arkui-x/')));
const out3 = join(work, 'broken');
const r3 = run([srcRoot, '--scan-report', join(root, 'benchmark/fixture-scan-report/report-broken.json'), '--out', out3], work);
check(` 格式异常：码 3+提示+空产物`, r3.status === 3 && r3.stderr.includes(expected.broken.stderrContains) && JSON.parse(text(out3, 'bridge-artifact.json')).artifacts.length === 0);
check(` 输入无效：码 2`, run([join(work, 'no-such'), '--scan-report', reportPath], work).status === 2);

// 增量
const out5 = join(work, 'incr');
run([srcRoot, '--scan-report', reportPath, '--out', out5], work);
const javaPath = join(out5, '.arkui-x/android/app/src/main/java/com/arkuix/bridge/BridgeBatteryInfoBatterySOC.java');
const localPath = join(out5, 'commons/batteryInfo/utils/BatteryInfoBatterySOCLocal.ets');
const j0 = readFileSync(javaPath, 'utf8');
const b = j0.indexOf('// ARKUIX-BRIDGE-HANDOFF BEGIN'), e = j0.indexOf('// ARKUIX-BRIDGE-HANDOFF END');
writeFileSync(javaPath, j0.slice(0, b) + j0.slice(b, e).replace('// 等价原生 API：', '// 开发者手改：真机调通\n        // 等价原生 API：') + j0.slice(e), 'utf8');
writeFileSync(localPath, '// 开发者已调整 Local 实现\n', 'utf8');
run([srcRoot, '--scan-report', reportPath, '--out', out5], work);
const j1 = readFileSync(javaPath, 'utf8');
check(` ④围栏内手改保留`, j1.includes(expected.incremental.handoffKept));
check(` ④围栏结构成对`, j1.includes('ARKUIX-BRIDGE-HANDOFF BEGIN') && j1.includes('ARKUIX-BRIDGE-HANDOFF END'));
check(` ②Local 手改保留`, readFileSync(localPath, 'utf8').trim() === expected.incremental.localKept);
// 未手改件幂等更新（VibratorStart 无手改→骨架区与首生成一致）
check(` 未手改件幂等（①接口内容稳定）`, text(out5, 'commons/batteryInfo/interface/BatteryInfoBatterySOCInterface.ets') === text(out1, 'commons/batteryInfo/interface/BatteryInfoBatterySOCInterface.ets'));

// 离线白名单
const netRe = /require\(['"]http['"]\)|from\s+['"]node:http['"]|from\s+['"]node:https['"]|from\s+['"]node:net['"]|fetch\(/g;
let netHits = [];
(function walk(d) {
  for (const e of readdirSync(d)) {
    if (e === 'node_modules' || e.startsWith('.git') || e.startsWith('.tmp')) continue;
    const f = join(d, e);
    if (statSync(f).isDirectory()) walk(f);
    else if (/\.(js|ets|json|tpl)$/.test(e)) netHits.push(...(readFileSync(f, 'utf8').match(netRe) ?? []).map((h) => `${relative(root, f)}: ${h}`));
  }
})(join(root, 'scripts'));
check(` 离线白名单 0 命中`, netHits.length === expected.offline.netHits, netHits.join('; '));

// 3 次一致性
const snap = (i) => {
  const o = join(work, `det-${i}`);
  run([srcRoot, '--scan-report', reportPath, '--out', o], work);
  return tree(o).map((p) => `${p}::${createHash('sha256').update(readFileSync(join(o, p))).digest('hex')}`).join('|');
};
const s1 = snap(1);
check(` 3 次产物语义一致`, s1 === snap(2) && s1 === snap(3));

console.log(`\n结果: ${pass} PASS / ${fail} FAIL`);
rmSync(work, { recursive: true, force: true });
process.exit(fail === 0 ? 0 : 1);
