#!/usr/bin/env node
/**
 * arkts-check.js — One-shot ArkTS static syntax checker for HarmonyOS projects.
 *
 * Directly drives DevEco Studio's own ArkTS language server (ace-server,
 * shipped with DevEco Studio under plugins\openharmony) over standard LSP.
 * NO deveco-cli installation required — the script discovers DevEco Studio
 * itself (env var / registry / common paths) and spawns ace-server directly.
 * No AI extension / CodeGenie of any kind is needed: ace-server is part of
 * the core DevEco Studio IDE distribution.
 *
 * Usage:
 *   node arkts-check.js --project <abs-project-root> <file.ets...> [options]
 *
 * Options:
 *   --json              Output structured JSON instead of text lines
 *   --studio <path>     Explicit DevEco Studio install root (or env DEVECO_STUDIO_PATH)
 *   --max-old-space MB  LSP heap size                    (default 8192)
 *   --init-timeout ms   LSP initialize timeout           (default 180000)
 *   --diag-timeout ms   Per-file diagnostic timeout      (default 90000)
 *   --settle ms         Max wait for server quiet after init (default 15000)
 *   --retries N         Retry empty-result files N times (default 0)
 *   --debug             Dump LSP notifications to stderr
 *   --quiet             Suppress progress messages on stderr
 *
 * Exit codes:
 *   0  ran successfully, no error-severity diagnostics
 *   1  ran successfully, >=1 file has error-severity (severity===1) diagnostics
 *   2  operational failure (DevEco Studio not found, server didn't start, ...)
 *
 * Requirements: DevEco Studio (>= 26.0.0.610, standard LSP entry) installed.
 * Node.js is needed to run this script — any Node >= 16 works; if Node is not
 * on PATH, use arkts-check.ps1 (Windows) / arkts-check.sh (macOS) launchers,
 * which fall back to DevEco Studio's bundled node.
 *
 * Platform support:
 *   - Windows: fully implemented and tested.
 *   - macOS:   best-effort, NOT yet verified on a real Mac（未真机验证）—
 *              discovery scans /Applications and ~/Applications for *.app
 *              bundles whose name contains "deveco"; the Mac install-layout
 *              assumptions (Contents/plugins/..., Contents/tools/node/bin/node)
 *              follow IntelliJ-platform conventions and devecocli's own Mac
 *              logic but have not been run on real hardware. If discovery or
 *              validation fails on a Mac, pass
 *              --studio "<path>/DevEco Studio.app" (or set DEVECO_STUDIO_PATH)
 *              to point at the install manually.
 *   - Linux:   NOT supported — DevEco Studio has no Linux build, so the
 *              standard-LSP engine this script drives does not exist there.
 */
'use strict';

const { spawn, execFileSync } = require('child_process');
const fs = require('fs');
const os = require('os');
const path = require('path');

/* =====================================================================
 * 架构总览（维护者向）
 *
 *   解析参数、校验工程与文件
 *        ↓
 *   发现 DevEco Studio（能力检测，非版本号比较）→ 失败即退出码 2，无兜底
 *        ↓
 *   直接 spawn ace-server 子进程（参数复刻 devecocli serve lsp 内部行为）
 *        ↓
 *   LSP 握手：initialize → 校验 diagnosticProvider 能力 → initialized
 *        ↓
 *   settle：等服务器索引通知静默（防止读到误导性的空诊断）
 *        ↓
 *   逐文件：didOpen → textDocument/diagnostic（拉取式）→ didClose
 *        ↓
 *   shutdown/exit 清理 → 输出结果，退出码 0（无 error）/ 1（有 error）
 *
 * 方案成立的钥匙：ace-server 以 --projectPath 启动时会自行解析工程并
 * 构造 initializationOptions（覆盖客户端发的内容），因此本脚本只需最薄的
 * 标准 LSP 握手，无需复刻 devecocli 的工程解析/模块模型构建。
 *
 * 输出流约定：检查结果走 stdout；进度/日志走 stderr（--quiet 可关）。
 *
 * 设计边界：本脚本不做"借道 devecocli serve lsp"的兜底 —— 它存在的意义
 * 就是服务没有 devecocli 的环境；发现不了 DevEco Studio 时直接失败并给出
 * 指引（见 main 开头）。装有 devecocli 的环境应优先用 devecocli 本身。
 * ===================================================================== */

// ============================== 1. 命令行参数与输入校验 ==============================

// 所有可调项集中于此；命令行解析只做"选项 → 覆盖默认值"这一件事。
const opts = {
  json: false,         // --json：结果以结构化 JSON 输出（供 agent 解析）
  studio: null,        // --studio：显式指定 DevEco Studio 安装根目录（跳过自动发现）
  maxOldSpace: 8192,   // ace-server 子进程的 --max-old-space-size（MB）
  initTimeout: 180000, // initialize 请求超时（冷启动时工程解析都在这段时间内完成）
  diagTimeout: 90000,  // 单文件 textDocument/diagnostic 请求超时
  quiet: false,        // --quiet：关闭 stderr 进度信息
  debug: false,        // --debug：把 LSP 通知/响应摘要打到 stderr（排障用）
  settle: 15000,       // initialize 后等待服务器"安静"的上限（毫秒）
  retries: 0,          // 空结果重试次数（默认 0：settle 后诊断立即可得，空结果基本是真没问题）
  retryDelay: 5000,    // 重试间隔（毫秒）
};
const files = [];   // 位置参数：待检查的 .ets 文件路径（绝对路径或相对工程根）
let project = null; // --project：目标 HarmonyOS 工程根目录

const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  const a = argv[i];
  if (a === '--json') opts.json = true;
  else if (a === '--quiet') opts.quiet = true;
  else if (a === '--debug') opts.debug = true;
  else if (a === '--studio') opts.studio = argv[++i];
  else if (a === '--max-old-space') opts.maxOldSpace = Number(argv[++i]);
  else if (a === '--init-timeout') opts.initTimeout = Number(argv[++i]);
  else if (a === '--diag-timeout') opts.diagTimeout = Number(argv[++i]);
  else if (a === '--settle') opts.settle = Number(argv[++i]);
  else if (a === '--retries') opts.retries = Number(argv[++i]);
  else if (a === '--help' || a === '-h') { usage(); process.exit(0); }
  else if (a === '--project' || a === '-p') project = argv[++i];
  else files.push(a);
}

function usage() {
  console.log('Usage: node arkts-check.js --project <abs-project-root> <file.ets...> [--json] [--studio <path>] [options]');
}

// 统一的致命错误出口：
// - --json 模式把错误打进 stdout（{ok:false,error}，agent 好捕获）
// - 普通模式打 stderr；退出码固定 2（运行失败）
function fail(msg, code = 2) {
  if (opts.json) console.log(JSON.stringify({ ok: false, error: msg }));
  else console.error('ERROR: ' + msg);
  process.exit(code);
}

// 进度信息一律走 stderr，保证 stdout 只有检查结果（结果流/日志流分离）。
// --json 时同样静默，避免污染 agent 对 stdout 的解析。
function note(msg) {
  if (!opts.quiet && !opts.json) process.stderr.write(`[arkts-check] ${msg}\n`);
}

// 必须显式给出工程根
if (!project) fail('Missing --project <project-root>');
project = path.resolve(project);
// 以 build-profile.json5 的存在作为"HarmonyOS 工程根"的判定标志
if (!fs.existsSync(path.join(project, 'build-profile.json5'))) {
  fail(`Not a HarmonyOS project root (no build-profile.json5): ${project}`);
}
if (files.length === 0) fail('No files to check. Pass .ets file paths (absolute, or relative to project root).');

// 逐个文件解析与校验：
// - 相对路径以工程根为基准解析
// - 必须存在、必须是 .ets（本脚本只覆盖 ArkTS）
// - 必须位于工程根之内：ace-server 只诊断工程内文件，越界文件会得到误导性的空诊断
const resolvedFiles = files.map((f) => {
  const abs = path.resolve(path.isAbsolute(f) ? f : path.join(project, f));
  if (!fs.existsSync(abs)) fail(`File does not exist: ${f} (resolved ${abs})`);
  if (!abs.toLowerCase().endsWith('.ets')) fail(`Not an .ets file: ${f} (this script checks ArkTS only)`);
  const rel = path.relative(project, abs);
  if (rel.startsWith('..')) fail(`File outside project root: ${abs}`);
  return abs;
});

// ============================== 2. 发现 DevEco Studio ==============================
// 判定标准是"能力检测"而非版本号比较：安装里存在标准 LSP 入口
// （ace-server\out\standardIndex\index.js）即可用 —— 这是脚本唯一硬依赖。

// 执行一次 `reg query ...`，返回 stdout 文本；任何失败返回 null。
// reg.exe 是 Windows 自带组件，因此查注册表不需要任何 npm 依赖。
function regQuery(args) {
  try {
    return execFileSync('reg', args, { encoding: 'utf8', stdio: ['ignore', 'pipe', 'ignore'], windowsHide: true });
  } catch { return null; }
}

// 从 reg 输出中提取 REG_SZ 值。按 "REG_SZ" 关键字定位而不是按 "(默认)" 值名定位：
// 值名会被系统本地化（中文系统显示"(默认)"，其他语言不同），REG_SZ 关键字是稳定的。
function regParseRegSz(out) {
  if (!out) return null;
  for (const line of out.split(/\r?\n/)) {
    const m = /^\s*.*?REG_SZ\s+(.+?)\s*$/.exec(line);
    if (m) return m[1];
  }
  return null;
}

// 从 reg 输出中提取子键路径列表（形如 HKEY_LOCAL_MACHINE\... 的行）。
function regSubkeys(out) {
  if (!out) return [];
  return out.split(/\r?\n/).map((l) => l.trim()).filter((l) => /^HKEY_/i.test(l));
}

/** 校验一个候选目录是否为可用的 DevEco Studio 安装；可用返回工具链信息，不可用返回 null。 */
function validateStudio(root) {
  if (!root || typeof root !== 'string') return null;
  // 容错：去首尾空白与引号；macOS 上自动补 .app 后缀
  let base = path.resolve(root.trim().replace(/^"|"$/g, ''));
  if (!fs.existsSync(base)) return null;
  const isMac = process.platform === 'darwin';
  if (isMac && !base.endsWith('.app')) base = `${base}.app`;
  const contents = isMac ? path.join(base, 'Contents') : base;
  // 第一道门槛（身份判定）：Windows 用 product-info.json；macOS 接受 Info.plist
  // 或 Contents/Resources/product-info.json（IntelliJ 平台两种布局；devecocli 的
  // mac 校验用的就是 Info.plist）。【macOS 分支未真机验证】
  if (isMac) {
    if (!fs.existsSync(path.join(contents, 'Info.plist'))
      && !fs.existsSync(path.join(contents, 'Resources', 'product-info.json'))) return null;
  } else if (!fs.existsSync(path.join(contents, 'product-info.json'))) {
    return null;
  }
  // 第二道门槛（唯一硬条件）：标准 LSP 入口存在
  // - 没有 standardIndex 但有旧版 out\index.js → 老版本安装，明确抛错说明原因
  //   （用户显式指定的路径是老版本时，应告知"为什么不行"而不是静默跳过）
  // - 两者都没有 → 不是有效候选，返回 null 继续找下一个
  const aceEntry = path.join(contents, 'plugins', 'openharmony', 'ace-server', 'out', 'standardIndex', 'index.js');
  const legacyEntry = path.join(contents, 'plugins', 'openharmony', 'ace-server', 'out', 'index.js');
  if (!fs.existsSync(aceEntry)) {
    if (fs.existsSync(legacyEntry)) {
      throw new Error(`DevEco Studio at "${base}" only ships the legacy LSP entry. This script needs the standard LSP entry (ace-server\\out\\standardIndex\\index.js, DevEco Studio >= 26.0.0.610).`);
    }
    return null;
  }
  // 顺带收集（可能为 null）：SDK 目录、DevEco 自带的 node.exe。
  // mac 自带 node 按 Unix 布局推测在 tools/node/bin/node【macOS 分支未真机验证】
  const sdkPath = path.join(contents, 'sdk');
  const bundledNode = isMac
    ? path.join(contents, 'tools', 'node', 'bin', 'node')
    : path.join(contents, 'tools', 'node', 'node.exe');
  return {
    studioRoot: base,
    aceEntry,
    sdkPath: fs.existsSync(sdkPath) ? sdkPath : null,
    bundledNode: fs.existsSync(bundledNode) ? bundledNode : null,
  };
}

// 候选来源按优先级：显式覆盖 > 注册表 > 常见路径。
// 注册表键位与默认路径和 devecocli 的发现逻辑同源（正常安装都能被自动发现）。
function discoverStudio() {
  const candidates = [];
  // 1. 显式覆盖：--studio 参数 / 环境变量。
  //    DEVECO_STUDIO_PATH 为本脚本专用；DEVECO_CLI_STUDIO_PATH 沿用 devecocli
  //    的变量名，方便已有环境直接复用。
  if (opts.studio) candidates.push(opts.studio);
  for (const envName of ['DEVECO_STUDIO_PATH', 'DEVECO_CLI_STUDIO_PATH']) {
    if (process.env[envName]) candidates.push(process.env[envName]);
  }
  if (process.platform === 'win32') {
    // 2. 注册表：HKLM\SOFTWARE\[WOW6432Node\]Huawei\DevEco Studio\<版本子键> 的默认值
    //    （正常安装都会在此登记版本子键，默认值即安装路径）
    for (const root of ['HKLM\\SOFTWARE\\Huawei\\DevEco Studio', 'HKLM\\SOFTWARE\\WOW6432Node\\Huawei\\DevEco Studio']) {
      const subs = regSubkeys(regQuery(['query', root]));
      for (const sk of subs) candidates.push(regParseRegSz(regQuery(['query', sk, '/ve'])));
    }
    // 3. 注册表：Uninstall 键里显示名以 "deveco studio" 开头的项的 InstallLocation
    //    （兜住自定义安装目录且只在 Uninstall 登记的情况）
    for (const root of [
      'HKLM\\SOFTWARE\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
      'HKLM\\SOFTWARE\\WOW6432Node\\Microsoft\\Windows\\CurrentVersion\\Uninstall',
    ]) {
      for (const sk of regSubkeys(regQuery(['query', root]))) {
        const name = sk.split('\\').pop() || '';
        if (name.normalize('NFKC').trim().toLowerCase().startsWith('deveco studio')) {
          candidates.push(regParseRegSz(regQuery(['query', sk, '/v', 'InstallLocation'])));
        }
      }
    }
    // 4. 常见安装路径
    candidates.push('C:\\Program Files\\Huawei\\DevEco Studio', 'C:\\Program Files (x86)\\Huawei\\DevEco Studio');
  } else if (process.platform === 'darwin') {
    // macOS：先探标准位置，再扫描应用目录里任何名字含 "deveco" 的 .app
    // （复刻 devecocli 的 mac 发现方式，可兜住 "DevEco Studio Preview.app" 等
    //  非默认命名）。【macOS 分支未真机验证】
    candidates.push('/Applications/DevEco Studio.app', path.join(process.env.HOME ?? '', 'Applications', 'DevEco Studio.app'));
    for (const dir of ['/Applications', path.join(process.env.HOME ?? '', 'Applications')]) {
      try {
        for (const name of fs.readdirSync(dir)) {
          if (name.toLowerCase().endsWith('.app') && name.toLowerCase().includes('deveco')) {
            candidates.push(path.join(dir, name));
          }
        }
      } catch { /* 目录不存在或不可读 → 跳过 */ }
    }
  }
  // Linux：DevEco Studio 没有 Linux 版本（标准 LSP 引擎不存在），无自动发现
  // 可言 —— 候选只剩显式覆盖（--studio / 环境变量），最终在 main 开头干净失败。
  // 逐个候选尝试校验，第一个通过者即采用
  for (const c of candidates) {
    const tc = validateStudio(c);
    if (tc) return tc;
  }
  return null;
}

const toolchain = discoverStudio();

// ============================== 3. 极简 LSP 客户端 ==============================

// Windows 路径 → LSP 的 file:// URI（反斜杠转正斜杠、盘符大写、file:/// 三个斜杠）
function toUri(p) {
  let s = p.replace(/\\/g, '/');
  if (/^[a-zA-Z]:/.test(s)) s = s[0].toUpperCase() + s.slice(1);
  return s.startsWith('/') ? `file://${s}` : `file:///${s}`;
}

// 只实现了本任务所需的最小 LSP 子集：
// - Content-Length 帧格式的收发（LSP over stdio 的标准传输层）
// - 带超时的请求/响应配对（JSON-RPC id 机制）
// - 通知收集 + onNotification 回调
// - 对"服务器→客户端请求"的自动应答（防止服务器等待回复而挂起）
class LspClient {
  constructor(proc) {
    this.proc = proc;
    this.buf = Buffer.alloc(0);   // stdout 数据的拼接缓冲区（帧可能被拆在多个 chunk 里）
    this.nextId = 1;              // JSON-RPC 请求 id 计数器
    this.pending = new Map();     // id → {resolve, reject, timer, method}：挂起中的请求
    this.notifications = [];      // 收到的全部通知（存档）
    this.onNotification = () => {}; // 通知回调（settle 阶段用来感知服务器活跃度）
    proc.stdout.on('data', (d) => this._feed(d));
    // stderr 只保留末尾 4000 字符：失败时要留线索，又不能被 TRACE 级日志淹没
    proc.stderr.on('data', (d) => { this.stderrTail = ((this.stderrTail || '') + d.toString('utf8')).slice(-4000); });
  }
  // 流式到达的 stdout 数据按 Content-Length 帧协议切包：
  // 找 \r\n\r\n 头体分界 → 解析 Content-Length → buffer 够一整帧才取 JSON
  // （不够说明是半帧，return 等下一个 chunk）；解析失败的帧直接丢弃继续。
  _feed(d) {
    this.buf = Buffer.concat([this.buf, d]);
    for (;;) {
      const headerEnd = this.buf.indexOf('\r\n\r\n');
      if (headerEnd < 0) return;
      const header = this.buf.slice(0, headerEnd).toString('ascii');
      const m = /Content-Length:\s*(\d+)/i.exec(header);
      if (!m) { this.buf = this.buf.slice(headerEnd + 4); continue; }
      const len = Number(m[1]);
      if (this.buf.length < headerEnd + 4 + len) return;
      const body = this.buf.slice(headerEnd + 4, headerEnd + 4 + len).toString('utf8');
      this.buf = this.buf.slice(headerEnd + 4 + len);
      let msg;
      try { msg = JSON.parse(body); } catch { continue; }
      this._dispatch(msg);
    }
  }
  // JSON-RPC 三种消息分流：
  // 1) 有 id + method → 服务器→客户端的"请求"：必须应答，否则服务器可能一直等。
  //    统一回 null，唯独 workspace/configuration 回 [] —— LSP 规范要求其结果必须是数组。
  // 2) 有 id + result/error → 对我方请求的"响应"：按 id 找到挂起的 Promise 并了结。
  // 3) 只有 method → "通知"：存档 + 触发回调。
  _dispatch(msg) {
    if (msg.id !== undefined && msg.method !== undefined) {
      if (opts.debug) process.stderr.write(`[debug] server request: ${msg.method}\n`);
      const result = msg.method === 'workspace/configuration' ? [] : null;
      this._send({ jsonrpc: '2.0', id: msg.id, result });
      return;
    }
    if (msg.id !== undefined && (msg.result !== undefined || msg.error !== undefined)) {
      const p = this.pending.get(msg.id);
      if (p) {
        this.pending.delete(msg.id);
        clearTimeout(p.timer);
        if (msg.error) p.reject(new Error(`${p.method}: ${msg.error.message} (${msg.error.code})`));
        else p.resolve(msg.result);
      }
      return;
    }
    if (msg.method) {
      this.notifications.push(msg);
      if (opts.debug) {
        const p = JSON.stringify(msg.params ?? {});
        process.stderr.write(`[debug] notification: ${msg.method} ${p.length > 300 ? p.slice(0, 300) + '…' : p}\n`);
      }
      this.onNotification(msg);
    }
  }
  // 发送：JSON-RPC 消息按 Content-Length 帧格式写入子进程 stdin
  _send(obj) {
    const body = JSON.stringify(obj);
    this.proc.stdin.write(`Content-Length: ${Buffer.byteLength(body)}\r\n\r\n${body}`);
  }
  // 发请求并挂起等待响应；超时未响应直接 reject，防止整个脚本卡死在无响应的服务器上
  request(method, params, timeoutMs) {
    const id = this.nextId++;
    return new Promise((resolve, reject) => {
      const timer = setTimeout(() => {
        this.pending.delete(id);
        reject(new Error(`${method} timed out after ${timeoutMs}ms`));
      }, timeoutMs);
      this.pending.set(id, { resolve, reject, timer, method });
      this._send({ jsonrpc: '2.0', id, method, params: params ?? null });
    });
  }
  // 发通知（无需应答）
  notify(method, params) {
    this._send({ jsonrpc: '2.0', method, params: params ?? {} });
  }
  // 标准的 LSP 关闭礼仪：shutdown 请求 → exit 通知 → 最多等 3 秒 → 强杀。
  // 目的：不留孤儿 ace-server 进程（它可能还带着 worker 子进程）。
  async dispose() {
    try { await this.request('shutdown', null, 10000); } catch { /* best effort */ }
    this.notify('exit');
    const dead = new Promise((r) => this.proc.on('exit', r));
    await Promise.race([dead, new Promise((r) => setTimeout(r, 3000))]);
    if (this.proc.exitCode === null) this.proc.kill();
  }
}

// ============================== 4. 主流程 ==============================
async function main() {
  note(`project: ${project}`);

  // 发现不了 DevEco Studio 就立刻失败并给出指引（本脚本无兜底，见架构总览）
  if (!toolchain) {
    fail('DevEco Studio not found. Install DevEco Studio (>= 26.0.0.610), or pass --studio <install-root>, or set DEVECO_STUDIO_PATH.');
  }

  // ace-server 的日志/崩溃报告目录：成功结束时删除；失败时保留并把路径打出来
  const tmpLogDir = fs.mkdtempSync(path.join(os.tmpdir(), 'arkts-check-'));

  // 子进程优先用 DevEco 自带的 node（与 ace-server 配套的版本）；
  // 缺失时退回当前进程的 node（实测 v24 也能正常运行 ace-server）
  const nodeBin = toolchain.bundledNode || process.execPath;
  const serverDesc = `${nodeBin} <ace-server standardIndex> --stdio (DevEco Studio: ${toolchain.studioRoot})`;
  note(`starting ace-server directly from DevEco Studio: ${toolchain.studioRoot}`);

  // 启动参数完全复刻 devecocli serve lsp 的内部行为（保证与 MCP check 工具同源）：
  // - --expose-gc / --max-old-space-size / --report-*：让 ace-server 可控地跑在
  //   大堆内存下，崩溃时留下诊断报告文件
  // - --stdio：以标准输入输出为传输层（LSP over stdio）
  // - --logger-path / --logger-level：ace-server 自身的日志输出位置
  // - --projectPath：ace-server 据此自行解析工程（方案成立的钥匙，见架构总览）
  // - --sdkPath：SDK 目录
  const serverArgs = [
    '--expose-gc',
    `--max-old-space-size=${opts.maxOldSpace}`,
    '--report-on-fatalerror', '--report-uncaught-exception',
    `--report-filename=nodejs_error_${Date.now()}.txt`, `--report-dir=${tmpLogDir}`,
    toolchain.aceEntry,
    '--stdio',
    `--logger-path=${tmpLogDir}`, '--logger-level=TRACE',
    `--projectPath=${project}`,
  ];
  if (toolchain.sdkPath) serverArgs.push(`--sdkPath=${toolchain.sdkPath}`);
  const child = spawn(nodeBin, serverArgs, { stdio: ['pipe', 'pipe', 'pipe'], windowsHide: true });
  if (opts.debug) note(`server: ${serverDesc}`);

  // spawn 本身失败（如 node 路径无效）会触发 error 事件 —— 用 Promise 捕获，
  // 并与 initialize 请求赛跑，谁先失败先暴露
  const spawnFail = new Promise((_, rej) => child.on('error', (e) => rej(new Error(`failed to start language server: ${e.message}`))));
  const lsp = new LspClient(child);

  const t0 = Date.now();
  try {
    // --- LSP 握手 ---
    // initialize 只带最小字段：ace-server 有了 --projectPath 会自己构造完整的
    // 初始化配置（覆盖客户端发的内容），客户端无需发送模块模型。
    // 冷启动时工程解析全部发生在这次请求里（实测约 3–25 秒）。
    const initResult = await Promise.race([
      lsp.request('initialize', {
        processId: process.pid,
        rootUri: toUri(project),
        capabilities: { textDocument: { diagnostic: {} } },
      }, opts.initTimeout),
      spawnFail,
    ]);
    note(`language server initialized in ${((Date.now() - t0) / 1000).toFixed(1)}s`);
    // 能力校验：响应里没有 diagnosticProvider → 老版本/legacy 入口，明确报错
    const caps = initResult?.capabilities || {};
    if (!caps.diagnosticProvider) {
      throw new Error('ace-server did not advertise diagnostic support — DevEco Studio version may be too old (needs standard LSP entry, >= 26.0.0.610).');
    }
    lsp.notify('initialized', {});

    // --- settle 静默期 ---
    // initialize 响应后服务器仍会继续发索引进度通知。每 250ms 轮询一次：
    // 距最后一条通知 ≥2 秒（服务器安静了）或总时长到 --settle 上限就放行。
    // 防止对着还在建索引的服务器查询，拿到误导性的空结果。
    if (opts.settle > 0) {
      note(`settling: waiting up to ${opts.settle}ms for server activity to quiet down…`);
      const startT = Date.now();
      let last = Date.now();
      lsp.onNotification = () => { last = Date.now(); };
      await new Promise((resolve) => {
        const iv = setInterval(() => {
          if (Date.now() - last >= 2000 || Date.now() - startT >= opts.settle) {
            clearInterval(iv);
            resolve();
          }
        }, 250);
      });
      note(`settled after ${((Date.now() - t0) / 1000).toFixed(1)}s since start`);
    }

    // --- 逐文件检查 ---
    const results = [];
    for (const abs of resolvedFiles) {
      const text = fs.readFileSync(abs, 'utf8');
      const uri = toUri(abs);
      let diags = [];
      let error = null;
      let attempt = 0;
      for (;;) {
        attempt++;
        // didOpen：把文件全文推给服务器（languageId 固定 arkts；
        // version 用尝试次数保证递增，符合 LSP 对版本号单调的要求）
        lsp.notify('textDocument/didOpen', { textDocument: { uri, languageId: 'arkts', text, version: attempt } });
        try {
          // 拉取式诊断（LSP 3.17+）：服务器同步返回该文件的全部诊断
          const resp = await lsp.request('textDocument/diagnostic', { textDocument: { uri } }, opts.diagTimeout);
          if (opts.debug) process.stderr.write(`[debug] diagnostic response: ${JSON.stringify(resp)?.slice(0, 400)}\n`);
          // 响应形状：标准是 {kind:'full', resultId, items:[...]} —— 读 resp.items。
          // （曾按直觉读 resp.result 拿到过恒空的结果，items 才是标准字段；
          //   后两个分支仅为形状容错保留）
          diags = Array.isArray(resp?.items) ? resp.items : (Array.isArray(resp) ? resp : (Array.isArray(resp?.result) ? resp.result : []));
        } catch (e) {
          error = e.message;
          diags = [];
        }
        lsp.notify('textDocument/didClose', { textDocument: { uri } });
        // 空结果重试（默认关闭）：settle 后空结果基本就是真没问题，
        // 重试只会白费时间；此开关留给极端情况排障用
        if (error === null && diags.length === 0 && attempt <= opts.retries) {
          note(`no diagnostics for ${path.basename(abs)} (attempt ${attempt}) — retrying in ${opts.retryDelay / 1000}s`);
          await new Promise((r) => setTimeout(r, opts.retryDelay));
          continue;
        }
        break;
      }
      results.push({ file: abs, diagnostics: diags, error });
      note(`checked ${path.basename(abs)}: ${error ? 'ERROR ' + error : diags.length + ' diagnostic(s)'}`);
    }

    // --- 收尾 ---
    await lsp.dispose();
    // 成功路径删除临时日志目录（失败路径在 catch 里保留并提示路径）
    try { fs.rmSync(tmpLogDir, { recursive: true, force: true }); } catch { /* 保留也无妨 */ }

    // severity===1（error 级）是硬阈值：有 error → 退出码 1；
    // warning(2)/提示(3) 不影响退出码，只进输出
    const withErrors = results.filter((r) => (r.diagnostics || []).some((d) => d.severity === 1));
    if (opts.json) {
      console.log(JSON.stringify({
        ok: true,
        project,
        server: serverDesc, // 记录用了哪个 DevEco Studio / 哪条启动路径，便于事后审计
        summary: {
          files: results.length,
          filesWithDiagnostics: results.filter((r) => (r.diagnostics || []).length > 0).length,
          filesWithErrors: withErrors.length,
          totalDiagnostics: results.reduce((n, r) => n + (r.diagnostics || []).length, 0),
        },
        results,
      }, null, 2));
    } else {
      for (const r of results) {
        if (r.error) console.log(`${r.file} => diagnostic failed: ${r.error}`);
        else if (r.diagnostics.length === 0) console.log(`${r.file} => no diagnostics`);
        else console.log(`${r.file} => Diagnostic: ${JSON.stringify(r.diagnostics)}`);
      }
    }
    process.exit(withErrors.length > 0 ? 1 : 0);
  } catch (e) {
    // 失败路径：杀子进程；保留临时日志目录并打印路径（排障线索）；
    // 输出错误信息 + 服务器 stderr 尾巴；退出码 2
    try { child.kill(); } catch { /* ignore */ }
    process.stderr.write(`(server logs kept at: ${tmpLogDir})\n`);
    if (opts.json) console.log(JSON.stringify({ ok: false, error: e.message, serverStderr: lsp.stderrTail || null }));
    else console.error(`ERROR: ${e.message}` + (lsp.stderrTail ? `\n--- server stderr (tail) ---\n${lsp.stderrTail}` : ''));
    process.exit(2);
  }
}

main();
