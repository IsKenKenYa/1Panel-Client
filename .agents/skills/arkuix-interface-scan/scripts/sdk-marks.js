import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * SDK 标记提取（L2.5， 源）：解析 ets/api 下 @ohos.*.d.ts 的 @crossplatform 标记
 * 输出 MarkIndex：Map<module, {moduleMarked: boolean|null, symbols: Map<symbol, boolean>}>
 *
 * 标记语义：
 * - 文件头注释块（declare namespace 之前）含 @crossplatform → moduleMarked=true（整模块支持）
 * - 模块声明存在但头注释无标记 → moduleMarked=false；符号级 JSDoc 含标记 → symbols[symbol]=true
 * - 仅识别被「注释块紧随其后的声明」命中的符号；无标记符号不写入 symbols（resolveMark 视为 unmarked）
 */
export function scanMarks(apiDir) {
  const marks = new Map();
  let files = [];
  try {
 // ：扩展至 .d.ets（62 个文件、37 含 @crossplatform，如 ArkSlider 全家族）
    files = readdirSync(apiDir).filter((f) => f.startsWith('@ohos.')
      && (f.endsWith('.d.ts') || f.endsWith('.d.ets')));
  } catch (err) {
    throw new Error(`SDK 标记索引构建失败（无法读取 ${apiDir}）: ${err.message}`);
  }
  for (const file of files) {
    const module = file.replace(/\.d\.(ts|ets)$/, '');
    let text;
    try {
      text = readFileSync(join(apiDir, file), 'utf8');
    } catch {
      continue;
    }
    marks.set(module, parseMarks(text));
  }
  return marks;
}

export function parseMarks(text) {
  const entry = { moduleMarked: null, symbols: new Map() };

  const tokens = tokenize(text);
  let i = 0;
  let sawModuleNamespace = false;
  while (i < tokens.length) {
    const token = tokens[i];
    if (token.kind === 'comment') {
      const next = tokens[i + 1];
      const marked = /@crossplatform/.test(token.text);
      if (next && next.kind === 'decl') {
 // ：不要求注释 token.top——import 语句会毒化 commentTop 标志，
 // 但 import 不产生声明 token，"注释紧邻首个顶层 namespace"的邻接性天然保持
        if (next.name === FIRST_NAMESPACE && !sawModuleNamespace && next.type === 'namespace') {
 // 文件头注释（含 import 前置形态）+ 首个 declare namespace = 模块级标记
          entry.moduleMarked = marked;
          sawModuleNamespace = true;
        } else {
          if (marked) entry.symbols.set(next.name, true);
        }
      } else if (next && next.kind === 'reexport' && marked) {
 // ：barrel re-export 前置注释带 @crossplatform → 导出清单逐符号标记
        for (const name of next.names) entry.symbols.set(name, true);
      }
    }
    if (token.kind === 'decl' && token.type === 'namespace' && token.top && !sawModuleNamespace) {
 // 头部无注释直接进入 namespace：模块未整体标记
      sawModuleNamespace = true;
      if (entry.moduleMarked === null) entry.moduleMarked = false;
    }
    i++;
  }
  if (entry.moduleMarked === null) entry.moduleMarked = false;
  return entry;
}

const FIRST_NAMESPACE = Symbol('firstNamespace');

/** 声明正则：函数/接口/类/const/enum/type/namespace/let/var（含 export [default] / declare 前缀；：default 形态实测缺失致标记丢失） */
const DECL_RE = /^[ \t]*(?:export\s+)?(?:default\s+)?(?:declare\s+)?(?:abstract\s+)?(?:async\s+)?(function|interface|class|struct|const|enum|type|namespace|let|var)\s+([A-Za-z_$][\w$]*)/;

function tokenize(text) {
  const tokens = [];
  const lines = text.split('\n');
  let commentBuffer = null;
  let commentTop = true;
  let baseIndent = null;

  for (let ln = 0; ln < lines.length; ln++) {
    const line = lines[ln];
    const trimmed = line.trim();

    if (commentBuffer !== null) {
      commentBuffer.text += '\n' + trimmed;
      if (trimmed.endsWith('*/')) {
        tokens.push({ kind: 'comment', text: commentBuffer.text, top: commentBuffer.top });
        commentBuffer = null;
      }
      continue;
    }
    if (trimmed.startsWith('/*')) {
      if (trimmed.endsWith('*/')) {
        tokens.push({ kind: 'comment', text: trimmed, top: commentTop });
      } else {
        commentBuffer = { text: trimmed, top: commentTop };
      }
      continue;
    }
    if (trimmed.startsWith('*') || trimmed.startsWith('//')) {
 // 行注释并入块注释语义（简化：单独 token 仅当紧邻声明时有效——这里忽略行注释标记）
      continue;
    }
    if (trimmed === '') continue;

    commentTop = false;
    const indent = line.length - line.trimStart().length;
    if (baseIndent === null) baseIndent = indent;
    const top = indent <= baseIndent;

    const decl = DECL_RE.exec(line);
    if (decl) {
      tokens.push({
        kind: 'decl',
        type: decl[1],
        name: decl[2],
        top,
        firstNamespace: decl[1] === 'namespace'
      });
    } else {
 // ：barrel re-export 形态 export { A, B } from './sub'——
 // 无 declare namespace，标记挂在 re-export 块前置注释上（@ohos.arkui.node 实证 21 处）
      const rex = line.match(/^export\s*\{([^}]*)\}\s*from\s*['"][^'"]+['"]\s*;?\s*$/);
      if (rex) {
        const names = rex[1].split(',').map((x) => x.trim())
          .map((x) => x.replace(/^type\s+/, ''))
          .filter((x) => /^[A-Za-z_$][\w$]*$/.test(x));
        if (names.length > 0) tokens.push({ kind: 'reexport', names, top });
      }
    }
  }
 // 标记首 namespace（模块名）供模块级判定
  const firstNs = tokens.find((t) => t.kind === 'decl' && t.firstNamespace && t.top);
  for (const t of tokens) {
    if (t.kind === 'decl' && t === firstNs) t.name = FIRST_NAMESPACE;
  }
  return tokens;
}
