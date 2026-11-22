import { cpSync, existsSync, mkdirSync, readFileSync, readdirSync, renameSync, rmSync, rmdirSync, writeFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { spawnAce } from './ace-invoker.js';
import { join, dirname } from 'node:path';
import { looseJson5 } from './migrate.js';
import { menuIndexOf, openharmonyCompileSdkOf, compileSdkWriteOf, apiLevelOf, DEFAULT_SDK_VERSION } from './sdk-versions.js';

/** scaffold 共享 ArkTS 候选（ace create 官方模板布局的归一顺序，design 固化；r3 探针实证 entry/ 顶层在场） */
const SHARED_CANDIDATES = ['entry', 'ets', 'ets_stage/source/entry'];

/**
 * 非空目录检查
 * @returns {{exists: boolean, nonEmpty: boolean}}
 */
export function checkOutputDir(dir) {
  if (!existsSync(dir)) return { exists: false, nonEmpty: false };
  let entries = [];
  try {
    entries = readdirSync(dir);
  } catch {
    return { exists: true, nonEmpty: true };
  }
  return { exists: true, nonEmpty: entries.length > 0 };
}

/**
 * 覆盖确认决策（语义）：无效应答返回 null（调用方提示合法取值并重新询问）
 * @returns {'skip'|'overwrite'|'abort'|null}
 */
export function decideOnNonEmpty(answer) {
  const normalized = String(answer || '').trim().toLowerCase();
  if (normalized === '' ) return null;
  if (normalized === 's' || normalized === 'skip' || normalized === '跳过') return 'skip';
  if (normalized === 'y' || normalized === 'o' || normalized === 'overwrite' || normalized === '覆盖') return 'overwrite';
  if (normalized === 'q' || normalized === 'a' || normalized === 'abort' || normalized === '中止') return 'abort';
  return null;
}

/**
 * 两级壳布局归一（ace 26.0.0 实测）：优先真实布局 .arkui-x/{android,ios}，
 * 兼容 legacy 顶层 android/ios（旧 ace / mock）。
 * @returns {{root: string, android: string, ios: string, legacy: boolean}}
 */
export function resolveShells(outDir) {
  const axAndroid = join(outDir, '.arkui-x', 'android');
  const axIos = join(outDir, '.arkui-x', 'ios');
  if (existsSync(axAndroid) || existsSync(axIos)) {
    return { root: join(outDir, '.arkui-x'), android: axAndroid, ios: axIos, legacy: false };
  }
  return { root: outDir, android: join(outDir, 'android'), ios: join(outDir, 'ios'), legacy: true };
}

/** scaffold 已在场判定：.arkui-x/ 在场，或 legacy 顶层双壳 */
export function scaffoldPresent(outDir) {
  if (existsSync(join(outDir, '.arkui-x'))) return true;
  return existsSync(join(outDir, 'android')) && existsSync(join(outDir, 'ios'));
}

/**
 * Compile SDK 菜单最大索引发现（仅适用于在崩溃前打印菜单的 ace 实现/mock 生态；
 * 真 ace 26.0.0 管道模式在 Q1 重绘即崩、不输出菜单——r3 实测后主流程已不依赖本函数）
 */
export function discoverCompileSdkMaxIndex(aceBin, nearDir) {
  const probeDir = `${nearDir}.acescan-${process.pid}`;
  let stdout = '';
  let spawnError = null;
  try {
    const result = spawnAce(aceBin, ['create', probeDir, '-t', 'app'], {
      spawnOpts: {
        encoding: 'utf8',
        input: '\n\n1\n',
        timeout: 20000
      }
    });
    stdout = result.stdout || '';
    if (result.error) spawnError = result.error;
  } catch (err) {
    spawnError = err;
  } finally {
    rmSync(probeDir, { recursive: true, force: true });
  }
  if (spawnError) return { error: spawnError };
  const line = stdout.split('\n').find((l) => /select\s+the\s+Comp\w*\s*SDk/i.test(l)); // 兼容 ace 拼写 Complie
  if (!line) return { idx: null };
  const pairs = [...line.matchAll(/(\d+)\s*:\s*\d[\w.]*/g)].map((m) => Number(m[1]));
  if (pairs.length === 0) return { idx: null };
  return { idx: Math.max(...pairs) };
}

/**
 * 包装 `ace create <dir> -t app`
 * - 交互模型（ace 26.0.0 实测 6 题）：项目名(默认)→bundleName(默认)→runtimeOS(1=OpenHarmony)
 *   →Compile SDK(菜单自适应索引)→平台(1/2/3 映射)→Framework(2=CocoaPods，Native Manual 路径实测挂起)
 * - scaffold 已在场：跳过 create 直接返回迁入所需信息（官方回退路径兑现）
 * - 布局：断言经 resolveShells 归一（.arkui-x/ 优先）
 * @param {{aceBin?: string, timeoutMs?: number, platform?: 'both'|'android'|'ios'}} options
 * @returns {{ok: boolean, reason?: string, sharedArktsDir?: string, skippedCreate?: boolean, legacy?: boolean}}
 */
export function createScaffold(outDir, options = {}) {
  const aceBin = options.aceBin || 'ace';
  const timeoutMs = options.timeoutMs || 300000;
  const platform = options.platform || 'both';
 // Compile SDK 版本（Compile SDK 强确认门已在上游 resolve；此处换算 ace 菜单编号——表插入序）。
 // 注：菜单编号以本机 ace 工具链为准（旧工具链菜单可能不含该版本），编号取自固化版本表
  const sdkVersionKey = options.sdkVersionKey || DEFAULT_SDK_VERSION;
  const sdkMenuIdx = menuIndexOf(sdkVersionKey) ?? menuIndexOf(DEFAULT_SDK_VERSION);

 // ：scaffold 已在场 → 跳过 ace create，直接供迁入（"手动 create 后重跑"承诺兑现）
  if (scaffoldPresent(outDir)) {
    return { ok: true, skippedCreate: true, sharedArktsDir: resolveSharedDir(outDir), legacy: resolveShells(outDir).legacy };
  }

  const platformAnswer = { both: '1', android: '2', ios: '3' }[platform];

 // 坑①前置避让（expect 绕行实测后固化）：真 ace 26.0.0 的 readline
 // 在管道模式下必崩（ERR_USE_AFTER_CLOSE），且 ace create 无 CLI 参数跳过交互——
 // 非 TTY 环境直接给出可执行指引，不浪费必崩的管道尝试（省 ~10s + 消除堆栈噪音）
  if (!process.stdin.isTTY) {
 // 先检测 ace 是否存在：不存在直接报因（不走短路长指引）
    const aceExists = existsSync(aceBin) || aceBin === 'ace';
    if (!aceExists) {
      return { ok: false, reason: `ace 命令不可用（${aceBin}）；请确认 ArkUI-X SDK toolchains 在 PATH 或以 --ace-bin 指定` };
    }
    const isMock = /mock|benchmark/i.test(aceBin); // 单测 mock-bin / benchmark mock-ace / 显式 test 标记
    if (!isMock) {
 // 真 ace + 非 TTY → 短路，给 copy-paste 指引
      console.error(`
┌─ ace create 在非 TTY 环境不可用（工具交互限制）─────────────┐
│ ace 26.0.0 的 create 为 6 题交互，管道模式下 readline 必崩。   │
│                                                              │
│ 请选择以下方式之一：                                          │
│                                                              │
│ A. 在终端手动执行（复制以下命令，按提示作答）：                  │
│      ${aceBin} create ${outDir} -t app                │
│    建议答案：                                                │
│      1. 项目名      → 回车（默认）                            │
│      2. bundleName  → 回车（默认）                            │
│      3. runtimeOS   → 1（OpenHarmony）                      │
│      4. Compile SDK → 编号 ${sdkMenuIdx} 后回车（= ${sdkVersionKey}；以本机 ace 菜单实际编号为准）│
│      5. 平台        → ${platformAnswer}（${platform}）${' '.repeat(Math.max(0, 10 - platform.length))}       │
│      6. Framework   → 2（CocoaPods）                        │
│                                                              │
│ B. 手动 create 完成后重跑本命令                               │
│    （scaffold 已在场时自动跳过 create 直接迁入）                │
│                                                              │
│ C. 在 TTY 终端运行本命令（自动透传交互）                        │
└──────────────────────────────────────────────────────────┘`);
      return { ok: false, reason: 'ace create 在非 TTY 环境不可用（详见上方指引，手动 create 后重跑即可跳过）', guidance: true };
    }
 // mock / benchmark：管道预喂可用
    const result = spawnAce(aceBin, ['create', outDir, '-t', 'app'], {
      spawnOpts: {
        encoding: 'utf8',
        timeout: timeoutMs,
        input: `\n\n1\n${sdkMenuIdx}\n${platformAnswer}\n2\n`
      }
    });
    return interpretCreateResult(result, outDir, platform, timeoutMs, aceBin);
  }

 // TTY 环境：透传交互（坑④：进入前打印完整题面预告+建议答案）
  console.log(`
即将进入 ace create 交互，共 6 题（建议答案加粗）：
  1. 项目名        回车（默认）
  2. bundleName    回车（默认）
  3. runtimeOS     按源工程形态（源为 HarmonyOS 形态选对应项；缺省 1 = OpenHarmony 推荐）
  4. Compile SDK   编号 ${sdkMenuIdx} = ${sdkVersionKey}（以本机 ace 菜单实际编号为准；文本输入，整串提交）
  5. 平台          ${platformAnswer} = ${platform}
  6. Framework     2 = CocoaPods（推荐；Native Manual 实测有问题）
`);
  let result = spawnAce(aceBin, ['create', outDir, '-t', 'app'], {
    spawnOpts: {
      stdio: ['inherit', 'inherit', 'inherit'],
      timeout: timeoutMs
    }
  });
  result = { ...result, stdout: '', stderr: '（TTY 透传模式：输出已直达终端）' };
  return interpretCreateResult(result, outDir, platform, timeoutMs, aceBin);
}

function interpretCreateResult(result, outDir, platform, timeoutMs, aceBin) {
  if (result.signal === 'SIGTERM' || result.error?.code === 'ETIMEDOUT') {
    return { ok: false, reason: `ace create 超时（>${timeoutMs}ms）被终止` };
  }
  if (result.error) {
    return { ok: false, reason: `ace 命令不可用（${result.error.message}）；请确认 ArkUI-X SDK toolchains 在 PATH 或以 --ace-bin 指定` };
  }
  if (result.status !== 0) {
 // 坑③：截获 ERR_USE_AFTER_CLOSE 崩溃，替换为人话
    const raw = `${result.stdout || ''}${result.stderr || ''}`;
    if (raw.includes('ERR_USE_AFTER_CLOSE')) {
      return { ok: false, reason: 'ace 交互在管道模式下崩溃（工具已知限制）——请在 TTY 终端运行本命令，或手动执行 ace create 后重跑（跳过 create）' };
    }
    const tail = (result.stderr || result.stdout || '').trim().split('\n').slice(-3).join(' | ');
    return { ok: false, reason: `ace create 失败（退出码 ${result.status}）${tail ? `：${tail}` : ''}` };
  }

  const shells = resolveShells(outDir);
  const wantAndroid = platform === 'both' || platform === 'android';
  const wantIos = platform === 'both' || platform === 'ios';
  const missing = [];
  if (wantAndroid && !existsSync(shells.android)) missing.push(`${shells.legacy ? '' : '.arkui-x/'}android`);
  if (wantIos && !existsSync(shells.ios)) missing.push(`${shells.legacy ? '' : '.arkui-x/'}ios`);
  if (missing.length > 0) {
    return { ok: false, reason: `ace create 退出码 0 但未检出所选平台壳 ${missing.join(' 与 ')}（scaffold 结构断言失败）` };
  }
  trimUnselectedShells(shells, platform);
  return { ok: true, sharedArktsDir: resolveSharedDir(outDir), legacy: shells.legacy };
}

/**
 * ：按所选平台裁剪未选平台壳（platform=android 时移除 ios/，反之亦然）
 */
export function trimUnselectedShells(shells, platform) {
  if (platform === 'android') rmSync(shells.ios, { recursive: true, force: true });
  if (platform === 'ios') rmSync(shells.android, { recursive: true, force: true });
}

/** 归一共享 ArkTS 目录（候选序；均缺失时落到 entry 由迁移方创建） */
export function resolveSharedDir(outDir) {
  for (const candidate of SHARED_CANDIDATES) {
    if (existsSync(join(outDir, candidate))) return join(outDir, candidate);
  }
  return join(outDir, 'entry');
}

// ── 根治：归档 scaffold 复用（零交互、确定性） ───

/** 归档内置默认值（make-scaffold-archive.js 组装锚，materialize 替换锚） */
export const ARCHIVE_DEFAULTS = { name: 'arkuixapp', bundle: 'com.example.arkuixapp' };

/**
 * local.properties 生成（格式对齐 ace pme）：
 * nodejs.dir + arkui-x.dir（SDK 根——licenses 所在层）+ sdk.dir（OH SDK 根，检出才写）。
 * 在场不覆盖（ace 同语义）；arkui-x 根未检出不写（避免半截配置误导）。
 * Windows 路径转义对齐 ace createLocalProperties（\ → \\ 与 : → \:）。
 */
export function writeLocalProperties(targetDir, paths, opts = {}) {
  const file = join(targetDir, 'local.properties');
  if (existsSync(file)) return false;
  if (!paths || !paths.arkuiXSdkRoot) return false;
  const platform = opts.platform || process.platform;
  // win32 转义规则：仅转义 '\'→'\\'、':'→'\:'（Java properties 兼容两种分隔符，'/' 形态更稳）——
  // 不做 '/'→'\\' 改写（改写会把 '/' 形态输入统一变形，破坏与产物/断言的一致性）
  const esc = (p) => platform === 'win32'
    ? String(p).replace(/\\/g, '\\\\').replace(/:/g, '\\:')
    : String(p);
  const lines = [`nodejs.dir=${esc(dirname(process.execPath))}`, `arkui-x.dir=${esc(paths.arkuiXSdkRoot)}`];
  if (paths.ohosSdkRoot) lines.push(`sdk.dir=${esc(paths.ohosSdkRoot)}`);
  writeFileSync(file, lines.join('\n') + '\n', 'utf8');
  return true;
}

/**
 * 平台版本基线提取（F4 适用版本澄清的数据源）：从生成的工程读取真实编译版本约束——
 * Android build.gradle 的 min/target/compileSdkVersion、iOS pbxproj 的
 * IPHONEOS_DEPLOYMENT_TARGET（首次出现值；归档四处一致）、OpenHarmony 侧 build-profile 的
 * compileSdkVersion/runtimeOS 与 hvigor-config 的 modelVersion。Android/iOS 按所选平台裁剪；
 * 文件缺失/未解析到 → 该侧省略；两侧皆无 → 返回 null（产物不输出该字段）。
 */
export function readPlatformBaseline(projectDir, platform = 'both') {
  const out = {};
  if (platform === 'both' || platform === 'android') {
    const android = readAndroidBaseline(join(projectDir, '.arkui-x', 'android', 'app', 'build.gradle'));
    if (android) out.android = android;
  }
  if (platform === 'both' || platform === 'ios') {
    const ios = readIosBaseline(join(projectDir, '.arkui-x', 'ios', 'app.xcodeproj', 'project.pbxproj'));
    if (ios) out.ios = ios;
  }
  const oh = readOhBaseline(projectDir);
  if (oh) out.openharmony = oh;
  return Object.keys(out).length > 0 ? out : null;
}

function readOhBaseline(projectDir) {
  const out = {};
  try {
    const bp = JSON.parse(looseJson5(readFileSync(join(projectDir, 'build-profile.json5'), 'utf8')));
    const holder = (bp.compileSdkVersion !== undefined || bp.runtimeOS !== undefined)
      ? bp : (bp.app?.products?.[0] ?? {});
    if (holder.compileSdkVersion !== undefined) out.compile_sdk_version = String(holder.compileSdkVersion);
    if (holder.runtimeOS !== undefined) out.runtime_os = String(holder.runtimeOS);
  } catch { /* 缺 build-profile/解析失败 → 侧省略 */ }
  try {
    const hc = JSON.parse(looseJson5(readFileSync(join(projectDir, 'hvigor', 'hvigor-config.json5'), 'utf8')));
    if (hc.modelVersion !== undefined) out.model_version = String(hc.modelVersion);
  } catch { /* skip */ }
  return Object.keys(out).length > 0 ? out : null;
}

function readAndroidBaseline(gradleFile) {
  let text;
  try { text = readFileSync(gradleFile, 'utf8'); } catch { return null; }
  const grab = (key) => {
    const m = new RegExp(`\\b${key}\\s+(\\d+)`).exec(text);
    return m ? Number(m[1]) : null;
  };
  const min = grab('minSdkVersion');
  if (min === null) return null; // minSdk 是基线的必要项（其余为补充）
  const target = grab('targetSdkVersion');
  const compile = grab('compileSdkVersion');
  return {
    min_sdk: min,
    ...(target !== null ? { target_sdk: target } : {}),
    ...(compile !== null ? { compile_sdk: compile } : {})
  };
}

function readIosBaseline(pbxprojFile) {
  let text;
  try { text = readFileSync(pbxprojFile, 'utf8'); } catch { return null; }
  const m = /IPHONEOS_DEPLOYMENT_TARGET\s*=\s*([\d.]+)\s*;/.exec(text);
  return m ? { deployment_target: m[1] } : null;
}

/**
 * 归档 scaffold 物化（根治）：复制归档 → 项目名/bundleName 变量替换 → java 包目录重组
 * → buildArkTS 环境路径注入 → platform 裁剪 → .projectInfo 重写 → compileSdk 断言。
 * 行为等价 ace create 26.0.0（标准答案：双平台/CocoaPods/OpenHarmony），零交互、确定性。
 * @param {{name?: string, bundle?: string, platform?: 'both'|'android'|'ios', ohpmPath?: string,
 *          arkuiXSdkPath?: string, arkuiXSdkRoot?: string, ohosSdkRoot?: string,
 *          sdkVersion?: object}} opts sdkVersion=Compile SDK 版本表条目（sdk-versions.js；缺省=归档固有 26.0.0）
 */
export function materializeFromArchive(archiveDir, outDir, opts = {}) {
  if (!existsSync(join(archiveDir, '.arkui-x'))) {
    return { ok: false, reason: `归档目录不合法（缺 .arkui-x/）: ${archiveDir}` };
  }
  const name = String(opts.name || ARCHIVE_DEFAULTS.name);
  const bundle = String(opts.bundle || ARCHIVE_DEFAULTS.bundle);
  if (!/^[a-z][a-z0-9_]*$/i.test(name)) return { ok: false, reason: `项目名非法（字母/数字/下划线，字母开头）: ${name}` };
  if (!/^[a-z][a-z0-9_.]*$/i.test(bundle)) return { ok: false, reason: `bundleName 非法（反向域名形态）: ${bundle}` };
  const platform = opts.platform || 'both';

  cpSync(archiveDir, outDir, { recursive: true, filter: (src) => !src.includes('xcuserdata') });

 // 变量替换（锚=归档默认值；覆盖 iOS 大写显示名形态）
  const AN = ARCHIVE_DEFAULTS.name;
  const AB = ARCHIVE_DEFAULTS.bundle;
  const newTail = bundle.split('.').at(-1);
  const oldTail = AB.split('.').at(-1);
  const TEXT_SUBS = [
    ['AppScope/app.json5'], ['AppScope/resources/base/element/string.json'], ['oh-package.json5'],
    ['.arkui-x/android/settings.gradle'], ['.arkui-x/android/app/src/main/res/values/strings.xml'],
    ['.arkui-x/android/app/src/main/AndroidManifest.xml'], ['.arkui-x/android/app/build.gradle'],
    ['.arkui-x/ios/app.xcodeproj/project.pbxproj'], ['.arkui-x/ios/app/AppDelegate.m'], ['.arkui-x/ios/app/Info.plist']
  ].map(([rel]) => join(outDir, rel));
  const javaDirs = ['.arkui-x/android/app/src/main/java', '.arkui-x/android/app/src/test/java', '.arkui-x/android/app/src/androidTest/java'].map((d) => join(outDir, d));
  const iosName = oldTail; // 归档 Info.plist 中的显示名= arkuixapp（小写形态首字母大写两处）
  for (const file of [...TEXT_SUBS, ...walkJava(javaDirs)]) {
    if (!existsSync(file)) continue;
    let s = readFileSync(file, 'utf8');
    s = s.split(AB).join(bundle).split(`${AB}:entry:EntryAbility:`).join(`${bundle}:entry:EntryAbility:`)
      .split(AN).join(name)
      .split(iosName.slice(0, 1).toUpperCase() + iosName.slice(1)).join(newTail.slice(0, 1).toUpperCase() + newTail.slice(1));
    writeFileSync(file, s);
  }

 // java 包目录重组（com/example/arkuixapp → 新 bundle 分包）
  const newParts = bundle.split('.');
  const oldParts = AB.split('.');
  for (const base of javaDirs) {
    const oldDir = join(base, ...oldParts);
    const newDir = join(base, ...newParts);
    if (!existsSync(oldDir)) continue;
    mkdirSync(newDir, { recursive: true });
    for (const f of readdirSync(oldDir)) {
      renameSync(join(oldDir, f), join(newDir, f));
    }
 // 清掉空旧目录链（保留 base；rmdirSync 空删语义——非空即抛错终止，防误删）
    let cur = oldDir;
    for (let i = 0; i < oldParts.length; i++) {
      try { rmdirSync(cur); } catch { break; }
      cur = join(cur, '..');
    }
  }

 // buildArkTS 环境路径注入（占位符 → 实际路径；未知则保留占位并提示）
  const envNote = [];
  const ohpm = opts.ohpmPath || '';
  const sdk = opts.arkuiXSdkPath || '';
  for (const rel of ['.arkui-x/android/buildArkTS', '.arkui-x/android/buildArkTS.bat', '.arkui-x/ios/buildArkTS.sh']) {
    const file = join(outDir, rel);
    if (!existsSync(file)) continue;
    let s = readFileSync(file, 'utf8');
    s = s.replaceAll('__PROJECT_PATH__', outDir);
    if (ohpm) s = s.replaceAll('__OHPM_PATH__', ohpm); else if (s.includes('__OHPM_PATH__')) envNote.push('ohpm 路径未检出（buildArkTS 保留占位符，编译前请手动改 ohpm_path）');
    if (sdk) s = s.replaceAll('__ARKUIX_SDK_PATH__', sdk); else if (s.includes('__ARKUIX_SDK_PATH__')) envNote.push('ArkUI-X SDK 路径未检出（buildArkTS 保留占位符，编译前请手动改 arkuiXSdkPath）');
    writeFileSync(file, s);
  }

 // local.properties（hvigor 直跑需要；在场不覆盖、根未检出不写）
  if (writeLocalProperties(outDir, { arkuiXSdkRoot: opts.arkuiXSdkRoot, ohosSdkRoot: opts.ohosSdkRoot })) {
    envNote.push(`local.properties 已生成（nodejs.dir/arkui-x.dir${opts.ohosSdkRoot ? '/sdk.dir' : ''}）`);
  } else if (!existsSync(join(outDir, 'local.properties'))) {
    envNote.push('ArkUI-X SDK 根未检出——local.properties 未生成（直跑 hvigorw 前请手动补 nodejs.dir/arkui-x.dir/sdk.dir）');
  }

 // Compile SDK 版本替换（sdkVersion=sdk-versions 表条目；缺省=归档固有 26.0.0 零版本替换）：
 // 版本写法按运行时形态分流（compileSdkWriteOf）——HarmonyOS 形态写全形态串（与源工程同步），
 // 缺省 OpenHarmony 形态（apiLevel<26 数字、26.0.0 字符串）；runtimeOS 与源工程同步（源显式
 // HarmonyOS 形态时保留，缺省保持归档 OpenHarmony）；hvigor-config modelVersion+插件版本与
 // 根 oh-package modelVersion 同步（ace ON 表语义，两形态同链）
  if (opts.sdkVersion || opts.runtimeOS === 'HarmonyOS') {
    const v = opts.sdkVersion;
    const ohCompile = v ? compileSdkWriteOf(v, opts.runtimeOS) : undefined;
    const bpFile = join(outDir, 'build-profile.json5');
    const bpDoc = JSON.parse(looseJson5(readFileSync(bpFile, 'utf8')));
    const holder = (bpDoc.compileSdkVersion !== undefined || bpDoc.compatibleSdkVersion !== undefined)
      ? bpDoc : (bpDoc.app?.products?.[0] ?? {});
    if (v) {
      // 版本三元组——保留源值 + 越界钳制（compile=所选；compatible/target 语义属源工程，不无故抬升）：
      //   compatible_eff = 源值（可解析且 <= compile）否则 compile
      //   target_eff = 源值钳制到 [compatible_eff, compile] 区间；源缺而归档带 target 键时 = compile
      // 恒满足 compatibleSdkVersion <= targetSdkVersion <= compileSdkVersion，且写法沿用源值自身形态
      const lvlC = apiLevelOf(ohCompile);
      const src = opts.sourceSdkVersions ?? {};
      const srcCompat = src.compatibleSdkVersion;
      const compatEff = (srcCompat !== undefined && apiLevelOf(srcCompat) !== null && lvlC !== null && apiLevelOf(srcCompat) <= lvlC)
        ? srcCompat : ohCompile;
      const srcTarget = src.targetSdkVersion;
      let targetEff;
      if (srcTarget !== undefined) {
        const lt = apiLevelOf(srcTarget);
        const lc = apiLevelOf(compatEff);
        if (lt === null || lvlC === null || lc === null) targetEff = ohCompile; // 不可解析——保守取 compile，防关系破坏
        else if (lt > lvlC) targetEff = ohCompile;
        else if (lt < lc) targetEff = compatEff;
        else targetEff = srcTarget;
      } else {
        targetEff = holder.targetSdkVersion !== undefined ? ohCompile : undefined; // 归档带 target 键而源无 → compile
      }
      if (holder.compileSdkVersion !== undefined) holder.compileSdkVersion = ohCompile;
      // 写入条件：归档带 target 键 或 源工程有 target 值（源语义应保留，不因归档缺键而丢）
      if (targetEff !== undefined && (holder.targetSdkVersion !== undefined || srcTarget !== undefined)) holder.targetSdkVersion = targetEff;
      if (holder.compatibleSdkVersion !== undefined) holder.compatibleSdkVersion = compatEff;
    }
    if (holder.runtimeOS !== undefined) holder.runtimeOS = opts.runtimeOS ?? 'OpenHarmony';
    writeFileSync(bpFile, JSON.stringify(bpDoc, null, 2) + '\n', 'utf8');
    if (v) {
      const pkgFile = join(outDir, 'oh-package.json5');
      const pkgDoc = JSON.parse(looseJson5(readFileSync(pkgFile, 'utf8')));
      if (pkgDoc.modelVersion !== undefined) pkgDoc.modelVersion = v.modelVersion;
      writeFileSync(pkgFile, JSON.stringify(pkgDoc, null, 2) + '\n', 'utf8');
      const hcFile = join(outDir, 'hvigor', 'hvigor-config.json5');
      const hcDoc = JSON.parse(looseJson5(readFileSync(hcFile, 'utf8')));
      hcDoc.modelVersion = v.modelVersion;
      (hcDoc.dependencies ??= {})['@ohos/hvigor-ohos-arkui-x-plugin'] = v.hvigorPlugin;
      writeFileSync(hcFile, JSON.stringify(hcDoc, null, 2) + '\n', 'utf8');
    }
  }

 // platform 裁剪 + .projectInfo 重写
  const shells = resolveShells(outDir);
  trimUnselectedShells(shells, platform);
  writeFileSync(join(outDir, '.projectInfo'), JSON.stringify({
    projectTemplate: 'app', moduleInfo: [], abilityInfo: [],
    platforms: platform === 'both' ? ['android', 'ios'] : [platform]
  }, null, 2) + '\n');

 // 断言：compileSdkVersion 恒等于所选写法；版本三元组关系 compatibleSdkVersion <= targetSdkVersion <= compileSdkVersion
 // （在场者按 apiLevel 比较；不可解析值视为校验失败）——归档被误改/版本替换失败/关系破坏即拒绝物化，防工程同步错误流出
  const expectCompile = opts.sdkVersion ? compileSdkWriteOf(opts.sdkVersion, opts.runtimeOS) : '26.0.0';
  const bpFinal = JSON.parse(looseJson5(readFileSync(join(outDir, 'build-profile.json5'), 'utf8')));
  const holderFinal = bpFinal.compileSdkVersion !== undefined ? bpFinal : (bpFinal.app?.products?.[0] ?? {});
  if (String(holderFinal.compileSdkVersion ?? '') !== String(expectCompile)) {
    return { ok: false, reason: `build-profile.json5 的 compileSdkVersion 为 ${JSON.stringify(holderFinal.compileSdkVersion)}，期望 ${JSON.stringify(expectCompile)}（归档被改动或版本替换失败），拒绝物化` };
  }
  const lv = { compatibleSdkVersion: apiLevelOf(holderFinal.compatibleSdkVersion), targetSdkVersion: apiLevelOf(holderFinal.targetSdkVersion), compileSdkVersion: apiLevelOf(holderFinal.compileSdkVersion) };
  const present = ['compatibleSdkVersion', 'targetSdkVersion', 'compileSdkVersion'].filter((k) => holderFinal[k] !== undefined);
  for (const k of present) {
    if (lv[k] === null) return { ok: false, reason: `build-profile.json5 的 ${k}=${JSON.stringify(holderFinal[k])} 无法解析为 API level（三值关系不可校验），拒绝物化` };
  }
  if (present.includes('compatibleSdkVersion') && present.includes('targetSdkVersion') && lv.compatibleSdkVersion > lv.targetSdkVersion) {
    return { ok: false, reason: `build-profile.json5 三值关系破坏：compatibleSdkVersion(${holderFinal.compatibleSdkVersion}) > targetSdkVersion(${holderFinal.targetSdkVersion})，拒绝物化` };
  }
  if (present.includes('targetSdkVersion') && lv.targetSdkVersion > lv.compileSdkVersion) {
    return { ok: false, reason: `build-profile.json5 三值关系破坏：targetSdkVersion(${holderFinal.targetSdkVersion}) > compileSdkVersion(${holderFinal.compileSdkVersion})，拒绝物化` };
  }
  if (present.includes('compatibleSdkVersion') && !present.includes('targetSdkVersion') && lv.compatibleSdkVersion > lv.compileSdkVersion) {
    return { ok: false, reason: `build-profile.json5 三值关系破坏：compatibleSdkVersion(${holderFinal.compatibleSdkVersion}) > compileSdkVersion(${holderFinal.compileSdkVersion})，拒绝物化` };
  }
  return { ok: true, sharedArktsDir: resolveSharedDir(outDir), legacy: false, fromArchive: true, envNote };
}

function walkJava(bases) {
  const out = [];
  for (const base of bases) {
    if (!existsSync(base)) continue;
    for (const root of [base, ...javaSubdirs(base)]) {
      for (const f of readdirSync(root)) {
        const full = join(root, f);
        if (full.endsWith('.java')) out.push(full);
      }
    }
  }
  return out;
}

function javaSubdirs(base) {
  const dirs = [];
  (function walk(dir) {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.isDirectory()) { const full = join(dir, e.name); dirs.push(full); walk(full); }
    }
  })(base);
  return dirs;
}
