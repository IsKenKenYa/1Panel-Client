import { spawnSync } from 'node:child_process';

/**
 * SkillInvoker：三 Skill 本地子进程调用——唯一子进程出口（白名单核验点）。
 * 超时 watchdog：默认 300000ms，环境变量 ARKUIX_SKILL_TIMEOUT_MS 可覆盖（对齐 F1 先例）。
 * TTY 交互透传：interactive=true 时 stdio=inherit（子 Skill 的确认关口直达终端，用户可输入应答）。
 */

export function defaultTimeoutMs() {
  const env = Number(process.env.ARKUIX_SKILL_TIMEOUT_MS);
  return Number.isInteger(env) && env > 0 ? env : 300000;
}

/**
 * @param {{cmd:string,args:string[],cwd?:string,timeoutMs?:number,interactive?:boolean}} spec
 * @returns {{exitCode:number,timedOut:boolean,stdout:string,stderr:string}}
 */
export function invokeSkill({ cmd, args, cwd, timeoutMs, interactive }) {
  const timeout = timeoutMs ?? defaultTimeoutMs();
  const spawnOpts = interactive
    ? { cwd, timeout, stdio: 'inherit' } // TTY：子进程直连终端（SDK 确认/分类确认等关口可交互）
    : { encoding: 'utf8', cwd, timeout }; // 非 TTY：捕获输出（CI/自动化语义）
  const r = spawnSync(cmd, args, spawnOpts);
  if (r.error && r.error.code === 'ETIMEDOUT' || r.signal === 'SIGTERM') {
    return { exitCode: 124, timedOut: true, stdout: r.stdout ?? '', stderr: (r.stderr ?? '') + `\n子进程超时（${timeout}ms）被终止` };
  }
  if (r.error) {
    return { exitCode: 127, timedOut: false, stdout: '', stderr: `子进程启动失败：${r.error.message}` };
  }
  return { exitCode: r.status ?? 1, timedOut: false, stdout: r.stdout ?? '', stderr: r.stderr ?? '' };
}

/**
 * 三阶段→子 Skill CLI 命令定位（--skill-dir 指向同族根目录； 参数面对齐同族先例）。
 * 决策应答经 decisionMap 映射为子 Skill 非交互参数（决策 → 参数注入）。
 */
export function skillCommandFor(stage, skillDir) {
  const map = {
    scan: ['node', `${skillDir}/arkuix-interface-scan/scripts/scan.js`],
    skeleton: ['node', `${skillDir}/arkuix-migration-skeleton/scripts/skeleton.js`],
    bridge: ['node', `${skillDir}/arkuix-bridge-codegen/scripts/bridge.js`],
  };
  return map[stage] ?? null;
}
