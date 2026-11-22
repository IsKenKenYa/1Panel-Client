
import { readFileSync, readdirSync, existsSync } from 'node:fs';
import { join, basename } from 'node:path';

/**
 * ①Interface.ets 契约合成（spec  多源合并； 增声明面源）：
 * 方法签名派生为**多源合并**（优先级：SDK d.ts 声明面 > Local 调用面 > locations 调用面；同方法名高优先级胜出）：
 * 0. **SDK d.ts 声明面**：scan-report 确认的 SDK 的 `ets/api/@ohos.<module>.d.ts`——
 *    namespace 真实函数签名 + 入口对象接口方法（如 camera.getCameraManager 返回的 CameraManager 全方法集），
 *    真实方法名/参数名/参数类型（Bridge 可映射集内保留，其余→ESObject）
 * 1. Local 迁移内容调用面（全部 `symbol.method(` 调用）
 * 2. 源码调用面（locations 指向的 .ets 文件成员访问解析）
 * 3. 兜底单参默认契约
 * 返回统一 Promise<Bridge.ResultValue>（③callMethod 的 Bridge 契约形态）。
 * 本契约为六件套签名唯一真相源（F3-Q2），②③④⑤⑥渲染均消费本产物。
 */

/** @returns {{interfaceName:string, methods:Array<{name:string, params:Array<{type:string,name:string}>}>, derived:string}} */
export function composeContract(item, local, srcRoot, sdkDir) {
  const methods = new Map();
  const methodName = methodIndexOf(item.symbol);
  let derived = 'default';
  const merge = (cs, prio) => {
    const prev = methods.get(cs.name);
    if (!prev || prio > prev.prio || (prio === prev.prio && cs.paramCount > prev.paramCount)) {
      methods.set(cs.name, { ...cs, prio });
    }
  };
  // 来源 0：SDK d.ts 声明面——最权威（真实方法集与签名）
  if (sdkDir) {
    for (const cs of deriveFromSdkDeclarations(sdkDir, item.module, item.symbol)) {
      merge(cs, 3);
      if (derived === 'default') derived = 'sdk-decls';
    }
  }
  // 来源 1：Local 迁移内容——全部 symbol 成员调用面
  //（语句可能用导入别名/命名空间前缀：全 symbol → 末段方法名两级回退）
  if (local && local.status === 'migrated' && local.content) {
    let calls = deriveFromText(local.content, item.symbol);
    if (calls.length === 0) {
      const seg = String(item.symbol).split(/[./]/).filter(Boolean).pop();
      if (seg && seg !== item.symbol) calls = deriveFromMethod(local.content, seg);
    }
    for (const cs of calls) {
      merge(cs, 2);
      if (derived === 'default') derived = 'local';
    }
  }
  // 来源 2：源码调用面（Local 成功也合并——覆盖 Local 语句窗口外的调用点）
  if (srcRoot && Array.isArray(item.locations) && item.locations.length > 0) {
    for (const cs of deriveFromLocations(item.locations, srcRoot, item.symbol)) {
      merge(cs, 1);
      if (derived === 'default') derived = 'call-sites';
    }
  }
  if (methods.size === 0) {
    methods.set(methodName, { name: methodName, paramCount: 0, argTypes: [], prio: 0 });
  }
  const out = [...methods.values()].map((cs) => ({
    name: cs.name,
    params: paramList(cs.paramCount, cs.argTypes, cs.paramNames)
  }));
  return { interfaceName: `${item.name}Interface`, methods: out, derived };
}

/**
 * 从文本（Local 迁移内容）推导 symbol 的成员调用面：
 * 解析 `symbol.method(...)`，返回 [{name, paramCount, argTypes}]（argTypes=顶层实参原文）。
 */
function deriveFromText(content, symbol) {
  return collectCalls(String(content), symbol);
}

/** 末段回退：按 `.seg(` 方法名形态收集（导入别名前缀，如 geo.getCurrentLocation(…)） */
function deriveFromMethod(content, methodName) {
  const re = new RegExp(`\\.${escapeRegExp(methodName)}\\s*(?:<[^>]*>)?\\s*\\(`, 'g');
  let best = null;
  let m;
  while ((m = re.exec(String(content))) !== null) {
    const args = parseArgsAt(String(content), re.lastIndex - 1);
    const cs = { name: methodName, paramCount: args.length, argTypes: args };
    if (!best || cs.paramCount > best.paramCount) best = cs;
  }
  return best ? [best] : [];
}

/**
 * 从 scan locations 指向的源文件推导 API 调用面（成员访问模式）。
 * 解析 `symbol.method(...)` / `symbol.method<...>(...)`，
 * 返回 [{name, paramCount, argTypes}]，同方法名去重取最大参数个数。
 */
function deriveFromLocations(locations, srcRoot, symbol) {
  const out = [];
  for (const loc of locations) {
    const m = /^(.+):(\d+)$/.exec(String(loc));
    if (!m) continue;
    const filePath = findSourceFile(srcRoot, m[1]);
    if (!filePath) continue;
    let content;
    try { content = readFileSync(filePath, 'utf8'); } catch { continue; }
    out.push(...collectCalls(content, symbol));
  }
  return out;
}

/** 文本内 `symbol.method(` 调用面收集（含泛型形态；参数类型注释/字符串内的假匹配由括号平衡兜底） */
function collectCalls(content, symbol) {
  const methods = new Map();
  const memberRe = new RegExp(`(?<![\\w$.])${escapeRegExp(symbol)}\\.([A-Za-z_$][\\w$]*)\\s*(?:<[^>]*>)?\\s*\\(`, 'g');
  let mm;
  while ((mm = memberRe.exec(content)) !== null) {
    const name = mm[1];
    const args = parseArgsAt(content, memberRe.lastIndex - 1);
    const cs = { name, paramCount: args.length, argTypes: args };
    const existing = methods.get(name);
    if (!existing || cs.paramCount > existing.paramCount) methods.set(name, cs);
  }
  return [...methods.values()];
}

/** 在 srcRoot 下按 basename 定位源文件（locations 路径可能因模块扁平化偏移） */
function findSourceFile(srcRoot, relPath) {
  const base = basename(relPath);
  const candidates = walkEts(srcRoot, base);
  return candidates.length > 0 ? candidates[0] : null;
}

function walkEts(dir, target, depth = 0) {
  if (depth > 8) return [];
  const out = [];
  try {
    for (const e of readdirSync(dir, { withFileTypes: true })) {
      if (e.name === 'oh_modules' || e.name === 'node_modules' || e.name.startsWith('.')) continue;
      const f = join(dir, e.name);
      if (e.isDirectory()) out.push(...walkEts(f, target, depth + 1));
      else if (e.name === target) out.push(f);
      if (out.length > 0) return out;
    }
  } catch { /* unreadable */ }
  return out;
}

/** 从 `(` 位置起做括号平衡，取顶层实参原文数组（类型推导的输入） */
function parseArgsAt(content, openParenIdx) {
  let depth = 0, i = openParenIdx, start = openParenIdx + 1;
  const args = [];
  while (i < content.length && i - openParenIdx < 2000) {
    const ch = content[i];
    if (ch === '(') { depth++; if (depth === 1) { i++; continue; } }
    else if (ch === ')') {
      depth--;
      if (depth === 0) {
        const last = content.slice(start, i).trim();
        if (last || args.length > 0) args.push(last);
        return args;
      }
    } else if (depth === 1 && ch === ',') {
      args.push(content.slice(start, i).trim());
      start = i + 1;
    }
    i++;
  }
  return args;
}

/** 实参字面量→Bridge 可映射集类型（回调/对象/数组→ESObject 走签名检查"需人工"通道） */
function classifyArg(arg) {
  const a = String(arg ?? '').trim();
  if (!a) return 'string';
  if (/^-?\d+(\.\d+)?$/.test(a)) return 'number';
  if (/^(true|false)$/.test(a)) return 'boolean';
  if (/^(['"]).*\1$/.test(a)) return 'string';
  if (a.includes('=>')) return 'ESObject';
  if (/^[{[]/.test(a)) return 'ESObject';
  return 'string';
}

// ── ：SDK d.ts 声明面（来源 0）──────────────────────────────────────────

/**
 * SDK d.ts 声明面推导：真实方法集与签名。
 * 1. namespace 级函数声明（如 sensor.on/off、camera.getCameraManager——真实参数名/类型）
 * 2. **入口对象接口方法**：namespace 函数返回类型对应的 interface 块内方法
 *    （如 camera.getCameraManager(): CameraManager → CameraManager 的 getSupportedCameras/
 *     createCameraInput/createSession 等全方法集—— 反馈"11+ 方法"诉求的正解）
 * 类型映射到 Bridge 可映射集（string/number/boolean 保留，其余→ESObject）。
 * @returns {Array<{name:string, paramCount:number, argTypes:string[], paramNames:string[]}>}
 */
export function deriveFromSdkDeclarations(sdkDir, module, symbol) {
  const dtsPath = findSdkDts(sdkDir, module);
  if (!dtsPath) return [];
  let text;
  try { text = readFileSync(dtsPath, 'utf8'); } catch { return []; }
  const stripped = stripDtComments(text);
  const nsName = String(symbol).split(/[./]/).filter(Boolean).pop() ?? '';
  const ns = extractBlock(stripped, new RegExp(`(?:declare|export)\\s+namespace\\s+${nsName}\\s*\\{`));
  if (!ns) return [];
  // 1. namespace 级函数
  const fns = parseFunctionDecls(ns);
  const out = new Map();
  for (const f of fns) {
    out.set(f.name, toCallShape(f.name, f.params));
  }
  // 2. 入口对象接口方法（namespace 函数的返回类型 → 同 namespace 内 interface 块）
  const returnTypes = [...new Set(fns.map((f) => f.returnType).filter(Boolean))];
  for (const rt of returnTypes) {
    const iface = extractBlock(ns, new RegExp(`interface\\s+${rt}\\s*(?:extends\\s+[^{]+)?\\{`));
    if (!iface) continue;
    for (const m of parseMethodDecls(iface)) {
      if (!out.has(m.name)) out.set(m.name, toCallShape(m.name, m.params)); // ns 函数名优先（同名重载取函数版）
    }
  }
  return [...out.values()];
}

/** d.ts 文件定位：@ohos.multimedia.camera → <sdk>/ets/api/@ohos.multimedia.camera.d.ts（@ 前缀是文件名一部分） */
function findSdkDts(sdkDir, module) {
  const rel = String(module).startsWith('@') ? String(module) : `@${String(module)}`;
  for (const base of ['ets/api', 'api']) {
    const p = join(sdkDir, base, `${rel}.d.ts`);
    if (existsSync(p)) return p;
  }
  return null;
}

/** 剥 d.ts 注释（块+行）——避免注释里的签名被误解析 */
function stripDtComments(text) {
  return String(text)
    .replace(/\/\*[\s\S]*?\*\//g, '')
    .replace(/\/\/[^\n]*/g, '');
}

/** 从文本提取 `{` 开头的平衡块（含声明头匹配）——深度平衡扫描 */
function extractBlock(text, headRe) {
  const m = headRe.exec(text);
  if (!m) return null;
  let depth = 0;
  let i = m.index + m[0].length - 1; // 指向 '{'
  let start = i + 1;
  for (; i < text.length; i++) {
    if (text[i] === '{') depth += 1;
    else if (text[i] === '}') {
      depth -= 1;
      if (depth === 0) return text.slice(start, i);
    }
  }
  return null;
}

/** 函数声明解析：`function name(params): ReturnType;`（d.ts 常态单行） */
function parseFunctionDecls(block) {
  const out = [];
  const re = /(?:^|\n)\s*(?:export\s+)?function\s+(\w+)\s*\(([^)]*)\)\s*(?::\s*([\w.]+))?\s*;/g;
  let m;
  while ((m = re.exec(block)) !== null) {
    out.push({ name: m[1], params: splitParams(m[2]), returnType: m[3] || '' });
  }
  return out;
}

/** 接口方法声明解析：`name(params): ReturnType;`（interface 块内成员方法） */
function parseMethodDecls(ifaceBlock) {
  const out = [];
  const re = /(?:^|\n)\s*(?:readonly\s+)?(?:[a-zA-Z_]\w*\s+)?(\w+)\s*\(([^)]*)\)\s*(?::\s*[\w.<>\[\]]+)?\s*;/g;
  let m;
  while ((m = re.exec(ifaceBlock)) !== null) {
    if (m[1] === 'constructor') continue;
    out.push({ name: m[1], params: splitParams(m[2]) });
  }
  return out;
}

/** 参数串切分：`type: SensorId, callback: Callback<T>, options?: Options` → 形参描述 */
function splitParams(raw) {
  const out = [];
  for (const seg of String(raw ?? '').split(',')) {
    const s = seg.trim();
    if (!s) continue;
    const mm = /^(\w+)\??\s*:\s*(.+)$/.exec(s);
    if (mm) out.push({ name: mm[1], type: mm[2].trim() });
    else out.push({ name: s, type: '' });
  }
  return out;
}

/** d.ts 形参 → 契约调用形状（参数名保留；类型映射 Bridge 可映射集） */
function toCallShape(name, params) {
  return {
    name,
    paramCount: params.length,
    paramNames: params.map((p) => p.name),
    argTypes: params.map((p) => mapDtType(p.type)),
  };
}

/** d.ts 类型 → Bridge 可映射集：string/number/boolean 原样；其余（枚举/接口/回调/数组）→ ESObject */
function mapDtType(type) {
  const t = String(type ?? '').trim();
  if (t === 'string' || t === 'number' || t === 'boolean') return t;
  return 'ESObject';
}

function escapeRegExp(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

/** symbol 末段驼峰化（router.pushUrl → pushUrl；非字母数字分段拼接） */
export function methodIndexOf(symbol) {
  const segs = String(symbol).split(/[^A-Za-z0-9]+/).filter(Boolean);
  const last = segs[segs.length - 1] ?? 'invoke';
  return last.charAt(0).toLowerCase() + last.slice(1);
}

function paramList(n, argTypes = [], paramNames = []) {
  const MAPPED = new Set(['string', 'number', 'boolean', 'ESObject']);
  return Array.from({ length: n }, (_, i) => {
    const t = argTypes?.[i];
    return {
      type: MAPPED.has(t) ? t : classifyArg(t), // d.ts 声明面已是映射类型原样用；调用面字面量走 classify
      name: paramNames?.[i] || `p${i}`,
    };
  });
}

/** 从迁移内容中解析目标调用的顶层实参个数（确定性简化口径：首个匹配调用的括号平衡） */
export function countTopLevelArgs(content, symbol) {
  const seg = String(symbol).split(/[./]/).filter(Boolean).pop() ?? '';
  const idx = content.indexOf(seg);
  if (idx < 0) return 0;
  const open = content.indexOf('(', idx + seg.length);
  if (open < 0) return 0;
  let depth = 0;
  let args = 0;
  let hasToken = false;
  for (let i = open; i < content.length; i++) {
    const c = content[i];
    if (c === '(') { depth++; if (depth === 1) continue; }
    else if (c === ')') { depth--; if (depth === 0) break; }
    else if (depth >= 1) {
      if (c === ',' && depth === 1) { args++; hasToken = false; }
      else if (!/\s/.test(c)) hasToken = true;
    }
  }
  if (hasToken || args > 0) args++;
  return args;
}

