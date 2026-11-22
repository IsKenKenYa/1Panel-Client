#!/usr/bin/env node
'use strict';

/**
 * 读取已安装 DevEco Studio 的 CodeLinter 规则信息，
 * 用于版本特化适配：对比 skill 规则全集，输出该版本实际可用/不可用的规则。
 *
 * 脚本读取三个数据源并合并为统一的规则视图（不区分来源，对外统一呈现为 CodeLinter 规则集）：
 *
 *   数据源 1a: ruleSet.json — 定义各预设（recommended/all）包含哪些规则及级别
 *   数据源 1b: code_linter_schema.json — 所有可在 rules 字段中使用的规则（IDE 自动补全用）
 *   数据源 2:  tsauditrules.json — 工具自动加载的规则，不区分 recommended/all，
 *              选中对应规则集的任意预设即全部运行
 *
 * 数据源路径（均从 DevEco 安装目录推导）：
 *   1a. <DevEco>/plugins/codelinter/arkPerfCheck/ruleSet.json
 *   1b. <DevEco>/plugins/openharmony/lib/ohos-resource-*.jar 内的 code_linter_schema.json
 *   2.  <DevEco>/plugins/codelinter/performanceAgent/tsauditrules.json
 *
 * 用法：
 *   node extract-schema.js <DevEco安装目录>
 *   node extract-schema.js <DevEco安装目录> --json
 *   node extract-schema.js <DevEco安装目录> --compare <skill规则全集JSON>
 */

const fs = require('fs');
const path = require('path');

const SCHEMA_JAR_GLOB = /^ohos-resource-.*\.jar$/;
const SCHEMA_JAR_PATH = 'com/huawei/deveco/res/ohos/json/schema/code_linter_schema.json';
const RULESET_RELATIVE = path.join('plugins', 'codelinter', 'arkPerfCheck', 'ruleSet.json');
const TSAUDIT_RELATIVE = path.join('plugins', 'codelinter', 'performanceAgent', 'tsauditrules.json');

/**
 * 从 jar 包中提取指定文件到临时目录
 * 依次尝试 adm-zip、Java jar 命令、PowerShell 三种方式
 */
function extractFromJar(jarPath, entryPath, outputPath) {
  // 尝试 adm-zip
  try {
    const AdZip = require('adm-zip');
    const zip = new AdZip(jarPath);
    const entry = zip.getEntry(entryPath);
    if (!entry) return null;
    fs.writeFileSync(outputPath, entry.getData());
    return outputPath;
  } catch (e) {
    // adm-zip 不可用，尝试下一种方式
  }

  // 尝试系统 jar 命令（Java）
  try {
    const { execSync } = require('child_process');
    const tmpDir = path.dirname(outputPath);
    execSync(`jar xf "${jarPath}" ${entryPath}`, { cwd: tmpDir, stdio: 'ignore' });
    const extracted = path.join(tmpDir, ...entryPath.split('/'));
    if (fs.existsSync(extracted)) {
      if (extracted !== outputPath) {
        fs.copyFileSync(extracted, outputPath);
        fs.unlinkSync(extracted);
      }
      return outputPath;
    }
  } catch (e) {
    // Java 不可用
  }

  // 尝试 PowerShell（Windows）— 写临时 .ps1 文件，硬编码路径避免参数传递问题
  if (process.platform === 'win32') {
    try {
      const { execSync } = require('child_process');
      const psScript = [
        'Add-Type -AssemblyName System.IO.Compression.FileSystem',
        `$zip = [System.IO.Compression.ZipFile]::OpenRead("${jarPath.replace(/"/g, '""')}")`,
        `$entry = $zip.GetEntry("${entryPath.replace(/"/g, '""')}")`,
        'if ($entry) {',
        `  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "${outputPath.replace(/"/g, '""')}", $true)`,
        '}',
        '$zip.Dispose()',
      ].join('\n');
      const psFile = outputPath + '.extract.ps1';
      fs.writeFileSync(psFile, psScript, 'utf8');
      execSync(
        `powershell -NoProfile -ExecutionPolicy Bypass -File "${psFile}"`,
        { stdio: 'pipe' }
      );
      try { fs.unlinkSync(psFile); } catch (e) {}
      if (fs.existsSync(outputPath)) return outputPath;
    } catch (e) {
      // PowerShell 失败
    }
  }

  return null;
}

/**
 * 查找 ohos-resource jar 文件
 */
function findResourceJar(openharmonyLibDir) {
  if (!fs.existsSync(openharmonyLibDir)) return null;
  const files = fs.readdirSync(openharmonyLibDir);
  for (const f of files) {
    if (SCHEMA_JAR_GLOB.test(f)) {
      return path.join(openharmonyLibDir, f);
    }
  }
  return null;
}

/**
 * 解析 schema，提取 definitions.all 中的全部规则
 * @returns {Object<string, string>} 规则名 -> 描述
 */
function parseSchema(schemaPath) {
  const raw = JSON.parse(fs.readFileSync(schemaPath, 'utf8'));
  const rules = {};
  const allProps = raw && raw.definitions && raw.definitions.all && raw.definitions.all.properties;
  if (allProps) {
    for (const [name, def] of Object.entries(allProps)) {
      rules[name] = def.description || '';
    }
  }
  return rules;
}

/**
 * 解析 ruleSet.json，提取各预设的规则及级别
 * @returns {Object<string, Object<string, number>>} 预设名 -> {规则ID: 级别}
 */
function parseRuleSet(ruleSetPath) {
  const raw = JSON.parse(fs.readFileSync(ruleSetPath, 'utf8'));
  const presets = {};
  for (const [presetName, rules] of Object.entries(raw)) {
    presets[presetName] = { ...rules };
  }
  return presets;
}

/**
 * 解析 tsauditrules.json，提取工具自动加载的规则
 * 这些规则不区分 recommended/all，选中对应规则集的任意预设即全部运行
 * @returns {string[]} 启用的规则名列表
 */
function parseTsAuditRules(tsAuditPath) {
  if (!tsAuditPath || !fs.existsSync(tsAuditPath)) return [];
  const raw = JSON.parse(fs.readFileSync(tsAuditPath, 'utf8'));
  return raw && raw.rules ? Object.keys(raw.rules).filter(k => raw.rules[k]) : [];
}

/**
 * 按规则集前缀分组
 * @param {string[]} ruleNames 规则名列表
 */
function groupByPrefix(ruleNames) {
  const groups = {};
  const noPrefix = [];
  for (const name of ruleNames) {
    const match = name.match(/^@([\w-]+)\//);
    if (match) {
      const prefix = '@' + match[1];
      if (!groups[prefix]) groups[prefix] = [];
      groups[prefix].push(name);
    } else {
      noPrefix.push(name);
    }
  }
  for (const prefix of Object.keys(groups)) {
    groups[prefix].sort();
  }
  noPrefix.sort();
  return { groups, noPrefix };
}

/**
 * 级别数字转文字
 */
function severityLabel(num) {
  return { 0: 'off', 1: 'warn', 2: 'error', 3: 'suggestion' }[num] || String(num);
}

/**
 * 主函数
 */
function main() {
  const args = process.argv.slice(2);
  if (args.length === 0 || args[0] === '-h' || args[0] === '--help') {
    console.log('用法: node extract-schema.js <DevEco安装目录> [--json] [--compare <skill规则全集JSON>]');
    console.log('');
    console.log('选项:');
    console.log('  <DevEco安装目录>    DevEco Studio 安装根目录');
    console.log('  --json              JSON 格式输出结果');
    console.log('  --compare <file>    与 skill 规则全集 JSON 对比差异');
    process.exit(0);
  }

  const devecoDir = args[0];
  let jsonMode = false;
  let compareFile = null;

  for (let i = 1; i < args.length; i++) {
    if (args[i] === '--json') jsonMode = true;
    else if (args[i] === '--compare' && i + 1 < args.length) { compareFile = args[i + 1]; i++; }
  }

  if (!fs.existsSync(devecoDir)) {
    console.error('错误: DevEco 安装目录不存在: ' + devecoDir);
    process.exit(1);
  }

  // 1. 读取 ruleSet.json
  const ruleSetPath = path.join(devecoDir, RULESET_RELATIVE);
  const ruleSetExists = fs.existsSync(ruleSetPath);
  let presets = null;
  if (ruleSetExists) {
    presets = parseRuleSet(ruleSetPath);
  } else {
    console.error('警告: 未找到 ruleSet.json: ' + ruleSetPath);
  }

  // 2. 查找并提取 schema
  const openharmonyLib = path.join(devecoDir, 'plugins', 'openharmony', 'lib');
  const jarPath = findResourceJar(openharmonyLib);
  let schemaRules = null;

  if (jarPath) {
    const tmpDir = require('os').tmpdir();
    const tmpSchema = path.join(tmpDir, 'code_linter_schema_extracted.json');
    const extracted = extractFromJar(jarPath, SCHEMA_JAR_PATH, tmpSchema);
    if (extracted) {
      schemaRules = parseSchema(extracted);
    } else {
      console.error('警告: 无法从 jar 包提取 schema: ' + jarPath);
    }
  } else {
    console.error('警告: 未找到 ohos-resource jar 文件: ' + openharmonyLib);
  }

  // 3. 读取 tsauditrules.json（工具自动加载的规则）
  const tsAuditPath = path.join(devecoDir, TSAUDIT_RELATIVE);
  const tsAuditExists = fs.existsSync(tsAuditPath);
  let tsAuditRules = [];
  if (tsAuditExists) {
    tsAuditRules = parseTsAuditRules(tsAuditPath);
  } else {
    console.error('警告: 未找到 tsauditrules.json: ' + tsAuditPath);
  }

  // 4. 汇总结果
  const result = {
    devecoDir,
    ruleSetPath: ruleSetExists ? ruleSetPath : null,
    tsAuditPath: tsAuditExists ? tsAuditPath : null,
    jarPath,
    schemaExtracted: !!schemaRules,
    schemaRuleCount: schemaRules ? Object.keys(schemaRules).length : 0,
    tsAuditRuleCount: tsAuditRules.length,
    ruleSetPresets: {},
    schemaRulesByPrefix: {},
    schemaNoPrefixRules: [],
    tsAuditRules: tsAuditRules.sort(),
    // 合并视图：ruleSet 预设规则 + schema 可用规则 + tsAudit 独立引擎规则
    allEffectiveRules: [],
  };

  if (presets) {
    for (const [name, rules] of Object.entries(presets)) {
      result.ruleSetPresets[name] = {
        count: Object.keys(rules).length,
        rules: Object.entries(rules).sort(([a], [b]) => a.localeCompare(b))
          .reduce((o, [k, v]) => { o[k] = severityLabel(v); return o; }, {}),
      };
    }
  }

  if (schemaRules) {
    const { groups, noPrefix } = groupByPrefix(Object.keys(schemaRules));
    // 无前缀规则（如 eqeqeq、prefer-const）为 ESLint 核心规则，归属于 @typescript-eslint
    if (noPrefix.length > 0) {
      if (!groups['@typescript-eslint']) groups['@typescript-eslint'] = [];
      groups['@typescript-eslint'] = groups['@typescript-eslint'].concat(noPrefix).sort();
    }
    for (const [prefix, ruleList] of Object.entries(groups)) {
      result.schemaRulesByPrefix[prefix] = {
        count: ruleList.length,
        rules: ruleList.reduce((o, r) => { o[r] = schemaRules[r]; return o; }, {}),
      };
    }
    result.schemaNoPrefixRules = noPrefix;
  }

  // 计算所有实际生效的规则（合并去重）
  // schemaRules 覆盖所有可在 rules 字段中使用的规则；
  // tsAuditRules 是工具自动加载的规则；
  // presets 中的规则 ID 理论上是 schemaRules 的子集，此处防御性并入以确保完整性。
  const effectiveSet = new Set();
  if (schemaRules) for (const r of Object.keys(schemaRules)) effectiveSet.add(r);
  for (const r of tsAuditRules) effectiveSet.add(r);
  if (presets) for (const preset of Object.values(presets)) for (const r of Object.keys(preset)) effectiveSet.add(r);
  result.allEffectiveRules = Array.from(effectiveSet).sort();

  // 5. 对比（如果提供了 compare 文件）
  if (compareFile && fs.existsSync(compareFile)) {
    const skillRules = JSON.parse(fs.readFileSync(compareFile, 'utf8'));
    const skillSet = new Set(skillRules);

    result.comparison = {
      inSkillNotInVersion: skillRules.filter(r => !effectiveSet.has(r)).sort(),
      inVersionNotInSkill: result.allEffectiveRules.filter(r => !skillSet.has(r)),
    };
  }

  // 6. 输出
  if (jsonMode) {
    console.log(JSON.stringify(result, null, 2));
  } else {
    console.log('=== CodeLinter 规则提取报告 ===');
    console.log('DevEco 目录: ' + devecoDir);
    console.log('ruleSet.json: ' + (result.ruleSetPath || '未找到'));
    console.log('tsauditrules.json: ' + (result.tsAuditPath || '未找到') + ' (' + result.tsAuditRuleCount + ' 条)');
    console.log('jar 文件: ' + (jarPath || '未找到'));
    console.log('schema 规则数: ' + result.schemaRuleCount);
    console.log('合并生效规则数: ' + result.allEffectiveRules.length);
    console.log('');

    if (presets) {
      console.log('=== 预设规则数 ===');
      for (const [name, info] of Object.entries(result.ruleSetPresets)) {
        console.log(`  ${name}: ${info.count} 条`);
      }
      console.log('');
    }

    if (schemaRules) {
      console.log('=== Schema 规则按前缀统计 ===');
      for (const [prefix, info] of Object.entries(result.schemaRulesByPrefix)) {
        console.log(`  ${prefix}: ${info.count} 条`);
      }
      if (result.schemaNoPrefixRules.length > 0) {
        console.log(`  (无前缀): ${result.schemaNoPrefixRules.length} 条`);
        result.schemaNoPrefixRules.forEach(r => console.log(`    - ${r}`));
      }
      console.log('');
    }

    if (tsAuditRules.length > 0) {
      console.log('=== 工具自动加载规则（tsauditrules.json）===');
      console.log(`  共 ${tsAuditRules.length} 条，全部默认启用`);
      const { groups: tsGroups, noPrefix: tsNoPrefix } = groupByPrefix(tsAuditRules);
      for (const [prefix, list] of Object.entries(tsGroups)) {
        console.log(`  ${prefix}: ${list.length} 条`);
      }
      if (tsNoPrefix.length > 0) {
        console.log(`  (无前缀): ${tsNoPrefix.length} 条`);
      }
      console.log('');
    }

    if (result.comparison) {
      const c = result.comparison;
      console.log('=== 与 Skill 规则全集对比（基于合并生效规则）===');
      console.log(`Skill 有、当前版本无（${c.inSkillNotInVersion.length} 条）:`);
      c.inSkillNotInVersion.forEach(r => console.log(`  - ${r}`));
      console.log(`当前版本有、Skill 无（${c.inVersionNotInSkill.length} 条）:`);
      c.inVersionNotInSkill.forEach(r => console.log(`  - ${r}`));
    }
  }
}

main();
