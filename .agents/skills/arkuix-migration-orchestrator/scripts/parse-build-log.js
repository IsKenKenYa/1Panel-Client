#!/usr/bin/env node
/**
 * 编译日志解析器：
 * ace/hvigor 输出带 ANSI 色码 + 控制台硬折行（"At File:" 断行），人工/脚本解析困难。
 * 本工具：① 剥 ANSI → ② 跨行还原（At File 拼接）→ ③ 按文件聚类 → ④ 按规则分组 → JSON 输出。
 * 用法：node scripts/parse-build-log.js <build.log> [--json]
 */
import { readFileSync } from 'node:fs';

const ANSI_RE = /\u001b\[[\d;]*[A-Za-z]/g;
const ERROR_RE = /(\d+\s+)?(ERROR|Error Message)[:\s]+(.+)/;
const FILE_RE = /At File:\s*(.+)/;

function parseLog(raw) {
 // ① 剥 ANSI
  const clean = raw.replace(ANSI_RE, '');
  const lines = clean.split(/\r?\n/);

 // ② 跨行还原：Error Message 行后可能跟 At File 行（可能折断）
  const errors = [];
  let current = null;
  for (let i = 0; i < lines.length; i++) {
    const line = lines[i].trim();
 // 兼容两种格式：① Error Message + At File 同行 ② 分行（At File 折断在下一行）
    const combined = /Error Message:\s*(.+?)\s*At File:\s*(.+)/.exec(line);
    if (combined) {
      if (current) errors.push(current);
      const loc = parseLocation(combined[2].trim());
      current = { message: combined[1].trim(), ...loc };
      continue;
    }
    const em = ERROR_RE.exec(line);
    if (em) {
      if (current) errors.push(current);
      current = { message: em[3].trim(), file: null, line: null, col: null };
      continue;
    }
    if (current && !current.file) {
      const remaining = line + (lines[i + 1] ? ' ' + lines[i + 1].trim() : '');
      const fm = FILE_RE.exec(remaining);
      if (fm) {
        Object.assign(current, parseLocation(fm[1].trim()));
      }
    }
  }
  if (current) errors.push(current);

 // ③ 按文件聚类
  const byFile = new Map();
  for (const e of errors) {
    const key = e.file ?? '(unknown)';
    if (!byFile.has(key)) byFile.set(key, []);
    byFile.get(key).push(e);
  }

 // ④ 按规则分组（arkts-xxx / 11706007 / Cannot find / 其他）
  const byRule = new Map();
  for (const e of errors) {
    const rule = extractRule(e.message);
    if (!byRule.has(rule)) byRule.set(rule, 0);
    byRule.set(rule, byRule.get(rule) + 1);
  }

  return { total: errors.length, byFile: Object.fromEntries(byFile), byRule: Object.fromEntries(byRule) };
}

function parseLocation(loc) {
  const parts = loc.split(':');
  if (parts.length >= 3) {
    return { file: parts.slice(0, -2).join(':'), line: parseInt(parts[parts.length - 2]) || null, col: parseInt(parts[parts.length - 1]) || null };
  }
  if (parts.length === 2) {
    return { file: parts[0], line: parseInt(parts[1]) || null, col: null };
  }
  return { file: loc, line: null, col: null };
}

function extractRule(msg) {
  const arkts = /\((arkts-[a-z-]+)\)/.exec(msg);
  if (arkts) return arkts[1];
  if (msg.includes('11706007')) return '11706007-crossplatform';
  if (msg.includes('Cannot find')) return 'cannot-find';
  if (msg.includes('Schema validate')) return 'schema-validate';
  return 'other';
}

// CLI
const file = process.argv[2];
if (!file) { console.error('用法: node parse-build-log.js <build.log> [--json]'); process.exit(2); }
const result = parseLog(readFileSync(file, 'utf8'));
if (process.argv.includes('--json')) {
  console.log(JSON.stringify(result, null, 2));
} else {
  console.log(`编译错误: ${result.total} 处\n`);
  console.log('按规则分组:');
  for (const [rule, count] of Object.entries(result.byRule).sort((a, b) => b[1] - a[1])) {
    console.log(`  ${rule}: ${count}`);
  }
  console.log('\n按文件聚类:');
  for (const [file, errs] of Object.entries(result.byFile).sort((a, b) => b[1].length - a[1].length).slice(0, 10)) {
    console.log(`  ${file}: ${errs.length} 处`);
  }
}
