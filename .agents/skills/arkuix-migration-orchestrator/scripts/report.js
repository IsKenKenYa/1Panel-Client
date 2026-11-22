import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { sixItemsOf } from './prompter.js';

const ACTIONS = {
  '删除': '删除该调用与对应 import 行',
  '重新设计实现': '重新设计跨平台实现（可走 F3 六件套：①Interface 契约 + ⑥Impl 分发器）',
  '降级为OH替代': (alt) => `调用点替换为替代实现：${alt || '需开发者评估（见迁移报告建议段）'}`,
  '降级为平台原生桥接': '已移入④桶——bridge 阶段自动生成 F3 六件套（调用点切换 ⑥Impl 分发器，Android/iOS 走平台原生桥接）',
  '自行实现': '自行实现跨平台等价能力（建议 F3 六件套骨架）',
  '裁剪': '裁剪该能力（删除调用与 import，或按平台条件编译隔离）',
  equivalent_bridge: '调用点切换到 F3 六件套（import ⑥Impl 分发器，getInterface() 自动选桥接/本地）',
  degraded_bridge: '调用点切换到 F3 六件套（④降级语义，注意能力损失标注）',
  platform_trim: '裁剪该调用与 import',
  keep_unknown: '暂搁置（待后续裁决/人工确认）',
};

function rewriteTickets(state, scan) {
  const rows = [];
  for (const d of state.decisions.filter((x) => x.chosen && /^(bd|uk):/.test(x.point))) { // 仅接口类决策（bd/uk），关键决策（骨架模式等）不入工单
    const key = d.point.replace(/^(bd|uk):/, '');
    const [module, symbol] = key.split('::');
    const item = findItem(scan, module, symbol);
    const act = typeof ACTIONS[d.chosen] === 'function' ? ACTIONS[d.chosen](item?.suggested_alternative) : (ACTIONS[d.chosen] ?? `按决策「${d.chosen}」处理`);
    const locs = (item?.locations ?? []).slice(0, 5).map((l) => '`' + l + '`').join(' ') || '_（无位置记录）_';
    rows.push(`| ${module}::${symbol} | ${d.chosen} | ${locs} | ${act} |`);
  }
 //② reduced_direct 编译阻断项——无决策但编译必败风险，入工单呈报（已同步插 TODO）
  for (const it of scan?.adaptation?.reduced_direct ?? []) {
    const locs = (it.locations ?? []).slice(0, 5).map((l) => '`' + l + '`').join(' ') || '_（无位置记录）_';
    const advice = it.advice || '按页内平台标注调整用法';
    rows.push(`| ${it.module}::${it.symbol} | ②编译阻断 | ${locs} | ②部分支持——部分符号 ArkUI-X 编译被拒：${advice}（模块可用，不注 import；调用点已插 TODO） |`);
  }
  if ((scan?.adaptation?.reduced_direct ?? []).length > 0) {
    rows.push('| （编译开关） |  | n/a | scaffold 已默认注入 `buildOption.ignoreCrossPlatform=true`（11706007 降为警告以解锁编译；**运行时 Android/iOS 上这些 API 仍不可用**——需 canIUse 守卫、平台差异逻辑或 F3 Bridge 接线；`--strict-crossplatform` 可恢复严格错误） |');
  }
  if (rows.length === 0) return '（无待改写项——所有决策均无需源码动作或无决策）';
  return ['| 接口 | 决策 | 源工程位置 | 建议动作 |', '|------|------|-----------|----------|', ...rows].join('\n');
}

function findItem(scan, module, symbol) {
  if (!scan?.adaptation) return undefined;
  for (const bucket of Object.values(scan.adaptation)) {
    const hit = (bucket ?? []).find((it) => it.module === module && it.symbol === symbol);
    if (hit) return hit;
  }
  return undefined;
}

/**
 * ReportComposer：5 段迁移报告+安全声明（同源汇总不自判）。
 * 分类结论一律取自  与阶段产物契约字段，本模块不重新判定。
 */

const tplPath = join(dirname(fileURLToPath(import.meta.url)), '..', 'templates', 'report.md.tpl');

export function composeReport(state, artifacts, tpl) {
  const template = tpl ?? readFileSync(tplPath, 'utf8');
  const scan = artifacts.scan ?? { adaptation: {} };
  const bars = artifacts.bridge ?? { artifacts: [], unmapped_native_apis: [] };
  const skeleton = artifacts.skeleton;

  const converted = section([...(scan.adaptation?.full_direct ?? []), ...(scan.adaptation?.reduced_direct ?? [])],
    (it) => `- ${it.module} :: ${it.symbol}（${it.source}）`);
  const degraded = section([...(scan.adaptation?.degraded_bridge ?? []), ...decidedSix(state, ['降级为OH替代'])],
    (it) => `- ${it.module} :: ${it.symbol}${it.chosen ? `（⑥决策：${it.chosen}）` : ''}`);
  const bridge = bars.artifacts.length
    ? [
        '**已生成并落位工程**（六件套 + BridgeRegistry + 工程级 PlatformInfo）：',
        ...bars.artifacts.map((a) => {
          const fileCount = Object.values(a.files ?? {}).filter(Boolean).length;
 // ：逐接口最低版本后缀（bridge-artifact min_*，来自 native-api-map 策展）——F4 适用版本澄清
          const ver = [a.min_android, a.min_ios].filter(Boolean).join(' / ');
          return `- ${a.name}（${a.category === 'equivalent_bridge' ? '③' : '④'}）${ver ? `——最低版本 ${ver}；` : '——'} ${fileCount} 文件，已写入工程 .arkui-x/ 与 entry/src/main/ets/commons/`;
        }),
        '',
        '**还需完成的接线**（文件已在工程内，以下两步激活）：',
        '- Android：宿主 Activity/Application 的 onCreate 调用 `BridgeRegistry.registerAll(context, BridgeManager.getInstance());`',
        '- 业务调用点：import ⑥Impl 分发器——`XxxImpl.getInterface().method()` 替换原 @ohos.* 直调（Android/iOS 自动走③桥接、HarmonyOS 走②Local；调用点已插 TODO 标注）',
        ...(bars.artifacts.some((a) => a.local_status === 'failed') || bars.unmapped_native_apis.length
          || (bars.audit && bars.audit.deficient_count > 0)
          ? ['', '**生成降级**（待人工补齐，不影响骨架可用性）：',
             ...bars.artifacts.filter((a) => a.local_status === 'failed')
               .map((a) => `- ${a.name}：②Local 迁移源缺失——平台实现需在④⑤围栏内补写`),
             ...(bars.unmapped_native_apis.length
               ? bars.unmapped_native_apis.map((u) => `- ${u}：等价映射未收录，需人工确认替代 API`)
               : []),
             ...(bars.audit && bars.audit.deficient_count > 0
               ? bars.audit.deficient.flatMap((d) => d.issues.map((i) =>
                 `- ${d.name}【${i.kind}】${i.file}：${i.detail}——${i.action}`))
               : [])]
          : []),
      ].join('\n')
    : '（未执行/无桥接项）';
  const unresolved = section([
    ...(scan.adaptation?.unknown ?? []),
    ...(bars.unmapped_native_apis ?? []).map((u) => ({ module: u.split('::')[0], symbol: u.split('::')[1], reason: 'unmapped' })),
    ...undecidedSix(state, artifacts.scan),
  ], (it) => `- ${it.module} :: ${it.symbol}${it.reason ? `（${it.reason}）` : '（⑥未决策）'}`);
  const decisions = state.decisions.length
    ? state.decisions.map((d) => `- [${d.point}] ${d.question} → ${d.chosen ?? '（未确认）'}${d.source ? `（来源：${d.source}）` : ''}`).join('\n')
    : '（无）';

  const skipped = STAGE_MARKS(state, 'skipped');
 // N2-A：源码改写工单（决策联动）——每个已确认决策映射回源工程位置与建议动作
  const tickets = rewriteTickets(state, artifacts.scan);
 // 适用版本澄清：工程基线 = F1 skeleton-result.platform_baseline（生成产物实测提取）；
 // 逐接口标注 = bridge-artifact min_android/min_ios（native-api-map 策展）优先于基线；恒附"更新开发环境"提示
  const pb = artifacts.skeleton?.platform_baseline;
  const pbLines = [];
  if (pb?.android) {
    pbLines.push(`- 工程基线（scaffold 实测）：Android minSdkVersion ${pb.android.min_sdk}${pb.android.target_sdk ? `（targetSdk ${pb.android.target_sdk}${pb.android.compile_sdk ? ` / compileSdk ${pb.android.compile_sdk}` : ''}）` : ''}`);
  }
  if (pb?.ios) pbLines.push(`- 工程基线（scaffold 实测）：iOS deployment target ${pb.ios.deployment_target}`);
  if (pb?.openharmony) {
    const oh = pb.openharmony;
    // 按在场字段拼装（modify 模式不做版本选择时 compile_sdk_version 缺席）——compile_sdk_version 在场才附"落账"尾注，缺席时显式注明"未做版本选择"。
    const parts = [];
    if (oh.compile_sdk_version) parts.push(`${oh.runtime_os ?? 'OpenHarmony'} compileSdkVersion ${oh.compile_sdk_version}`); // 前缀按实际形态（与源工程同步语义下可为 HarmonyOS）
    if (oh.runtime_os) parts.push(`runtimeOS ${oh.runtime_os}`);
    if (oh.model_version) parts.push(`hvigor modelVersion ${oh.model_version}`);
    if (parts.length > 0) {
      const tail = oh.compile_sdk_version ? '——Compile SDK 版本选择落账' : '（modify 模式未做版本选择）';
      pbLines.push(`- 工程基线（scaffold 实测）：${parts.join('，')}${tail}`);
    }
  }
  if (pbLines.length === 0) {
    pbLines.push('- 工程基线：本次运行未取得 skeleton-result.platform_baseline（skeleton 阶段未执行或为旧版产物）');
  }
  const bridgeArtifacts = (bars.artifacts ?? []);
  const withVer = bridgeArtifacts.filter((a) => a.min_android || a.min_ios)
    .map((a) => `- ${a.name}：${[a.min_android, a.min_ios].filter(Boolean).join(' / ')}`);
  const withoutVer = bridgeArtifacts.filter((a) => !a.min_android && !a.min_ios && !a.unmapped)
    .map((a) => `- ${a.name}：（版本未标注——适用工程基线）`);
  const unmapped = bridgeArtifacts.filter((a) => !a.min_android && !a.min_ios && a.unmapped)
    .map((a) => `- ${a.name}：（原生 API 映射未策展——需人工确认替代 API 及版本要求）`);
  const perApi = [...withVer, ...withoutVer, ...unmapped];
  const platformBaseline = [
    ...pbLines,
    ...(perApi.length > 0
      ? ['- 逐接口标注（最低版本）优先于工程基线；未标注条目适用工程基线', ...perApi]
      : ['- 逐接口版本标注：本次迁移无桥接接口（bridge 阶段未产出或 ③④桶为空）']),
    '- ⚠ 使用有问题（编译失败/运行异常）时，请先确认目标设备与开发环境不低于上述版本，并升级 ArkUI-X SDK / Android SDK / Xcode 后重试',
  ].join('\n');
  return template
    .replace('{{tickets}}', tickets)
    .replace('{{platformBaseline}}', platformBaseline)
    .replace('{{converted}}', stageMark(converted, state, 'scan') ?? converted)
    .replace('{{degraded}}', converted === '（无）' && degraded === '（无）' ? degraded : degraded)
    .replace('{{bridge}}', state.stages.bridge.status === 'skipped' ? '未执行（阶段未选择）' : bridge)
    .replace('{{unresolved}}', unresolved)
    .replace('{{decisions}}', decisions)
    .replace('{{skeleton}}', skeleton ? `${skeleton.mode}/${skeleton.platform}` : (state.stages.skeleton.status === 'skipped' ? '未执行（阶段未选择）' : '（无）'))
    .replace('{{stageOverview}}', ['scan', 'skeleton', 'bridge', 'report'].map((s) => `${s}=${state.stages[s].status}`).join('，'))
    + (skipped.length ? `\n\n> 未执行阶段：${skipped.join('、')}\n` : '');
}

function section(items, render) {
  if (!items || items.length === 0) return '（无）';
  return items.map(render).join('\n');
}

function decidedSix(state, chosenSet) {
  return state.decisions.filter((d) => d.source && d.chosen && chosenSet.includes(d.chosen))
    .map((d) => ({ module: d.point.replace(/^bd:/, '').split('::')[0], symbol: d.point.replace(/^bd:/, '').split('::')[1], chosen: d.chosen }));
}

function undecidedSix(state, scan) {
  const decided = new Set(state.decisions.filter((d) => d.chosen).map((d) => d.point));
  const recorded = new Set(state.decisions.map((d) => d.point));
  const pending = scan ? sixItemsOf(scan)
    .filter((it) => !decided.has(`bd:${it.module}::${it.symbol}`))
    .map((it) => ({ module: it.module, symbol: it.symbol })) : [];
  const aborted = state.decisions.filter((d) => d.source && !d.chosen)
    .map((d) => ({ module: d.point.replace(/^bd:/, '').split('::')[0], symbol: d.point.replace(/^bd:/, '').split('::')[1] }));
  return [...pending, ...aborted.filter((a) => !recorded.has(`bd:${a.module}::${a.symbol}`) || !decided.has(`bd:${a.module}::${a.symbol}`))];
}

function STAGE_MARKS(state, status) {
  return Object.entries(state.stages).filter(([, v]) => v.status === status).map(([k]) => k);
}

function stageMark(text, state, stage) {
  return state.stages[stage]?.status === 'skipped' ? '未执行（阶段未选择）' : text;
}
