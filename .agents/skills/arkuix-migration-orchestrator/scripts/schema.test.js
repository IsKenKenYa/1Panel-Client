import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync, existsSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';
import { validate } from './validator.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const schema = JSON.parse(readFileSync(join(root, 'rules/migration-state.schema.json'), 'utf8'));

test('Schema：顶层字段齐备（stages 四键/decisions/checkpoints/current_stage）', () => {
  assert.deepEqual(schema.required.sort(), ['checkpoints', 'current_stage', 'decisions', 'schema_version', 'stages'].sort());
  assert.deepEqual(Object.keys(schema.properties.stages.properties).sort(), ['bridge', 'report', 'scan', 'skeleton'].sort());
  assert.equal(schema.properties.current_stage.enum.includes('done'), true);
});

test('Schema：stage 状态枚举/decisions 项/checkpoints 项（interrupted_at 可选缺席）', () => {
  const st = schema.definitions.stage;
  assert.deepEqual(st.properties.status.enum.sort(), ['done', 'failed', 'pending', 'running', 'skipped'].sort());
  const d = schema.definitions.decision;
  assert.deepEqual(d.properties.source.enum.sort(), ['hms-closed', 'kit-closed', 'ohos-unique', 'unknown'].sort());
  assert.equal('chosen' in d.properties, true);
  const cp = schema.definitions.checkpoint;
  assert.deepEqual(cp.required.sort(), ['at', 'snapshot', 'stage'].sort());
  assert.equal('interrupted_at' in schema.properties, true);
});

test('实例校验：合法最小实例通过；缺字段被拒（validator 联动）', () => {
  const ok = {
    schema_version: 1,
    stages: { scan: { status: 'pending', artifacts: [] }, skeleton: { status: 'pending', artifacts: [] }, bridge: { status: 'pending', artifacts: [] }, report: { status: 'pending', artifacts: [] } },
    current_stage: 'scan', decisions: [], checkpoints: [],
  };
  assert.equal(validate(ok, schema).ok, true);
  const bad = { ...ok, stages: { ...ok.stages, scan: { status: 'bogus' } } };
  assert.equal(validate(bad, schema).ok, false);
});

test('三族 Schema 副本在场+版本注记', () => {
  for (const f of ['scan-report', 'skeleton-result', 'bridge-artifact']) {
    assert.ok(readFileSync(join(root, `rules/schemas/${f}.schema.json`), 'utf8').length > 0);
  }
  const v = JSON.parse(readFileSync(join(root, 'rules/schemas/VERSIONS.json'), 'utf8'));
  assert.equal(v['bridge-artifact'].source, 'arkuix-bridge-codegen');
});

// ── pattern 契约闸：相对路径禁反斜杠（win32 漏归一在此被拦下）；绝对原生路径（sdk.path）不受限 ──
test('pattern 闸：locations 反斜杠形态被拒，"/" 形态通过；sdk.path 原生路径不受限', () => {
  const scanSchema = existsSync(join(root, 'rules/schemas/scan-report.schema.json'))
    ? JSON.parse(readFileSync(join(root, 'rules/schemas/scan-report.schema.json'), 'utf8')) : schema;
  const mk = (sdkPath) => ({
    schema_version: 1, project_model: 'stage',
    sdk: { path: sdkPath, version: '26.0.0', confirmed: true, origin: 'explicit' },
    inventory: [], adaptation: { full_direct: [], reduced_direct: [], equivalent_bridge: [],
      degraded_bridge: [], platform_trim: [], business_decision: [], unknown: [] },
  });
  const withLoc = (loc) => { const r = mk('/x'); r.adaptation.unknown.push({
    source: 'ohos', module: '@ohos.mock', symbol: 'm', occurrences: 1, locations: [loc],
    reason: 'r', advice: 'a', suggested_alternative: '' }); return r; };
  const bad = validate(withLoc('entry\\src\\Index.ets:3'), scanSchema);
  assert.equal(bad.ok, false, '反斜杠 locations 应被 pattern 闸拒绝');
  assert.ok(bad.errors.some((e) => e.includes('不匹配约束')), bad.errors.join(';'));
  const good = validate(withLoc('entry/src/Index.ets:3'), scanSchema);
  assert.equal(good.ok, true, '"/" 形态通过：' + good.errors.join(';'));
  const winSdk = validate(mk('C:\\Users\\x\\Sdk\\26.0.0'), scanSchema);
  assert.equal(winSdk.ok, true, 'sdk.path 绝对原生路径不受 pattern 限制：' + winSdk.errors.join(';'));
});
