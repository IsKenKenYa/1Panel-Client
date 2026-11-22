import { existsSync, readFileSync, statSync } from 'node:fs';
import { resolve, join } from 'node:path';

/** ②Local 迁移源定位与读取（源工程只读） */

const MAX_SPAN_LINES = 60;

/**
 * 以 locations 为锚，从源工程提取该接口的 @ohos.* 调用实现（最小完整语句窗口，确定性）。
 * ：**全部 locations 逐一收割**（去重合并 import 与语句）——多方法 Local 各方法体各得语句
 * （如 sensor 的 on/off 两处调用分属两方法）；可选 kit import 改写为底层 @ohos 直导入
 * （②Local 类文件进 ArkUI-X 编译集时 @kit.* 不可解析——用 SDK kits 索引映射）。
 * @param {{sdkDir?: string}} opts sdkDir=scan-report 确认的 SDK（kit 改写用）
 * @returns {{name:string,status:'migrated',content:string,ref:string}|{name:string,status:'failed',reason:string}}
 */
export function extractLocal(item, projectRoot, opts = {}) {
 // ：②Local 件是 ArkTS(.ets) 实现——仅 source=ohos 适用；
 // ndk/hms（C++ 宏/闭源）不迁入（会产出不可编译空壳/宏平铺），显式 failed 待人工补
  if (item.source && item.source !== 'ohos') {
    return { name: item.name, status: 'failed', reason: `源码读取失败：${item.source === 'ndk' ? 'NDK C-API 无 .ets 迁移源（平台实现于 ④⑤ 侧补齐）' : '该来源不适用 ②Local 迁移'}，需手动补入` };
  }
  const imports = new Set();
  const statements = [];
  const stmtFiles = []; // 语句来源文件文本（外围作用域收割用）
  const seenStmt = new Set();
  const refs = [];
  let anyLocated = false;
  let shellOnlyCount = 0;
  for (const loc of item.locations ?? []) {
    const located = locateLine(loc, projectRoot);
    if (!located.ok) continue;
    anyLocated = true;
    let text;
    try { text = readFileSync(located.file, 'utf8'); } catch { continue; }
 // b：location 锚在 import 行（F2 对命名空间级符号常只记 import 行）→ 收割该文件内**全部** symbol 调用语句
    //（on/off/once 等多方法各得语句——而非只取首个调用）
    const lines = text.split(/\r?\n/);
    const anchorIdx = located.line - 1;
 // ：锚行判定扩展——import 行**与  改写标记（// [MIG]）及噪声行（空行/纯注释/
    // 纯闭合括号）**均触发 findAllCallLines 全文件调用扫描。此前 MIG 锚走单锚点+宽松重锚，
    // 在大型文件中常命中变量声明（private cameraManager: camera.X）而非方法调用 → 方法体全空壳
    const anchorLine = anchorIdx >= 0 && anchorIdx < lines.length ? lines[anchorIdx] : '';
    const anchorIsCallAnchor = /^\s*import\s/.test(anchorLine)
      || /^\s*\/\/\s*\[MIG\]/.test(anchorLine)
      || !anchorLine.trim()
      || /^\s*\/\//.test(anchorLine)
      || /^[}\])\s]+$/.test(anchorLine);
    const anchors = anchorIsCallAnchor ? findAllCallLines(lines, item.symbol) : [located.line];
    for (const anchorLine of anchors) {
      try {
        const stmt = extractStatement(located.file, anchorLine, item.symbol);
        if (stmt === null) continue;
        if (isShellOnly(stmt)) { shellOnlyCount += 1; continue; }
        const norm = (s) => s.replace(/\s+/g, ' ').trim();
        const hash = norm(stmt);
        if (seenStmt.has(hash)) continue;
 // ：兄弟语句吸收会使后锚点的块是已收集块的子串（on 锚点吸收了 off → off 锚点的块重复）——包含去重
        if (statements.some((prev) => norm(prev).includes(hash))) continue;
        seenStmt.add(hash);
        statements.push(stmt);
        stmtFiles.push(text);
        refs.push(located.rel);
        for (const l of harvestImports(text, item, stmt)) imports.add(l);
      } catch { /* 单锚点失败不影响其余（其余语句仍迁入） */ }
    }
  }
  if (!anyLocated) {
    const why = (item.locations ?? []).length === 0 ? 'locations 为空' : 'locations 指向的文件均不存在或不可读';
    return { name: item.name, status: 'failed', reason: `源码读取失败：${why}，需手动补入` };
  }
  if (statements.length === 0) {
    const why = shellOnlyCount > 0 ? `迁移语句为空壳（仅 import/注释，共 ${shellOnlyCount} 处）` : '未能定位完整调用语句';
    return { name: item.name, status: 'failed', reason: `源码读取失败：${why}，需手动补入` };
  }
 // ：kit import 改写（@kit.* 在 ArkUI-X 编译集不可解析——按 SDK kits 索引映射为底层 @ohos 直导入）
  let importLines = [...imports];
  if (opts.sdkDir) importLines = importLines.map((l) => rewriteKitImport(l, opts.sdkDir)).filter(Boolean);
 // c： stub 重定向行对 ②Local 无语义（Local 是 OH 直调实现——须导入真实 @ohos 模块，
 // stub 是编译占位）。源文件被  改写后原 kit import 已被注释、收割到的是 stub 行——
 // 过滤 stub 行并确保真实模块导入在场（缺失则按 item.module 直接生成默认导入）
  const seg = String(item.symbol).split(/[./]/).filter(Boolean).pop();
  const modRe = new RegExp(`from\\s+['"]${escapeRegExp(item.module)}['"]`);
  importLines = importLines.filter((l) => !/n2b-stubs/.test(l));
  if (seg && !importLines.some((l) => modRe.test(l) && bindsIdentifier(l, seg))) {
    importLines.unshift(`import ${seg} from '${item.module}'; // [MIG]  已注释原导入——Local 直调需真实模块`);
  }
 // ：外围作用域收割——迁移语句引用的自由标识符（Logger/DeviceService/TAG…）按来源分类带入：
 // 包导入原样 / 模块名导入带依赖提示 / 相对导入注释指引 / 本地 const 字面量内联 / 其余列入未解析注释
  importLines = [...importLines, ...harvestScopeBindings(statements, stmtFiles, item.symbol)];
  return { name: item.name, status: 'migrated', content: [...importLines, ...statements].join('\n'), ref: refs[0] ?? '' };
}

/**
 * ：语句自由标识符的外围绑定收割。
 * 逐标识符在语句来源文件中找绑定 import / 本地 const 字面量，按来源分类产出行：
 * - @ohos.* 直导入 → 原样（任意位置可解析）
 * - 相对路径导入（'../model/X'）→ 注释行（路径相对源工程——HAR 内无效，接线时改写/迁入）
 * - 模块名导入（'sample_common'）→ 原样 + 依赖提示注释（需 HAR oh-package 声明依赖）
 * - 本地 const 字面量（const TAG = 'X'）→ 内联声明
 * - 均未命中 → 未解析标识符汇总注释（接线时补）
 */
function harvestScopeBindings(statements, stmtFiles, symbol) {
  const out = [];
  const unresolved = [];
  const seen = new Set();
  const seenLines = new Set(); // 同一 import 行可绑定多个自由标识符（{A, B} from 'x'）——去重
  const allImports = new Set(); // (标识符 → import 行) 全量索引（跨语句来源文件）
  const importLines = [];
  for (const text of stmtFiles) {
    for (const line of String(text).split(/\r?\n/)) {
      if (!/^\s*import\s/.test(line)) continue;
      importLines.push(line);
    }
  }
  statements.forEach((stmt, idx) => {
    const ids = freeIdentifiersOf(stmt, symbol);
    // 语句来源文件优先（局部 const/相对导入最准），全量文件兜底
    const ownText = stmtFiles[idx] ?? '';
    for (const id of ids) {
      if (seen.has(id)) continue;
      seen.add(id);
      const binding = importLines.find((l) => bindsIdentifier(l, id));
      if (binding) {
        if (seenLines.has(binding)) continue; // 同 import 行已带出（{Logger, UIContextSelf} 一行两标识符）
        seenLines.add(binding);
        const spec = importSpecOf(binding);
        if (spec.startsWith('.')) {
          out.push(`// [MIG] ${binding.trim()} —— 相对源工程路径，接线时按 HAR 内位置改写或迁入依赖`);
        } else if (spec.startsWith('@')) {
          out.push(binding.trim());
        } else {
 // ：模块名导入注释化——HAR 无该依赖时 live 导入即编译错（模块解析失败），
 // 声明依赖后取消注释
          out.push(`// [MIG] ${binding.trim()} —— 模块名导入，需在 HAR oh-package 声明依赖后取消注释`);
        }
        continue;
      }
      const literal = constLiteralOf(id, ownText);
      if (literal !== null) {
        out.push(`const ${id} = ${literal}; // [MIG] 源工程本地常量内联`);
        continue;
      }
      unresolved.push(id);
    }
  });
  if (unresolved.length > 0) {
    out.push(`// [MIG] 未解析标识符（源工程外围作用域——接线时补 import/实现）: ${[...new Set(unresolved)].join(', ')}`);
  }
  return out;
}

/** import 行的模块说明符：`import X from 'spec'` → 'spec' */
function importSpecOf(importLine) {
  const m = /from\s+['"]([^'"]+)['"]/.exec(importLine);
  return m ? m[1] : '';
}

/** 本地 const 字面量查找：`const NAME = 'lit'` / `const NAME: T = 123` → 字面量原文（未命中 null） */
function constLiteralOf(id, text) {
  const re = new RegExp(`(?:^|\\n)\\s*const\\s+${id}\\s*(?::\\s*[^=;]+)?=\\s*('[^']*'|"[^"]*"|-?\\d+(?:\\.\\d+)?)\\s*;`);
  const m = re.exec(String(text ?? ''));
  return m ? m[1] : null;
}

/**
 * 语句自由标识符提取：引用外围作用域的标识符（迁移后需 import/内联才能解析）。
 * 剥字符串/模板/注释后收集标识符；剔除——语句内局部名（回调参数/const/let/对象键）、
 * symbol 根与其成员链、关键字/全局内置。
 */
export function freeIdentifiersOf(stmt, symbol) {
  const symRoot = String(symbol).split(/[./]/).filter(Boolean).pop() ?? '';
  const st = { block: false, str: null };
  const codeOnly = String(stmt).split(/\r?\n/).map((l) => stripCode(l, st)).join('\n');
  const defined = new Set();
  for (const m of codeOnly.matchAll(/\(([^()]*)\)\s*=>/g)) {
    for (const p of m[1].split(',')) {
      const name = p.trim().split(/[:\s]/)[0];
      if (/^[A-Za-z_$][\w$]*$/.test(name)) defined.add(name);
    }
  }
  for (const m of codeOnly.matchAll(/\b(?:const|let|var)\s+([A-Za-z_$][\w$]*)/g)) defined.add(m[1]);
 // b：类成员声明名（private/public/protected/readonly/static X: T = ...）归"已定义"——
  // 声明位不是引用位（成员声明型语句被兄弟吸收进语句块时，成员名不是自由标识符）
  for (const m of codeOnly.matchAll(/\b(?:private|public|protected|readonly|static)\s+([A-Za-z_$][\w$]*)/g)) defined.add(m[1]);
 // b2：装饰器成员（@Local adaptRatio: number = ...）——装饰器名与成员名均非自由标识符
  for (const m of codeOnly.matchAll(/@[A-Za-z_$][\w$]*\s+([A-Za-z_$][\w$]*)/g)) defined.add(m[1]);
  for (const m of codeOnly.matchAll(/[{,]\s*([A-Za-z_$][\w$]*)\s*:/g)) defined.add(m[1]);
  const KEYWORDS = new Set(['if', 'else', 'return', 'const', 'let', 'var', 'new', 'typeof', 'undefined', 'null',
    'true', 'false', 'console', 'this', 'Math', 'JSON', 'Date', 'Promise', 'Error', 'String', 'Number',
    'Boolean', 'Array', 'Object', 'export', 'import', 'function', 'void', 'interface', 'type', 'as', 'in', 'of',
 // b：TS/ArkTS 修饰符与类型关键字（成员声明型语句的声明位/类型位不是自由标识符）
    'private', 'public', 'protected', 'readonly', 'static', 'get', 'set', 'declare', 'async', 'await',
    'class', 'enum', 'extends', 'implements', 'constructor', 'namespace', 'super',
    'number', 'string', 'boolean', 'object', 'unknown', 'never', 'any', 'symbol', 'bigint',
    'Record', 'Array', 'Map', 'Set', 'ESObject']);
  const out = [];
 // 剔除属性访问段（.on/.SensorId/.info——成员名非自由标识符）与装饰器（@Local 等元编程名非业务标识符）
  const strippedProps = codeOnly.replace(/\.[A-Za-z_$][\w$]*/g, '').replace(/@[A-Za-z_$][\w$]*/g, '');
  for (const m of strippedProps.matchAll(/[A-Za-z_$][\w$]*/g)) {
    const id = m[0];
    if (defined.has(id) || KEYWORDS.has(id) || id === symRoot) continue;
    if (!out.includes(id)) out.push(id);
  }
  return out;
}

/** b：文件内全部 symbol 调用行（`symbol.method(` 形态——import 锚的多方法收割） */
function findAllCallLines(lines, symbol) {
  const seg = String(symbol).split(/[./]/).filter(Boolean).pop() ?? '';
  const out = [];
  const re = new RegExp(`(?<![\\w$.])${escapeRegExp(seg)}\\.[A-Za-z_$][\\w$]*\\s*\\(`);
  for (let i = 0; i < lines.length; i++) {
    if (/^\s*import\s/.test(lines[i]) || /^\s*\/\//.test(lines[i])) continue;
    if (re.test(lines[i])) out.push(i + 1);
  }
  return out;
}

/** 单 location 定位：'文件:行' → 绝对路径 */
function locateLine(loc, projectRoot) {
  const m = /^(.+):(\d+)$/.exec(String(loc));
  if (!m) return { ok: false };
  const rel = m[1];
  const file = resolve(projectRoot, rel);
  if (!existsSync(file)) return { ok: false };
  let st;
  try { st = statSync(file); } catch { return { ok: false }; }
  if (!st.isFile()) return { ok: false };
  return { ok: true, file, line: Number(m[2]), rel };
}

/**
 * ：kit import 行改写——`import { sensor } from '@kit.SensorServiceKit'` → `import sensor from '@ohos.sensor'`
 * （依据 SDK kits d.ts 的默认导入重导出：`import sensor from '@ohos.sensor'; export { sensor };`）。
 * 绑定名全部可映射才改写；部分可映射/索引缺失时保留原行（保守——@kit 未决项由  管辖）。
 */
function rewriteKitImport(importLine, sdkDir) {
  const km = /^\s*import\s+(?:type\s+)?\{([^}]+)\}\s+from\s+['"](@kit\.[A-Za-z0-9_.]+)['"]\s*;?\s*$/.exec(importLine);
  if (!km) return importLine;
  const kitFile = join(sdkDir, 'ets', 'kits', `${km[2]}.d.ts`);
  if (!existsSync(kitFile)) return importLine;
  let kitText;
  try { kitText = readFileSync(kitFile, 'utf8'); } catch { return importLine; }
  // kit 索引：默认导入行 `import X from '@ohos.mod';` → X → mod
  const defMap = new Map();
  for (const line of kitText.split(/\r?\n/)) {
    const dm = /import\s+([A-Za-z_$][\w$]*)\s+from\s+['"](@ohos\.[A-Za-z0-9_.]+)['"]/.exec(line);
    if (dm) defMap.set(dm[1], dm[2]);
  }
  const names = km[1].split(',').map((s) => s.trim().split(/\s+as\s+/).pop()).filter(Boolean);
  if (names.length === 0 || !names.every((n) => defMap.has(n))) return importLine;
  return names.map((n) => `import ${n} from '${defMap.get(n)}';`).join('\n');
}

/** 收割语句所需 import：from item.module 的行 + 绑定语句根标识符的行（默认/具名/as 别名） */
function harvestImports(text, item, statement) {
  const root = (String(statement).match(/^[^A-Za-z_$]*([A-Za-z_$][\w$]*)/) || [])[1];
  const modRe = new RegExp(`from\\s+['"]${escapeRegExp(item.module)}['"]`);
 // a：symbol 命名空间名恒参与绑定匹配——成员声明型语句（`private cameraManager: camera.X`）
 // 的根标识符提取到 private 等修饰符，此前会漏收 `import { camera } from '@kit.CameraKit'`
  const seg = String(item.symbol).split(/[./]/).filter(Boolean).pop();
  const out = [];
  for (const line of String(text).split(/\r?\n/)) {
    if (!/^\s*import\s/.test(line)) continue;
 // （方案 2 保底）：只收割 OH API 命名空间导入（@ohos.*/@kit.*/@hms.*）——
 // /接线已把源文件改写为 commons HAR 名（multimedia_camera——自引用）或项目内部
 // HAR（sample_common）或 stub（n2b-stubs），收割进来是错误导入；真实 @ohos 模块导入
 // 由 c 兜底合成保证在场。标识符域的其他 import 由外围作用域收割（harvestScopeBindings）分类处理
    const spec = importSpecOf(line);
    if (spec && !spec.startsWith('@')) continue;
    if (modRe.test(line) || (root && bindsIdentifier(line, root)) || (seg && bindsIdentifier(line, seg))) out.push(line);
  }
  return out;
}

function bindsIdentifier(importLine, id) {
  const m = /^\s*import\s+(?:type\s+)?(.+?)\s+from\s/.exec(importLine);
  if (!m) return false;
  const binding = m[1];
  if (/^[A-Za-z_$][\w$]*$/.test(binding)) return binding === id; // 默认导入
  const named = binding.match(/\{(.*)\}/);
  if (named) {
    return named[1].split(',').some((seg) => {
      const parts = seg.trim().split(/\s+as\s+/);
      return (parts[1] ?? parts[0] ?? '').trim() === id;
    });
  }
  return false;
}

/**
 * 提取 line 起涉及的完整调用语句：从语句逻辑起点（前行以 =,(,{ 结尾或本行以 await/import/const 等开头）
 * 到语句终止，带换行原文返回。 修复：
 * - 括号深度平衡：嵌套回调内的 `return;` 不误判语句终止（深度归零且遇 `;` 才结束）
 * - 行号漂移：锚定行是 `// [MIG]` 注释（改写把 import 行原位替换为注释+净增行）时，
 *   跳过 MIG 注释/import 噪声行，按 symbol 内容重新锚定首个调用行
 */
export function extractStatement(file, line, symbol) {
  const text = readFileSync(file, 'utf-8');
  const lines = text.split(/\r?\n/);
  if (line < 1 || line > lines.length) return null;
  let start = line - 1;
  const seg = String(symbol).split(/[./]/).filter(Boolean).pop() ?? '';
 // 锚定噪声判定：import 语句 / 改写注释行（原 import 被 // [MIG] 原位替换）/
  //  重定向 stub import（行尾 // [MIG] 迁移占位）
  const isNoise = (l) =>
    /^\s*import\s/.test(l) || /^\s*\/\/\s*\[MIG\]/.test(l) || /^\s*\/\/\s*\[N2B\]/.test(l)
 // ：空行/纯注释/纯闭合括号行（如函数收尾 }——locations 常锚于此）不能作语句锚，同样触发前向重锚
    || !l.trim() || /^\s*\/\//.test(l) || /^[}\])\s]+$/.test(l);
  if (isNoise(lines[start])) {
    let reanchored = -1;
    for (let i = start + 1; i < lines.length; i++) {
      const l = lines[i];
      if (isNoise(l)) continue; // 仍在 import/注释区
      if (l.includes(seg) && /[.(\s]/.test(l)) { reanchored = i; break; }
    }
    if (reanchored < 0) {
 // ：前向无命中（锚常落在语句块收尾 `});`——调用行在前）→ 后向找最近的含 seg 调用行
      for (let i = start - 1; i >= 0; i--) {
        const l = lines[i];
        if (isNoise(l)) continue;
        if (l.includes(seg) && /[.(\s]/.test(l)) { reanchored = i; break; }
      }
    }
    if (reanchored >= 0) start = reanchored;
    // 双向均无 → 保持原锚（噪声行），由 isShellOnly 判空壳
  }
  // 向前回溯：上一行以连接符结尾则并入。 细化：`{` 结尾仅当**非语句块开头**时才算续行
  //（`vibrator.startVibration({` 对象字面量调用=续行 ✓；`export function f(): string {` 函数签名=假续行，
  //  误并入会使深度扫描永不归零、语句块拖到 EOF）
  const BLOCK_OPENER = /^\s*(export\s+)?(async\s+)?function\b|=>\s*\{|^\s*(if|for|while|switch|try|catch|else|do)\b|^\s*(export\s+)?(abstract\s+)?class\b|^\s*interface\b/;
  const endsConnector = (l) => /[=(:\[+\-*/&|,?]\s*$/.test(l)
    || (/\{\s*$/.test(l) && !BLOCK_OPENER.test(l));
  while (start > 0 && endsConnector(lines[start - 1])) start -= 1;
  // 向后扫描：括号深度平衡——剥离注释/字符串内容后计数，深度归零且行尾 `;` 才终止；
  // ：终止后后视吸收**同符号连续兄弟语句**（如 sensor.on(...) 后紧跟 sensor.off(...)——
  // 多方法 Local 类的各方法体各得其语句），非同符号语句或语句块收尾则停止
  const scanState = { block: false, str: null };
  let end = start;
  let depth = 0;
  let i = start;
  while (i < lines.length && i - start < MAX_SPAN_LINES) {
    end = i;
    const code = stripCode(lines[i], scanState);
    for (const ch of code) {
      if (ch === '{' || ch === '(' || ch === '[') depth += 1;
      else if (ch === '}' || ch === ')' || ch === ']') depth = Math.max(0, depth - 1);
    }
    if (depth === 0 && /;\s*$/.test(code)) {
      let j = i + 1;
      while (j < lines.length && isNoise(lines[j])) j += 1;
      if (j < lines.length && j - start < MAX_SPAN_LINES && lines[j].includes(seg) && /[.(\s]/.test(lines[j])) {
        i = j;
        continue;
      }
      break;
    }
    i += 1;
  }
  const block = lines.slice(start, end + 1).join('\n');
  if (seg && !block.includes(seg)) return null;
  return block;
}

/**
 * 行级剥离：去注释（行/块）与字符串内容（保留引号定界），返回可计数括号的代码面。
 * scanState 跨行携带块注释/模板字符串态（多行字符串内的括号不计入深度）。
 */
function stripCode(line, st) {
  let out = '';
  let i = 0;
  while (i < line.length) {
    const c = line[i];
    const d = line[i + 1];
    if (st.block) {
      if (c === '*' && d === '/') { st.block = false; i += 2; continue; }
      i += 1; continue;
    }
    if (st.str) {
      if (c === '\\') { i += 2; continue; }
      if (c === st.str) { st.str = null; i += 1; continue; }
      i += 1; continue;
    }
    if (c === '/' && d === '/') break; // 行注释：剩余丢弃
    if (c === '/' && d === '*') { st.block = true; i += 2; continue; }
    if (c === "'" || c === '"' || c === '`') { st.str = c; i += 1; continue; }
    out += c;
    i += 1;
  }
  return out;
}

/** 括号净深度（兜底自检）：剥离注释/字符串后计数，0=平衡（可编译的必要条件） */
export function netBracketDepth(text) {
  const st = { block: false, str: null };
  let depth = 0;
  for (const line of String(text).split(/\r?\n/)) {
    const code = stripCode(line, st);
    for (const ch of code) {
      if (ch === '{' || ch === '(' || ch === '[') depth += 1;
      else if (ch === '}' || ch === ')' || ch === ']') depth -= 1;
    }
  }
  return depth;
}

/** ：有效内容判定——剔除注释/空行/import 后无实质语句视为空壳 */
export function isShellOnly(content) {
  const meaningful = String(content).split('\n')
    .map((l) => l.trim())
    .filter((l) => l && !l.startsWith('//') && !l.startsWith('*') && !l.startsWith('/*') && !l.startsWith('import '));
  return meaningful.length === 0;
}

/** ②Local 迁移产物文件路径（相对输出目录； files.local 同源） */
export function localFilePath(item) {
  // 契约路径固定 '/' 分隔（平台无关）——win32 的 join 产生 '\' 会破坏下游消费与断言比对
  return `commons/${moduleDir(item.module)}/utils/${item.name}Local.ets`;
}

/** module → 目录段（@ohos.xx.yyy → xx-yyy；非法字符归一） */
export function moduleDir(module) {
  const segs = String(module).replace(/^@/, '').split(/[./]/).filter(Boolean);
  if (segs.length > 1 && (segs[0] === 'ohos' || segs[0] === 'hms')) segs.shift(); // 去命名空间段
  return segs.join('-');
}

/**
 * ②Local 内容拆分（class 化）：import 行区 / 语句单元区（对齐 docs 一码三平台的 Local 形态——
 * import 置文件顶部，语句单元各落对应类方法体）。语句单元=深度归零处 `;` 切分（多行语句保持完整）。
 * @returns {{imports:string[], statements:string[]}}
 */
export function splitLocalContent(content) {
  const imports = [];
  const rest = [];
  for (const line of String(content ?? '').split(/\r?\n/)) {
    if (/^\s*import\s/.test(line)) imports.push(line);
 // ：外围作用域收割行归头部区（[MIG] 注释导入/const 内联——不是语句，误入语句区会进类尾参考块）
    else if (/^\s*\/\/\s*\[MIG\]/.test(line)) imports.push(line);
    else if (/^\s*const\s+\w+\s*=.*\/\/\s*\[MIG\]/.test(line)) imports.push(line);
    else if (line.trim()) rest.push(line);
  }
  const statements = [];
  const st = { block: false, str: null };
  let depth = 0;
  let current = [];
  for (const line of rest) {
    current.push(line);
    const code = stripCode(line, st);
    for (const ch of code) {
      if (ch === '{' || ch === '(' || ch === '[') depth += 1;
      else if (ch === '}' || ch === ')' || ch === ']') depth = Math.max(0, depth - 1);
    }
    if (depth === 0 && /;\s*$/.test(code)) {
      statements.push(current.join('\n'));
      current = [];
    }
  }
  if (current.length) statements.push(current.join('\n')); // 无收尾分号的残块（自检兜底）
  return { imports, statements };
}

function escapeRegExp(s) {
  return String(s).replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}
