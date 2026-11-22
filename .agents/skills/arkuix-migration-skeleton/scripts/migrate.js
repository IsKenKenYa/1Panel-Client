import { readdirSync, readFileSync, writeFileSync, mkdirSync, copyFileSync, existsSync } from 'node:fs';
import { createHash } from 'node:crypto';
import { join, dirname, resolve, relative, sep } from 'node:path';

/** 忽略清单（design 风险表：特殊文件处理，SKILL.md 声明） */
const IGNORED_NAMES = new Set(['.hvigor', 'build', 'oh_modules', 'node_modules', '.git', '.idea', '.clangd', '.arkui-x']);

/**
 * 模块发现：根 build-profile.json5 的 modules[].srcPath 驱动，
 * 支持业务名 entry（如 veditor）与 products/default 布局；解析失败回退经典 entry/src/main。
 * @returns {Array<{name: string, path: string}>} 模块 src/main 清单（排序确定）
 */
export function discoverModuleMains(root) {
  const mains = [];
  const bp = join(root, 'build-profile.json5');
  let parseError = null;
  if (existsSync(bp)) {
    try {
      const doc = JSON.parse(looseJson5(readFileSync(bp, 'utf8')));
      for (const m of doc?.modules ?? []) {
        if (!m || typeof m.srcPath !== 'string') continue;
        const p = join(root, m.srcPath, 'src', 'main');
        if (existsSync(p)) mains.push({ name: String(m.name ?? m.srcPath), path: p });
      }
    } catch (err) {
      parseError = err.message; // 解析失败显式透出（不再静默吞掉）
    }
  }
  if (mains.length === 0) {
    const classic = join(root, 'entry', 'src', 'main');
    if (existsSync(classic)) mains.push({ name: 'entry', path: classic });
  }
  mains.sort((a, b) => a.name.localeCompare(b.name));
  mains.parseError = parseError;
  return mains;
}

/** 宽松 JSON5：剥注释、无引号键加引号、单引号串转双引号、去尾逗号
 * （官方样例 build-profile 无引号键为常态写法，严格 JSON.parse 必败）；
 * 导出供 config-migrator 复用（同款解析口径） */
export function looseJson5(text) {
  const stripped = stripJsonComments(text);
  return stripped
    .replace(/([{,]\s*)([A-Za-z_$][A-Za-z0-9_$]*)(\s*:)/g, '$1"$2"$3') // 无引号键
    .replace(/'([^'\\]*)'/g, '"$1"') // 单引号串
    .replace(/,(\s*[}\]])/g, '$1'); // 尾逗号
}

function stripJsonComments(text) {
  let out = '';
  let inBlock = false;
  let quote = null;
  for (let i = 0; i < text.length; i++) {
    const ch = text[i];
    const next = text[i + 1];
    if (inBlock) {
      if (ch === '*' && next === '/') { inBlock = false; i += 1; out += '  '; }
      else out += ch === '\n' ? '\n' : ' ';
      continue;
    }
    if (quote) {
      out += ch;
      if (ch === '\\') { out += next ?? ''; i += 1; continue; }
      if (ch === quote) quote = null;
      continue;
    }
    if (ch === '/' && next === '/') { while (i < text.length && text[i] !== '\n') i += 1; out += '\n'; continue; }
    if (ch === '/' && next === '*') { inBlock = true; i += 1; out += '  '; continue; }
    if (ch === '"' || ch === "'") { quote = ch; out += ch; continue; }
    out += ch;
  }
  return out;
}

/**
 * 源码迁入（多模块布局支持）：
 * - 逐模块将 <srcPath>/src/main/** 原样搬移至 <outDir>/<moduleName>/src/main
 *   （entry 模块即 scaffold 的共享 ArkTS 目录，落点与其天然一致；其余模块与 entry 平级）
 * - 搬移=复制（源工程保留原件）；不改写内容（哈希前后一致）
 * - 零迁入 = 显式失败（不静默伪成功），由调用方以退出码 2 终止
 *
 * @param {string} srcRoot 源工程根
 * @param {string} outDir new 模式输出目录（模块迁入基准）
 * @returns {{filesMoved: number, modules: Array<{name, files}>, ignored: string[],
 *            hashes: Map<string, string>, ok: boolean, reason?: string}}
 */
export function migrateSources(srcRoot, outDir) {
  const modules = discoverModuleMains(srcRoot);
  if (modules.length === 0) {
    return { filesMoved: 0, modules: [], ignored: [], hashes: new Map(), ok: false,
      reason: '源工程无可迁入源码（未发现任何模块的 src/main：build-profile modules 与经典 entry 布局均缺失）' };
  }
  const ignored = [];
  const hashes = new Map();
  const perModule = [];
  let filesMoved = 0; // 仅名为 entry 的模块 → 合入 scaffold 的 entry/（覆盖 Hello World 模板）。
 // 无 entry 命名模块时不猜测主模块（业务名工程保持模块名平级目录，scaffold entry/ 保留模板），
 // shared_arkts_dir 如实指向内容实际所在（由调用方读取 modules[].target 判断）。
  const primaryMod = modules.find((m) => m.name === 'entry');
 // G2/r2：源模块根→顶层 target 索引（file: 依赖重写映射用；entry 合入 scaffold 顶层 entry/）
  const moduleIndex = modules.map((m) => ({
    src: resolve(m.path, '../..'),
    target: m === primaryMod ? 'entry' : m.name,
  }));
  for (const mod of modules) {
    const files = [];
    collect(mod.path, mod.path, files, ignored);
    files.sort();
    const targetDir = mod === primaryMod ? 'entry' : mod.name;
    for (const rel of files) {
      const from = join(mod.path, rel);
      const to = join(outDir, targetDir, 'src', 'main', rel);
      mkdirSync(dirname(to), { recursive: true });
      copyFileSync(from, to);
      hashes.set(`${mod.name}:${rel}`, hashOf(from));
      filesMoved += 1;
    }
 // G2 修复（f3f4-r1 靶场，2026-10-11；r2 修正嵌套 srcPath）：非 entry 模块补迁模块级文件——
 // build-profile.json5/oh-package.json5/hvigorfile.ts/hvigor-config.json5/Index.ets（oh-package main 桶入口）/obfuscation-rules.txt；
 // 模块根从 mod.path（<srcPath>/src/main）回溯两级推导，兼容嵌套 srcPath（./commons/base、products/phone 等）；
 // oh-package.json5 的 file: 相对依赖随扁平化提升重写（原模块位置→顶层 <target>/），重写后以最终内容入哈希账。
    const MODULE_LEVEL_FILES = ['build-profile.json5', 'oh-package.json5', 'hvigorfile.ts',
      'hvigor-config.json5', 'Index.ets', 'obfuscation-rules.txt', 'consumer-rules.txt'];
    if (mod !== primaryMod) {
      const modRoot = resolve(mod.path, '../..');
      const levelCopied = [];
      for (const f of MODULE_LEVEL_FILES) {
        const from = join(modRoot, f);
        if (!existsSync(from)) continue;
        const to = join(outDir, targetDir, f);
        mkdirSync(dirname(to), { recursive: true });
        if (f === 'oh-package.json5') {
          let text = readFileSync(from, 'utf8');
          const { text: rewritten, count } = rewriteFileDeps(text, modRoot, moduleIndex);
          writeFileSync(to, rewritten, 'utf8');
          hashes.set(`${mod.name}:/${f}`, hashOf(to));
          if (count > 0) levelCopied.push(`${f}(依赖重写×${count})`);
          else levelCopied.push(f);
        } else {
          copyFileSync(from, to);
          hashes.set(`${mod.name}:/${f}`, hashOf(to));
          levelCopied.push(f);
        }
      }
      if (levelCopied.length > 0) console.log(`模块 ${mod.name}（${relative(srcRoot, modRoot) || modRoot}）补迁模块级文件 ${levelCopied.length} 件${levelCopied.some(x=>x.includes('重写')) ? '（含依赖重写）' : ''}`);
    }
    perModule.push({ name: mod.name, files: files.length, target: targetDir });
  }
  ignored.sort();
  if (filesMoved === 0) {
    return { filesMoved: 0, modules: perModule, ignored, hashes, ok: false,
      reason: '迁移清单为空（各模块 src/main 下无文件或全部被忽略清单排除）' };
  } // AppScope 项目级资源随迁——new 模式 scaffold 自带 AppScope（空资源集）会遮蔽
 // 源工程的媒体/资源。策略：源文件覆盖同名、
 // scaffold 独有保留（合并非替换）；app.json5 例外——scaffold 版已按 --project-name/--bundle-name 定制。
  const srcAppScope = join(srcRoot, 'AppScope');
  if (existsSync(srcAppScope)) {
    const asFiles = [];
    collect(srcAppScope, srcAppScope, asFiles, []);
    let asCopied = 0;
    for (const rel of asFiles) {
      if (rel === 'app.json5') continue; // scaffold 定制版保留
      const from = join(srcAppScope, rel);
      const to = join(outDir, 'AppScope', rel);
      mkdirSync(dirname(to), { recursive: true });
      copyFileSync(from, to);
      hashes.set(`AppScope:${rel}`, hashOf(from));
      asCopied += 1;
    }
    if (asCopied > 0) console.log(`AppScope 项目级资源随迁 ${asCopied} 件（源覆盖同名；app.json5 保留 scaffold 定制版）`);
    filesMoved += asCopied;
  }
  return { filesMoved, modules: perModule, ignored, hashes, ok: true };
}

/** oh-package.json5 的 file: 相对依赖随扁平化提升重写：
 * 原路径相对源模块根解析 → 命中被迁移模块（src 前缀）→ 重写为 file:../<target>[/<模块内剩余路径>]；
 * 未命中（外部/oh_modules 等）原样保留。返回重写后文本与重写计数。 */
function rewriteFileDeps(text, srcModRoot, moduleIndex) {
  let count = 0;
  const mapTo = (rel) => {
    const abs = resolve(srcModRoot, rel);
    const hit = moduleIndex.find((mi) => abs === mi.src || abs.startsWith(mi.src + sep));
    if (!hit) return null;
 // 剩余路径归一为 / 分隔（Windows 下 slice 产生 \，写入 oh-package 的 file: 依赖不得混用分隔符）
    const rest = abs === hit.src ? '' : abs.slice(hit.src.length + 1).split(sep).join('/');
    count += 1;
    return '../' + hit.target + (rest ? '/' + rest : '');
  };
 // 形态1：file:../xxx；形态2：裸 "../xxx"（仅 .. 开头跨目录依赖；./ 自指不动）
  let out = text.replace(/(file:)(\.?\.?\/[^"'\n,}]+)/g, (m, p1, rel) => mapTo(rel) ? p1 + mapTo(rel) : m);
  out = out.replace(/"(\.\.\/[^"']+)"/g, (m, rel) => (mapTo(rel) ? '"' + mapTo(rel) + '"' : m));
  return { text: out, count };
}

/**校验：目标文件集合与内容哈希同源一致（键以 "/" 开头=模块级文件，落 <target>/ 根） */
export function verifyMigration(srcRoot, outDir, migration) {
  if (!migration || !migration.ok) return { ok: false, reason: (migration && migration.reason) || '迁移统计缺失' };
  const targetMap = new Map((migration.modules ?? []).map((m) => [m.name, m.target ?? m.name]));
  for (const [key, expectedHash] of migration.hashes) {
    const [modName, ...rest] = key.split(':');
    const rel = rest.join(':'); // AppScope 项目级资源键（AppScope:<rel>）落 outDir/AppScope/<rel>——非模块 src/main 形态
    if (modName === 'AppScope') {
      const to = join(outDir, 'AppScope', rel);
      if (!existsSync(to)) return { ok: false, reason: `迁入缺失: ${key}` };
      if (hashOf(to) !== expectedHash) return { ok: false, reason: `内容被改写: ${key}` };
      continue;
    }
    const targetDir = targetMap.get(modName) ?? modName;
    const to = rel.startsWith('/') ? join(outDir, targetDir, rel.slice(1)) : join(outDir, targetDir, 'src', 'main', rel);
    if (!existsSync(to)) return { ok: false, reason: `迁入缺失: ${key}` };
    if (hashOf(to) !== expectedHash) return { ok: false, reason: `内容被改写: ${key}` };
  }
  return { ok: true };
}

function collect(root, dir, files, ignored) {
  for (const entry of readdirSync(dir, { withFileTypes: true })) {
    if (IGNORED_NAMES.has(entry.name)) {
      ignored.push(entry.name);
      continue;
    }
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      collect(root, full, files, ignored);
    } else if (entry.isFile()) {
 // 相对路径归一为 / 分隔（Windows join 产生 \；哈希账键与断言跨平台稳定）
      files.push(relative(root, full).split(sep).join('/'));
    }
  }
}

function hashOf(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}
