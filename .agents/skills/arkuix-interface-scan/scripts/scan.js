#!/usr/bin/env node
import { existsSync, mkdirSync, writeFileSync, renameSync } from 'node:fs';
import { join, resolve } from 'node:path';
import readline from 'node:readline/promises';
import { detectModel, enumerateFiles, extractReferences } from './extract.js';
import { detectSdkCandidates, validateSdkDir, sdkVersionOf, sdkCandidatesOfRoot, sortRecommended, hasKitsDir } from './sdk-locator.js';
import { scanMarks } from './sdk-marks.js';
import { buildKitIndex } from './kit-index.js';
import { buildNativeSymbolIndex } from './native-index.js';
import { loadRules, classify, BUCKETS } from './classify.js';
import { renderJson, renderMarkdown } from './report.js';

/** CLI 退出码映射（spec  固化，跨版本稳定） */
const EXIT_OK = 0; // 成功（含 SDK 未检出单源降级的成功产出）
const EXIT_INTERNAL = 1; // 内部错误：未预期异常
const EXIT_USAGE = 2; // 输入无效：根目录不存在/不可读、参数非法值
const EXIT_MODEL = 3; // 模型不支持：project_model=fa/unknown（产物照常写出）
const EXIT_ABORT = 4; // 用户中止：SDK 目录确认环节中止/输入流结束

function usage() {
  return [
    '用法: node scripts/scan.js <工程根目录> [--out <输出目录>] [--sdk-dir <OpenHarmony SDK 目录>] [--yes] [--no-sdk] [--force-no-kits] [--rules <规则表路径>]',
    '',
    '  <工程根目录>            待扫描的 Stage 工程根目录（必填）',
    '  --out <目录>            输出目录（默认 <工程根>/arkuix-scan-output；重跑覆盖旧产物时有确认/警示）',
    '  --sdk-dir <目录>        显式指定 OpenHarmony SDK 目录（视同确认——仍会交叉比对全量候选并打印清单；--sdk-path 为兼容别名）',
    '  --yes                   非交互采纳探测到的 SDK（视同确认，取推荐序第一并大声打印）',
    '  --no-sdk                明确降级为规则表单源判定（报告中显著标注）',
    '  --force-no-kits         显式确认使用无 kits 的 SDK（接受 @kit.* 导入无法展开、全部归⑥的后果；质量门放行）',
    '  --rules <路径>          自定义规则表（默认 rules/adaptation.json）',
    '',
    '退出码: 0=成功（含单源降级产出）; 1=内部错误; 2=输入无效; 3=模型不支持（FA/unknown，产物照常写出）; 4=用户中止（SDK 确认中止）'
  ].join('\n');
}

function parseArgs(argv) {
  const opts = { root: null, out: null, sdkDir: null, yes: false, noSdk: false, forceNoKits: false, rules: null };
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--out') opts.out = argv[++i];
    else if (arg === '--sdk-dir' || arg === '--sdk-path') opts.sdkDir = argv[++i];
    else if (arg === '--yes') opts.yes = true;
    else if (arg === '--no-sdk') opts.noSdk = true;
    else if (arg === '--force-no-kits') opts.forceNoKits = true;
    else if (arg === '--rules') opts.rules = argv[++i];
    else if (arg === '-h' || arg === '--help') { console.log(usage()); process.exit(EXIT_OK); }
    else positional.push(arg);
  }
  opts.root = positional[0] || null;
  return opts;
}

/** 仅当存在 Native 源码文件时才构建 sysroot 索引（纯 ArkTS 工程零开销） */
function inventoryHasNative(files) {
  const nativeExts = new Set(['.cpp', '.cc', '.cxx', '.h', '.hpp']);
  return files.some((f) => nativeExts.has(f.slice(f.lastIndexOf('.'))));
}

function emptyAdaptation() {
  const adaptation = {};
  for (const bucket of BUCKETS) adaptation[bucket] = [];
  return adaptation;
}

function atomicWrite(file, content) {
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, content, 'utf8');
  renameSync(tmp, file);
}

/**
 * SDK 路径查找方法（询问先行——先向开发者要路径，探测候选仅作参考）。
 * 输出到 stderr/stdout 供开发者与 agent 呈报使用。
 */
function printSdkLookupGuide() {
  console.error('SDK 路径查找方法：');
  console.error('  · DevEco Studio：设置界面（Settings/Preferences → SDK）页面可查看本机 SDK 安装位置');
  console.error('  · 常见默认位置：macOS ~/Library/OpenHarmony/Sdk、Windows %LOCALAPPDATA%\\OpenHarmony\\Sdk');
  console.error('    （旧版华为形态：~/Library/Huawei/Sdk、%LOCALAPPDATA%\\Huawei\\Sdk；DevEco 安装目录下 sdk/ 亦可）');
  console.error('  · 有效目录特征：版本级目录（如 .../Sdk/26.0.0），其下含 ets/api 且存在 @ohos.*.d.ts');
}

/**
 * （询问先行）：先向开发者询问本机 SDK 路径并确认——探测只作参考候选，
 * 不再以"探测→呈报候选→确认"为主序（防找错/耗时）；路径格式不符即反馈纠正。
 * 返回 {aborted:true} 表示用户中止/流结束（调用方退出码 4）。
 */
async function confirmSdk(opts) {
  if (opts.noSdk) return { degraded: true };
  if (opts.sdkDir) {
    const validation = validateSdkDir(opts.sdkDir);
    if (validation.ok) {
 // ：显式指定=开发者已确认——醒目打印所用版本与 kits 能力（不再静默）
      console.log(`SDK 判定源（显式指定）: ${resolve(opts.sdkDir)}（版本 ${sdkVersionOf(opts.sdkDir)}${hasKitsDir(opts.sdkDir) ? '，kits √' : '，无 kits 目录'}）`);
 // 显式预设也强制全量候选探测交叉核对——agent 抢跑塞答案不能藏住完整候选面
      crossCheckCandidates(opts.sdkDir);
      return { path: resolve(opts.sdkDir), apiDir: validation.apiDir, confirmed: true, origin: 'explicit' };
    }
 // ：指向多版本根 → 枚举子版本按推荐序呈报确认（纠正指引的一种形态）
    const expanded = sortRecommended(sdkCandidatesOfRoot(opts.sdkDir, 'explicit'));
    if (expanded.length > 0) {
      return await presentSdkCandidates(expanded, opts, `指定目录含 ${expanded.length} 个 SDK 版本`);
    }
 // 格式无效 → 详因 + 纠正指引（查找方法/有效特征）；TTY 可当场重输，非 TTY 退出码 2
    console.error(`错误: 指定的 SDK 目录无效（${validation.reason}）: ${opts.sdkDir}`);
    printSdkLookupGuide();
    if (process.stdin.isTTY) {
      const reentered = await askPathOrBrowse(localCandidates());
      if (reentered.aborted) return reentered;
      crossCheckCandidates(reentered.path);
      return reentered;
    }
    process.exit(EXIT_USAGE);
  }

  const valid = [];
  for (const candidate of detectSdkCandidates(null)) {
    const validation = validateSdkDir(candidate.path);
    if (validation.ok) valid.push({ ...candidate, ...validation });
  }
  if (valid.length === 0) return requestSdkOrDegrade();
 // --yes（CI 显式授权）：仍自动采纳推荐序第一（大声打印）
  if (opts.yes) return autoPickRecommended(valid);
 // 非 TTY：询问先行——退出码 4 零产出，指引=查找方法+参考候选+重跑通道（不代答）
  if (!process.stdin.isTTY) return nonTtyRequestSdkPath(valid);
 // TTY：先问路径（回车浏览探测候选；无效路径当场反馈纠正）
  return askPathOrBrowse(valid);
}

/** 本机有效候选（探测+校验，供交叉核对/质量门建议清单） */
function localCandidates() {
  return detectSdkCandidates(null).filter((c) => {
    const v = validateSdkDir(c.path);
    return v.ok;
  });
}

/** --yes（CI 显式授权）：采纳推荐序第一=最新含 kits，stdout 大声打印 */
function autoPickRecommended(valid) {
  const best = valid[0];
  console.log(`已自动选择 SDK（--yes 授权，推荐序第一=最新含 kits）: ${best.path}（版本 ${sdkVersionOf(best.path)}${hasKitsDir(best.path) ? '，kits √' : '，无 kits 目录'}，来源 ${best.origin}）`);
  if (!hasKitsDir(best.path)) {
    console.warn('⚠ 所选 SDK 无 ets/kits 目录——@kit.* 聚合导入将无法展开为底层 @ohos.* 模块（建议改用含 kits 的新版本）');
  }
  return { path: resolve(best.path), apiDir: best.apiDir, confirmed: true, origin: `auto:${best.origin}` };
}

/** 非 TTY 无预设 → 询问先行（退出码 4 零产出）。指引=查找方法+参考候选+重跑通道 */
function nonTtyRequestSdkPath(valid) {
  console.error('未提供 SDK 判定源——请向开发者确认本机 OpenHarmony SDK 路径后，以 --sdk-dir <目录> 重跑（编排器：--answer sdk=<目录>）；未经确认，不产出判定。');
  printSdkLookupGuide();
  if (valid.length > 0) {
    console.error('本机探测到的参考候选（★=含 kits，可直接选用其一）：');
    valid.forEach((c, i) => {
      const mark = i === 0 ? '★' : ' ';
      console.error(`  ${mark} ${c.path}（版本 ${sdkVersionOf(c.path)}，${hasKitsDir(c.path) ? 'kits √' : '无 kits'}，来源 ${c.origin}）`);
    });
  }
  console.error('CI/自动化可 --yes 接受推荐候选；开发者确认接受单源（规则表）降级判定则以 --no-sdk 重跑（报告中将标注）。');
  return { aborted: true, reason: 'SDK 路径未经开发者确认（非交互，询问先行）' };
}

/** TTY 询问先行——先要路径；回车=浏览探测候选（兼容保留）；无效路径当场反馈纠正（连续 3 次=中止） */
async function askPathOrBrowse(valid) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    let invalid = 0;
    for (;;) {
      console.log('\n请提供本机 OpenHarmony SDK 路径（判定源——目录与版本须经开发者确认）。');
      printSdkLookupGuideTTY();
      if (valid.length > 0) {
        console.log('本机探测到的参考候选（可直接粘贴其一，回车后也可逐个浏览确认）：');
        valid.forEach((c, i) => {
          console.log(`  ${i === 0 ? '★' : ' '} ${c.path}（版本 ${sdkVersionOf(c.path)}，${hasKitsDir(c.path) ? 'kits √' : '无 kits'}）`);
        });
      }
      const answer = (await rl.question('SDK 路径（直接回车 = 浏览探测候选选择 / q = 中止）: ')).trim();
      if (answer.toLowerCase() === 'q') return { aborted: true, reason: '用户选择中止' };
      if (answer === '') {
        if (valid.length === 0) {
          console.log('（未探测到候选）直接回车 = 降级为规则表单源判定（报告中将标注）——如需降级请再按一次回车，否则输入 SDK 目录。');
          const second = (await rl.question('SDK 路径（回车 = 确认单源降级 / 输入目录 / q 中止）: ')).trim();
          if (second === '') return { degraded: true };
          if (second.toLowerCase() === 'q') return { aborted: true, reason: '用户选择中止' };
          const v2 = validateSdkDir(second);
          if (v2.ok) return { path: resolve(second), apiDir: v2.apiDir, confirmed: true, origin: 'interactive' };
          console.error(`目录无效（${v2.reason}）——请参照上方查找方法纠正后重试。`);
          invalid += 1;
          if (invalid >= 3) return { aborted: true, reason: '连续 3 次无效 SDK 路径' };
          continue;
        }
        const picked = await interactiveConfirm(valid);
        return picked.aborted ? picked : { ...picked, origin: 'interactive' };
      }
      const validation = validateSdkDir(answer);
      if (validation.ok) {
        console.log(`SDK 判定源（开发者输入）: ${resolve(answer)}（版本 ${sdkVersionOf(answer)}${hasKitsDir(answer) ? '，kits √' : '，无 kits 目录'}）`);
        return { path: resolve(answer), apiDir: validation.apiDir, confirmed: true, origin: 'interactive' };
      }
      // 格式不符及时反馈纠正——详因 + 多版本根展开提示
      invalid += 1;
      if (invalid >= 3) return { aborted: true, reason: '连续 3 次无效 SDK 路径' };
      console.error(`目录无效（${validation.reason}）。`);
      const expanded = sdkCandidatesOfRoot(answer, 'explicit');
      if (expanded.length > 0) {
        console.error(`该目录为多版本根，包含 ${expanded.length} 个版本——请指定具体版本子目录：`);
        for (const c of sortRecommended(expanded)) {
          console.error(`  ${hasKitsDir(c.path) ? '★' : ' '} ${c.path}（版本 ${sdkVersionOf(c.path)}${hasKitsDir(c.path) ? '，kits √' : '，无 kits'}）`);
        }
      } else {
        console.error('有效 SDK 目录特征：版本级目录（含 ets/api 且存在 @ohos.*.d.ts）；请参照查找方法确认路径后重试。');
      }
    }
  } catch (err) {
    return { aborted: true };
  } finally {
    rl.close();
  }
}

/** TTY 查找方法（与 printSdkLookupGuide 同款内容，走 stdout 与交互同通道） */
function printSdkLookupGuideTTY() {
  console.log('SDK 路径查找方法：');
  console.log('  · DevEco Studio：设置界面（Settings/Preferences → SDK）页面可查看本机 SDK 安装位置');
  console.log('  · 常见默认位置：macOS ~/Library/OpenHarmony/Sdk、Windows %LOCALAPPDATA%\\OpenHarmony\\Sdk');
  console.log('    （旧版华为形态：~/Library/Huawei/Sdk、%LOCALAPPDATA%\\Huawei\\Sdk；DevEco 安装目录下 sdk/ 亦可）');
  console.log('  · 有效目录特征：版本级目录（如 .../Sdk/26.0.0），其下含 ets/api 且存在 @ohos.*.d.ts');
}

/**
 * 显式预设交叉核对——无论预设来自开发者还是 agent，全量候选清单恒打印到 stderr
 * （agent 可读、开发者可见，防"塞了答案就藏住候选面"）；预设不在候选中/无 kits 均警示并给更优项。
 */
function crossCheckCandidates(explicitPath) {
  const candidates = localCandidates();
  if (candidates.length === 0) return;
  const norm = (p) => resolve(p).replace(/[\\/]+$/, '');
  const given = norm(explicitPath);
  console.error('[SDK 候选清单]（本机全量探测——供交叉核对显式指定值）');
  for (const c of candidates) {
    const mark = norm(c.path) === given ? ' ← 本次使用' : '';
    console.error(`  ${hasKitsDir(c.path) ? '★' : ' '} ${c.path} API${sdkVersionOf(c.path)} ${hasKitsDir(c.path) ? '(有kits)' : '(无kits)'}${mark}`);
  }
  if (!candidates.some((c) => norm(c.path) === given)) {
    console.error(`⚠ 显式指定的 SDK 不在探测候选清单中——请确认路径正确（本机共探测 ${candidates.length} 个候选）`);
  }
  if (!hasKitsDir(explicitPath)) {
    const withKits = candidates.filter((c) => hasKitsDir(c.path));
    if (withKits.length > 0) {
      console.error('⚠⚠ 指定的 SDK 无 ets/kits——@kit.* 聚合导入将全部无法展开（误归⑥业务决策）');
      console.error(`   建议改用含 kits 的候选：${withKits.map((c) => `${c.path}（API ${sdkVersionOf(c.path)}）`).join(' / ')}`);
    }
  }
}

/**
 * 候选呈报与确认（目录一律经开发者确认——即使仅一个候选也不默认采用）：
 * - --yes：CI 显式授权自动选择——取推荐序第一（最新含 kits），stdout 大声打印所选
 * - 非 TTY：列出全部候选（推荐项标 ★）退出码 4 零产出，请 agent 呈报开发者确认后以 --sdk-dir 重跑
 * - TTY：交互确认（默认展示推荐序第一）
 */
async function presentSdkCandidates(valid, opts, headline) {
  const best = valid[0];
  if (opts.yes) {
    console.log(`已自动选择 SDK（--yes 授权，推荐序第一=最新含 kits）: ${best.path}（版本 ${sdkVersionOf(best.path)}${hasKitsDir(best.path) ? '，kits √' : '，无 kits 目录'}，来源 ${best.origin}）`);
    if (!hasKitsDir(best.path)) {
      console.warn('⚠ 所选 SDK 无 ets/kits 目录——@kit.* 聚合导入将无法展开为底层 @ohos.* 模块（建议改用含 kits 的新版本）');
    }
    return { path: resolve(best.path), apiDir: best.apiDir, confirmed: true, origin: `auto:${best.origin}` };
  }
  if (!process.stdin.isTTY) {
 // （用户反馈：SDK 判定源必须经使用者确认——agent 驱动场景不能默默选；：单候选同样确认）
    console.error(`${headline}（未经确认，不产出判定）：`);
    valid.forEach((c, i) => {
      const mark = i === 0 ? '★' : ' ';
      const recommend = i === 0 ? ' ← 推荐（最新含 kits）' : '';
      console.error(`  ${mark} ${c.path}（版本 ${sdkVersionOf(c.path)}，${hasKitsDir(c.path) ? 'kits √' : '无 kits'}，来源 ${c.origin}）${recommend}`);
    });
    console.error('请向开发者呈报以上候选并确认后，以 --sdk-dir <目录> 重跑（编排器：--answer sdk=<目录>）；CI/自动化可 --yes 接受推荐候选。');
    return { aborted: true, reason: 'SDK 候选未经确认（非交互）' };
  }
  const picked = await interactiveConfirm(valid);
  return picked.aborted ? picked : { ...picked, origin: 'interactive' };
}

async function requestSdkOrDegrade() {
  if (!process.stdin.isTTY) {
 // 无候选同样询问先行——查找方法 + 显式降级通道（原断言短语保留：'未检出 OpenHarmony SDK 候选'/'--no-sdk'）
    console.error('未检出 OpenHarmony SDK 候选（未经确认，不产出判定）——');
    printSdkLookupGuide();
    console.error('请向开发者确认本机 SDK 路径后以 --sdk-dir <目录> 重跑（编排器：--answer sdk=<目录>）；');
    console.error('或开发者确认接受单源（规则表）降级判定后，以 --no-sdk 显式降级重跑（报告中将标注）。');
    return { aborted: true, reason: '未检出 SDK 且未获路径/降级确认（非交互）' };
  }
 // TTY：与主流程同款询问先行（无候选时回车=二次确认单源降级）
  return askPathOrBrowse([]);
}

async function interactiveConfirm(valid) {
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    let index = 0;
    for (;;) {
      const candidate = valid[index];
      const version = sdkVersionOf(candidate.path);
      console.log('\n检测到 OpenHarmony SDK:');
      console.log(`  目录: ${candidate.path}`);
      console.log(`  版本: ${version}（来源: ${candidate.origin}）`);
      const answer = (await rl.question(
        '确认使用该 SDK？[Y=确认 / n=输入其他目录 / r=切换下一个候选 / q=中止] ')).trim().toLowerCase();
      if (answer === '' || answer === 'y') {
        return { path: candidate.path, apiDir: candidate.apiDir, confirmed: true };
      }
      if (answer === 'r') {
        index = (index + 1) % valid.length;
        continue;
      }
      if (answer === 'q') {
        return { aborted: true };
      }
      const validation = validateSdkDir(answer);
      if (!validation.ok) {
        console.log(`目录无效（${validation.reason}），请重试。`);
        continue;
      }
      return { path: resolve(answer), apiDir: validation.apiDir, confirmed: true };
    }
  } catch (err) {
    return { aborted: true };
  } finally {
    rl.close();
  }
}

async function main(argv) {
  const opts = parseArgs(argv);
  if (!opts.root) {
    console.error(usage());
    process.exit(EXIT_USAGE);
  }
  const root = resolve(opts.root);
  if (!existsSync(root)) {
    console.error(`错误: 工程根目录不存在: ${root}`);
    process.exit(EXIT_USAGE);
  }
 // 缺省输出目录锚定工程根（防 CWD 漂移致产物散落）
  const outDir = resolve(opts.out || join(root, 'arkuix-scan-output'));
 // （B）：覆盖确认——已有旧产物时 TTY 询问、非 TTY 显著警示后继续（不阻断 CI）
  const prevReport = join(outDir, 'scan-report.json');
  if (existsSync(prevReport) && !opts.yes) {
    if (process.stdin.isTTY) {
      const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
      try {
        const answer = (await rl.question(
          `输出目录已有上次扫描产物（${outDir}），覆盖? [Y=覆盖 / q=中止] `)).trim().toLowerCase();
        if (answer === 'q' || answer === 'n') {
          console.error('用户中止：未覆盖既有产物（可 --out 指定新目录后重跑）。');
          process.exit(EXIT_ABORT);
        }
      } finally {
        rl.close();
      }
    } else {
      console.error(`提示: 输出目录已有上次扫描产物，本次将覆盖（${outDir}）；如需保留请 --out 指定新目录。`);
    }
  }

  const model = detectModel(root);
  let inventory = [];
  let dynamicHints = [];
  let adaptation = emptyAdaptation();
  let sdkInfo = null;
  let degraded = false;
  let rules = null;

  if (model === 'stage') {
    sdkInfo = await confirmSdk(opts);
    if (sdkInfo.aborted) {
      console.error('用户中止：未完成 SDK 确认，不产出适配判定。');
      process.exit(EXIT_ABORT);
    }
    const files = enumerateFiles(root);
    const kitsDir = sdkInfo && !sdkInfo.degraded && sdkInfo.apiDir
      ? join(sdkInfo.apiDir, '..', 'kits') : null;
    const sysrootDir = sdkInfo && !sdkInfo.degraded && sdkInfo.apiDir
      ? join(sdkInfo.apiDir, '..', '..', 'native', 'sysroot', 'usr', 'include') : null;
    ({ inventory, dynamicHints } = extractReferences(root, files, {
      kitIndex: buildKitIndex(kitsDir),
      nativeIndex: inventoryHasNative(files) ? buildNativeSymbolIndex(existsSync(sysrootDir) ? sysrootDir : null) : null
    }));
 // SDK 质量硬门——无 kits 的 SDK + 工程含 @kit.* 导入 → 全部误归⑥（39 项类事故），
 // 不再 warn 后静默继续；开发者显式确认后果（--force-no-kits）才放行
    const kitItems = inventory.filter((i) => String(i.module || '').startsWith('@kit.'));
    if (sdkInfo && !sdkInfo.degraded && sdkInfo.path && !hasKitsDir(sdkInfo.path)
      && kitItems.length > 0 && !opts.forceNoKits) {
      const withKits = localCandidates().filter((c) => hasKitsDir(c.path));
      console.error(`⚠ SDK（${sdkVersionOf(sdkInfo.path)}）无 ets/kits，但工程含 ${kitItems.length} 处 @kit.* 导入——全部将误归⑥业务决策（@kit 无法展开为底层 @ohos.* 模块）。`);
      if (withKits.length > 0) {
        console.error(`建议改用含 kits 的 SDK 候选（--sdk-dir 重跑）：${withKits.map((c) => `${c.path}（API ${sdkVersionOf(c.path)}）`).join(' / ')}`);
      } else {
        console.error('本机未探测到含 kits 的候选——请安装含 ets/kits 的 SDK（API 20+）后重跑。');
      }
      console.error('如开发者确认接受此后果（@kit.* 全部走⑥人工决策），加 --force-no-kits 显式确认后重跑。');
      process.exit(EXIT_ABORT);
    }
    rules = loadRules(opts.rules);
    let marks = null;
    if (sdkInfo && !sdkInfo.degraded) {
      try {
        marks = scanMarks(sdkInfo.apiDir);
      } catch (err) {
        console.error(`错误: ${err.message}`);
        process.exit(EXIT_INTERNAL);
      }
    } else {
      degraded = true;
    }
    ({ adaptation } = classify(inventory, rules, marks));
  }

  const scanReport = {
    schema_version: 1,
    project_model: model,
    ...((sdkInfo && !sdkInfo.degraded)
      ? { sdk: { path: sdkInfo.path, version: sdkVersionOf(sdkInfo.path), confirmed: sdkInfo.confirmed, origin: sdkInfo.origin || 'unknown' } }
      : {}),
    inventory,
    adaptation
  };

  mkdirSync(outDir, { recursive: true });
  atomicWrite(join(outDir, 'scan-report.json'), renderJson(scanReport));
  atomicWrite(join(outDir, 'migration-advice.md'), renderMarkdown(scanReport, { degraded, rules, dynamicHints }));

  if (model === 'fa') {
    console.log('FA 模型不支持，仅支持 Stage 模型；ScanReport.project_model=fa，未产出适配分类。');
    process.exit(EXIT_MODEL);
  } else if (model === 'unknown') {
    console.log('工程模型无法判定（缺 Stage/FA 工程特征）；ScanReport.project_model=unknown，未产出适配分类。');
    process.exit(EXIT_MODEL);
  } else if (degraded) {
    console.log('完成（SDK 未检出，单源判定，已在报告标注）: scan-report.json + migration-advice.md');
  } else {
    console.log(`完成（SDK: ${sdkInfo.path}，确认途径 ${sdkInfo.origin}）: scan-report.json + migration-advice.md`);
  }
  process.exit(EXIT_OK);
}

main(process.argv.slice(2)).catch((err) => {
  console.error(`内部错误: ${err.message}`);
  process.exit(EXIT_INTERNAL);
});
