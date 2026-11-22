#!/usr/bin/env node
/**
 * F4 全量验收（对应入口，mock-skill 替身，场景+数据驱动，对齐 F1/F2 benchmark 形态）：
 * 全流程深断言（逐字段/⑥分流/报告逐段）+ new 模式 + 阶段子集 + 决策中止（缺预设/非法预设）+
 * 中断续跑（决策保留）+ 损坏重跑 + 回滚 + 超时 + 退出码全集 + 离线白名单 + 3 次一致性。
 */
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, writeFileSync, readFileSync, readdirSync, statSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname, relative } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const node = process.execPath;
const cli = join(root, 'scripts/orchestrate.js');
const MOCK = join(root, 'benchmark/mock-skill');
const FIXTURE = join(root, 'benchmark/fixture-project');
const expected = JSON.parse(readFileSync(join(root, 'benchmark/expected-metrics.json'), 'utf8'));
const ANSWERS = [
  '--answer', 'skeleton_mode=modify',
  '--answer', 'uk:@ohos.nonsense::mysteryApi=equivalent_bridge',
  '--answer', 'uk:@ohos.mockFeature::legacyApi=keep_unknown',
  '--answer', 'bd:@hms.map::map.MapComponent=降级为OH替代',
  '--answer', 'bd:@hms.push::pushService.getToken=裁剪',
  '--answer', 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现',
  '--answer', 'bd:@kit.MockKit::mockKit.doThing=降级为OH替代',
];

let pass = 0, fail = 0;
function check(name, ok, detail = '') {
  if (ok) { pass++; } else { fail++; console.log(`  [FAIL] ${name}${detail ? ' — ' + detail : ''}`); }
}
const run = (args, env = {}) => spawnSync(node, [cli, ...args], { encoding: 'utf8', env: { ...process.env, ...env } });
const stateOf = (out) => JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
const callsOf = (log) => readFileSync(log, 'utf8');

const work = mkdtempSync(join(tmpdir(), 'f4-bench-'));

// ── 全流程──
console.log('== 全流程==');
const out1 = join(work, 'full'), log1 = join(work, 'full.log');
const r1 = run([FIXTURE, '--out', out1, '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_LOG: log1 });
check(' 退出码 0', r1.status === expected.fullFlow.exitCode, r1.stderr);
const order = callsOf(log1).trim().split('\n').map((l) => l.replace(/\(.*/, ''));
check(' 调度序 scan→skeleton→bridge', order.join('→') === expected.fullFlow.callOrder.join('→'), order.join('→'));
const st1 = stateOf(out1);
for (const [stage, exp] of Object.entries(expected.fullFlow.stages)) {
  const s = st1.stages[stage];
  check(` ${stage}.status=${exp.status}`, s.status === exp.status);
  for (const a of exp.artifacts) check(` ${stage}.artifacts 含 ${a}`, s.artifacts.includes(a));
  if (exp.exit_code !== undefined) check(` ${stage}.exit_code=${exp.exit_code}`, s.exit_code === exp.exit_code);
}
check(' current_stage=done', st1.current_stage === expected.fullFlow.currentStage);
check(' interrupted_at 缺席（完成态）', !('interrupted_at' in st1));
check(' checkpoints≥3（scan/skeleton/bridge）', st1.checkpoints.length >= 3);
const key = st1.decisions.find((d) => d.point === expected.fullFlow.keyDecision.point);
check(`关键决策 skeleton_mode=${expected.fullFlow.keyDecision.chosen}`, key?.chosen === expected.fullFlow.keyDecision.chosen);
for (const exp of expected.fullFlow.sixDecisions) {
  const d = st1.decisions.find((x) => x.point === exp.point);
  check(`⑥决策在场：${exp.point}`, !!d);
  if (!d) continue;
  check(`⑥ source=${exp.source}`, d.source === exp.source);
  check(`⑥ chosen=${exp.chosen}`, d.chosen === exp.chosen);
  check(`⑥ 题面含「${exp.questionContains}」`, (d.question ?? '').includes(exp.questionContains));
}
const skeletonResult = JSON.parse(readFileSync(join(out1, 'skeleton-result.json'), 'utf8'));
check(`SKRS 消费：skeleton mode=${expected.fullFlow.skeletonResult.mode}`, skeletonResult.mode === expected.fullFlow.skeletonResult.mode);
check(`SKRS 消费：platform=${expected.fullFlow.skeletonResult.platform}`, skeletonResult.platform === expected.fullFlow.skeletonResult.platform);
const md1 = readFileSync(join(out1, 'migration-report.md'), 'utf8');
for (const h of ['一、已转换项', '二、降级标记', '三、桥接项', '四、未解决项', '五、决策记录']) check(`报告段「${h}」`, md1.includes(h));
for (const s of expected.fullFlow.reportSections.converted) check(`已转换段含「${s}」`, md1.includes(s));
for (const s of expected.fullFlow.reportSections.degraded) check(`降级段含「${s}」`, md1.includes(s));
for (const s of expected.fullFlow.reportSections.bridge) check(`桥接段含「${s}」`, md1.includes(s));
for (const s of expected.fullFlow.reportSections.unresolved) check(`未解决段含「${s}」`, md1.includes(s));
for (const s of expected.fullFlow.reportSections.decisions) check(`决策段含「${s}」`, md1.includes(s));
check(`安全声明「${expected.fullFlow.securityDeclaration}」`, md1.includes(expected.fullFlow.securityDeclaration));
// ：unknown 裁决回写（全流程事实一致）
const sr1 = JSON.parse(readFileSync(join(out1, 'scan-report.json'), 'utf8'));
check(' 裁决移桶：mysteryApi unknown→③+reason 溯源', sr1.adaptation.equivalent_bridge.some((i) => i.module === '@ohos.nonsense' && i.reason.includes('F4 编排人工裁决：unknown→③等价桥接')));
check(' 移桶后不在 unknown', !sr1.adaptation.unknown.some((i) => i.module === '@ohos.nonsense'));
check(' 显式搁置：legacyApi 保持 unknown+标注', sr1.adaptation.unknown.some((i) => i.module === '@ohos.mockFeature' && i.reason.includes('显式搁置')));
check(' decisions 留痕（source=unknown）', st1.decisions.some((d) => d.point === 'uk:@ohos.nonsense::mysteryApi' && d.source === 'unknown' && d.chosen === 'equivalent_bridge'));
check(' 回写后契约仍过校验（resume 前提）', (() => { try { return JSON.parse(readFileSync(join(out1, 'scan-report.json'), 'utf8')).schema_version === 1; } catch { return false; } })());
check(' 缺 uk 预设→码 4（不代答）', run([FIXTURE, '--out', join(work, 'uk-abort'), '--skill-dir', MOCK, '--answer', 'skeleton_mode=modify'], {}).status === 4);

// ── new 模式（决策映射）──
console.log('== new 模式（决策→参数映射）==');
const outN = join(work, 'new'), logN = join(work, 'new.log');
 // new 模式配置迁移强确认门——缺预设 → F1（mock 复刻）退出码 6 → 编排器转码 4 + 专属指引
const ANSWERS_NEW_NO_MC = ANSWERS.map((a) => (a.startsWith('skeleton_mode=') ? 'skeleton_mode=new' : a));
const noMc = run([FIXTURE, '--out', join(work, 'new-nomc'), '--skill-dir', MOCK, ...ANSWERS_NEW_NO_MC]);
check('new 缺 migrate_configs 预设 → 退出码 4（强门转译）', noMc.status === 4, `status=${noMc.status}`);
check('专属指引在场（--answer migrate_configs=yes|no）', (noMc.stderr || '').includes('--answer migrate_configs=yes|no'), noMc.stderr);
 // Compile SDK 版本门：缺 compile_sdk 预设（其余齐）→ 退出码 4 + 专属指引
const noCs = run([FIXTURE, '--out', join(work, 'new-nocs'), '--skill-dir', MOCK,
  ...ANSWERS_NEW_NO_MC, '--answer', 'migrate_configs=no']);
check('compile_sdk: new 缺预设 → 退出码 4（版本门转译）', noCs.status === 4, `status=${noCs.status}`);
check('compile_sdk: 专属指引在场（--answer compile_sdk=<版本>）', (noCs.stderr || '').includes('--answer compile_sdk=<版本>'), noCs.stderr);
check('compile_sdk: mock 支持清单透传（26.0.0）', (noCs.stderr || '').includes('26.0.0'), noCs.stderr);
const ANSWERS_NEW = [...ANSWERS_NEW_NO_MC, '--answer', 'migrate_configs=no', '--answer', 'compile_sdk=26.0.0'];
const rN = run([FIXTURE, '--out', outN, '--skill-dir', MOCK, ...ANSWERS_NEW], { ARKUIX_MOCK_LOG: logN });
check('new 模式退出码 0', rN.status === expected.newMode.exitCode, rN.stderr);
check(`mock 收到 ${expected.newMode.skeletonCall}`, callsOf(logN).includes(expected.newMode.skeletonCall));
check(`skeleton-result mode=${expected.newMode.mode}`, JSON.parse(readFileSync(join(outN, 'skeleton-result.json'), 'utf8')).mode === expected.newMode.mode);

// ── ：--scaffold-from 透传（非 TTY skeleton 免 ace create 交互）──
console.log('== scaffold-from 透传==');
const outS = join(work, 'sf'), logS = join(work, 'sf.log');
const rS = run([FIXTURE, '--out', outS, '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_LOG: logS });
check('默认透传（无值→内置归档）', rS.status === expected.scaffoldPassthrough.exitCode
  && callsOf(logS).includes(`skeleton(modify,${expected.scaffoldPassthrough.defaultBuiltin})`), callsOf(logS));
const outS2 = join(work, 'sf2'), logS2 = join(work, 'sf2.log');
const rS2 = run([FIXTURE, '--out', outS2, '--skill-dir', MOCK, ...ANSWERS, '--scaffold-from', '/custom/archive'], { ARKUIX_MOCK_LOG: logS2 });
check('显式归档目录透传', rS2.status === expected.scaffoldPassthrough.exitCode
  && callsOf(logS2).includes(`skeleton(modify,${expected.scaffoldPassthrough.explicitDir})`), callsOf(logS2));

// ── 阶段子集──
console.log('== 阶段子集==');
const out2 = join(work, 'subset');
const r2 = run([FIXTURE, '--stages', 'scan', '--out', out2, '--skill-dir', MOCK], {});
check('子集退出码 0', r2.status === expected.subset.exitCode);
const st2 = stateOf(out2);
for (const s of expected.subset.skipped) check(`子集 ${s}=skipped`, st2.stages[s].status === 'skipped');
check(`报告标注「${expected.subset.reportMark}」`, readFileSync(join(out2, 'migration-report.md'), 'utf8').includes(expected.subset.reportMark));
check('未决策⑥入未解决段（scan,report：@hms.* 未决策呈现）', run([FIXTURE, '--stages', 'scan,report', '--out', join(work, 'noreport6'), '--skill-dir', MOCK], {}).status === 0
  && readFileSync(join(work, 'noreport6', 'migration-report.md'), 'utf8').includes('（⑥未决策）'));

// ── 决策中止（缺预设/非法预设）──
console.log('== 决策不代答==');
const r4 = run([FIXTURE, '--out', join(work, 'abort'), '--skill-dir', MOCK, '--answer', 'skeleton_mode=modify'], {});
check('缺预设→码 4 且一次列全待答清单（N3）', r4.status === expected.abortNoPreset.exitCode && r4.stderr.includes('需补') && r4.stderr.includes('--answer bd:') && r4.stderr.includes('--answer uk:'));
const r4b = run([FIXTURE, '--out', join(work, 'abort2'), '--skill-dir', MOCK, '--answer', 'bd:@hms.map::map.MapComponent=不存在选项'], {});
check('非法预设→码 4 并入待答清单（N3 收集式）', r4b.status === expected.abortBadPreset.exitCode && r4b.stderr.includes('需补') && r4b.stderr.includes('--answer bd:@hms.map::map.MapComponent='));
check('N2-A 工单段在场（六、源码改写工单）', md1.includes('六、源码改写工单') && md1.includes('调用点切换到 F3 六件套'));
check(' bd 回写标注（裁决后 scan-report）', sr1.adaptation.business_decision.some((i) => i.reason.includes('F4 编排人工裁决：⑥→降级为OH替代')));

// ── 前置缺失/输入无效 ──
check('仅选 bridge 无上游→码 3', run([FIXTURE, '--stages', 'bridge', '--out', join(work, 'miss'), '--skill-dir', MOCK], {}).status === expected.missingPrecondition.exitCode);
check('根目录不存在→码 2', run([join(work, 'no-such'), '--skill-dir', MOCK], {}).status === expected.usage.exitCode);

// ── 中断续跑（决策保留不重询）──
console.log('== 中断与续跑==');
const out5 = join(work, 'resume'), log5 = join(work, 'resume.log');
const r5 = run([FIXTURE, '--out', out5, '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_LOG: log5, ARKUIX_MOCK_BRIDGE: 'fail' });
check('bridge 失败→码 5+interrupted_at', r5.status === expected.skillFailure.exitCode && stateOf(out5).interrupted_at.startsWith(expected.skillFailure.interruptedPrefix));
check('中断态 stages.bridge=failed', stateOf(out5).stages.bridge.status === 'failed');
const scanBefore = (callsOf(log5).match(/scan/g) ?? []).length;
const decisionsAtAbort = stateOf(out5).decisions.filter((d) => d.chosen).length;
const r5b = run([FIXTURE, '--out', out5, '--skill-dir', MOCK, '--answer', 'skeleton_mode=modify'], { ARKUIX_MOCK_LOG: log5 });
check('续跑成功（仅 skeleton_mode 预设，⑥决策已保留免重询）', r5b.status === 0, r5b.stderr);
check('续跑 scan 不重跑', (callsOf(log5).match(/scan/g) ?? []).length === scanBefore);
check('续跑后已确认决策保留', stateOf(out5).decisions.filter((d) => d.chosen).length >= decisionsAtAbort);

// ── 损坏产物──
console.log('== 损坏产物==');
const out6 = join(work, 'corrupt'), log6 = join(work, 'corrupt.log');
run([FIXTURE, '--out', out6, '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_LOG: log6 });
writeFileSync(join(out6, 'scan-report.json'), '{"broken":true}', 'utf8');
const before6 = (callsOf(log6).match(/scan/g) ?? []).length;
const r6 = run([FIXTURE, '--stages', 'scan,bridge', '--out', out6, '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_LOG: log6 });
check('损坏检出→scan 重跑→成功', r6.status === 0 && (callsOf(log6).match(/scan/g) ?? []).length > before6 && r6.stdout.includes('产物不完整'));

// ── 回滚──
console.log('== 回滚==');
const out7 = join(work, 'rollback'), log7 = join(work, 'rollback.log');
run([FIXTURE, '--out', out7, '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_LOG: log7 });
const r7 = run([FIXTURE, '--out', out7, '--skill-dir', MOCK, ...ANSWERS, '--rollback', 'scan'], { ARKUIX_MOCK_LOG: log7 });
check('回滚后续跑全 done', r7.status === expected.rollbackScan.exitCode && ['scan', 'skeleton', 'bridge', 'report'].every((s) => stateOf(out7).stages[s].status === 'done'));
check(`skeleton 从回滚目标重产出（≥${expected.rollbackScan.skeletonReruns}）`, (callsOf(log7).match(/skeleton/g) ?? []).length >= expected.rollbackScan.skeletonReruns);
check(`回滚目标 scan 本身重跑（${expected.rollbackScan.scanReruns} 次）`, (callsOf(log7).match(/scan/g) ?? []).length >= expected.rollbackScan.scanReruns, `实际 ${(callsOf(log7).match(/scan/g) ?? []).length}（旧行为不重跑）`);
check('回滚无 checkpoint→码 4', run([FIXTURE, '--out', join(work, 'rb-none'), '--skill-dir', MOCK, '--rollback', 'scan'], {}).status === expected.rollbackNone.exitCode);

// ── 子 Skill 超时──
check('子 Skill 超时→码 5+超时标注', run([FIXTURE, '--out', join(work, 'timeout'), '--skill-dir', MOCK, ...ANSWERS], { ARKUIX_MOCK_SCAN: 'timeout', ARKUIX_SKILL_TIMEOUT_MS: '800' }).stderr.includes('超时'));

// ── 离线白名单──
console.log('== 离线白名单==');
const netRe = /require\(['"]http['"]\)|from\s+['"]node:http['"]|from\s+['"]node:https['"]|from\s+['"]node:net['"]|fetch\(/g;
let netHits = [];
for (const dir of ['scripts', 'rules', 'templates']) {
  (function walk(d) {
    for (const e of readdirSync(d)) {
      const f = join(d, e);
      if (statSync(f).isDirectory()) walk(f);
      else if (/\.(js|json|tpl)$/.test(e)) netHits.push(...(readFileSync(f, 'utf8').match(netRe) ?? []).map((h) => `${relative(root, f)}: ${h}`));
    }
  })(join(root, dir));
}
check('零网络 API 引用', netHits.length === expected.offline.netHits, netHits.join('; '));

// ── 3 次一致性──
console.log('== 3 次一致性==');
const snap = (i) => {
  const o = join(work, `det-${i}`);
  run([FIXTURE, '--out', o, '--skill-dir', MOCK, ...ANSWERS], {});
  const state = stateOf(o);
  delete state.checkpoints; // 快照 at 为非语义字段，排除（声明）
  return JSON.stringify(state) + '::' + readFileSync(join(o, 'migration-report.md'), 'utf8');
};
const s1 = snap(1);
check('3 次 MigrationState+报告一致', s1 === snap(2) && s1 === snap(3));

console.log(`\n结果: ${pass} PASS / ${fail} FAIL`);
rmSync(work, { recursive: true, force: true });
process.exit(fail === 0 ? 0 : 1);
