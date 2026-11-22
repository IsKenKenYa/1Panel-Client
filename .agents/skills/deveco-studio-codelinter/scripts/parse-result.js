#!/usr/bin/env node
'use strict';

/**
 * CodeLinter JSON 结果解析脚本
 *
 * 将 CodeLinter 的 JSON 输出解析为结构化格式，并生成可读报告。
 *
 * 用法：
 *   node parse-result.js <result.json>                      // 解析文件
 *   cat result.json | node parse-result.js                  // 从 stdin 读取
 *   node parse-result.js <result.json> --format json        // JSON 格式输出
 *   node parse-result.js <result.json> --format text        // 文本报告（默认）
 *   node parse-result.js <result.json> --format summary     // 仅汇总
 */

const fs = require('fs');
const path = require('path');

const SEVERITY_ORDER = { error: 0, warn: 1, suggestion: 2 };
const SEVERITY_LABEL = {
  error: '错误',
  warn: '警告',
  suggestion: '建议',
};
const SEVERITY_ICON = {
  error: '🔴',
  warn: '🟡',
  suggestion: '🔵',
};

/**
 * 解析 CodeLinter JSON 输出
 * @param {string|Array|Object} raw - JSON 字符串或已解析对象
 * @returns {{files: Array, messages: Array, summary: Object}}
 */
function parse(raw) {
  let data;
  if (typeof raw === 'string') {
    data = JSON.parse(raw);
  } else {
    data = raw;
  }

  // 统一为数组格式
  if (!Array.isArray(data)) {
    data = [data];
  }

  const files = [];
  const messages = [];
  const summary = {
    total: 0,
    error: 0,
    warn: 0,
    suggestion: 0,
    byRule: {},
    byFile: {},
  };

  for (const fileEntry of data) {
    const filePath = fileEntry.filePath || fileEntry.file || fileEntry.filename || '(unknown)';
    const fileMessages = fileEntry.messages || fileEntry.warnings || [];

    if (fileMessages.length === 0) continue;

    files.push({
      filePath,
      messageCount: fileMessages.length,
    });

    summary.byFile[filePath] = { error: 0, warn: 0, suggestion: 0 };

    for (const msg of fileMessages) {
      const severity = msg.severity || msg.level || 'warn';
      const rule = msg.rule || msg.ruleId || '(no-rule)';
      const line = msg.line || 0;
      const column = msg.column || 0;
      const message = msg.message || msg.description || '';

      const parsed = {
        filePath,
        line,
        column,
        severity,
        rule,
        message,
      };

      messages.push(parsed);

      summary.total++;
      if (summary[severity] !== undefined) {
        summary[severity]++;
        summary.byFile[filePath][severity]++;
      }
      summary.byRule[rule] = (summary.byRule[rule] || 0) + 1;
    }
  }

  // 按严重程度排序
  messages.sort((a, b) => {
    const sevDiff = (SEVERITY_ORDER[a.severity] ?? 99) - (SEVERITY_ORDER[b.severity] ?? 99);
    if (sevDiff !== 0) return sevDiff;
    if (a.filePath !== b.filePath) return a.filePath.localeCompare(b.filePath);
    return (a.line || 0) - (b.line || 0);
  });

  return { files, messages, summary };
}

/**
 * 生成文本格式报告
 * @param {{files: Array, messages: Array, summary: Object}} parsed
 * @returns {string}
 */
function formatText(parsed) {
  const { summary, messages } = parsed;
  const lines = [];

  lines.push('📊 CodeLinter 检查报告');
  lines.push('━'.repeat(30));
  lines.push(`🔴 错误：${summary.error} 个`);
  lines.push(`🟡 警告：${summary.warn} 个`);
  lines.push(`🔵 建议：${summary.suggestion} 个`);
  lines.push(`总计：${summary.total} 个问题`);
  lines.push('');

  if (messages.length === 0) {
    lines.push('✅ 无问题');
    return lines.join('\n');
  }

  // 按文件分组
  let currentFile = null;
  for (const msg of messages) {
    if (msg.filePath !== currentFile) {
      currentFile = msg.filePath;
      const relPath = tryRelativePath(msg.filePath);
      lines.push('');
      lines.push(`📁 ${relPath}`);
    }

    const icon = SEVERITY_ICON[msg.severity] || '⚪';
    const label = SEVERITY_LABEL[msg.severity] || msg.severity;
    lines.push(`  ${icon} 第${msg.line}行:${msg.column}列  ${msg.rule}`);
    lines.push(`     ${msg.message}`);
  }

  // 按规则统计
  const topRules = Object.entries(summary.byRule)
    .sort((a, b) => b[1] - a[1])
    .slice(0, 10);

  if (topRules.length > 0) {
    lines.push('');
    lines.push('📋 高频规则 TOP 10');
    lines.push('─'.repeat(30));
    for (const [rule, count] of topRules) {
      lines.push(`  ${rule}: ${count} 次`);
    }
  }

  return lines.join('\n');
}

/**
 * 生成汇总报告
 * @param {{summary: Object}} parsed
 * @returns {string}
 */
function formatSummary(parsed) {
  const { summary } = parsed;
  const lines = [];

  lines.push('📊 CodeLinter 汇总');
  lines.push('━'.repeat(20));
  lines.push(`🔴 错误：${summary.error}`);
  lines.push(`🟡 警告：${summary.warn}`);
  lines.push(`🔵 建议：${summary.suggestion}`);
  lines.push(`总计：${summary.total}`);
  lines.push(`涉及文件：${Object.keys(summary.byFile).length}`);

  return lines.join('\n');
}

/**
 * 尝试转为相对路径（仅用于显示）
 */
function tryRelativePath(filePath) {
  try {
    const cwd = process.cwd();
    const rel = path.relative(cwd, filePath);
    return rel.length < filePath.length ? rel : filePath;
  } catch (e) {
    return filePath;
  }
}

/**
 * 从文件或 stdin 读取
 */
function readInput(fileArg) {
  if (fileArg && fileArg !== '-' && fs.existsSync(fileArg)) {
    return fs.readFileSync(fileArg, 'utf-8');
  }
  // 从 stdin 读取
  return fs.readFileSync(0, 'utf-8');
}

// CLI 入口
if (require.main === module) {
  const args = process.argv.slice(2);
  let format = 'text';
  let inputFile = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--format' && i + 1 < args.length) {
      format = args[i + 1];
      i++;
    } else if (args[i] === '-h' || args[i] === '--help') {
      console.log('用法: node parse-result.js [file] [--format text|json|summary]');
      console.log('');
      console.log('选项:');
      console.log('  file             结果文件路径（不指定则从 stdin 读取）');
      console.log('  --format <type>  输出格式：text(默认) / json / summary');
      console.log('  -h, --help       显示帮助');
      process.exit(0);
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  try {
    const raw = readInput(inputFile);
    const parsed = parse(raw);

    switch (format) {
      case 'json':
        console.log(JSON.stringify(parsed, null, 2));
        break;
      case 'summary':
        console.log(formatSummary(parsed));
        break;
      case 'text':
      default:
        console.log(formatText(parsed));
        break;
    }
  } catch (e) {
    console.error('解析失败: ' + e.message);
    process.exit(1);
  }
}

module.exports = { parse, formatText, formatSummary, SEVERITY_ORDER, SEVERITY_ICON };
