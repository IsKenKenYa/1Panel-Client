import { readFileSync, writeFileSync, renameSync } from 'node:fs';

/**
 * Adjudicator：unknown 裁决 + ⑥桥接决策回写 ScanReport（F4 ，spec  六件套联动）。
 * - uk chosen ∈ {equivalent_bridge, degraded_bridge, platform_trim}：项从 unknown 桶移入目标桶，reason 追加溯源
 * - uk chosen = keep_unknown：保持 unknown，reason 追加"显式搁置"标注（与未处理区分）
 * - bd chosen = 降级为平台原生桥接（hms-closed/kit-closed）：项从⑥ business_decision 移入④ degraded_bridge——
 *   bridge 阶段（F3）消费④桶即自动生成六件套骨架（⑥降级须可触达桥接生成）
 * - bd 其余 chosen：不移桶，reason 追加裁决标注（三产物口径一致）
 * - 原地原子改写（tmp+rename）；幂等：reason 已含裁决标注的项跳过、已移桶项按未命中计
 * - 不增删字段（契约零变更，校验保持通过）
 */

const LABEL = { equivalent_bridge: '③等价桥接', degraded_bridge: '④降级桥接', platform_trim: '⑤平台裁剪' };
const BD_BRIDGE_CHOICE = '降级为平台原生桥接';
const MARK = '（F4 编排人工裁决';
const KEEP_MARK = '（开发者显式搁置，待后续裁决）';

/** @returns {{moved:Array,kept:Array,unchanged:number}} */
export function applyAdjudications(reportPath, decisions) {
  const report = JSON.parse(readFileSync(reportPath, 'utf8'));
  const moved = [];
  const kept = [];
  let unchanged = 0;
  for (const d of decisions) {
    if (!d.chosen) continue;
 // bd 类（⑥业务决策）：桥接选择移桶④（——F3 消费④桶生成六件套）；其余仅 reason 标注（三产物口径一致）
    if (d.source === 'hms-closed' || d.source === 'kit-closed' || d.source === 'ohos-unique') {
      const key = d.point.replace(/^bd:/, '');
      const [module, symbol] = key.split('::');
      const idx = (report.adaptation.business_decision ?? []).findIndex((it) => it.module === module && it.symbol === symbol);
      if (d.chosen === BD_BRIDGE_CHOICE) {
        if (idx < 0) { unchanged++; continue; } // 已移桶（重入幂等）或项不存在
        const item = report.adaptation.business_decision[idx];
        if (item.reason && item.reason.includes(MARK)) { unchanged++; continue; } // 已裁决防重标
        item.reason = (item.reason ?? '') + `${MARK}：⑥→④降级桥接（${BD_BRIDGE_CHOICE}，触发 F3 六件套生成），见 MigrationState.decisions）`;
        report.adaptation.business_decision.splice(idx, 1);
        report.adaptation.degraded_bridge.push(item);
        moved.push(`${key}→degraded_bridge`);
        continue;
      }
      if (idx >= 0 && !(report.adaptation.business_decision[idx].reason ?? '').includes(MARK)) {
        report.adaptation.business_decision[idx].reason = (report.adaptation.business_decision[idx].reason ?? '') + `${MARK}：⑥→${d.chosen}，见 MigrationState.decisions）`;
      }
      continue;
    }
    if (d.source !== 'unknown') continue;
    const key = d.point.replace(/^uk:/, '');
    const [module, symbol] = key.split('::');
    const idx = (report.adaptation.unknown ?? []).findIndex((it) => it.module === module && it.symbol === symbol);
    if (idx < 0) { unchanged++; continue; } // 已移桶（重入幂等）或项不存在
    const item = report.adaptation.unknown[idx];
    if (item.reason && item.reason.includes(MARK)) { unchanged++; continue; } // 已裁决防重标
    if (d.chosen === 'keep_unknown') {
      item.reason = (item.reason ?? '') + KEEP_MARK;
      report.adaptation.unknown[idx] = item;
      kept.push(key);
      continue;
    }
    if (!LABEL[d.chosen]) continue; // 非法值不写（askDecision 已拦，双保险）
    item.reason = (item.reason ?? '') + `${MARK}：unknown→${LABEL[d.chosen]}，见 MigrationState.decisions）`;
    report.adaptation.unknown.splice(idx, 1);
    report.adaptation[d.chosen].push(item);
    moved.push(`${key}→${d.chosen}`);
  }
  const tmp = `${reportPath}.tmp-${process.pid}`;
  writeFileSync(tmp, JSON.stringify(report, null, 2) + '\n', 'utf8');
  renameSync(tmp, reportPath);
  return { moved, kept, unchanged };
}
