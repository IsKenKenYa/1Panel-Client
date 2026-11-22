#!/usr/bin/env node
/**
 * 生成保守的 ArkUI V1/V2 迁移清单。
 * 这是词法扫描器，不是 ArkTS 解析器；编辑源码前仍需确认输出证据。
 * 需要 Node.js 20+，仅使用内置模块。
 */
import { existsSync, readFileSync, readdirSync, realpathSync, statSync } from 'node:fs';
import { homedir } from 'node:os';
import { basename, extname, join, relative, resolve, sep } from 'node:path';
import { parseArgs } from 'node:util';

const SKIP_DIRS = new Set([
  '.git', '.hvigor', '.idea', '.preview', 'build', 'node_modules', 'oh_modules',
]);
const SKIP_FILES = new Set(['hvigorfile.ts', 'hvigorfile.js']);
const SOURCE_SUFFIXES = new Set(['.ets', '.ts']);
const MANIFEST_NAMES = new Set([
  'build-profile.json5', 'oh-package.json5', 'oh-package-lock.json5', 'module.json5', 'app.json5',
]);
const V1_DECORATORS = new Set([
  'Component', 'State', 'Prop', 'Link', 'ObjectLink', 'Provide', 'Consume',
  'StorageLink', 'StorageProp', 'LocalStorageLink', 'LocalStorageProp',
  'Observed', 'Track', 'Watch', 'Reusable',
]);
const V2_DECORATORS = new Set([
  'ComponentV2', 'Local', 'Param', 'Event', 'Provider', 'Consumer', 'ObservedV2',
  'Trace', 'Monitor', 'SyncMonitor', 'Computed', 'Once', 'ReusableV2', 'Type',
]);
const STATIC_API_OWNERS = new Set([
  'AppStorage', 'AppStorageV2', 'PersistentStorage', 'PersistenceV2',
  'Environment', 'LocalStorage', 'UIUtils',
]);

// 使用 Unicode 单词字符及边界，避免中文标识符被 JavaScript 的 ASCII \w/\b 截断。
const WORD = String.raw`[\p{L}\p{N}_]`;
const BOUNDARY = String.raw`(?:(?<!${WORD})(?=${WORD})|(?<=${WORD})(?!${WORD}))`;
const DECORATOR_RE = new RegExp(String.raw`@(${WORD}+)${BOUNDARY}(?:\s*\(([^\r\n)]*)\))?`, 'gu');
const COMPONENT_RE = new RegExp(
  String.raw`((?:@${WORD}+(?:\s*\([^\r\n)]*\))?\s*)+)(?:export\s+)?struct\s+(${WORD}+)`, 'gu',
);
const CLASS_RE = new RegExp(
  String.raw`((?:@${WORD}+(?:\s*\([^\r\n)]*\))?\s*)+)(?:export\s+)?class\s+(${WORD}+)`, 'gu',
);
const PROVIDE_RE = new RegExp(
  String.raw`@(Provide|Consume|Provider|Consumer)${BOUNDARY}(?:\s*\(([^\r\n)]*)\))?`, 'gu',
);
const STORAGE_DECORATOR_RE = /@(LocalStorageLink|LocalStorageProp|StorageLink|StorageProp)\s*\(([^\r\n)]*)\)/gu;
const STORAGE_CALL_RE = new RegExp(
  String.raw`${BOUNDARY}(AppStorageV2|PersistenceV2|AppStorage|PersistentStorage|Environment|LocalStorage|UIUtils)\.(${WORD}+)\s*\(([^\r\n)]*)`, 'gu',
);
const LOCAL_INSTANCE_CALL_RE = new RegExp(
  String.raw`${BOUNDARY}([A-Za-z_$][\p{L}\p{N}_$]*)\.(setOrCreate|getOrCreate|set|get|has|delete|link|prop|ref)\s*\(([^\r\n)]*)`, 'gu',
);
const RENDER_RE = new RegExp(String.raw`${BOUNDARY}(ForEach|LazyForEach|Repeat)\s*\(`, 'gu');
const IMPORT_RE = new RegExp(
  String.raw`${BOUNDARY}from\s+['"]([^'"]+)['"]|${BOUNDARY}import\s*\(\s*['"]([^'"]+)['"]\s*\)`, 'gu',
);
const SDK_RE = /['"]?(compatibleSdkVersion|targetSdkVersion|compileSdkVersion)['"]?\s*:\s*['"]?([^,'"}\s]+)/gu;
const MODULE_RE = /['"]?(name|srcPath|type)['"]?\s*:\s*['"]([^'"]+)['"]/gu;
const DEP_PAIR_RE = /['"]([^'"]+)['"]\s*:\s*['"]([^'"]+)['"]/gu;

function* iterFiles(root, { suffixes, names, archiveSuffix } = {}) {
  function* walk(directory) {
    const entries = readdirSync(directory, { withFileTypes: true });
    for (const entry of entries) {
      if (SKIP_FILES.has(entry.name)) continue;
      const path = join(directory, entry.name);
      const isFile = entry.isFile()
        || (entry.isSymbolicLink() && statSync(path, { throwIfNoEntry: false })?.isFile());
      const archiveName = process.platform === 'win32' ? entry.name.toLowerCase() : entry.name;
      if (isFile && (suffixes?.has(extname(entry.name).toLowerCase()) || names?.has(entry.name)
        || (archiveSuffix && archiveName.endsWith(archiveSuffix)))) {
        yield path;
      }
    }
    for (const entry of entries) {
      // 在遍历时排除生成目录；不递归进入符号链接目录。
      if (entry.isDirectory() && !SKIP_DIRS.has(entry.name)) yield* walk(join(directory, entry.name));
    }
  }
  yield* walk(root);
}

function readText(path) {
  return readFileSync(path, 'utf8').replace(/\r\n?/g, '\n');
}

function relativePath(root, path) {
  return relative(root, path).split(sep).join('/');
}

function trimWhitespace(value) {
  // 保留 UTF-8 BOM 等非空白字符，避免改变证据原文。
  return value.replace(/^[\p{White_Space}\x1c-\x1f]+|[\p{White_Space}\x1c-\x1f]+$/gu, '');
}

function stripComments(text) {
  const out = [];
  let index = 0;
  let block = false;
  let quote = null;
  let escape = false;
  while (index < text.length) {
    const char = text[index];
    const following = text[index + 1] ?? '';
    if (block) {
      if (char === '*' && following === '/') {
        out.push('  ');
        block = false;
        index += 2;
      } else {
        out.push(char === '\n' ? '\n' : ' ');
        index++;
      }
      continue;
    }
    if (quote) {
      out.push(char);
      if (escape) escape = false;
      else if (char === '\\') escape = true;
      else if (char === quote) quote = null;
      index++;
      continue;
    }
    if (char === "'" || char === '"' || char === '`') {
      quote = char;
      out.push(char);
      index++;
    } else if (char === '/' && following === '*') {
      out.push('  ');
      block = true;
      index += 2;
    } else if (char === '/' && following === '/') {
      while (index < text.length && text[index] !== '\n') {
        out.push(' ');
        index++;
      }
    } else {
      out.push(char);
      index++;
    }
  }
  return out.join('');
}

function evidence(root, path, original, match, fields) {
  const line = original.slice(0, match.index).split('\n').length;
  const sourceLine = original.split(/[\n\v\f\x1c-\x1e\x85\u2028\u2029]/u)[line - 1] ?? '';
  return {
    file: relativePath(root, path),
    line,
    text: Array.from(trimWhitespace(sourceLine)).slice(0, 220).join(''),
    ...fields,
  };
}

function decorators(block) {
  return Array.from(block.matchAll(DECORATOR_RE), match => match[1]);
}

function firstArgument(value) {
  value = trimWhitespace(value);
  let depth = 0;
  let quote = null;
  let escape = false;
  for (let index = 0; index < value.length; index++) {
    const char = value[index];
    if (quote) {
      if (escape) escape = false;
      else if (char === '\\') escape = true;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === "'" || char === '"' || char === '`') quote = char;
    else if ('([{'.includes(char)) depth++;
    else if (')]}'.includes(char)) depth = Math.max(0, depth - 1);
    else if (char === ',' && depth === 0) return trimWhitespace(value.slice(0, index));
  }
  return trimWhitespace(value);
}

function escapeRegex(value) {
  return value.replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function objectBody(text, field) {
  const match = new RegExp(String.raw`['"]?${escapeRegex(field)}['"]?\s*:\s*\{`, 'u').exec(text);
  if (!match) return null;
  const start = match.index + match[0].length - 1;
  let depth = 0;
  let quote = null;
  let escape = false;
  for (let index = start; index < text.length; index++) {
    const char = text[index];
    if (quote) {
      if (escape) escape = false;
      else if (char === '\\') escape = true;
      else if (char === quote) quote = null;
      continue;
    }
    if (char === "'" || char === '"') quote = char;
    else if (char === '{') depth++;
    else if (char === '}') {
      depth--;
      if (depth === 0) return text.slice(start + 1, index);
    }
  }
  return null;
}

function scanSource(root, path, componentFilter, result) {
  const original = readText(path);
  const code = stripComments(original);
  const add = (key, match, fields) => result[key].push(evidence(root, path, original, match, fields));
  for (const match of code.matchAll(COMPONENT_RE)) {
    add('components', match, { name: match[2], decorators: decorators(match[1]) });
  }
  for (const match of code.matchAll(CLASS_RE)) {
    const decos = decorators(match[1]);
    if (decos.includes('Observed') || decos.includes('ObservedV2')) {
      add('observable_classes', match, { name: match[2], decorators: decos });
    }
  }
  for (const match of code.matchAll(DECORATOR_RE)) {
    if (V1_DECORATORS.has(match[1]) || V2_DECORATORS.has(match[1])) {
      add('decorators', match, { name: match[1], argument: trimWhitespace(match[2] || '') });
    }
  }
  for (const match of code.matchAll(PROVIDE_RE)) {
    add('provide_consume', match, { kind: match[1], alias: trimWhitespace(match[2] || '<implicit>') });
  }
  for (const match of code.matchAll(STORAGE_DECORATOR_RE)) {
    add('storage', match, {
      kind: 'decorator', owner: match[1], operation: 'bind', key: firstArgument(match[2]),
    });
  }
  for (const match of code.matchAll(STORAGE_CALL_RE)) {
    add('storage', match, {
      kind: 'static-call', owner: match[1], operation: match[2], key: firstArgument(match[3]),
    });
    if (match[1] === 'UIUtils'
      && ['makeV1Observed', 'enableV2Compatibility', 'makeObserved'].includes(match[2])) {
      add('compatibility_calls', match, { function: `UIUtils.${match[2]}` });
    }
  }
  for (const match of code.matchAll(LOCAL_INSTANCE_CALL_RE)) {
    if (!STATIC_API_OWNERS.has(match[1])) {
      add('local_storage_candidates', match, {
        owner: match[1], operation: match[2], key: firstArgument(match[3]),
      });
    }
  }
  for (const match of code.matchAll(RENDER_RE)) add('rendering', match, { construct: match[1] });
  for (const match of code.matchAll(IMPORT_RE)) {
    const module = match[1] || match[2];
    if (module.toLowerCase().includes('arkui.advanced') || module.toLowerCase().includes('arkui-advanced')) {
      add('advanced_imports', match, { module });
    }
    if (!module.startsWith('.') && !module.startsWith('@kit.')) add('external_imports', match, { module });
  }
  if (componentFilter) {
    const callRe = new RegExp(String.raw`${BOUNDARY}${escapeRegex(componentFilter)}\s*\(`, 'gu');
    for (const match of code.matchAll(callRe)) {
      add('component_references', match, { component: componentFilter });
    }
  }
}

function scanManifests(root, result) {
  for (const path of iterFiles(root, { names: MANIFEST_NAMES })) {
    const text = readText(path);
    const file = relativePath(root, path);
    for (const match of text.matchAll(SDK_RE)) {
      result.sdk_versions.push({ file, field: match[1], value: match[2] });
    }
    const name = basename(path);
    if (name === 'build-profile.json5') {
      for (const match of text.matchAll(MODULE_RE)) {
        result.module_evidence.push({ file, field: match[1], value: match[2] });
      }
    }
    const fields = name === 'oh-package.json5'
      ? ['dependencies', 'devDependencies', 'dynamicDependencies']
      : name === 'oh-package-lock.json5' ? ['specifiers'] : [];
    for (const scope of fields) {
      const body = objectBody(text, scope);
      if (body === null) continue;
      for (const match of body.matchAll(DEP_PAIR_RE)) {
        result.dependency_candidates.push({ file, scope, name: match[1], specifier: match[2] });
      }
    }
  }
  for (const suffix of ['.har', '.hsp']) {
    for (const path of iterFiles(root, { archiveSuffix: suffix })) {
      result.local_archives.push(relativePath(root, path));
    }
  }
}

function buildResult(root, componentFilter) {
  const result = {
    project_root: root,
    project_markers: [],
    sdk_versions: [],
    module_evidence: [],
    components: [],
    observable_classes: [],
    decorators: [],
    provide_consume: [],
    storage: [],
    local_storage_candidates: [],
    compatibility_calls: [],
    rendering: [],
    advanced_imports: [],
    external_imports: [],
    dependency_candidates: [],
    local_archives: [],
    component_filter: componentFilter,
    component_references: [],
    notes: [
      '本结果仅来自词法扫描；请在源码中确认组件层级、alias、动态 key、修改位置和数据类型。',
      '已排除生成目录和下载的依赖树；请单独检查依赖包的公共导出。',
    ],
  };
  for (const name of ['build-profile.json5', 'hvigorfile.ts', 'hvigorfile.js', 'hvigorw', 'hvigorw.bat']) {
    if (existsSync(join(root, name))) result.project_markers.push(name);
  }
  for (const path of iterFiles(root, { suffixes: SOURCE_SUFFIXES })) {
    scanSource(root, path, componentFilter, result);
  }
  scanManifests(root, result);
  return result;
}

function table(rows, columns) {
  if (!rows.length) return '_未发现。_\n';
  const header = `| ${columns.map(([label]) => label).join(' | ')} |`;
  const divider = `| ${columns.map(() => '---').join(' | ')} |`;
  const body = rows.map(row => {
    const values = columns.map(([, key]) => {
      const value = Array.isArray(row[key]) ? row[key].join(', ') : String(row[key] ?? '');
      return value.replace(/\|/g, '\\|').replace(/\n/g, ' ');
    });
    return `| ${values.join(' | ')} |`;
  });
  return [header, divider, ...body].join('\n') + '\n';
}

function counts(rows, key, prefix = '') {
  const values = new Map();
  for (const row of rows) values.set(row[key], (values.get(row[key]) ?? 0) + 1);
  return [...values.keys()].sort().map(name => `\`${prefix}${name}\`=${values.get(name)}`).join(', ') || '未发现。';
}

function markdown(result) {
  const lines = [
    '# ArkUI V1/V2 迁移清单', '',
    `工程根目录：\`${result.project_root}\``, '',
    `工程标记：${result.project_markers.join(', ') || '无'}`, '',
    '## SDK 证据', '',
    table(result.sdk_versions, [['文件', 'file'], ['字段', 'field'], ['值', 'value']]),
    '## 模块证据', '',
    table(result.module_evidence, [['文件', 'file'], ['字段', 'field'], ['值', 'value']]),
    '## 装饰器数量', '', counts(result.decorators, 'name', '@'), '',
    '## 组件', '',
    table(result.components, [['组件', 'name'], ['装饰器', 'decorators'], ['文件', 'file'], ['行号', 'line']]),
    '## 可观察类', '',
    table(result.observable_classes, [['类', 'name'], ['装饰器', 'decorators'], ['文件', 'file'], ['行号', 'line']]),
  ];
  if (result.component_filter) {
    lines.push(
      `## 对 \`${result.component_filter}\` 的引用`, '',
      table(result.component_references, [['文件', 'file'], ['行号', 'line'], ['证据', 'text']]),
    );
  }
  lines.push(
    '## Provide/Consume 候选项', '',
    table(result.provide_consume, [['类型', 'kind'], ['Alias', 'alias'], ['文件', 'file'], ['行号', 'line']]),
    '## Storage key 证据', '',
    table(result.storage, [['所有者', 'owner'], ['操作', 'operation'], ['Key 表达式', 'key'], ['文件', 'file'], ['行号', 'line']]),
    '## 类 LocalStorage 实例调用候选项', '',
    table(result.local_storage_candidates, [['所有者', 'owner'], ['操作', 'operation'], ['Key 表达式', 'key'], ['文件', 'file'], ['行号', 'line']]),
    '## 兼容 API 调用', '',
    table(result.compatibility_calls, [['函数', 'function'], ['文件', 'file'], ['行号', 'line']]),
    '## 渲染结构数量', '', counts(result.rendering, 'construct'), '',
    '## 渲染/复用证据', '',
    table(result.rendering, [['结构', 'construct'], ['文件', 'file'], ['行号', 'line'], ['证据', 'text']]),
    '## 高级组件 import', '',
    table(result.advanced_imports, [['模块', 'module'], ['文件', 'file'], ['行号', 'line']]),
    '## 外部 import 候选项', '',
    table(result.external_imports, [['模块', 'module'], ['文件', 'file'], ['行号', 'line']]),
    '## 依赖候选项', '',
    table(result.dependency_candidates, [['范围', 'scope'], ['名称', 'name'], ['依赖描述', 'specifier'], ['文件', 'file']]),
    '## 本地 HAR/HSP 归档', '',
    result.local_archives.map(item => `- \`${item}\``).join('\n') || '_未发现。_', '',
    '## 注意事项', '', ...result.notes.map(note => `- ${note}`), '',
  );
  return lines.join('\n');
}

const HELP = `用法：node scripts/inventory.mjs <project_root> [--component <组件名>] [--format markdown|json]

在不修改工程的前提下，生成 ArkUI V1/V2 迁移候选项清单。

位置参数：
  project_root          HarmonyOS/OpenHarmony 工程或源码根目录

选项：
  -h, --help            显示此帮助信息并退出
  --component <组件名>  列出该组件的创建/引用位置
  --format <格式>       markdown 或 json，默认为 markdown

示例：
  node scripts/inventory.mjs "path/to/project"
  node scripts/inventory.mjs "path/to/project" --component Child --format json
`;

function main() {
  let args;
  try {
    args = parseArgs({
      options: {
        help: { type: 'boolean', short: 'h' },
        component: { type: 'string' },
        format: { type: 'string', default: 'markdown' },
      },
      allowPositionals: true,
    });
    if (args.values.help) {
      process.stdout.write(HELP);
      return 0;
    }
    if (args.positionals.length !== 1) throw new Error('请提供一个工程根目录。');
    if (!['markdown', 'json'].includes(args.values.format)) {
      throw new Error('--format 只能是 markdown 或 json。');
    }
  } catch (error) {
    process.stderr.write(`错误：${error.message}\n${HELP}`);
    return 2;
  }
  let root = args.positionals[0];
  if (root === '~') root = homedir();
  else if (/^~[/\\]/u.test(root)) root = join(homedir(), root.slice(2));
  root = resolve(root);
  if (!statSync(root, { throwIfNoEntry: false })?.isDirectory()) {
    process.stderr.write(`错误：工程根目录不是有效目录：${root}\n`);
    return 2;
  }
  root = realpathSync.native(root);
  const result = buildResult(root, args.values.component ?? null);
  process.stdout.write((args.values.format === 'json' ? JSON.stringify(result, null, 2) : markdown(result)) + '\n');
  return 0;
}

try {
  process.exitCode = main();
} catch (error) {
  process.stderr.write(`错误：${error.message}\n`);
  process.exitCode = 1;
}
