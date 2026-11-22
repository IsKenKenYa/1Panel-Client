import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadTemplates, renderFivePieces, todoAnnotation, FENCE } from './renderer.js';
import { loadNativeApiMap, matchNativeApi, _setCache } from './native-map.js';

const templates = loadTemplates();
const MAPPED = { name: 'BatteryInfoBatterySOC', module: '@ohos.batteryInfo', symbol: 'batterySOC', category: 'equivalent_bridge' };
const UNMAPPED = { name: 'FakeUnknownApi', module: '@ohos.nonsense', symbol: 'mystery', category: 'equivalent_bridge' };
const DEGRADED = { name: 'VibratorStart', module: '@ohos.vibrator', symbol: 'startVibration', category: 'degraded_bridge', reason: '振幅精细化控制在 ArkUI-X 侧不可用' };
const CONTRACT = (n = 'BatteryInfoBatterySOCInterface') => ({ interfaceName: n, methods: [{ name: 'batterySOC', params: [{ type: 'string', name: 'p0' }] }] });

test('renderFivePieces：六件齐备+落位符合路径约定（+⑥Impl 分发器）', () => {
  const out = renderFivePieces(MAPPED, { status: 'migrated', content: 'const udid = deviceInfo.udid;', ref: 'a.ets:1' }, CONTRACT(), templates);
  const keys = Object.keys(out.texts);
  assert.equal(keys.length, 7); // ①②③⑥+④⑤.h⑤.m（工程级 PlatformInfo 由 writer 单独落盘，不在每接口 texts）
  assert.ok(out.paths.interface.includes('commons/batteryInfo/interface/BatteryInfoBatterySOCInterface.ets'));
  assert.ok(out.paths.local.endsWith('BatteryInfoBatterySOCLocal.ets'));
  assert.ok(out.paths.impl.endsWith('BatteryInfoBatterySOCImpl.ets'), '⑥分发器落 impl/');
  assert.ok(out.paths.platform_info.endsWith('commons/utils/PlatformInfo.ets'), '工程级 PlatformInfo 路径');
  assert.ok(out.paths.android.endsWith('BridgeBatteryInfoBatterySOC.java'));
  assert.ok(out.paths.android.startsWith('.arkui-x/android/'));
  assert.ok(out.paths.ios.startsWith('.arkui-x/ios/'));
  //  形态：②Local class implements ①；③ArkUIX class；⑥分发 import PlatformInfo
  assert.ok(out.texts[out.paths.local].includes('export class BatteryInfoBatterySOCLocal implements BatteryInfoBatterySOCInterface'));
  assert.ok(out.texts[out.paths.arkui_x].includes('export class BatteryInfoBatterySOCArkUIX implements BatteryInfoBatterySOCInterface'));
  assert.ok(out.texts[out.paths.impl].includes("import { PlatformInfo, PlatformTypeEnum } from '../../utils/PlatformInfo'"));
  assert.ok(out.texts[out.paths.impl].includes('BatteryInfoBatterySOCLocal.getInstance()'));
});

test('renderFivePieces：③类已映射→④⑤渲染等价原生 API', () => {
  loadNativeApiMap();
  const out = renderFivePieces(MAPPED, { status: 'failed', reason: 'x' }, CONTRACT(), templates);
  const java = out.texts[out.paths.android];
  const iosM = out.texts[out.paths.ios_m];
  assert.ok(java.includes('等价原生 API：android.os.BatteryManager.getIntProperty'));
  assert.ok(iosM.includes('batteryLevel'));
});

test('renderFivePieces：③类未映射→unmapped 标记（不猜测）', () => {
  const out = renderFivePieces(UNMAPPED, { status: 'failed', reason: 'x' }, { interfaceName: 'X', methods: [{ name: 'm', params: [] }] }, templates);
  assert.equal(out.unmapped, true);
  assert.ok(out.texts[out.paths.android].includes('unmapped_native_apis'));
});

test('renderFivePieces：④类→降级占位+能力损失语义', () => {
  const out = renderFivePieces(DEGRADED, { status: 'failed', reason: 'x' }, { interfaceName: 'X', methods: [{ name: 'startVibration', params: [] }] }, templates);
  const java = out.texts[out.paths.android];
  assert.ok(java.includes('降级说明：振幅精细化控制在 ArkUI-X 侧不可用'));
  assert.ok(java.includes('TODO(ARKUIX-BRIDGE)'));
});

test('renderFivePieces：TODO 注解三要素+围栏成对', () => {
  const out = renderFivePieces(DEGRADED, { status: 'failed', reason: 'x' }, { interfaceName: 'X', methods: [{ name: 'startVibration', params: [] }] }, templates);
  const java = out.texts[out.paths.android];
  const ann = todoAnnotation(DEGRADED, 'android');
  assert.ok(ann.includes('interface=VibratorStart') && ann.includes('platform=android') && ann.includes('category=degraded_bridge'));
  assert.ok(java.includes(ann));
  assert.ok(java.includes(FENCE.java.begin) && java.includes(FENCE.java.end));
  const iosM = out.texts[out.paths.ios_m];
  assert.ok(iosM.includes(FENCE.objc.begin) && iosM.includes(FENCE.objc.end));
});

test('native-api-map：两级匹配（符号级→模块级通配）；损坏映射表 fail-fast', () => {
  _setCache({ meta: { rules_version: '0.0.0-test' }, mappings: [
    { module: '@ohos.a', symbol: 'x', android: 'A', ios: 'I' },
    { module: '@ohos.b', symbol: '*', android: 'B', ios: 'I2' },
  ] });
  assert.ok(matchNativeApi('@ohos.a', 'x'));
  assert.ok(matchNativeApi('@ohos.b', 'anything'));
  assert.equal(matchNativeApi('@ohos.none', 'x'), undefined);
});

// ── ：④⑤ 围栏内最低版本注释（native-api-map min_*）────────────────────
test('min_android/min_ios 在场 → ④⑤ 围栏内渲染最低版本注释；缺席不渲染', () => {
  _setCache({ meta: { rules_version: '0.0.0-test' }, mappings: [
    { module: '@ohos.batteryInfo', symbol: 'batterySOC', android: 'A', ios: 'I',
      min_android: 'API 21+', min_ios: 'iOS 9.0+' },
  ] });
  const out = renderFivePieces(MAPPED, { status: 'failed', reason: 'x' }, CONTRACT(), templates);
  assert.ok(out.texts[out.paths.android].includes('最低版本要求：Android API 21+'), '④ 围栏内 Android 版本注释');
  assert.ok(out.texts[out.paths.ios_m].includes('最低版本要求：iOS 9.0+'), '⑤ 围栏内 iOS 版本注释');
  assert.ok(out.nativeApi && out.nativeApi.min_android === 'API 21+', 'nativeApi 透传（bridge.js→writer 消费）');
  // 缺席（测试规则表该条目无 min_* 标注）→ 不渲染版本行
  _setCache({ meta: { rules_version: '0.0.0-test' }, mappings: [
    { module: '@ohos.unknownModule', symbol: 'unknownSymbol', android: 'A2', ios: 'I2' }, // 无 min_android/min_ios
  ] });
  loadNativeApiMap();
  // 用不在真实规则表的模块→不命中映射→无 min_*→不渲染版本行
  const UNKNOWN_ITEM = { name: 'Unknown', module: '@ohos.unknownMod', symbol: 'unknownSym', category: 'equivalent_bridge', locations: [] };
  const UNKNOWN_CONTRACT = { interfaceName: 'UnknownInterface', methods: [{ name: 'doThing', params: [] }] };
  const out2 = renderFivePieces(UNKNOWN_ITEM, { status: 'failed', reason: 'x' }, UNKNOWN_CONTRACT, templates);
  assert.ok(!out2.texts[out2.paths.android].includes('最低版本要求'), '未标注不渲染版本注释');
});

// ── ④⑤ 全方法渲染 ───────────────────────────
test('④⑤ 按契约全方法渲染——Java/ObjC 每方法一围栏；多参选择器形态', () => {
  const contract = { interfaceName: 'XInterface', methods: [
    { name: 'getCameraManager', params: [{ name: 'context', type: 'ESObject' }] },
    { name: 'on', params: [{ name: 'type', type: 'string' }, { name: 'callback', type: 'ESObject' }] },
  ] };
  const out = renderFivePieces(MAPPED, { status: 'failed', reason: 'x' }, contract, templates);
  const java = out.texts[out.paths.android];
  assert.ok(java.includes('public String getCameraManager(Object context)'), '④ 方法1（ESObject→Object）');
  assert.ok(java.includes('public String on(String type, Object callback)'), '④ 方法2（双参）');
  assert.equal((java.match(/ARKUIX-BRIDGE-HANDOFF BEGIN/g) || []).length, 2, '④ 每方法一围栏');
  const iosH = out.texts[out.paths.ios];
  assert.ok(iosH.includes('- (NSString*)getCameraManager:(id)context;'), '⑤.h 方法1');
  assert.ok(iosH.includes('- (NSString*)on:(NSString*)type arg2:(id)callback;'), '⑤.h 方法2（多参选择器 name:arg2:）');
  const iosM = out.texts[out.paths.ios_m];
  assert.ok(iosM.includes('- (NSString*)on:(NSString*)type arg2:(id)callback {'), '⑤.m 实现体双方法');
  assert.equal((iosM.match(/ARKUIX-BRIDGE-HANDOFF BEGIN/g) || []).length, 2, '⑤.m 每方法一围栏');
});

// ── ：方法体可编译性判定 ───────────────────────────────────
test('this 引用/未解析标识符的语句 → // ORIG: 注释化（类可编译兑现）', () => {
  const local = { status: 'migrated', ref: 'a.ets:1', content: [
    "import sensor from '@ohos.sensor';",
    "this.mgr = camera.getCameraManager(UIContextSelf.ctx);",
    "sensor.on(sensor.SensorId.X);",
  ].join('\n') };
  const contract = { interfaceName: 'XInterface', methods: [
    { name: 'getCameraManager', params: [] },
    { name: 'on', params: [] },
  ] };
  const out = renderFivePieces(
    { name: 'X', module: '@ohos.multimedia.camera', symbol: 'camera', category: 'degraded_bridge' },
    local, contract, templates);
  const text = out.texts[out.paths.local];
  assert.ok(text.includes('// ORIG: this.mgr = camera.getCameraManager'), 'this 语句注释化');
  assert.ok(text.includes('含 this 成员引用'), '注释原因标注');
  assert.ok(text.includes('sensor.on(sensor.SensorId.X);'), '自含语句 live 平铺（可编译）');
  assert.ok(!text.includes('// ORIG: sensor.on'), '自含语句不注释化');
});
