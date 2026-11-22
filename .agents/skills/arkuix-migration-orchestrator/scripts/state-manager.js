import { mkdirSync, writeFileSync, renameSync, existsSync, readFileSync } from 'node:fs';
import { join } from 'node:path';

/**
 * StateManager：六态状态机
 * + MigrationState单点原子写盘+ checkpoint 快照/回滚。
 */

export const STAGES = ['scan', 'skeleton', 'bridge', 'report'];
export const STATE_FILE = 'migration-state.json';
export const CHECKPOINT_DIR = 'checkpoints';

/** 合法状态迁移矩阵（design 算法与状态机） */
export const TRANSITIONS = {
  Assessing: ['Planning', 'Error'],
  Planning: ['AwaitingConfirm', 'Applying'],
  AwaitingConfirm: ['Applying', 'Error'],
  Applying: ['Checkpointing', 'Interrupted'],
  Checkpointing: ['Planning', 'Reporting'],
  Reporting: ['Done'],
};

export class StateManager {
  constructor(outDir) {
    this.outDir = outDir;
    this.internal = 'Assessing';
    this.state = null;
  }

  static fresh() {
    const stages = {};
    for (const s of STAGES) stages[s] = { status: 'pending', artifacts: [] };
    return { schema_version: 1, stages, current_stage: 'scan', decisions: [], checkpoints: [] };
  }

  /** 加载既有 MigrationState（断点续跑）；无则新建 */
  load() {
    const file = join(this.outDir, STATE_FILE);
    if (existsSync(file)) {
      this.state = JSON.parse(readFileSync(file, 'utf8'));
    } else {
      this.state = StateManager.fresh();
      this.flush();
    }
    return this.state;
  }

  /** 状态机迁移（非法迁移抛错， 单点） */
  transition(to) {
    const legal = TRANSITIONS[this.internal] ?? [];
    if (!legal.includes(to)) throw new Error(`非法状态迁移：${this.internal}→${to}`);
    this.internal = to;
  }

  /** 原子写盘（tmp+rename：中断不残留半成品） */
  flush() {
    const file = join(this.outDir, STATE_FILE);
    mkdirSync(this.outDir, { recursive: true });
    const tmp = `${file}.tmp-${process.pid}`;
    writeFileSync(tmp, JSON.stringify(this.state, null, 2) + '\n', 'utf8');
    renameSync(tmp, file);
  }

  markSkipped(stages) {
    for (const s of stages) if (this.state.stages[s].status === 'pending') this.state.stages[s].status = 'skipped';
    this.flush();
  }

  markRunning(stage) {
    this.state.stages[stage].status = 'running';
    this.state.current_stage = stage;
    this.flush();
  }

  /** 阶段完成：落账+checkpoint 快照 */
  markDone(stage, artifacts, exitCode = 0) {
    this.state.stages[stage] = { status: 'done', artifacts, exit_code: exitCode };
    this.state.current_stage = stage;
    const snap = join(CHECKPOINT_DIR, `${stage}.json`);
    mkdirSync(join(this.outDir, CHECKPOINT_DIR), { recursive: true });
    writeFileSync(join(this.outDir, snap), JSON.stringify(this.state, null, 2) + '\n', 'utf8');
    this.state.checkpoints.push({ stage, snapshot: snap, at: new Date().toISOString() });
    this.flush();
  }

  /** 中断落账（失败阶段+原因） */
  markInterrupted(stage, reason) {
    this.state.stages[stage].status = 'failed';
    this.state.interrupted_at = `${stage}:${reason}`;
    this.flush();
  }

  /** 决策落账（未确认不写 chosen） */
  recordDecision(entry) {
    const exists = this.state.decisions.find((d) => d.point === entry.point);
    if (exists) Object.assign(exists, entry);
    else this.state.decisions.push(entry);
    this.flush();
  }

  /** 回滚至目标阶段快照（其后 stages 重置为快照值；产物文件物理保留逻辑失效） */
  rollbackTo(stage) {
    const cp = [...this.state.checkpoints].reverse().find((c) => c.stage === stage);
    if (!cp) return { ok: false, reason: `无 ${stage} 阶段 checkpoint` };
    const snapPath = join(this.outDir, cp.snapshot);
    if (!existsSync(snapPath)) return { ok: false, reason: `快照文件缺失：${cp.snapshot}` };
    this.state = JSON.parse(readFileSync(snapPath, 'utf8'));
 // markDone 的快照在 status=done 之后落盘——直接恢复会导致目标阶段仍 done
 // 不重跑（"已回滚但啥也没发生"）。回滚语义=续跑从目标阶段开始 → 强制重置为 pending
    this.state.stages[stage] = { status: 'pending', artifacts: [] };
    this.flush();
    return { ok: true };
  }
}
