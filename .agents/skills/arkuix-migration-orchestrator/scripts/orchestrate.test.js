import { test } from 'node:test';
import assert from 'node:assert/strict';
import { spawnSync } from 'node:child_process';
import { mkdtempSync, rmSync, readFileSync, writeFileSync, existsSync, cpSync, mkdirSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const MOCK_DIR = join(root, 'benchmark', 'mock-skill');
const FIXTURE = join(root, 'benchmark', 'fixture-project');
const node = process.execPath;

function run(args, env = {}, cwd) {
  return spawnSync(node, [join(root, 'scripts/orchestrate.js'), ...args], {
    encoding: 'utf8', cwd,
    env: { ...process.env, ...env },
  });
}
const answers = [
  '--answer', 'skeleton_mode=modify',
  '--answer', 'uk:@ohos.nonsense::mysteryApi=equivalent_bridge',
  '--answer', 'uk:@ohos.mockFeature::legacyApi=keep_unknown',
  '--answer', 'bd:@hms.map::map.MapComponent=降级为OH替代',
  '--answer', 'bd:@hms.push::pushService.getToken=裁剪',
  '--answer', 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现',
  '--answer', 'bd:@kit.MockKit::mockKit.doThing=降级为OH替代',
];

test('全流程：四阶段按序调度+契约传递+落账，退出码 0', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const calls = readFileSync(log, 'utf8').trim().split('\n');
  assert.deepEqual(calls.map((c) => c.replace(/\(.*/, '')), ['scan', 'skeleton', 'bridge']);
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  for (const s of ['scan', 'skeleton', 'bridge', 'report']) assert.equal(st.stages[s].status, 'done');
  assert.equal(st.current_stage, 'done');
  // ：unknown 裁决回写 ScanReport（全流程事实一致）
  const sr = JSON.parse(readFileSync(join(out, 'scan-report.json'), 'utf8'));
  const moved = sr.adaptation.equivalent_bridge.find((i) => i.module === '@ohos.nonsense');
  assert.ok(moved && moved.reason.includes('F4 编排人工裁决：unknown→③等价桥接'), 'mysteryApi 移③+溯源');
  assert.ok(!sr.adaptation.unknown.some((i) => i.module === '@ohos.nonsense'), 'mysteryApi 不再在 unknown');
  const keptItem = sr.adaptation.unknown.find((i) => i.module === '@ohos.mockFeature');
  assert.ok(keptItem && keptItem.reason.includes('显式搁置'), 'legacyApi 显式搁置标注');
  rmSync(dir, { recursive: true, force: true });
});

test('unknown 裁决缺预设→用户中止退出码 4（不代答）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--answer', 'skeleton_mode=modify',
    '--answer', 'bd:@hms.map::map.MapComponent=降级为OH替代', '--answer', 'bd:@hms.push::pushService.getToken=裁剪',
    '--answer', 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现',
    '--answer', 'bd:@kit.MockKit::mockKit.doThing=降级为OH替代'], {});
  assert.equal(r.status, 4);
  assert.ok(r.stderr.includes('uk:'));
  rmSync(dir, { recursive: true, force: true });
});

test('⑥降级为平台原生桥接→移桶④并触达 bridge 阶段（e2e）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const bridgeAnswers = answers.map((a) => a.replace('bd:@kit.MockKit::mockKit.doThing=降级为OH替代', 'bd:@kit.MockKit::mockKit.doThing=降级为平台原生桥接'));
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...bridgeAnswers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const sr = JSON.parse(readFileSync(join(out, 'scan-report.json'), 'utf8'));
  assert.ok(!sr.adaptation.business_decision.some((i) => i.module === '@kit.MockKit'), 'MockKit 不再在⑥桶');
  const moved = sr.adaptation.degraded_bridge.find((i) => i.module === '@kit.MockKit');
  assert.ok(moved && moved.reason.includes('⑥→④降级桥接'), 'MockKit 移④+溯源');
  const calls = readFileSync(log, 'utf8').trim().split('\n');
  assert.ok(calls.includes('bridge'), 'bridge 阶段被调度（消费④桶）');
  rmSync(dir, { recursive: true, force: true });
});

test('--answer 内联形态 --answer=<ID>=<值> 与 flag 形态等价（含 @ ID 与中文值）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR,
    '--answer=skeleton_mode=modify',                              // 内联（ASCII 值）
    '--answer=uk:@ohos.nonsense::mysteryApi=equivalent_bridge',   // 内联（含 @ ID）
    '--answer', 'uk:@ohos.mockFeature::legacyApi=keep_unknown',   // flag 形态（对照）
    '--answer=bd:@hms.map::map.MapComponent=降级为OH替代',        // 内联（含中文值）
    '--answer', 'bd:@hms.push::pushService.getToken=裁剪',
    '--answer=bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现',
    '--answer=bd:@kit.MockKit::mockKit.doThing=降级为平台原生桥接'], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  const chosenOf = (p) => st.decisions.find((d) => d.point === p)?.chosen;
  assert.equal(chosenOf('skeleton_mode'), 'modify', '内联 ASCII 值落账');
  assert.equal(chosenOf('uk:@ohos.nonsense::mysteryApi'), 'equivalent_bridge', '内联 @ ID 落账');
  assert.equal(chosenOf('bd:@hms.map::map.MapComponent'), '降级为OH替代', '内联中文值落账');
  assert.equal(chosenOf('bd:@kit.MockKit::mockKit.doThing'), '降级为平台原生桥接', '内联桥接选择落账');
  const sr = JSON.parse(readFileSync(join(out, 'scan-report.json'), 'utf8'));
  assert.ok(sr.adaptation.degraded_bridge.some((i) => i.module === '@kit.MockKit'), '内联桥接选择同样移桶④（与  联动）');
  assert.ok(!r.stdout.includes('预设未消费'), '无未消费预设告警（内联 key 均被识别）');
  rmSync(dir, { recursive: true, force: true });
});

test('多模块 entry 三级来源——自动推导落账 / --answer 预设覆盖 / --modify-entry 显式覆盖', () => {
  // 多模块工程根（无 entry 命名模块 → 自动推导取首个模块 phone）
  const proj = mkdtempSync(join(tmpdir(), 'f4-proj-'));
  writeFileSync(join(proj, 'build-profile.json5'), JSON.stringify({ modules: [{ name: 'phone' }, { name: 'watch' }] }, null, 2) + '\n');
  // 1) 自动推导：透传 F1 + ASCII 行 + MigrationState 落账（source=derived）
  const dir1 = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const log1 = join(dir1, 'calls.log');
  const r1 = run([proj, '--out', join(dir1, 'out'), '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log1 });
  assert.equal;
  assert.ok(readFileSync(log1, 'utf8').includes('modify-entry=phone'), '推导 entry 透传 F1');
  assert.ok(r1.stdout.includes('[modify-entry] entry=phone source=derived'), 'ASCII 调试行（乱码免疫）');
  const d1 = JSON.parse(readFileSync(join(dir1, 'out', 'migration-state.json'), 'utf8'))
    .decisions.find((d) => d.point === 'modify_entry');
  assert.ok(d1 && d1.chosen === 'phone' && d1.source === 'derived', '推导值落账 MigrationState（agent 结构化可读）');
  // 2）预设覆盖：--answer modify_entry=watch → source=preset
  const dir2 = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const log2 = join(dir2, 'calls.log');
  const r2 = run([proj, '--out', join(dir2, 'out'), '--skill-dir', MOCK_DIR, ...answers,
    '--answer', 'modify_entry=watch'], { ARKUIX_MOCK_LOG: log2 });
  assert.equal;
  assert.ok(readFileSync(log2, 'utf8').includes('modify-entry=watch'), '预设 entry 透传 F1');
  assert.ok(r2.stdout.includes('[modify-entry] entry=watch source=preset'), '预设来源标注');
  const d2 = JSON.parse(readFileSync(join(dir2, 'out', 'migration-state.json'), 'utf8'))
    .decisions.find((d) => d.point === 'modify_entry');
  assert.ok(d2 && d2.chosen === 'watch' && d2.source === 'preset', '预设值落账');
  // 3）显式覆盖：--modify-entry watch > 预设 → source=explicit
  const dir3 = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const log3 = join(dir3, 'calls.log');
  const r3 = run([proj, '--out', join(dir3, 'out'), '--skill-dir', MOCK_DIR, ...answers,
    '--answer', 'modify_entry=phone', '--modify-entry', 'watch'], { ARKUIX_MOCK_LOG: log3 });
  assert.equal;
  assert.ok(readFileSync(log3, 'utf8').includes('modify-entry=watch'), '显式 flag 优先于预设');
  assert.ok(r3.stdout.includes('[modify-entry] entry=watch source=explicit'), '显式来源标注');
  rmSync(proj, { recursive: true, force: true });
  rmSync(dir1, { recursive: true, force: true });
  rmSync(dir2, { recursive: true, force: true });
  rmSync(dir3, { recursive: true, force: true });
});

test('⑥分流：两类⑥预设决策落账', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  const hms = st.decisions.find((d) => d.point === 'bd:@hms.map::map.MapComponent');
  const ohos = st.decisions.find((d) => d.point === 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList');
  assert.equal(hms.source, 'hms-closed');
  assert.equal(hms.chosen, '降级为OH替代');
  assert.equal(ohos.source, 'ohos-unique');
  assert.equal(ohos.chosen, '重新设计实现');
  const kit = st.decisions.find((d) => d.point === 'bd:@kit.MockKit::mockKit.doThing');
  assert.equal(kit.source, 'kit-closed');
  assert.equal(kit.chosen, '降级为OH替代');
  rmSync(dir, { recursive: true, force: true });
});

test('skeleton 透传 --scaffold-from（默认内置归档；显式目录透传）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const calls = readFileSync(log, 'utf8');
  assert.ok(calls.includes('scaffold-from=builtin'), '默认无值→F1 内置归档');
  const out2 = join(dir, 'out2');
  const log2 = join(dir, 'calls2.log');
  const r2 = run([FIXTURE, '--out', out2, '--skill-dir', MOCK_DIR, ...answers, '--scaffold-from', '/custom/archive'], { ARKUIX_MOCK_LOG: log2 });
  assert.equal;
  assert.ok(readFileSync(log2, 'utf8').includes('scaffold-from=/custom/archive'), '显式目录原样透传');
  const out3 = join(dir, 'out3');
  const log3 = join(dir, 'calls3.log');
  const r3 = run([FIXTURE, '--out', out3, '--skill-dir', MOCK_DIR, ...answers, '--strict-crossplatform'], { ARKUIX_MOCK_LOG: log3 });
  assert.equal;
  const c3 = readFileSync(log3, 'utf8');
  assert.ok(c3.includes('strict-crossplatform'), ' 严格模式透传');
  assert.ok(!readFileSync(join(out3, 'migration-state.json'), 'utf8').includes('strict'), '决策账不含该开关（非决策项）');
  rmSync(dir, { recursive: true, force: true });
});

test('决策缺预设→用户中止退出码 4，且一次列全待答清单', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--answer', 'skeleton_mode=modify'], {});
  assert.equal(r.status, 4);
  // N3：非首个缺预设即中止，而是收集全部待答后统一呈报（本 fixture：3×bd + 1×bd-kit + 2×uk）
  assert.ok(r.stderr.includes('需补 6 项决策预设'), r.stderr.slice(0, 300));
  assert.ok(r.stderr.includes('--answer bd:@hms.map::map.MapComponent=<降级为OH替代|降级为平台原生桥接|自行实现|裁剪>'));
  assert.ok(r.stderr.includes('--answer uk:@ohos.mockFeature::legacyApi=<equivalent_bridge|degraded_bridge|platform_trim|keep_unknown>'));
  rmSync(dir, { recursive: true, force: true });
});

test('N3-b：子集轮 skipped 不永久锁死——后续全流程轮解锁续跑', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const r1 = run([FIXTURE, '--stages', 'scan', '--out', out, '--skill-dir', MOCK_DIR], {});
  assert.equal;
  const st1 = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  assert.equal(st1.stages.bridge.status, 'skipped');
  const r2 = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], {});
  assert.equal;
  const st2 = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  assert.equal(st2.stages.bridge.status, 'done'); // 曾 skipped 的阶段被解锁并完成
  assert.ok(r2.stdout.includes('已解锁'));
  rmSync(dir, { recursive: true, force: true });
});

test('阶段子集：仅 scan→其余 skipped+报告"未执行"', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const r = run([FIXTURE, '--stages', 'scan', '--out', out, '--skill-dir', MOCK_DIR], {});
  assert.equal(r.status, 0, r.stderr);
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  assert.equal(st.stages.scan.status, 'done');
  for (const s of ['skeleton', 'bridge', 'report']) assert.equal(st.stages[s].status, 'skipped');
  const md = readFileSync(join(out, 'migration-report.md'), 'utf8');
  assert.ok(md.includes('未执行'));
  rmSync(dir, { recursive: true, force: true });
});

test('仅选 bridge 无上游产物→退出码 3（场景 5）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const r = run([FIXTURE, '--stages', 'bridge', '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR], {});
  assert.equal(r.status, 3);
  rmSync(dir, { recursive: true, force: true });
});

test('子 Skill 失败→interrupted_at+退出码 5；续跑不重跑 scan', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const r1 = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log, ARKUIX_MOCK_BRIDGE: 'fail' });
  assert.equal;
  const st1 = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  assert.ok(st1.interrupted_at.startsWith('bridge:'));
  // 续跑（去 fail 开关）：scan/skeleton 不重跑（calls.log 无新增 scan）
  const before = readFileSync(log, 'utf8');
  const r2 = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  assert.equal;
  const after = readFileSync(log, 'utf8');
  assert.equal(after.match(/scan/g).length, before.match(/scan/g).length);
  assert.ok(after.includes('bridge')); // 断点阶段重跑
  rmSync(dir, { recursive: true, force: true });
});

test('损坏 scan 产物续跑→检出并从 scan 重跑', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log }); // 全量完成
  writeFileSync(join(out, 'scan-report.json'), '{"broken": true}', 'utf8'); // 人为损坏
  const before = readFileSync(log, 'utf8');
  const r = run([FIXTURE, '--stages', 'scan,bridge', '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const after = readFileSync(log, 'utf8');
  assert.ok(after.match(/scan/g).length > before.match(/scan/g).length); // scan 被重跑
  assert.ok(r.stdout.includes('产物不完整'));
  rmSync(dir, { recursive: true, force: true });
});

test('回滚：--rollback scan→skeleton 产物保留但 stages 重置，续跑重产出', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers, '--rollback', 'scan'], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  for (const s of ['scan', 'skeleton', 'bridge', 'report']) assert.equal(st.stages[s].status, 'done');
  const calls = readFileSync(log, 'utf8').match(/skeleton/g).length;
  assert.ok(calls >= 2); // skeleton 从回滚目标阶段重产出
  rmSync(dir, { recursive: true, force: true });
});

test('回滚目标无 checkpoint→退出码 4', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--rollback', 'scan'], {});
  assert.equal(r.status, 4);
  rmSync(dir, { recursive: true, force: true });
});

test('输入无效：根目录不存在→退出码 2', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const r = run([join(dir, 'no-such'), '--skill-dir', MOCK_DIR], {});
  assert.equal(r.status, 2);
  rmSync(dir, { recursive: true, force: true });
});

test('bridge_codegen 决策：bridge 产出后非 TTY 默认 skip 不阻断；--answer proceed 输出指引', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  // 非 TTY 缺预设 → 默认 skip（可选决策），exit 0
  const r1 = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_MOCK_LOG: log });
  assert.equal;
  const st1 = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  const d1 = st1.decisions.find((d) => d.point === 'bridge_codegen');
  assert.ok(d1, 'bridge_codegen 决策落账');
  assert.equal(d1.chosen, 'skip', '非 TTY 缺预设默认 skip');
  assert.ok(!r1.stdout.includes('平台代码生成指引'), 'skip 不输出指引');
  // --answer bridge_codegen=proceed → 输出指引
  const out2 = join(dir, 'out2');
  const r2 = run([FIXTURE, '--out', out2, '--skill-dir', MOCK_DIR, ...answers, '--answer', 'bridge_codegen=proceed'], {});
  assert.equal;
  assert.ok(r2.stdout.includes('平台代码生成指引'), 'proceed 输出指引');
  assert.ok(r2.stdout.includes('adaptation-guide'), '指引含 F3 文档引用');
  const st2 = JSON.parse(readFileSync(join(out2, 'migration-state.json'), 'utf8'));
  assert.equal(st2.decisions.find((d) => d.point === 'bridge_codegen')?.chosen, 'proceed');
  rmSync(dir, { recursive: true, force: true });
});

// ── 确认门转译 ───────────────────────────────────────────────────────────

test('非 TTY 无授权不再自动注入 --yes——子 Skill 确认门退出码 6 → 编排器转码 4 + 待确认指引', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-t4-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, ...answers],
    { ARKUIX_MOCK_SKELETON: 'confirm' });
  assert.equal(r.status, 4, `status=${r.status}\n${r.stderr}`);
  assert.ok(r.stderr.includes('待确认'), '转"待确认"语义（不再误报工具失败）');
  assert.ok(r.stderr.includes('ARKUIX_SCAN_YES=1'), '指引含授权方式');
  rmSync(dir, { recursive: true, force: true });
});

test('ARKUIX_SCAN_YES=1 授权后确认门放行（全流程退出码 0）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-t4-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, ...answers],
    { ARKUIX_MOCK_SKELETON: 'confirm', ARKUIX_SCAN_YES: '1' });
  assert.equal(r.status, 0, r.stderr);
  rmSync(dir, { recursive: true, force: true });
});

test('SDK 不自动选定——无预设时 F2 呈报候选退出码 4 → 编排器转"待确认 SDK"（码 4）呈报候选', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-t6-'));
  const env = { ARKUIX_MOCK_SCAN: 'confirm-sdk', ARKUIX_OH_SDK_DIR: '/fake/oh/sdk', ARKUIX_SDK_DIR: '/fake/ambiguous' };
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--stages', 'scan'], env);
  assert.equal(r.status, 4, `status=${r.status}\n${r.stderr}`);
  assert.ok(r.stderr.includes('待确认: 阶段=scan'), '转"待确认 SDK"框架（非工具失败）');
  assert.ok(r.stderr.includes('--answer sdk='), '指引含 --answer sdk= 预设方式');
  assert.ok(r.stderr.includes('★ /mock/sdk/26.0.0'), 'F2 候选清单原样透传（含推荐标记）');
  assert.ok(r.stderr.includes('sdk-preset=unset'), '调试行显示未预设');
  assert.ok(!existsSync(join(dir, 'out', 'scan-report.json')), '未确认零产出');
  rmSync(dir, { recursive: true, force: true });
});

test('环境变量不再视为确认（ARKUIX_OH_SDK_DIR 设值仍呈报待确认，不自动注入）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-t6-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--stages', 'scan'],
    { ARKUIX_MOCK_SCAN: 'confirm-sdk', ARKUIX_OH_SDK_DIR: '/fake/oh/sdk' });
  assert.equal(r.status, 4, `status=${r.status}\n${r.stderr}`);
  assert.ok(r.stderr.includes('sdk-preset=unset'), 'env 不注入（显式预设优先）');
  rmSync(dir, { recursive: true, force: true });
});

test('--answer sdk=<目录> 预设 → 注入 --sdk-dir（开发者显式确认），全链通过', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-t6-'));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--stages', 'scan',
    '--answer', 'sdk=/confirmed/sdk/26.0.0'], { ARKUIX_MOCK_SCAN: 'confirm-sdk' });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(r.stderr.includes('sdk-preset=given'), '调试行显示预设');
  const scanReport = JSON.parse(readFileSync(join(dir, 'out', 'scan-report.json'), 'utf8'));
  assert.ok(scanReport.sdk && scanReport.sdk.path === '/confirmed/sdk/26.0.0', '--sdk-dir 注入（mock-scan 透传）', JSON.stringify(scanReport.sdk));
  rmSync(dir, { recursive: true, force: true });
});

// ── ：force_no_kits 预设透传 ────────────────────────────────────────────
test('--answer force_no_kits=1 → 透传 --force-no-kits 给 F2（质量门显式确认）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-t7-'));
  const log = join(dir, 'calls.log');
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, '--stages', 'scan',
    '--answer', 'sdk=/confirmed/sdk/26.0.0', '--answer', 'force_no_kits=1'], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  const calls = readFileSync(log, 'utf8');
  assert.ok(calls.includes('scan(--force-no-kits)'), '--force-no-kits 已透传（mock 调用日志断言面）');
  rmSync(dir, { recursive: true, force: true });
});

// ── new 模式配置迁移强确认门（编排透传 + 缺预设转码 4） ──────────
test('--answer migrate_configs 预设 → 透传 --migrate-configs 给 F1 并落账决策', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const newAnswers = [...answers.map((a) => (a === 'skeleton_mode=modify' ? 'skeleton_mode=new' : a)),
    '--answer', 'migrate_configs=yes', '--answer', 'compile_sdk=26.0.0'];
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...newAnswers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(readFileSync(log, 'utf8').includes('migrate-configs=yes'), 'mock 收到 --migrate-configs yes（值型 flag 正确消费）');
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  assert.equal(st.decisions.find((d) => d.point === 'migrate_configs')?.chosen, 'yes', '决策落账 MigrationState');
  rmSync(dir, { recursive: true, force: true });
});

test('new 模式缺 migrate_configs 预设 → F1 退出码 6 → 编排器转码 4 + 专属指引', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const newAnswers = answers.map((a) => (a === 'skeleton_mode=modify' ? 'skeleton_mode=new' : a));
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, ...newAnswers]);
  assert.equal(r.status, 4, r.stderr);
  assert.ok(r.stderr.includes('--answer migrate_configs=yes|no'), '专属指引在场', r.stderr);
  assert.ok(r.stderr.includes('待确认: 阶段=skeleton'), '待确认标注在场', r.stderr);
  rmSync(dir, { recursive: true, force: true });
});

// ── Compile SDK 版本强确认门（编排透传 + 缺预设转码 4） ──────────
test('compile_sdk：--answer compile_sdk 预设 → 透传 --compile-sdk 并落账决策', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const out = join(dir, 'out');
  const log = join(dir, 'calls.log');
  const newAnswers = [...answers.map((a) => (a === 'skeleton_mode=modify' ? 'skeleton_mode=new' : a)),
    '--answer', 'migrate_configs=no', '--answer', 'compile_sdk=24'];
  const r = run([FIXTURE, '--out', out, '--skill-dir', MOCK_DIR, ...newAnswers], { ARKUIX_MOCK_LOG: log });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(readFileSync(log, 'utf8').includes('compile-sdk=24'), 'mock 收到 --compile-sdk 24（值型 flag 正确消费）');
  const st = JSON.parse(readFileSync(join(out, 'migration-state.json'), 'utf8'));
  assert.equal(st.decisions.find((d) => d.point === 'compile_sdk')?.chosen, '24', '决策落账 MigrationState');
  rmSync(dir, { recursive: true, force: true });
});

test('compile_sdk：new 模式缺 compile_sdk 预设 → F1 退出码 6 → 编排器转码 4 + 专属指引', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-e2e-'));
  const newAnswers = [...answers.map((a) => (a === 'skeleton_mode=modify' ? 'skeleton_mode=new' : a)),
    '--answer', 'migrate_configs=no'];
  const r = run([FIXTURE, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, ...newAnswers]);
  assert.equal(r.status, 4, r.stderr);
  assert.ok(r.stderr.includes('--answer compile_sdk=<版本>'), '专属指引在场', r.stderr);
  assert.ok(r.stderr.includes('待确认: 阶段=skeleton'), '待确认标注在场', r.stderr);
  rmSync(dir, { recursive: true, force: true });
});

// ── new 模式默认输出目录锚定工程根（不随执行目录漂移）──
test('new 模式无 --out → 默认落 <工程>/arkuix-orchestrate/（cwd=skill 根也不漂移）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-out-'));
  const proj = join(dir, 'proj');
  cpSync(FIXTURE, proj, { recursive: true });
  const newAnswers = answers.map((a) => (a === 'skeleton_mode=modify' ? 'skeleton_mode=new' : a))
    .concat(['--answer', 'migrate_configs=yes', '--answer', 'compile_sdk=26.0.0']);
  // cwd=skill 根（历史误入场景）——默认 out 仍应锚定工程根
  const r = run([proj, '--skill-dir', MOCK_DIR, ...newAnswers], {}, root);
  assert.equal(r.status, 0, r.stderr);
  assert.ok(existsSync(join(proj, 'arkuix-orchestrate', 'migration-state.json')), '产物落 <工程>/arkuix-orchestrate/');
  assert.ok(!existsSync(join(root, 'arkuix-orchestrate')), 'skill 根零误入');
  assert.ok(!existsSync(join(proj, '.arkui-x', 'migration')), 'new 模式不落 modify 默认路径');
  rmSync(dir, { recursive: true, force: true });
});

// ── 回滚/续跑轮骨架模式恢复：skeleton 已 done 时落位仍按已确认模式取 projectRoot（commons 落工程根而非输出目录）──
test('rollback bridge 轮：modify 已确认 → commons 落工程根（skeletonMode 从 decisions 恢复）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-rbmode-'));
  const proj = join(dir, 'proj');
  cpSync(FIXTURE, proj, { recursive: true });
  const out = join(proj, '.arkui-x', 'migration');
  const common = ['--skill-dir', MOCK_DIR, '--answer', 'skeleton_mode=modify',
    '--answer', 'uk:@ohos.nonsense::mysteryApi=keep_unknown', '--answer', 'uk:@ohos.mockFeature::legacyApi=equivalent_bridge',
    '--answer', 'bd:@hms.map::map.MapComponent=降级为OH替代', '--answer', 'bd:@hms.push::pushService.getToken=裁剪',
    '--answer', 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList=重新设计实现',
    '--answer', 'bd:@kit.MockKit::mockKit.doThing=降级为OH替代'];
  const r1 = run([proj, '--out', out, ...common], { ARKUIX_SCAN_YES: '1' });
  assert.equal(r1.status, 0, r1.stderr);
  // 预置 bridge 输出侧 commons（mock 替身不产 commons——以真实 wireCommonsAsHar 路径为对象）
  const bc = join(out, 'bridge', 'commons', 'deviceInfo');
  mkdirSync(join(bc, 'interface'), { recursive: true });
  mkdirSync(join(bc, 'impl'), { recursive: true });
  writeFileSync(join(bc, 'interface', 'DeviceInfoUdidInterface.ets'), 'export interface DeviceInfoUdidInterface {\n  udid(): Promise<unknown>;\n}\n');
  writeFileSync(join(bc, 'impl', 'DeviceInfoUdidImpl.ets'), 'export class DeviceInfoUdidImpl {\n  public static getInterface(): DeviceInfoUdidInterface { return null as ESObject; }\n}\n');
  const r2 = run([proj, '--out', out, ...common, '--rollback', 'bridge'], { ARKUIX_SCAN_YES: '1' });
  assert.equal(r2.status, 0, r2.stderr);
  assert.ok(existsSync(join(proj, 'commons', 'deviceinfo', 'Index.ets')), '回滚轮 commons 仍落工程根（模式已恢复）');
  const idx = readFileSync(join(proj, 'commons', 'deviceinfo', 'Index.ets'), 'utf8');
  assert.ok(idx.includes('export const udid: DeviceInfoUdidInterface = DeviceInfoUdidImpl.getInterface();'), '具名符号实例导出（symbol=udid）');
  assert.ok(!existsSync(join(out, 'commons')), '回滚轮 commons 不落输出目录');
  rmSync(dir, { recursive: true, force: true });
});

// ── new 模式 scaffold 落点事前告知（stdout 打印路径）──
test('new 模式 skeleton 阶段开始前打印 scaffold 落点路径', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-scaffold-'));
  const proj = join(dir, 'proj');
  cpSync(FIXTURE, proj, { recursive: true });
  const newAnswers = answers.map((a) => (a === 'skeleton_mode=modify' ? 'skeleton_mode=new' : a))
    .concat(['--answer', 'migrate_configs=yes', '--answer', 'compile_sdk=26.0.0']);
  const r = run([proj, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, ...newAnswers], { ARKUIX_SCAN_YES: '1' });
  assert.equal(r.status, 0, r.stderr);
  assert.ok(r.stdout.includes('scaffold 落点：'), 'stdout 含 scaffold 落点路径');
  assert.ok(r.stdout.includes(join(dir, 'out')), '路径含 --out 指定目录');
  // modify 模式不打印此行
  const r2 = run([proj, '--out', join(dir, 'out2'), '--skill-dir', MOCK_DIR, ...answers], { ARKUIX_SCAN_YES: '1' });
  assert.equal(r2.status, 0, r2.stderr);
  assert.ok(!r2.stdout.includes('scaffold 落点：'), 'modify 模式不打印 scaffold 落点');
  rmSync(dir, { recursive: true, force: true });
});

// ── bridge_codegen=proceed 指引含逐接口版本约束（有标注/unmapped/未标注三类）──
test('bridge_codegen=proceed：指引输出逐接口版本约束（有版本标注+unmapped 需人工确认+未标注适用基线）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f4-bcg-'));
  const proj = join(dir, 'proj');
  cpSync(FIXTURE, proj, { recursive: true });
  const fullAns = [...answers, '--answer', 'bridge_codegen=proceed'];
  const r = run([proj, '--out', join(dir, 'out'), '--skill-dir', MOCK_DIR, ...fullAns], { ARKUIX_SCAN_YES: '1' });
  assert.equal(r.status, 0, r.stderr);
  const out = r.stdout || '';
  assert.ok(out.includes('版本约束门'), '指引含版本约束门');
  assert.ok(out.includes('agent 必须查'), '约束 agent 查官方文档');
  assert.ok(out.includes('编排器不代查版本信息'), '明确编排器不代查——agent 职责');
});
