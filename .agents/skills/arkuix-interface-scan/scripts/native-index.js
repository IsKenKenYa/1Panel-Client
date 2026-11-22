import { readdirSync, readFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';
import { stripComments } from './extract.js';

/**
 * NDK 符号→头文件权威归属索引：
 * 数据源 = OH SDK native/sysroot/usr/include 下全部 .h 文件。
 * 归属规则（确定性）：每个 OH_* 符号归属"声明权重最高"的头文件——
 * 声明形态行（函数定义/typedef/struct/enum 等）权重 2，普通引用权重 1；
 * 平局取相对路径字典序最小。修复此前"归属=文件内最近一条 NDK include"启发式
 * 在符号未直接 include 其头文件时（经传递依赖可见）的系统性错挂
 * （实测 48 条被错挂 hilog/log.h）。
 */
const OH_RE = /\b(OH_[A-Za-z]\w*)/g;
const DECL_HINT_RE = /^\s*(?:typedef|struct|enum|union|static\s+|const\s+|extern\s+|[A-Za-z_][\w\s\*]*?)$/;

export function buildNativeSymbolIndex(sysrootDir) {
  if (!sysrootDir) return null;
  const scores = new Map(); // symbol -> Map<headerRelPath, weight>
  const files = [];
  walk(sysrootDir, sysrootDir, files);
  for (const relPath of files.sort()) {
    let text;
    try {
      text = readFileSync(join(sysrootDir, relPath), 'utf8');
    } catch {
      continue;
    }
 // ：先剥注释（文档注释提及不得计分）+ 声明形态权重 10:1
 // （函数定义/原型/typedef/struct/enum/extern=10，普通代码引用=1）——
 // 修复"注释/参数提及频次击败定义头"与"平局字典序选错"两类错挂
    for (const raw of stripComments(text.split('\n'))) {
      if (!raw.includes('OH_')) continue;
      const isDecl = /\bOH_\w+\s*\(/.test(raw) || /^\s*(?:typedef|struct|enum|union|extern)\b/.test(raw);
      const weight = isDecl ? 10 : 1;
      OH_RE.lastIndex = 0;
      let m;
      while ((m = OH_RE.exec(raw)) !== null) {
        if (!scores.has(m[1])) scores.set(m[1], new Map());
        const per = scores.get(m[1]);
        per.set(relPath, (per.get(relPath) || 0) + weight);
      }
    }
  }
  const index = new Map();
  for (const [symbol, per] of scores) {
    let best = '';
    let bestWeight = -1;
    for (const [header, weight] of [...per.entries()].sort()) {
      if (weight > bestWeight) {
        best = header;
        bestWeight = weight;
      }
    }
    if (best) index.set(symbol, best);
  }
  return index.size > 0 ? index : null;
}

function walk(root, dir, files) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    const full = join(dir, e.name);
    if (e.isDirectory()) walk(root, full, files);
    // 归一 '/'：此值为 C-API 规则表（'/' 形态键）的匹配键——win32 反斜杠形态永远不命中，致真实运行 C-API 全误判 unknown
    else if (e.isFile() && e.name.endsWith('.h')) files.push(relative(root, full).split(sep).join('/'));
  }
}
