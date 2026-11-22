import { readdirSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * @kit.* 展开索引：
 * 数据源 = OH SDK `ets/kits/@kit.*.d.ts`——kit 聚合文件以
 * `import X, { A, B as C } from '@ohos.mod';` 形态声明成员与符号来源，
 * 由此构建 kit→成员模块集合 与 kit 导出面符号→@ohos 模块 映射。
 * 降级模式（无 SDK/kits 缺失）索引为 null：@kit 条目按原样保留，
 * 判定侧给出"未展开"显式 unknown（宁缺毋错，不静默）。
 */
const KIT_IMPORT_RE = /^import\s+(.+?)\s+from\s+'(@(?:ohos|hms)\.[A-Za-z0-9_.-]+)'\s*;?\s*$/;

export function buildKitIndex(kitsDir) {
  if (!kitsDir) return null;
  let entries;
  try {
    entries = readdirSync(kitsDir);
  } catch {
    return null;
  }
  const kits = new Map(); // kitName -> Set<@ohos.module>
  const symbols = new Map(); // kitSymbol -> '@ohos.module'（kit 导出面名，含别名）
  for (const name of entries) {
    if (!name.startsWith('@kit.') || !name.endsWith('.d.ts')) continue;
    const kitName = name.slice(0, -'.d.ts'.length);
    let text;
    try {
      text = readFileSync(join(kitsDir, name), 'utf8');
    } catch {
      continue;
    }
    for (const raw of text.split('\n')) {
      const m = raw.match(KIT_IMPORT_RE);
      if (!m) continue;
      const module = m[2];
      if (!kits.has(kitName)) kits.set(kitName, new Set());
      kits.get(kitName).add(module);
      for (const sym of clauseSymbols(m[1])) {
        if (!symbols.has(sym)) symbols.set(sym, module);
      }
    }
  }
  if (kits.size === 0) return null;
  return { kits, symbols };
}

/** 解析 import 子句的 kit 导出面符号（默认名 + 具名 + as 别名后的名字） */
function clauseSymbols(clause) {
  const out = [];
  const brace = clause.indexOf('{');
  const head = brace === -1 ? clause : clause.slice(0, brace);
  const dm = head.match(/([A-Za-z_$][\w$]*)\s*(?:,\s*$|$)/);
  if (dm) out.push(dm[1]);
  if (brace !== -1) {
    const close = clause.lastIndexOf('}');
    const names = clause.slice(brace + 1, close === -1 ? undefined : close);
    for (const part of names.split(',')) {
      const seg = part.trim();
      if (!seg) continue;
      const asM = seg.match(/^type\s+([\w$]+)(?:\s+as\s+([\w$]+))?$/) || seg.match(/^([\w$]+)\s+as\s+([\w$]+)$/);
      if (asM) out.push(asM[2] || asM[1]);
      else if (/^[\w$]+$/.test(seg)) out.push(seg);
    }
  }
  return out;
}

/** kit 是否已知（索引在场且含该 kit） */
export function kitKnown(index, kitName) {
  return !!(index && index.kits.has(kitName));
}

/** 展开 kit 为成员模块清单（确定性：按名排序） */
export function kitMembers(index, kitName) {
  const set = index && index.kits.get(kitName);
  return set ? [...set].sort() : [];
}
