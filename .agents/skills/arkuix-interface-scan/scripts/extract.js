import { readdirSync, readFileSync, statSync, existsSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

/**
 * 依赖缓存/构建产物目录排除清单（约束固化，按目录名匹配、大小写不敏感、任意层级；
 * 如需扩展随规则表版本演进）
 */
const EXCLUDED_DIRS = new Set([
 // spec  固化清单
  '.git', '.hvigor', 'oh_modules', 'node_modules', 'build', '.previewer', '.cxx',
  '.idea', '.vscode', 'deriveddata', 'pods',
 // 实现期既有补充（缓存/构建产物同类）
  '.clang', '.clangd', '.preview', 'local', '.cache', 'hvigor'
]);

const SOURCE_EXTS = new Set(['.ets', '.ts']);
/** Native 源码文件类型清单（design  固化；如需扩展随规则表版本演进） */
const NATIVE_EXTS = new Set(['.cpp', '.cc', '.cxx', '.h', '.hpp']);
/** 配置类文件也纳入引用扫描（构建配置） */
const CONFIG_FILES = new Set(['module.json5', 'build-profile.json5', 'oh-package.json5', 'hvigorfile.ts']);

/**
 * 工程模型判定
 * stage：AppScope/app.json5 在场（Stage 工程根特征）
 * fa：config.json 在场且无 Stage 特征（FA 工程特征）
 * unknown：两者皆无
 */
export function detectModel(root) {
  if (existsSync(join(root, 'AppScope', 'app.json5'))) return 'stage';
  if (existsSync(join(root, 'config.json'))) return 'fa';
 // （真机实测反馈）：真实 IDE 创建的 FA 工程 config.json 位于模块级 <module>/src/main/config.json
 // （FA 无 module.json5，模块清单即 config.json）；仅认根目录会漏判并误入 stage 推定
  for (const dir of listModuleDirs(root)) {
    const modDir = join(root, dir, 'src', 'main');
    if (existsSync(join(modDir, 'config.json')) && !existsSync(join(modDir, 'module.json5'))) return 'fa';
  }
  if (existsSync(join(root, 'build-profile.json5')) && existsSync(join(root, 'oh-package.json5'))) {
 // 部分 Stage 工程无 AppScope（单模块）——以构建体系在场推定 stage
    return 'stage';
  }
  return 'unknown';
}

/**  辅助：枚举候选模块目录（一级目录，排除构建/配置目录） */
function listModuleDirs(root) {
  const SKIP = new Set(['AppScope', 'oh_modules', '.hvigor', '.git', '.idea', 'hvigor', 'build']);
  try {
    return readdirSync(root, { withFileTypes: true })
      .filter((e) => e.isDirectory() && !SKIP.has(e.name))
      .map((e) => e.name);
  } catch {
    return [];
  }
}

export function enumerateFiles(root) {
  const files = [];
  walk(root, root, files);
  files.sort();
  return files;
}

function walk(root, dir, files) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const entry of entries) {
    if (entry.name.startsWith('.') && entry.name !== '.gitignore') {
      if (entry.isDirectory()) continue;
    }
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      if (isExcludedDir(entry.name)) continue;
      walk(root, full, files);
    } else if (entry.isFile()) {
      if (SOURCE_EXTS.has(extOf(entry.name)) || NATIVE_EXTS.has(extOf(entry.name))
        || CONFIG_FILES.has(entry.name)) {
        files.push(relative(root, full).split(sep).join('/')); // locations/module 契约值固定 '/'（win32 relative 产生 '\\'）
      }
    }
  }
}

function isExcludedDir(name) {
  return EXCLUDED_DIRS.has(name.toLowerCase());
}

function extOf(name) {
  const dot = name.lastIndexOf('.');
  return dot === -1 ? '' : name.slice(dot);
}

const MODULE_RE = /(@(?:ohos|hms)\.[A-Za-z0-9_.-]+|@kit\.[A-Za-z0-9_.-]+)/g;

/* ── Native C-API────────────────────────────────────── */

/** NDK 头文件识别（design 固化启发式，可随规则表演进扩展）：
 *  include 路径以 .h 结尾，且首段为已知 NDK sysroot 目录（ace/arkui/napi/hilog）
 *  或任一段/basename 以 native_ 开头、basename 以 ohos_ 开头 */
const NDK_ROOT_SEGMENTS = new Set(['ace', 'arkui', 'napi', 'node_api', 'hilog', 'rawfile', 'libarkui_ios', 'libarkui_android']);
/** ArkUI-X 专属已知头（docs native-apis 收录但路径无识别性前缀，rules  清单成员；随规则表演进扩展） */
const KNOWN_ARKUIX_HEADERS = new Set(['plugin_utils.h']);
const INCLUDE_RE = /^\s*#\s*include\s*([<"])([^>"]+)[>"]/;
const OH_SYMBOL_RE = /\bOH_[A-Za-z]\w*/g;
const DLOPEN_LITERAL_RE = /\bdlopen\s*\(\s*["']([^"']+\.so)["']/g;
const DLOPEN_NONLITERAL_RE = /\bdlopen\s*\(\s*[A-Za-z_`]/;
const UNATTRIBUTED_MODULE = '(unattributed)';

function isNdkHeader(includePath) {
  if (!includePath.endsWith('.h')) return false;
  const segments = includePath.split('/');
  const base = segments[segments.length - 1];
  if (base.startsWith('native_') || base.startsWith('ohos_')) return true;
 // 顶层头（无目录段）按去扩展名比对（如 node_api.h）；带路径按首段比对（如 napi/、rawfile/）
  if (NDK_ROOT_SEGMENTS.has(base.replace(/\.h$/, '')) || NDK_ROOT_SEGMENTS.has(segments[0])) return true;
  if (KNOWN_ARKUIX_HEADERS.has(base)) return true;
  return segments.some((s) => s.startsWith('native_'));
}

/** ArkTS 动态导入变量/拼接形式（静态不可解析，提示不计数） */
const DYN_IMPORT_NONLITERAL_RE = /\bimport\s*\(\s*(?!['"])[A-Za-z_`]/;

/**
 * 注释消除（保留行数，字符串感知）：行注释与块注释；
 * 识别 ' " ` 字符串及反斜杠转义——字符串内的 // 与块注释起始不误伤（如 URL）。
 * 已知取舍：跨行模板字符串按普通代码处理（其内出现模块串属极端场景）。
 */
export function stripComments(rawLines) {
  const out = [];
  let inBlock = false;
  for (const raw of rawLines) {
    let line = '';
    let quote = null;
    let i = 0;
    while (i < raw.length) {
      const ch = raw[i];
      const next = raw[i + 1];
      if (inBlock) {
        if (ch === '*' && next === '/') { inBlock = false; line += '  '; i += 2; continue; }
        line += ' ';
        i += 1;
        continue;
      }
      if (quote) {
        line += ch;
        if (ch === '\\') {
          if (i + 1 < raw.length) line += raw[i + 1];
          i += 2;
          continue;
        }
        if (ch === quote) quote = null;
        i += 1;
        continue;
      }
      if (ch === '/' && next === '/') break; // 行注释：截断余下列
      if (ch === '/' && next === '*') { inBlock = true; line += '  '; i += 2; continue; }
      if (ch === "'" || ch === '"' || ch === '`') { quote = ch; line += ch; i += 1; continue; }
      line += ch;
      i += 1;
    }
    out.push(line);
  }
  return out;
}

/** 多行 import 累积上限（畸形输入安全阀） */
const MULTILINE_IMPORT_MAX_LINES = 50;

/**
 * 引用提取（扩展 Native；增补：注释感知 + 多行/混合/反引号形态）：
 * - ArkTS/配置：import … from '@ohos.x'（含**多行具名**与**默认+具名混合**形态）/
 *   import('@ohos.x') 与 import(`@ohos.x`)（字面量动态导入）/ 配置文件模块字符串（*module-ref*）
 * - Native（.cpp/.cc/.cxx/.h/.hpp）：#include 的 NDK 头文件（module=头文件路径，
 *   symbol='*include*'）与 OH_* C-API 符号（module=该文件此前最近一条 NDK include）
 * - dlopen("libxxx.z.so") 字面量：module=.so 库名，symbol='*dlopen*'
 * - **注释中的引用/符号/动态加载一律不计**（行注释与块注释，字符串感知）
 * - 变量/拼接形式的动态加载：不计入 inventory，记入 dynamicHints
 *
 * @returns {{inventory: Array<{source, module, symbol, file, line}>,
 *            dynamicHints: Array<{file, line, kind: 'dynamic-import'|'dlopen'}>}}
 */
export function extractReferences(root, files, options = {}) {
  const kitIndex = options.kitIndex || null;
  const nativeIndex = options.nativeIndex || null;
  const inventory = [];
  const dynamicHints = [];
  for (const relFile of files) {
    let text;
    try {
      text = readFileSync(join(root, relFile), 'utf8');
    } catch {
      continue;
    }
    const isNative = NATIVE_EXTS.has(extOf(relFile));
    const lines = stripComments(text.split('\n'));
    let lastNdkInclude = UNATTRIBUTED_MODULE;
    let pendingImport = null; // { startLine, buf }：跨行具名 import 累积
    for (let i = 0; i < lines.length; i++) {
      const line = lines[i];
      const lineNo = i + 1;

      if (isNative) {
        const inc = line.match(INCLUDE_RE);
        if (inc && isNdkHeader(inc[2])) {
          lastNdkInclude = inc[2];
          inventory.push({ source: 'ndk', module: inc[2], symbol: '*include*', file: relFile, line: lineNo });
        } else {
          OH_SYMBOL_RE.lastIndex = 0;
          let m;
          while ((m = OH_SYMBOL_RE.exec(line)) !== null) {
 // ：优先 sysroot 声明索引权威归属；缺索引回退"最近 NDK include"启发式
            const attributed = nativeIndex ? nativeIndex.get(m[0]) : undefined;
            inventory.push({ source: 'ndk', module: attributed || lastNdkInclude, symbol: m[0], file: relFile, line: lineNo });
          }
        }
        DLOPEN_LITERAL_RE.lastIndex = 0;
        let dl;
        while ((dl = DLOPEN_LITERAL_RE.exec(line)) !== null) {
          inventory.push({ source: 'ndk', module: dl[1], symbol: '*dlopen*', file: relFile, line: lineNo });
        }
        if (DLOPEN_NONLITERAL_RE.test(line)) {
          dynamicHints.push({ file: relFile, line: lineNo, kind: 'dlopen' });
        }
        continue;
      }

 // ArkTS / 配置 —— 多行具名 import 状态机（起始行计数）
      MODULE_RE.lastIndex = 0;
      const headModule = MODULE_RE.exec(line);
      const startsNewImport = /^\s*import\b/.test(line);
      const opensPending = startsNewImport && line.includes('{') && !line.includes('}')
        && !headModule;
      if (pendingImport) {
 // ：新 import 语句出现 = pending 块为本地/未闭合模块，安全丢弃后处理当前行
        if (startsNewImport) {
          pendingImport = null; // 本地多行 import（from 'musicbasic' 等）：丢弃，不误吞后续
        } else {
          pendingImport.buf += ` ${line.trim()}`;
          const overflow = (i - pendingImport.startLine) > MULTILINE_IMPORT_MAX_LINES;
          if (headModule || overflow) {
            if (headModule) {
              for (const item of expandModule(headModule[1], symbolsOf(pendingImport.buf, headModule[1]), kitIndex)) {
                inventory.push({ ...item, file: relFile, line: pendingImport.startLine + 1 });
              }
            }
            pendingImport = null; // 畸形（overflow 无模块）安全丢弃
          }
          continue;
        }
 // startsNewImport 分支：fall through 让当前行按新 import 正常处理
      }
      if (opensPending) {
        pendingImport = { startLine: i, buf: line.trim() };
        continue;
      }

      MODULE_RE.lastIndex = 0;
      let match;
      while ((match = MODULE_RE.exec(line)) !== null) {
        const module = match[1];
        for (const item of expandModule(module, symbolsOf(line, module), kitIndex)) {
          inventory.push({ ...item, file: relFile, line: lineNo });
        }
      }
      if (DYN_IMPORT_NONLITERAL_RE.test(line)) {
        dynamicHints.push({ file: relFile, line: lineNo, kind: 'dynamic-import' });
      }
    }
  }
  return { inventory, dynamicHints };
}

/**
 * @kit 展开与来源归属：
 * - kit 已知 + 符号可解析 → 落到真实 @ohos.* 模块（source=ohos）
 * - kit 已知 + 星号/动态等模块级引用 → 展开为全部成员模块（确定性排序）
 * - 符号不可解析 / kit 未知 / 无索引（降级）→ 保留 @kit.* 模块（判定侧显式 unknown，不静默）
 */
function expandModule(module, symbols, kitIndex) {
  const items = [];
  if (!module.startsWith('@kit.')) {
    for (const symbol of symbols) {
      items.push({ source: module.startsWith('@ohos.') ? 'ohos' : 'hms', module, symbol });
    }
    return items;
  }
  const known = !!(kitIndex && kitIndex.kits.has(module));
  for (const symbol of symbols) {
    if (known && !symbol.startsWith('*') && kitIndex.symbols.has(symbol)) {
      const mapped = kitIndex.symbols.get(symbol);
      items.push({ source: mapped.startsWith('@ohos.') ? 'ohos' : 'hms', module: mapped, symbol });
      continue;
    }
    if (known) {
 // 星号/动态/默认名/不可解析符号（kit 已知）：模块级引用 → 展开全部成员（确定性排序）
      for (const m of [...kitIndex.kits.get(module)].sort()) {
        items.push({ source: m.startsWith('@ohos.') ? 'ohos' : 'hms', module: m, symbol });
      }
      continue;
    }
 // ：未知/未展开 kit 归属不可判定（可能为 HMS 闭源生态或降级模式 OH kit）→ source=unknown，
 // 判定侧仍走 @kit 显式 unknown 分支（classifyOhos），统计不再虚计 ohos
    items.push({ source: 'unknown', module, symbol });
  }
  return items;
}

/**
 * 符号归一（design 固化）：
 * - 具名导入：取原始导出名（剥离 `as 别名`），每个符号独立一项
 * - 默认导入：取本地命名空间名
 * - 动态导入：*dynamic*
 * - 配置文件/其他出现：*module-ref*
 */
function symbolsOf(line, module) {
  const fromIdx = indexOfAny(line, [`from '${module}'`, `from "${module}"`]);
  const dynIdx = indexOfAny(line, [`import('${module}')`, `import("${module}")`, `import(\`${module}\`)`]);

  if (fromIdx !== -1) {
    const head = line.slice(0, fromIdx).trim();
    const brace = head.indexOf('{');
    if (brace !== -1) {
      const close = head.lastIndexOf('}');
      const names = head.slice(brace + 1, close === -1 ? undefined : close);
      const symbols = names.split(',').map((s) => s.trim()).filter(Boolean)
        .map((s) => s.split(/\s+as\s+/)[0].replace(/^type\s+/, ''));
 // 混合形态：import ns, { a, b } from '...'——默认符号与具名符号一并产出
      const def = head.slice(0, brace).match(/(?:^|\s)import\s+(?:type\s+)?([A-Za-z_$][\w$]*)\s*,\s*$/);
      if (def) symbols.unshift(def[1]);
      return symbols.length ? symbols : ['*'];
    }
    const m = head.match(/import\s+([A-Za-z_$][\w$]*)\s*$/);
    if (m) return [m[1]];
    return ['*'];
  }
  if (dynIdx !== -1) {
    return ['*dynamic*'];
  }
  return ['*module-ref*'];
}

function indexOfAny(line, needles) {
  let best = -1;
  for (const needle of needles) {
    const idx = line.indexOf(needle);
    if (idx !== -1 && (best === -1 || idx < best)) best = idx;
  }
  return best;
}
