#!/usr/bin/env node
/** mock-scan：F2 替身（VM 测试入口）。行为开关（环境变量）：ARKUIX_MOCK_SCAN=fail→退出码 5；timeout→挂起。产物=fixture scan 报告 */
import { readFileSync, writeFileSync, mkdirSync, appendFileSync, existsSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const here = dirname(fileURLToPath(import.meta.url));
let out = './arkuix-orchestrate';
let sdkDir = '';
const argv = process.argv.slice(2);
for (let i = 0; i < argv.length; i++) {
  if (argv[i] === '--out') out = argv[i + 1];
  else if (argv[i] === '--sdk-dir') sdkDir = argv[i + 1]; // ：透传可见性（--sdk-dir 注入断言）
}

if (process.env.ARKUIX_MOCK_LOG) appendFileSync(process.env.ARKUIX_MOCK_LOG, `scan${argv.includes('--force-no-kits') ? '(--force-no-kits)' : ''}\n`);
if (process.env.ARKUIX_MOCK_SCAN === 'fail') { console.error('mock-scan 模拟失败'); process.exit(5); }
if (process.env.ARKUIX_MOCK_SCAN === 'timeout') { setTimeout(() => {}, 60000); }
 //  确认门模拟（询问先行复刻）：未传 --sdk-dir → 询问先行指引（查找方法+参考候选）退出码 4
if (process.env.ARKUIX_MOCK_SCAN === 'confirm-sdk' && !sdkDir) {
  console.error('未提供 SDK 判定源——请向开发者确认本机 OpenHarmony SDK 路径后，以 --sdk-dir <目录> 重跑（编排器：--answer sdk=<目录>）；未经确认，不产出判定。');
  console.error('SDK 路径查找方法：');
  console.error('  · DevEco Studio：设置界面（Settings/Preferences → SDK）页面可查看本机 SDK 安装位置');
  console.error('  · 常见默认位置：macOS ~/Library/OpenHarmony/Sdk、Windows %LOCALAPPDATA%\\OpenHarmony\\Sdk');
  console.error('  · 有效目录特征：版本级目录（含 ets/api 的 @ohos.*.d.ts）');
  console.error('本机探测到的参考候选（★=含 kits，可直接选用其一）：');
  console.error('  ★ /mock/sdk/26.0.0（版本 26.0.0，kits √，来源 default:mock） ← 推荐（最新含 kits）');
  console.error('   /mock/sdk/10（版本 10，无 kits，来源 default:mock）');
  process.exit(4);
}

mkdirSync(out, { recursive: true });
const fixture = JSON.parse(readFileSync(join(here, '..', '..', '..', 'fixture-project', 'scan-fixture.json'), 'utf8'));
if (sdkDir) fixture.sdk = { path: sdkDir, version: 'mock', confirmed: true, origin: 'explicit' }; //  断言面
writeFileSync(join(out, 'scan-report.json'), JSON.stringify(fixture, null, 2) + '\n');
console.log('mock-scan 完成');
