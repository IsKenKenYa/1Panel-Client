#!/usr/bin/env node
/**
 * mock-ace：arkui-x toolchains `ace` 命令替身（benchmark 确定性测试入口）
 * 行为由环境变量控制：
 *   MOCK_ACE_BEHAVIOR：success（默认）— modify 读 stdin 平台选择（1/2/3）后按选项产壳；create 产 scaffold
 *                      fail            — modify 报 Operation failed 退出 1
 *                      timeout         — modify 挂起 60s（触发调用方超时/ARKUIX_ACE_TIMEOUT_MS 覆盖核验）
 *   MOCK_ACE_VERSION：check 输出的 ArkUI-X SDK 版本（默认 26.0.0；低版本场景如 21 → modify_available=false，门槛 API 22）
 */
import { mkdirSync, writeFileSync, appendFileSync, existsSync as fsExists } from 'node:fs';
import { join } from 'node:path';

const behavior = process.env.MOCK_ACE_BEHAVIOR || 'success';
const version = process.env.MOCK_ACE_VERSION || '26.0.0';
const cmd = process.argv[2];

if (cmd === 'create') {
 // r3 布局校准 + 6 题交互仿真：部分喂答（<6 答）时打印含 Compile SDK 菜单的题面后
 // 以非零退出模拟 readline 崩溃（供菜单发现探针解析）；完整 6 答成功产出真实布局
  let input = '';
  process.stdin.on('data', (d) => { input += d; });
  process.stdin.on('end', () => {
    const answers = input.split('\n');
    if (answers.length < 6) {
      console.log('? Enter the project name(mock): ');
      console.log('? Enter the bundleName (com.example.mock): ');
      console.log('? Enter the runtimeOS (1: OpenHarmony; 2: HarmonyOS): ');
      console.log('? Please select the Complie SDk (1: 10; 2: 11; 3: 12; 4: 13; 5: 14; 6: 15; 7: 16; 8: 17; 9: 18; 10: 19; 11: 20; 12: 21; 13: 22; 14: 23; 15: 24; 16: 26.0.0): ');
      process.exit(1);
    }
    const out = process.argv[3];
    mkdirSync(join(out, '.arkui-x', 'android', 'app'), { recursive: true });
    writeFileSync(join(out, '.arkui-x', 'android', 'build.gradle'), '// mock gradle\n');
    mkdirSync(join(out, '.arkui-x', 'ios', 'app'), { recursive: true });
    mkdirSync(join(out, 'entry', 'src', 'main'), { recursive: true });
    console.log('create success (layout=.arkui-x)');
  });
} else if (cmd === 'modify') {
  if (behavior === 'fail') {
    console.error('Error: Operation failed. Go to your project directory and try again.');
    process.exit(1);
  }
  if (behavior === 'timeout') {
    setTimeout(() => process.exit(0), 60000);
  } else {
    let input = '';
    process.stdin.on('data', (d) => { input += d; });
    process.stdin.on('end', () => {
 // 平台应答映射：1=双平台 / 2=仅 Android / 3=仅 iOS
      const answer = input.trim().charAt(0);
      const p = process.cwd();
      if (answer === '1' || answer === '2') {
        mkdirSync(join(p, '.arkui-x', 'android', 'app'), { recursive: true });
        writeFileSync(join(p, '.arkui-x', 'android', 'build.gradle'), '// mock gradle\n');
        writeFileSync(join(p, '.arkui-x', 'android', 'settings.gradle'), '// mock settings\n');
      }
      if (behavior === 'success-rewrite') {
 //  测试载体：模拟真实 ace 改写既有构建文件（实测漏报点）
        for (const f of ['hvigorfile.ts', 'hvigor/hvigor-config.json5']) {
          if (fsExists(join(p, f))) appendFileSync(join(p, f), '\n// ace inject\n');
        }
      }
      if (answer === '1' || answer === '3') {
        mkdirSync(join(p, '.arkui-x', 'ios', 'app'), { recursive: true });
        mkdirSync(join(p, '.arkui-x', 'ios', 'app.xcodeproj'), { recursive: true });
      }
      if (!['1', '2', '3'].includes(answer)) {
        console.error('no platform answer');
        process.exit(3);
      }
      mkdirSync(join(p, '.arkui-x'), { recursive: true });
      writeFileSync(join(p, '.arkui-x', 'arkui-x-config.json5'), '{}\n'); // 对齐真实 ace 产物
 //  测试载体：对齐真 ace 26.0.0 的必办 WARN（成功路径 stdout 携带，供调用方沉淀断言）
      console.log("WARN: arkui-x project must delete the 'useNormalizedOHMUrl' Setting Items in build-profile.json5");
      console.log(`modify HarmonyOS project to ArkUI-X project success! (platform answer=${answer})`);
      process.exit(0);
    });
  }
} else if (cmd === 'check') {
  console.log(`[√] ArkUI-X (ArkUI-X SDK version ${version})`);
  console.log('[√] Android toolchains (mock)');
  console.log('[√] Xcode (mock)');
} else {
  console.error(`mock-ace: unsupported command ${cmd}`);
  process.exit(2);
}
