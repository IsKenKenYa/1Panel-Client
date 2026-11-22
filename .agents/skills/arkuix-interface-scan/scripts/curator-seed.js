import { readFileSync, writeFileSync } from 'node:fs';
import { join, resolve, basename } from 'node:path';
import { fileURLToPath } from 'node:url';
import { dirname } from 'node:path';
import { scanMarks } from './sdk-marks.js';
import { validateSdkDir } from './sdk-locator.js';

const SKILL_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));

/**
 * 规则表播种器（SDK @crossplatform 机器源 → full_direct 条目）：
 * - 仅播种「模块级整标」（moduleMarked=true：SDK 声明整模块跨平台支持）的模块
 * - 符号级部分标记的模块不播种（避免把部分支持误标为整模块①）——打印统计供人工策展
 * - 已有条目的模块跳过（人工策展优先，幂等可重跑）
 * - 条目 reason 注明机器播种出处；SDK 版本记录入 meta.sources
 * 用法：node scripts/curator-seed.js --sdk-dir <OH SDK 目录> [--rules <规则表路径>]
 */
export function seedRules(rulesDoc, markIndex, meta) {
  const existing = new Set(rulesDoc.rules.map((r) => r.module));
  const seeded = [];
  const partialModules = [];
  for (const [module, entry] of markIndex) {
    if (existing.has(module)) continue;
    if (entry.moduleMarked === true) {
      seeded.push({
        module, symbol: null, category: 'full_direct',
        reason: `SDK @crossplatform 模块级标记播种（机器源：${meta.sourceLabel}；标记≠ArkUI-X 已发布实测支持，人工策展可覆盖本条）`,
        advice: '可直接使用（SDK 声明整模块跨平台）；建议对关键路径做双平台回归验证',
        suggested_alternative: 'N/A'
      });
      existing.add(module);
    } else if (entry.symbols.size > 0) {
      const marked = [...entry.symbols.values()].filter(Boolean).length;
      partialModules.push(`${module}（${marked} 个符号级标记，未播种）`);
    }
  }
  return { seeded, partialModules };
}

function main() {
  const argv = process.argv.slice(2);
  let sdkDir = null;
  let rulesPath = join(SKILL_ROOT, 'rules', 'adaptation.json');
  for (let i = 0; i < argv.length; i++) {
    if (argv[i] === '--sdk-dir') sdkDir = argv[++i];
    else if (argv[i] === '--rules') rulesPath = argv[++i];
  }
  if (!sdkDir) {
    console.error('用法: node scripts/curator-seed.js --sdk-dir <OpenHarmony SDK 目录> [--rules <规则表路径>]');
    process.exit(2);
  }
  const validation = validateSdkDir(resolve(sdkDir));
  if (!validation.ok) {
    console.error(`SDK 目录无效（${validation.reason}）: ${sdkDir}`);
    process.exit(2);
  }
  const doc = JSON.parse(readFileSync(rulesPath, 'utf8'));
  const markIndex = scanMarks(validation.apiDir);
  const sourceLabel = `OH SDK ${basename(sdkDir) || sdkDir} ets/api`;
  const { seeded, partialModules } = seedRules(doc, markIndex, { sourceLabel });

  if (seeded.length > 0) {
    doc.rules.push(...seeded.sort((a, b) => a.module.localeCompare(b.module)));
    const [major, minor, patch] = String(doc.meta.rules_version).split('.').map(Number);
    doc.meta.rules_version = `${major}.${minor + 1}.${patch}`;
    doc.meta.curated_at = new Date().toISOString().slice(0, 10);
    doc.meta.sources = doc.meta.sources.filter((s) => s.kind !== 'oh-sdk-crossplatform-seed');
    doc.meta.sources.push({
      kind: 'oh-sdk-crossplatform-seed',
      version: `${sourceLabel}（模块级整标播种 ${seeded.length} 条，幂等重跑）`
    });
    writeFileSync(rulesPath, JSON.stringify(doc, null, 2) + '\n', 'utf8');
  }
  console.log(`播种 ${seeded.length} 条（rules_version → ${doc.meta.rules_version}）；` +
    `符号级部分标记模块 ${partialModules.length} 个未播种（供人工策展）`);
  for (const line of partialModules.slice(0, 10)) console.log(`  - ${line}`);
}

if (process.argv[1] && resolve(process.argv[1]) === resolve(fileURLToPath(import.meta.url))) {
  main();
}
