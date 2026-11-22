import { test } from 'node:test';
import { readFileSync } from 'node:fs';
import { fileURLToPath } from 'node:url';
import { dirname, join } from 'node:path';

const root = dirname(dirname(fileURLToPath(import.meta.url)));
const schema = JSON.parse(readFileSync(join(root, 'rules', 'schema.json'), 'utf8'));

const SKRS1_TOP_REQUIRED = ['schema_version', 'mode', 'platform', 'shared_arkts_dir', 'environment'];
const PLATFORM_REQUIRED = ['ready', 'missing'];
const ARKUIX_SDK_REQUIRED = ['detected', 'version', 'modify_available'];

test('顶层字段齐备且必填（platform 必填；壳字段条件必填不在 required）', () => {
  const props = schema.properties;
  for (const field of SKRS1_TOP_REQUIRED) {
    if (!(field in props)) throw new Error(`缺少顶层字段: ${field}`);
    if (!schema.required.includes(field)) throw new Error(`${field} 应为必填`);
  }
  if (schema.required.includes('android_shell') || schema.required.includes('ios_shell')) {
    throw new Error('壳字段应为条件必填（allOf/if-then），不在顶层 required');
  }
  for (const field of ['android_shell', 'ios_shell']) {
    if (!(field in props)) throw new Error(`缺少字段定义: ${field}`);
  }
});

test('mode 枚举为 modify/new', () => {
  const pm = schema.properties.mode;
  if (JSON.stringify(pm.enum) !== JSON.stringify(['modify', 'new'])) {
    throw new Error(`mode 枚举不符: ${JSON.stringify(pm.enum)}`);
  }
});

test('platform 枚举为 both/android/ios', () => {
  const pf = schema.properties.platform;
  if (JSON.stringify(pf.enum) !== JSON.stringify(['both', 'android', 'ios'])) {
    throw new Error(`platform 枚举不符: ${JSON.stringify(pf.enum)}`);
  }
});

test('壳字段条件必填（allOf if-then 两分支）', () => {
  const branches = schema.allOf || [];
  if (branches.length !== 2) throw new Error(`应有两个条件必填分支: ${branches.length}`);
  const androidBranch = branches.find((b) => (b.then?.required || []).includes('android_shell'));
  const iosBranch = branches.find((b) => (b.then?.required || []).includes('ios_shell'));
  if (!androidBranch) throw new Error('缺 android_shell 条件分支');
  if (!iosBranch) throw new Error('缺 ios_shell 条件分支');
  if (JSON.stringify(androidBranch.if.properties.platform.enum) !== JSON.stringify(['both', 'android'])) {
    throw new Error('android_shell 分支条件应为 platform ∈ {both, android}');
  }
  if (JSON.stringify(iosBranch.if.properties.platform.enum) !== JSON.stringify(['both', 'ios'])) {
    throw new Error('ios_shell 分支条件应为 platform ∈ {both, ios}');
  }
});

test('environment 结构 {android, ios, arkui_x_sdk}', () => {
  const env = schema.properties.environment;
  for (const key of ['android', 'ios']) {
    if (!(key in env.properties)) throw new Error(`environment 缺少 ${key}`);
    if (!env.required.includes(key)) throw new Error(`environment.${key} 应为必填`);
    const platform = env.properties[key].properties
      || schema.definitions[env.properties[key].$ref.split('/').pop()].properties;
    for (const f of PLATFORM_REQUIRED) {
      if (!(f in platform)) throw new Error(`environment.${key} 缺少 ${f}`);
    }
    if (platform.ready.type !== 'boolean') throw new Error('ready 应为 boolean');
    if (platform.missing.type !== 'array') throw new Error('missing 应为 array');
  }
  if (!env.required.includes('arkui_x_sdk')) throw new Error('environment.arkui_x_sdk 应为必填');
  const sdkDef = schema.definitions[env.properties.arkui_x_sdk.$ref.split('/').pop()];
  for (const f of ARKUIX_SDK_REQUIRED) {
    if (!(f in sdkDef.properties)) throw new Error(`arkui_x_sdk 缺少 ${f}`);
    if (!sdkDef.required.includes(f)) throw new Error(`arkui_x_sdk.${f} 应为必填`);
  }
  if (sdkDef.properties.detected.type !== 'boolean') throw new Error('arkui_x_sdk.detected 应为 boolean');
  if (sdkDef.properties.modify_available.type !== 'boolean') throw new Error('arkui_x_sdk.modify_available 应为 boolean');
});

test('schema_version 常量 1', () => {
  if (schema.properties.schema_version.const !== 1) throw new Error('schema_version 应为常量 1');
});

test('platform_baseline 可选字段：android 侧 min_sdk 必填、ios 侧 deployment_target 必填、两侧均不在顶层 required', () => {
  const pbRef = schema.properties.platform_baseline;
  if (!pbRef || !pbRef.$ref) throw new Error('缺少 platform_baseline 字段定义');
  const def = schema.definitions[pbRef.$ref.split('/').pop()];
  if (def.additionalProperties !== false) throw new Error('platformBaseline 应禁止多余字段');
  if (def.properties.android.required.join() !== 'min_sdk') throw new Error('android.min_sdk 应必填');
  if (def.properties.android.properties.min_sdk.type !== 'integer') throw new Error('min_sdk 应为 integer');
  if (def.properties.ios.required.join() !== 'deployment_target') throw new Error('ios.deployment_target 应必填');
  if (def.properties.ios.properties.deployment_target.type !== 'string') throw new Error('deployment_target 应为 string');
  if (schema.required.includes('platform_baseline')) throw new Error('platform_baseline 为可选字段，不应入顶层 required');
});

test('config_migration 可选字段（decision 必填枚举 yes/no；verification.ok 必填；不入顶层 required）', () => {
  const cmRef = schema.properties.config_migration;
  if (!cmRef || !cmRef.$ref) throw new Error('缺少 config_migration 字段定义');
  const def = schema.definitions[cmRef.$ref.split('/').pop()];
  if (def.additionalProperties !== false) throw new Error('configMigration 应禁止多余字段');
  if (JSON.stringify(def.required) !== JSON.stringify(['decision'])) throw new Error('decision 应为唯一必填');
  if (JSON.stringify(def.properties.decision.enum) !== JSON.stringify(['yes', 'no'])) throw new Error('decision 枚举 yes/no');
  const ver = def.properties.verification;
  if (JSON.stringify(ver.required) !== JSON.stringify(['ok'])) throw new Error('verification.ok 应必填');
  if (ver.properties.ok.type !== 'boolean') throw new Error('ok 应为 boolean');
  if (schema.required.includes('config_migration')) throw new Error('config_migration 为可选字段，不应入顶层 required');
});

test('platform_baseline.openharmony 可选子对象（compile_sdk_version/runtime_os/model_version 全可选字符串）', () => {
  const def = schema.definitions.platformBaseline;
  const oh = def.properties.openharmony;
  if (!oh) throw new Error('缺 openharmony 子对象定义');
  if (oh.additionalProperties !== false) throw new Error('openharmony 应禁止多余字段');
  if (oh.required) throw new Error('openharmony 字段全可选（实测提取到多少记多少）');
  for (const f of ['compile_sdk_version', 'runtime_os', 'model_version']) {
    if (oh.properties[f].type !== 'string') throw new Error(`${f} 应为 string`);
  }
});
