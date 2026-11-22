import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import {
  loadSdkVersions, listSupported, resolveVersionEntry, compareVersionKeys,
  highestVersionEntry, menuIndexOf, openharmonyCompileSdkOf, detectSourceSdkVersion,
  compileSdkWriteOf, detectSourceRuntimeOS
} from './sdk-versions.js';

test('版本表完整性：16 键（10..24 + 26.0.0，无 25）；字段齐备（ON 表策展源）', () => {
  const doc = loadSdkVersions();
  const keys = doc.versions.map((v) => v.key);
  assert.equal(keys.length, 16, JSON.stringify(keys));
  assert.ok(!keys.includes('25'), 'ON 表无 25 键（ace 一致）');
  assert.equal(keys[0], '10');
  assert.equal(keys[keys.length - 1], '26.0.0', '插入序=菜单序，26.0.0 为最后一项');
  for (const v of doc.versions) {
    for (const f of ['devEcoVersion', 'compileSdkVersion', 'compatibleSdkVersion', 'modelVersion', 'hvigorPlugin']) {
      assert.equal(typeof v[f], 'string', `${v.key}.${f}`);
    }
  }
});

test('关键条目抽查（ON 表实测值）：24=6.1.1(24)/plugin 4.24.2；22=6.0.2(22)/4.22.3；26.0.0 裸版本', () => {
  const e24 = resolveVersionEntry('24');
  assert.equal(e24.compileSdkVersion, '6.1.1(24)');
  assert.equal(e24.modelVersion, '6.1.1');
  assert.equal(e24.hvigorPlugin, '4.24.2');
  const e22 = resolveVersionEntry('22');
  assert.equal(e22.compileSdkVersion, '6.0.2(22)');
  assert.equal(e22.hvigorPlugin, '4.22.3');
  const e26 = resolveVersionEntry('26.0.0');
  assert.equal(e26.compileSdkVersion, '26.0.0');
  assert.equal(e26.hvigorPlugin, '4.24.2');
});

test('resolveVersionEntry：版本键/全形态/devEcoVersion 反查；未收录 null（不猜测）', () => {
  assert.equal(resolveVersionEntry('23').key, '23');
  assert.equal(resolveVersionEntry('6.1.0(23)').key, '23');
  assert.equal(resolveVersionEntry('6.1.1(24)').key, '24');
  assert.equal(resolveVersionEntry('5.0.5').key, '13', 'devEcoVersion 反查（ON 表：13=5.0.5，17=5.0.13）');
  assert.equal(resolveVersionEntry('25'), null);
  assert.equal(resolveVersionEntry(''), null);
  assert.equal(resolveVersionEntry('nonsense'), null);
});

test('菜单编号（表插入序 1..16）：10=1、24=15、26.0.0=16；未收录 null', () => {
  assert.equal(menuIndexOf('10'), 1);
  assert.equal(menuIndexOf('24'), 15);
  assert.equal(menuIndexOf('26.0.0'), 16);
  assert.equal(menuIndexOf('25'), null);
});

test('OpenHarmony 形态 compileSdk 写法（ace modifyOpenHarmonyOSConfig 实证）：<26 数字 apiLevel；26.0.0 字符串', () => {
  assert.deepEqual(openharmonyCompileSdkOf(resolveVersionEntry('24')), 24);
  assert.deepEqual(openharmonyCompileSdkOf(resolveVersionEntry('10')), 10);
  assert.equal(openharmonyCompileSdkOf(resolveVersionEntry('26.0.0')), '26.0.0');
});

test('最高版本=26.0.0；语义化键比较（26.0.0 > 24 > 10）', () => {
  assert.equal(highestVersionEntry().key, '26.0.0');
  assert.ok(compareVersionKeys('26.0.0', '24') > 0);
  assert.ok(compareVersionKeys('24', '10') > 0);
  assert.equal(listSupported().length, 16);
});

test('detectSourceSdkVersion：源 build-profile 全形态/数字/OpenHarmony 裸版本均可探测；缺文件/未收录 null', () => {
  const mk = (content) => {
    const dir = mkdtempSync(join(tmpdir(), 'f1-sdkver-'));
    writeFileSync(join(dir, 'build-profile.json5'), content, 'utf8');
    return dir;
  };
  const a = mk('{ "app": { "products": [{ "name": "default", "compatibleSdkVersion": "6.1.0(23)" }] } }');
  assert.equal(detectSourceSdkVersion(a).key, '23', 'products 全形态');
  const b = mk('{ "compileSdkVersion": 24, "compatibleSdkVersion": 24 }');
  assert.equal(detectSourceSdkVersion(b).key, '24', '顶层数字（OpenHarmony 形态）');
  const c = mk('{ "app": { "products": [{ "compileSdkVersion": "26.0.0", "runtimeOS": "OpenHarmony" }] } }');
  assert.equal(detectSourceSdkVersion(c).key, '26.0.0', 'OpenHarmony 裸版本');
  const d = mk('{ "app": { "products": [{ "compatibleSdkVersion": "9.9.9(99)" }] } }');
  assert.equal(detectSourceSdkVersion(d), null, '未收录 → null');
  const e = mkdtempSync(join(tmpdir(), 'f1-sdkver-none-'));
  assert.equal(detectSourceSdkVersion(e), null, '缺 build-profile → null');
  for (const x of [a, b, c, d, e]) rmSync(x, { recursive: true, force: true });
});

// ── runtimeOS 与源工程同步：形态分流写法 + 源形态探测 ──
test('compileSdkWriteOf：OpenHarmony 缺省数字 / HarmonyOS 全形态串 / 26.0.0 两形态一致', () => {
  const e17 = resolveVersionEntry('17');
  assert.equal(compileSdkWriteOf(e17), 17, '缺省=OpenHarmony 形态（数字 apiLevel）');
  assert.equal(compileSdkWriteOf(e17, 'HarmonyOS'), '5.0.5(17)', 'HarmonyOS 形态=全形态串（ON 表）');
  const e26 = resolveVersionEntry('26.0.0');
  assert.equal(compileSdkWriteOf(e26, 'HarmonyOS'), '26.0.0', '26.0.0 两形态写法一致');
});

test('detectSourceRuntimeOS：显式 HarmonyOS 识别（顶层/products）；缺失或 OpenHarmony → null（缺省语义）', () => {
  const mk = (bp) => { const d = mkdtempSync(join(tmpdir(), 'f1-rtos-')); writeFileSync(join(d, 'build-profile.json5'), JSON.stringify(bp)); return d; };
  assert.equal(detectSourceRuntimeOS(mk({ app: { products: [{ name: 'default', runtimeOS: 'HarmonyOS' }] } })), 'HarmonyOS', 'products 内 HarmonyOS');
  assert.equal(detectSourceRuntimeOS(mk({ runtimeOS: 'HarmonyOS' })), 'HarmonyOS', '顶层 HarmonyOS');
  assert.equal(detectSourceRuntimeOS(mk({ runtimeOS: 'OpenHarmony' })), null, '显式 OpenHarmony → null（缺省语义）');
  assert.equal(detectSourceRuntimeOS(mk({ app: { products: [{ name: 'default' }] } })), null, '无 runtimeOS 字段 → null（历史 OpenHarmony 工程兼容）');
});
