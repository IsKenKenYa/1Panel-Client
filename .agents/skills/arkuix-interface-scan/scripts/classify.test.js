import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadRules, matchRule, classify, BUCKETS } from './classify.js';

function inventoryOf(spec) {
  return spec.map(([source, module, symbol, file, line]) => ({ source, module, symbol, file, line }));
}

function markIndex(spec) {
  // spec: [module, moduleMarked, [[symbol, marked], ...]]
  const map = new Map();
  for (const [module, moduleMarked, symbols] of spec) {
    map.set(module, { moduleMarked, symbols: new Map(symbols || []) });
  }
  return map;
}

function findItem(adaptation, bucket, module, symbol) {
  return adaptation[bucket].find((i) => i.module === module && i.symbol === symbol);
}

test('双源一致：SDK 支持 + 规则表① → 采规则表细分，reason 注明双源一致', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.notificationManager', false, [['publish', true]]]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.notificationManager', 'publish', 'a.ets', 3]]), rules, marks);
  const item = findItem(adaptation, 'full_direct', '@ohos.notificationManager', 'publish');
  assert.ok(item, '应归 full_direct');
  assert.match(item.reason, /双源一致/);
  assert.equal(item.advice, '直接使用');
});

test('双源一致：SDK 无标记 + 规则表⑤ → platform_trim', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.account.osAccount', false, []]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.account.osAccount', 'getAccountManager', 'a.ets', 1]]), rules, marks);
  assert.ok(findItem(adaptation, 'platform_trim', '@ohos.account.osAccount', 'getAccountManager'));
});

test('双源冲突（SDK 支持 vs 规则表⑤）→ unknown 含两源结论', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.mockConflict', false, [['doWork', true]]]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.mockConflict', 'doWork', 'a.ets', 5]]), rules, marks);
  const item = findItem(adaptation, 'unknown', '@ohos.mockConflict', 'doWork');
  assert.ok(item, '冲突应归 unknown');
  assert.match(item.reason, /双源冲突/);
  assert.match(item.reason, /⑤平台裁剪/);
});

test('双源冲突（SDK 无标记 vs 规则表①）→ unknown', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.mockConflict2', false, [['doWork', false]]]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.mockConflict2', 'doWork', 'a.ets', 5]]), rules, marks);
  assert.ok(findItem(adaptation, 'unknown', '@ohos.mockConflict2', 'doWork'));
});

test('单源命中：SDK 支持标记 + 规则表未覆盖 → ① 单源(SDK)', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.someMarked', false, [['foo', true]]]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.someMarked', 'foo', 'a.ets', 2]]), rules, marks);
  const item = findItem(adaptation, 'full_direct', '@ohos.someMarked', 'foo');
  assert.ok(item);
  assert.match(item.reason, /单源（SDK）/);
});

test('SDK 无标记 + 规则表未覆盖 → unknown', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.nobody', false, [['foo', false]]]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.nobody', 'foo', 'a.ets', 2]]), rules, marks);
  const item = findItem(adaptation, 'unknown', '@ohos.nobody', 'foo');
  assert.ok(item);
  assert.match(item.reason, /判定依据未覆盖/);
});

test('单源（规则表）：SDK 索引无该模块 + 规则表⑤ → ⑤', () => {
  const rules = loadRules();
  const marks = markIndex([]); // 索引为空但可用（非降级）
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.distributedKVStore', 'sync', 'a.ets', 9]]), rules, marks);
  const item = findItem(adaptation, 'platform_trim', '@ohos.distributedKVStore', 'sync');
  assert.ok(item);
  assert.match(item.reason, /单源（规则表/);
});

test('降级（marks=null）：规则表单源采信（geoLocationManager 经裁决改判②）', () => {
  const rules = loadRules();
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.geoLocationManager', 'getCurrentLocation', 'a.ets', 4]]), rules, null);
  const item = findItem(adaptation, 'reduced_direct', '@ohos.geoLocationManager', 'getCurrentLocation');
  assert.ok(item);
  assert.match(item.reason, /单源（规则表/);
});

test('降级 + 规则表未覆盖 → unknown', () => {
  const rules = loadRules();
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.unknownOne', 'x', 'a.ets', 1]]), rules, null);
  assert.ok(findItem(adaptation, 'unknown', '@ohos.unknownOne', 'x'));
});

test('@hms.*：默认⑥ + 已知替代建议', () => {
  const rules = loadRules();
  const { adaptation } = classify(
    inventoryOf([['hms', '@hms.map', 'MapComponent', 'p.ets', 7]]), rules, null);
  const item = findItem(adaptation, 'business_decision', '@hms.map', 'MapComponent');
  assert.ok(item);
  assert.equal(item.suggested_alternative, '@ohos.map（Map Kit 开源侧能力，功能子集）');
});

test('@hms.* 无已知替代 → 需开发者评估', () => {
  const rules = loadRules();
  const { adaptation } = classify(
    inventoryOf([['hms', '@hms.brandnew', 'x', 'p.ets', 7]]), rules, null);
  const item = findItem(adaptation, 'business_decision', '@hms.brandnew', 'x');
  assert.equal(item.suggested_alternative, '需开发者评估');
});

test('聚合：同接口多引用 occurrences+locations 完整去重', () => {
  const rules = loadRules();
  const marks = markIndex([['@ohos.someMarked', false, [['foo', true]]]]);
  const { adaptation } = classify(inventoryOf([
    ['ohos', '@ohos.someMarked', 'foo', 'a.ets', 2],
    ['ohos', '@ohos.someMarked', 'foo', 'b.ets', 10],
    ['ohos', '@ohos.someMarked', 'foo', 'a.ets', 2]
  ]), rules, marks);
  const item = findItem(adaptation, 'full_direct', '@ohos.someMarked', 'foo');
  assert.equal(item.occurrences, 3);
  assert.deepEqual(item.locations, ['a.ets:2', 'b.ets:10']);
});

test('桶互斥：同一接口仅出现在一个分类桶', () => {
  const rules = loadRules();
  const marks = markIndex([
    ['@ohos.notificationManager', false, [['publish', true]]],
    ['@ohos.mockConflict', false, [['doWork', true]]]
  ]);
  const { adaptation } = classify(inventoryOf([
    ['ohos', '@ohos.notificationManager', 'publish', 'a.ets', 1],
    ['ohos', '@ohos.mockConflict', 'doWork', 'a.ets', 2],
    ['hms', '@hms.map', 'MapComponent', 'a.ets', 3],
    ['ohos', '@ohos.nobody', 'foo', 'a.ets', 4]
  ]), rules, marks);
  const seen = new Map();
  let total = 0;
  for (const bucket of BUCKETS) {
    for (const item of adaptation[bucket]) {
      total += 1;
      const key = `${item.module}#${item.symbol}`;
      assert.ok(!seen.has(key), `桶互斥被破坏: ${key} 出现于 ${seen.get(key)} 与 ${bucket}`);
      seen.set(key, bucket);
    }
  }
  assert.equal(total, 4);
});

test('@ohos.* 无扫描判定的 business_decision', () => {
  const rules = loadRules();
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.anything', 'x', 'a.ets', 1]]), rules, null);
  for (const item of adaptation.business_decision) {
    assert.notEqual(item.source, 'ohos', '@ohos.* 不得被扫描判定为⑥');
  }
});

test('两级匹配：符号级规则优先于模块级', () => {
  const rules = {
    meta: {},
    byKey: new Map([
      ['@ohos.m#specialFn', { module: '@ohos.m', symbol: 'specialFn', category: 'degraded_bridge', reason: 'r', advice: 'a', suggested_alternative: 'N/A' }],
      ['@ohos.m', { module: '@ohos.m', symbol: null, category: 'full_direct', reason: 'r', advice: 'a', suggested_alternative: 'N/A' }]
    ])
  };
  assert.equal(matchRule(rules, '@ohos.m', 'specialFn').category, 'degraded_bridge');
  assert.equal(matchRule(rules, '@ohos.m', 'otherFn').category, 'full_direct');
});

test('规则表加载失败 fail-fast', () => {
  assert.throws(() => loadRules('/nonexistent/rules.json'));
});

test('C-API（source=ndk）：规则表覆盖 → 采规则表分类，reason 注明单源（规则表；C-API）', () => {
  const rules = loadRules();
  const marks = markIndex([]); // marks 不参与 C-API 判定（规则表单源）
  const { adaptation } = classify(inventoryOf([
    ['ndk', 'ace/xcomponent/native_interface_xcomponent.h', '*include*', 'a.cpp', 2],
    ['ndk', 'ace/xcomponent/native_interface_xcomponent.h', 'OH_NativeXComponent_RegisterCallback', 'a.cpp', 6]
  ]), rules, marks);
  const inc = findItem(adaptation, 'full_direct', 'ace/xcomponent/native_interface_xcomponent.h', '*include*');
  assert.ok(inc, 'xcomponent include 应归 full_direct');
  assert.match(inc.reason, /单源（规则表；C-API 判定源为规则表）/);
  assert.ok(findItem(adaptation, 'full_direct', 'ace/xcomponent/native_interface_xcomponent.h', 'OH_NativeXComponent_RegisterCallback'));
});

test('C-API：规则表未覆盖 → unknown（不猜分类）', () => {
  const rules = loadRules();
  const { adaptation } = classify(inventoryOf([
    ['ndk', 'native_media/avcodec.h', '*include*', 'a.cpp', 8],
    ['ndk', 'libblend.z.so', '*dlopen*', 'a.cpp', 12]
  ]), rules, null); // 降级路径同样规则表单源
  const item = findItem(adaptation, 'unknown', 'native_media/avcodec.h', '*include*');
  assert.ok(item);
  assert.match(item.reason, /判定依据未覆盖/);
  assert.ok(findItem(adaptation, 'unknown', 'libblend.z.so', '*dlopen*'));
});

test('C-API 替代建议兜底：非①桶 N/A → 需自行选择平台原生替代；①直连保 N/A；策展值不覆盖', () => {
  const rules = loadRules();
  const { adaptation } = classify(inventoryOf([
    ['ndk', 'hilog/log.h', '*include*', 'a.cpp', 1],
    ['ndk', 'arkui/native_node.h', '*include*', 'a.cpp', 2],
    ['ndk', 'multimedia/player_framework/native_avformat.h', '*include*', 'a.cpp', 3],
    ['ndk', 'native_media/avcodec.h', '*include*', 'a.cpp', 8]
  ]), rules, markIndex([]));
  assert.equal(findItem(adaptation, 'equivalent_bridge', 'hilog/log.h', '*include*').suggested_alternative,
    '需自行选择平台原生替代', '③ 策展值 N/A 应兜底为平台原生指引');
  assert.equal(findItem(adaptation, 'full_direct', 'arkui/native_node.h', '*include*').suggested_alternative,
    'N/A', '① 直连无替代语义保 N/A');
  assert.equal(findItem(adaptation, 'equivalent_bridge', 'multimedia/player_framework/native_avformat.h', '*include*').suggested_alternative,
    '@ohos.multimedia.media', '有策展替代值时不覆盖');
  assert.equal(findItem(adaptation, 'unknown', 'native_media/avcodec.h', '*include*').suggested_alternative,
    '需自行选择平台原生替代', 'unknown 兜底为平台原生指引');
});

test('C-API：SDK 标记在场也不参与判定（单源=规则表）', () => {
  const rules = loadRules();
  // 构造与规则表方向相反的 SDK 标记：C-API 仍按规则表出分类（无双源冲突路径）
  const marks = markIndex([['hilog/log.h', true, []]]);
  const { adaptation } = classify(
    inventoryOf([['ndk', 'hilog/log.h', '*include*', 'a.cpp', 3]]), rules, marks);
  assert.ok(findItem(adaptation, 'equivalent_bridge', 'hilog/log.h', '*include*'));
});

test('规则表含 platform 单平台条目（符号级）', () => {
  const rules = loadRules();
  const rule = rules.byKey.get('@ohos.mockSinglePlatform#mockAndroidOnlyApi');
  assert.ok(rule, '符号级单平台条目在场');
  assert.equal(rule.platform, 'android');
});

test('C-API 清单条目判定：arkui/rawfile/napi/plugin_utils → full_direct（reason 注明 docs 佐证）', () => {
  const rules = loadRules();
  const marks = markIndex([]);
  const { adaptation } = classify(inventoryOf([
    ['ndk', 'arkui/native_node.h', '*include*', 'a.cpp', 1],
    ['ndk', 'rawfile/raw_file_manager.h', '*include*', 'a.cpp', 2],
    ['ndk', 'rawfile/raw_file_manager.h', 'OH_ResourceManager_OpenRawFile', 'a.cpp', 3],
    ['ndk', 'napi/native_api.h', '*include*', 'a.cpp', 4],
    ['ndk', 'node_api.h', '*include*', 'a.cpp', 5],
    ['ndk', 'ace/xcomponent/native_interface_xcomponent.h', '*include*', 'a.cpp', 6]
  ]), rules, marks);
  for (const key of ['arkui/native_node.h#*include*', 'rawfile/raw_file_manager.h#*include*',
    'rawfile/raw_file_manager.h#OH_ResourceManager_OpenRawFile', 'napi/native_api.h#*include*',
    'node_api.h#*include*', 'ace/xcomponent/native_interface_xcomponent.h#*include*']) {
    const item = findItem(adaptation, 'full_direct', ...key.split('#'));
    assert.ok(item, `${key} 应归 full_direct`);
    assert.match(item.reason, /官方收录|参考收录|双平台/, `${key} reason 注明 docs 佐证`);
  }
});

test('plugin_utils：JNI 函数仅 Android 形态在 reason/advice 注明', () => {
  const rules = loadRules();
  const { adaptation } = classify(
    inventoryOf([['ndk', 'plugin_utils.h', '*include*', 'p.cpp', 1]]), rules, null);
  const item = findItem(adaptation, 'full_direct', 'plugin_utils.h', '*include*');
  assert.ok(item);
  assert.match(item.reason + item.advice, /Android JNI|仅 Android/);
});

test('撤下条目（无 docs 佐证）→ unknown（宁缺毋错）', () => {
  const rules = loadRules();
  const { adaptation } = classify(inventoryOf([
    ['ndk', 'native_drawing/native_drawing.h', '*include*', 'd.cpp', 1],
    ['ndk', 'ohos_init.h', '*include*', 'd.cpp', 2]
  ]), rules, markIndex([]));
  assert.ok(findItem(adaptation, 'unknown', 'native_drawing/native_drawing.h', '*include*'));
  assert.ok(findItem(adaptation, 'unknown', 'ohos_init.h', '*include*'));
  const item = findItem(adaptation, 'unknown', 'native_drawing/native_drawing.h', '*include*');
  assert.match(item.reason, /判定依据未覆盖/);
});

test('单平台清单条目：picker（android）/window（ios）符号级 platform 字段 + platform_trim 口径', () => {
  const rules = loadRules();
  assert.equal(rules.byKey.get('@ohos.file.picker#save').platform, 'android');
  assert.equal(rules.byKey.get('@ohos.window#on').platform, 'ios');
  //  口径统一：单平台唯一合法组合 = platform_trim + platform
  assert.equal(rules.byKey.get('@ohos.file.picker#save').category, 'platform_trim');
  assert.equal(rules.byKey.get('@ohos.window#on').category, 'platform_trim');
  const { adaptation } = classify(inventoryOf([
    ['ohos', '@ohos.file.picker', 'save', 'p.ets', 1],
    ['ohos', '@ohos.window', 'on', 'p.ets', 2]
  ]), rules, markIndex([])); // mini-sdk 无此二模块 d.ts → SDK absent → 单源（规则表）
  const save = findItem(adaptation, 'platform_trim', '@ohos.file.picker', 'save');
  const on = findItem(adaptation, 'platform_trim', '@ohos.window', 'on');
  assert.ok(save && on, '均归 platform_trim（口径）');
  assert.match(save.reason, /单源（规则表/);
  assert.match(on.reason, /单源（规则表/);
});

test('路径归一：带前缀形态（libarkui_ios/include/plugin_utils.h）经 basename 兜底命中规则条目', () => {
  const rules = loadRules();
  const { adaptation } = classify(inventoryOf([
    ['ndk', 'libarkui_ios/include/plugin_utils.h', '*include*', 'p.cpp', 1],
    ['ndk', 'arkui/../arkui/native_node.h', '*include*', 'p.cpp', 2]
  ]), rules, null);
  const item = findItem(adaptation, 'full_direct', 'libarkui_ios/include/plugin_utils.h', '*include*');
  assert.ok(item, '带前缀形态应经 basename 兜底命中');
  assert.match(item.reason, /Android JNI|参考收录/);
  // 全路径条目（如 arkui/native_node.h）不受兜底影响——此处构造的非常规路径仍落 unknown
  assert.ok(findItem(adaptation, 'unknown', 'arkui/../arkui/native_node.h', '*include*'));
});

// ── 残留：SDK 单源路径同样联动单平台警示 ───
test('window 命名空间命中模块级条目 → 双源一致采 reduced_direct + 单平台警示联动', () => {
  const rules = loadRules();
  //  起 @ohos.window 有模块级条目（reduced_direct，支持向）；
  // SDK 模块级标记为真（support）× 规则表 reduced_direct（支持向细分）→ 双源一致：采规则表细分
  const marks = markIndex([['@ohos.window', true, []]]);
  const { adaptation } = classify(
    inventoryOf([['ohos', '@ohos.window', 'window', 'w.ets', 1]]), rules, marks);
  const item = findItem(adaptation, 'reduced_direct', '@ohos.window', 'window');
  assert.ok(item, '应归 reduced_direct（双源一致采规则表细分）');
  assert.match(item.reason, /双源一致/, 'reason 注明双源一致');
  assert.match(item.reason, /仅 ios 平台的符号级条目/, '附单平台警示（同模块存在 iOS-only 符号条目）');
});

// ── ：未展开 @kit.* 条目 source=unknown ───
test('未知 kit source=unknown 透传；未展开闭源 kit 归 business_decision（策展条目命中给替代指引）', () => {
  const rules = loadRules();
  // 策展条目命中（@kit.PushKit 有模块级条目）
  const r1 = classify(inventoryOf([['unknown', '@kit.PushKit', 'pushService', 'p.ets', 1]]), rules, markIndex([]));
  const hit = findItem(r1.adaptation, 'business_decision', '@kit.PushKit', 'pushService');
  assert.ok(hit, 'PushKit 命中策展条目归 business_decision');
  assert.equal(hit.source, 'unknown', 'source 如实透传 unknown（统计口径不虚计）');
  assert.match(hit.suggested_alternative, /APNs/);
  // 无条目的未知 kit →  归类兜底（同样 business_decision，类比 @hms）
  const r2 = classify(inventoryOf([['unknown', '@kit.UnknownHmsKit', 'foo', 'p.ets', 1]]), rules, markIndex([]));
  const fall = findItem(r2.adaptation, 'business_decision', '@kit.UnknownHmsKit', 'foo');
  assert.ok(fall, '未知闭源 kit 归 business_decision');
  assert.match(fall.reason, /未展开[\s\S]*闭源生态/);
  assert.match(fall.advice, /HMS Core/);
});

// ── ：docs 实证条目 × SDK 无标记 → 采规则表（标记不全情形） ───
test('evidence=docs-verified 与 SDK 无标记"冲突"时采规则表（vibrator 实例），普通条目仍双源冲突 unknown', () => {
  const rules = loadRules();
  const vib = rules.byKey.get('@ohos.vibrator');
  assert.ok(vib, 'vibrator 模块级条目在场');
  assert.equal(vib.evidence, 'docs-verified');
  // SDK 无标记（unsupport 弱信号）× docs 实证支持 → full_direct（非 unknown）
  const marks = markIndex([['@ohos.vibrator', false, []]]);
  const { adaptation } = classify(inventoryOf([['ohos', '@ohos.vibrator', 'vibrator', 'v.ets', 1]]), rules, marks);
  const item = findItem(adaptation, 'full_direct', '@ohos.vibrator', 'vibrator');
  assert.ok(item, '应归 full_direct');
  assert.match(item.reason, /docs 实证/, 'reason 注明 docs 实证采信');
  // 对照：无 evidence 的普通条目冲突仍走  unknown（mini-sdk @ohos.mockConflict 场景延续）
  const mRules = { byKey: new Map([['@ohos.mockX#sym', { module: '@ohos.mockX', symbol: null, category: 'full_direct', reason: 'r', advice: 'a' }]]) };
  const m2 = classify(inventoryOf([['ohos', '@ohos.mockX', 'sym', 'x.ets', 1]]), mRules, markIndex([['@ohos.mockX', false, []]]));
  assert.ok(findItem(m2.adaptation, 'unknown', '@ohos.mockX', 'sym'), '普通条目冲突仍 unknown');
});
