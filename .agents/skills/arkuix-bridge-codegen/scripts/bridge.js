#!/usr/bin/env node
import { existsSync, readFileSync } from 'node:fs';
import { resolve, join } from 'node:path';
import { loadScanReport, extractBridges, isEmptyBridgeList, FormatError } from './report-loader.js';
import { extractLocal } from './local-extractor.js';
import { composeContract, deriveFromSdkDeclarations } from './interface-composer.js';
import { loadTemplates, renderFivePieces } from './renderer.js';
import { loadNativeApiMap } from './native-map.js';
import { checkSignatures } from './signature-checker.js';
import { mergeFile, mergeLocal } from './merger.js';
import { writePieces, writeArtifactJson, renderReport, atomicWrite } from './writer.js';
import { auditPieces } from './auditor.js';

/** CLI 退出码映射（spec  固化，跨版本稳定） */
const EXIT_OK = 0; // 成功（含③④均空 、单接口 Local 失败的部分成功 ）
const EXIT_INTERNAL = 1; // 内部错误：未预期异常
const EXIT_USAGE = 2; // 输入无效：源工程/ScanReport 不存在或不可读、参数非法
const EXIT_FORMAT = 3; // ScanReport 格式异常

function usage() {
  return [
    '用法: node scripts/bridge.js <源工程根目录> --scan-report <ScanReport 路径> [--out <输出目录>]',
    '',
    '消费 F2 ScanReport 的 ③equivalent_bridge/④degraded_bridge 分类，生成五件套 + BridgeArtifact + 报告。',
    '  --scan-report <路径>   F2 ScanReport 文件（必填，schema_version=1）',
    '  --out <目录>           输出目录（默认 ./arkuix-bridge/，不写入源工程）',
    '',
    '退出码: 0 成功（含空清单/部分成功） / 1 内部错误 / 2 输入无效 / 3 ScanReport 格式异常',
  ].join('\n');
}

export function parseArgs(argv) {
  const opts = { root: null, scanReport: null, out: null };
  for (let i = 0; i < argv.length; i++) {
    const a = argv[i];
    if (a === '--scan-report') opts.scanReport = argv[++i];
    else if (a === '--out') opts.out = argv[++i];
    else if (a === '--help' || a === '-h') { opts.help = true; return opts; }
    else if (!opts.root) opts.root = a;
    else { opts.error = `多余参数：${a}`; return opts; }
  }
  return opts;
}

/** 主流程（导出供测试）：返回 {exitCode} */
export function run(root, scanReportPath, outDir) {
 // 步骤 2：加载与契约校验
  let report;
  try {
    report = loadScanReport(scanReportPath);
  } catch (e) {
    if (e instanceof FormatError) {
      console.error(e.message);
      writeArtifactJson(outDir, { schema_version: 1, artifacts: [], unmapped_native_apis: [] });
      return EXIT_FORMAT;
    }
    throw e;
  }
  loadNativeApiMap(); // ：fail-fast（损坏→未预期异常→码 1）

 // ：③④均空→良性完成
  if (isEmptyBridgeList(report)) {
    console.log('无需桥接接口');
    writeArtifactJson(outDir, { schema_version: 1, artifacts: [], unmapped_native_apis: [] });
    return EXIT_OK;
  }

  const items = extractBridges(report);
  const skippedIncludes = items.skippedIncludes ?? [];
  if (skippedIncludes.length > 0) {
    console.log(`已跳过 ${skippedIncludes.length} 个 #include 头文件依赖项（无调用语义，不生成桥接件；清单见报告）`);
  }
  const templates = loadTemplates();

 // ：SDK 判定源=scan-report 确认的 SDK（开发者确认语义链）——d.ts 声明面（①契约源 0）与 kit import 改写共用
  const sdkDir = report.sdk?.path || '';
  if (sdkDir) console.log(`SDK 声明面源（scan-report 确认）: ${sdkDir}（d.ts 契约面 + ②Local kit import 改写）`);

 // 步骤 3~5：Local 提取（全 locations 收割+kit 改写）→ ①契约（多源含 d.ts）→ 六件渲染
  const pieces = [];
  for (const item of items) {
    const local = extractLocal(item, root, { sdkDir });
    const contract = composeContract(item, local, root, sdkDir); //传 srcRoot 供调用面推导
    const rendered = renderFivePieces(item, local, contract, templates);

 // 步骤 7：增量合并（②Local 已存在→保留；④⑤围栏保留）
    const texts = {};
    for (const [rel, draft] of Object.entries(rendered.texts)) {
      const abs = join(outDir, rel);
      const existing = existsSync(abs) ? readFileSync(abs, 'utf8') : null;
      const kind = rel === rendered.paths.android ? 'java'
        : (rel === rendered.paths.ios || rel === rendered.paths.ios_m) ? 'objc'
        : rel === rendered.paths.local ? 'local' : null;
      const merged = kind === 'local' ? mergeLocal(existing, draft) : mergeFile(existing, draft, kind);
      if (merged.kept && kind === 'local') rendered.keptLocalNote = '②Local 已存在，保留开发者版本';
      texts[rel] = merged.content;
    }
    pieces.push({
      item,
      paths: rendered.paths,
      texts,
      localStatus: local.status,
      localReason: local.status === 'failed' ? local.reason : undefined,
      unmapped: rendered.unmapped,
      nativeApi: rendered.nativeApi,
      derived: contract.derived,
 // 语义自检输入：契约面与 SDK 声明面的方法计数（contract-thin 判定=面覆盖缺口）
      contractMethodCount: contract.methods.length,
      sdkFaceMethodCount: sdkDir ? deriveFromSdkDeclarations(sdkDir, item.module, item.symbol).length : 0,
    });
  }

 // 步骤 6：签名一致性（不阻断）
  const contracts = items.map((it, i) => composeContract(it, pieces[i].localStatus === 'migrated'
    ? { status: 'migrated', content: pieces[i].texts[pieces[i].paths.local] } : { status: 'failed' }, root, sdkDir));
  const mismatches = checkSignatures(items, contracts);

 // 步骤 8：产出（+报告，原子写盘）
  const { artifact, unmapped, localFailures } = writePieces(outDir, pieces, templates);
 // 步骤 9：产物自检——五件套落盘后确定性结构检查；硬残缺入 audit.deficient（必补），
 // 建议级入 audit.suggestions；agent 标准动作见 SKILL.md"产物自检兜底"；不改退出码（残缺=待补信号）
  artifact.audit = auditPieces(outDir, pieces);
  if (artifact.audit.deficient_count > 0) {
    console.error(`⚠ 产物自检：${artifact.audit.checked} 件中 ${artifact.audit.deficient_count} 件硬残缺——清单见 bridge-artifact.json 的 audit.deficient 与报告"产物自检"段；请读取对应文件与源工程 locations 补全后重跑（幂等不覆盖手改）。`);
  }
  if (artifact.audit.suggestion_count > 0) {
    console.error(`提示: 产物自检另有 ${artifact.audit.suggestion_count} 件建议级（contract-thin 单方法兜底契约，建议补全调用面）——见 audit.suggestions。`);
  }
  writeArtifactJson(outDir, artifact);
  const tpl = readFileSync(new URL('../templates/report.md.tpl', import.meta.url), 'utf8');
  const reportMd = renderReport(tpl, {
    scanReportPath,
    skippedIncludes: skippedIncludes.length ? skippedIncludes.map((it) => `- ${it.module}（头文件依赖）`).join('\n') : '（无）',
    wiringGuide: pieces.length > 0
      ? [
         '**产物落位说明**：六件套在输出目录内；接线时按以下路径映射拷入工程壳——',
         '- ①Interface/②Local/③ArkUIX/⑥Impl 分发器：`<输出目录>/commons/<module>/` → `<工程根>/entry/src/main/ets/commons/`（或任一编译集模块）',
         '- 工程级 PlatformInfo：`<输出目录>/commons/utils/PlatformInfo.ets` → `<工程根>/entry/src/main/ets/commons/utils/`（⑥分发器共用，每工程一份）',
         '- ④Android BridgePlugin：`<输出目录>/.arkui-x/android/` → `<工程根>/.arkui-x/android/`（Java 源码树同路径）',
         '- ⑤iOS BridgePlugin：`<输出目录>/.arkui-x/ios/` → `<工程根>/.arkui-x/ios/`（并加入 Xcode target）',
         '',
         '**Android 接线三步**：',
         '1. 拷贝 ④ Java 文件到工程 `.arkui-x/android/` 对应目录',
         '2. 在宿主 Activity/Application 的 onCreate 调用：`BridgeRegistry.registerAll(context, BridgeManager.getInstance());`',
         '3. AndroidManifest.xml 补权限（按接口需求：CAMERA/VIBRATE/INTERNET 等）',
         '',
         '**ArkTS 接线（一码三平台）**：业务调用点 import ⑥分发器——`import { XxxImpl } from \'.../impl/XxxImpl\'; XxxImpl.getInterface().method(...)` 替换原 @ohos.* 直调（调用点已插 TODO 标注）。Android/iOS 自动走③桥接、HarmonyOS 走②Local 直调——业务码零平台感知',
         '',
         '**iOS 接线三步**：',
         '1. 拷贝 ⑤ .h/.m 到工程 `.arkui-x/ios/` 对应目录',
         '2. project.pbxproj 加 PBXBuildFile/PBXFileReference/PBXGroup/PBXSourcesBuildPhase 四段引用',
         '3. AppDelegate 初始化处创建 Bridge 实例（各头文件注释含创建代码）',
        ].join('\n')
      : '（无桥接产物）',
    total: items.length,
    equivalentCount: items.filter((i) => i.category === 'equivalent_bridge').length,
    degradedCount: items.filter((i) => i.category === 'degraded_bridge').length,
    localMigrated: pieces.filter((p) => p.localStatus === 'migrated').length,
    localFailed: localFailures.length,
    mismatchCount: mismatches.length,
    unmappedCount: unmapped.length,
    artifactTable: artifactsTable(pieces),
    mismatchList: mismatches.length ? mismatches.map((m) => `- ${m.name}.${m.method}（${m.type}→${m.side}）：${m.issue}`).join('\n') : '（无）',
    unmappedList: unmapped.length ? unmapped.map((u) => `- ${u}`).join('\n') : '（无）',
    localFailureList: localFailures.length ? localFailures.map((f) => `- ${f.name}：${f.reason}`).join('\n') : '（无）',
    auditChecked: artifact.audit.checked,
    auditDeficientCount: artifact.audit.deficient_count,
    auditList: artifact.audit.deficient_count > 0
      ? artifact.audit.deficient.map((d) => d.issues.map((i) =>
        `- ${d.name}（${d.symbol}）【${i.kind}】${i.file}：${i.detail}\n  → ${i.action}`).join('\n')).join('\n')
      : '（无硬残缺项）',
    auditSuggestionList: artifact.audit.suggestion_count > 0
      ? artifact.audit.suggestions.map((d) => d.issues.map((i) =>
        `- ${d.name}（${d.symbol}）【${i.kind}】${i.detail}\n  → ${i.action}`).join('\n')).join('\n')
      : '（无）',
    keptNote: pieces.some((p) => p.keptLocalNote) ? '- 本次再生成存在保留项：②Local 已存在文件未覆盖。' : '',
  });
  atomicWrite(join(outDir, 'bridge-report.md'), reportMd);
  return EXIT_OK;
}

function artifactsTable(pieces) {
 // ：最低版本列（native-api-map min_* 在场时启用；未标注条目适用 F1 platform_baseline 工程基线）
  const hasVer = pieces.some((p) => p.nativeApi?.min_android || p.nativeApi?.min_ios);
  const rows = hasVer
    ? ['| 接口 | 分类 | ②Local | 最低版本 | 五件路径 |', '|------|------|--------|----------|----------|']
    : ['| 接口 | 分类 | ②Local | 五件路径 |', '|------|------|--------|----------|'];
  for (const p of pieces) {
    const ver = [p.nativeApi?.min_android, p.nativeApi?.min_ios].filter(Boolean)
      .map((v, i) => (i === 0 ? v : v)).join(' / ');
    const cells = [
      p.item.name,
      p.item.category === 'equivalent_bridge' ? '③' : '④',
      p.localStatus === 'migrated' ? '已迁移' : '失败',
    ];
    if (hasVer) cells.push(ver || '—（适用工程基线）');
    cells.push(`${p.paths.interface} 等`);
    rows.push(`| ${cells.join(' | ')} |`);
  }
  return rows.join('\n');
}

function main(argv) {
  const opts = parseArgs(argv);
  if (opts.help) { console.log(usage()); return EXIT_OK; }
  if (opts.error) { console.error(`错误: ${opts.error}`); console.error(usage()); return EXIT_USAGE; }
  if (!opts.root || !opts.scanReport) { console.error('错误: 缺少必填参数（源工程根目录 / --scan-report）'); console.error(usage()); return EXIT_USAGE; }
  const root = resolve(opts.root);
  const scanReportPath = resolve(opts.scanReport);
  if (!existsSync(root)) { console.error(`错误: 源工程根目录不存在：${root}`); return EXIT_USAGE; }
  if (!existsSync(scanReportPath)) { console.error(`错误: ScanReport 文件不存在：${scanReportPath}`); return EXIT_USAGE; }
  const outDir = resolve(opts.out ?? './arkuix-bridge');
  try {
    return run(root, scanReportPath, outDir);
  } catch (e) {
    console.error(`内部错误: ${e.message}`);
    return EXIT_INTERNAL;
  }
}

if (process.argv[1] && process.argv[1].endsWith('bridge.js')) {
  process.exit(main(process.argv.slice(2)));
}
