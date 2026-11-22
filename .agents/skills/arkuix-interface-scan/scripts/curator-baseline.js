#!/usr/bin/env node
/**
 * curator-baseline —— 策展基线对账脚本（L0/L2 工单化）：
 * 三源交叉：OH SDK @ohos.* 模块标记 × arkui-x docs 收录面（含页内平台标注表）× 本仓规则表，
 * 产出分层工单：
 *   L0-可自动：docs 页含平台标注表 → 模块级 verdict + 符号级"不支持"清单（可直接产规则草稿）
 *   L1-已策展：规则表在场条目（标注机器播种/docs 实证状态）
 *   L2-长尾：无标记+无条目+无 docs 页（真扫落 unknown，按需经 F4 裁决；本清单即待策展工单池）
 * 用法：node scripts/curator-baseline.js --sdk-dir <ets/api> --docs-dir <reference/apis> [--json <输出>]
 */
import { readFileSync, readdirSync, writeFileSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const SKILL_ROOT = join(dirname(fileURLToPath(import.meta.url)), '..');

function parseArgs(argv) {
  const o = { sdkDir: null, docsDir: null, json: null };
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--sdk-dir') o.sdkDir = argv[++i];
    else if (argv[i] === '--docs-dir') o.docsDir = argv[++i];
    else if (argv[i] === '--json') o.json = argv[++i];
  }
  return o;
}

function docPageFor(mod, pages) {
  const name = mod.replace('@ohos.', '');
  const parts = name.split('.');
  const variants = [name, name.replace(/\./g, '-')];
  if (parts.length > 1) variants.push(parts[parts.length - 1], parts[parts.length - 1].toLowerCase(), parts[0], parts[0].toLowerCase());
  for (const v of variants) {
    for (const p of ['js-apis-', 'arkts-apis-']) {
      if (pages.has(`${p}${v}.md`)) return `${p}${v}.md`;
    }
  }
  return null;
}

/** 解析页内平台标注表（| 名称 | … | Android平台 | iOS平台 |）：返回符号级"不支持"清单与行数 */
function parsePlatformTable(docPath) {
  const text = readFileSync(docPath, 'utf8');
  const rows = text.split('\n').filter((l) => l.startsWith('|') && (l.includes('支持') || l.includes('不支持')));
  const gaps = [];
  for (const row of rows) {
    if (!row.includes('不支持')) continue;
    const cells = row.split('|').map((c) => c.trim());
    const name = cells[1] ?? '';
    const android = cells.some((c) => c === '不支持');
    if (!name || name === '名称' || name.startsWith('--')) continue;
    gaps.push({ symbol: name.replace(/[`*]/g, '').slice(0, 80), row: row.slice(0, 160) });
  }
  return { annotatedRows: rows.length, gaps };
}

function main() {
  const opts = parseArgs(process.argv.slice(2));
  const sdkDir = opts.sdkDir;
  const docsDir = opts.docsDir;
  if (!sdkDir || !docsDir) {
    console.error('用法: node scripts/curator-baseline.js --sdk-dir <ets/api> --docs-dir <reference/apis> [--json <输出>]');
    process.exit(2);
  }
  const rulesDoc = JSON.parse(readFileSync(join(SKILL_ROOT, 'rules', 'adaptation.json'), 'utf8'));
  const curated = new Map(rulesDoc.rules.map((r) => [r.module, r]));
  const pages = new Set(readdirSync(docsDir).filter((p) => p.endsWith('.md')));

  const report = { generatedFrom: { sdkDir, docsDir }, rulesVersion: rulesDoc.meta?.rules_version, tiers: { l0Auto: [], l1Curated: [], l2Longtail: [] }, stats: {} };
  const modules = readdirSync(sdkDir).filter((f) => f.startsWith('@ohos.') && f.endsWith('.d.ts'));
  for (const f of modules) {
    const mod = '@ohos.' + f.slice(6, -5);
    const marks = readFileSync(join(sdkDir, f), 'utf8').split('@crossplatform').length - 1;
    const page = docPageFor(mod, pages);
    const rule = curated.get(mod);
    let platform = null;
    if (page) {
      const { annotatedRows, gaps } = parsePlatformTable(join(docsDir, page));
      platform = { page, annotatedRows, gapCount: gaps.length, verdict: annotatedRows > 0 ? (gaps.length === 0 ? 'full_direct' : 'reduced_direct') : 'no-table', gaps: gaps.slice(0, 30) };
    }
    const entry = { module: mod, sdkMarks: marks, docsPage: page, platform, rule: rule ? { category: rule.category, docsVerified: rule.evidence === 'docs-verified' } : null };
    if (rule) report.tiers.l1Curated.push(entry);
    else if (page) report.tiers.l0Auto.push(entry);
    else report.tiers.l2Longtail.push(entry);
  }
  report.stats = {
    modules: modules.length,
    curated: report.tiers.l1Curated.length,
    docsInUncurated: report.tiers.l0Auto.length,
    docsLongtail: report.tiers.l2Longtail.length,
    machineSeededFullDirectNeedsVerify: report.tiers.l1Curated.filter((e) => e.rule.category === 'full_direct' && !e.rule.docsVerified).length,
  };
  const out = opts.json ?? join(SKILL_ROOT, 'benchmark', 'curator-baseline-report.json');
  writeFileSync(out, JSON.stringify(report, null, 2));
  console.log(`对账完成：模块 ${report.stats.modules} | 已策展 ${report.stats.curated} | docs在场未策展(L0可自动) ${report.stats.docsInUncurated} | 长尾工单池(L2) ${report.stats.docsLongtail} | 机器①待实证 ${report.stats.machineSeededFullDirectNeedsVerify}`);
  console.log(`报告: ${out}`);
}

main();
