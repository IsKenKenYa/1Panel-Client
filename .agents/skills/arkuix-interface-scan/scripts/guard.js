#!/usr/bin/env node
/** guard：单测与 benchmark 无条件全跑并汇总退出码——单项失败不遮蔽另一项的全量信号 */
import { spawnSync } from 'node:child_process';

const npm = process.platform === 'win32' ? 'npm.cmd' : 'npm';
const steps = [['test', '单测'], ['benchmark', 'benchmark']];
const results = [];
for (const [script, label] of steps) {
  console.log(`\n━━━ guard ▸ npm run ${script}（${label}）━━━`);
  const r = spawnSync(npm, ['run', script], { stdio: 'inherit', shell: true });
  results.push([label, r.status === 0]);
}
console.log('\n━━━ guard 汇总 ━━━');
for (const [label, ok] of results) console.log(`${ok ? '✔' : '✖'} ${label}`);
process.exit(results.some(([, ok]) => !ok) ? 1 : 0);
