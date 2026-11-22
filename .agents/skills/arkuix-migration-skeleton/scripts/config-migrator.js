import { existsSync, readFileSync, writeFileSync, copyFileSync, mkdirSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { looseJson5 } from './migrate.js';

/**
 * 配置文件迁移（new 模式可选增强，开发者强确认后启用）。
 *
 * 白名单合并策略——scaffold 模板的 arkui-x 适配键恒保留，源工程业务配置叠加：
 * - 根 build-profile.json5：`app.signingConfigs`（源在场整组替换）+ `app.products`（按产品名深合并，源字段覆盖同名）；
 *   `compileSdkVersion/compatibleSdkVersion/runtimeOS/modules` 恒不动（arkui-x 跨平台编译依赖）
 * - 根/entry oh-package.json5：`dependencies/devDependencies/overrides` 合并（源版本覆盖同名、scaffold 独有键保留）；
 *   `name/version/modelVersion/main` 恒 scaffold（HAR/HAP 身份与 26.0.0 模型版本）
 * - AppScope/app.json5：`app` 标量字段源覆盖（`bundleName` 保留 scaffold 定制版——如需源 bundleName 以 --bundle-name 传入）
 * - 无冲突拷贝：`code-linter.json5`、根 `.gitignore`、`entry/obfuscation-rules.txt`（仅 scaffold 侧缺失时）
 * - 恒保留模板（覆盖即破坏跨平台编译，逐项写明原因）：根 hvigorfile.ts、hvigor/hvigor-config.json5、entry build-profile.json5
 *
 * 「不遗漏、不多改」由 verifyConfigMigration 双向校验（调用方失败即回滚 snapshots 并中止）：
 * - 多改：合并前后解析文档 diff——变更路径必须 ⊆ 该文件白名单前缀；不变量（compileSdkVersion 等）恒不变
 * - 遗漏：应迁键（白名单内源键）全部落到输出
 */

const OH_PACKAGE_MERGE_KEYS = ['dependencies', 'devDependencies', 'overrides'];

/** products 条目内的版本/运行时键——归档放在 app.products[0]（compileSdkVersion 26.0.0 等），
 * 源值覆盖会回退 SDK 版本破坏跨平台编译：overlay 与遗漏校验双双排除（有意保留 scaffold 版） */
const PRODUCT_EXCLUDE_KEYS = ['compileSdkVersion', 'targetSdkVersion', 'compatibleSdkVersion', 'runtimeOS']; // 版本三元组恒 scaffold/版本替换写——源值合入会破坏 compatible<=target<=compile 关系与形态一致性

/** 恒保留模板清单（file → 原因）；仅当源工程存在同名文件时计入报告（否则无从"保留"） */
const KEEP_TEMPLATE = [
  ['hvigorfile.ts', 'arkui-x 专用任务导出（AppTasksForArkUIX）——覆盖破坏跨平台编译'],
  ['hvigor/hvigor-config.json5', 'modelVersion + @ohos/hvigor-ohos-arkui-x-plugin 插件依赖——覆盖破坏跨平台编译'],
  ['entry/build-profile.json5', 'scaffold 版含 obfuscation buildOptionSet 与 ohosTest targets（arkui-x 适配形态）'],
];

/** 无冲突拷贝清单（src 相对源工程根 = dst 相对输出根；仅 dst 缺失时拷贝） */
const COPY_NO_CONFLICT = ['code-linter.json5', '.gitignore', 'entry/obfuscation-rules.txt'];

/**
 * 执行配置迁移。返回 {merged, copied, kept_template, snapshots}：
 * - merged: [{file, action, keys}]（action=merge|replace-subtree）
 * - snapshots: Map<输出文件绝对路径, 合并前原文>（verify 失败时调用方回滚）
 */
export function migrateConfigs(srcRoot, outDir) {
  const report = { merged: [], copied: [], kept_template: [], snapshots: new Map() };
  mergeRootBuildProfile(srcRoot, outDir, report);
  mergeOhPackage(join(srcRoot, 'oh-package.json5'), join(outDir, 'oh-package.json5'), 'oh-package.json5（根）', report);
  mergeOhPackage(join(srcRoot, 'entry', 'oh-package.json5'), join(outDir, 'entry', 'oh-package.json5'), 'entry/oh-package.json5', report);
  mergeAppJson5(srcRoot, outDir, report);
  for (const rel of COPY_NO_CONFLICT) {
    const src = join(srcRoot, rel);
    const dst = join(outDir, rel);
    if (existsSync(src) && !existsSync(dst)) {
      mkdirSync(dirname(dst), { recursive: true });
      copyFileSync(src, dst);
      report.copied.push(rel);
    }
  }
  for (const [rel, reason] of KEEP_TEMPLATE) {
    if (existsSync(join(srcRoot, rel))) report.kept_template.push({ file: rel, reason });
  }
  return report;
}

/** 读 + 宽松解析（缺文件返回 null；解析失败返回 {parseError}——调用方按"无法合并"处理） */
function readJson5(file) {
  if (!existsSync(file)) return null;
  try {
    return JSON.parse(looseJson5(readFileSync(file, 'utf8')));
  } catch (err) {
    return { parseError: `${err.message}` };
  }
}

function mergeRootBuildProfile(srcRoot, outDir, report) {
  const src = readJson5(join(srcRoot, 'build-profile.json5'));
  const dstFile = join(outDir, 'build-profile.json5');
  const dst = readJson5(dstFile);
  if (!src || !dst || src.parseError || dst.parseError || !dst.app) return;
  const keys = [];
  report.snapshots.set(dstFile, readFileSync(dstFile, 'utf8'));
  if (Array.isArray(src.app?.signingConfigs)) {
    dst.app.signingConfigs = src.app.signingConfigs;
    keys.push('app.signingConfigs（整组替换）');
  }
  if (Array.isArray(src.app?.products) && src.app.products.length > 0) {
    for (const sp of src.app.products) {
      const name = sp?.name ?? 'default';
      const overlay = Object.fromEntries(Object.entries(sp).filter(([k]) => !PRODUCT_EXCLUDE_KEYS.includes(k)));
      const idx = (dst.app.products ?? []).findIndex((p) => (p?.name ?? 'default') === name);
      if (idx >= 0) dst.app.products[idx] = { ...dst.app.products[idx], ...overlay };
      else (dst.app.products ??= []).push(overlay);
    }
    keys.push(`app.products.${src.app.products.map((p) => p?.name ?? 'default').join('/')}`);
  }
  if (keys.length > 0) {
    writeFileSync(dstFile, JSON.stringify(dst, null, 2) + '\n', 'utf8');
    report.merged.push({ file: 'build-profile.json5', action: 'merge', keys });
  } else {
    report.snapshots.delete(dstFile); // 未改动不留快照
  }
}

function mergeOhPackage(srcFile, dstFile, label, report) {
  const src = readJson5(srcFile);
  const dst = readJson5(dstFile);
  if (!src || !dst || src.parseError || dst.parseError) return;
  const keys = [];
  report.snapshots.set(dstFile, readFileSync(dstFile, 'utf8'));
  for (const k of OH_PACKAGE_MERGE_KEYS) {
    const fromSrc = src[k];
    if (!fromSrc || typeof fromSrc !== 'object') continue;
    const count = Object.keys(fromSrc).filter((d) => dst[k]?.[d] !== fromSrc[d]).length;
    dst[k] = { ...(dst[k] ?? {}), ...fromSrc };
    if (count > 0) keys.push(`${k}×${count}`);
  }
  if (keys.length > 0) {
    writeFileSync(dstFile, JSON.stringify(dst, null, 2) + '\n', 'utf8');
    report.merged.push({ file: label, action: 'merge', keys });
  } else {
    report.snapshots.delete(dstFile);
  }
}

function mergeAppJson5(srcRoot, outDir, report) {
  const srcFile = join(srcRoot, 'AppScope', 'app.json5');
  const dstFile = join(outDir, 'AppScope', 'app.json5');
  const src = readJson5(srcFile);
  const dst = readJson5(dstFile);
  if (!src || !dst || src.parseError || dst.parseError) return;
  const keys = [];
  report.snapshots.set(dstFile, readFileSync(dstFile, 'utf8'));
  for (const [k, v] of Object.entries(src.app ?? {})) {
    if (k === 'bundleName') continue; // scaffold 定制版（materialize 已按 --bundle-name 替换；如需源值以参数传入）
    if (v !== null && typeof v === 'object') continue; // 仅标量（versionCode/versionName/icon/label/vendor 等）
    if (JSON.stringify(dst.app[k]) !== JSON.stringify(v)) {
      dst.app[k] = v;
      keys.push(k);
    }
  }
  if (keys.length > 0) {
    writeFileSync(dstFile, JSON.stringify(dst, null, 2) + '\n', 'utf8');
    report.merged.push({ file: 'AppScope/app.json5', action: 'merge', keys });
  } else {
    report.snapshots.delete(dstFile);
  }
}

/**
 * 遗漏/多改双向校验（防遗漏、防多改）。
 * @returns {{ok: boolean, missing: string[], unexpected_changes: string[]}}
 */
export function verifyConfigMigration(srcRoot, outDir, applied) {
  const missing = [];
  const unexpected = [];
  const diffPaths = (before, after, prefix = '') => {
    const out = [];
    const keys = new Set([...Object.keys(before ?? {}), ...Object.keys(after ?? {})]);
    for (const k of keys) {
      const p = prefix ? `${prefix}.${k}` : k;
      const b = before?.[k];
      const a = after?.[k];
      if (b && a && typeof b === 'object' && typeof a === 'object' && !Array.isArray(b) && !Array.isArray(a)) {
        out.push(...diffPaths(b, a, p));
      } else if (JSON.stringify(b) !== JSON.stringify(a)) out.push(p);
    }
    return out;
  };
  const allow = (paths, prefixes) => paths.filter((p) => !prefixes.some((pre) => p === pre || p.startsWith(pre + '.')));

  for (const [file, beforeText] of applied.snapshots) {
    const before = JSON.parse(looseJson5(beforeText));
    const after = readJson5(file);
    if (!after || after.parseError) { unexpected.push(`${file}：合并后不可解析`); continue; }
    const rel = relativeOf(outDir, file);
    const changed = diffPaths(before, after);
    if (rel === 'build-profile.json5') {
      const bad = allow(changed, ['app.signingConfigs', 'app.products']);
      for (const b of bad) unexpected.push(`build-profile.json5：白名单外改动 ${b}`);
      for (const inv of ['compileSdkVersion', 'targetSdkVersion', 'compatibleSdkVersion', 'runtimeOS', 'modules']) {
        if (JSON.stringify(before[inv]) !== JSON.stringify(after[inv])) {
          unexpected.push(`build-profile.json5：不变量 ${inv} 被改动`);
        }
      }
 // products 条目内的版本键（归档形态）恒 scaffold——源值回退 SDK 版本即坏（PRODUCT_EXCLUDE_KEYS 同口径）
      const productOf = (doc) => (doc?.app?.products ?? []).find((p) => (p?.name ?? 'default') === 'default');
      const bp0 = productOf(before);
      const ap0 = productOf(after);
      if (bp0) {
        for (const inv of PRODUCT_EXCLUDE_KEYS) {
          if (JSON.stringify(bp0[inv]) !== JSON.stringify(ap0?.[inv])) {
            unexpected.push(`build-profile.json5：不变量 app.products.${inv} 被改动`);
          }
        }
      }
    } else if (rel === 'oh-package.json5' || rel === 'entry/oh-package.json5') {
      const bad = allow(changed, OH_PACKAGE_MERGE_KEYS);
      for (const b of bad) unexpected.push(`${rel}：白名单外改动 ${b}`);
      for (const inv of ['name', 'version', 'modelVersion', 'main']) {
        if (JSON.stringify(before[inv]) !== JSON.stringify(after[inv])) {
          unexpected.push(`${rel}：不变量 ${inv} 被改动`);
        }
      }
    } else if (rel === 'AppScope/app.json5') {
      const bad = changed.filter((p) => p === 'app.bundleName' || !p.startsWith('app.'));
      for (const b of bad) unexpected.push(`AppScope/app.json5：白名单外改动 ${b}`);
    }
  }

  // 遗漏：应迁键须落到输出（源与输出的白名单面逐键比对）
  const srcBp = readJson5(join(srcRoot, 'build-profile.json5'));
  const outBp = readJson5(join(outDir, 'build-profile.json5'));
  if (srcBp && outBp && !srcBp.parseError && !outBp.parseError) {
    if (Array.isArray(srcBp.app?.signingConfigs)
      && JSON.stringify(outBp.app?.signingConfigs) !== JSON.stringify(srcBp.app.signingConfigs)) {
      missing.push('build-profile.json5：app.signingConfigs 未落齐');
    }
    for (const sp of srcBp.app?.products ?? []) {
      const name = sp?.name ?? 'default';
      const op = (outBp.app?.products ?? []).find((p) => (p?.name ?? 'default') === name);
      if (!op) { missing.push(`build-profile.json5：app.products.${name} 缺失`); continue; }
      for (const [k, v] of Object.entries(sp)) {
        if (PRODUCT_EXCLUDE_KEYS.includes(k)) continue; // 版本键有意保留 scaffold 版（不回退）
        if (JSON.stringify(op[k]) !== JSON.stringify(v)) missing.push(`build-profile.json5：app.products.${name}.${k} 未落齐`);
      }
    }
  }
  for (const [srcRel, label] of [['oh-package.json5', 'oh-package.json5（根）'], ['entry/oh-package.json5', 'entry/oh-package.json5']]) {
    const s = readJson5(join(srcRoot, srcRel));
    const o = readJson5(join(outDir, srcRel));
    if (!s || !o || s.parseError || o.parseError) continue;
    for (const k of OH_PACKAGE_MERGE_KEYS) {
      for (const [dep, ver] of Object.entries(s[k] ?? {})) {
        if (JSON.stringify(o[k]?.[dep]) !== JSON.stringify(ver)) missing.push(`${label}：${k}.${dep} 未落齐`);
      }
    }
  }
  const srcApp = readJson5(join(srcRoot, 'AppScope', 'app.json5'));
  const outApp = readJson5(join(outDir, 'AppScope', 'app.json5'));
  if (srcApp && outApp && !srcApp.parseError && !outApp.parseError) {
    for (const [k, v] of Object.entries(srcApp.app ?? {})) {
      if (k === 'bundleName' || (v !== null && typeof v === 'object')) continue;
      if (JSON.stringify(outApp.app?.[k]) !== JSON.stringify(v)) missing.push(`AppScope/app.json5：app.${k} 未落齐`);
    }
  }
  return { ok: missing.length === 0 && unexpected.length === 0, missing, unexpected_changes: unexpected };
}

function relativeOf(outDir, file) {
  const norm = (p) => p.split('\\').join('/');
  return norm(file).replace(`${norm(outDir)}/`, '');
}
