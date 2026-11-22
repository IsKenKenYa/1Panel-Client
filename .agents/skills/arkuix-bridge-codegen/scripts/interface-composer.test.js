import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { composeContract, methodIndexOf, countTopLevelArgs, deriveFromSdkDeclarations } from './interface-composer.js';

const ITEM = { name: 'DeviceInfoUdid', module: '@ohos.deviceInfo', symbol: 'udid', category: 'equivalent_bridge' };

test('composeContract：契约合成（interfaceName+方法签名，①真相源）', () => {
  const local = { status: 'migrated', content: 'const udid = deviceInfo.udid;' };
  const c = composeContract(ITEM, local);
  assert.equal(c.interfaceName, 'DeviceInfoUdidInterface');
  assert.equal(c.methods.length, 1);
  assert.equal(c.methods[0].name, 'udid');
});

test('composeContract：多实参调用→参数个数派生', () => {
  const local = { status: 'migrated', content: 'geo.getCurrentLocation("high", cb)' };
  const item = { ...ITEM, symbol: 'geolocation.getCurrentLocation' };
  const c = composeContract(item, local);
  assert.equal(c.methods[0].params.length, 2);
});

test('composeContract：Local 缺席→单参默认契约（local_status 承载失败语义）', () => {
  const c = composeContract(ITEM, { status: 'failed', reason: 'x' });
  assert.equal(c.methods[0].params.length, 0, '空调用面兜底=0 参（不 pad p0）');
});

test('countTopLevelArgs：顶层逗号计数（嵌套括号/回调不计）', () => {
  assert.equal(countTopLevelArgs('geo.getCurrentLocation("high", (err, loc) => { log(err, loc); })', 'getCurrentLocation'), 2);
  assert.equal(countTopLevelArgs('deviceInfo.udid', 'udid'), 0);
});

test('methodIndexOf：symbol 末段驼峰化', () => {
  assert.equal(methodIndexOf('geolocation.getCurrentLocation'), 'getCurrentLocation');
  assert.equal(methodIndexOf('udid'), 'udid');
});

// ── 契约方法面收敛 ───────────────────────────────────────────────────────────

test('Local 内容全部方法调用面入契约（不再只取首个）', () => {
  const local = { status: 'migrated', content: [
    "import sensor from '@ohos.sensor';",
    'sensor.on(sensor.SensorId.HALL, (data: sensor.HallResponse) => {',
    '  return;',
    '});',
    'sensor.off(sensor.SensorId.HALL);',
  ].join('\n') };
  const item = { ...ITEM, name: 'SensorSensor', module: '@ohos.sensor', symbol: 'sensor' };
  const c = composeContract(item, local);
  const names = c.methods.map((m) => m.name).sort();
  assert.deepEqual(names, ['off', 'on'], 'on/off 两个方法均入契约');
  assert.equal(c.derived, 'local');
});

test('参数类型按实参字面量推导（number/string/boolean/ESObject）', () => {
  const local = { status: 'migrated', content: 'vibrator.vibrate(300, "short", true, (err) => {});' };
  const item = { ...ITEM, name: 'VibVib', module: '@ohos.vibrator', symbol: 'vibrator' };
  const c = composeContract(item, local);
  const types = c.methods.find((m) => m.name === 'vibrate').params.map((p) => p.type);
  assert.deepEqual(types, ['number', 'string', 'boolean', 'ESObject'], '字面量类型推导（回调→ESObject 待人工）');
});

test('Local 成功也合并 locations 调用面（覆盖窗口外的调用点）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f3-icp-'));
  mkdirSync(join(root, 'pages'), { recursive: true });
  writeFileSync(join(root, 'pages', 'Cam.ets'), [
    'export function use() {',
    '  camera.getCameraManager();',
    '  camera.createCameraInput();',
    '}',
  ].join('\n'));
  const local = { status: 'migrated', content: 'camera.getCameraManager();' };
  const item = { ...ITEM, name: 'CamCam', module: '@ohos.multimedia.camera', symbol: 'camera',
    locations: ['pages/Cam.ets:2'] };
  const c = composeContract(item, local, root);
  const names = c.methods.map((m) => m.name).sort();
  assert.deepEqual(names, ['createCameraInput', 'getCameraManager'], 'Local+locations 双源合并');
  rmSync(root, { recursive: true, force: true });
});

test('别名前缀末段回退（geo.getCurrentLocation 形态）', () => {
  const local = { status: 'migrated', content: 'geo.getCurrentLocation("high", cb)' };
  const item = { ...ITEM, symbol: 'geolocation.getCurrentLocation' };
  const c = composeContract(item, local);
  assert.equal(c.methods.length, 1);
  assert.equal(c.methods[0].name, 'getCurrentLocation');
  assert.equal(c.methods[0].params.length, 2);
  assert.equal(c.methods[0].params[0].type, 'string', '字面量 "high" → string');
});

// ── ：SDK d.ts 声明面（契约源 0）──────────────────────────────────────
test('d.ts 声明面——namespace 函数 + 入口对象接口方法全方法集（真实参数名/类型）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f3-t9sdk-'));
  const api = join(root, 'ets', 'api');
  mkdirSync(api, { recursive: true });
  writeFileSync(join(api, '@ohos.multimedia.camera.d.ts'), [
    '/**',
    ' * @module',
    ' */',
    'import type Context from "./application/BaseContext";',
    'declare namespace camera {',
    '    /** doc comment */',
    '    function getCameraManager(context: Context): CameraManager;',
    '    interface CameraManager {',
    '        getSupportedCameras(): Array<CameraDevice>;',
    '        createCameraInput(camera: CameraDevice): CameraInput;',
    '        createSession(): CameraSession;',
    '        on(type: string, callback: Callback<CameraStatusInfo>): void;',
    '    }',
    '    interface CameraDevice {',
    '        readonly cameraId: string;',
    '    }',
    '}',
  ].join('\n'));
  const decls = deriveFromSdkDeclarations(root, '@ohos.multimedia.camera', 'camera');
  const names = decls.map((d) => d.name).sort();
  assert.deepEqual(names, ['createCameraInput', 'createSession', 'getCameraManager', 'getSupportedCameras', 'on'],
    'ns 函数 + CameraManager 接口方法（入口对象模式）');
  const gm = decls.find((d) => d.name === 'getCameraManager');
  assert.equal(gm.paramCount, 1);
  assert.deepEqual(gm.paramNames, ['context'], '真实参数名保留');
  assert.equal(gm.argTypes[0], 'ESObject', 'Context→ESObject（非可映射集）');
  const on = decls.find((d) => d.name === 'on');
  assert.deepEqual(on.paramNames, ['type', 'callback']);
  assert.equal(on.argTypes[0], 'string', 'string 原样');
  rmSync(root, { recursive: true, force: true });
});

test('composeContract 优先级——d.ts 声明面胜出（同方法名真实签名覆盖调用面推导）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f3-t9c-'));
  const api = join(root, 'ets', 'api');
  mkdirSync(api, { recursive: true });
  writeFileSync(join(api, '@ohos.mock.d.ts'), [
    'declare namespace mock {',
    '    function f(a: string, b: number, c: boolean): void;',
    '}',
  ].join('\n'));
  const local = { status: 'migrated', content: 'mock.f("x")' };
  const item = { ...ITEM, name: 'MockMock', module: '@ohos.mock', symbol: 'mock' };
  const c = composeContract(item, local, null, root);
  assert.equal(c.derived, 'sdk-decls');
  const f = c.methods.find((m) => m.name === 'f');
  assert.equal(f.params.length, 3, 'd.ts 真实 3 参胜出（调用面只有 1 参）');
  assert.deepEqual(f.params.map((p) => p.name), ['a', 'b', 'c'], '真实参数名');
  assert.deepEqual(f.params.map((p) => p.type), ['string', 'number', 'boolean'], '真实类型映射');
  rmSync(root, { recursive: true, force: true });
});

test('d.ts 缺失/模块不匹配 → 静默跳过（回退调用面源）', () => {
  const local = { status: 'migrated', content: 'geo.getCurrentLocation("high", cb)' };
  const item = { ...ITEM, symbol: 'geolocation.getCurrentLocation' };
  const c = composeContract(item, local, null, '/nonexistent/sdk');
  assert.equal(c.derived, 'local');
  assert.equal(c.methods[0].params.length, 2);
});

// ── arity 不虚高：0 参方法签名为 0 参（不 pad p0）──
test('composeContract：无参调用面 → 0 参签名（不 pad p0）', () => {
  const item = { name: 'TestNoArgs', module: '@ohos.test', symbol: 'test.getStatus', category: 'equivalent_bridge' };
  const contract = composeContract(item, { status: 'migrated', content: 'test.getStatus();' }, null, null);
  const m = contract.methods.find((x) => x.name === 'getStatus');
  assert.ok(m, '方法在场');
  assert.equal(m.params.length, 0, '0 参方法签名不 pad p0');
});
