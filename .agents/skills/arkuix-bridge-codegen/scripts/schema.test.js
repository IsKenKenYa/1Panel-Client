import { test } from 'node:test';
import assert from 'node:assert/strict';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
const schema = JSON.parse(readFileSync(join(root, 'rules/schema.json'), 'utf8'));

test('Schema：顶层字段齐备（schema_version/artifacts/unmapped_native_apis）', () => {
  assert.equal(schema.required.length, 3);
  assert.deepEqual(schema.required.sort(), ['artifacts', 'schema_version', 'unmapped_native_apis'].sort());
  assert.equal(schema.properties.schema_version.const, 1);
  assert.equal(schema.properties.artifacts.type, 'array');
  assert.equal(schema.properties.unmapped_native_apis.type, 'array');
});

test('Schema：artifacts 项字段（五件路径+③④分类+local_status）', () => {
  const a = schema.definitions.artifact;
  assert.deepEqual(a.properties.category.enum.sort(), ['degraded_bridge', 'equivalent_bridge'].sort());
  assert.deepEqual(a.properties.local_status.enum.sort(), ['failed', 'migrated'].sort());
  const files = schema.definitions.files; // artifact.files 为 $ref → definitions.files
  assert.deepEqual(files.required.sort(), ['android', 'arkui_x', 'interface', 'ios', 'local'].sort());
  assert.equal(files.additionalProperties, false);
  assert.equal(a.additionalProperties, false);
});

test('Schema：min_android/min_ios 可选字段（适用版本澄清；字符串、不入 required）', () => {
  const a = schema.definitions.artifact;
  assert.equal(a.properties.min_android.type, 'string');
  assert.equal(a.properties.min_ios.type, 'string');
  assert.ok(!a.required.includes('min_android') && !a.required.includes('min_ios'), '可选字段不入 required');
});
