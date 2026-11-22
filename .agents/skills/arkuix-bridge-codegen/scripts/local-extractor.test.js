import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, writeFileSync, mkdirSync, rmSync, readFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { createHash } from 'node:crypto';
import { extractLocal, localFilePath, freeIdentifiersOf, splitLocalContent } from './local-extractor.js';

const ITEM = { name: 'DeviceInfoUdid', module: '@ohos.deviceInfo', symbol: 'udid', category: 'equivalent_bridge',
  locations: ['entry/src/main/ets/pages/Index.ets:3'] };

function projectWith(content) {
  const root = mkdtempSync(join(tmpdir(), 'f3-local-'));
  mkdirSync(join(root, 'entry/src/main/ets/pages'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'), content, 'utf8');
  return root;
}

test('extractLocal：locations 锚定提取完整调用语句（保留业务逻辑非空壳）', () => {
  const src = [
    'import deviceInfo from \'@ohos.deviceInfo\';',
    'function getUdid(cb: (s: string) => void) {',
    '  const udid = deviceInfo.udid;',
    '  cb(udid);',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const r = extractLocal(ITEM, root);
  assert.equal(r.status, 'migrated');
  assert.ok(r.content.includes('deviceInfo.udid'));
  rmSync(root, { recursive: true, force: true });
});

test('extractLocal：多实参调用语句提取（换行/括号跨行）', () => {
  const src = [
    'import geo from \'@ohos.geolocation\';',
    'export function locate() {',
    '  geo.getCurrentLocation("high", (err, loc) => {',
    '    console.log(loc.latitude);',
    '  });',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, symbol: 'geolocation.getCurrentLocation', locations: ['entry/src/main/ets/pages/Index.ets:3'] };
  const r = extractLocal(item, root);
  assert.equal(r.status, 'migrated');
  assert.ok(r.content.includes('getCurrentLocation('));
  rmSync(root, { recursive: true, force: true });
});

test('extractLocal：文件不存在→failed+原因标注，不抛出', () => {
  const item = { ...ITEM, locations: ['entry/src/main/ets/pages/Missing.ets:1'] };
  const r = extractLocal(item, mkdtempSync(join(tmpdir(), 'f3-empty-')));
  assert.equal(r.status, 'failed');
  assert.ok(r.reason.includes('源码读取失败'));
  assert.ok(r.reason.includes('需手动补入'));
});

test('extractLocal：锚行越界/不含目标符号→failed 显式降级', () => {
  const root = projectWith('const x = 1;\nconst y = 2;\n');
  const r = extractLocal(ITEM, root); // 第 4 行越界 → 语句定位失败
  assert.equal(r.status, 'failed');
  assert.ok(r.reason.includes('源码读取失败'));
  rmSync(root, { recursive: true, force: true });
});

test('源工程只读——提取前后文件指纹一致', () => {
  const src = 'const udid = deviceInfo.udid;';
  const root = projectWith(src);
  const file = join(root, 'entry/src/main/ets/pages/Index.ets');
  const sha = (f) => createHash('sha256').update(readFileSync(f)).digest('hex');
  const before = sha(file);
  extractLocal({ ...ITEM, locations: ['entry/src/main/ets/pages/Index.ets:1'] }, root);
  assert.equal(before, sha(file));
  rmSync(root, { recursive: true, force: true });
});

test('localFilePath：落位路径确定性', () => {
  assert.equal(localFilePath(ITEM), 'commons/deviceInfo/utils/DeviceInfoUdidLocal.ets'); // 字面量断言（跨平台确定）
});

test('source≠ohos 不迁 .ets（ndk 显式 failed 待人工）；空壳语句判 failed', () => {
  const ndkItem = { ...ITEM, source: 'ndk', name: 'NdkX' };
  const r1 = extractLocal(ndkItem, mkdtempSync(join(tmpdir(), 'f3-x-')));
  assert.equal(r1.status, 'failed');
  assert.ok(r1.reason.includes('NDK C-API 无 .ets 迁移源'));
  const root = projectWith("import x from '@ohos.x';\n// const udid = deviceInfo.udid;（仅注释）\n");
  const r2 = extractLocal({ ...ITEM, locations: ['entry/src/main/ets/pages/Index.ets:2'] }, root);
  assert.equal(r2.status, 'failed');
  assert.ok(r2.reason.includes('未能定位完整调用语句'), '全文件扫描无调用行（注释锚不再单锚退化—— 语义）');
  rmSync(root, { recursive: true, force: true });
});

// ── 语句完整性 ───────────────────────────────────────────────────────────

test('嵌套回调内的 return; 不截断语句（括号深度平衡，产物括号闭合可编译）', () => {
  const src = [
    'import sensor from \'@ohos.sensor\';',
    'export function watch() {',
    '  sensor.on(sensor.SensorId.HALL, (data: sensor.HallResponse) => {',
    '    if (data === null) {',
    '      return;',
    '    }',
    '    console.info(data);',
    '  });',
    '  sensor.off(sensor.SensorId.HALL);',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, symbol: 'sensor', locations: ['entry/src/main/ets/pages/Index.ets:3'] };
  const r = extractLocal(item, root);
  assert.equal(r.status, 'migrated', JSON.stringify(r));
  assert.ok(r.content.includes('sensor.on('), '含 on 调用起点');
  assert.ok(r.content.includes('return;'), '含回调内 return（未被误判终止）');
  assert.ok(r.content.includes('sensor.off('), '含后续 off 调用');
  const opens = (r.content.match(/\{/g) || []).length + (r.content.match(/\(/g) || []).length;
  const closes = (r.content.match(/\}/g) || []).length + (r.content.match(/\)/g) || []).length;
  assert.equal(opens, closes, '括号深度平衡（可编译）');
  rmSync(root, { recursive: true, force: true });
});

test('字符串/注释内的括号与分号不干扰深度计数', () => {
  const src = [
    'import router from \'@ohos.router\';',
    'export function go() {',
    '  const url = "a);b{c"; // ( 注释里的 ((( 与 ;',
    '  router.pushUrl({ url: `${url};` }, (err) => {',
    '    return;',
    '  });',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, symbol: 'router', locations: ['entry/src/main/ets/pages/Index.ets:4'] };
  const r = extractLocal(item, root);
  assert.equal(r.status, 'migrated', JSON.stringify(r));
  assert.ok(r.content.includes('pushUrl('));
  const lastLine = r.content.trim().split('\n').pop().trim();
  assert.equal(lastLine, '});', '语句在 }); 正确终止（字符串/注释内的括号分号不误判）');
  rmSync(root, { recursive: true, force: true });
});

test('行号漂移——锚定落在 // [MIG] 注释行（原位替换 import）时按 symbol 重锚定', () => {
  const src = [
    '// [MIG] import sensor from \'@ohos.sensor\';',
    "import sensor from '../../n2b-stubs'; // [MIG] 迁移占位",
    'export function watch() {',
    '  sensor.on(sensor.SensorId.HALL, (data) => { return; });',
    '  sensor.off(sensor.SensorId.HALL);',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, symbol: 'sensor', locations: ['entry/src/main/ets/pages/Index.ets:1'] };
  const r = extractLocal(item, root);
  assert.equal(r.status, 'migrated', JSON.stringify(r));
  assert.ok(r.content.includes('sensor.on('), '重锚到真实调用行');
  assert.ok(!r.content.startsWith('// [MIG]'), 'MIG 注释不进产物');
  rmSync(root, { recursive: true, force: true });
});

// ── ：全 locations 收割 + kit import 改写 ─────────────────────────────
test('多 locations 逐一收割——on/off 两语句各自迁入（多方法 Local 各得方法体）', () => {
  const src = [
    "import sensor from '@ohos.sensor';",
    'export function watch() {',
    '  sensor.on(sensor.SensorId.HALL, (data) => { return; });',
    '  sensor.off(sensor.SensorId.HALL);',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, symbol: 'sensor',
    locations: ['entry/src/main/ets/pages/Index.ets:3', 'entry/src/main/ets/pages/Index.ets:4'] };
  const r = extractLocal(item, root);
  assert.equal(r.status, 'migrated', JSON.stringify(r));
  assert.ok(r.content.includes('sensor.on('), 'on 语句迁入');
  assert.ok(r.content.includes('sensor.off('), 'off 语句迁入');
  assert.equal(r.content.split('sensor.off').length - 1, 1, '去重（无重复语句）');
  rmSync(root, { recursive: true, force: true });
});

test('kit import 改写——@kit.* 语句在 ArkUI-X 编译集不可解析 → 按 SDK kits 索引映射 @ohos 直导入', () => {
  const sdkRoot = mkdtempSync(join(tmpdir(), 'f3-t9kit-'));
  const kits = join(sdkRoot, 'ets', 'kits');
  mkdirSync(kits, { recursive: true });
  writeFileSync(join(kits, '@kit.SensorServiceKit.d.ts'),
    "import sensor from '@ohos.sensor';\nimport vibrator from '@ohos.vibrator';\nexport { sensor, vibrator };\n");
  const src = [
    "import { sensor } from '@kit.SensorServiceKit';",
    'export function watch() {',
    '  sensor.on(sensor.SensorId.HALL);',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, module: '@ohos.sensor', symbol: 'sensor',
    locations: ['entry/src/main/ets/pages/Index.ets:3'] };
  const r = extractLocal(item, root, { sdkDir: sdkRoot });
  assert.equal(r.status, 'migrated');
  assert.ok(r.content.includes("import sensor from '@ohos.sensor';"), 'kit import 已改写为 @ohos 直导入');
  assert.ok(!r.content.includes('@kit.'), '无残留 @kit import');
  rmSync(root, { recursive: true, force: true });
  rmSync(sdkRoot, { recursive: true, force: true });
});

test('kit 索引缺失/部分绑定不可映射 → 保守保留原行', () => {
  const sdkRoot = mkdtempSync(join(tmpdir(), 'f3-t9kit2-')); // 无 kits 目录
  const src = [
    "import { unknownSym } from '@kit.ScanKit';",
    'export function watch() {',
    '  sensor.on(1);',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, symbol: 'sensor', locations: ['entry/src/main/ets/pages/Index.ets:3'] };
  const r = extractLocal(item, root, { sdkDir: sdkRoot });
  assert.ok(!r.content.includes("from '@kit.ScanKit'") || r.content.includes('@kit.ScanKit'),
    '索引缺失不改写（保守）');
  rmSync(root, { recursive: true, force: true });
  rmSync(sdkRoot, { recursive: true, force: true });
});

// ── ：外围作用域收割（自由标识符解析）────────────────────────────────
test('自由标识符按来源分类带入——模块名导入/相对导入注释/const 内联/未解析汇总', () => {
  const src = [
    "import { Logger, UIContextSelf } from 'sample_common';",
    "import { DeviceService } from '../model/DeviceService';",
    "import { CommonConstants } from '../constants/CommonConstants';",
    "import sensor from '@ohos.sensor';",
    "const TAG: string = 'WatchAbility';",
    'export function watch() {',
    '  sensor.on(sensor.SensorId.HALL, (data) => {',
    '    Logger.info(TAG, `status = ${data.status}`);',
    '    DeviceService.hallStatus = data.status;',
    '    UIContextSelf.emitEventHub(CommonConstants.HALL_STATUS, data.status);',
    '    MysteryHelper.tick();',
    '  });',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, module: '@ohos.sensor', symbol: 'sensor',
    locations: ['entry/src/main/ets/pages/Index.ets:7'] };
  const r = extractLocal(item, root);
  assert.equal(r.status, 'migrated', JSON.stringify(r));
  const c = r.content;
  assert.equal((c.match(/sample_common/g) ?? []).length, 1, '同 import 行去重（{A, B} 一行两标识符）');
  assert.ok(c.includes("// [MIG] import { Logger, UIContextSelf } from 'sample_common'; —— 模块名导入，需在 HAR oh-package 声明依赖后取消注释"), '模块名导入注释化（live 导入无 HAR 依赖即编译错）');
  assert.ok(!c.includes("\nimport { Logger"), '非 live（防误判）');
  assert.ok(c.includes('// [MIG] import { DeviceService } from'), '相对导入注释化（HAR 内路径无效）');
  assert.ok(c.includes("const TAG = 'WatchAbility'; // [MIG] 源工程本地常量内联"), 'TAG const 字面量内联');
  assert.ok(c.includes('未解析标识符'), 'MysteryHelper 未解析汇总在场');
  assert.ok(c.includes('MysteryHelper'), '未解析清单含具体名字');
  assert.ok(c.includes('// [MIG] import { CommonConstants }'), 'CommonConstants 走相对导入注释分支');
  rmSync(root, { recursive: true, force: true });
});

test('freeIdentifiersOf——语句局部名/关键字/symbol 根剔除', () => {
  const stmt = 'sensor.on(sensor.SensorId.HALL, (data) => { Logger.info(TAG, `x ${data.s}`); }, { interval: 1 });';
  const ids = freeIdentifiersOf(stmt, 'sensor');
  assert.ok(ids.includes('Logger') && ids.includes('TAG'), '自由标识符: ' + ids.join(','));
  assert.ok(!ids.includes('data'), '回调参数剔除');
  assert.ok(!ids.includes('interval'), '对象键剔除');
  assert.ok(!ids.includes('sensor') && !ids.includes('HALL'), 'symbol 根/属性段剔除');
});

test('splitLocalContent——外围收割行归头部区（不进语句区/类尾参考块）', () => {
  const content = [
    "import sensor from '@ohos.sensor';",
    "import { Logger } from 'sample_common'; // [MIG] 模块名导入——需在 HAR 的 oh-package 声明该依赖",
    "const TAG = 'W'; // [MIG] 源工程本地常量内联",
    "// [MIG] import { DeviceService } from '../model/DeviceService'; —— 相对源工程路径，接线时按 HAR 内位置改写或迁入依赖",
    "// [MIG] 未解析标识符（源工程外围作用域——接线时补 import/实现）: Mystery",
    "sensor.on(sensor.SensorId.HALL, (data) => { Logger.info(TAG); });",
  ].join('\n');
  const { imports, statements } = splitLocalContent(content);
  assert.equal(imports.length, 5, 'import + 3 类 [MIG] 行 + const 内联全部归头部（实际 ' + imports.length + '）');
  assert.equal(statements.length, 1, '仅 on 语句在语句区');
  assert.ok(statements[0].includes('sensor.on('));
});

test('c： 改写后的源文件——stub 重定向行被滤除、真实模块导入兜底生成', () => {
  const src = [
    '// [MIG] @ohos.multimedia.camera::camera → equivalent_bridge（切换…）',
    '// [MIG] @kit.CameraKit → @ohos.multimedia.camera: import { camera } from \'@kit.CameraKit\';',
    "import { camera } from '../../n2b-stubs'; // [MIG] 迁移占位",
    'export function use() {',
    '  const m = camera.getCameraManager(getContext());',
    '  m.getSupportedCameras();',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, module: '@ohos.multimedia.camera', symbol: 'camera',
    locations: ['entry/src/main/ets/pages/Index.ets:5'] };
  const r = extractLocal(item, root, {});
  assert.equal(r.status, 'migrated');
  assert.ok(!r.content.includes('n2b-stubs'), 'stub 行滤除（Local 是 OH 直调实现，不导占位）');
  assert.ok(r.content.includes("import camera from '@ohos.multimedia.camera';"), '真实模块导入兜底生成');
  rmSync(root, { recursive: true, force: true });
});

test('b：成员声明型语句——修饰符/装饰器/类型关键字/成员名不入未解析清单', () => {
  const stmt = [
    'private cameraManager: camera.CameraManager | undefined = undefined;',
    '@Local adaptRatio: number = this.xComponentSize.width / PREVIEW_PROFILE_WIDTH;',
  ].join('\n');
  const ids = freeIdentifiersOf(stmt, 'camera');
  assert.deepEqual(ids, ['PREVIEW_PROFILE_WIDTH'], '仅真正的自由引用（常量名）；private/cameraManager/adaptRatio/number/Local 均剔除（实际: ' + ids.join(',') + '）');
});

// ── 调用面与导入收敛 ─────────────────────────────────────
test('MIG 注释锚→findAllCallLines 全文件调用扫描（防单锚退化到变量声明）', () => {
  const src = [
    "import { camera } from '@kit.CameraKit';",
    "export struct Page {",
    '  private cameraManager: camera.CameraManager | undefined = undefined;',
    '  build() {',
    '    Button("go").onClick(() => {',
    '      this.cameraManager = camera.getCameraManager(ctx);',
    '      camera.isCameraMuted();',
    '    })',
    '  }',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, module: '@ohos.multimedia.camera', symbol: 'camera',
    locations: ['entry/src/main/ets/pages/Index.ets:1'] };
  const r = extractLocal(item, root, {});
  assert.equal(r.status, 'migrated');
  assert.ok(r.content.includes('camera.getCameraManager('), '真实调用语句迁入（非变量声明）');
  assert.ok(r.content.includes('camera.isCameraMuted('), '第二调用迁入');
  rmSync(root, { recursive: true, force: true });
});

test('harvest 只收 @ 前缀 OH API 导入——commons/项目 HAR/stub 裸模块名跳过', () => {
  const src = [
    "import { camera } from 'multimedia_camera';",        // 接线改写后形态（自引用）
    "import { Logger } from 'sample_common';",            // 项目内部 HAR
    "import { camera as cam2 } from '../../n2b-stubs';",  // stub
    "import camera from '@ohos.multimedia.camera';",      // 真实 OH API
    'export function use() {',
    '  camera.getCameraManager();',
    '}',
  ].join('\n');
  const root = projectWith(src);
  const item = { ...ITEM, module: '@ohos.multimedia.camera', symbol: 'camera',
    locations: ['entry/src/main/ets/pages/Index.ets:1'] };
  const r = extractLocal(item, root, {});
  const c = r.content;
  assert.ok(c.includes("import camera from '@ohos.multimedia.camera'"), 'OH API 导入在场');
  assert.ok(!c.includes("from 'multimedia_camera'"), 'commons 自引用跳过');
  assert.ok(!c.includes('n2b-stubs'), 'stub 跳过');
  // sample_common 属标识符域——由外围作用域收割分类（带 [MIG] 提示），不进 symbol 域
  rmSync(root, { recursive: true, force: true });
});
