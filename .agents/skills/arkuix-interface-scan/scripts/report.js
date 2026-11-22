import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { matchRule, hasPlatformEntries } from './classify.js';

const SKILL_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

const BUCKET_TITLES = {
  full_direct: '① 完整直用（full_direct）',
  reduced_direct: '② 有损直用（reduced_direct）',
  equivalent_bridge: '③ 等价桥接（equivalent_bridge）— 将由 F3 生成桥接',
  degraded_bridge: '④ 降级桥接（degraded_bridge）— 将由 F3 生成桥接',
  platform_trim: '⑤ 平台裁剪（platform_trim）',
  business_decision: '⑥ 业务决策（business_decision）',
  unknown: 'unknown — 待人工确认'
};

const BUCKET_ORDER = [
  'full_direct', 'reduced_direct', 'equivalent_bridge', 'degraded_bridge',
  'platform_trim', 'business_decision', 'unknown'
];

const SIX_BUCKETS = BUCKET_ORDER.slice(0, 6);

/** ScanReport JSON 渲染（契约产物；键序固定保证确定性 ） */
export function renderJson(scanReport) {
  const ordered = orderReport(scanReport);
  return JSON.stringify(ordered, null, 2) + '\n';
}

function orderReport(report) {
  const out = {
    schema_version: report.schema_version,
    project_model: report.project_model
  };
  if (report.sdk !== undefined) out.sdk = report.sdk;
  out.inventory = report.inventory.map(orderInventoryItem);
  out.adaptation = {};
  for (const bucket of BUCKET_ORDER) {
    out.adaptation[bucket] = (report.adaptation[bucket] || []).map(orderAdaptationItem);
  }
  return out;
}

function orderInventoryItem(item) {
  return { source: item.source, module: item.module, symbol: item.symbol, file: item.file, line: item.line };
}

function orderAdaptationItem(item) {
  return {
    source: item.source,
    module: item.module,
    symbol: item.symbol,
    occurrences: item.occurrences,
    locations: [...item.locations],
    reason: item.reason,
    advice: item.advice,
    suggested_alternative: item.suggested_alternative
  };
}

/**
 * 单平台支持接口占比（design 固化公式，报告渲染时实时计算）：
 *   分子 = 已判定 @ohos.* 条目中命中规则表符号级 platform 标注的接口数
 *   分母 = adaptation 六分类中 source=ohos 的条目数（不含 unknown、不含 @hms.*）
 * 规则表无任何单平台条目时显示 0% 并注明。
 */
export function computePlatformRatio(scanReport, rules) {
  let denominator = 0;
  let numerator = 0;
  for (const bucket of SIX_BUCKETS) {
    for (const item of scanReport.adaptation[bucket] || []) {
      if (item.source !== 'ohos') continue;
      denominator += 1;
      if (rules) {
        const rule = rules.byKey ? rules.byKey.get(`${item.module}#${item.symbol}`) : matchRule(rules, item.module, item.symbol);
        if (rule && (rule.platform === 'android' || rule.platform === 'ios')) numerator += 1;
      }
    }
  }
  return { numerator, denominator, known: rules ? hasPlatformEntries(rules) : false };
}

/** Markdown 迁移建议报告（含平台标注；来源列/单平台占比/动态加载提示） */
export function renderMarkdown(scanReport, options = {}) {
  const template = readFileSync(join(SKILL_ROOT, 'templates', 'report.md.tpl'), 'utf8');
  const sections = [];

  if (options.degraded) {
    sections.push('> ⚠️ **SDK 未检出，单源判定**：本次判定仅基于规则表；建议提供 OpenHarmony SDK 目录后重扫以获得双源交叉结论。');
  }
  if (scanReport.project_model === 'fa') {
    sections.push('> **FA 模型不支持，仅支持 Stage 模型**：未产出适配分类。');
  } else if (scanReport.project_model === 'unknown') {
    sections.push('> **工程模型无法判定**：未产出适配分类（缺 Stage/FA 工程特征）。');
  }
  if (options.dynamicHints && options.dynamicHints.length > 0) {
    const hints = options.dynamicHints
      .map((h) => `- ${h.file}:${h.line}（${h.kind === 'dlopen' ? 'dlopen' : 'dynamic import'}）`)
      .join('\n');
    sections.push(`> ⚠️ **存在不可静态解析的动态加载（dynamic import / dlopen）**：以下位置为变量/拼接形式，未计入接口清单，请人工核查：\n${hints}`);
  }

  for (const bucket of BUCKET_ORDER) {
    const items = scanReport.adaptation[bucket] || [];
    if (items.length === 0) continue;
    const lines = [`### ${BUCKET_TITLES[bucket]}`, '',
      '| 接口 | 来源 | 引用次数 | 位置 | 分类理由 | 迁移建议 | 替代建议 |',
      '|------|------|----------|------|----------|----------|----------|'];
    for (const item of items) {
      lines.push(`| ${item.module} → ${item.symbol} | ${item.source} | ${item.occurrences} | ${item.locations.join('<br>')} | ${escapeCell(item.reason)} | ${escapeCell(item.advice)} | ${escapeCell(item.suggested_alternative)} |`);
    }
    sections.push(lines.join('\n'));
  }

  if (sections.length === 0) {
    sections.push('未发现 @ohos.*/@hms.* 接口引用。');
  }

 // 单平台占比统计节（渲染时实时计算）
  const ratio = computePlatformRatio(scanReport, options.rules);
  let ratioLine;
  if (scanReport.project_model === 'stage') {
    if (!ratio.known) {
      ratioLine = '单平台支持接口占比：0%（规则表暂无单平台条目）';
    } else if (ratio.denominator === 0) {
      ratioLine = '单平台支持接口占比：0%（无已判定 @ohos.* 条目）';
    } else {
      const pct = Math.round((ratio.numerator / ratio.denominator) * 100);
      ratioLine = `单平台支持接口占比：${ratio.numerator}/${ratio.denominator}（${pct}%）`;
    }
  } else {
    ratioLine = '单平台支持接口占比：N/A（未产出适配分类）';
  }

  const sdkLine = scanReport.sdk
    ? `${scanReport.sdk.path}（版本 ${scanReport.sdk.version}，${scanReport.sdk.confirmed ? `已确认（${scanReport.sdk.origin || 'explicit'}）` : `⚠ 未经确认（${scanReport.sdk.origin || 'unknown'}）——请核对判定源`}）`
    : (options.degraded ? '未检出（单源判定）' : '未使用');

  return template
    .replace(/{{PROJECT_MODEL}}/g, scanReport.project_model)
    .replace(/{{SDK_LINE}}/g, sdkLine)
    .replace(/{{INVENTORY_COUNT}}/g, String(scanReport.inventory.length))
    .replace(/{{PLATFORM_RATIO}}/g, ratioLine)
    .replace(/{{SECTIONS}}/g, sections.join('\n\n'));
}

function escapeCell(text) {
  return String(text).replace(/\|/g, '\\|').replace(/\n/g, ' ');
}
