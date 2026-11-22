#!/usr/bin/env node
'use strict';

/**
 * 从 CodeLinter HTML 报告中提取 fixable 信息
 *
 * 背景：
 *   CLI 的 -f json 输出仅含 5 个核心字段（line/column/severity/message/rule），
 *   不含 fixable 标识。-f html 报告内嵌了完整的 defect 对象（含 fixable/fixKey/
 *   ruleDocPath/engineName 等），是唯一能判断规则是否支持 QuickFix 的 CLI 数据源。
 *
 *   --fix 模式的 JSON 输出在当前 DevEco 版本不可靠（返回空数组但文件未被修改），
 *   因此不能通过 --fix 对比法判断可修复项，必须从 HTML 提取 fixable 字段。
 *
 * HTML 报告结构：
 *   报告末尾有一段 JS 赋值，形如 `Hc=[{"filePath":"...","defects":[{...}]}]`，
 *   其中每个 defect 对象包含字段：
 *     - description: 告警描述
 *     - severity: 数字（2=error, 1=warn, 3=suggestion）
 *     - ruleId: 规则 ID
 *     - fixable: 布尔值，是否支持 QuickFix
 *     - fixKey: 修复键
 *     - reportLine / reportColumn: 行列号
 *     - engineName / ruleDocPath / mergeKey 等
 *
 * 用法：
 *   node extract-fixable.js <result.html>                          // 输出可修复规则列表（JSON 数组）
 *   node extract-fixable.js <result.html> --format full            // 输出完整 defect 列表（含 fixable 字段）
 *   node extract-fixable.js <result.html> --format summary         // 输出汇总（可修复/不可修复计数）
 *   node extract-fixable.js <result.html> -o fixable-rules.json    // 写入文件
 */

const fs = require('fs');

const SEVERITY_NAME = { 2: 'error', 1: 'warn', 3: 'suggestion' };

/**
 * 从 HTML 内容中提取 defect 数组
 * 定位 `[{"filePath":` 开始的 JSON 数组，按括号深度匹配到对应闭合 ]
 * @param {string} html
 * @returns {Array|null}
 */
function extractDefects(html) {
  const marker = '[{"filePath"';
  const start = html.indexOf(marker);
  if (start < 0) return null;

  let depth = 0;
  let end = -1;
  let inString = false;
  let escape = false;
  for (let i = start; i < html.length; i++) {
    const ch = html[i];
    if (escape) { escape = false; continue; }
    if (ch === '\\') { escape = true; continue; }
    if (ch === '"') { inString = !inString; continue; }
    if (inString) continue;
    if (ch === '[') depth++;
    else if (ch === ']') {
      depth--;
      if (depth === 0) { end = i; break; }
    }
  }
  if (end < 0) return null;

  const jsonStr = html.slice(start, end + 1);
  try {
    return JSON.parse(jsonStr);
  } catch (e) {
    throw new Error('解析 HTML 内嵌 JSON 失败: ' + e.message);
  }
}

/**
 * 从 defect 数组中提取 fixable 信息
 * @param {Array} files - extractDefects 的返回值
 * @returns {{fixableRules: string[], fixableDefects: Array, nonFixableDefects: Array, summary: Object}}
 */
function analyzeFixable(files) {
  const fixableRules = new Set();
  const fixableDefects = [];
  const nonFixableDefects = [];

  for (const file of files) {
    for (const d of (file.defects || [])) {
      const item = {
        filePath: file.filePath,
        line: d.reportLine,
        column: d.reportColumn,
        severity: SEVERITY_NAME[d.severity] || String(d.severity),
        rule: d.ruleId,
        message: d.description,
        fixable: !!d.fixable,
        fixKey: d.fixKey || null,
      };
      if (d.fixable) {
        fixableRules.add(d.ruleId);
        fixableDefects.push(item);
      } else {
        nonFixableDefects.push(item);
      }
    }
  }

  return {
    fixableRules: Array.from(fixableRules),
    fixableDefects,
    nonFixableDefects,
    summary: {
      total: fixableDefects.length + nonFixableDefects.length,
      fixable: fixableDefects.length,
      nonFixable: nonFixableDefects.length,
      fixableRules: Array.from(fixableRules),
    },
  };
}

/**
 * 从 HTML 文件路径读取并提取 fixable 信息
 * @param {string} htmlPath
 * @returns {Object} analyzeFixable 的返回值
 */
function fromFile(htmlPath) {
  const html = fs.readFileSync(htmlPath, 'utf-8');
  const files = extractDefects(html);
  if (!files) {
    throw new Error('HTML 报告中未找到 defect 数据（可能为空报告或格式不匹配）');
  }
  return analyzeFixable(files);
}

// CLI 入口
if (require.main === module) {
  const args = process.argv.slice(2);
  let format = 'rules';
  let inputFile = null;
  let outputFile = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--format' && i + 1 < args.length) {
      format = args[i + 1];
      i++;
    } else if ((args[i] === '-o' || args[i] === '--output') && i + 1 < args.length) {
      outputFile = args[i + 1];
      i++;
    } else if (args[i] === '-h' || args[i] === '--help') {
      console.log('用法: node extract-fixable.js <result.html> [--format rules|full|summary] [-o <output>]');
      console.log('');
      console.log('选项:');
      console.log('  <result.html>          HTML 报告文件路径');
      console.log('  --format <type>        输出格式：rules(默认,可修复规则ID数组) / full(完整defect) / summary(汇总)');
      console.log('  -o, --output <file>    写入文件（默认输出到 stdout）');
      console.log('  -h, --help             显示帮助');
      process.exit(0);
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  if (!inputFile) {
    console.error('错误: 请指定 HTML 报告文件路径');
    process.exit(1);
  }

  try {
    const result = fromFile(inputFile);
    let output;
    switch (format) {
      case 'full':
        output = JSON.stringify({
          fixableDefects: result.fixableDefects,
          nonFixableDefects: result.nonFixableDefects,
          summary: result.summary,
        }, null, 2);
        break;
      case 'summary':
        const s = result.summary;
        output = [
          '🔧 fixable 提取结果',
          '═'.repeat(30),
          '总告警数: ' + s.total,
          '✅ 可自动修复: ' + s.fixable + ' 条',
          '🔧 需手动处理: ' + s.nonFixable + ' 条',
          '',
        ];
        if (s.fixableRules.length > 0) {
          output.push('可修复规则:');
          for (const r of s.fixableRules) output.push('  ✅ ' + r);
        }
        output = output.join('\n');
        break;
      case 'rules':
      default:
        output = JSON.stringify(result.fixableRules, null, 2);
        break;
    }

    if (outputFile) {
      fs.writeFileSync(outputFile, output);
      console.log('已写入 ' + outputFile);
    } else {
      console.log(output);
    }
  } catch (e) {
    console.error('提取失败: ' + e.message);
    process.exit(1);
  }
}

module.exports = { extractDefects, analyzeFixable, fromFile };
