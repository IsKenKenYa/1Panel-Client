import { readFileSync } from 'node:fs';

/** ScanReport 契约加载与③④清单提取（spec  只读消费） */

export class FormatError extends Error {
  /** @param {string} field 缺失/类型不符的字段名（提示语料） */
  constructor(field) {
    super(`ScanReport格式异常：缺少${field}字段`);
    this.field = field;
  }
}

/**
 * 加载并做最小契约校验（仅校验本 Skill 消费面：adaptation.equivalent_bridge/degraded_bridge）。
 * @param {string} path ScanReport 文件路径
 * @returns {object} ScanReport JSON
 * @throws {FormatError} 缺字段或类型不符
 */
export function loadScanReport(path) {
  const report = JSON.parse(readFileSync(path, 'utf8'));
  if (typeof report !== 'object' || report === null || Array.isArray(report)) {
    throw new FormatError('顶层对象');
  }
  if (!('adaptation' in report) || typeof report.adaptation !== 'object' || report.adaptation === null) {
    throw new FormatError('adaptation');
  }
  for (const key of ['equivalent_bridge', 'degraded_bridge']) {
    if (!(key in report.adaptation)) throw new FormatError(`adaptation.${key}`);
    if (!Array.isArray(report.adaptation[key])) throw new FormatError(`adaptation.${key}（应为数组）`);
  }
  return report;
}

/**
 * 提取③+④清单并归一为 BridgeItem[]（同一 module+symbol 仅一套五件套， 边界）。
 * @returns {Array<{name:string,module:string,symbol:string,category:'equivalent_bridge'|'degraded_bridge',locations:string[],reason:string,advice:string}>}
 */
export function extractBridges(report) {
  const seen = new Set();
  const items = [];
  for (const category of ['equivalent_bridge', 'degraded_bridge']) {
    for (const raw of report.adaptation[category]) {
      const key = `${raw.module}::${raw.symbol}`;
      if (seen.has(key)) continue; // 同接口跨桶去重（至多一套五件套）
      seen.add(key);
      items.push({
        name: bridgeNameOf(raw.module, raw.symbol),
        module: raw.module,
        symbol: raw.symbol,
        source: raw.source ?? 'ohos',
        category,
        locations: Array.isArray(raw.locations) ? raw.locations : [],
        reason: raw.reason ?? '',
        advice: raw.advice ?? '',
      });
    }
  }
 // G4（f3f4-r1 靶场）：#include 头文件依赖无调用语义，不生成桥接件——列入跳过清单供报告披露
  const skipped = items.filter((it) => it.symbol === '*include*');
  const bridgeItems = items.filter((it) => it.symbol !== '*include*');
 // G4：同产物名去重（序号后缀确定性去重）
  const used = new Set();
  for (const it of bridgeItems) {
    let n = it.name;
    let i = 2;
    while (used.has(n)) n = `${it.name}${i++}`;
    it.name = n;
    used.add(n);
  }
  bridgeItems.skippedIncludes = skipped;
  return bridgeItems;
}

/** Bridge 命名源：module 后缀 + symbol 分段驼峰拼接（确定性，④⑤ 文件名 {Name} 用）；符号首段与模块同名时去重 */
export function bridgeNameOf(module, symbol) {
  const pascal = (s) => s.charAt(0).toUpperCase() + s.slice(1);
 // G4：模块段保留下划线分词语义（native_avcodec_base.h → NativeAvcodecBase 而非丢分隔致 HInclude 撞名）
  const modSeg = pascal(String(module).split(/[./@]/).filter(Boolean).pop() ?? '');
  const segs = String(symbol).split(/[^A-Za-z0-9]+/).filter(Boolean).map(pascal);
  if (segs.length > 1 && segs[0].toLowerCase() === modSeg.toLowerCase()) segs.shift();
  return [modSeg, ...segs].join('');
}

/** ③+④ 均空判定（良性完成） */
export function isEmptyBridgeList(report) {
  return report.adaptation.equivalent_bridge.length === 0 && report.adaptation.degraded_bridge.length === 0;
}
