/**
 * 增量合并（spec ；design  围栏协议）：
 * - ④⑤（Java/ObjC）：围栏外骨架区替换为新草案；围栏段（BEGIN~END 含边界）按序保留既有手改区；
 *   草案围栏数不足/不成对 → 视为模板变更越界，整体替换并标记 kept=false（报告提示复核）。
 * - ①③：无围栏件，整体幂等替换（同输入再生成内容一致）。
 * - ②Local：文件已存在 → 保留开发者版本不覆盖。
 */

const FENCE_RE = {
  java: /^([ \t]*\/\/[ \t]*ARKUIX-BRIDGE-HANDOFF (BEGIN|END)[ \t]*\r?\n?)$/gm,
  objc: /^([ \t]*#pragma mark[ \t]+ARKUIX-BRIDGE-HANDOFF (BEGIN|END)[ \t]*\r?\n?)$/gm,
};

function fencesOf(text, fenceKind) {
  const re = new RegExp(FENCE_RE[fenceKind].source, 'gm');
  const all = [...text.matchAll(re)];
  const pairs = [];
  for (let i = 0; i + 1 < all.length; i += 2) {
    if (all[i][2] === 'BEGIN' && all[i + 1][2] === 'END') pairs.push([all[i], all[i + 1]]);
  }
  return pairs;
}

/** 将 existing 的围栏段按序回填到 draft 的对应围栏位置（骨架区=draft，手改区=existing） */
export function refillFences(draft, existing, fenceKind) {
  const exPairs = fencesOf(existing, fenceKind);
  const drPairs = fencesOf(draft, fenceKind);
  if (drPairs.length !== exPairs.length || exPairs.length === 0) return null;
  let out = '';
  let cursor = 0;
  for (let i = 0; i < exPairs.length; i++) {
    const [dBegin, dEnd] = drPairs[i];
    const [eBegin, eEnd] = exPairs[i];
    out += draft.slice(cursor, dBegin.index);
    out += existing.slice(eBegin.index, eEnd.index + eEnd[0].length);
    cursor = dEnd.index + dEnd[0].length;
  }
  out += draft.slice(cursor);
  return out;
}

/**
 * 合并单文件。
 * @param {string|null} existing 既有文件内容（null=首生成）
 * @param {string} draft 新草案内容
 * @param {'java'|'objc'|null} fenceKind 围栏形态（null=无围栏整体替换）
 * @returns {{content:string, kept:boolean}} kept=true 表示既有围栏段（手改区）被保留
 */
export function mergeFile(existing, draft, fenceKind) {
  if (existing === null || existing === undefined) return { content: draft, kept: false };
  if (!fenceKind) return { content: draft, kept: false };
  const merged = refillFences(draft, existing, fenceKind);
  if (merged === null) return { content: draft, kept: false };
  return { content: merged, kept: true };
}

/**
 * ②Local 合并：已存在→保留既有（不覆盖开发者调整）。
 * @returns {{content:string, kept:boolean}}
 */
export function mergeLocal(existing, draft) {
  if (existing === null || existing === undefined) return { content: draft, kept: false };
  return { content: existing, kept: true };
}
