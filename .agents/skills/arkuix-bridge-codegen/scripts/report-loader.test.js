import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { loadScanReport, extractBridges, isEmptyBridgeList, bridgeNameOf, FormatError } from './report-loader.js';

function reportWith(adaptation) {
  return { schema_version: 1, project_model: 'stage', inventory: [], adaptation };
}
const item = (over = {}) => ({
  module: '@ohos.deviceInfo', symbol: 'udid', occurrences: 1, locations: ['entry/src/main/ets/pages/Index.ets:10'],
  reason: 'r', advice: 'a', source: 'ohos', suggested_alternative: 'N/A', ...over,
});

test('loadScanReport：合法报告通过并提取③④清单', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f3-loader-'));
  const file = join(dir, 'report.json');
  writeFileSync(file, JSON.stringify(reportWith({
    equivalent_bridge: [item()], degraded_bridge: [item({ module: '@ohos.vibrator', symbol: 'startVibration' })],
    full_direct: [], reduced_direct: [], platform_trim: [], business_decision: [], unknown: [],
  })));
  const report = loadScanReport(file);
  const items = extractBridges(report);
  assert.equal(items.length, 2);
  assert.equal(items[0].category, 'equivalent_bridge');
  assert.equal(items[1].category, 'degraded_bridge');
  rmSync(dir, { recursive: true, force: true });
});

test('loadScanReport：缺 adaptation 字段→FormatError（码 3 语义源）', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f3-loader-'));
  const file = join(dir, 'report.json');
  writeFileSync(file, JSON.stringify({ schema_version: 1, project_model: 'stage', inventory: [] }));
  assert.throws(() => loadScanReport(file), (e) => e instanceof FormatError && e.message.includes('缺少adaptation'));
  rmSync(dir, { recursive: true, force: true });
});

test('loadScanReport：字段类型不符（equivalent_bridge 非数组）→FormatError', () => {
  const dir = mkdtempSync(join(tmpdir(), 'f3-loader-'));
  const file = join(dir, 'report.json');
  writeFileSync(file, JSON.stringify(reportWith({ equivalent_bridge: {}, degraded_bridge: [] })));
  assert.throws(() => loadScanReport(file), (e) => e instanceof FormatError && e.message.includes('equivalent_bridge'));
  rmSync(dir, { recursive: true, force: true });
});

test('isEmptyBridgeList：③④均空→true（良性完成）', () => {
  const r = reportWith({ equivalent_bridge: [], degraded_bridge: [] });
  assert.equal(isEmptyBridgeList(r), true);
});

test('extractBridges：同接口（module+symbol）跨桶去重，至多一套五件套（边界）', () => {
  const r = reportWith({
    equivalent_bridge: [item()],
    degraded_bridge: [item()], // 同接口重复入桶
  });
  assert.equal(extractBridges(r).length, 1);
});

test('bridgeNameOf：module 后缀+symbol 分段驼峰（确定性）', () => {
  assert.equal(bridgeNameOf('@ohos.deviceInfo', 'udid'), 'DeviceInfoUdid');
  assert.equal(bridgeNameOf('@ohos.geolocation', 'geolocation.getCurrentLocation'), 'GeolocationGetCurrentLocation');
});

test('G4：*include* 头文件依赖跳过（不生成桥接件，清单披露）+ 同名去重', () => {
  const r = reportWith({
    equivalent_bridge: [item({ module: 'a/x.h', symbol: '*include*' }), item({ module: 'b/x.h', symbol: '*include*' }), item()],
    degraded_bridge: [],
  });
  const items = extractBridges(r);
  assert.equal(items.length, 1); // include 项被跳过
  assert.equal(items.skippedIncludes.length, 2);
});
