import { spawnSync } from 'node:child_process';
import { spawnAce } from './ace-invoker.js';
import { existsSync, readdirSync, realpathSync } from 'node:fs';
import { delimiter, dirname, join } from 'node:path';
import { homedir } from 'node:os';

/** modify 可用门槛（修订：ace modify 自 API 22 起提供——原 24 为误记） */
const MODIFY_API_THRESHOLD = 22;

/**
 * 环境检测（增 arkui_x_sdk 检出）：
 * 主源=解析 `ace check` 输出（toolchains/Xcode 就绪状态 + ArkUI-X SDK 版本行）；
 * 补测=Gradle/JDK/CocoaPods 分项独立探测（粒度）。
 * 检测不阻断骨架生成（环境仅决定验证范围）；例外：modify_available=false 且模式=modify
 * 由 CliEntry 拒绝（边界，退出码 4，零写）。
 *
 * @param {{aceBin?: string, run?: Function, platform?: string, aceCheckOutput?: string,
 *          env?: object}} options
 *   run(cmd, args) → {status, stdout} 注入用（测试）；缺省用 spawnSync
 */
export function detectEnvironment(options = {}) {
  const run = options.run || ((cmd, args) => spawnAce(cmd, args, { spawnOpts: { encoding: 'utf8', timeout: 15000 } }));
  const platform = options.platform || process.platform;

  const android = { ready: false, missing: [] };
  const ios = { ready: false, missing: [] };

  if (platform !== 'darwin') {
    ios.missing.push('需 macOS（iOS 编译环境仅可在 macOS 上就绪）');
  }

 // 主源：ace check（可注入输出或执行体）
  let checkText = null;
  const aceBin = options.aceBin || 'ace';
  let aceAvailable = false;
  if (options.aceCheckOutput !== undefined) {
    checkText = options.aceCheckOutput;
    aceAvailable = true;
  } else {
    const result = run(aceBin, ['check']);
 //区分三种失败形态（超时/不在 PATH/非零退出），各给可操作提示
    if (result.error && result.error.code === 'ETIMEDOUT') {
      aceAvailable = false;
      console.warn('⚠ ace check 探测超时（冷启动可能较慢）——可设 ARKUIX_ACE_TIMEOUT_MS 调大后重试');
    } else if (result.error && result.error.code === 'ENOENT') {
      aceAvailable = false;
      console.warn('⚠ ace 不在 PATH——请确认 ArkUI-X SDK toolchains/bin 已加入环境变量或用 --ace-bin 指定路径');
    } else if (result.error) {
      aceAvailable = false;
      console.warn(`⚠ ace 启动失败：${result.error.message}`);
    } else if (result.status !== 0) {
      aceAvailable = false;
      const errSnippet = (result.stderr || result.stdout || '').split('\n').filter(l => l.trim()).slice(0, 3).join('\n');
      console.warn(`⚠ ace check 退出码 ${result.status}${errSnippet ? '\n' + errSnippet : ''}`);
    } else {
      aceAvailable = true;
      if (result.stdout) checkText = result.stdout;
    }
  }
  if (checkText) {
    applyAceCheck(checkText, android, ios);
  }

 // 分项补测（粒度）
  probe(android, 'Gradle', () => run('gradle', ['--version']));
  probe(android, 'JDK', () => run('java', ['-version']));
  if (platform === 'darwin') {
    probe(ios, 'Xcode', () => run('xcodebuild', ['-version']));
    probe(ios, 'CocoaPods', () => run('pod', ['--version']));
  }

  android.ready = android.missing.length === 0;
  ios.ready = ios.missing.length === 0;

 // ：arkui_x_sdk 检出（detected/version/modify_available=API 24+ 门槛）
  const arkuiXSdk = detectArkuiXSdk({ aceBin, run, checkText, aceAvailable, options });
  return { android, ios, arkui_x_sdk: arkuiXSdk };
}

/**
 * ace 可执行文件路径解析（buildArkTS 占位符/local.properties 推导源，不再只依赖显式 --ace-bin）：
 * 显式路径原样返回；裸 'ace' 按 PATH 扫描（win32 含 .cmd/.bat/.exe/.ps1 扩展名探测）。
 * 解析结果经 realpath（macOS PATH 项常为 symlink）。
 * @returns {string} 绝对路径；未检出返回 ''
 */
export function resolveAceBinPath(aceBin, env = process.env) {
  let candidate = '';
  if (aceBin && aceBin !== 'ace') {
    candidate = aceBin;
  } else {
    const pathVar = env.PATH || env.Path || '';
    const exts = process.platform === 'win32' ? ['', '.cmd', '.bat', '.exe', '.ps1'] : [''];
    for (const dir of pathVar.split(delimiter)) {
      if (!dir) continue;
      for (const ext of exts) {
        const p = join(dir, `ace${ext}`);
        if (existsSync(p)) { candidate = p; break; }
      }
      if (candidate) break;
    }
  }
  if (!candidate || !existsSync(candidate)) return '';
  try {
    return realpathSync(candidate);
  } catch {
    return candidate;
  }
}

/**
 * ArkUI-X SDK 路径推导（从 ace 可执行路径）：
 * ace 形如 <SdkRoot>/<ver>/arkui-x/toolchains/bin/ace(.cmd)。
 * @returns {{sdkPath: string, sdkRoot: string}} sdkPath=版本级 arkui-x 目录（buildArkTS arkuiXSdkPath 语义）；
 * sdkRoot=SDK 根（local.properties arkui-x.dir 语义——licenses 所在层）。形态不匹配返回空串。
 */
export function arkuiXSdkPathsFromAce(aceReal) {
  if (!aceReal) return { sdkPath: '', sdkRoot: '' };
  const m = String(aceReal).match(/^(.*[\\/])(\d{2}(?:\.\d+){0,2})[\\/]arkui-x[\\/]toolchains[\\/]bin[\\/]ace(?:\.(cmd|bat|ps1|exe))?$/i);
  if (!m) return { sdkPath: '', sdkRoot: '' };
  const sdkRoot = m[1].replace(/[\\/]$/, '');
  // 按输入自身的分隔符风格拼接（POSIX 输入→'/'，Windows 输入→'\'）——join 会把 POSIX 输入改写为 win32 形态
  const s = m[1].endsWith('\\') ? '\\' : '/';
  return { sdkPath: `${sdkRoot}${s}${m[2]}${s}arkui-x`, sdkRoot };
}

/**
 * ARKUIX_SDK_DIR 环境变量按形态路由（同名变量在 scan（OH SDK）与 skeleton（ArkUI-X SDK）
 * 两阶段语义冲突——此处只接受 ArkUI-X SDK 形态，OH SDK 形态明确拒绝不误用）：
 * 版本级（<root>/<ver>，其下有 arkui-x/）或根级（其下有 <ver>/arkui-x/）。
 * @returns {{sdkPath: string, sdkRoot: string}} 非法/未设返回空串。
 */
export function arkuiXSdkPathsFromEnv(envValue) {
  if (!envValue || !existsSync(envValue)) return { sdkPath: '', sdkRoot: '' };
  if (existsSync(join(envValue, 'arkui-x'))) {
    return { sdkPath: join(envValue, 'arkui-x'), sdkRoot: dirname(envValue) };
  }
  try {
    const versions = readdirSync(envValue)
      .filter((e) => /^\d/.test(e) && existsSync(join(envValue, e, 'arkui-x')))
      .sort((a, b) => a.localeCompare(b, 'en', { numeric: true }));
    if (versions.length) {
      const ver = versions[versions.length - 1];
      return { sdkPath: join(envValue, ver, 'arkui-x'), sdkRoot: envValue };
    }
  } catch { /* 非目录/不可读 */ }
  return { sdkPath: '', sdkRoot: '' };
}

/**
 * OH SDK 根目录探测（local.properties sdk.dir 语义=根级、版本子目录布局；独立导出——不进 skeleton-result 契约）：
 * 候选=ARKUIX_SDK_DIR（OH SDK 形态：版本级含 ets/ → 上级为根；或根级含 <ver>/ets/）→ 常规安装路径。
 * @returns {string} SDK 根目录（其下为版本目录）；未检出返回 ''。
 */
export function detectOhosSdkRoot(env = process.env, home = homedir()) {
  const candidates = [];
  // ：ARKUIX_OH_SDK_DIR（OH SDK 专用名）优先，ARKUIX_SDK_DIR 兼容（均做形态校验）
  for (const envVar of ['ARKUIX_OH_SDK_DIR', 'ARKUIX_SDK_DIR']) {
    const v = env[envVar];
    if (v && existsSync(v)) {
      if (existsSync(join(v, 'ets'))) candidates.push(dirname(v));
      else candidates.push(v);
    }
  }
  candidates.push(join(home, 'Library', 'OpenHarmony', 'Sdk'));
  candidates.push(join(home, 'AppData', 'Local', 'OpenHarmony', 'Sdk'));
  candidates.push(join(home, 'Library', 'Huawei', 'Sdk'));
  candidates.push(join(home, 'AppData', 'Local', 'Huawei', 'Sdk'));
  for (const base of candidates) {
    if (!existsSync(base)) continue;
    try {
      const versions = readdirSync(base)
        .filter((e) => /^\d/.test(e) && existsSync(join(base, e, 'ets')));
      if (versions.length) return base;
    } catch { /* skip */ }
  }
  return '';
}

/**
 * ArkUI-X SDK 检出：
 * - detected：ace 工具在场（ace check 可执行）
 * - version：ace check 版本行（如 "[√] ArkUI-X (ArkUI-X SDK version 26.0.0.38)" → 26.0.0.38）
 *   或 aceBin 路径中的版本目录段（如 .../ArkUI-X/Sdk/26.0.0/...）
 * - modify_available：版本归一后 major >= 24（"24"/"23" 两位与 "26.0.0" 三段式均按数字比较，
 *   禁止字符串直比）；无法判定版本时=false（保守）
 */
export function detectArkuiXSdk({ aceBin, run, checkText, aceAvailable, options }) {
  let version = '';
  if (checkText) {
    version = parseVersionFromCheck(checkText);
  }
  if (!version && aceBin && aceBin !== 'ace') {
    version = parseVersionFromPath(aceBin);
  }
  if (!version && aceAvailable && !options.aceCheckOutput) {
 // ace check --version 形态兜底（不计入 detected 判定）
    const result = run(aceBin, ['--version']);
    if (!result.error && result.status === 0 && result.stdout) {
      version = parseVersionFromCheck(result.stdout);
    }
  }
  const api = apiLevelOf(version);
  return {
    detected: aceAvailable,
    version,
    modify_available: api !== null && api >= MODIFY_API_THRESHOLD
  };
}

/** ace check 输出中的版本行解析：[√] ArkUI-X (ArkUI-X SDK version 26.0.0.38) */
export function parseVersionFromCheck(text) {
  for (const line of String(text || '').split('\n')) {
    if (!/ArkUI-X/i.test(line)) continue;
    const m = line.match(/version\s+v?(\d{2}(?:\.\d+){0,2})/i);
    if (m) return m[1];
  }
  return '';
}

/** ace 命令路径中的版本目录段：…/ArkUI-X/Sdk/26.0.0/arkui-x/toolchains/bin/ace → 26.0.0 */
export function parseVersionFromPath(aceBin) {
  let real = aceBin;
  try {
    real = realpathSync(aceBin);
  } catch {
    real = aceBin;
  }
  const m = real.match(/(\d{2}(?:\.\d+){0,2})/g);
  if (!m) return '';
 // 取最后一个形如版本目录的段（排除文件名中的零散数字由 \d{2} 起始约束）
  return m[m.length - 1] || '';
}

/** 版本归一比较（design 固化）：API <26 两位数字（"24"）与 API ≥26 三段式（"26.0.0"）统一取 major 数字比较 */
export function apiLevelOf(version) {
  if (!version || typeof version !== 'string') return null;
  const m = version.match(/^(\d{2})(?:\.\d+){0,2}$/);
  if (!m) return null;
  const major = Number(m[1]);
  return Number.isFinite(major) ? major : null;
}

function applyAceCheck(text, android, ios) {
  const lines = text.split('\n');
  const okMarked = (label) => lines.some((l) => l.includes('[√]') && l.includes(label));
  const badMarked = (label) => lines.some((l) => l.includes('[X]') && l.includes(label));
  if (okMarked('Android toolchains')) {
    removeFrom(android.missing, 'Android SDK');
  } else if (badMarked('Android toolchains') || text.includes('Android SDK is not installed')) {
    if (!android.missing.includes('Android SDK')) android.missing.push('Android SDK');
  }
  if (okMarked('Xcode')) {
    removeFrom(ios.missing, 'Xcode');
  } else if (badMarked('Xcode')) {
    if (!ios.missing.includes('Xcode')) ios.missing.push('Xcode');
  }
}

function probe(status, name, exec) {
  if (status.missing.includes(`需 macOS`)) return; // 平台不可用时分项不重复报
  let ok = false;
  try {
    const result = exec();
    ok = result.status === 0;
  } catch {
    ok = false;
  }
  if (!ok && !status.missing.includes(name)) status.missing.push(name);
  if (ok) removeFrom(status.missing, name);
}

function removeFrom(list, name) {
  const idx = list.indexOf(name);
  if (idx !== -1) list.splice(idx, 1);
}
