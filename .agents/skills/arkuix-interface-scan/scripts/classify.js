import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const SKILL_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

export const BUCKETS = [
  'full_direct', 'reduced_direct', 'equivalent_bridge', 'degraded_bridge',
  'platform_trim', 'business_decision', 'unknown'
];

/** 支持向（SDK 标记支持时应落入的方向） */
const SUPPORT_DIRECTION = new Set(['full_direct', 'reduced_direct']);
/** 不支持向（SDK 无标记时应落入的方向：无原生等价，需桥接/裁剪） */
const UNSUPPORT_DIRECTION = new Set(['equivalent_bridge', 'degraded_bridge', 'platform_trim']);

export function loadRules(rulesPath) {
  const path = rulesPath || join(SKILL_ROOT, 'rules', 'adaptation.json');
  const doc = JSON.parse(readFileSync(path, 'utf8'));
  if (!doc || !Array.isArray(doc.rules)) {
    throw new Error(`规则表非法（缺 rules 数组）: ${path}`);
  }
  for (const rule of doc.rules) {
    if (!BUCKETS.slice(0, 6).includes(rule.category)) {
      throw new Error(`规则表条目 category 非法: ${rule.module} -> ${rule.category}`);
    }
  }
  const rules = { meta: doc.meta || {}, byKey: new Map() };
  for (const rule of doc.rules) {
    rules.byKey.set(moduleSymbolKey(rule.module, rule.symbol ?? null), rule);
  }
  return rules;
}

/** 单平台条目在场性（报告占比统计的数据源探测） */
export function hasPlatformEntries(rules) {
  for (const rule of rules.byKey.values()) {
    if (rule.platform === 'android' || rule.platform === 'ios') return true;
  }
  return false;
}

export function moduleSymbolKey(module, symbol) {
  return symbol ? `${module}#${symbol}` : `${module}`;
}

/**
 * 规则匹配：符号级优先 → 模块级兜底（两级匹配）
 * @returns {rule|null}
 */
export function matchRule(rules, module, symbol) {
  if (symbol) {
    const exact = rules.byKey.get(moduleSymbolKey(module, symbol));
    if (exact) return exact;
  }
  return rules.byKey.get(moduleSymbolKey(module, null)) || null;
}

/**
 * 归一接口身份（聚合键）
 */
export function interfaceKey(item) {
  return `${item.source}|${item.module}|${item.symbol}`;
}

/**
 * 双源交叉判定（纯函数， 信号三分矩阵）
 *
 * @param {Array} inventory - [{source:'ohos'|'hms'|'ndk'|'unknown', module, symbol, file, line}]
 *   （未展开 @kit.* 条目 source=unknown——归属不可判定，判定走 classifyOhos 的 @kit 显式 unknown 分支）
 * @param {object} rules - loadRules() 产物
 * @param {Map|null} marks - MarkIndex：module -> {symbols: Map<symbol, boolean>, moduleMarked: boolean|null}；
 *                           null = 降级（SDK 未检出， 单源）
 * @returns {{adaptation: object, bucketsRef: string[]}} 七桶结果
 */
export function classify(inventory, rules, marks) {
 // 聚合
  const aggregated = new Map();
  for (const item of inventory) {
    const key = interfaceKey(item);
    let entry = aggregated.get(key);
    if (!entry) {
      entry = { source: item.source, module: item.module, symbol: item.symbol, occurrences: 0, locations: new Set() };
      aggregated.set(key, entry);
    }
    entry.occurrences += 1;
    entry.locations.add(`${item.file}:${item.line}`);
  }

  const adaptation = emptyAdaptation();

  for (const entry of aggregated.values()) {
    const item = toAdaptationItem(entry);
    if (entry.source === 'hms') {
      classifyHms(item, rules);
      pushTo(adaptation, item);
      continue;
    }
    if (entry.source === 'ndk') {
      classifyNdk(item, rules);
      pushTo(adaptation, item);
      continue;
    }
    classifyOhos(item, rules, marks);
    pushTo(adaptation, item);
  }

  sortAdaptation(adaptation);
  return { adaptation, bucketsRef: BUCKETS };
}

function emptyAdaptation() {
  const adaptation = {};
  for (const bucket of BUCKETS) adaptation[bucket] = [];
  return adaptation;
}

function toAdaptationItem(entry) {
  return {
    source: entry.source,
    module: entry.module,
    symbol: entry.symbol,
    occurrences: entry.occurrences,
    locations: [...entry.locations].sort(),
    reason: '',
    advice: '',
    suggested_alternative: 'N/A'
  };
}

function pushTo(adaptation, item) {
 // 桶互斥自检：classify* 必须先写 bucket 字段
  if (!BUCKETS.includes(item.bucket)) {
    throw new Error(`桶互斥自检失败: ${item.module}#${item.symbol} 无合法 bucket`);
  }
  adaptation[item.bucket].push(item);
  delete item.bucket;
}

/** @hms.*：默认⑥业务决策 + 替代建议 */
function classifyHms(item, rules) {
  const rule = matchRule(rules, item.module, item.symbol);
  item.bucket = 'business_decision';
  item.reason = rule ? rule.reason : '接口来源为 @hms.*（闭源）：不走自动分类，默认业务决策';
  item.advice = rule ? rule.advice : '由开发者决策降级为 OH 开源替代或自行实现同等功能';
  item.suggested_alternative = rule
    ? (rule.suggested_alternative || '需开发者评估')
    : '需开发者评估';
}

/**
 * NDK C-API：规则表单源判定（design C-API 判定数据源固化：
 * SDK C-API 头文件无系统性跨平台标注，不可作机器源；sdk-marks.js 预留接入点）
 */
function classifyNdk(item, rules) {
 // 路径归一（清单演进）：全路径 miss 时按 basename 兜底
 // （如 libarkui_ios/include/plugin_utils.h → plugin_utils.h；docs 集成教程的带前缀形态）
  let rule = matchRule(rules, item.module, item.symbol);
  if (!rule) {
    const base = item.module.split('/').pop();
    if (base !== item.module) rule = matchRule(rules, base, item.symbol);
  }
  if (!rule) {
    item.bucket = 'unknown';
    item.reason = '判定依据未覆盖（C-API：规则表未覆盖该头文件/符号；SDK C-API 头文件暂无跨平台标记体系可作机器源）';
    item.advice = '人工确认：查证 ArkUI-X 对该 C-API 的支持性后补充规则表';
    item.suggested_alternative = '需自行选择平台原生替代';
    return;
  }
  item.bucket = rule.category;
  item.reason = `单源（规则表；C-API 判定源为规则表）: ${rule.reason}`;
  item.advice = rule.advice;
  // ：ndk 项替代建议兜底——非①桶（③④⑥/未决）'N/A' 渲染为空指引，统一兜底"需自行选择平台原生替代"；
  // ①full_direct 直连无替代语义，保 'N/A'（F4 报告/rewriter TODO 均消费 suggested_alternative）
  const alt = rule.suggested_alternative;
  if (rule.category === 'full_direct') {
    item.suggested_alternative = alt || 'N/A';
  } else {
    item.suggested_alternative = alt && alt !== 'N/A' ? alt : '需自行选择平台原生替代';
  }
}

/** @ohos.*：双源交叉矩阵（marks=null 走  单源） */
function classifyOhos(item, rules, marks) {
  if (item.module.startsWith('@kit.')) {
 // ：@kit 条目仅在未展开（降级模式/kit 未知/符号不可解析）时到达此处——显式不静默
 // ：华为闭源生态 kit（OH SDK kits 不含）类比 @hms.* 归⑥业务决策（未知 kit 归属不可判定但闭源生态为常态）；
 // source=unknown 如实透传（统计口径不虚计 ohos/hms）
    const kitName = item.module.replace('@kit.', '');
    const rule = matchRule(rules, item.module, item.symbol);
    if (rule) {
      item.bucket = rule.category;
      item.reason = `单源（规则表；闭源 kit 策展条目）: ${rule.reason}`;
      item.advice = rule.advice;
      item.suggested_alternative = rule.suggested_alternative || 'N/A';
      return;
    }
    item.bucket = 'business_decision';
    item.reason = `@kit.${kitName} 未展开（${marks === null ? '降级模式无 SDK kits 映射源，可能为闭源/专有生态包' : 'OH SDK kits 不含此 kit——华为闭源生态 kit（HMS 系）'}）； 归类：类比 @hms.* 走业务决策`;
    item.advice = '按华为闭源生态处理：评估 HMS Core 跨平台 SDK 接入（部分 Kit 有独立跨平台版本），或降级为平台原生桥接（Android Google 服务 / iOS 系统框架——对应 F4 编排⑥决策选项「降级为平台原生桥接」，移桶④由 F3 生成六件套）';
    item.suggested_alternative = 'HMS Core 跨平台 SDK / 平台原生桥接';
    return;
  }
  const rule = matchRule(rules, item.module, item.symbol);
  const ruleSignal = rule
    ? (SUPPORT_DIRECTION.has(rule.category) ? 'support' : 'unsupport')
    : null;

  if (marks === null) {
 //  降级：规则表单源
    if (!rule) {
      item.bucket = 'unknown';
      item.reason = '判定依据未覆盖（SDK 未检出，单源模式下规则表亦未覆盖）';
      item.advice = '人工确认：补充规则表或提供 OpenHarmony SDK 目录';
    } else {
      item.bucket = rule.category;
      item.reason = `单源（规则表；SDK 未检出降级）: ${rule.reason}`;
      item.advice = rule.advice;
      item.suggested_alternative = rule.suggested_alternative || 'N/A';
    }
    return;
  }

  const mark = resolveMark(marks, item.module, item.symbol);
 // mark: 'marked' | 'unmarked' | 'absent'（absent=SDK 索引无该模块，无信号）
  const sdkSignal = mark === 'marked' ? 'support' : (mark === 'unmarked' ? 'unsupport' : null);

  if (ruleSignal && sdkSignal && ruleSignal !== sdkSignal) {
 // ：docs 实证条目（evidence=docs-verified）与 SDK 标记冲突时采规则表——
 // SDK @crossplatform 标记存在两向不全实情（vibrator：该标没标；window：标记过承诺而符号级实测极窄），
 // docs 逐 API 实证为强证据，双向优先
    if (rule.evidence === 'docs-verified') {
      item.bucket = rule.category;
      item.reason = `${sdkSignal === 'unsupport' ? '单源（规则表·docs 实证；SDK 无 @crossplatform 标记但 ArkUI-X docs 实证，标记不全情形）' : '单源（规则表·docs 实证；SDK 模块级标记存在但 docs 实证覆盖面更精确，采信规则表）'}: ${rule.reason}`;
      item.advice = rule.advice;
      item.suggested_alternative = rule.suggested_alternative || 'N/A';
      appendPlatformCaveat(item, rules, item.module);
      return;
    }
 //  双源冲突
    item.bucket = 'unknown';
    item.reason = `双源冲突：SDK 标记${mark === 'marked' ? '支持跨平台' : '无 @crossplatform 标记'}，规则表归 ${labelOf(rule.category)}（${rule.reason}）`;
    item.advice = '人工确认两源结论后更新规则表或 SDK 版本';
    return;
  }

  if (ruleSignal && sdkSignal && ruleSignal === sdkSignal) {
 // 双源一致：支持向采规则表细分；不支持向采规则表
    item.bucket = rule.category;
    item.reason = `双源一致（SDK ${mark === 'marked' ? '支持标记' : '无标记'} + 规则表）: ${rule.reason}`;
    item.advice = rule.advice;
    item.suggested_alternative = rule.suggested_alternative || 'N/A';
    appendPlatformCaveat(item, rules, item.module);
    return;
  }

  if (sdkSignal === 'support' && !ruleSignal) {
    item.bucket = 'full_direct';
    item.reason = '单源（SDK）：@crossplatform 标记支持跨平台，规则表未覆盖';
    item.advice = '可直接使用；建议回归验证（规则表未覆盖细节）';
 //  残留：SDK 单源路径同样联动单平台警示——同模块存在符号级 platform 条目时避免无保留承诺
    appendPlatformCaveat(item, rules, item.module);
    return;
  }

  if (sdkSignal === 'unsupport' && !ruleSignal) {
    item.bucket = 'unknown';
    item.reason = '判定依据未覆盖（SDK 无标记且规则表未覆盖）';
    item.advice = '人工确认：查证 ArkUI-X 支持性后补充规则表';
    return;
  }

  if (!sdkSignal && ruleSignal) {
    item.bucket = rule.category;
    item.reason = `单源（规则表；SDK 索引无该模块）: ${rule.reason}`;
    item.advice = rule.advice;
    item.suggested_alternative = rule.suggested_alternative || 'N/A';
    appendPlatformCaveat(item, rules, item.module);
    return;
  }

 // 双源皆无信号
  item.bucket = 'unknown';
  item.reason = '判定依据未覆盖（SDK 索引无该模块且规则表未覆盖）';
  item.advice = '人工确认：核对模块名与 SDK 版本后补充规则表';
}

/** ：命名空间/模块级引用命中时，若同模块存在符号级 platform 条目 → reason 附单平台警示 */
function appendPlatformCaveat(item, rules, module) {
  if (!rules || !rules.byKey) return;
  for (const [key, rule] of rules.byKey) {
    if (key.startsWith(`${module}#`) && (rule.platform === 'android' || rule.platform === 'ios')) {
      item.reason += `（注意：本模块含仅 ${rule.platform} 平台的符号级条目，命名空间整体引用对 ${rule.platform === 'android' ? 'iOS' : 'Android'} 侧可能过度承诺）`;
      return;
    }
  }
}

function resolveMark(marks, module, symbol) {
  const entry = marks.get(module);
  if (!entry) return 'absent';
  if (entry.moduleMarked === true) return 'marked';
  if (entry.moduleMarked === false && entry.symbols.size === 0) return 'unmarked';
  if (symbol && entry.symbols.has(symbol)) {
    return entry.symbols.get(symbol) ? 'marked' : 'unmarked';
  }
 // 符号未在标记索引中且模块未整标：视为无标记（保守）
  return 'unmarked';
}

const LABELS = {
  full_direct: '①完整直用', reduced_direct: '②有损直用', equivalent_bridge: '③等价桥接',
  degraded_bridge: '④降级桥接', platform_trim: '⑤平台裁剪', business_decision: '⑥业务决策'
};
function labelOf(category) {
  return LABELS[category] || category;
}

function sortAdaptation(adaptation) {
  for (const bucket of BUCKETS) {
    adaptation[bucket].sort((a, b) =>
      (a.module + '#' + a.symbol).localeCompare(b.module + '#' + b.symbol));
  }
}
