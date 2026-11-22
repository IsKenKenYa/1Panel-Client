#!/usr/bin/env node
/**
 * extract-rules.js — 从 codescanner 部署目录提取规则清单
 *
 * 用法:
 *   node extract-rules.js <部署根目录> [--out <输出目录>]
 *
 * 部署根目录示例:
 *   D:/download/commandline-tools-windows-x64-26.0.1.272/command-line-tools/codescanner
 *
 * 输出（markdown 摘要，供人工核对 / 更新 references/rules/*.md）:
 *   stdout: C++ 规则表 + ArkTS 规则表
 *   --out 指定时写入 <out>/cpp-rules-summary.md 与 <out>/arkts-rules-summary.md
 *
 * 注意：本脚本只读规则 JSON，不写引擎配置。
 */
import { readFileSync, writeFileSync, mkdirSync } from 'node:fs';
import path from 'node:path';

function fail(msg) {
  process.stderr.write(`[extract-rules] ${msg}\n`);
  process.exit(2);
}

const [, , deployRoot, ...rest] = process.argv;
if (!deployRoot) {
  fail('usage: node extract-rules.js <codescanner 部署根目录> [--out <输出目录>]');
}
const outDir = rest.indexOf('--out') >= 0 ? rest[rest.indexOf('--out') + 1] : undefined;

function loadJson(rel) {
  const p = path.join(deployRoot, rel);
  try {
    return JSON.parse(readFileSync(p, 'utf-8'));
  } catch (err) {
    fail(`cannot read ${p}: ${err.message}`);
  }
}

// ── C++ 规则 ───────────────────────────────────────────────────────────────
const base = loadJson('cpp-agent/base_rules.json');
const cppLines = ['# C++ 规则摘要', ''];
for (const [group, rules] of Object.entries(base.rules?.cpp ?? {})) {
  cppLines.push(`## ${group}（${rules.length} 条）`, '');
  cppLines.push('| 规则 ID | severity | default | 检查器 | API 配对 |', '|---|---|---|---|---|');
  for (const r of rules) {
    const apis = (r.apis ?? []).join(' / ') || '-';
    cppLines.push(`| ${r.ruleId} | ${r.severity} | ${r.default} | ${r.checker} | ${apis} |`);
  }
  cppLines.push('');
}
const cppText = cppLines.join('\n');

// ── ArkTS 规则 ─────────────────────────────────────────────────────────────
const cfg = loadJson('homeflow/config/checkerConfig.json');
const arktsLines = ['# ArkTS 规则摘要', ''];
for (const [checkerName, checker] of Object.entries(cfg.checkers ?? {})) {
  const subs = checker.subRules ?? [];
  arktsLines.push(`## ${checkerName}（${subs.length} 条）`, '');
  arktsLines.push('| 规则 ID | severity | default | resourceType | 分配接口 | 释放接口 |', '|---|---|---|---|---|---|');
  for (const r of subs) {
    const alloc = (r.allocators ?? []).map((a) => `${a.module ?? ''}::${a.class ?? ''}.${a.api_name ?? ''}`).join(' / ') || '-';
    const rele = (r.releasers ?? []).map((a) => `${a.module ?? ''}::${a.class ?? ''}.${a.api_name ?? ''}`).join(' / ') || '-';
    arktsLines.push(`| ${r.ruleId} | ${r.severity} | ${r.default} | ${r.resourceType} | ${alloc} | ${rele} |`);
  }
  arktsLines.push('');
}
const arktsText = arktsLines.join('\n');

process.stdout.write(cppText + '\n'); process.stdout.write(arktsText + '\n');

if (outDir) {
  mkdirSync(outDir, { recursive: true });
  writeFileSync(path.join(outDir, 'cpp-rules-summary.md'), cppText, 'utf-8');
  writeFileSync(path.join(outDir, 'arkts-rules-summary.md'), arktsText, 'utf-8');
  process.stderr.write(`[extract-rules] written to ${outDir}\n`);
}
