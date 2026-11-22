import { test } from 'node:test';
import assert from 'node:assert/strict';
import { renderJson, renderMarkdown, computePlatformRatio } from './report.js';
import { loadRules } from './classify.js';

function sampleReport() {
  return {
    schema_version: 1,
    project_model: 'stage',
    sdk: { path: '/sdk/26.0.0', version: '26.0.0', confirmed: true },
    inventory: [
      { source: 'ohos', module: '@ohos.router', symbol: 'router', file: 'a.ets', line: 1 }
    ],
    adaptation: {
      full_direct: [{
        source: 'ohos', module: '@ohos.notificationManager', symbol: 'publish',
        occurrences: 2, locations: ['a.ets:1', 'b.ets:4'],
        reason: '双源一致（SDK 支持标记 + 规则表）: ArkUI-X 已移植',
        advice: '直接使用', suggested_alternative: 'N/A'
      }],
      reduced_direct: [], equivalent_bridge: [{
        source: 'ohos', module: '@ohos.geoLocationManager', symbol: 'getCurrentLocation',
        occurrences: 1, locations: ['a.ets:9'],
        reason: '双源一致: 需平台桥接', advice: '由 F3 生成桥接', suggested_alternative: 'N/A'
      }], degraded_bridge: [{
        source: 'ohos', module: '@ohos.vibrator', symbol: 'startVibration',
        occurrences: 1, locations: ['a.ets:11'],
        reason: '双源一致: 双平台能力受限', advice: '由 F3 生成桥接并降级为基本振动', suggested_alternative: 'N/A'
      }], platform_trim: [], business_decision: [{
        source: 'hms', module: '@hms.map', symbol: 'MapComponent',
        occurrences: 1, locations: ['b.ets:2'],
        reason: '@hms.*（闭源）默认业务决策', advice: '评估开源地图方案',
        suggested_alternative: '需开发者评估'
      }], unknown: [{
        source: 'ohos', module: '@ohos.conflict', symbol: 'x',
        occurrences: 1, locations: ['c.ets:3'],
        reason: '双源冲突：SDK 标记支持跨平台，规则表归 ⑤平台裁剪',
        advice: '人工确认两源结论', suggested_alternative: 'N/A'
      }]
    }
  };
}

test('renderJson：键序固定，关键字段断言', () => {
  const text = renderJson(sampleReport());
  const parsed = JSON.parse(text);
  assert.deepEqual(Object.keys(parsed), ['schema_version', 'project_model', 'sdk', 'inventory', 'adaptation']);
  assert.deepEqual(Object.keys(parsed.adaptation), [
    'full_direct', 'reduced_direct', 'equivalent_bridge', 'degraded_bridge',
    'platform_trim', 'business_decision', 'unknown']);
  const item = parsed.adaptation.full_direct[0];
  assert.deepEqual(Object.keys(item), [
    'source', 'module', 'symbol', 'occurrences', 'locations', 'reason', 'advice', 'suggested_alternative']);
});

test('renderJson：降级报告无 sdk 字段', () => {
  const report = sampleReport();
  delete report.sdk;
  const parsed = JSON.parse(renderJson(report));
  assert.equal(parsed.sdk, undefined);
});

test('renderJson 确定性：同输入两次渲染逐字节一致', () => {
  assert.equal(renderJson(sampleReport()), renderJson(sampleReport()));
});

test('renderMarkdown：六分类组织+F3 桥接标注+⑥替代建议+unknown 清单', () => {
  const md = renderMarkdown(sampleReport(), {});
  assert.match(md, /① 完整直用/);
  assert.match(md, /③ 等价桥接（equivalent_bridge）— 将由 F3 生成桥接/);
  assert.match(md, /④ 降级桥接（degraded_bridge）— 将由 F3 生成桥接/);
  assert.match(md, /@hms\.map → MapComponent/);
  assert.match(md, /需开发者评估/);
  assert.match(md, /unknown — 待人工确认/);
  assert.match(md, /双源冲突/);
  assert.match(md, /\/sdk\/26\.0\.0/);
});

test('renderMarkdown：降级标注', () => {
  const report = sampleReport();
  delete report.sdk;
  const md = renderMarkdown(report, { degraded: true });
  assert.match(md, /SDK 未检出，单源判定/);
  assert.match(md, /未检出（单源判定）/);
});

test('renderMarkdown：FA 提示', () => {
  const report = sampleReport();
  report.project_model = 'fa';
  const md = renderMarkdown(report, {});
  assert.match(md, /FA 模型不支持，仅支持 Stage 模型/);
});

test('renderMarkdown：报告不含源码正文（仅白名单字段渲染）', () => {
  const md = renderMarkdown(sampleReport(), {});
  // 源码正文特征（函数体/语句）不应出现；仅位置与理由
  assert.doesNotMatch(md, /function foo|const x =|=> \{/);
});

test('renderMarkdown：来源列展示（ohos/hms/ndk）', () => {
  const report = sampleReport();
  report.adaptation.full_direct.push({
    source: 'ndk', module: 'ace/xcomponent/native_interface_xcomponent.h', symbol: '*include*',
    occurrences: 1, locations: ['a.cpp:2'], reason: '单源（规则表；C-API 判定源为规则表）: r',
    advice: '直接使用', suggested_alternative: 'N/A'
  });
  const md = renderMarkdown(report, {});
  assert.match(md, /\| ohos \|/);
  assert.match(md, /\| hms \|/);
  assert.match(md, /\| ndk \|/);
});

test('computePlatformRatio：分子=命中 platform 符号级条目，分母=已判定 @ohos.*（不含 unknown/@hms.*）', () => {
  const rules = loadRules();
  const report = sampleReport();
  // sampleReport 六分类 @ohos.*：notificationManager#publish、geoLocationManager#getCurrentLocation、
  // vibrator#startVibration = 3；再注入 2 个单平台命中条目 → 2/5
  report.adaptation.full_direct.push(
    { source: 'ohos', module: '@ohos.mockSinglePlatform', symbol: 'mockAndroidOnlyApi', occurrences: 1, locations: ['x.ets:1'], reason: 'r', advice: 'a', suggested_alternative: 'N/A' },
    { source: 'ohos', module: '@ohos.mockSinglePlatform', symbol: 'mockIosOnlyApi', occurrences: 1, locations: ['x.ets:2'], reason: 'r', advice: 'a', suggested_alternative: 'N/A' }
  );
  const ratio = computePlatformRatio(report, rules);
  assert.equal(ratio.denominator, 5);
  assert.equal(ratio.numerator, 2);
  assert.equal(ratio.known, true);
});

test('renderMarkdown：单平台占比统计节（实时计算）', () => {
  const rules = loadRules();
  const report = sampleReport();
  report.adaptation.full_direct.push({
    source: 'ohos', module: '@ohos.mockSinglePlatform', symbol: 'mockAndroidOnlyApi',
    occurrences: 1, locations: ['x.ets:1'], reason: 'r', advice: 'a', suggested_alternative: 'N/A'
  });
  const md = renderMarkdown(report, { rules });
  assert.match(md, /单平台支持接口占比：1\/4（25%）/);
});

test('renderMarkdown：规则表无单平台条目时显示 0% 并注明', () => {
  const rules = { meta: {}, byKey: new Map([['@ohos.router#router', { module: '@ohos.router', symbol: null, category: 'reduced_direct', reason: 'r', advice: 'a' }]]) };
  const md = renderMarkdown(sampleReport(), { rules });
  assert.match(md, /单平台支持接口占比：0%（规则表暂无单平台条目）/);
});

test('renderMarkdown：动态加载提示（变量/拼接形式位置清单）', () => {
  const md = renderMarkdown(sampleReport(), {
    dynamicHints: [
      { file: 'a.ets', line: 7, kind: 'dynamic-import' },
      { file: 'n.cpp', line: 24, kind: 'dlopen' }
    ]
  });
  assert.match(md, /存在不可静态解析的动态加载（dynamic import \/ dlopen）/);
  assert.match(md, /a\.ets:7（dynamic import）/);
  assert.match(md, /n\.cpp:24（dlopen）/);
});

test('真实单平台条目计入占比（picker#save + window#on → 2/2）', () => {
  const rules = loadRules();
  const report = sampleReport();
  report.adaptation.full_direct.push(
    { source: 'ohos', module: '@ohos.file.picker', symbol: 'save', occurrences: 1, locations: ['p.ets:1'], reason: 'r', advice: 'a', suggested_alternative: 'N/A' },
    { source: 'ohos', module: '@ohos.window', symbol: 'on', occurrences: 1, locations: ['p.ets:2'], reason: 'r', advice: 'a', suggested_alternative: 'N/A' }
  );
  const ratio = computePlatformRatio(report, rules);
  // 分母 = 原 3 条 @ohos.* + 2 条真实单平台条目 = 5；分子 = 2
  assert.equal(ratio.denominator, 5);
  assert.equal(ratio.numerator, 2);
  const md = renderMarkdown(report, { rules });
  assert.match(md, /单平台支持接口占比：2\/5（40%）/);
});

test('审计看护 G3：已判定 @ohos.* 条目为 0 时占比显示 0%（无已判定条目）而非 0/0', () => {
  const rules = loadRules();
  const report = sampleReport();
  report.adaptation.full_direct = [];
  report.adaptation.reduced_direct = [];
  report.adaptation.equivalent_bridge = [];
  report.adaptation.degraded_bridge = [];
  // 仅保留 hms 与 unknown 项 → 分母 0
  const md = renderMarkdown(report, { rules });
  assert.match(md, /单平台支持接口占比：0%（无已判定 @ohos\.\* 条目）/);
  assert.doesNotMatch(md, /0\/0（/);
});
