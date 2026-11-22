import { test } from 'node:test';
import assert from 'node:assert/strict';
import { composeReport } from './report.js';
import { StateManager } from './state-manager.js';

const state = () => {
  const s = StateManager.fresh();
  s.stages.scan = { status: 'done', artifacts: ['scan-report.json'], exit_code: 0 };
  s.stages.skeleton = { status: 'done', artifacts: ['skeleton-result.json'], exit_code: 0 };
  s.stages.bridge = { status: 'done', artifacts: ['bridge-artifact.json'], exit_code: 0 };
  s.decisions = [
    { point: 'skeleton_mode', question: '骨架生成模式', options: ['modify', 'new'], chosen: 'modify' },
    { point: 'bd:@hms.map::MapComponent', question: 'q', options: ['降级为OH替代', '自行实现', '裁剪'], chosen: '降级为OH替代', source: 'hms-closed' },
    { point: 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList', question: 'q', options: ['删除', '重新设计实现'], source: 'ohos-unique' },
  ];
  return s;
};

const artifacts = () => ({
  scan: { adaptation: {
    full_direct: [{ module: '@ohos.router', symbol: 'router.pushUrl', source: 'ohos' }],
    reduced_direct: [{ module: '@ohos.web', symbol: 'WebComponent', source: 'ohos' }],
    degraded_bridge: [{ module: '@ohos.vibrator', symbol: 'startVibration', source: 'ohos' }],
    unknown: [{ module: '@ohos.nonsense', symbol: 'mysteryApi', source: 'ohos' }],
  } },
  skeleton: { mode: 'modify', platform: 'both' },
  bridge: { artifacts: [{ name: 'DeviceInfoUdid', category: 'equivalent_bridge', files: { interface: 'commons/deviceInfo/interface/DeviceInfoUdidInterface.ets' }, local_status: 'migrated' }], unmapped_native_apis: ['@ohos.nonsense::mysteryApi'] },
});

test('报告 5 段结构齐备+各段非空', () => {
  const md = composeReport(state(), artifacts());
  for (const h of ['一、已转换项', '二、降级标记', '三、桥接项', '四、未解决项', '五、决策记录']) {
    assert.ok(md.includes(h), h);
  }
  assert.ok(md.includes('router.pushUrl'));       // 已转换
  assert.ok(md.includes('startVibration'));       // 降级
  assert.ok(md.includes('DeviceInfoUdid'));       // 桥接
  assert.ok(md.includes('mysteryApi'));           // 未解决（unknown+unmapped）
  assert.ok(md.includes('skeleton_mode'));        // 决策记录
});

test('N2-A：源码改写工单段（决策→位置→建议动作）', () => {
  const md = composeReport(state(), artifacts());
  assert.ok(md.includes('六、源码改写工单'));
  assert.ok(md.includes('@hms.map::MapComponent | 降级为OH替代')); // bd 决策行
  assert.ok(md.includes('调用点替换为替代实现：')); // 降级替代动作文案
});

test('安全声明在场', () => {
  const md = composeReport(state(), artifacts());
  assert.ok(md.includes('未发起网络外传'));
});

// ── 适用版本与环境要求段 ─────────────────────────────────
test('适用版本段：工程基线（F1 platform_baseline）+ 逐接口 min_* 优先 + 更新开发环境提示', () => {
  const arts = artifacts();
  arts.skeleton = { mode: 'modify', platform: 'both',
    platform_baseline: { android: { min_sdk: 26, target_sdk: 33, compile_sdk: 33 }, ios: { deployment_target: '10.0' } } };
  arts.bridge.artifacts.push({ name: 'BatteryInfoBatterySOC', category: 'equivalent_bridge',
    files: { interface: 'a' }, local_status: 'migrated', min_android: 'API 21+', min_ios: 'iOS 9.0+' });
  const md = composeReport(state(), arts);
  assert.ok(md.includes('七、适用版本与环境要求'), '新段在场');
  assert.ok(md.includes('Android minSdkVersion 26'), '工程基线 Android 行');
  assert.ok(md.includes('iOS deployment target 10.0'), '工程基线 iOS 行');
  assert.ok(md.includes('BatteryInfoBatterySOC：API 21+ / iOS 9.0+'), '逐接口标注清单');
  assert.ok(md.includes('逐接口标注（最低版本）优先于工程基线'), '优先级规则说明');
  assert.ok(md.includes('升级 ArkUI-X SDK / Android SDK / Xcode 后重试'), '更新开发环境提示');
  assert.ok(md.includes('最低版本 API 21+ / iOS 9.0+'), '桥接段条目版本后缀');
});

test('适用版本段：无 skeleton 基线时如实声明（不编造数值），提示语恒在场', () => {
  const md = composeReport(state(), artifacts());
  assert.ok(md.includes('未取得 skeleton-result.platform_baseline'));
  assert.ok(md.includes('升级 ArkUI-X SDK / Android SDK / Xcode 后重试'), '提示恒在场');
});

test('同源汇总：⑥已决策降级项入降级段、未决策⑥入未解决段（/不自判）', () => {
  const md = composeReport(state(), artifacts());
  assert.ok(md.includes('（⑥决策：降级为OH替代）'));
  assert.ok(md.includes('deviceManager.getTrustedDeviceList（⑥未决策）'));
});

test('skipped 阶段标注"未执行"', () => {
  const s = state();
  s.stages.bridge = { status: 'skipped', artifacts: [] };
  const md = composeReport(s, { ...artifacts(), bridge: null });
  assert.ok(md.includes('未执行（阶段未选择）'));
});

// ── 兜底：F4 报告透出 F3 产物自检残缺 ─────────────────────────────────
test('bridge-artifact.audit.deficient 透出至"生成降级"段（agent 补全指引）', () => {
  const st = state();
  const arts = artifacts();
  arts.bridge = {
    artifacts: [{ name: 'SensorSensor', symbol: 'sensor', category: 'equivalent_bridge',
      files: { interface: 'a', local: 'b', arkui_x: 'c', android: 'd', ios: 'e' }, local_status: 'migrated' }],
    unmapped_native_apis: [],
    audit: { checked: 1, deficient_count: 1, suggestion_count: 0,
      deficient: [{ name: 'SensorSensor', symbol: 'sensor', issues: [{
        file: 'commons/sensor/utils/SensorSensorLocal.ets', kind: 'local-unbalanced',
        detail: '②Local 括号不闭合（净深度 +2）——不可编译',
        action: '读取源工程 locations（x.ets:12）对应完整语句，补全本文件' }] }],
      suggestions: [] },
  };
  const md = composeReport(st, arts);
  assert.ok(md.includes('SensorSensor【local-unbalanced】'), '残缺项透出');
  assert.ok(md.includes('补全本文件'), 'action 指引随行（agent 可执行）');
});

// ── OH 基线行字段缺失降级（modify 模式无 compile_sdk_version 时的拼装形态）──
test('适用版本段：openharmony 基线无 compile_sdk_version → 按 runtimeOS/modelVersion 拼装且零 undefined', () => {
  const arts = artifacts();
  arts.skeleton.platform_baseline = { openharmony: { runtime_os: 'OpenHarmony', model_version: '26.0.0' } };
  const md = composeReport(state(), arts);
  assert.ok(!md.includes('undefined'), '任何字段缺失不产生 undefined 字样');
  assert.ok(md.includes('runtimeOS OpenHarmony，hvigor modelVersion 26.0.0（modify 模式未做版本选择）'),
    '缺 compile_sdk_version 时显式注明未做版本选择');
});
test('适用版本段：openharmony 基线含 compile_sdk_version → 落账尾注保持', () => {
  const arts = artifacts();
  arts.skeleton.platform_baseline = { openharmony: { compile_sdk_version: '24', runtime_os: 'OpenHarmony', model_version: '6.1.1' } };
  const md = composeReport(state(), arts);
  assert.ok(md.includes('OpenHarmony compileSdkVersion 24，runtimeOS OpenHarmony，hvigor modelVersion 6.1.1——Compile SDK 版本选择落账'),
    '版本选择落账行');
});

// ── OH 基线行前缀按实际运行时形态（与源工程同步语义下可为 HarmonyOS）──
test('适用版本段：openharmony 形态为 HarmonyOS → 基线行前缀如实', () => {
  const arts = artifacts();
  arts.skeleton.platform_baseline = { openharmony: { compile_sdk_version: '5.0.5(17)', runtime_os: 'HarmonyOS', model_version: '5.0.5' } };
  const md = composeReport(state(), arts);
  assert.ok(md.includes('HarmonyOS compileSdkVersion 5.0.5(17)，runtimeOS HarmonyOS，hvigor modelVersion 5.0.5——Compile SDK 版本选择落账'),
    '前缀随 runtime_os 如实呈现');
});

// ── 第七段改进：桥接接口全量列出（有版本标注+未标注），空列表降级说明 ──
test('适用版本段：桥接接口全量列出——有版本标注的+未标注的（适用工程基线）', () => {
  const arts = artifacts();
  arts.skeleton.platform_baseline = { android: { min_sdk: 26 }, ios: { deployment_target: '10.0' } };
  arts.bridge.artifacts.push({ name: 'DeviceInfoUdid', category: 'equivalent_bridge', files: { interface: 'a' }, local_status: 'migrated', min_android: 'API 21+', min_ios: 'iOS 9+' });
  arts.bridge.artifacts.push({ name: 'ScanKitScanBarcode', category: 'degraded_bridge', files: { interface: 'b' }, local_status: 'migrated' });
  const md = composeReport(state(), arts);
  assert.ok(md.includes('DeviceInfoUdid：API 21+ / iOS 9+'), '有版本标注的接口列出');
  assert.ok(md.includes('ScanKitScanBarcode：（版本未标注'), '未标注的接口也列出（附适用工程基线说明）');
});

test('适用版本段：无桥接接口（③④桶空）→ 降级说明而非空段', () => {
  const arts = artifacts();
  arts.skeleton.platform_baseline = { android: { min_sdk: 26 } };
  arts.bridge.artifacts = [];
  const md = composeReport(state(), arts);
  assert.ok(md.includes('逐接口版本标注：本次迁移无桥接接口'), '空列表时降级说明');
});

// ── 第七段三类区分：有版本标注 / 在 map 无版本 / 不在 map（unmapped）──
test('适用版本段：三类区分——有版本+在 map 无版本+unmapped 需人工确认', () => {
  const arts = artifacts();
  arts.skeleton.platform_baseline = { android: { min_sdk: 26 } };
  arts.bridge.artifacts = [
    { name: 'Camera', files: { interface: 'a' }, min_android: 'API 21+', min_ios: 'iOS 7+' },
    { name: 'Sensor', files: { interface: 'b' } }, // 在 map 但无 min_*（无 unmapped 标记）
    { name: 'ScanKit', files: { interface: 'c' }, unmapped: true }, // 不在 map
  ];
  const md = composeReport(state(), arts);
  assert.ok(md.includes('Camera：API 21+ / iOS 7+'), '有版本标注');
  assert.ok(md.includes('Sensor：（版本未标注——适用工程基线）'), '在 map 无版本→适用基线');
  assert.ok(md.includes('ScanKit：（原生 API 映射未策展——需人工确认替代 API 及版本要求）'), 'unmapped→需人工确认');
});
