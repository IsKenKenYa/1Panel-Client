#!/usr/bin/env node
'use strict';

/**
 * CodeLinter 结果分析脚本
 *
 * 在 parse-result.js 的基础上进行深度分析：
 * - 按规则集分组统计
 * - 生成修复优先级建议
 * - 输出 Markdown 格式分析报告
 *
 * 关于可自动修复（QuickFix）的判断：
 *   本脚本不再维护静态 AUTOFIXABLE_RULES 名单。CLI 的 -f json 输出不含 fixable 字段，
 *   静态名单无法覆盖 DevEco 版本差异和 .ets 文件的实际 QuickFix 行为。
 *   可自动修复项由 SKILL.md Step 5a 的 HTML 报告提取法（extract-fixable.js）探测，结果通过 fixableRules
 *   参数传入本脚本，或通过 --fixable-rules 命令行参数注入。
 *
 * 用法：
 *   node analyze-results.js <result.json>                                          // 文本报告
 *   node analyze-results.js <result.json> --format markdown                        // Markdown 报告
 *   node analyze-results.js <result.json> --format json                            // JSON 结构化
 *   node analyze-results.js <result.json> --fixable-rules <rules.json>             // 注入可修复规则
 *   cat result.json | node analyze-results.js                                      // 从 stdin 读取
 */

const { parse } = require('./parse-result');
const fs = require('fs');

// 规则集前缀映射（与 shipped ruleSet.json 中的实际前缀一致）
const RULESET_PREFIXES = [
  '@typescript-eslint',
  '@hw-stylistic',
  '@performance',
  '@security',
  '@correctness',
  '@cross-device-app-dev',
  '@compatibility',
  '@previewer',
  '@private',
];

/**
 * 根据规则 ID 推断规则集
 * @param {string} ruleId
 * @returns {string}
 */
function inferRuleset(ruleId) {
  for (const prefix of RULESET_PREFIXES) {
    if (ruleId.startsWith(prefix + '/') || ruleId.startsWith(prefix + '-')) {
      return prefix;
    }
  }
  return 'other';
}

/**
 * 创建可自动修复规则判定函数
 *
 * 可修复规则集合应由 SKILL.md Step 5a 的 HTML 报告提取法（extract-fixable.js）探测得到，
 * 通过 fixableRules 参数传入。未传入时返回 () => false，即不判定任何规则为可修复，
 * 此时 priority.autofix 恒为空，所有告警按 critical/manual 分类。
 *
 * @param {string[]|Set<string>|null} fixableRules - 可自动修复的规则 ID 集合
 * @returns {(ruleId: string) => boolean}
 */
function makeFixableChecker(fixableRules) {
  if (!fixableRules) {
    return () => false;
  }
  const set = fixableRules instanceof Set ? fixableRules : new Set(fixableRules);
  return (ruleId) => set.has(ruleId);
}

/**
 * 深度分析
 * @param {string|Array|Object} raw - JSON 字符串或已解析对象
 * @param {string[]|Set<string>|null} [fixableRules] - 可自动修复的规则 ID 集合
 *   来自 Step 5a HTML 报告提取法（extract-fixable.js）探测结果。未传入时不判定任何规则为可修复。
 * @returns {Object} 分析结果
 */
function analyze(raw, fixableRules) {
  const parsed = parse(raw);
  const { messages, summary } = parsed;
  const isFixable = makeFixableChecker(fixableRules);

  const analysis = {
    summary,
    byRuleset: {},
    byFile: [],
    byRule: {},
    autofixable: {
      count: 0,
      rules: [],
      messages: [],
    },
    priority: {
      critical: [],    // error 且不可自动修复
      autofix: [],     // 可自动修复的
      manual: [],      // warn/suggestion 需手动处理
    },
  };

  // 初始化规则集统计
  for (const prefix of RULESET_PREFIXES) {
    analysis.byRuleset[prefix] = { error: 0, warn: 0, suggestion: 0, total: 0, rules: {} };
  }
  analysis.byRuleset.other = { error: 0, warn: 0, suggestion: 0, total: 0, rules: {} };

  // 按文件汇总
  const fileMap = {};
  for (const msg of messages) {
    const rs = inferRuleset(msg.rule);
    const rsStat = analysis.byRuleset[rs] || (analysis.byRuleset[rs] = { error: 0, warn: 0, suggestion: 0, total: 0, rules: {} });

    rsStat.total++;
    if (rsStat[msg.severity] !== undefined) rsStat[msg.severity]++;
    rsStat.rules[msg.rule] = (rsStat.rules[msg.rule] || 0) + 1;

    // 按规则汇总
    if (!analysis.byRule[msg.rule]) {
      analysis.byRule[msg.rule] = {
        count: 0,
        severity: msg.severity,
        ruleset: rs,
        autofixable: isFixable(msg.rule),
        sampleFiles: [],
      };
    }
    analysis.byRule[msg.rule].count++;

    // 收集样例文件（最多5个）
    if (analysis.byRule[msg.rule].sampleFiles.length < 5) {
      const sample = `${msg.filePath}:${msg.line}`;
      if (!analysis.byRule[msg.rule].sampleFiles.includes(sample)) {
        analysis.byRule[msg.rule].sampleFiles.push(sample);
      }
    }

    // 按文件汇总
    if (!fileMap[msg.filePath]) {
      fileMap[msg.filePath] = { filePath: msg.filePath, error: 0, warn: 0, suggestion: 0, total: 0, rules: new Set() };
    }
    fileMap[msg.filePath].total++;
    if (fileMap[msg.filePath][msg.severity] !== undefined) fileMap[msg.filePath][msg.severity]++;
    fileMap[msg.filePath].rules.add(msg.rule);

    // 可自动修复
    if (isFixable(msg.rule)) {
      analysis.autofixable.count++;
      if (!analysis.autofixable.rules.includes(msg.rule)) {
        analysis.autofixable.rules.push(msg.rule);
      }
      analysis.autofixable.messages.push(msg);
      analysis.priority.autofix.push(msg);
    } else if (msg.severity === 'error') {
      analysis.priority.critical.push(msg);
    } else {
      analysis.priority.manual.push(msg);
    }
  }

  // 文件列表转数组并排序
  analysis.byFile = Object.values(fileMap).map((f) => ({
    ...f,
    rules: Array.from(f.rules),
  }));
  analysis.byFile.sort((a, b) => {
    const ae = a.error || 0;
    const be = b.error || 0;
    if (ae !== be) return be - ae;
    return b.total - a.total;
  });

  return analysis;
}

/**
 * 生成 Markdown 分析报告
 * @param {Object} analysis
 * @returns {string}
 */
function formatMarkdown(analysis) {
  const lines = [];
  const s = analysis.summary;

  lines.push('# CodeLinter 分析报告');
  lines.push('');

  // 汇总
  lines.push('## 汇总');
  lines.push('');
  lines.push(`| 级别 | 数量 |`);
  lines.push(`|------|------|`);
  lines.push(`| 🔴 错误 | ${s.error} |`);
  lines.push(`| 🟡 警告 | ${s.warn} |`);
  lines.push(`| 🔵 建议 | ${s.suggestion} |`);
  lines.push(`| **总计** | **${s.total}** |`);
  lines.push(`| 涉及文件 | ${Object.keys(s.byFile).length} |`);
  lines.push('');

  // 修复优先级
  lines.push('## 修复优先级');
  lines.push('');
  lines.push(`1. **紧急手动修复**（error 级别，不可自动修复）：${analysis.priority.critical.length} 个`);
  lines.push(`2. **自动修复**（支持 --fix）：${analysis.priority.autofix.length} 个`);
  lines.push(`3. **手动处理**（warn/suggestion）：${analysis.priority.manual.length} 个`);
  lines.push('');

  if (analysis.autofixable.count > 0) {
    lines.push('### 可自动修复的规则');
    lines.push('');
    for (const rule of analysis.autofixable.rules) {
      const r = analysis.byRule[rule];
      if (r) {
        lines.push(`- \`${rule}\` — ${r.count} 处`);
      }
    }
    lines.push('');
    lines.push('> 以上规则经 HTML 报告提取法（extract-fixable.js）探测确认可自动修复，运行 `node <CODELINTER> --fix /path/to/project` 修复');
    lines.push('');
  }

  // 按规则集统计
  lines.push('## 按规则集分布');
  lines.push('');
  lines.push('| 规则集 | error | warn | suggestion | 总计 |');
  lines.push('|--------|-------|------|------------|------|');
  for (const rs of RULESET_PREFIXES) {
    const stat = analysis.byRuleset[rs];
    if (stat && stat.total > 0) {
      lines.push(`| ${rs} | ${stat.error} | ${stat.warn} | ${stat.suggestion} | ${stat.total} |`);
    }
  }
  const otherStat = analysis.byRuleset.other;
  if (otherStat && otherStat.total > 0) {
    lines.push(`| other | ${otherStat.error} | ${otherStat.warn} | ${otherStat.suggestion} | ${otherStat.total} |`);
  }
  lines.push('');

  // 热点文件 TOP 10
  const topFiles = analysis.byFile.slice(0, 10);
  if (topFiles.length > 0) {
    lines.push('## 热点文件 TOP 10');
    lines.push('');
    lines.push('| 文件 | error | warn | suggestion | 总计 |');
    lines.push('|------|-------|------|------------|------|');
    for (const f of topFiles) {
      const relPath = f.filePath.replace(/\\/g, '/');
      lines.push(`| ${relPath} | ${f.error || 0} | ${f.warn || 0} | ${f.suggestion || 0} | ${f.total} |`);
    }
    lines.push('');
  }

  // 高频规则 TOP 10
  const topRules = Object.entries(analysis.byRule)
    .sort((a, b) => b[1].count - a[1].count)
    .slice(0, 10);
  if (topRules.length > 0) {
    lines.push('## 高频规则 TOP 10');
    lines.push('');
    lines.push('| 规则 | 次数 | 级别 | 规则集 |');
    lines.push('|------|------|------|--------|');
    for (const [rule, info] of topRules) {
      lines.push(`| \`${rule}\` | ${info.count} | ${info.severity} | ${info.ruleset} |`);
    }
    lines.push('');
  }

  // 紧急修复列表
  if (analysis.priority.critical.length > 0) {
    lines.push('## 紧急修复列表（error 级别）');
    lines.push('');
    for (const msg of analysis.priority.critical.slice(0, 20)) {
      const relPath = msg.filePath.replace(/\\/g, '/');
      lines.push(`- **${relPath}:${msg.line}** — \`${msg.rule}\``);
      lines.push(`  - ${msg.message}`);
    }
    if (analysis.priority.critical.length > 20) {
      lines.push(`- ...还有 ${analysis.priority.critical.length - 20} 个`);
    }
    lines.push('');
  }

  return lines.join('\n');
}

/**
 * 生成文本分析报告
 * @param {Object} analysis
 * @returns {string}
 */
function formatText(analysis) {
  const lines = [];
  const s = analysis.summary;

  lines.push('📊 CodeLinter 深度分析');
  lines.push('═'.repeat(40));
  lines.push('');
  lines.push('【汇总】');
  lines.push(`  🔴 错误: ${s.error}  🟡 警告: ${s.warn}  🔵 建议: ${s.suggestion}`);
  lines.push(`  总计: ${s.total}  涉及文件: ${Object.keys(s.byFile).length}`);
  lines.push('');

  lines.push('【修复优先级】');
  lines.push(`  1. 紧急手动修复 (error): ${analysis.priority.critical.length} 个`);
  lines.push(`  2. 自动修复 (--fix):     ${analysis.priority.autofix.length} 个`);
  lines.push(`  3. 手动处理 (warn/sug):  ${analysis.priority.manual.length} 个`);
  lines.push('');

  if (analysis.autofixable.count > 0) {
    lines.push('【可自动修复的规则】（经 HTML 报告提取法探测）');
    for (const rule of analysis.autofixable.rules) {
      const r = analysis.byRule[rule];
      if (r) {
        lines.push(`  ✅ ${rule} — ${r.count} 处`);
      }
    }
    lines.push('  → 运行 --fix 自动修复');
    lines.push('');
  }

  lines.push('【按规则集分布】');
  for (const rs of RULESET_PREFIXES) {
    const stat = analysis.byRuleset[rs];
    if (stat && stat.total > 0) {
      lines.push(`  ${rs}: ${stat.total} (🔴${stat.error} 🟡${stat.warn} 🔵${stat.suggestion})`);
    }
  }
  lines.push('');

  const topFiles = analysis.byFile.slice(0, 5);
  if (topFiles.length > 0) {
    lines.push('【热点文件 TOP 5】');
    for (const f of topFiles) {
      const relPath = f.filePath.replace(/\\/g, '/');
      lines.push(`  ${relPath}`);
      lines.push(`    总计 ${f.total} (🔴${f.error || 0} 🟡${f.warn || 0} 🔵${f.suggestion || 0})`);
    }
  }

  return lines.join('\n');
}

/**
 * 从文件或 stdin 读取
 */
function readInput(fileArg) {
  if (fileArg && fileArg !== '-' && fs.existsSync(fileArg)) {
    return fs.readFileSync(fileArg, 'utf-8');
  }
  return fs.readFileSync(0, 'utf-8');
}

// CLI 入口
if (require.main === module) {
  const args = process.argv.slice(2);
  let format = 'text';
  let inputFile = null;
  let fixableRulesFile = null;

  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--format' && i + 1 < args.length) {
      format = args[i + 1];
      i++;
    } else if ((args[i] === '--fixable-rules' || args[i] === '-r') && i + 1 < args.length) {
      fixableRulesFile = args[i + 1];
      i++;
    } else if (args[i] === '-h' || args[i] === '--help') {
      console.log('用法: node analyze-results.js [file] [--format text|markdown|json] [--fixable-rules <rules.json>]');
      console.log('');
      console.log('选项:');
      console.log('  file                          结果文件路径（不指定则从 stdin 读取）');
      console.log('  --format <type>               输出格式：text(默认) / markdown / json');
      console.log('  --fixable-rules <rules.json>  可自动修复的规则 ID 列表（JSON 数组）');
      console.log('                                来自 Step 5a HTML 报告提取法（extract-fixable.js）探测结果');
      console.log('  -h, --help                    显示帮助');
      process.exit(0);
    } else if (!args[i].startsWith('-')) {
      inputFile = args[i];
    }
  }

  try {
    const raw = readInput(inputFile);
    let fixableRules = null;
    if (fixableRulesFile) {
      const data = JSON.parse(fs.readFileSync(fixableRulesFile, 'utf-8'));
      fixableRules = Array.isArray(data) ? data : (data.rules || data.fixableRules || []);
    }
    const analysis = analyze(raw, fixableRules);

    switch (format) {
      case 'json':
        console.log(JSON.stringify(analysis, null, 2));
        break;
      case 'markdown':
      case 'md':
        console.log(formatMarkdown(analysis));
        break;
      case 'text':
      default:
        console.log(formatText(analysis));
        break;
    }
  } catch (e) {
    console.error('分析失败: ' + e.message);
    process.exit(1);
  }
}

module.exports = {
  analyze,
  formatMarkdown,
  formatText,
  makeFixableChecker,
  inferRuleset,
  RULESET_PREFIXES,
};
