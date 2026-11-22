#!/usr/bin/env node
/** mock-skeleton：F1 替身。位置参数根目录后第一个非 -- 参数为模式（modify/new）；产物= skeleton-result */
import { writeFileSync, mkdirSync, appendFileSync } from 'node:fs';
import { join } from 'node:path';

let out = './arkuix-orchestrate';
let mode = 'modify';
let scaffoldFrom = '';
let strict = false;
let modifyEntry = '';
let migrateConfigs = '';
let compileSdk = '';
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '--out') out = argv[++i];
  else if (argv[i] === '--scan-report') ++i;
  else if (argv[i] === '--modify-entry') modifyEntry = argv[++i]; // ：编排器 entry 透传断言面
  else if (argv[i] === '--migrate-configs') migrateConfigs = argv[++i]; // 编排器配置迁移决策透传断言面（值型 flag——须消费，否则值会误当位置模式参数）
  else if (argv[i] === '--compile-sdk') compileSdk = argv[++i]; // Compile SDK 版本门透传断言面（值型 flag，同上须消费）
  else if (argv[i] === '--scaffold-from') {
    const v = argv[i + 1];
    if (v && !v.startsWith('-')) { scaffoldFrom = v; i++; } // 指定归档目录
    else scaffoldFrom = 'builtin'; // 无值 → F1 内置归档
  }
  else if (argv[i] === '--strict-crossplatform') strict = true;
  else if (!argv[i].startsWith('-') && argv[i - 1] && !['--out', '--scan-report', '--modify-entry', '--migrate-configs', '--compile-sdk'].includes(argv[i - 1]) && argv[i] !== argv[0]) mode = argv[i];
}

if (process.env.ARKUIX_MOCK_LOG) appendFileSync(process.env.ARKUIX_MOCK_LOG, `skeleton(${mode}${scaffoldFrom ? `,scaffold-from=${scaffoldFrom}` : ''}${strict ? ',strict-crossplatform' : ''}${modifyEntry ? `,modify-entry=${modifyEntry}` : ''}${migrateConfigs ? `,migrate-configs=${migrateConfigs}` : ''}${compileSdk ? `,compile-sdk=${compileSdk}` : ''})\n`);
if (process.env.ARKUIX_MOCK_SKELETON === 'fail') { console.error('mock-skeleton 模拟失败'); process.exit(5); }
 //  确认门模拟：无 --yes 且 ARKUIX_MOCK_SKELETON=confirm → 退出码 6（复刻 F1  未授权）
if (process.env.ARKUIX_MOCK_SKELETON === 'confirm' && !argv.includes('--yes')) {
  console.error('非交互环境执行 modify 需 --yes 跳过计划改动清单确认（未提供则按用户中止，退出码 6）。');
  process.exit(6);
}
 // 配置迁移强确认门复刻：new 模式缺 --migrate-configs → 退出码 6（非 TTY 不代答；编排器转码 4）
if (mode === 'new' && !migrateConfigs) {
  console.error('new 模式需显式确认是否迁移源工程配置文件（未确认不执行任何生成动作）。');
  console.error('请以 --migrate-configs <yes|no> 重跑（编排器：--answer migrate_configs=yes|no）');
  process.exit(6);
}
 // Compile SDK 版本强确认门复刻（同款不代答）：new 模式缺 --compile-sdk → 退出码 6
if (mode === 'new' && !compileSdk) {
  console.error('new 模式需显式确认 Compile SDK 版本（scaffold 编译基线；未确认不执行任何生成动作）。');
  console.error('支持版本：10 / 11 / 12 / 13 / 14 / 15 / 16 / 17 / 18 / 19 / 20 / 21 / 22 / 23 / 24 / 26.0.0');
  console.error('推荐：★ 最高 26.0.0；请以 --compile-sdk <版本> 重跑（编排器：--answer compile_sdk=<版本>）');
  process.exit(6);
}

mkdirSync(out, { recursive: true });
const result = {
  schema_version: 1,
  mode,
  platform: 'both',
  android_shell: mode === 'modify' ? '.arkui-x/android/' : 'android/',
  ios_shell: mode === 'modify' ? '.arkui-x/ios/' : 'ios/',
  shared_arkts_dir: mode === 'modify' ? 'entry' : 'ets_stage/source/entry',
  environment: {
    android: { ready: true, missing: [] },
    ios: { ready: false, missing: ['需 macOS'] },
    arkui_x_sdk: { detected: true, version: '26.0.0', modify_available: true },
  },
};
writeFileSync(join(out, 'skeleton-result.json'), JSON.stringify(result, null, 2) + '\n');
console.log(`mock-skeleton 完成（mode=${mode}${migrateConfigs ? `,migrate-configs=${migrateConfigs}` : ''}${compileSdk ? `,compile-sdk=${compileSdk}` : ''}）`);
