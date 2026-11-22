#!/usr/bin/env node
'use strict';

/**
 * CodeLinter 配置校验脚本
 *
 * 在运行 CodeLinter 之前校验配置文件，避免因规则集/规则名/路径不存在而静默通过（0 告警误判）。
 *
 * 校验三类问题：
 *   1. ruleSet 中的规则集不存在于当前 DevEco 版本
 *   2. rules 中的规则名不存在于当前 DevEco 版本
 *   3. 工程目录不存在
 *
 * 用法：
 *   node validate-config.js <配置文件> <工程目录> <DevEco安装目录>
 *   node validate-config.js <配置文件> <工程目录> <DevEco安装目录> --json
 *
 * 退出码：
 *   0 — 校验通过
 *   1 — 校验失败（有错误）
 */

const fs = require('fs');
const path = require('path');

// Windows 控制台中文编码修复
if (process.platform === 'win32') {
  try {
    require('child_process').execSync('chcp 65001', { stdio: 'ignore' });
  } catch (e) {}
}

const SCHEMA_JAR_PATH = 'com/huawei/deveco/res/ohos/json/schema/code_linter_schema.json';
const RULESET_RELATIVE = path.join('plugins', 'codelinter', 'arkPerfCheck', 'ruleSet.json');
const TSAUDIT_RELATIVE = path.join('plugins', 'codelinter', 'performanceAgent', 'tsauditrules.json');
const SCHEMA_JAR_GLOB = /^ohos-resource-.*\.jar$/;

/**
 * 从 jar 包中提取 schema（复用 extract-schema.js 的逻辑）
 */
function extractSchemaFromJar(devecoDir) {
  const openharmonyLib = path.join(devecoDir, 'plugins', 'openharmony', 'lib');
  if (!fs.existsSync(openharmonyLib)) return null;

  const files = fs.readdirSync(openharmonyLib);
  let jarPath = null;
  for (const f of files) {
    if (SCHEMA_JAR_GLOB.test(f)) {
      jarPath = path.join(openharmonyLib, f);
      break;
    }
  }
  if (!jarPath) return null;

  const entryPath = SCHEMA_JAR_PATH;
  const tmpFile = path.join(require('os').tmpdir(), 'codelinter_schema_for_validate.json');

  // 尝试 adm-zip
  try {
    const AdZip = require('adm-zip');
    const zip = new AdZip(jarPath);
    const entry = zip.getEntry(entryPath);
    if (entry) {
      fs.writeFileSync(tmpFile, entry.getData());
      return JSON.parse(fs.readFileSync(tmpFile, 'utf8'));
    }
  } catch (e) {}

  // 尝试 PowerShell（Windows）
  if (process.platform === 'win32') {
    try {
      const psScript = [
        'Add-Type -AssemblyName System.IO.Compression.FileSystem',
        `$zip = [System.IO.Compression.ZipFile]::OpenRead("${jarPath.replace(/"/g, '""')}")`,
        `$entry = $zip.GetEntry("${entryPath.replace(/"/g, '""')}")`,
        'if ($entry) {',
        `  [System.IO.Compression.ZipFileExtensions]::ExtractToFile($entry, "${tmpFile.replace(/"/g, '""')}", $true)`,
        '}',
        '$zip.Dispose()',
      ].join('\n');
      const psFile = tmpFile + '.ps1';
      fs.writeFileSync(psFile, psScript, 'utf8');
      require('child_process').execSync(
        `powershell -NoProfile -ExecutionPolicy Bypass -File "${psFile}"`,
        { stdio: 'pipe' }
      );
      try { fs.unlinkSync(psFile); } catch (e) {}
      if (fs.existsSync(tmpFile)) {
        return JSON.parse(fs.readFileSync(tmpFile, 'utf8'));
      }
    } catch (e) {}
  }

  return null;
}

/**
 * 提取当前版本所有合法的规则集预设名、规则名
 */
function extractValidRules(devecoDir) {
  const validPresets = new Set();
  const validRules = new Set();

  // 1. ruleSet.json — 预设名 + 预设内规则
  const ruleSetPath = path.join(devecoDir, RULESET_RELATIVE);
  if (fs.existsSync(ruleSetPath)) {
    const ruleSet = JSON.parse(fs.readFileSync(ruleSetPath, 'utf8'));
    for (const [presetName, rules] of Object.entries(ruleSet)) {
      validPresets.add(presetName);
      for (const ruleId of Object.keys(rules)) {
        validRules.add(ruleId);
      }
    }
  }

  // 2. schema — 所有可用的规则
  const schema = extractSchemaFromJar(devecoDir);
  if (schema && schema.definitions && schema.definitions.all && schema.definitions.all.properties) {
    for (const ruleId of Object.keys(schema.definitions.all.properties)) {
      validRules.add(ruleId);
    }
  }

  // 3. tsauditrules.json — 工具自动加载的规则
  const tsAuditPath = path.join(devecoDir, TSAUDIT_RELATIVE);
  if (fs.existsSync(tsAuditPath)) {
    const tsAudit = JSON.parse(fs.readFileSync(tsAuditPath, 'utf8'));
    if (tsAudit.rules) {
      for (const ruleId of Object.keys(tsAudit.rules)) {
        if (tsAudit.rules[ruleId]) {
          validRules.add(ruleId);
        }
      }
    }
  }

  return { validPresets, validRules };
}

/**
 * 解析 JSON5 配置文件（简易解析，去除注释后 JSON.parse）
 */
function parseConfig(configPath) {
  let raw = fs.readFileSync(configPath, 'utf8');
  // 去除单行注释 //...
  raw = raw.replace(/\/\/.*$/gm, '');
  // 去除多行注释 /*...*/
  raw = raw.replace(/\/\*[\s\S]*?\*\//g, '');
  // 去除尾逗号
  raw = raw.replace(/,\s*([}\]])/g, '$1');
  return JSON.parse(raw);
}

/**
 * 主校验函数
 */
function validate(configPath, projectDir, devecoDir) {
  const errors = [];

  // 1. 校验工程目录
  if (!projectDir || !fs.existsSync(projectDir)) {
    errors.push({
      type: 'path',
      message: '工程目录不存在: ' + (projectDir || '(未指定)'),
    });
    return { valid: false, errors };
  }

  const stat = fs.statSync(projectDir);
  if (!stat.isDirectory()) {
    errors.push({
      type: 'path',
      message: '工程路径不是目录: ' + projectDir,
    });
    return { valid: false, errors };
  }

  // 2. 校验配置文件存在
  if (!configPath || !fs.existsSync(configPath)) {
    errors.push({
      type: 'config',
      message: '配置文件不存在: ' + (configPath || '(未指定)'),
    });
    return { valid: false, errors };
  }

  // 3. 解析配置文件
  let config;
  try {
    config = parseConfig(configPath);
  } catch (e) {
    errors.push({
      type: 'config',
      message: '配置文件解析失败: ' + e.message,
    });
    return { valid: false, errors };
  }

  // 4. 提取当前版本合法的规则集和规则
  const { validPresets, validRules } = extractValidRules(devecoDir);

  if (validPresets.size === 0) {
    errors.push({
      type: 'schema',
      message: '无法从 DevEco 安装目录提取规则集数据，请确认路径正确: ' + devecoDir,
    });
    return { valid: false, errors };
  }

  // 5. 校验 ruleSet 中的规则集
  if (config.ruleSet && Array.isArray(config.ruleSet)) {
    for (const preset of config.ruleSet) {
      if (!validPresets.has(preset)) {
        // 模糊匹配建议
        const prefix = preset.split('/')[0];
        const suggestions = [...validPresets].filter(p => p.startsWith(prefix)).slice(0, 5);
        errors.push({
          type: 'ruleset',
          preset: preset,
          message: '规则集不存在: ' + preset,
          suggestion: suggestions.length ? '是否想用: ' + suggestions.join(', ') : '无相似规则集',
        });
      }
    }
  }

  // 6. 校验 rules 中的规则名
  if (config.rules && typeof config.rules === 'object') {
    for (const ruleId of Object.keys(config.rules)) {
      // 跳过无前缀的 ESLint 核心规则（eqeqeq、prefer-const 等）
      if (!ruleId.startsWith('@')) continue;

      if (!validRules.has(ruleId)) {
        // 模糊匹配建议
        const parts = ruleId.split('/');
        const prefix = parts[0];
        const suggestions = [...validRules]
          .filter(r => r.startsWith(prefix) && r !== ruleId)
          .slice(0, 5);
        errors.push({
          type: 'rule',
          rule: ruleId,
          message: '规则不存在: ' + ruleId,
          suggestion: suggestions.length ? '相似规则: ' + suggestions.join(', ') : '无相似规则',
        });
      }
    }
  }

  return { valid: errors.length === 0, errors };
}

// CLI 入口
if (require.main === module) {
  const args = process.argv.slice(2);

  if (args.length < 3 || args[0] === '-h' || args[0] === '--help') {
    console.log('用法: node validate-config.js <配置文件> <工程目录> <DevEco安装目录> [--json]');
    console.log('');
    console.log('校验内容:');
    console.log('  1. ruleSet 中的规则集是否存在于当前 DevEco 版本');
    console.log('  2. rules 中的规则名是否存在于当前 DevEco 版本');
    console.log('  3. 工程目录是否存在');
    console.log('');
    console.log('退出码:');
    console.log('  0 — 校验通过');
    console.log('  1 — 校验失败');
    process.exit(args[0] === '-h' ? 0 : 1);
  }

  const configPath = args[0];
  const projectDir = args[1];
  const devecoDir = args[2];
  const jsonMode = args.includes('--json');

  const result = validate(configPath, projectDir, devecoDir);

  if (jsonMode) {
    console.log(JSON.stringify(result, null, 2));
  } else if (result.valid) {
    console.log('校验通过');
  } else {
    console.error('校验失败，发现 ' + result.errors.length + ' 个问题：');
    console.error('');
    for (const err of result.errors) {
      console.error('  [' + err.type + '] ' + err.message);
      if (err.suggestion) {
        console.error('         ' + err.suggestion);
      }
    }
    console.error('');
    console.error('请修正配置后重新运行。');
  }

  process.exit(result.valid ? 0 : 1);
}

module.exports = { validate, extractValidRules, parseConfig };
