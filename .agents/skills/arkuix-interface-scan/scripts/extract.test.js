import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { detectModel, enumerateFiles, extractReferences } from './extract.js';

function makeProject(files) {
  const root = mkdtempSync(join(tmpdir(), 'f2-extract-'));
  for (const [rel, content] of Object.entries(files)) {
    const file = join(root, rel);
    mkdirSync(join(file, '..'), { recursive: true });
    writeFileSync(file, content, 'utf8');
  }
  return root;
}

test('detectModel：AppScope/app.json5 → stage', () => {
  const root = makeProject({ 'AppScope/app.json5': '{}', 'entry/src/main/module.json5': '{}' });
  assert.equal(detectModel(root), 'stage');
  rmSync(root, { recursive: true, force: true });
});

test('detectModel：config.json（无 Stage 特征）→ fa', () => {
  const root = makeProject({ 'config.json': '{}' });
  assert.equal(detectModel(root), 'fa');
  rmSync(root, { recursive: true, force: true });
});

test('detectModel：无特征 → unknown', () => {
  const root = makeProject({ 'README.md': 'x' });
  assert.equal(detectModel(root), 'unknown');
  rmSync(root, { recursive: true, force: true });
});

test('enumerateFiles：含 .ets/.ts 与配置，排除 node_modules/oh_modules/.hvigor/build', () => {
  const root = makeProject({
    'entry/src/main/ets/Index.ets': 'x',
    'entry/src/main/ets/pages/Detail.ts': 'x',
    'entry/src/main/module.json5': '{}',
    'oh-package.json5': '{}',
    'node_modules/pkg/index.js': 'x',
    'oh_modules/pkg/index.js': 'x',
    '.hvigor/cache.dat': 'x',
    'entry/build/intermediate.js': 'x'
  });
  const files = enumerateFiles(root);
  assert.ok(files.includes('entry/src/main/ets/Index.ets'));
  assert.ok(files.includes('entry/src/main/ets/pages/Detail.ts'));
  assert.ok(files.includes('entry/src/main/module.json5'));
  assert.ok(!files.some((f) => f.startsWith('node_modules')));
  assert.ok(!files.some((f) => f.startsWith('oh_modules')));
  assert.ok(!files.some((f) => f.startsWith('.hvigor')));
  assert.ok(!files.some((f) => f.includes('/build/')));
  rmSync(root, { recursive: true, force: true });
});

test('引用提取：具名(剥离别名/逐符号独立项)/默认/动态导入与配置文件引用，file:line 准确', () => {
  const root = makeProject({
    'a.ets': [
      "import { publish, cancel as cancelNotification } from '@ohos.notificationManager';",
      "import router from '@ohos.router';",
      "const m = await import('@ohos.geoLocationManager');"
    ].join('\n'),
    'b.ets': "import { MapComponent } from '@hms.map';",
    'module.json5': '{"reqPermissions":[{"name":"ohos.permission.LOCATION"}]}',
    'oh-package.json5': '{"dependencies":{"@ohos.libx":"file:../libx"}}'
  });
  const { inventory: inv } = extractReferences(root, ['a.ets', 'b.ets', 'module.json5', 'oh-package.json5']);
  const by = (module, symbol) => inv.find((i) => i.module === module && i.symbol === symbol);

  // 具名导入归一为原始导出符号（别名剥离），逐符号独立项
  assert.deepEqual(
    { ...by('@ohos.notificationManager', 'publish') },
    { source: 'ohos', module: '@ohos.notificationManager', symbol: 'publish', file: 'a.ets', line: 1 });
  assert.deepEqual(
    { ...by('@ohos.notificationManager', 'cancel') },
    { source: 'ohos', module: '@ohos.notificationManager', symbol: 'cancel', file: 'a.ets', line: 1 });
  assert.deepEqual(
    { ...by('@ohos.router', 'router') },
    { source: 'ohos', module: '@ohos.router', symbol: 'router', file: 'a.ets', line: 2 });
  assert.deepEqual(
    { ...by('@ohos.geoLocationManager', '*dynamic*') },
    { source: 'ohos', module: '@ohos.geoLocationManager', symbol: '*dynamic*', file: 'a.ets', line: 3 });
  assert.deepEqual(
    { ...by('@hms.map', 'MapComponent') },
    { source: 'hms', module: '@hms.map', symbol: 'MapComponent', file: 'b.ets', line: 1 });
  const cfg = inv.find((i) => i.file === 'oh-package.json5');
  assert.ok(cfg, '构建配置依赖引用应计入');
  assert.equal(cfg.symbol, '*module-ref*');
  assert.equal(inv.filter((i) => i.file === 'module.json5').length, 0, '权限名（无@前缀）不计为模块引用');
  rmSync(root, { recursive: true, force: true });
});

test('enumerateFiles：含 Native 源码 {.cpp,.cc,.cxx,.h,.hpp}，排除 Pods/DerivedData（大小写不敏感）', () => {
  const root = makeProject({
    'entry/src/main/cpp/napi_init.cpp': 'x',
    'entry/src/main/cpp/types/lib.cpp': 'x',
    'entry/src/main/cpp/bridge.cc': 'x',
    'entry/src/main/cpp/codec.cxx': 'x',
    'entry/src/main/cpp/include/util.h': 'x',
    'entry/src/main/cpp/include/util.hpp': 'x',
    'entry/src/main/cpp/main.c': 'x',
    'Pods/Dep/a.cpp': 'x',
    'ios/DerivedData/Build/a.cpp': 'x',
    '.previewer/cache.cpp': 'x'
  });
  const files = enumerateFiles(root);
  assert.ok(files.includes('entry/src/main/cpp/napi_init.cpp'));
  assert.ok(files.includes('entry/src/main/cpp/bridge.cc'));
  assert.ok(files.includes('entry/src/main/cpp/codec.cxx'));
  assert.ok(files.includes('entry/src/main/cpp/include/util.h'));
  assert.ok(files.includes('entry/src/main/cpp/include/util.hpp'));
  assert.ok(!files.includes('entry/src/main/cpp/main.c'), '.c 不在 Native 清单');
  assert.ok(!files.some((f) => f.startsWith('Pods')));
  assert.ok(!files.some((f) => f.includes('DerivedData')));
  assert.ok(!files.some((f) => f.startsWith('.previewer')));
  rmSync(root, { recursive: true, force: true });
});

test('Native 提取：NDK 头包含 + OH_* 符号（module 归一为最近 NDK include）+ 非 NDK 头不计', () => {
  const root = makeProject({
    'n.cpp': [
      '#include <vector>',
      '#include <hilog/log.h>',
      '#include "ace/xcomponent/native_interface_xcomponent.h"',
      'extern "C" void Init(OH_NativeXComponent* c) {',
      '  OH_NativeXComponent_RegisterCallback(c, nullptr);',
      '}',
      '#include "native_media/avcodec.h"',
      'void E() { OH_AVEncoder_Create(nullptr); }'
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['n.cpp']);
  const by = (module, symbol) => inv.find((i) => i.module === module && i.symbol === symbol);
  assert.deepEqual(
    { ...by('hilog/log.h', '*include*') },
    { source: 'ndk', module: 'hilog/log.h', symbol: '*include*', file: 'n.cpp', line: 2 });
  assert.ok(by('ace/xcomponent/native_interface_xcomponent.h', '*include*'), 'xcomponent 头计入');
  assert.ok(by('ace/xcomponent/native_interface_xcomponent.h', 'OH_NativeXComponent'), '类型 OH_* 计入且归因最近 NDK include');
  assert.ok(by('ace/xcomponent/native_interface_xcomponent.h', 'OH_NativeXComponent_RegisterCallback'));
  assert.ok(by('native_media/avcodec.h', '*include*'), '未覆盖头文件也计入 inventory（判定归 unknown）');
  assert.ok(by('native_media/avcodec.h', 'OH_AVEncoder_Create'), 'avcodec include 后的 OH_* 归因切换');
  assert.ok(!inv.some((i) => i.module === 'vector'), '标准库头不计入');
  rmSync(root, { recursive: true, force: true });
});

test('动态加载：dlopen 字面量计入（module=so 库名）；变量形式仅提示不计入', () => {
  const root = makeProject({
    'n.cpp': [
      'void L(void* h, const char* p) {',
      '  h = dlopen("libblend.z.so", 2);',
      '  h = dlopen(p, 2);',
      '}'
    ].join('\n')
  });
  const { inventory: inv, dynamicHints } = extractReferences(root, ['n.cpp']);
  const dl = inv.find((i) => i.module === 'libblend.z.so');
  assert.deepEqual({ ...dl }, { source: 'ndk', module: 'libblend.z.so', symbol: '*dlopen*', file: 'n.cpp', line: 2 });
  assert.equal(inv.filter((i) => i.symbol === '*dlopen*').length, 1, '变量形式不计入');
  assert.deepEqual(dynamicHints, [{ file: 'n.cpp', line: 3, kind: 'dlopen' }]);
  rmSync(root, { recursive: true, force: true });
});

test('ArkTS 动态加载：变量形式 import(x) 仅提示不计入', () => {
  const root = makeProject({
    'a.ets': [
      "export async function f(n: string) {",
      "  const a = await import('@ohos.router');",
      '  const b = await import(n);',
      '  return a || b;',
      '}'
    ].join('\n')
  });
  const { inventory: inv, dynamicHints } = extractReferences(root, ['a.ets']);
  assert.ok(inv.some((i) => i.module === '@ohos.router' && i.symbol === '*dynamic*'), '字面量动态导入计入');
  assert.equal(inv.filter((i) => i.module === '@ohos.router').length, 1, '变量形式不计入');
  assert.deepEqual(dynamicHints, [{ file: 'a.ets', line: 3, kind: 'dynamic-import' }]);
  rmSync(root, { recursive: true, force: true });
});

test('C-API 清单头识别：arkui/rawfile/napi 前缀 + plugin_utils 双形态（含 libarkui_ios 路径）', () => {
  const root = makeProject({
    'capi.cpp': [
      '#include <arkui/native_node.h>',
      '#include <napi/native_api.h>',
      '#include <node_api.h>',
      '#include "rawfile/raw_file_manager.h"',
      '#include "plugin_utils.h"',
      '#include <libarkui_ios/include/plugin_utils.h>'
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['capi.cpp']);
  const mods = new Set(inv.filter((i) => i.source === 'ndk').map((i) => i.module));
  assert.ok(mods.has('arkui/native_node.h'), 'arkui/ 头识别');
  assert.ok(mods.has('napi/native_api.h'), 'napi/ 头识别');
  assert.ok(mods.has('node_api.h'), 'node_api.h 识别');
  assert.ok(mods.has('rawfile/raw_file_manager.h'), 'rawfile/ 头识别');
  assert.ok(mods.has('plugin_utils.h'), 'plugin_utils.h 裸名识别（清单成员）');
  assert.ok(mods.has('libarkui_ios/include/plugin_utils.h'), 'libarkui_ios 路径形态识别（docs 集成教程实证形态）');
  assert.equal(inv.length, 6, '全部 include 计入、无多余');
  rmSync(root, { recursive: true, force: true });
});

test('审计增补：注释中的引用一律不计（行/块/跨行块注释，字符串感知）', () => {
  const root = makeProject({
    'a.ets': [
      "// import { x } from '@ohos.router';",
      "/* import { y } from '@ohos.router'; */",
      '/*',
      "import { z } from '@ohos.router';",
      '*/',
      "import { real } from '@ohos.router';"
    ].join('\n'),
    'b.cpp': [
      '// OH_NativeXComponent_RegisterCallback(c, nullptr);',
      '// void* h = dlopen("libx.z.so", 2);',
      '// void* h2 = dlopen(p, 2);',
      '/* OH_ArkUI_xxx(); */',
      'int keep = 1;'
    ].join('\n')
  });
  const { inventory: inv, dynamicHints } = extractReferences(root, ['a.ets', 'b.cpp']);
  assert.equal(inv.length, 1, '仅真实 import 计数');
  assert.equal(inv[0].symbol, 'real');
  assert.equal(dynamicHints.length, 0, '注释中的 dlopen 不产生提示');
  rmSync(root, { recursive: true, force: true });
});

test('审计增补：字符串内 // 不误伤同行真实引用（URL 场景）', () => {
  const root = makeProject({
    'a.ets': "const u = 'https://gitcode.com/x'; import { publish } from '@ohos.notificationManager';\n"
  });
  const { inventory: inv } = extractReferences(root, ['a.ets']);
  assert.equal(inv.length, 1);
  assert.equal(inv[0].symbol, 'publish');
  rmSync(root, { recursive: true, force: true });
});

test('审计增补：多行具名 import 逐符号提取（起始行计数）+ 畸形安全容忍', () => {
  const root = makeProject({
    'ok.ets': [
      'import {',
      '  publish,',
      '  cancel as cancelNotification',
      "} from '@ohos.notificationManager';"
    ].join('\n'),
    'bad.ets': [
      'import {',
      '  a,',
      '  b',
      'const broken = 1;'
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['ok.ets', 'bad.ets']);
  assert.equal(inv.length, 2, '多行具名两符号；畸形不计');
  assert.ok(inv.some((i) => i.symbol === 'publish' && i.line === 1), '起始行计数');
  assert.ok(inv.some((i) => i.symbol === 'cancel'));
  rmSync(root, { recursive: true, force: true });
});

test('审计增补：混合默认+具名与反引号动态导入形态', () => {
  const root = makeProject({
    'a.ets': [
      "import ns, { foo } from '@ohos.router';",
      'const m = await import(`@ohos.geoLocationManager`);'
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['a.ets']);
  assert.equal(inv.length, 3);
  assert.ok(inv.some((i) => i.symbol === 'ns' && i.module === '@ohos.router'));
  assert.ok(inv.some((i) => i.symbol === 'foo'));
  assert.ok(inv.some((i) => i.symbol === '*dynamic*' && i.module === '@ohos.geoLocationManager'));
  rmSync(root, { recursive: true, force: true });
});

test('审计看护 P11：CRLF 行尾正常计数', () => {
  const root = makeProject({
    'a.ets': "import { x } from '@ohos.router';\r\nimport { y } from '@ohos.router';\r\n"
  });
  const { inventory: inv } = extractReferences(root, ['a.ets']);
  assert.equal(inv.length, 2);
  assert.ok(inv.every((i) => ['x', 'y'].includes(i.symbol)));
  rmSync(root, { recursive: true, force: true });
});

test('审计看护 P12：export-from 再导出计具名符号与星号再导出', () => {
  const root = makeProject({
    'a.ets': [
      "export { x } from '@ohos.router';",
      "export * from '@ohos.notificationManager';"
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['a.ets']);
  assert.equal(inv.length, 2);
  assert.ok(inv.some((i) => i.symbol === 'x' && i.module === '@ohos.router'));
  assert.ok(inv.some((i) => i.symbol === '*' && i.module === '@ohos.notificationManager'));
  rmSync(root, { recursive: true, force: true });
});

test('@kit 导入展开（索引在场）——具名符号落真实模块；星号/动态展开成员；未解析保留 @kit', () => {
  const root = makeProject({
    'a.ets': [
      "import { onlyFn } from '@kit.TestKit';",
      "import kitNs from '@kit.TestKit';",
      "import { ghostFn } from '@kit.UnknownKit';",
      "const d = await import('@kit.TestKit');"
    ].join('\n')
  });
  const kitIndex = { kits: new Map([['@kit.TestKit', new Set(['@ohos.router', '@ohos.markedonly'])]]),
    symbols: new Map([['router', '@ohos.router'], ['onlyFn', '@ohos.markedonly']]) };
  const { inventory: inv } = extractReferences(root, ['a.ets'], { kitIndex });
  const by = (m, s) => inv.find((i) => i.module === m && i.symbol === s);
  assert.deepEqual({ ...by('@ohos.markedonly', 'onlyFn') },
    { source: 'ohos', module: '@ohos.markedonly', symbol: 'onlyFn', file: 'a.ets', line: 1 });
  // 默认命名空间 → 展开全部成员（排序确定）
  assert.ok(by('@ohos.markedonly', 'kitNs') && by('@ohos.router', 'kitNs'), '默认名展开到成员模块');
  // 动态字面量 → *dynamic* 展开到成员
  assert.ok(inv.some((i) => i.module === '@ohos.router' && i.symbol === '*dynamic*'), '动态 kit 展开成员');
  // 未知 kit / 未解析符号 → 保留 @kit.*
  assert.ok(by('@kit.UnknownKit', 'ghostFn'));
  assert.equal(inv.length, 1 + 2 + 1 + 2);
  rmSync(root, { recursive: true, force: true });
});

test('降级（无索引）@kit 原样保留，判定侧显式 unknown', async () => {
  const root = makeProject({ 'a.ets': "import { onlyFn } from '@kit.TestKit';\n" });
  const { inventory: inv } = extractReferences(root, ['a.ets']);
  // ：未知/降级 kit 归属不可判定 → source=unknown（不虚计 ohos/hms）
  assert.deepEqual(inv, [{ source: 'unknown', module: '@kit.TestKit', symbol: 'onlyFn', file: 'a.ets', line: 1 }]);
  rmSync(root, { recursive: true, force: true });
  const { classify } = await import('./classify.js');
  const { adaptation } = classify(
    [{ source: 'unknown', module: '@kit.TestKit', symbol: 'onlyFn', file: 'a.ets', line: 1 }],
    await import('./classify.js').then((m) => m.loadRules()), null);
  // ：未展开 kit 由 unknown 改归 business_decision（类比 @hms.* 闭源生态处理）
  const item = adaptation.business_decision.find((i) => i.module === '@kit.TestKit');
  assert.ok(item, '判定归 business_decision');
  assert.match(item.reason, /@kit.*未展开/);
});

test('sysroot 声明索引优先归属——未直接 include 的符号挂到声明头而非最近 include', async () => {
  const { buildNativeSymbolIndex } = await import('./native-index.js');
  const idx = buildNativeSymbolIndex('benchmark/mini-sdk/native/sysroot/usr/include');
  assert.equal(idx.get('OH_NativeWindow_Create'), 'native_window/native_window.h');
  assert.equal(idx.get('OH_LOG_Print'), 'hilog/log.h');
  const root = makeProject({
    'a.cpp': [
      '#include <hilog/log.h>',
      'void W() {',
      '  OH_NativeWindow_Create();',
      '  OH_LOG_Print(0, 1, "d");',
      '}'
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['a.cpp'], { nativeIndex: idx });
  const win = inv.find((i) => i.symbol === 'OH_NativeWindow_Create');
  const log = inv.find((i) => i.symbol === 'OH_LOG_Print');
  assert.equal(win.module, 'native_window/native_window.h', '归属声明头而非 hilog');
  assert.equal(log.module, 'hilog/log.h');
  rmSync(root, { recursive: true, force: true });
});

test('注释提及不计分 + 声明权重压过引用频次', async () => {
  const { buildNativeSymbolIndex } = await import('./native-index.js');
  const idx = buildNativeSymbolIndex('benchmark/mini-sdk/native/sysroot/usr/include');
  // arkui/native_node.h 仅在文档注释中提及 OH_PixelmapNative_Release（剥注释后 0 分）
  assert.equal(idx.get('OH_PixelmapNative_Release'), 'multimedia/image_framework/image/pixelmap_native.h');
  // 声明头（10 分）压过 8 处参数提及（8 分）的用例以单测构造
  const root = makeProject({ 'a.cpp': 'void f() { OH_PixelmapNative_Release(nullptr); }\n' });
  const { inventory: inv } = extractReferences(root, ['a.cpp'], { nativeIndex: idx });
  assert.equal(inv[0].module, 'multimedia/image_framework/image/pixelmap_native.h');
  rmSync(root, { recursive: true, force: true });
});

test('多行本地 import 后跟单行 @hms import——不吞、不误归、垃圾符号不产', () => {
  const root = makeProject({
    'a.ets': [
      "import {",
      "  AppStorageKeys,",
      "  MusicAppState",
      "} from 'musicbasic';",
      "import { getPlayerManager } from 'player';",
      "import { HdsBarStyle, HdsTabs } from '@hms.hds.hdsBaseComponent';",
      "import { publish } from '@ohos.notificationManager';"
    ].join('\n')
  });
  const { inventory: inv } = extractReferences(root, ['a.ets']);
  // 本地模块（musicbasic/player）不计入 @ohos/@hms inventory
  const hms = inv.filter((i) => i.source === 'hms');
  const ohos = inv.filter((i) => i.source === 'ohos');
  assert.equal(hms.length, 2, '仅 2 条真实 HMS 符号');
  assert.ok(hms.every((i) => ['HdsBarStyle', 'HdsTabs'].includes(i.symbol)), 'HMS 符号不误归本地模块名');
  assert.ok(ohos.some((i) => i.symbol === 'publish'), '@ohos import 正常计数');
  assert.ok(!inv.some((i) => i.symbol.includes('} from')), '无垃圾符号');
  assert.ok(!inv.some((i) => i.symbol.includes('AppStorageKeys')), '本地模块符号不误入 inventory');
  rmSync(root, { recursive: true, force: true });
});

// ── （真机实测）：真实 IDE FA 工程（entry/src/main/config.json 模块级形态） ───
test('IDE FA 工程（<module>/src/main/config.json 且无 module.json5）判 fa；混合形态不误判', () => {
  const root = mkdtempSync(join(tmpdir(), 'f2-sd34-'));
  // IDE FA 真实形态：build-profile+oh-package+entry/src/main/config.json（无 module.json5）
  writeFileSync(join(root, 'build-profile.json5'), '{ "modules": [{ "name": "entry", "srcPath": "./entry" }] }');
  writeFileSync(join(root, 'oh-package.json5'), '{ "name": "fa" }');
  mkdirSync(join(root, 'entry/src/main'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/config.json'), '{ "app": {} }');
  assert.equal(detectModel(root), 'fa', 'IDE FA 形态应判 fa（原误判 stage）');
  // Stage 单模块（src/main/module.json5）不受影响
  const root2 = mkdtempSync(join(tmpdir(), 'f2-sd34b-'));
  writeFileSync(join(root2, 'build-profile.json5'), '{ "modules": [] }');
  writeFileSync(join(root2, 'oh-package.json5'), '{ "name": "st" }');
  mkdirSync(join(root2, 'entry/src/main'), { recursive: true });
  writeFileSync(join(root2, 'entry/src/main/module.json5'), '{ "module": {} }');
  assert.equal(detectModel(root2), 'stage', '单模块 stage 推定不回归');
  // 同目录两者并存 → 以 stage 清单为准（module.json5 在场）
  writeFileSync(join(root2, 'entry/src/main/config.json'), '{ "app": {} }');
  assert.equal(detectModel(root2), 'stage', 'module.json5 优先（不判 fa）');
  rmSync(root, { recursive: true, force: true });
  rmSync(root2, { recursive: true, force: true });
});
