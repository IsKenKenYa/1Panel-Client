#!/usr/bin/env node
/**
 * make-scaffold-archive.js —— 一次性归档组装工具（维护者用）
 *
 * 从 ArkUI-X SDK 26.0.0 toolchains 的官方模板组装"标准答案" scaffold 归档：
 *   项目名 arkuixapp / bundleName com.example.arkuixapp / Compile SDK 16(=26.0.0)
 *   / runtimeOS OpenHarmony / 双平台 / Framework CocoaPods
 * 行为按 ace 工具 CLI 交互实证复刻（GM/KM/XM/createPackageFile/modifyOpenHarmonyOSConfig）：
 *   - 复制 ohos_stage + ets_stage/source + android + cocoapods/ios
 *   - XM 占位符替换（固定清单）
 *   - java 包目录按 bundleName 分包重组
 *   - build-profile.json5 SDK 六元组映射（26.0.0，字符串形态）
 *   - buildArkTS 系列环境路径以占位符固化（__PROJECT_PATH__/__OHPM_PATH__/__ARKUIX_SDK_PATH__）
 *   - 剔除 xcuserdata（Xcode UI 状态，非模板内容）
 * 边界与扩展路径（详见 SKILL.md"归档物化未对标 ace create 的边界"）：
 *   - 签名：保留模板 Manual（ace 会写本机证书；如需 Automatic → 组装后替换 pbxproj 签名三行）
 *   - 参数集：仅 26.0.0/OpenHarmony/双平台/CocoaPods/app；HarmonyOS/其他 SDK 版本/Native Manual/
 *     library/plugin_napi → 本工具加参数再生成对应归档（PM 分支/ON() 映射/模板目录切换）
 *   - buildArkTS 三件从 26.0.0 参照产物提取（ace 动态生成，模板无源；占位符固化后由 materialize 注入）
 * 用法: node scripts/make-scaffold-archive.js <ArkUI-X SDK toolchains/ace_tools 路径> <输出归档目录>
 */
import { cpSync, existsSync, mkdirSync, readFileSync, rmSync, writeFileSync, readdirSync, renameSync, statSync } from 'node:fs';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';

const aceToolsDir = process.argv[2];
const outDir = process.argv[3];
// 可选：参照产物目录（ace create 26.0.0 直出），用于提取动态生成的 buildArkTS 三件（复杂模板不复刻）
const refDir = process.argv[4];
if (!aceToolsDir || !outDir || !existsSync(join(aceToolsDir, 'templates'))) {
  console.error('用法: node make-scaffold-archive.js <ace_tools 目录(含 templates/)> <输出归档目录> [参照产物目录]');
  process.exit(2);
}

const T = join(aceToolsDir, 'templates');
const NAME = 'arkuixapp';
const BUNDLE = 'com.example.arkuixapp';

rmSync(outDir, { recursive: true, force: true });
mkdirSync(outDir, { recursive: true });

// KM：模板组装（app 模板 + 双平台 + CocoaPods iOS）
cpSync(join(T, 'ohos_stage'), outDir, { recursive: true });
cpSync(join(T, 'ets_stage', 'source'), outDir, { recursive: true });
mkdirSync(join(outDir, '.arkui-x'), { recursive: true });
cpSync(join(T, 'android'), join(outDir, '.arkui-x', 'android'), { recursive: true });
cpSync(join(T, 'cocoapods', 'ios'), join(outDir, '.arkui-x', 'ios'), { recursive: true });
// KM 内的重命名：AppDelegate_stage → AppDelegate
renameSync(join(outDir, '.arkui-x/ios/app/AppDelegate_stage.m'), join(outDir, '.arkui-x/ios/app/AppDelegate.m'));
renameSync(join(outDir, '.arkui-x/ios/app/AppDelegate_stage.h'), join(outDir, '.arkui-x/ios/app/AppDelegate.h'));
writeFileSync(join(outDir, '.arkui-x', 'arkui-x-config.json5'), readFileSync(join(T, 'arkui-x-config.json5')));

// CocoaPods Podfile（pod init 标准空壳，固化；依赖在编译期 pod install 解析）
writeFileSync(join(outDir, '.arkui-x', 'ios', 'Podfile'), [
  '# Uncomment the next line to define a global platform for your project',
  '# platform :ios, \'9.0\'', '',
  'target \'app\' do',
  '  # Comment the next line if you don\'t want to use dynamic frameworks',
  '  use_frameworks!', '',
  '  # Pods for app', '',
  'end', ''
].join('\n'));

// XM：占位符替换（固定清单；replaceInfo 语义=逐行 replaceAll）
const iosName = BUNDLE.split('.').at(-1).toLowerCase();
const replacements = [
  ['AppScope/resources/base/element/string.json', 'projectName', NAME],
  ['AppScope/app.json5', 'appBunduleName', BUNDLE],
  ['oh-package.json5', 'packageInfo', NAME],
  ['entry/src/main/resources/base/element/string.json', 'module_ability_name', 'EntryAbility'],
  ['entry/src/main/resources/en_US/element/string.json', 'module_ability_name', 'EntryAbility'],
  ['entry/src/main/resources/zh_CN/element/string.json', 'module_ability_name', 'EntryAbility'],
  ['entry/src/main/module.json5', 'module_ability_name', 'EntryAbility'],
  ['entry/src/main/module.json5', 'module_name', 'entry'],
  ['entry/src/ohosTest/module.json5', 'module_test_name', 'entry_test'],
  ['entry/src/ohosTest/resources/base/element/string.json', 'module_test_name', 'entry_test_desc'],
  ['entry/oh-package.json5', 'module_name', 'entry'],
 // Android
  ['.arkui-x/android/settings.gradle', 'appName', NAME],
  ['.arkui-x/android/app/src/main/res/values/strings.xml', 'appName', NAME],
  ['.arkui-x/android/app/src/main/AndroidManifest.xml', 'packageName', BUNDLE],
  ['.arkui-x/android/app/build.gradle', 'packageName', BUNDLE],
  ['.arkui-x/android/app/src/main/java/MainActivity.java', 'package packageName', `package ${BUNDLE}`],
  ['.arkui-x/android/app/src/main/java/MyApplication.java', 'package packageName', `package ${BUNDLE}`],
  ['.arkui-x/android/app/src/androidTest/java/ExampleInstrumentedTest.java', 'package packageName', `package ${BUNDLE}`],
  ['.arkui-x/android/app/src/test/java/ExampleUnitTest.java', 'package packageName', `package ${BUNDLE}`],
  ['.arkui-x/android/app/src/main/java/MainActivity.java', 'ArkUIInstanceName', `${BUNDLE}:entry:EntryAbility:`],
  ['.arkui-x/android/app/src/main/java/MainActivity.java', 'MainActivity', 'EntryEntryAbilityActivity'],
  ['.arkui-x/android/app/src/main/AndroidManifest.xml', 'MainActivity', 'EntryEntryAbilityActivity'],
 // iOS
  ['.arkui-x/ios/app.xcodeproj/project.pbxproj', 'bundleIdentifier', BUNDLE],
  ['.arkui-x/ios/app/AppDelegate.m', 'packageName', BUNDLE],
  ['.arkui-x/ios/app/Info.plist', '{{CFBundleName}}', iosName],
  ['.arkui-x/ios/app/Info.plist', '{{CFBundleDisplayName}}', iosName.slice(0, 1).toUpperCase() + iosName.slice(1)]
];
for (const [rel, from, to] of replacements) {
  const file = join(outDir, rel);
  if (!existsSync(file)) { console.error(`警告: 模板缺文件 ${rel}`); continue; }
  writeFileSync(file, readFileSync(file, 'utf8').split('\n').map((l) => l.includes(from) ? l.replaceAll(from, to) : l).join('\n'));
}

// createPackageFile：java 平铺文件移入 bundleName 分包目录 + MainActivity 重命名（ace 同款）
renameSync(join(outDir, '.arkui-x/android/app/src/main/java/MainActivity.java'),
  join(outDir, '.arkui-x/android/app/src/main/java/EntryEntryAbilityActivity.java'));
for (const base of ['app/src/main/java', 'app/src/test/java', 'app/src/androidTest/java']) {
  const dir = join(outDir, '.arkui-x/android', base);
  if (!existsSync(dir)) continue;
  let target = dir;
  for (const part of BUNDLE.split('.')) { target = join(target, part); mkdirSync(target, { recursive: true }); }
  for (const entry of readdirSync(dir)) {
    const full = join(dir, entry);
    if (statSync(full).isFile()) { writeFileSync(join(target, entry), readFileSync(full)); rmSync(full); }
  }
}

// jM（OpenHarmony + SDK 16）：build-profile SDK 字段映射（26.0.0 字符串形态，runtimeOS 保持 OpenHarmony）
const bpPath = join(outDir, 'build-profile.json5');
let bp = readFileSync(bpPath, 'utf8');
bp = bp.replaceAll('"compileSdkVersion": 10', '"compileSdkVersion": "26.0.0"')
  .replaceAll('"compatibleSdkVersion": 10', '"compatibleSdkVersion": "26.0.0"');
writeFileSync(bpPath, bp);

// jM 深加工（o>=12）：oh-package 注入 modelVersion；hvigor-config 重写为 26.0.0 形态（插件 4.24.2）
const ohpPath = join(outDir, 'oh-package.json5');
writeFileSync(ohpPath, readFileSync(ohpPath, 'utf8').replace(/^{\n/, '{\n  "modelVersion": "26.0.0",\n'));
writeFileSync(join(outDir, 'hvigor', 'hvigor-config.json5'), [
  '{',
  '  "modelVersion": "26.0.0",',
  '  "dependencies": {',
  '    "@ohos/hvigor-ohos-arkui-x-plugin": "4.24.2"',
  '  },',
  '  "execution": {},',
  '  "logging": {},',
  '  "debugging": {}',
  '}'
].join('\n'));

// ：对齐 ace create（API≥12 = modelVersion 工程）的 hvigor 布局——删除模板自带的三件
// （hvigor/hvigor-wrapper.js + 根 hvigorw + hvigorw.bat）。旧 wrapper 与 hvigor 6.x schema /
// Node 24（spawn .cmd 无 shell 被拒 + pnpm 7.30 HTTP 崩）三重不兼容；modelVersion 工程的
// hvigorw 自举由 ace build（Integration IDE hvigorw --sync）或 DevEco 完成，工程不内置 wrapper。
for (const stale of ['hvigor/hvigor-wrapper.js', 'hvigorw', 'hvigorw.bat']) {
  const p = join(outDir, stale);
  if (existsSync(p)) rmSync(p, { force: true });
}

// BM（createAndroidTaskInBuildGradle）：build.gradle 注入 ArkTSBuildTask hook
const gradlePath = join(outDir, '.arkui-x/android/app/build.gradle');
const GRADLE_HOOK = [
  '',
  '',
  ' //Select whether you want to execute the compile arkts script.',
  '    def configBuildFlag = false',
  '',
  '    task ArkTSBuildTask {',
  '      preBuild.dependsOn ArkTSBuildTask',
  '      doLast {',
  '        if (configBuildFlag) {',
  '          def os = System.getProperty("os.name").toLowerCase()',
  '          if (os.contains("win")) {',
  '            exec {',
  "              commandLine 'cmd', '/c', '.\\\\buildArkTS'",
  "              workingDir file( project.projectDir.getAbsolutePath() + '\\\\..' )",
  '            }',
  '          } else {',
  '            exec {',
  "              commandLine 'sh', '-c', 'chmod +x ./buildArkTS && ./buildArkTS'",
  "              workingDir file( project.projectDir.getAbsolutePath() + '/..' )",
  '            }',
  '          }',
  '        }',
  '      }',
  '    }'
].join('\n');
let gradle = readFileSync(gradlePath, 'utf8');
gradle = gradle.replace(/(buildToolsVersion "[^"]*")/, `$1\n${GRADLE_HOOK}`);
writeFileSync(gradlePath, gradle);

// （createIosScriptInPbxproj）：buildPhases 头插 Run Script 引用 + 文件尾前插 ShellScript 段
const pbxPath = join(outDir, '.arkui-x/ios/app.xcodeproj/project.pbxproj');
const PBX_ID = 'DD0D56CB443B43659ABE95F1';
const PBX_HOOK = `/* Begin PBXShellScriptBuildPhase section */
      ${PBX_ID} /* Run Script */ = {
          isa = PBXShellScriptBuildPhase;
          buildActionMask = 2147483647;
          files = (
          );
          inputPaths = (
          );
          name = "Run My Script";
          outputPaths = (
          );
          runOnlyForDeploymentPostprocessing = 0;
          shellPath = "/bin/sh";
          shellScript = '# Select whether you want to execute the compile arkts script.
configBuildFlag=false
if [ "$configBuildFlag" = "false" ]; then
\texit 0
fi
sh \${SRCROOT}/buildArkTS.sh';
      };
/* End PBXShellScriptBuildPhase section */`;
let pbx = readFileSync(pbxPath, 'utf8');
pbx = pbx.replace(/(buildPhases = \(\n)/, `$1\t\t\t\t${PBX_ID} /* Run Script */,\n`);
pbx = pbx.replace(/(\/\* End PBXNativeTarget section \*\/\n)/, `$1\n${PBX_HOOK}\n`);
writeFileSync(pbxPath, pbx);

// WM/buildArkTS 三件（ace 动态生成，模板无源）——从参照产物提取 + 占位符固化
for (const rel of ['.arkui-x/android/buildArkTS', '.arkui-x/android/buildArkTS.bat', '.arkui-x/ios/buildArkTS.sh']) {
  const ref = refDir ? join(refDir, rel) : '';
  const file = join(outDir, rel);
  if (ref && existsSync(ref)) {
    const content = readFileSync(ref, 'utf8')
      .replace(/^project_path=.*$/m, 'project_path="__PROJECT_PATH__"')
      .replace(/^ohpm_path=.*$/m, 'ohpm_path="__OHPM_PATH__"')
      .replace(/^arkuiXSdkPath=.*$/m, 'arkuiXSdkPath="__ARKUIX_SDK_PATH__"');
    writeFileSync(file, content);
  } else if (existsSync(file)) {
    writeFileSync(file, readFileSync(file, 'utf8')
      .replace(/^project_path=.*$/m, 'project_path="__PROJECT_PATH__"')
      .replace(/^ohpm_path=.*$/m, 'ohpm_path="__OHPM_PATH__"')
      .replace(/^arkuiXSdkPath=.*$/m, 'arkuiXSdkPath="__ARKUIX_SDK_PATH__"'));
  } else {
    console.error(`警告: 参照产物缺 ${rel}（归档无该构建脚本）`);
  }
}
function placeholderize(content) {
  return content
    .replace(/^project_path=.*$/m, 'project_path="__PROJECT_PATH__"')
    .replace(/^ohpm_path=.*$/m, 'ohpm_path="__OHPM_PATH__"')
    .replace(/^arkuiXSdkPath=.*$/m, 'arkuiXSdkPath="__ARKUIX_SDK_PATH__"');
}

// .projectInfo（双平台）
writeFileSync(join(outDir, '.projectInfo'), JSON.stringify({
  projectTemplate: 'app', moduleInfo: [], abilityInfo: [], platforms: ['android', 'ios']
}, null, 2) + '\n');

// 剔除 xcuserdata（Xcode UI 状态）
rmSync(join(outDir, '.arkui-x/ios/app.xcodeproj/project.xcworkspace/xcuserdata'), { recursive: true, force: true });
try { rmSync(join(outDir, '.arkui-x/ios/app.xcodeproj/xcuserdata'), { recursive: true, force: true }); } catch { /* 无则跳过 */ }

console.log(`归档完成: ${outDir}（${NAME} / ${BUNDLE} / 26.0.0 / OpenHarmony / both / CocoaPods）`);
