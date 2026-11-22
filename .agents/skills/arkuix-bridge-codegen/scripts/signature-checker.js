import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

/**
 * 签名一致性校验：
 * 以 ①Interface 契约（真相源）参数类型为基准，校验其经 type-map 到 Java/ObjC 的映射可确定性；
 * 无映射/歧义映射 → Mismatch（仅入报告，不阻断产出）。
 */

let typeMapCache = null;

export function loadTypeMap(path) {
  const p = path ?? join(dirname(fileURLToPath(import.meta.url)), '..', 'rules', 'type-map.json');
  const map = JSON.parse(readFileSync(p, 'utf8'));
  if (!Array.isArray(map.types)) throw new Error(`type-map 结构非法：缺少 types（${p}）`);
  for (const t of map.types) {
    if (typeof t.arkts !== 'string' || typeof t.java !== 'string' || typeof t.objc !== 'string') {
      throw new Error(`type-map 条目非法：arkts/java/objc 必填（${p}）`);
    }
  }
  typeMapCache = map;
  return map;
}

/**
 * @param {Array<{name:string,module:string,symbol:string}>} items 接口清单
 * @param {Array<{interfaceName:string,methods:Array<{name:string,params:Array<{type:string,name:string}>}>}>} contracts ①契约
 * @returns {Array<{name:string,method:string,type:string,side:'java'|'objc',issue:string}>} Mismatch[]（空数组=全一致）
 */
export function checkSignatures(items, contracts, typeMap) {
  const map = typeMap ?? typeMapCache ?? loadTypeMap();
  const mismatches = [];
  contracts.forEach((contract, i) => {
    const item = items[i];
    for (const method of contract.methods) {
      for (const param of method.params) {
        const entry = map.types.find((t) => t.arkts === param.type);
        if (!entry) {
          mismatches.push({ name: item.name, method: method.name, type: param.type, side: 'java', issue: '无映射（需人工）' });
          mismatches.push({ name: item.name, method: method.name, type: param.type, side: 'objc', issue: '无映射（需人工）' });
        } else if (entry.ambiguous) {
          mismatches.push({ name: item.name, method: method.name, type: param.type, side: 'java', issue: `映射歧义：${param.type}→${entry.java}（需人工）` });
          mismatches.push({ name: item.name, method: method.name, type: param.type, side: 'objc', issue: `映射歧义：${param.type}→${entry.objc}（需人工）` });
        }
      }
    }
  });
  return mismatches;
}

export function _setCache(m) { typeMapCache = m; }
