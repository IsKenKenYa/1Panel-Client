import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, readFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { applyAdjudications } from './adjudicator.js';
import { validate } from './validator.js';
import { readFileSync as rf } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join as j } from 'node:path';

const schema = JSON.parse(rf(j(dirname(fileURLToPath(import.meta.url)), '..', 'rules', 'schemas', 'scan-report.schema.json'), 'utf8'));
const ITEM = (m, s) => ({ source: 'ohos', module: m, symbol: s, occurrences: 1, locations: ['a:1'], reason: '判定依据未覆盖', advice: 'x', suggested_alternative: 'N/A' });

function reportWith(unknown) {
  return { schema_version: 1, project_model: 'stage', inventory: [],
    adaptation: { full_direct: [], reduced_direct: [], equivalent_bridge: [], degraded_bridge: [], platform_trim: [], business_decision: [], unknown } };
}

function setup(unknown) {
  const dir = mkdtempSync(join(tmpdir(), 'f4-adj-'));
  const p = join(dir, 'scan-report.json');
  writeFileSync(p, JSON.stringify(reportWith(unknown)), 'utf8');
  return { dir, p };
}

test('裁决移桶（unknown→③）+reason 溯源，契约仍过  校验', () => {
  const { dir, p } = setup([ITEM('@ohos.batteryInfo', 'batterySOC')]);
  const r = applyAdjudications(p, [{ point: 'uk:@ohos.batteryInfo::batterySOC', chosen: 'equivalent_bridge', source: 'unknown' }]);
  assert.deepEqual(r.moved, ['@ohos.batteryInfo::batterySOC→equivalent_bridge']);
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.unknown.length, 0);
  assert.equal(out.adaptation.equivalent_bridge.length, 1);
  assert.ok(out.adaptation.equivalent_bridge[0].reason.includes('（F4 编排人工裁决：unknown→③等价桥接'));
  assert.equal(validate(out, schema).ok, true);
  rmSync(dir, { recursive: true, force: true });
});

test('keep_unknown=显式搁置——保持 unknown 桶+标注（与未处理区分）', () => {
  const { dir, p } = setup([ITEM('@ohos.mockFeature', 'legacyApi')]);
  const r = applyAdjudications(p, [{ point: 'uk:@ohos.mockFeature::legacyApi', chosen: 'keep_unknown', source: 'unknown' }]);
  assert.deepEqual(r.kept, ['@ohos.mockFeature::legacyApi']);
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.unknown.length, 1);
  assert.ok(out.adaptation.unknown[0].reason.includes('显式搁置'));
  assert.equal(validate(out, schema).ok, true);
  rmSync(dir, { recursive: true, force: true });
});

test('④⑤ 移桶目标正确', () => {
  const { dir, p } = setup([ITEM('@ohos.a', 'x'), ITEM('@ohos.b', 'y')]);
  applyAdjudications(p, [
    { point: 'uk:@ohos.a::x', chosen: 'degraded_bridge', source: 'unknown' },
    { point: 'uk:@ohos.b::y', chosen: 'platform_trim', source: 'unknown' },
  ]);
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.degraded_bridge.length, 1);
  assert.equal(out.adaptation.platform_trim.length, 1);
  rmSync(dir, { recursive: true, force: true });
});

test('幂等——重复回写不重复标注不移已移项', () => {
  const { dir, p } = setup([ITEM('@ohos.batteryInfo', 'batterySOC')]);
  const d = [{ point: 'uk:@ohos.batteryInfo::batterySOC', chosen: 'equivalent_bridge', source: 'unknown' }];
  applyAdjudications(p, d);
  const r2 = applyAdjudications(p, d);
  assert.equal;
  assert.equal;
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal((out.adaptation.equivalent_bridge[0].reason.match(/F4 编排人工裁决/g) ?? []).length, 1);
  rmSync(dir, { recursive: true, force: true });
});

test('bd 决策回写标注（不移桶，三产物口径一致）', () => {
  const { dir, p } = setup([]);
  const rep0 = reportWith([]);
  rep0.adaptation.business_decision = [ITEM('@hms.map', 'map.MapComponent')];
  writeFileSync(p, JSON.stringify(rep0), 'utf8');
  const r = applyAdjudications(p, [{ point: 'bd:@hms.map::map.MapComponent', chosen: '降级为OH替代', source: 'hms-closed' }]);
  assert.equal(r.moved.length, 0); // 不移桶
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.business_decision.length, 1); // 留在⑥桶
  assert.ok(out.adaptation.business_decision[0].reason.includes('F4 编排人工裁决：⑥→降级为OH替代'));
  assert.equal(validate(out, schema).ok, true);
  rmSync(dir, { recursive: true, force: true });
});

test('bd=降级为平台原生桥接→⑥移桶④+溯源（F3 消费④桶生成六件套），契约过  校验', () => {
  const { dir, p } = setup([]);
  const rep0 = reportWith([]);
  rep0.adaptation.business_decision = [ITEM('@kit.ScanKit', 'customScan')];
  writeFileSync(p, JSON.stringify(rep0), 'utf8');
  const r = applyAdjudications(p, [{ point: 'bd:@kit.ScanKit::customScan', chosen: '降级为平台原生桥接', source: 'kit-closed' }]);
  assert.deepEqual(r.moved, ['@kit.ScanKit::customScan→degraded_bridge']);
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.business_decision.length, 0); // 不在⑥桶
  assert.equal(out.adaptation.degraded_bridge.length, 1); // 移入④桶
  assert.ok(out.adaptation.degraded_bridge[0].reason.includes('（F4 编排人工裁决：⑥→④降级桥接（降级为平台原生桥接，触发 F3 六件套生成）'));
  assert.equal(validate(out, schema).ok, true);
  rmSync(dir, { recursive: true, force: true });
});

test('bd 桥接移桶幂等——重入不重复标注不移已移项', () => {
  const { dir, p } = setup([]);
  const rep0 = reportWith([]);
  rep0.adaptation.business_decision = [ITEM('@kit.ScanKit', 'customScan')];
  writeFileSync(p, JSON.stringify(rep0), 'utf8');
  const d = [{ point: 'bd:@kit.ScanKit::customScan', chosen: '降级为平台原生桥接', source: 'kit-closed' }];
  applyAdjudications(p, d);
  const r2 = applyAdjudications(p, d);
  assert.equal;
  assert.equal;
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.degraded_bridge.length, 1);
  assert.equal((out.adaptation.degraded_bridge[0].reason.match(/F4 编排人工裁决/g) ?? []).length, 1);
  rmSync(dir, { recursive: true, force: true });
});

test('bd 非桥接选择不误移桶（ohos-unique 恒不移）', () => {
  const { dir, p } = setup([]);
  const rep0 = reportWith([]);
  rep0.adaptation.business_decision = [ITEM('@ohos.distributedDeviceManager', 'deviceManager.getTrustedDeviceList')];
  writeFileSync(p, JSON.stringify(rep0), 'utf8');
  const r = applyAdjudications(p, [{ point: 'bd:@ohos.distributedDeviceManager::deviceManager.getTrustedDeviceList', chosen: '重新设计实现', source: 'ohos-unique' }]);
  assert.equal(r.moved.length, 0);
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.degraded_bridge.length, 0);
  assert.equal(out.adaptation.business_decision.length, 1);
  rmSync(dir, { recursive: true, force: true });
});

test('未决项不写（仅 chosen 落账后生效）', () => {
  const { dir, p } = setup([ITEM('@ohos.a', 'x')]);
  const r = applyAdjudications(p, [{ point: 'uk:@ohos.a::x', source: 'unknown' }]); // 无 chosen
  assert.equal(r.moved.length + r.kept.length, 0);
  const out = JSON.parse(readFileSync(p, 'utf8'));
  assert.equal(out.adaptation.unknown.length, 1);
  assert.ok(!out.adaptation.unknown[0].reason.includes('裁决'));
  rmSync(dir, { recursive: true, force: true });
});
