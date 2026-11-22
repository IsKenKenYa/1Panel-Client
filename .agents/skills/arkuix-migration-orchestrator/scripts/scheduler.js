import { STAGES } from './state-manager.js';

/** StageScheduler：固定阶段序+阶段子集 */

/** 上游依赖（阶段→直接上游）：skeleton/bridge 依赖 scan；report 无硬依赖（汇总已有） */
const PREDEPS = { skeleton: ['scan'], bridge: ['scan'], report: [] };

export function planStages(selected) {
  if (selected !== null && selected !== undefined && selected.length === 0) {
    return { ok: false, reason: '阶段列表为空（--stages 须为非空子集，或省略以全流程执行）' };
  }
  const list = Array.isArray(selected) && selected.length > 0 ? selected : [...STAGES];
  for (const s of list) {
    if (!STAGES.includes(s)) return { ok: false, reason: `非法阶段名：${s}（合法：${STAGES.join('/')}）` };
  }
  const uniq = [...new Set(list)];
 // 执行序固定：按 STAGES 全序过滤所选子集
  return { ok: true, stages: STAGES.filter((s) => uniq.includes(s)) };
}

/**
 * 前置缺失检查（场景 5/退出码 3 语义源）：
 * 所选阶段的上游既不在所选集内、也未在 MigrationState 中 done → 缺失。
 */
export function missingPreconditions(plannedStages, state) {
  const missing = [];
  for (const s of plannedStages) {
    for (const dep of PREDEPS[s] ?? []) {
      const inPlan = plannedStages.includes(dep);
      const doneAlready = state?.stages?.[dep]?.status === 'done';
      if (!inPlan && !doneAlready) missing.push(`${s} 需要 ${dep} 产物（未选择且未产出）`);
    }
  }
  return missing;
}

/** 待执行阶段：计划内且未 done/skipped（续跑时跳过已通过阶段） */
export function pendingStages(plannedStages, state) {
  return plannedStages.filter((s) => !['done', 'skipped'].includes(state.stages[s].status));
}
