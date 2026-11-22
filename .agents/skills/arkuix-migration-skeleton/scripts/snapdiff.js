import { createHash } from 'node:crypto';
import { readdirSync, readFileSync } from 'node:fs';
import { join, relative, sep } from 'node:path';

const IGNORED = new Set(['.git', '.hvigor', 'oh_modules', 'node_modules', 'build', '.previewer', '.cxx']);

/**
 * 工程文件快照：全工程（排除缓存/产物目录）文件 → sha256。
 * modify 前后各取一次，diff 得"实际改动文件清单"（新增+改写全覆盖，
 * 修复此前仅枚举 .arkui-x/ 子树、漏报既有构建文件改写的问题）。
 */
export function snapshotProject(root) {
  const map = new Map();
  walk(root, root, map);
  return map;
}

function walk(root, dir, map) {
  let entries;
  try {
    entries = readdirSync(dir, { withFileTypes: true });
  } catch {
    return;
  }
  for (const e of entries) {
    if (e.isDirectory()) {
      if (IGNORED.has(e.name)) continue;
      walk(root, join(dir, e.name), map);
    } else if (e.isFile()) {
      const full = join(dir, e.name);
 // 相对路径归一为 / 分隔（Windows relative 产生 \；diff 清单为跨平台稳定标识符）
      map.set(relative(root, full).split(sep).join('/'), hashOf(full));
    }
  }
}

/** 前后快照 diff：返回新增+改写的相对路径清单（排序确定） */
export function diffSnapshots(before, after) {
  const changed = [];
  for (const [rel, hash] of after) {
    if (!before.has(rel)) changed.push(`+ ${rel}`);
    else if (before.get(rel) !== hash) changed.push(`~ ${rel}`);
  }
  for (const rel of before.keys()) {
    if (!after.has(rel)) changed.push(`- ${rel}`);
  }
  return changed.sort();
}

function hashOf(file) {
  return createHash('sha256').update(readFileSync(file)).digest('hex');
}
