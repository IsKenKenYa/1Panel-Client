import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

/** native-api-map 加载与两级匹配（load 校验失败 fail-fast） */

let cached = null;

export function loadNativeApiMap(path) {
  const p = path ?? join(dirname(fileURLToPath(import.meta.url)), '..', 'rules', 'native-api-map.json');
  const map = JSON.parse(readFileSync(p, 'utf8'));
  if (!map || typeof map !== 'object' || !Array.isArray(map.mappings)) {
    throw new Error(`native-api-map 结构非法：缺少 mappings（${p}）`);
  }
  if (!map.meta || typeof map.meta.rules_version !== 'string') {
    throw new Error(`native-api-map 结构非法：缺少 meta.rules_version（${p}）`);
  }
  for (const m of map.mappings) {
    if (typeof m.module !== 'string' || typeof m.symbol !== 'string' || typeof m.android !== 'string' || typeof m.ios !== 'string') {
      throw new Error(`native-api-map 条目非法：module/symbol/android/ios 必填（${p}）`);
    }
 // ：可选最低版本标注（F4 适用版本澄清）——在场须为字符串（如 "API 21+"/"iOS 9+"）
    if (m.min_android !== undefined && typeof m.min_android !== 'string') {
      throw new Error(`native-api-map 条目非法：min_android 须为字符串（${p}）`);
    }
    if (m.min_ios !== undefined && typeof m.min_ios !== 'string') {
      throw new Error(`native-api-map 条目非法：min_ios 须为字符串（${p}）`);
    }
  }
  cached = map;
  return map;
}

/** 两级匹配：符号级（module+symbol）→ 模块级（module）；无命中 undefined（不猜测） */
export function matchNativeApi(module, symbol) {
  const map = cached ?? loadNativeApiMap();
  const exact = map.mappings.find((m) => m.module === module && m.symbol === symbol);
  if (exact) return exact;
  return map.mappings.find((m) => m.module === module && m.symbol === '*');
}

/** 测试注入 */
export function _setCache(map) { cached = map; }
