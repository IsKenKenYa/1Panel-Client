import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, readFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { writePieces, writeArtifactJson, renderReport, atomicWrite } from './writer.js';

const PIECE = (name, status = 'migrated') => ({
  item: { name, module: '@ohos.deviceInfo', symbol: 'udid', category: 'equivalent_bridge' },
  paths: { interface: `commons/deviceInfo/interface/${name}Interface.ets`, local: `commons/deviceInfo/utils/${name}Local.ets`,
    arkui_x: `commons/deviceInfo/utils/${name}ArkUIX.ets`, android: `.arkui-x/android/app/src/main/java/com/arkuix/bridge/Bridge${name}.java`,
    ios: `.arkui-x/ios/app/BridgeSrc/Bridge${name}.h` },
  texts: {
    [`commons/deviceInfo/interface/${name}Interface.ets`]: `// ${name} interface`,
    [`commons/deviceInfo/utils/${name}Local.ets`]: `// ${name} local`,
    [`commons/deviceInfo/utils/${name}ArkUIX.ets`]: `// ${name} arkux`,
    [`.arkui-x/android/app/src/main/java/com/arkuix/bridge/Bridge${name}.java`]: `// Bridge${name}`,
    [`.arkui-x/ios/app/BridgeSrc/Bridge${name}.h`]: `// Bridge${name}.h`,
    [`.arkui-x/ios/app/BridgeSrc/Bridge${name}.m`]: `// Bridge${name}.m`,
  },
  localStatus: status,
  ...(status === 'failed' ? { localReason: '源码读取失败：测试，需手动补入' } : {}),
  unmapped: false,
});

test('writePieces：五件落盘+ 组装', () => {
  const out = mkdtempSync(join(tmpdir(), 'f3-writer-'));
  const { artifact } = writePieces(out, [PIECE('DeviceInfoUdid')]);
  assert.ok(existsSync(join(out, 'commons/deviceInfo/interface/DeviceInfoUdidInterface.ets')));
  assert.ok(existsSync(join(out, '.arkui-x/ios/app/BridgeSrc/BridgeDeviceInfoUdid.m')));
  assert.equal(artifact.schema_version, 1);
  assert.equal(artifact.artifacts.length, 1);
  assert.equal(artifact.artifacts[0].local_status, 'migrated');
  assert.deepEqual(artifact.unmapped_native_apis, []);
  rmSync(out, { recursive: true, force: true });
});

test('writePieces：local failed→local_status=failed+reason 落账', () => {
  const out = mkdtempSync(join(tmpdir(), 'f3-writer-'));
  const { artifact, localFailures } = writePieces(out, [PIECE('BadOne', 'failed')]);
  assert.equal(artifact.artifacts[0].local_status, 'failed');
  assert.ok(artifact.artifacts[0].reason.includes('源码读取失败'));
  assert.equal(localFailures.length, 1);
  rmSync(out, { recursive: true, force: true });
});

test('writeArtifactJson+atomicWrite：原子写盘（tmp+rename，不残留 .tmp）', () => {
  const out = mkdtempSync(join(tmpdir(), 'f3-writer-'));
  const f = writeArtifactJson(out, { schema_version: 1, artifacts: [], unmapped_native_apis: [] });
  assert.equal(JSON.parse(readFileSync(f, 'utf8')).schema_version, 1);
  assert.ok(!existsSync(f + '.tmp-1'));
  rmSync(out, { recursive: true, force: true });
});

test('renderReport：占位替换完整（无残留 {{}}）', () => {
  const tpl = '# 报告\n总数 {{total}}\n清单\n{{artifactTable}}';
  const md = renderReport(tpl, { total: 0, artifactTable: '（无）' });
  assert.ok(!md.includes('{{'));
});

test('N4：BridgeRegistry.java 生成（集中注册，Android 接线一步化）', () => {
  const out = mkdtempSync(join(tmpdir(), 'f3-reg-'));
  const { artifact } = writePieces(out, [PIECE('DeviceInfoUdid'), PIECE('VibratorStart')]);
  const reg = readFileSync(join(out, '.arkui-x/android/app/src/main/java/com/arkuix/bridge/BridgeRegistry.java'), 'utf8');
  assert.ok(reg.includes('registerBridgePlugin("DeviceInfoUdid", new BridgeDeviceInfoUdid('));
  assert.ok(reg.includes('registerBridgePlugin("VibratorStart", new BridgeVibratorStart('));
  assert.ok(reg.includes('public static void registerAll(Context context, BridgeManager bridgeManager)'));
  rmSync(out, { recursive: true, force: true });
});

// ── 产物契约增补 ───────────────────────────────────────────────────────────

test('BridgeArtifact 条目含 symbol 字段（F4/人工定位接口符号）', () => {
  const out = mkdtempSync(join(tmpdir(), 'f3-w-'));
  const pieces = [{
    item: { name: 'SensorSensor', symbol: 'sensor', module: '@ohos.sensor', category: 'equivalent_bridge' },
    paths: { interface: 'commons/sensor/interface/SensorSensorInterface.ets', local: 'commons/sensor/utils/SensorSensorLocal.ets',
      arkui_x: 'commons/sensor/utils/SensorSensorArkUIX.ets', android: '.arkui-x/android/a/BridgeSensorSensor.java', ios: '.arkui-x/ios/a/BridgeSensorSensor.h' },
    texts: {},
    localStatus: 'migrated',
  }];
  const { artifact } = writePieces(out, pieces);
  assert.equal(artifact.artifacts[0].symbol, 'sensor');
  assert.ok(artifact.artifacts[0].files && artifact.artifacts[0].files.interface, 'files 五件路径齐备');
  rmSync(out, { recursive: true, force: true });
});

test('min_android/min_ios 透传 BridgeArtifact（F4 适用版本澄清消费）；缺席不输出字段', () => {
  const out = mkdtempSync(join(tmpdir(), 'f3-w-minapi-'));
  const withVer = { ...PIECE('DeviceInfoUdid'), nativeApi: { android: 'A', ios: 'I', min_android: 'API 21+', min_ios: 'iOS 9.0+' } };
  const withoutVer = PIECE('VibratorStart');
  const { artifact } = writePieces(out, [withVer, withoutVer]);
  assert.equal(artifact.artifacts[0].min_android, 'API 21+');
  assert.equal(artifact.artifacts[0].min_ios, 'iOS 9.0+');
  assert.equal(artifact.artifacts[1].min_android, undefined, '未标注条目不输出字段');
  assert.equal(artifact.artifacts[1].min_ios, undefined);
  rmSync(out, { recursive: true, force: true });
});
