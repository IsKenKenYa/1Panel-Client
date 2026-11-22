import { existsSync, readdirSync, readFileSync } from 'node:fs';
import { spawnSync } from 'node:child_process';
import { join, relative, sep } from 'node:path';

/**
 *（Windows 实证）：统一 ace 子进程启动。
 * - aceBin 以 .js 结尾（mock/benchmark）→ 经 process.execPath 执行（Windows 无法直接执行 .js，顺带修复 mock 跨平台）
 * - win32（ace.cmd / 裸 ace 靠 PATH 解析）→ shell:true（Node ≥ 18.20/20.12 对 .cmd/.bat 无 shell 启动抛 EINVAL，
 *   CVE-2024-27980 安全策略）；含空格/括号参数双引号转义；
 *   路径形态的 aceBin 先做存在性检查——shell 模式下 cmd 对不存在路径返回非零退出码而非 ENOENT，
 *   合成 ENOENT 保持与 posix spawn 一致的"命令不可用"语义（跨平台失败原因稳定）
 * - 其余平台原样 spawnSync
 * @param {{platform?: string, spawnSync?: Function}} opts 可注入（单测）
 */
export function spawnAce(aceBin, args, opts = {}) {
  const platform = opts.platform || process.platform;
  const run = opts.spawnSync || spawnSync;
  const spawnOpts = { ...opts.spawnOpts };
  if (/\.(js|mjs|cjs)$/i.test(aceBin)) {
    return run(process.execPath, [aceBin, ...args], spawnOpts);
  }
  if (platform === 'win32') {
    if (/[/\\]/.test(aceBin) && !existsSync(aceBin)) {
      const err = new Error(`spawnSync ${aceBin} ENOENT`);
      err.code = 'ENOENT';
      return { status: null, stdout: '', stderr: '', error: err };
    }
    const quoted = [aceBin, ...args].map((a) => (/[\s()&^|<>]/.test(a) ? `"${a}"` : a));
    return run(quoted.join(' '), { ...spawnOpts, shell: true });
  }
  return run(aceBin, args, spawnOpts);
}

/** modify 前置校验（design 代码事实 3：缺构建三件套被 ace 拒绝） */
const PREFLIGHT_FILES = ['build-profile.json5', 'oh-package.json5', 'hvigorfile.ts'];

/** 默认超时阈值（真实工程探查约 5 分钟定值） */
export const DEFAULT_TIMEOUT_MS = 300000;

/** 平台选项 → ace modify 交互应答映射（1=双平台/2=Android/3=iOS） */
export const PLATFORM_ANSWERS = { both: '1', android: '2', ios: '3' };

/**
 * 超时阈值解析（design「超时与 ARKUIX_ACE_TIMEOUT_MS 设计」固化）：
 * 显式参数 > 环境变量 ARKUIX_ACE_TIMEOUT_MS > 默认 300000ms；
 * 环境变量非法（非正整数）→ stderr 警告后回默认；进程启动时读取一次。
 */
export function resolveTimeoutMs(explicitMs, env = process.env) {
  if (explicitMs !== undefined && explicitMs !== null) return explicitMs;
  const raw = env.ARKUIX_ACE_TIMEOUT_MS;
  if (raw === undefined || raw === '') return DEFAULT_TIMEOUT_MS;
  const value = Number(raw);
  if (!Number.isInteger(value) || value <= 0) {
    console.error(`警告: ARKUIX_ACE_TIMEOUT_MS 非法值 "${raw}"（须为正整数毫秒），回退默认 ${DEFAULT_TIMEOUT_MS}ms`);
    return DEFAULT_TIMEOUT_MS;
  }
  return value;
}

export function preflight(root) {
  const missing = PREFLIGHT_FILES.filter((f) => !existsSync(join(root, f)));
  return { ok: missing.length === 0, missing };
}

/**
 * 调用 ace modify --project（平台选项映射）：
 * - 交互喂答：stdin 写入平台应答（1=双平台/2=Android/3=iOS）
 * - 成功判据：与 platform 一致的平台壳目录在场
 * - 失败路径：非零退出/超时 → {ok:false, reason}（调用方提示建议 new + 实际改动清单）
 *
 * @param {{aceBin?: string, timeoutMs?: number, platform?: 'both'|'android'|'ios'}} options
 */
export function invokeModify(root, options = {}) {
  const aceBin = options.aceBin || 'ace';
  const timeoutMs = options.timeoutMs || DEFAULT_TIMEOUT_MS;
  const platform = options.platform || 'both';
  const answer = PLATFORM_ANSWERS[platform];

 //--modify-entry <module> 支持多模块非 TTY 管道喂答
 // 按序喂 [平台应答, entry 应答]，绕过二级交互的管道崩溃问题
  if (options.modifyEntry) {
    const input = `${answer}\n${options.modifyEntry}\n`;
    const result = spawnAce(aceBin, ['modify', '--project'], {
      spawnOpts: { cwd: root, input, encoding: 'utf8', timeout: timeoutMs }
    });
    return interpretModifyResult(result, root, platform, timeoutMs);
  }

 // 已知坑前置避让（实测）：多模块工程的 modify 二级交互在管道模式下必崩
 // ——提前读 build-profile.json5 检测多模块，TTY 环境直接走透传（跳过必崩的管道尝试）
  const multiModule = isMultiModule(root);
  const skipPipe = multiModule && process.stdin.isTTY;

  if (skipPipe) {
 // 坑④：进入透传前打印完整题面预告
    console.log(`
检测到多模块工程，ace modify 将有二级交互，已切换 TTY 透传模式。
即将出现的问题：
  1. 平台选择      ${answer} = ${platform}（已预选，但需在终端确认）
  2. 跨平台 entry   请输入模块名（如 entry，见 build-profile.json5 的 modules[].name）
`);
    const result = spawnAce(aceBin, ['modify', '--project'], {
      spawnOpts: {
        cwd: root,
        stdio: ['inherit', 'inherit', 'inherit'],
        timeout: timeoutMs
      }
    });
    return interpretModifyResult({ ...result, stdout: '', stderr: '（TTY 透传模式：输出已直达终端）' },
      root, platform, timeoutMs);
  }

  let result = spawnAce(aceBin, ['modify', '--project'], {
    spawnOpts: {
      cwd: root,
      input: `${answer}\n`,
      encoding: 'utf8',
      timeout: timeoutMs
    }
  }); // 管道崩溃 + TTY → 透传重试（兜底：未在前置检测中避让的场景）
  const raw = `${result.stdout || ''}${result.stderr || ''}`;
  if (raw.includes('ERR_USE_AFTER_CLOSE') && process.stdin.isTTY) {
    console.log('\nace 管道交互崩溃（工具已知限制），切换 TTY 透传模式。');
    console.log('即将出现的问题：');
    console.log('  1. 平台选择      按提示输入（1=双平台/2=Android/3=iOS）');
    console.log('  2. [多模块时] 跨平台 entry 模块名（如 entry）');
    const retry = spawnAce(aceBin, ['modify', '--project'], {
      spawnOpts: {
        cwd: root,
        stdio: ['inherit', 'inherit', 'inherit'],
        timeout: timeoutMs
      }
    });
    result = { ...retry, stdout: '', stderr: '（TTY 透传模式：输出已直达终端）' };
  } else if (raw.includes('ERR_USE_AFTER_CLOSE')) {
 // 坑③：非 TTY 环境下崩溃 → 替换堆栈为人话
    result = { ...result,
      stderr: 'ace 交互在管道模式下崩溃（多模块工程的已知限制）。\n' +
        '解决方式：\n' +
        '  A. 在 TTY 终端运行本命令（自动透传交互）\n' +
        '  B. 手动执行 ace modify --project 后重跑本命令（幂等跳过）\n' +
        '  C. 改用 new 模式（--mode new）'
    };
  }

  return interpretModifyResult(result, root, platform, timeoutMs);
}

/** 检测工程是否多模块（build-profile.json5 modules > 1）——管道 modify 交互已知坑的前置避让 */
function isMultiModule(root) {
  try {
    const bp = readFileSync(join(root, 'build-profile.json5'), 'utf8');
    const doc = JSON.parse(bp
      .replace(/\/\*[\s\S]*?\*\//g, '')
      .replace(/\/\/.*$/gm, '')
      .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3')
      .replace(/'([^'\\]*)'/g, '"$1"')
      .replace(/,(\s*[}\]])/g, '$1'));
    return (doc?.modules ?? []).length > 1;
  } catch {
    return false;
  }
}

/**：采集 ace modify 的 WARN 级提示，供成功产物沉淀（编译前必办事项） */
export function collectAceWarnings(stdout, stderr, root) {
  const lines = `${stdout || ''}\n${stderr || ''}`
    .split(/\r?\n/)
    .map((l) => l.trim())
    .filter((l) => /\bWARN\b/i.test(l));
 // TTY 透传模式 stdout 直达终端不可捕获 → 静态复核已知必办项（触发条件确定：build-profile 含该项即 WARN）
  try {
    const bp = readFileSync(join(root, 'build-profile.json5'), 'utf8');
    if (/useNormalizedOHMUrl/.test(bp) && !lines.some((l) => l.includes('useNormalizedOHMUrl'))) {
      lines.push("WARN: arkui-x project must delete the 'useNormalizedOHMUrl' Setting Items in build-profile.json5");
    }
  } catch { /* build-profile 缺失（幂等 new 等场景）→ 跳过静态复核 */ }
  return [...new Set(lines)];
}

function interpretModifyResult(result, root, platform, timeoutMs) {
  if (result.signal === 'SIGTERM' || result.error?.code === 'ETIMEDOUT') {
    return { ok: false, reason: `ace modify 超时（>${timeoutMs}ms）被终止`, stdout: result.stdout || '', stderr: result.stderr || '' };
  }
  if (result.error) {
    return { ok: false, reason: `ace 命令不可用（${result.error.message}）；请确认 ArkUI-X SDK toolchains 在 PATH 或以 --ace-bin 指定`, stdout: '', stderr: '' };
  }
  if (result.status !== 0) {
    const tail = tailOf(result.stderr || result.stdout);
    return { ok: false, reason: `ace modify 失败（退出码 ${result.status}）${tail ? `：${tail}` : ''}`, stdout: result.stdout || '', stderr: result.stderr || '' };
  }

  const androidShell = join(root, '.arkui-x', 'android');
  const iosShell = join(root, '.arkui-x', 'ios'); // 仅断言所选平台壳在场（both→双；android→android/；ios→ios/）
  const missing = [];
  if (platform === 'both' || platform === 'android') {
    if (!existsSync(androidShell)) missing.push('.arkui-x/android');
  }
  if (platform === 'both' || platform === 'ios') {
    if (!existsSync(iosShell)) missing.push('.arkui-x/ios');
  }
  if (missing.length > 0) {
    return {
      ok: false,
      reason: `ace modify 退出码 0 但未检出所选平台壳 ${missing.join(' 与 ')}（断言失败）`,
      stdout: result.stdout || '', stderr: result.stderr || ''
    };
  }
  return {
    ok: true,
    artifacts: {
      // 壳路径契约值归一 '/'（win32 join 产生 '\'，报告/断言跨平台稳定；existsSync 对两种分隔符均可用）
      androidShell: androidShell.split(sep).join('/'),
      iosShell: iosShell.split(sep).join('/'),
      changedFiles: walkTop(join(root, '.arkui-x'))
    },
    stdout: result.stdout || '',
    stderr: result.stderr || ''
  };
}

/** 实际改动文件清单（成功与失败路径均输出） */
export function walkTop(dir) {
  const out = [];
  collectRel(dir, dir, out, 0);
  return out.sort();
}

function collectRel(root, dir, out, depth) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    const full = join(dir, entry.name);
 // 相对路径归一为 / 分隔（Windows join 产生 \；报告/断言跨平台稳定）
    const rel = relative(root, full).split(sep).join('/');
    if (entry.isDirectory()) {
      out.push(`${rel}/`);
      if (depth < 1) collectRel(root, full, out, depth + 1);
    } else {
      out.push(rel);
    }
  }
}

function tailOf(text) {
  if (!text) return '';
  const lines = text.trim().split('\n');
  return lines.slice(-3).join(' | ');
}
