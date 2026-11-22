import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadDecisionMap, presentSix, sixItemsOf, askDecision, injectArgs } from './prompter.js';

const HMS = { source: 'hms', module: '@hms.map', symbol: 'map.MapComponent', suggested_alternative: '@ohos.map.mapComponent（开源地图组件）' };
const HMS2 = { source: 'hms', module: '@hms.push', symbol: 'pushService.getToken', suggested_alternative: '需开发者评估' };
const OH_UNIQUE = { source: 'ohos', module: '@ohos.distributedDeviceManager', symbol: 'deviceManager.getTrustedDeviceList' };

test('presentSix：@hms.*⑥→呈现替代建议+四选项（含平台原生桥接）', () => {
  const d = presentSix(HMS);
  assert.equal(d.source, 'hms-closed');
  assert.ok(d.question.includes('@ohos.map.mapComponent'));
  assert.deepEqual(d.options, ['降级为OH替代', '降级为平台原生桥接', '自行实现', '裁剪']);
  const d2 = presentSix(HMS2);
  assert.ok(d2.question.includes('需开发者评估'));
});

test('presentSix：@ohos.* 独有（从⑤降出⑥）→删除/重新设计', () => {
  const d = presentSix(OH_UNIQUE);
  assert.equal(d.source, 'ohos-unique');
  assert.deepEqual(d.options, ['删除', '重新设计实现']);
});

test('sixItemsOf：⑥全量提取（/G1：任意 source 的 business_decision + platform_trim 的 ohos，不静默忽略）', () => {
  const KIT = { source: 'unknown', module: '@kit.ScanKit', symbol: 'scan.startScan' };
  const OHBD = { source: 'ohos', module: '@ohos.application.BackupExtensionAbility', symbol: 'onBackup' };
  const report = { adaptation: { business_decision: [HMS, HMS2, KIT, OHBD], platform_trim: [OH_UNIQUE] } };
  const items = sixItemsOf(report);
  assert.equal(items.length, 5); // hms×2 + kit×1 + ohos⑥×1 + ohos⑤×1
  const kit = presentSix(KIT);
  assert.equal(kit.source, 'kit-closed');
  assert.deepEqual(kit.options, ['降级为OH替代', '降级为平台原生桥接', '自行实现', '裁剪']);
  const ohosBd = presentSix(OHBD);
  assert.equal(ohosBd.source, 'ohos-unique');
});

test('askDecision：预设应答注入→chosen', () => {
  const d = presentSix(HMS);
  const r = askDecision(d, { tty: false, presets: { [d.point]: '降级为OH替代' } });
  assert.equal(r.status, 'chosen');
  assert.equal(r.chosen, '降级为OH替代');
});

test('askDecision：非 TTY 缺预设→中止（码 4 语义源）', () => {
  const d = presentSix(HMS);
  const r = askDecision(d, { tty: false, presets: {} });
  assert.equal(r.status, 'aborted');
  assert.ok(r.reason.includes('非交互模式缺少预设应答'));
});

test('askDecision：预设值非法→中止', () => {
  const d = presentSix(HMS);
  const r = askDecision(d, { tty: false, presets: { [d.point]: '不存在的选项' } });
  assert.equal(r.status, 'aborted');
});

test('askDecision：TTY 连续 3 次无效应答→中止（边界）', () => {
  const answers = ['?', '??', '???'];
  const d = presentSix(HMS);
  const r = askDecision(d, { tty: true, presets: {}, readLine: () => answers.shift() ?? '' });
  assert.equal(r.status, 'aborted');
  assert.ok(r.reason.includes('连续 3 次无效'));
});

test('askDecision：TTY 合法应答→chosen', () => {
  const d = presentSix(HMS);
  const r = askDecision(d, { tty: true, presets: {}, readLine: () => '自行实现' });
  assert.equal(r.chosen, '自行实现');
});

test('ndk 题面措辞：NDK C-API 不再称"闭源 Kit"', () => {
  const d = presentSix({ source: 'ndk', module: 'multimedia/player_framework/native_avcodec_base.h', symbol: 'OH_AVCodec_x' });
  assert.ok(d.question.includes('NDK C-API（ArkUI-X 未交付）'));
  assert.equal(d.source, 'kit-closed');
});

test('presentUnknown：选项=③④⑤+显式搁置；缺预设=中止', async () => {
  const { presentUnknown, unknownItemsOf } = await import('./prompter.js');
  const item = { source: 'ohos', module: '@ohos.batteryInfo', symbol: 'batterySOC' };
  const d = presentUnknown(item);
  assert.equal(d.point, 'uk:@ohos.batteryInfo::batterySOC');
  assert.equal(d.source, 'unknown');
  assert.deepEqual(d.options, ['equivalent_bridge', 'degraded_bridge', 'platform_trim', 'keep_unknown']);
  const r = askDecision(d, { tty: false, presets: { 'uk:@ohos.batteryInfo::batterySOC': 'keep_unknown' } });
  assert.equal(r.chosen, 'keep_unknown');
  const aborted = askDecision(d, { tty: false, presets: {} });
  assert.equal(aborted.status, 'aborted');
  assert.equal(unknownItemsOf({ adaptation: { unknown: [item] } }).length, 1);
});

test('injectArgs：决策→子 Skill 参数映射（decision-map 声明）', () => {
  const map = loadDecisionMap();
  assert.deepEqual(injectArgs('skeleton_mode', 'new', map), ['new']);
  assert.deepEqual(injectArgs('overwrite', 'skip', map), ['--confirm-overwrite', 'skip']);
});

test('loadDecisionMap：损坏结构 fail-fast', () => {
  assert.throws(() => loadDecisionMap('/no/such/map.json'));
});
