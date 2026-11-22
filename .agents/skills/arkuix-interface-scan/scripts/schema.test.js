import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const schemaPath = join(root, 'rules', 'schema.json');

const schema = JSON.parse(readFileSync(schemaPath, 'utf8'));

const SRS1_TOP_REQUIRED = ['schema_version', 'project_model', 'sdk', 'inventory', 'adaptation'];
const ADAPTATION_BUCKETS = [
  'full_direct', 'reduced_direct', 'equivalent_bridge', 'degraded_bridge',
  'platform_trim', 'business_decision', 'unknown'
];
const ADAPTATION_ITEM_REQUIRED = [
  'source', 'module', 'symbol', 'occurrences', 'locations', 'reason',
  'advice', 'suggested_alternative'
];
const INVENTORY_ITEM_REQUIRED = ['source', 'module', 'symbol', 'file', 'line'];

test('顶层字段齐备且必填性正确（sdk 为可选）', () => {
  const props = schema.properties;
  for (const field of SRS1_TOP_REQUIRED) {
    if (!(field in props)) throw new Error(`缺少顶层字段: ${field}`);
  }
  const required = schema.required;
  for (const field of SRS1_TOP_REQUIRED.filter((f) => f !== 'sdk')) {
    if (!required.includes(field)) throw new Error(`${field} 应为必填`);
  }
  if (required.includes('sdk')) throw new Error('sdk 应为可选（降级路径缺省）');
});

test('project_model 枚举为 stage/fa/unknown', () => {
  const pm = schema.properties.project_model;
  if (JSON.stringify(pm.enum) !== JSON.stringify(['stage', 'fa', 'unknown'])) {
    throw new Error(`project_model 枚举不符: ${JSON.stringify(pm.enum)}`);
  }
});

test('sdk 字段结构 {path, version, confirmed}', () => {
  const sdk = schema.properties.sdk.properties;
  for (const f of ['path', 'version', 'confirmed']) {
    if (!(f in sdk)) throw new Error(`sdk 缺少字段: ${f}`);
  }
  if (schema.properties.sdk.properties.confirmed.type !== 'boolean') {
    throw new Error('sdk.confirmed 应为 boolean');
  }
});

test('adaptation 固定七桶', () => {
  const props = schema.properties.adaptation.properties;
  const buckets = Object.keys(props);
  for (const b of ADAPTATION_BUCKETS) {
    if (!buckets.includes(b)) throw new Error(`adaptation 缺少桶: ${b}`);
  }
  if (buckets.length !== ADAPTATION_BUCKETS.length) {
    throw new Error(`adaptation 桶数量不符: ${buckets}`);
  }
});

test('adaptation 项字段与必填齐备', () => {
  const bucket = schema.properties.adaptation.properties.full_direct;
  const arraySchema = bucket.items || schema.definitions[bucket.$ref.split('/').pop()];
  const item = arraySchema.items;
  const props = item.properties;
  for (const f of ADAPTATION_ITEM_REQUIRED) {
    if (!(f in props)) throw new Error(`adaptation 项缺少字段: ${f}`);
  }
  for (const f of ADAPTATION_ITEM_REQUIRED) {
    if (!item.required.includes(f)) throw new Error(`adaptation 项 ${f} 应为必填`);
  }
  if (JSON.stringify(props.source.enum) !== JSON.stringify(['ohos', 'hms', 'ndk', 'unknown'])) {
    throw new Error('adaptation 项 source 枚举应为 ohos/hms/ndk/unknown');
  }
});

test('inventory 项 source 枚举含 ndk（增补 unknown）', () => {
  const invSource = schema.properties.inventory.items.properties.source;
  if (JSON.stringify(invSource.enum) !== JSON.stringify(['ohos', 'hms', 'ndk', 'unknown'])) {
    throw new Error(`inventory 项 source 枚举应为 ohos/hms/ndk/unknown: ${JSON.stringify(invSource.enum)}`);
  }
});

test('inventory 项字段与必填齐备，line>=1', () => {
  const item = schema.properties.inventory.items;
  for (const f of INVENTORY_ITEM_REQUIRED) {
    if (!(f in item.properties)) throw new Error(`inventory 项缺少字段: ${f}`);
    if (!item.required.includes(f)) throw new Error(`inventory 项 ${f} 应为必填`);
  }
  if (item.properties.line.minimum !== 1) throw new Error('line 最小值应为 1');
});

test('schema_version 常量 1', () => {
  const sv = schema.properties.schema_version;
  if (sv.const !== 1) throw new Error('schema_version 应为常量 1');
});
