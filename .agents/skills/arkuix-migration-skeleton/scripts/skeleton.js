#!/usr/bin/env node
import { existsSync, mkdirSync, writeFileSync, renameSync, readFileSync, copyFileSync, readdirSync } from 'node:fs';
import { join, relative, resolve, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import readline from 'node:readline/promises';
import { loadReport, check, rejectMessage } from './model-gate.js';
import { detectEnvironment, resolveAceBinPath, arkuiXSdkPathsFromAce, arkuiXSdkPathsFromEnv, detectOhosSdkRoot } from './env-detector.js';
import { preflight, invokeModify, resolveTimeoutMs, collectAceWarnings } from './ace-invoker.js';
import { checkOutputDir, decideOnNonEmpty, createScaffold, scaffoldPresent, resolveShells, materializeFromArchive, writeLocalProperties, readPlatformBaseline } from './scaffold.js';
import { migrateSources, verifyMigration } from './migrate.js';
import { migrateConfigs, verifyConfigMigration } from './config-migrator.js';
import { resolveVersionEntry, listSupported, highestVersionEntry, detectSourceSdkVersion, detectSourceRuntimeOS, detectSourceSdkVersions } from './sdk-versions.js';
import { snapshotProject, diffSnapshots } from './snapdiff.js';
import { renderJson, renderMarkdown, renderVerificationAssists } from './result.js';

/** CLI 退出码映射（spec  固化，跨版本稳定） */
const EXIT_OK = 0; // 正常结束：完成产出；或用户跳过（不产出，stdout 明示）
const EXIT_INTERNAL = 1; // 内部错误：未预期异常
const EXIT_USAGE = 2; // 输入无效：根目录不存在/不可读、参数非法值（含非交互模式/平台非法值）
const EXIT_MODEL = 3; // 模型拒绝：project_model=fa / ScanReport 缺失不可解析 unknown
const EXIT_ENV = 4; // 环境不满足：SDK < API 22 且模式=modify（边界）
const EXIT_TOOL = 5; // 工具失败：ace tool 非零退出或超时
const EXIT_ABORT = 6; // 用户中止：交互无效输入连续/流结束、覆盖确认中止、计划确认未 --yes

const PLATFORMS = ['both', 'android', 'ios'];
const MAX_INVALID_ATTEMPTS = 3;

function usage() {
  return [
    '用法: node scripts/skeleton.js <工程根目录> --scan-report <F2 scan-report.json> [选项]',
    '',
    '  <工程根目录>                 Stage 工程根目录（必填）',
    '  --scan-report <路径>         F2 ScanReport 路径（必填，project_model 判定输入）',
    '  --mode <modify|new>          骨架生成模式（未指定时交互引导，默认建议 modify；非交互必填）',
    '                               modify 缺省走内置归档自修改（零 ace 依赖、跨平台一致）；',
    '                               显式 --ace-modify 才调用 ace modify 工具（Windows 非 TTY 交互易崩，不推荐）',
    '  --platform <both|android|ios> 平台选项（默认 both；未指定时交互引导）',
    '  --out <目录>                 输出目录（new 模式 scaffold 落点；默认 <工程根>/arkuix-skeleton-output）',
    '  --confirm-overwrite <skip|overwrite|abort> 输出目录非空确认（非交互等价参数；非 TTY 缺省 abort）',
    '  --yes                        跳过 modify 计划改动清单确认（非 TTY 无则按用户中止，退出码 6）',
    '  --ace-bin <路径>             ace 命令路径（默认 PATH 中的 ace；buildArkTS 占位符/local.properties 推导源）',
    '  --ace-modify                 modify 模式改走 ace modify 工具路径（默认归档自修改；与 --scaffold-from 互斥）',
    '  --timeout-ms <毫秒>          ace 子进程超时阈值（默认 300000；环境变量 ARKUIX_ACE_TIMEOUT_MS 可覆盖）',
    '  --strict-crossplatform       关闭 （默认在 arkui-x-config.json5 注入 buildOption.ignoreCrossPlatform=true，',
    '                               把 11706007 跨平台不支持接口从编译错误降为警告；运行时仍需 canIUse 守卫或 Bridge 接线）',
    '  --migrate-configs <yes|no>   new 模式配置文件迁移确认（强确认门：非交互缺省=用户中止，退出码 6）；',
    '                               yes=白名单合并源工程配置进 scaffold（根 build-profile 的 signingConfigs/products、',
    '                               根与 entry oh-package 依赖、AppScope/app.json5 标量——bundleName 除外；code-linter/.gitignore',
    '                               无冲突拷贝；hvigorfile/hvigor-config/entry build-profile 恒保留模板并说明；',
    '                               含遗漏/多改双向校验，失败自动回滚）',
    '  --compile-sdk <版本>          new 模式 Compile SDK 版本（强确认门：非交互缺省=用户中止，退出码 6；ace create 同款语义）；',
    '                               值=版本键（24 / 26.0.0 …）或全形态（6.1.1(24)）；支持清单=rules/sdk-versions.json（ON 表策展）；',
    '                               产物版本六元组按所选替换（build-profile compile/compatibleSdk、hvigor-config modelVersion+插件、',
    '                               根 oh-package modelVersion；runtimeOS 与源工程同步——源显式 HarmonyOS 形态时保留并写全形态版本串，缺省 OpenHarmony）；推荐：最高 26.0.0，其次源工程版本',
    '',
    '退出码: 0=完成/跳过; 1=内部错误; 2=输入无效; 3=模型拒绝; 4=环境不满足(SDK<API22+modify); 5=工具失败; 6=用户中止'
  ].join('\n');
}

function parseArgs(argv) {
  const opts = {
    root: null, scanReport: null, mode: null, platform: null, out: null,
    confirmOverwrite: null, yes: false, aceBin: null, timeoutMs: null, aceModify: false
  };
  const positional = [];
  for (let i = 0; i < argv.length; i++) {
    const arg = argv[i];
    if (arg === '--scan-report') opts.scanReport = argv[++i];
    else if (arg === '--mode') opts.mode = argv[++i];
    else if (arg === '--platform') opts.platform = argv[++i];
    else if (arg === '--out') opts.out = argv[++i];
    else if (arg === '--confirm-overwrite') opts.confirmOverwrite = argv[++i];
    else if (arg === '--yes') opts.yes = true;
    else if (arg === '--ace-bin') opts.aceBin = argv[++i];
    else if (arg === '--modify-entry') opts.modifyEntry = argv[++i];
    else if (arg === '--scaffold-from') {
      const next = argv[i + 1];
      if (next && !next.startsWith('--')) opts.scaffoldFrom = argv[++i];
      else opts.scaffoldFrom = true; // 无值 → 内置归档 assets/scaffold-26.0.0
    }
    else if (arg === '--project-name') opts.projectName = argv[++i];
    else if (arg === '--bundle-name') opts.bundleName = argv[++i];
    else if (arg === '--ace-modify') opts.aceModify = true;
    else if (arg === '--strict-crossplatform') opts.strictCrossplatform = true;
    else if (arg === '--migrate-configs') {
      const value = argv[++i];
      if (value !== 'yes' && value !== 'no') {
        console.error(`错误: --migrate-configs 仅支持 yes/no，收到 ${value ?? '（缺值）'}`);
        process.exit(EXIT_USAGE);
      }
      opts.migrateConfigs = value;
    }
    else if (arg === '--compile-sdk') {
      const value = argv[++i];
      if (!value || value.startsWith('--')) {
        console.error('错误: --compile-sdk 缺版本值（如 --compile-sdk 24 或 --compile-sdk 26.0.0）');
        process.exit(EXIT_USAGE);
      }
      opts.compileSdk = value;
    }
    else if (arg === '--timeout-ms') {
      const value = Number(argv[++i]);
      if (!Number.isInteger(value) || value <= 0) {
        console.error(`错误: --timeout-ms 须为正整数毫秒，收到 ${argv[i]}`);
        process.exit(EXIT_USAGE);
      }
      opts.timeoutMs = value;
    }
    else if (arg === '-h' || arg === '--help') { console.log(usage()); process.exit(EXIT_OK); }
    else positional.push(arg);
  }
  opts.root = positional[0] || null;
  if (opts.mode && !['modify', 'new'].includes(opts.mode)) {
    console.error(`错误: --mode 仅支持 modify/new，收到 ${opts.mode}`);
    process.exit(EXIT_USAGE);
  }
  if (opts.platform && !PLATFORMS.includes(opts.platform)) {
    console.error(`错误: --platform 仅支持 both/android/ios，收到 ${opts.platform}`);
    process.exit(EXIT_USAGE);
  }
  if (opts.confirmOverwrite && !['skip', 'overwrite', 'abort'].includes(opts.confirmOverwrite)) {
    console.error(`错误: --confirm-overwrite 仅支持 skip/overwrite/abort，收到 ${opts.confirmOverwrite}`);
    process.exit(EXIT_USAGE);
  }
  if (opts.aceModify && opts.scaffoldFrom !== undefined) {
    console.error('错误: --ace-modify 与 --scaffold-from 互斥（前者走 ace 工具路径，后者走归档自修改）');
    process.exit(EXIT_USAGE);
  }
  return opts;
}

/** ：迁入后回写 build-profile 注册各模块（宽松 JSON5 解析 + 保序写入） */
function registerModules(outDir, modules) {
  if (!modules || modules.length === 0) return;
  const bpPath = join(outDir, 'build-profile.json5');
  if (!existsSync(bpPath)) {
 // scaffold 未自带 build-profile（mock 或旧版 ace）→ 创建基础骨架并注册全部模块
    const skeleton = { app: { products: [{ name: 'default' }] },
      modules: modules.map((m) => ({ name: m.name, srcPath: `./${m.name}` })) };
    atomicWrite(bpPath, JSON.stringify(skeleton, null, 2) + '\n');
    console.log(`已创建 build-profile.json5 并注册 ${modules.length} 个迁入模块`);
    return;
  }
  try {
    const doc = JSON.parse(looseParseBuildProfile(readFileSync(bpPath, 'utf8')));
    const existing = new Set((doc.modules ?? []).map((m) => m.srcPath));
 // 新增清单与计数同源（计数与括号内模块名一致）；
 // 注册项补 targets（与 scaffold 自带 entry 形态对称）
    const added = [];
    for (const mod of modules) {
      const srcPath = `./${mod.name}`;
      if (!existing.has(srcPath)) {
        (doc.modules ??= []).push({ name: mod.name, srcPath,
          targets: [{ name: 'default', applyToProducts: ['default'] }] });
        added.push(mod.name);
      }
    }
    if (added.length > 0) {
      atomicWrite(bpPath, JSON.stringify(doc, null, 2) + '\n');
      console.log(`build-profile.json5 已注册 ${added.length} 个迁入模块（${added.join('、')}）`);
    }
  } catch (err) {
    console.error(`警告: build-profile 注册回写失败（${err.message}）——产出工程需手动注册各模块`);
  }
}

/** N1：多模块装配——moduleLists/arkui-x-config/entry 依赖三处补全（原样 scaffold 语义之外的最小注入，均带  标注） */
export function assembleModules(outDir, modules, opts = {}) {
 //har 模块不写入 moduleLists（无独立 res/default/resources 产物→ace 打包 ENOENT 崩溃）；
 // har 经 entry 的 file: 依赖进编译图（ohpm 解析），moduleLists 只列 hap/feature 类可独立编译的模块
  const hars = new Set();
  for (const m of modules ?? []) {
 // ：har 类型同时查 build-profile.json5 和 src/main/module.json5（实际声明位置）
    const name = m.target ?? m.name;
    for (const bpPath of [join(outDir, name, 'build-profile.json5'), join(outDir, name, 'src', 'main', 'module.json5')]) {
      if (!existsSync(bpPath)) continue;
      try {
        const raw = readFileSync(bpPath, 'utf8')
          .replace(/\/\*[\s\S]*?\*\//g, '')
          .replace(/(^|[,{\s])("(?:[^"\\]|\\.)*")\s*:/g, '$1$2:')
          .replace(/(^|,)\s*([A-Za-z_$][\w$]*)\s*:/g, '$1"$2":')
          .replace(/,\s*([}\]])/g, '$1');
        const bp = JSON.parse(raw);
        if (bp?.module?.type === 'har' || bp?.type === 'har') { hars.add(name); break; }
      } catch { /* 解析失败保守不过滤 */ }
    }
  }
  const names = (modules ?? []).map((m) => m.target ?? m.name).filter((n) => n !== 'entry' && !hars.has(n));
  const harNames = [...hars];
  if (harNames.length > 0) console.log(`har 模块 ${harNames.join('、')} 不入 moduleLists（经 entry file: 依赖进编译图）`);
 //F2 误报类 11706007（can't support crossplatform）降级为编译警告——
 // 默认开启（迁移首要目标=编译绿+出包），--strict-crossplatform 恢复严格错误；置于 names 早退前（单模块工程同样注入）。
 // 语义：仅不拦编译；运行时 Android/iOS 上这些 API 仍不可用，需 canIUse 守卫或 F3 Bridge 接线（报告已同步提示）。
  const cfg = join(outDir, '.arkui-x/arkui-x-config.json5');
  if (existsSync(cfg) && !opts.strictCrossplatform && !readFileSync(cfg, 'utf8').includes('ignoreCrossPlatform')) {
    const t2 = readFileSync(cfg, 'utf8').replace(/}\s*$/, (m0) => `,
  "buildOption": {
    "ignoreCrossPlatform": true // 11706007 降警告（--strict-crossplatform 可关闭）
  }
${m0}`);
    writeFileSync(cfg, t2, 'utf8');
    console.log('已开启 ignoreCrossPlatform（跨平台不支持接口降级为警告；运行时仍需守卫/桥接）');
  }
  if (names.length === 0) return;
  const list = ['entry', ...names].join(',');
  for (const rel of ['.arkui-x/android/buildArkTS', '.arkui-x/android/buildArkTS.bat', '.arkui-x/ios/buildArkTS.sh']) {
    const f = join(outDir, rel);
    if (!existsSync(f)) continue;
    let t = readFileSync(f, 'utf8');
    t = t.replace(/(set\s+)?moduleLists=entry\b/, (m0, setPfx) =>
      `${setPfx ?? ''}moduleLists=${list} # 多模块装配`); //单次替换防 bat 双重
    writeFileSync(f, t, 'utf8');
  }
  if (existsSync(cfg)) {
    let t = readFileSync(cfg, 'utf8');
    if (t.includes('"modules"')) {
      t = t.replace(/"modules"\s*:\s*\[\s*"entry"\s*\]/, `"modules": [\n    ${['entry', ...names].map((n) => `"${n}"`).join(',\n    ')}\n  ]`);
      writeFileSync(cfg, t, 'utf8');
    }
  }
  const entryPkg = join(outDir, 'entry/oh-package.json5');
  if (existsSync(entryPkg)) {
    const deps = Object.fromEntries(names.map((n) => [n, `file:../${n}`]));
    let t = readFileSync(entryPkg, 'utf8');
    t = t.replace(/"dependencies"\s*:\s*\{[^}]*\}/, `"dependencies": ${JSON.stringify(deps, null, 2).slice(1, -1).split('\n').map((l,i)=>i?l:l+' ').join('\n')} `.trim() ? t.replace(/"dependencies"\s*:\s*\{[^}]*\}/, `"dependencies": ${JSON.stringify(deps)}`) : t);
 // 上行三元的复杂写法简化：直接替换
    t = readFileSync(entryPkg, 'utf8').replace(/"dependencies"\s*:\s*\{[^}]*\}/, `"dependencies": ${JSON.stringify(deps)}`);
    writeFileSync(entryPkg, t, 'utf8');
  }
  console.log(`已装配 ${names.length} 个业务模块进编译集（moduleLists=${list}；entry 依赖 file:../ 注入）`);
}

/** 宽松解析（复用 migrate.js 同思路：剥注释+无引号键+尾逗号） */
function looseParseBuildProfile(text) {
  return text
    .replace(/\/\*[\s\S]*?\*\//g, '') // 块注释
    .replace(/\/\/.*$/gm, '') // 行注释
    .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3')
    .replace(/'([^'\\]*)'/g, '"$1"')
    .replace(/,(\s*[}\]])/g, '$1');
}

function atomicWrite(file, content) {
  const tmp = `${file}.tmp-${process.pid}`;
  writeFileSync(tmp, content, 'utf8');
  renameSync(tmp, file);
}

/** 交互询问循环骨架：无效应答提示并重新询问，连续 MAX_INVALID_ATTEMPTS 次或流结束 → 用户中止（码 6） */
async function askLoop(rl, question, normalize) {
  let invalid = 0;
  for (;;) {
    let answer;
    try {
      answer = await rl.question(question);
    } catch {
      return { aborted: true, reason: '输入流结束' };
    }
    if (answer === null) return { aborted: true, reason: '输入流结束' };
    const decision = normalize(answer);
    if (decision === 'abort') return { aborted: true, reason: '用户选择中止' };
    if (decision === null) {
      invalid += 1;
      if (invalid >= MAX_INVALID_ATTEMPTS) {
        return { aborted: true, reason: `连续 ${MAX_INVALID_ATTEMPTS} 次无效输入` };
      }
      console.log('输入无效，请按提示重新输入。');
      continue;
    }
    return { value: decision };
  }
}

async function resolveMode(opts) {
  if (opts.mode) return opts.mode;
  if (opts.yes) return 'modify'; // F1-Q1：默认建议 modify（改动小）
  if (!process.stdin.isTTY) {
    console.error('未指定 --mode 且当前为非交互环境；请显式指定 --mode modify 或 --mode new（默认建议 modify，改动小）。');
    process.exit(EXIT_USAGE);
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      '选择骨架生成模式 [M=modify（默认建议，就地改造原工程）/ n=new（新建 scaffold 迁入源码）] ',
      (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === '' || a === 'm') return 'modify';
        if (a === 'n') return 'new';
        if (a === 'q') return 'abort';
        return null;
      });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：未开始任何生成动作，零写操作。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

/**  平台选项引导（默认 both；非交互缺省 both） */
async function resolvePlatform(opts) {
  if (opts.platform) return opts.platform;
  if (!process.stdin.isTTY) return 'both';
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      '选择平台选项 [B=双平台（默认） / a=仅 Android / i=仅 iOS] ',
      (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === '' || a === 'b') return 'both';
        if (a === 'a') return 'android';
        if (a === 'i') return 'ios';
        if (a === 'q') return 'abort';
        return null;
      });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：未开始任何生成动作，零写操作。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

/** ：modify 计划改动清单确认（TTY 交互；非 TTY 需 --yes，无则按用户中止，码 6） */
async function confirmPlanChanges(plan, opts) {
  console.log('将以 modify 模式执行以下改动（执行前确认）：');
  for (const line of plan) console.log(`  - ${line}`);
  if (opts.yes) {
    console.log('（--yes：跳过确认）');
    return;
  }
  if (!process.stdin.isTTY) {
    console.error('非交互环境执行 modify 需 --yes 跳过计划改动清单确认（未提供则按用户中止，退出码 6）。');
    process.exit(EXIT_ABORT);
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl, '确认执行以上改动？[Y=继续 / q=中止] ', (answer) => {
      const a = answer.trim().toLowerCase();
      if (a === '' || a === 'y') return 'go';
      if (a === 'q' || a === 'n') return 'abort';
      return null;
    });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：零写操作。`);
      process.exit(EXIT_ABORT);
    }
  } finally {
    rl.close();
  }
}

/**
 * ：F2 分类结果逐桶确认（风险序 unknown→①；TTY 逐桶 y/a/n；非 TTY 需 --yes）。
 * 每非空桶展示计数 + Top3 条目摘要；y=确认本桶 / a=剩余全部确认 / n|q=中止（码 6，零写）。
 */
const BUCKET_RISK_ORDER = [
  ['unknown', '⑦ unknown（待人工确认）'],
  ['business_decision', '⑥ 业务决策（business_decision）'],
  ['reduced_direct', '② 有损直用（reduced_direct）'],
  ['degraded_bridge', '④ 降级桥接（degraded_bridge）'],
  ['equivalent_bridge', '③ 等价桥接（equivalent_bridge）'],
  ['platform_trim', '⑤ 平台裁剪（platform_trim）'],
  ['full_direct', '① 完整直用（full_direct）']
];

export async function confirmScanBuckets(doc, scanReportPath, opts = {}, io = {}) {
  const adaptation = (doc && doc.adaptation) || {};
  const advicePath = String(scanReportPath || '').replace(/scan-report\.json$/, 'migration-advice.md');
  const counts = BUCKET_RISK_ORDER.map(([b]) => (adaptation[b] || []).length);
  console.log('── F2 扫描结果确认 ──');
  console.log(BUCKET_RISK_ORDER.map(([b, label], i) => `${label} ${counts[i]}`).join(' | '));
  if (advicePath) console.log(`完整清单: ${advicePath}`);

  if (opts.yes) {
    console.log('（--yes：跳过逐桶确认）');
    return 'ok';
  }
  const isTTY = io.isTTY !== undefined ? io.isTTY : process.stdin.isTTY;
  if (!isTTY) {
 //  交互序修正：非 TTY 未确认（--yes）→ 零产出退出（与  SDK 确认同款强制）——
 // agent 须将 migration-advice.md 分类结论呈报用户确认后带 --yes 重跑；分类是迁移决策的根基，不可默默继续。
 // 方案1（呈报块）：随退出输出预格式化逐桶呈报材料，agent 应整块转述（逐桶读给用户/贴给用户）后收集确认
    console.error('F2 分类结果未经确认（非交互环境）。请将以下呈报块完整转述给用户确认'
      + '（逐桶读出/粘贴，收集确认或异议），确认后以 --yes 重跑本命令；TTY 环境将逐桶交互确认。未确认不执行任何生成动作。');
    console.error('\n===== F2 分类结果呈报块（风险序，请逐桶向用户确认）=====');
    for (const [bucket, label] of BUCKET_RISK_ORDER) {
      const items = (adaptation[bucket] || []);
      console.error(`\n【${label}】共 ${items.length} 条`);
      for (const it of items.slice(0, 3)) {
        console.error(`  - ${it.module} → ${it.symbol}：${String(it.reason || '').slice(0, 60)}`);
      }
      if (items.length > 3) console.error(`  - ……其余 ${items.length - 3} 条见 ${advicePath || 'migration-advice.md'}`);
      if (items.length === 0) console.error('  （空）');
    }
    console.error('\n===== 呈报块结束 =====');
    process.exit(EXIT_ABORT);
  }
  const rl = io.readline || readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    let total = 0;
    for (let i = 0; i < BUCKET_RISK_ORDER.length; i++) {
      const [bucket, label] = BUCKET_RISK_ORDER[i];
      const items = adaptation[bucket] || [];
      if (items.length === 0) continue;
      total += 1;
      console.log(`\n（${total}）${label}，共 ${items.length} 条，示例：`);
      for (const it of items.slice(0, 3)) {
        const reason = String(it.reason || '').slice(0, 48);
        console.log(`    ${it.module} → ${it.symbol}   ${reason}`);
      }
      if (items.length > 3) console.log(`    …等 ${items.length - 3} 条见完整清单`);
      const result = await askLoop(rl, '本桶确认? [y=确认 / a=剩余全部确认 / n=中止复核] ', (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === '' || a === 'y') return 'yes';
        if (a === 'a') return 'all';
        if (a === 'n' || a === 'q') return 'abort';
        return null;
      });
      if (result.aborted) {
        console.error(`用户中止（${result.reason}）：请复核 ${advicePath || 'F2 报告'} 后重跑本命令。零写操作。`);
        process.exit(EXIT_ABORT);
      }
      if (result.value === 'all') {
        console.log('（剩余桶全部确认）');
        return 'ok';
      }
    }
    return 'ok';
  } finally {
    rl.close();
  }
}

/** new 模式配置迁移确认（强确认门——不代答）。TTY 询问（默认不合并）；
 * 非 TTY 必须显式 --migrate-configs <yes|no>，缺失=用户中止（码 6，零写）。
 * io 注入（单测）：{isTTY, readline}。 */
export async function resolveMigrateConfigs(opts, io = {}) {
  if (opts.migrateConfigs === 'yes' || opts.migrateConfigs === 'no') return opts.migrateConfigs;
  const isTTY = io.isTTY !== undefined ? io.isTTY : process.stdin.isTTY;
  if (!isTTY) {
    console.error('new 模式需显式确认是否迁移源工程配置文件（未确认不执行任何生成动作）。');
    console.error('请以 --migrate-configs <yes|no> 重跑（编排器：--answer migrate_configs=yes|no）：');
    console.error('  yes = 白名单合并源工程配置进 scaffold（根 build-profile 的 signingConfigs/products、根与 entry 的');
    console.error('        oh-package 依赖、AppScope/app.json5 标量——bundleName 除外；code-linter/.gitignore 无冲突拷贝；');
    console.error('        hvigorfile/hvigor-config/entry build-profile 恒保留模板并说明；含遗漏/多改双向校验，失败自动回滚）');
    console.error('  no  = 维持现状（scaffold 模板配置，仅注册迁入模块）');
    process.exit(EXIT_ABORT);
  }
  const rl = io.readline || readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      '选择是否将源工程配置文件合并迁入 scaffold [N=不合并（默认） / y=合并 / q=中止] ',
      (answer) => {
        const a = answer.trim().toLowerCase();
        if (a === 'y') return 'yes';
        if (a === '' || a === 'n') return 'no';
        if (a === 'q') return 'abort';
        return null;
      });
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：未开始任何生成动作，零写操作。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

/** Compile SDK 版本强确认门（new 模式必答——开发者自选；推荐序：★最高版本优先，◆其次源工程版本）。
 * 显式 --compile-sdk 直通（值经 resolveVersionEntry 解析：版本键或全形态）；非 TTY 缺参=用户中止
 * （码 6 零写，不代答——与 migrate-configs 同款强门语义）；TTY 交互询问（回车=最高；编号/版本键；
 * 连续 3 次无效=中止）。io 注入（单测）：{isTTY, readline}。返回 sdk-versions 表条目。 */
export async function resolveCompileSdk(opts, srcRoot, io = {}) {
  const supported = listSupported();
  const highest = highestVersionEntry();
  const srcEntry = detectSourceSdkVersion(srcRoot);
  if (opts.compileSdk) {
    const entry = resolveVersionEntry(opts.compileSdk);
    if (!entry) {
      console.error(`错误: --compile-sdk 未收录：${opts.compileSdk}`);
      console.error(`支持版本：${supported.map((v) => v.key).join(' / ')}`);
      process.exit(EXIT_USAGE);
    }
    return entry;
  }
  const isTTY = io.isTTY !== undefined ? io.isTTY : process.stdin.isTTY;
  if (!isTTY) {
    console.error('new 模式需显式确认 Compile SDK 版本（scaffold 编译基线；未确认不执行任何生成动作）。');
    console.error(`支持版本：${supported.map((v) => v.key).join(' / ')}`);
    console.error(`推荐：★ 最高 ${highest.key}（内置归档验证形态）${srcEntry ? `；◆ 或源工程版本 ${srcEntry.key}（源 build-profile 实测 ${srcEntry.compileSdkVersion}）` : ''}`);
    console.error(`请以 --compile-sdk <版本> 重跑（如 --compile-sdk ${highest.key}${srcEntry ? ` 或 --compile-sdk ${srcEntry.key}` : ''}；编排器：--answer compile_sdk=<版本>）`);
    process.exit(EXIT_ABORT);
  }
  const rl = io.readline || readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    console.log('\n选择 Compile SDK 版本（scaffold 编译基线；ace create 同款语义）：');
    supported.forEach((v, i) => {
      const mark = v.key === highest.key ? '★' : (srcEntry && v.key === srcEntry.key ? '◆' : ' ');
      const note = v.key === highest.key ? '（默认/回车——最高版本）' : (srcEntry && v.key === srcEntry.key ? '（源工程版本）' : '');
      console.log(`  ${mark} ${i + 1}. ${v.key}（compileSdk ${v.compileSdkVersion}）${note}`);
    });
    let invalid = 0;
    for (;;) {
      let answer;
      try {
        answer = (await rl.question('版本 [回车=最高 / 编号或版本键 / q=中止]: ')).trim();
      } catch {
        console.error('用户中止（输入流结束）：零写操作。');
        process.exit(EXIT_ABORT);
      }
      if (answer === '') return highest;
      if (answer.toLowerCase() === 'q') {
        console.error('用户中止：未开始任何生成动作，零写操作。');
        process.exit(EXIT_ABORT);
      }
      const byIndex = /^\d+$/.test(answer) ? supported[Number(answer) - 1] : undefined;
      const entry = byIndex ?? resolveVersionEntry(answer);
      if (entry) {
        console.log(`Compile SDK（开发者选择）: ${entry.key}（compileSdk ${entry.compileSdkVersion}）`);
        return entry;
      }
      invalid += 1;
      if (invalid >= 3) {
        console.error('连续 3 次无效版本输入，中止：零写操作。');
        process.exit(EXIT_ABORT);
      }
      console.error(`无效版本：${answer}——请输入编号（1-${supported.length}）或版本键（如 24 / 26.0.0）`);
    }
  } finally {
    rl.close();
  }
}

/** ：非空目录确认（跳过/覆盖/中止）；确认前零产出。跳过=退出码 0（stdout 明示）；中止=码 6 */async function confirmNonEmpty(outDir, opts) {
  const state = checkOutputDir(outDir);
  if (!state.exists || !state.nonEmpty) return 'overwrite';
  if (opts.confirmOverwrite) return opts.confirmOverwrite;
  if (opts.yes) return 'overwrite';
  if (!process.stdin.isTTY) {
    console.error(`输出目录已存在且非空: ${outDir}；非交互环境缺省按中止处理（可使用 --confirm-overwrite overwrite/skip 或 --yes）。`);
    return 'abort';
  }
  const rl = readline.createInterface({ input: process.stdin, output: process.stdout });
  try {
    const result = await askLoop(rl,
      `输出目录已存在且非空: ${outDir}\n选择策略 [s=跳过(零变更结束) / y=覆盖 / q=中止] `,
      (answer) => decideOnNonEmpty(answer));
    if (result.aborted) {
      console.error(`用户中止（${result.reason}）：确认前未产出任何新文件。`);
      process.exit(EXIT_ABORT);
    }
    return result.value;
  } finally {
    rl.close();
  }
}

async function main(argv) {
  const opts = parseArgs(argv);
  if (!opts.root || !opts.scanReport) {
    console.error(usage());
    process.exit(EXIT_USAGE);
  }
  const root = resolve(opts.root);
  if (!existsSync(root)) {
    console.error(`错误: 工程根目录不存在: ${root}`);
    process.exit(EXIT_USAGE);
  }
 // --compile-sdk 值早校验（未收录即码 2，先于任何交互）
  if (opts.compileSdk !== undefined && !resolveVersionEntry(opts.compileSdk)) {
    console.error(`错误: --compile-sdk 未收录：${opts.compileSdk}`);
    console.error(`支持版本：${listSupported().map((v) => v.key).join(' / ')}`);
    process.exit(EXIT_USAGE);
  }
 // ScanReport 存在性/可解析性由 ModelGate 统一判定（缺失也走引导 F2 路径）

 // ：模型前置（——任何写操作之前；退出码 3）
  const scanReport = loadReport(resolve(opts.scanReport));
  const gate = check(scanReport);
  if (gate.verdict !== 'pass') {
    console.error(rejectMessage(gate));
    process.exit(EXIT_MODEL);
  }

 // ：环境检测（不阻断；arkui_x_sdk 检出供 modify 门槛判定）
  const environment = detectEnvironment(opts.aceBin ? { aceBin: opts.aceBin } : {});

 // 参数硬校验（先于任何交互/确认）：非 TTY 缺 --mode（且无 --yes 缺省豁免）→ 码 2（语义保持）
  if (!opts.mode && !opts.yes && !process.stdin.isTTY) {
    console.error('未指定 --mode 且当前为非交互环境；请显式指定 --mode modify 或 --mode new（默认建议 modify，改动小）。');
    process.exit(EXIT_USAGE);
  }

 // （交互序修正，用户反馈）：F2 分类结果逐桶确认——必须在骨架生成方式（mode/platform）询问**之前**，
 // 正确决策链 = SDK 确认（F2）→ 分类确认 → 骨架生成方式 → 执行；非 TTY 未确认（--yes）即停（与  同款强制）
  await confirmScanBuckets(scanReport.doc, resolve(opts.scanReport), opts);

 // 交互定序：模式 → 平台 →（new）配置迁移确认 →（new）Compile SDK 版本确认 →（new）目录确认 → 生成
  const mode = await resolveMode(opts);
  const platform = await resolvePlatform(opts);
 // --migrate-configs 仅适用 new（modify 就地改造不动工程构建配置）；new 模式强确认门
  if (opts.migrateConfigs !== undefined && mode === 'modify') {
    console.error('错误: --migrate-configs 仅适用于 new 模式（modify 就地改造不动工程构建配置）。');
    process.exit(EXIT_USAGE);
  }
  const migrateConfigsDecision = mode === 'new' ? await resolveMigrateConfigs(opts) : null;
 // Compile SDK 版本：仅适用 new；与 --scaffold-from <显式目录> 互斥（自定义归档自带版本不做替换）；
 // 非显式归档/ace create 路径均走强确认门（内置归档做六元组替换；ace create 按菜单编号喂答）
  if (opts.compileSdk !== undefined && mode === 'modify') {
    console.error('错误: --compile-sdk 仅适用于 new 模式（modify 就地改造保留源工程自身版本）。');
    process.exit(EXIT_USAGE);
  }
  if (opts.compileSdk !== undefined && typeof opts.scaffoldFrom === 'string') {
    console.error('错误: --compile-sdk 与 --scaffold-from <显式目录> 互斥（自定义归档自带版本，不做替换）。');
    process.exit(EXIT_USAGE);
  }
  const compileSdkEntry = (mode === 'new' && typeof opts.scaffoldFrom !== 'string')
    ? await resolveCompileSdk(opts, root)
    : null;

  // ：幂等重跑前置——已 modify 工程无需 ace（先于 SDK 门槛判定）
  const alreadyModifiedPre = mode === 'modify' && existsSync(join(root, '.arkui-x', 'arkui-x-config.json5'));

  // modify 路径选择：归档自修改为默认（零 ace 依赖、Windows 非 TTY 不再踩 ace 交互崩溃）；
  // 显式 --ace-modify 才走 ace 工具路径
  const builtinArchive = join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'scaffold-26.0.0');
  const useAceModify = mode === 'modify' && opts.aceModify === true;
  const modifyArchiveDir = useAceModify ? null
    : (opts.scaffoldFrom === undefined || opts.scaffoldFrom === true) ? builtinArchive : opts.scaffoldFrom;

  //  边界：ace modify 工具路径需 SDK API 24+（归档自修改不依赖 ace，不受此门槛；幂等重跑豁免）
  if (useAceModify && !alreadyModifiedPre && !environment.arkui_x_sdk.modify_available) {
    const detected = environment.arkui_x_sdk.detected
      ? `检出版本 ${environment.arkui_x_sdk.version || '未知'}`
      : '未检出 ArkUI-X SDK（ace tool 不在 PATH）';
    console.error(`ArkUI-X SDK 版本低于 API 22，ace modify 不可用（${detected}）。建议：升级 ArkUI-X SDK 至 API 22+，或改用 new 模式（--mode new）。`);
    process.exit(EXIT_ENV);
  }

 // 缺省输出目录锚定工程根（防 CWD 漂移致产物散落）
  const outDir = resolve(opts.out || join(root, 'arkuix-skeleton-output'));
 // （B）：modify 报告覆盖警示（new 模式的目录确认由  confirmNonEmpty 管）
  if (mode === 'modify' && existsSync(join(outDir, 'skeleton-result.json'))) {
    console.log(`提示: 输出目录已有上次产物，本次将覆盖（${outDir}）；如需保留请 --out 指定新目录。`);
  }
  const timeoutMs = resolveTimeoutMs(opts.timeoutMs);

  let artifacts;
  let migration = null;
  let changedFiles = [];
  let aceWarnings = []; // ：ace WARN 级提示沉淀（report/result，编译前必办）
  let resultBaseDir = root; // 壳相对路径基准（modify=工程根；new=输出目录）
  let configMigration = null; // new 模式配置迁移决策与结果（config_migration 契约字段）

  if (mode === 'modify') {
  // 前置：工程完整性（design 代码事实 3）
    const pf = preflight(root);
    if (!pf.ok) {
      console.error(`工程不完整（缺 ${pf.missing.join('、')}），modify 将拒绝执行；请补全 Stage 工程构建配置后重试，或改用 --mode new。`);
      process.exit(EXIT_USAGE);
    }
  // ：幂等重跑——.arkui-x/arkui-x-config.json5 在场 = 已 modify，跳过注入
  // （同时消除实测发现的"已 modify 工程重跑挂起"触发路径）
    const alreadyModified = alreadyModifiedPre;
    if (alreadyModified) {
      console.log('检测到工程已 modify（.arkui-x/arkui-x-config.json5 在场），跳过注入（幂等重跑）。');
      const shells = resolveShells(root);
      const wantAndroid = platform === 'both' || platform === 'android';
      const wantIos = platform === 'both' || platform === 'ios';
      if ((wantAndroid && !existsSync(shells.android)) || (wantIos && !existsSync(shells.ios))) {
        console.error(`已 modify 工程缺少所选平台壳（platform=${platform}）；如需补齐请先移除 .arkui-x/ 后重跑。`);
        process.exit(EXIT_TOOL);
      }
 // ：幂等路径无 ace stdout → 静态复核已知必办项（build-profile 含 useNormalizedOHMUrl 即补）
      aceWarnings = collectAceWarnings('', '', root);
    } else {
  //  Scope Guard：计划改动清单确认对归档/ace 两路径一致生效——
  // 归档注入同样是就地改写原工程，非 TTY 无 --yes 按用户中止（码 6 零写）
      const platformLabel = { both: '双平台（Default(Android, iOS)，应答 1）', android: '仅 Android（应答 2）', ios: '仅 iOS（应答 3）' }[platform];
      const plannedDirs = platform === 'both' ? '.arkui-x/android/ 与 .arkui-x/ios/' : (platform === 'android' ? '.arkui-x/android/' : '.arkui-x/ios/');
      await confirmPlanChanges([
        useAceModify
          ? `调用 ace modify --project（平台选项: ${platformLabel}）`
          : `从${modifyArchiveDir === builtinArchive ? '内置' : '指定'}归档确定性注入跨平台壳（零 ace 交互、跨平台一致）`,
        `在原工程注入 ${plannedDirs}（模板展开与工程配置注入项；改写各模块 hvigorfile 与 hvigor-config 插件依赖）`,
        '原工程结构与 entry 源码保留（就地改造，不做源码内容改写）'
      ], opts);
  // 路径选择：默认归档自修改（modifyArchiveDir 已在模式判定区解析）；
  // --ace-modify 显式走 ace 工具（保留与官方工具产物的对齐验证/逃生通道）
      if (!useAceModify) {
        const snapBefore = snapshotProject(root);
  // ：buildArkTS 占位符/local.properties 推导——解析 PATH 中的真实 ace 路径，
  // 显式 --ace-bin 优先；ARKUIX_SDK_DIR 仅接受 ArkUI-X SDK 形态（防 OH SDK 语义误用）
        const { arkuiXSdkPath, arkuiXSdkRoot, ohosSdkRoot } = resolveSdkPathsForInject(opts);
        const modResult = modifyFromArchive(root, modifyArchiveDir, {
          platform, projectName: opts.projectName, bundleName: opts.bundleName,
          arkuiXSdkPath, arkuiXSdkRoot, ohosSdkRoot
        });
        changedFiles = diffSnapshots(snapBefore, snapshotProject(root));
        if (!modResult.ok) {
          console.error(`失败：${modResult.reason}`);
          process.exit(EXIT_TOOL);
        }
        console.log(`已从归档注入跨平台壳（零 ace 交互）：${modResult.filesCopied} 文件，${modResult.modulesRewired} 个模块 hvigorfile 改写`);
        if (changedFiles.length) {
          console.log(`实际改动文件清单（+ 新增 / ~ 改写 / - 删除）：\n${changedFiles.map((f) => `  - ${f}`).join('\n')}`);
        }
        for (const note of modResult.envNote || []) console.log(`标注：${note}`);
  // ：归档路径无 ace stdout → 静态复核已知必办项（build-profile 含 useNormalizedOHMUrl 即补）
        aceWarnings = collectAceWarnings('', '', root);
      } else {
      const snapBefore = snapshotProject(root); // ：全工程前后快照 diff
      const invocation = invokeModify(root, { aceBin: opts.aceBin, timeoutMs, platform, modifyEntry: opts.modifyEntry });
      changedFiles = diffSnapshots(snapBefore, snapshotProject(root));
      if (!invocation.ok) {
        console.error(`失败：${invocation.reason}`);
        if (changedFiles.length) {
          console.error(`实际改动文件清单（保留供排查，不自动回滚；建议以工程版本控制还原）：\n${changedFiles.map((f) => `  - ${f}`).join('\n')}`);
        }
        console.error('建议改用 new 模式（--mode new：新建跨平台空工程后迁入源码）。');
    console.error(`
┌─ 下一步建议 ─────────────────────────────────────┐
│ A. 在 TTY 终端重跑本命令（多模块时自动透传交互）        │
│ B. 改用 new 模式：                                     │
│    node scripts/skeleton.js <工程> --scan-report <F2产物> --mode new --yes │
│ C. 手动执行 ace 后重跑（幂等跳过 ace 调用）：            │
│    ace modify --project  （在工程根目录下执行）           │
└─────────────────────────────────────────────────┘`);
        process.exit(EXIT_TOOL);
      }
      if (changedFiles.length) {
        console.log(`实际改动文件清单（+ 新增 / ~ 改写 / - 删除）：\n${changedFiles.map((f) => `  - ${f}`).join('\n')}`);
      }
 // ：成功路径沉淀 ace WARN（stdout 提取 + 静态复核兜底）
      aceWarnings = collectAceWarnings(invocation.stdout, invocation.stderr, root);
      } // 关闭 ace modify else 分支
      } // 关闭归档/ace 选择分支
 //modify 模式同样注入 ——
 // ace modify 创建的 `.arkui-x/arkui-x-config.json5` 不含 buildOption.ignoreCrossPlatform，
 // 导致②有损直用项 11706007 以 error 阻断编译（new 模式经 assembleModules 注入，modify 此前漏注入）
    {
      const cfg = join(root, '.arkui-x', 'arkui-x-config.json5');
      if (existsSync(cfg) && !opts.strictCrossplatform && !readFileSync(cfg, 'utf8').includes('ignoreCrossPlatform')) {
        const t2 = readFileSync(cfg, 'utf8').replace(/}\s*$/, (m0) => `,
  "buildOption": {
    "ignoreCrossPlatform": true
  }
${m0}`);
        writeFileSync(cfg, t2, 'utf8');
        console.log('modify 模式已注入 ignoreCrossPlatform（跨平台不支持接口降级为警告）');
      }
    }
    artifacts = {
      androidShell: '.arkui-x/android',
      iosShell: '.arkui-x/ios',
      sharedArktsDir: existsSync(join(root, 'entry')) ? 'entry' : '.'
    };
  } else {
 // ：非空确认（跳过=退出码 0；中止=码 6）
    const decision = await confirmNonEmpty(outDir, opts);
    if (decision === 'skip') {
      console.log('已跳过本次骨架生成');
      process.exit(EXIT_OK);
    }
    if (decision === 'abort') {
      console.error('用户中止：确认前未产出任何新文件。');
      process.exit(EXIT_ABORT);
    }
 //  根治：--scaffold-from 归档物化（零交互、确定性）优先于 ace create
    const archiveDir = opts.scaffoldFrom === true ? join(dirname(fileURLToPath(import.meta.url)), '..', 'assets', 'scaffold-26.0.0') : opts.scaffoldFrom;
    let scaffold;
    if (archiveDir) {
  // ：占位符推导统一走 resolveSdkPathsForInject（PATH 解析 ace，不再只认显式 --ace-bin）
      const { arkuiXSdkPath, arkuiXSdkRoot, ohosSdkRoot } = resolveSdkPathsForInject(opts);
      scaffold = materializeFromArchive(archiveDir, outDir, {
        name: opts.projectName, bundle: opts.bundleName, platform,
        arkuiXSdkPath, arkuiXSdkRoot, ohosSdkRoot,
        sdkVersion: compileSdkEntry ?? undefined, // Compile SDK 版本六元组替换（缺省=归档固有 26.0.0）
        runtimeOS: detectSourceRuntimeOS(root) ?? undefined, // 运行时形态与源工程同步（显式 HarmonyOS 形态保留；缺省 OpenHarmony）
        sourceSdkVersions: detectSourceSdkVersions(root), // 源版本三元组原始值（compatible/target 保留+钳制语义的数据源）
      });
      if (!scaffold.ok) {
        console.error(`失败：${scaffold.reason}`);
        process.exit(EXIT_TOOL);
      }
      console.log(`已从归档 scaffold 物化（零交互，Compile SDK ${compileSdkEntry?.key ?? '26.0.0'}）：${archiveDir}`);
      for (const note of scaffold.envNote || []) console.log(`标注：${note}`);
    } else {
      scaffold = createScaffold(outDir, { aceBin: opts.aceBin, timeoutMs, platform, sdkVersionKey: compileSdkEntry?.key });
    }
    if (!scaffold.ok) {
      console.error(`失败：${scaffold.reason}`);
      
    console.error(`
┌─ 下一步建议 ─────────────────────────────────────┐
│ A. 在 TTY 终端运行本命令（自动透传 ace 交互）            │
│ B. 手动执行 ace create 后重跑本命令（跳过 create）：     │
│    ${opts.aceBin || 'ace'} create ${outDir} -t app           │
│    建议答案：默认/默认/1(OpenHarmony)/16(最大项SDK)/1(双平台)/2(CocoaPods) │
│ C. 改用 modify 模式（如工程构建配置完整）                │
└─────────────────────────────────────────────────┘`);
      process.exit(EXIT_TOOL);
    }
    if (scaffold.skippedCreate) {
      console.log('检测到 scaffold 已在场（.arkui-x/ 或双壳目录），跳过 ace create，直接执行源码迁入（官方回退路径）。');
    }
    migration = migrateSources(root, outDir);
    if (!migration.ok) {
 // 零迁入显式失败（退出码 2）——不静默伪成功
      console.error(`迁入失败：${migration.reason}`);
      
    console.error(`
┌─ 下一步建议 ─────────────────────────────────────┐
│ 迁入失败常见原因：                                       │
│ · build-profile.json5 的 modules[].srcPath 指向无效目录   │
│ · 工程无可迁入源码（各模块 src/main 下为空）              │
│ 请检查后重跑，或改用 modify 模式就地改造。                 │
└─────────────────────────────────────────────────┘`);
      process.exit(EXIT_USAGE);
    }
    const verification = verifyMigration(root, outDir, migration);
    if (!verification.ok) {
      console.error(`迁入完整性校验失败：${verification.reason}`);
      process.exit(EXIT_INTERNAL);
    }
 // ：迁入后回写 build-profile 注册各模块——否则产出仅能构建 scaffold 自带的 Hello World
    registerModules(outDir, migration.modules);
 // 多模块装配进 APK——buildArkTS(s) moduleLists、arkui-x-config modules、
 // entry oh-package file: 依赖三处同步补全，业务模块才进编译集（修复"编译绿≠业务进包"）
    assembleModules(outDir, migration.modules, opts);
 // 配置文件白名单合并 + 遗漏/多改校验——assembleModules 之后执行（后者整体重写
 // entry oh-package 的 dependencies，后合并以"在场键保留"策略保住 file: 模块依赖）
    configMigration = { decision: migrateConfigsDecision };
    if (migrateConfigsDecision === 'yes') {
      const cm = migrateConfigs(root, outDir);
      const verify = verifyConfigMigration(root, outDir, cm);
      configMigration = {
        decision: 'yes',
        merged: cm.merged,
        copied: cm.copied,
        kept_template: cm.kept_template,
        verification: { ok: verify.ok, missing: verify.missing, unexpected_changes: verify.unexpected_changes },
      };
      if (!verify.ok) {
        for (const [file, content] of cm.snapshots) writeFileSync(file, content, 'utf8');
        console.error('配置合并自检失败（不遗漏/不多改校验未过）——已回滚全部合并改动文件；明细：');
        for (const u of verify.unexpected_changes) console.error(`  多改：${u}`);
        for (const m of verify.missing) console.error(`  遗漏：${m}`);
        process.exit(EXIT_INTERNAL);
      }
      console.log(`配置文件迁移完成：合并 ${cm.merged.length} 件 / 无冲突拷贝 ${cm.copied.length} 件 / 保留模板 ${cm.kept_template.length} 件（校验通过：无遗漏、无多改）`);
    }
    resultBaseDir = outDir;
 // ：壳路径按真实布局归一（.arkui-x/ 优先；legacy 顶层兼容 mock/旧 ace）
    const legacyLayout = scaffold.legacy === true;
    artifacts = {
      androidShell: legacyLayout ? 'android' : '.arkui-x/android',
      iosShell: legacyLayout ? 'ios' : '.arkui-x/ios',
      sharedArktsDir: relative(outDir, scaffold.sharedArktsDir) || '.',
 // ：如实描述各模块实际落点（entry→entry/，业务名→<模块名>/）
      migratedModules: (migration.modules ?? []).map((m) => ({ name: m.name, target: m.target ?? m.name, files: m.files }))
    };
  }

 // 适用版本澄清：从生成产物提取真实平台版本基线（modify=工程根；new=输出目录——resultBaseDir 已按模式归一）
  const platformBaseline = readPlatformBaseline(resultBaseDir, platform);

 //  产物 + 报告 + 验证辅助（壳路径为相对路径，基准=resultBaseDir）
  const skeletonResult = {
    schema_version: 1,
    mode,
    platform,
    android_shell: artifacts.androidShell,
    ios_shell: artifacts.iosShell,
    shared_arkts_dir: artifacts.sharedArktsDir,
 // ：artifacts.migratedModules 透传至 JSON 契约（modify 分支无值→条件省略）
    migrated_modules: artifacts.migratedModules,
 // 平台版本基线（F4 适用版本澄清消费；未提取到→条件省略）
    ...(platformBaseline ? { platform_baseline: platformBaseline } : {}),
 // new 模式配置迁移决策与结果（modify 不适用→条件省略）
    ...(configMigration ? { config_migration: configMigration } : {}),
 // ：ace WARN 级提示沉淀（编译前必办；无→条件省略）
    ace_warnings: aceWarnings,
    environment
  };
  mkdirSync(outDir, { recursive: true });
  atomicWrite(join(outDir, 'skeleton-result.json'), renderJson(skeletonResult));
  atomicWrite(join(outDir, 'migration-skeleton-report.md'),
    renderMarkdown(skeletonResult, { migration, changedFiles, aceWarnings }));

 // ：编译验证辅助（就绪且所选平台生成；不直接执行）
  const assists = renderVerificationAssists(skeletonResult, resultBaseDir);
  for (const [relPath, content] of Object.entries(assists)) {
    const file = join(outDir, relPath);
    mkdirSync(join(file, '..'), { recursive: true });
    atomicWrite(file, content);
  }

  const envNote = [];
  if (platform !== 'ios' && !environment.android.ready) envNote.push('Android 环境未就绪，需在对应环境补验');
  if (platform !== 'android' && !environment.ios.ready) envNote.push('iOS 环境未就绪，需在对应环境补验');
  console.log(`完成（mode=${mode}，platform=${platform}）：skeleton-result.json + migration-skeleton-report.md（${outDir}）`);
  if (envNote.length) console.log(`标注：${envNote.join('；')}（骨架已按所选平台生成，不受影响）`);
  process.exit(EXIT_OK);
}

// 入口守卫：仅直接执行时跑主流程，import（单测取 confirmScanBuckets 等）不触发
if (process.argv[1] && resolve(process.argv[1]) === fileURLToPath(import.meta.url)) {
  main(process.argv.slice(2)).catch((err) => {
    console.error(`内部错误: ${err.message}`);
    process.exit(EXIT_INTERNAL);
  });
}

/**
 * buildArkTS 占位符 / local.properties 的 SDK 路径推导：
 * 主源=解析 PATH 中的真实 ace 路径（显式 --ace-bin 优先，realpath 消 symlink）；
 * 回退=ARKUIX_SDK_DIR（仅接受 ArkUI-X SDK 形态——orchestrated 运行中该变量常为 OH SDK 语义，形态校验防误用）；
 * ohosSdkRoot 独立探测（ARKUIX_SDK_DIR 的 OH 形态 + 常规安装路径）。
 */
function resolveSdkPathsForInject(opts) {
  const aceReal = resolveAceBinPath(opts.aceBin);
  const fromAce = arkuiXSdkPathsFromAce(aceReal);
  let arkuiXSdkPath = fromAce.sdkPath;
  let arkuiXSdkRoot = fromAce.sdkRoot;
  if (!arkuiXSdkPath) {
 // ：ARKUIX_X_SDK_DIR（ArkUI-X SDK 专用名）优先；ARKUIX_SDK_DIR 兼容保留（形态校验防 OH SDK 误用）
    const fromEnv = arkuiXSdkPathsFromEnv(process.env.ARKUIX_X_SDK_DIR || process.env.ARKUIX_SDK_DIR);
    arkuiXSdkPath = fromEnv.sdkPath;
    arkuiXSdkRoot = fromEnv.sdkRoot;
  }
  return { arkuiXSdkPath, arkuiXSdkRoot, ohosSdkRoot: detectOhosSdkRoot() };
}

/**
 * 归档 modify：从内置归档确定性注入跨平台壳——零 ace 交互、跨平台一致（Windows/Linux/macOS）。
 * 对工程做三件事（与 ace modify 产物等价）：
 * 1. 拷贝 .arkui-x/ 目录（android/ + ios/ + arkui-x-config.json5，按 platform 裁剪）
 * 2. 改写各模块 hvigorfile.ts（对齐 ace modify TASK_TYPE_MAP 权威映射，见下方 rewire 注释）
 * 3. 更新根 hvigor/hvigor-config.json5（添加 arkui-x plugin 依赖）
 * 追加：buildArkTS 三件占位符注入（含 project_path）+ local.properties 生成。
 */
export function modifyFromArchive(root, archiveDir, opts = {}) {
  const platform = opts.platform || 'both';
  const result = { ok: false, reason: '', filesCopied: 0, modulesRewired: 0, modulesSkipped: 0, envNote: [] };
 // hvigor-arkui-x 插件版本：源工程版本可查固化版本表则按 ON 表对齐（Compile SDK 版本选择同源），
 // 否则维持归档验证值 4.24.2（modify 保留源工程自身 API 版本，仅插件随版本对齐）
  const srcVerEntry = detectSourceSdkVersion(root);
  const pluginVersion = srcVerEntry?.hvigorPlugin ?? '4.24.2';
  if (srcVerEntry) result.envNote.push(`hvigor-arkui-x 插件版本按源工程版本 ${srcVerEntry.key} 对齐（ON 表 ${pluginVersion}）`);
  try {
    // 1. 拷贝 .arkui-x/（按平台裁剪）
    const arkuiXSrc = join(archiveDir, '.arkui-x');
    const arkuiXDst = join(root, '.arkui-x');
    if (!existsSync(arkuiXSrc)) {
      result.reason = `归档目录不合法（缺 .arkui-x/）: ${archiveDir}`;
      return result;
    }
    mkdirSync(arkuiXDst, { recursive: true });
    const wantAndroid = platform === 'both' || platform === 'android';
    const wantIos = platform === 'both' || platform === 'ios';
    if (wantAndroid) result.filesCopied += copyTree(join(arkuiXSrc, 'android'), join(arkuiXDst, 'android'));
    if (wantIos) result.filesCopied += copyTree(join(arkuiXSrc, 'ios'), join(arkuiXDst, 'ios'));
    // arkui-x-config.json5
    const cfgSrc = join(arkuiXSrc, 'arkui-x-config.json5');
    if (existsSync(cfgSrc)) {
      copyFileSync(cfgSrc, join(arkuiXDst, 'arkui-x-config.json5'));
      result.filesCopied++;
    }

    // 2. 改写各模块 hvigorfile.ts（对齐 ace modify 的 TASK_TYPE_MAP 权威映射——
    // appTasks→AppTasksForArkUIX / hapTasks→HapTasks / hspTasks→HspTasks / harTasks→不动。
    // 实证：@ohos/hvigor-ohos-arkui-x-plugin@4.24.2 的导出面仅
    // {AppTasksForArkUIX, AppTasksForArkUIXLibrary, HapTasks, HspTasks}——无 HarTasksForArkUIX，
    // har 模块必须留在 @ohos/hvigor-ohos-plugin（ace modify 同样不改 har 模块））
    const modules = discoverModules(root);
    for (const mod of modules) {
      const hvigorFile = join(mod.dir, 'hvigorfile.ts');
      if (!existsSync(hvigorFile)) continue;
      const content = readFileSync(hvigorFile, 'utf8');
      // 仅改写标准模块（已含 arkui-x plugin 的跳过——幂等）
      if (content.includes('arkui-x-plugin')) { continue; }
      const isRoot = mod.dir === root;
      const isHar = /harTasks/.test(content);
      const isHsp = /hspTasks/.test(content);
      const isApp = /appTasks/.test(content);
      if (isHar && !isApp) { result.modulesSkipped++; continue; } // har 模块留在 ohos-plugin
      if (!isRoot && !isApp && !isHsp && !/hapTasks/.test(content)) continue; // 无已知任务导出——不动
      const exportName = isRoot || isApp ? 'AppTasksForArkUIX' : isHsp ? 'HspTasks' : 'HapTasks';
      const newContent = `// Script for compiling build behavior. It is built in the build plug-in and cannot be modified currently.\nexport { ${exportName} } from '@ohos/hvigor-ohos-arkui-x-plugin';\n`;
      writeFileSync(hvigorFile, newContent, 'utf8');
      result.modulesRewired++;
    }

    // 3. 更新根 hvigor/hvigor-config.json5（对齐 ace modify Oxe 语义：modelVersion 工程才注入插件；
    // 缺文件时按 26.0.0 形态新建；旧 hvigorVersion 形态跳过并警示——旧 schema 引擎拒绝额外依赖键）
    const hvigorDir = join(root, 'hvigor');
    const hvigorConfig = join(hvigorDir, 'hvigor-config.json5');
    mkdirSync(hvigorDir, { recursive: true });
    let config = {};
    if (existsSync(hvigorConfig)) {
      try { config = JSON.parse(readFileSync(hvigorConfig, 'utf8')
        .replace(/\/\*[\s\S]*?\*\//g, '')
        .replace(/\/\/.*$/gm, '')
        .replace(/,\s*([}\]])/g, '$1')); } catch { config = {}; }
    }
    if (!existsSync(hvigorConfig)) {
      config = { modelVersion: '26.0.0', dependencies: { '@ohos/hvigor-ohos-arkui-x-plugin': pluginVersion } };
      writeFileSync(hvigorConfig, JSON.stringify(config, null, 2) + '\n', 'utf8');
      result.filesCopied++;
    } else if ('hvigorVersion' in config) {
      result.envNote.push('hvigor-config.json5 为旧 hvigorVersion 形态（hvigor 4.x 以下）——未注入 arkui-x 插件依赖；建议先升级工程至 modelVersion 形态');
    } else if (!config.modelVersion) {
      result.envNote.push('hvigor-config.json5 无 modelVersion（形态未识别）——未注入 arkui-x 插件依赖，请人工确认');
    } else {
      if (!config.dependencies) config.dependencies = {};
      if (!config.dependencies['@ohos/hvigor-ohos-arkui-x-plugin']) {
        config.dependencies['@ohos/hvigor-ohos-arkui-x-plugin'] = pluginVersion;
        writeFileSync(hvigorConfig, JSON.stringify(config, null, 2) + '\n', 'utf8');
        result.filesCopied++;
      }
    }

    // 4. 项目名/bundleName 定制（从 AppScope/app.json5 读取； ：补 JSON.parse——
    // 此前 looseParseBuildProfile 返回净化字符串未解析，bundleName 恒 undefined，替换静默跳过）
    const appJson5 = join(root, 'AppScope', 'app.json5');
    if (existsSync(appJson5)) {
      try {
        const app = JSON.parse(looseParseBuildProfile(readFileSync(appJson5, 'utf8')));
        const bundleName = app?.app?.bundleName;
        if (bundleName) {
          // 替换 .arkui-x/ 内的包名引用（Android build.gradle、iOS Podfile 等）
          replaceInFiles(arkuiXDst, 'com.example.arkuixapp', bundleName);
        }
      } catch { /* 忽略 app.json5 解析失败 */ }
    }

    // 5. buildArkTS 占位符注入（project_path 一并替换——防 modify 产物 buildArkTS
    // 三件残留 __PROJECT_PATH__ 字面量必坏；SDK 路径由调用方解析传入）
    result.envNote.push(...injectBuildArkTSPaths(arkuiXDst, root, opts.arkuiXSdkPath || ''));

    // 6. local.properties（hvigor 直跑需 nodejs.dir/arkui-x.dir/sdk.dir；
    // arkui-x.dir=SDK 根（licenses 所在层）；在场不覆盖（ace pme 同语义））
    if (writeLocalProperties(root, { arkuiXSdkRoot: opts.arkuiXSdkRoot, ohosSdkRoot: opts.ohosSdkRoot })) {
      result.envNote.push(`local.properties 已生成（nodejs.dir/arkui-x.dir${opts.ohosSdkRoot ? '/sdk.dir' : ''}）`);
    } else if (!existsSync(join(root, 'local.properties'))) {
      result.envNote.push('ArkUI-X SDK 根未检出——local.properties 未生成（直跑 hvigorw 前请手动补 nodejs.dir/arkui-x.dir/sdk.dir）');
    }

    // 7. 多模块装配：按工程真实模块回写 modules/moduleLists——归档固定 entry，
    // 多模块工程（phone/watch 等无 entry 模块）hvigor 报 00303200 Invalid module name 'entry'。
    // 口径同 N1：har 不入列（经 file: 依赖进编译图），entry/feature/shared 入列
    const hapModules = hapModulesOf(root);
    if (hapModules.length > 0 && !(hapModules.length === 1 && hapModules[0] === 'entry')) {
      const list = hapModules.join(',');
      for (const rel of ['android/buildArkTS', 'android/buildArkTS.bat', 'ios/buildArkTS.sh']) {
        const f = join(arkuiXDst, rel);
        if (!existsSync(f)) continue;
        let t = readFileSync(f, 'utf8');
        t = t.replace(/(set\s+)?moduleLists=entry\b/, (m0, pfx) =>
          `${pfx ?? ''}moduleLists=${list} # 工程模块装配`);
        writeFileSync(f, t, 'utf8');
      }
      const cfgF = join(arkuiXDst, 'arkui-x-config.json5');
      if (existsSync(cfgF)) {
        let t = readFileSync(cfgF, 'utf8');
        t = t.replace(/"modules"\s*:\s*\[\s*"entry"\s*\]/,
          `"modules": [${hapModules.map((n) => `"${n}"`).join(', ')}]`);
        writeFileSync(cfgF, t, 'utf8');
      }
      result.envNote.push(`模块装配：modules/moduleLists=${list}（har 不入列，经 file: 依赖进编译图）`);
    }

    result.ok = true;
  } catch (e) {
    result.reason = e.message;
  }
  return result;
}

/** 工程可独立编译模块：build-profile modules[] 逐个查 module.json5.type——har 排除 */
function hapModulesOf(root) {
  const out = [];
  for (const mod of discoverModules(root)) {
    if (mod.dir === root) continue;
    const mj = [join(mod.dir, 'src', 'main', 'module.json5'), join(mod.dir, 'module.json5')];
    let type = '';
    for (const p of mj) {
      if (!existsSync(p)) continue;
      try {
        const doc = JSON.parse(looseParseBuildProfile(readFileSync(p, 'utf8')));
        type = doc?.module?.type ?? '';
      } catch { /* 解析失败保守跳过该模块 */ }
      break;
    }
    if (type && type !== 'har') out.push(mod.name);
  }
  return out;
}

/** 发现工程中的模块（build-profile modules[].srcPath → 模块根目录） */
function discoverModules(root) {
  const out = [{ dir: root, name: '_root' }];
  try {
    const bp = JSON.parse(readFileSync(join(root, 'build-profile.json5'), 'utf8')
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/\/\/.*$/gm, '')
      .replace(/,\s*([}\]])/g, '$1'));
    for (const m of bp?.modules ?? []) {
      const srcPath = m.srcPath ?? `./${m.name}`;
      const modDir = resolve(root, srcPath);
      if (existsSync(modDir)) out.push({ dir: modDir, name: m.name });
    }
  } catch { /* 解析失败走文件系统扫描 */ }
  // 兜底：扫描根下 2 层内含 hvigorfile.ts 的目录（覆盖 build-profile 解析失败场景）
  if (out.length <= 1) {
    try {
      for (const entry of readdirSync(root, { withFileTypes: true })) {
        if (!entry.isDirectory() || entry.name.startsWith('.') || entry.name === 'oh_modules' || entry.name === 'hvigor') continue;
        const modDir = join(root, entry.name);
        if (existsSync(join(modDir, 'hvigorfile.ts'))) out.push({ dir: modDir, name: entry.name });
        // 二层（products/phone、common/sample_common 等）
        try {
          for (const sub of readdirSync(modDir, { withFileTypes: true })) {
            if (!sub.isDirectory() || sub.name.startsWith('.')) continue;
            const subDir = join(modDir, sub.name);
            if (existsSync(join(subDir, 'hvigorfile.ts'))) out.push({ dir: subDir, name: sub.name });
          }
        } catch { /* skip */ }
      }
    } catch { /* skip */ }
  }
  return out;
}

function copyTree(src, dst) {
  let count = 0;
  try {
    for (const entry of readdirSync(src, { withFileTypes: true })) {
      const from = join(src, entry.name);
      const to = join(dst, entry.name);
      if (entry.isDirectory()) count += copyTree(from, to);
      else {
        mkdirSync(dirname(to), { recursive: true });
        copyFileSync(from, to);
        count++;
      }
    }
  } catch { /* skip */ }
  return count;
}

function replaceInFiles(dir, from, to) {
  try {
    for (const entry of readdirSync(dir, { withFileTypes: true })) {
      const f = join(dir, entry.name);
      if (entry.name === 'oh_modules' || entry.name === 'node_modules' || entry.name.startsWith('.')) continue;
      if (entry.isDirectory()) replaceInFiles(f, from, to);
      else if (/\.(gradle|properties|pbxproj|plist|Podfile|xml|json5?)$/.test(entry.name) || entry.name === 'Podfile') {
        try {
          const t = readFileSync(f, 'utf8');
          if (t.includes(from)) writeFileSync(f, t.split(from).join(to), 'utf8');
        } catch { /* skip binary */ }
      }
    }
  } catch { /* skip */ }
}

/** buildArkTS 三件占位符注入；未替换项返回 envNote（保留占位符并提示） */
function injectBuildArkTSPaths(arkuiXDir, projectRoot, sdkPath) {
  const notes = [];
  const files = [
    join(arkuiXDir, 'android', 'buildArkTS'),
    join(arkuiXDir, 'android', 'buildArkTS.bat'),
    join(arkuiXDir, 'ios', 'buildArkTS.sh'),
  ];
  for (const f of files) {
    if (!existsSync(f)) continue;
    let t = readFileSync(f, 'utf8');
    t = t.split('__PROJECT_PATH__').join(projectRoot);
    if (sdkPath) {
      t = t.split('__ARKUIX_SDK_PATH__').join(sdkPath);
    } else if (t.includes('__ARKUIX_SDK_PATH__')) {
      notes.push('ArkUI-X SDK 路径未检出（buildArkTS 保留占位符，编译前请手动改 arkuiXSdkPath）');
    }
    writeFileSync(f, t, 'utf8');
  }
  return [...new Set(notes)];
}
