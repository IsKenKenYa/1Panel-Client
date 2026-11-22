import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { looseJson5 } from './migrate.js';

/**
 * Compile SDK 版本表（固化策展，来源=ace_tools.js ON() 映射实测提取，见 rules/sdk-versions.json meta）：
 * - 与 ace create 的 Compile SDK 菜单全集一致（数组插入序=菜单编号序 1..N）
 * - runtimeOS 与版本正交（ace create 第 3 题独立应答，本 Skill 恒 OpenHarmony 形态）
 * - OpenHarmony 形态 build-profile 版本写法（ace modifyOpenHarmonyOSConfig 实证）：
 *   apiLevel<26 → 数字 apiLevel；仅 26.0.0 → 字符串 "26.0.0"（见 openharmonyCompileSdkOf）
 */

const SKILL_ROOT = dirname(dirname(fileURLToPath(import.meta.url)));
const REQUIRED_FIELDS = ['key', 'apiLevel', 'devEcoVersion', 'compileSdkVersion', 'compatibleSdkVersion', 'modelVersion', 'hvigorPlugin'];

let cached = null;

export const DEFAULT_SDK_VERSION = '26.0.0';

/** 加载版本表（fail-fast：结构/字段非法即抛——未预期异常语义） */
export function loadSdkVersions(path) {
  const p = path ?? join(SKILL_ROOT, 'rules', 'sdk-versions.json');
  const doc = JSON.parse(readFileSync(p, 'utf8'));
  if (!doc || !Array.isArray(doc.versions) || doc.versions.length === 0) {
    throw new Error(`sdk-versions 结构非法：缺少 versions 数组（${p}）`);
  }
  for (const v of doc.versions) {
    for (const f of REQUIRED_FIELDS) {
      if (v[f] === undefined || v[f] === null || v[f] === '') {
        throw new Error(`sdk-versions 条目非法：${v.key ?? '?'} 缺 ${f}（${p}）`);
      }
    }
    if (!Number.isInteger(v.apiLevel)) throw new Error(`sdk-versions 条目非法：${v.key} 的 apiLevel 须为整数`);
  }
  cached = doc;
  return doc;
}

function table() {
  return cached ?? loadSdkVersions();
}

/** 支持版本全集（菜单序）；测试注入 */
export function listSupported() {
  return [...table().versions];
}

export function _setCache(doc) { cached = doc; }

/** 版本输入解析：版本键（"24"/"26.0.0"）或 compileSdk/compatibleSdkVersion 全形态（"6.1.1(24)"）→ 表条目；未收录 null（不猜测） */
export function resolveVersionEntry(input) {
  const s = String(input ?? '').trim();
  if (!s) return null;
  const versions = table().versions;
  return versions.find((v) => v.key === s)
    ?? versions.find((v) => v.compileSdkVersion === s || v.compatibleSdkVersion === s)
    ?? versions.find((v) => v.devEcoVersion === s)
    ?? null;
}

/** 语义化版本键比较（'26.0.0' > '24' > '10'，数字段逐段） */
export function compareVersionKeys(a, b) {
  const pa = String(a).split('.').map((s) => Number(s) || 0);
  const pb = String(b).split('.').map((s) => Number(s) || 0);
  for (let i = 0; i < Math.max(pa.length, pb.length); i++) {
    const d = (pa[i] ?? 0) - (pb[i] ?? 0);
    if (d !== 0) return d;
  }
  return 0;
}

/** 最高版本表条目（推荐默认） */
export function highestVersionEntry() {
  return [...table().versions].sort((a, b) => compareVersionKeys(b.key, a.key))[0];
}

/** ace create Compile SDK 菜单编号（表插入序 1..N；未收录 null） */
export function menuIndexOf(key) {
  const idx = table().versions.findIndex((v) => v.key === key);
  return idx >= 0 ? idx + 1 : null;
}

/**
 * OpenHarmony 形态 build-profile 的 compileSdkVersion/compatibleSdkVersion 写入值
 * （ace modifyOpenHarmonyOSConfig 实证：`o=n; n>=26&&(o=t)`——apiLevel<26 写数字，26.0.0 写字符串）。
 */
export function openharmonyCompileSdkOf(entry) {
  return entry.apiLevel >= 26 ? entry.key : entry.apiLevel;
}

/**
 * 按运行时形态分流的版本写入值：HarmonyOS 形态写全形态串（表内 compileSdkVersion，
 * 如 "5.0.5(17)"——HarmonyOS 形态实证写法）；其余（缺省）走 OpenHarmony 形态写法。
 */
export function compileSdkWriteOf(entry, runtimeOS) {
  return runtimeOS === 'HarmonyOS' ? entry.compileSdkVersion : openharmonyCompileSdkOf(entry);
}

/**
 * 源工程运行时形态探测：读源根 build-profile 的 runtimeOS（顶层或 app.products[0]）。
 * 仅显式 "HarmonyOS" 返回之（形态保留语义）；缺失/其他值返回 null（按 OpenHarmony 形态处理，
 * 兼容无 runtimeOS 字段的历史 OpenHarmony 工程）。返回值供归档物化与版本写法分流。
 */
export function detectSourceRuntimeOS(srcRoot) {
  const bpPath = join(srcRoot, 'build-profile.json5');
  if (!existsSync(bpPath)) return null;
  let doc;
  try { doc = JSON.parse(looseJson5(readFileSync(bpPath, 'utf8'))); } catch { return null; }
  const holder = (doc.runtimeOS !== undefined) ? doc : (doc.app?.products?.[0] ?? {});
  return holder.runtimeOS === 'HarmonyOS' ? 'HarmonyOS' : null;
}

/**
 * 源工程版本探测：loose-parse 源根 build-profile 的 compile/compatibleSdkVersion
 * （顶层或 app.products[0]，OpenHarmony 数字形态与 HarmonyOS 全形态均反查）→ 表条目；失败/未收录 null。
 */
export function detectSourceSdkVersion(srcRoot) {
  const bpPath = join(srcRoot, 'build-profile.json5');
  if (!existsSync(bpPath)) return null;
  let doc;
  try {
    doc = JSON.parse(looseJson5(readFileSync(bpPath, 'utf8')));
  } catch {
    return null;
  }
  const holders = [doc, doc?.app?.products?.[0] ?? {}];
  for (const h of holders) {
    for (const field of ['compileSdkVersion', 'compatibleSdkVersion']) {
      if (h?.[field] === undefined || h?.[field] === null) continue;
      // OpenHarmony 数字形态（24）直接当键试；全形态（"6.1.1(24)"）由 resolveVersionEntry 反查
      const hit = resolveVersionEntry(String(h[field])) ?? resolveVersionEntry(h[field]);
      if (hit) return hit;
    }
  }
  return null;
}


/**
 * 任意版本写法 → API level 数值（用于三值关系比较）：全形态串（"5.0.5(17)"→17）经
 * 版本表反查；裸 "26.0.0"→26；纯数字直取。不可解析返回 null（调用方保守处理）。
 */
export function apiLevelOf(value) {
  if (value === undefined || value === null) return null;
  const s = String(value).trim();
  if (/^\d+$/.test(s)) return parseInt(s, 10);
  if (s === '26.0.0') return 26;
  const m = /\((\d+)\)\s*$/.exec(s); // 全形态串末段即 apiLevel（x.y.z(api)）——无需版本表精确匹配（源工程串可能非表内条目形态）
  if (m) return parseInt(m[1], 10);
  const entry = resolveVersionEntry(s);
  return entry ? entry.apiLevel : null;
}

/**
 * 源工程版本三元组原始值探测（顶层或 app.products[0]，与 detectSourceRuntimeOS 同源）：
 * 返回 { compatibleSdkVersion, targetSdkVersion, compileSdkVersion }（在场者；缺省键为 undefined）。
 * 供 new 模式物化做"保留源值 + 越界钳制"——compatible/target 语义属源工程（兼容下限/目标版本），
 * 仅当破坏 compatible <= target <= compile 关系时钳制，不无故抬升兼容基线。
 */
export function detectSourceSdkVersions(srcRoot) {
  const bpPath = join(srcRoot, 'build-profile.json5');
  if (!existsSync(bpPath)) return {};
  let doc;
  try { doc = JSON.parse(looseJson5(readFileSync(bpPath, 'utf8'))); } catch { return {}; }
  const holder = (doc.compileSdkVersion !== undefined || doc.compatibleSdkVersion !== undefined || doc.targetSdkVersion !== undefined)
    ? doc : (doc.app?.products?.[0] ?? {});
  const out = {};
  for (const k of ['compileSdkVersion', 'targetSdkVersion', 'compatibleSdkVersion']) {
    if (holder[k] !== undefined && holder[k] !== null) out[k] = holder[k];
  }
  return out;
}