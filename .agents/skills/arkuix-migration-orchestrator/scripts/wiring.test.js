import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { fileURLToPath } from 'node:url';
import { wireBridgeToProject } from './orchestrate.js';

const root = join(dirname(fileURLToPath(import.meta.url)), '..');
function dirname(p) { return p.split('/').slice(0, -1).join('/'); }

/** 构造 F3 六件套 bridge 输出目录（含工程级 PlatformInfo + 模块 interface/impl/utils） */
function mkBridgeOut(t) {
  const bridgeOut = mkdtempSync(join(tmpdir(), 'f4-wire-'));
  const mod = join(bridgeOut, 'commons', 'multimedia-camera');
  mkdirSync(join(mod, 'interface'), { recursive: true });
  mkdirSync(join(mod, 'impl'), { recursive: true });
  mkdirSync(join(mod, 'utils'), { recursive: true });
  writeFileSync(join(mod, 'interface', 'XInterface.ets'), 'export interface XInterface {}\n');
  writeFileSync(join(mod, 'utils', 'XArkUIX.ets'), 'export class XArkUIX {}\n');
  writeFileSync(join(mod, 'utils', 'XLocal.ets'), 'export class XLocal {}\n');
  writeFileSync(join(mod, 'impl', 'XImpl.ets'),
    "import { PlatformInfo, PlatformTypeEnum } from '../../utils/PlatformInfo';\nexport class XImpl {}\n");
  mkdirSync(join(bridgeOut, 'commons', 'utils'), { recursive: true });
  writeFileSync(join(bridgeOut, 'commons', 'utils', 'PlatformInfo.ets'),
    'export class PlatformInfo {}\n');
  // 工程级裸目录外的另一模块（验证互不影响）
  return bridgeOut;
}

test('wiring：⑥impl 拷贝 + 工程级 utils 裸目录跳过 + PlatformInfo 分发 + import 层级改写', () => {
  const bridgeOut = mkBridgeOut();
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-proj-'));
  const artifact = { artifacts: [{ module: '@ohos.multimedia.camera', name: 'X', symbol: 'x', category: 'equivalent_bridge' }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);

  const har = join(projectRoot, 'commons', 'multimedia_camera');
  assert.ok(existsSync(join(har, 'src', 'main', 'ets', 'impl', 'XImpl.ets')), '⑥impl 已拷贝');
  assert.ok(existsSync(join(har, 'src', 'main', 'ets', 'utils', 'PlatformInfo.ets')), 'PlatformInfo 已分发进 HAR');
  assert.ok(!existsSync(join(projectRoot, 'commons', 'utils')), '工程级裸 utils 目录不模块化');
  const implText = readFileSync(join(har, 'src', 'main', 'ets', 'impl', 'XImpl.ets'), 'utf8');
  assert.ok(implText.includes("'../utils/PlatformInfo'"), '⑥内 import 已改写为 HAR 层级');
  assert.ok(!implText.includes('../../utils/PlatformInfo'), '原平铺层级 import 无残留');
  assert.ok(existsSync(join(har, 'oh-package.json5')), 'HAR oh-package 落盘');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});

test('wiring：file: 依赖按模块真实嵌套层级计算（products/phone 二级 → ../../commons/）', () => {
  const bridgeOut = mkBridgeOut();
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-nested-'));
  // 嵌套布局：products/phone（scankit 形态）
  const phoneDir = join(projectRoot, 'products', 'phone');
  mkdirSync(phoneDir, { recursive: true });
  writeFileSync(join(phoneDir, 'oh-package.json5'), JSON.stringify({ name: 'phone', dependencies: {} }));
  mkdirSync(join(phoneDir, 'src', 'main', 'ets'), { recursive: true });
  writeFileSync(join(phoneDir, 'src', 'main', 'ets', 'Index.ets'),
    "import { camera } from 'n2b-stubs';\n// [MIG] import { camera } from '@ohos.multimedia.camera'\n");
  // build-profile（注册 commons 模块用）
  writeFileSync(join(projectRoot, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default" }] }, "modules": [{ "name": "phone", "srcPath": "./products/phone" }] }');
  const artifact = { artifacts: [{ module: '@ohos.multimedia.camera', name: 'X', symbol: 'camera', category: 'equivalent_bridge' }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);

  const pkg = JSON.parse(readFileSync(join(phoneDir, 'oh-package.json5'), 'utf8'));
  assert.equal(pkg.dependencies.multimedia_camera, 'file:../../commons/multimedia_camera',
    'file: 路径按真实嵌套层级（ohpm 可解析）');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});

test('wiring：平铺布局（entry 一级）→ file:../commons/ 不回归', () => {
  const bridgeOut = mkBridgeOut();
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-flat-'));
  const entryDir = join(projectRoot, 'entry');
  mkdirSync(join(entryDir, 'src', 'main', 'ets'), { recursive: true });
  writeFileSync(join(entryDir, 'oh-package.json5'), JSON.stringify({ name: 'entry', dependencies: {} }));
  writeFileSync(join(entryDir, 'src', 'main', 'ets', 'Index.ets'),
    "import { camera } from 'n2b-stubs';\n// [MIG] import { camera } from '@ohos.multimedia.camera'\n");
  writeFileSync(join(projectRoot, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default" }] }, "modules": [{ "name": "entry", "srcPath": "./entry" }] }');
  const artifact = { artifacts: [{ module: '@ohos.multimedia.camera', name: 'X', symbol: 'camera', category: 'equivalent_bridge' }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);

  const pkg = JSON.parse(readFileSync(join(entryDir, 'oh-package.json5'), 'utf8'));
  assert.equal(pkg.dependencies.multimedia_camera, 'file:../commons/multimedia_camera', '平铺布局一级相对路径');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});

test('Index.ets 恒生成（含⑥Impl 导出——未被 rewire 的 HAR 不空壳声明）', () => {
  const bridgeOut = mkBridgeOut();
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-idx-'));
  writeFileSync(join(projectRoot, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default" }] }, "modules": [] }');
  const artifact = { artifacts: [{ module: '@ohos.multimedia.camera', name: 'X', symbol: 'x', category: 'equivalent_bridge' }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);
  const idx = readFileSync(join(projectRoot, 'commons', 'multimedia_camera', 'Index.ets'), 'utf8');
  assert.ok(idx.includes("export { XImpl } from './src/main/ets/impl/XImpl'"), '⑥Impl 正式入口导出（模版定义形态）');
  const pkg = JSON.parse(readFileSync(join(projectRoot, 'commons', 'multimedia_camera', 'oh-package.json5'), 'utf8'));
  assert.equal(pkg.main, 'Index.ets', 'oh-package main 声明');
  assert.ok(existsSync(join(projectRoot, 'commons', 'multimedia_camera', 'Index.ets')), 'Index.ets 在场（未被 rewire 的 HAR 也生成）');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});

// ── @kit.* 模块：import/依赖名与落位目录同源一致性 ──
test('wiring：@kit.* HAR——依赖名与落位目录一致（files 路径为基准，杜绝 _kit_scankit 悬空）', () => {
  const bridgeOut = mkdtempSync(join(tmpdir(), 'f4-kit-'));
  const mod = join(bridgeOut, 'commons', 'kit-ScanKit');   // F3 实际目录形态（@→kit 段保留，.→-）
  mkdirSync(join(mod, 'interface'), { recursive: true });
  mkdirSync(join(mod, 'impl'), { recursive: true });
  writeFileSync(join(mod, 'interface', 'ScanInterface.ets'), 'export interface ScanInterface {}\n');
  writeFileSync(join(mod, 'impl', 'ScanImpl.ets'), 'export class ScanImpl {}\n');
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-kitproj-'));
  const entryDir = join(projectRoot, 'entry');
  mkdirSync(join(entryDir, 'src', 'main', 'ets'), { recursive: true });
  writeFileSync(join(entryDir, 'oh-package.json5'), JSON.stringify({ name: 'entry', dependencies: {} }));
  writeFileSync(join(entryDir, 'src', 'main', 'ets', 'Index.ets'),
    "import { scanBarcode } from 'n2b-stubs';\n// [MIG] import { scanBarcode } from '@kit.ScanKit'\n");
  writeFileSync(join(projectRoot, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default" }] }, "modules": [{ "name": "entry", "srcPath": "./entry" }] }');
  const artifact = { artifacts: [{ module: '@kit.ScanKit', name: 'ScanKitScanBarcode', symbol: 'scanBarcode', category: 'degraded_bridge',
    files: { interface: 'commons/kit-ScanKit/interface/ScanKitScanBarcodeInterface.ets' } }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);

  const pkg = JSON.parse(readFileSync(join(entryDir, 'oh-package.json5'), 'utf8'));
  const depName = Object.keys(pkg.dependencies ?? {}).find((k) => k.includes('scankit') || k.includes('kit'));
  assert.ok(depName === 'kit_scankit', `依赖名=落位目录名 kit_scankit（实际 ${depName}）`);
  assert.equal(pkg.dependencies[depName], 'file:../commons/kit_scankit', 'file: 路径指向真实落位目录');
  assert.ok(existsSync(join(projectRoot, 'commons', 'kit_scankit')), 'HAR 目录在场');
  const src = readFileSync(join(entryDir, 'src', 'main', 'ets', 'Index.ets'), 'utf8');
  assert.ok(src.includes("from 'kit_scankit'"), '业务 import 切至同名 HAR 模块');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});

// ── 空桥接产物不注入宿主（避免悬空 BridgeRegistry 引用）──
test('wiring：空 artifacts → 不注入 BridgeRegistry（空产物不落位不注入，R-23 边界）', () => {
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-empty-'));
  const activityDir = join(projectRoot, '.arkui-x', 'android', 'app', 'src', 'main', 'java', 'com', 'example', 'app');
  mkdirSync(activityDir, { recursive: true });
  const activity = join(activityDir, 'EntryAbilityActivity.java');
  writeFileSync(activity, 'import ohos.stage.ability.adapter.StageActivity;\npublic class EntryEntryAbilityActivity extends StageActivity {\n  protected void onCreate(android.os.Bundle savedInstanceState) { super.onCreate(savedInstanceState); }\n}\n');
  wireBridgeToProject(join(projectRoot, 'no-such-bridge-out'), projectRoot, 'modify', { artifacts: [] });
  const t = readFileSync(activity, 'utf8');
  assert.ok(!t.includes('BridgeRegistry'), '空 artifacts 零注入（无悬空引用）');
  rmSync(projectRoot, { recursive: true, force: true });
});

// ── 具名导入形态（@kit.*）：HAR Index 按符号导出接口实例（import { sym } 直取，方法经 Bridge 分发）──
test('wiring：@kit.* HAR——Index.ets 具名符号实例导出（symbol: Iface = Impl.getInterface()）', () => {
  const bridgeOut = mkdtempSync(join(tmpdir(), 'f4-named-'));
  const mod = join(bridgeOut, 'commons', 'kit-ScanKit');
  mkdirSync(join(mod, 'interface'), { recursive: true });
  mkdirSync(join(mod, 'impl'), { recursive: true });
  writeFileSync(join(mod, 'interface', 'ScanKitCustomScanInterface.ets'), 'export interface ScanKitCustomScanInterface {\n  startScanPageForResult(p0: string): Promise<unknown>;\n}\n');
  writeFileSync(join(mod, 'impl', 'ScanKitCustomScanImpl.ets'), 'export class ScanKitCustomScanImpl {\n  public static getInterface(): ScanKitCustomScanInterface { return null as ESObject; }\n}\n');
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-namedproj-'));
  writeFileSync(join(projectRoot, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default" }] }, "modules": [] }');
  const artifact = { artifacts: [{ module: '@kit.ScanKit', name: 'ScanKitCustomScan', symbol: 'customScan', category: 'degraded_bridge',
    files: { interface: 'commons/kit-ScanKit/interface/ScanKitCustomScanInterface.ets' } }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);
  const idx = readFileSync(join(projectRoot, 'commons', 'kit_scankit', 'Index.ets'), 'utf8');
  assert.ok(idx.includes("export const customScan: ScanKitCustomScanInterface = ScanKitCustomScanImpl.getInterface();"),
    '具名符号接口实例导出在场');
  const firstExport = idx.split('\n').findIndex((l) => l.startsWith('export'));
  const lastImport = idx.split('\n').findLastIndex((l) => l.startsWith('import'));
  assert.ok(lastImport < firstExport, 'import 全部置顶（严格 ArkTS 禁止语句后置 import）');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});

// ── @kit.* namespace 镜像：artifact symbol 作候选名匹配 n2b-stubs 命名空间 ──
test('wiring：@kit.* HAR——buildBridgeNamespace 以 artifact.symbol 匹配 n2b-stubs namespace（scanBarcode.ScanType 枚举面导出）', () => {
  const bridgeOut = mkdtempSync(join(tmpdir(), 'f4-ns-'));
  const mod = join(bridgeOut, 'commons', 'kit-ScanKit');
  mkdirSync(join(mod, 'interface'), { recursive: true });
  mkdirSync(join(mod, 'impl'), { recursive: true });
  writeFileSync(join(mod, 'interface', 'ScanKitScanBarcodeInterface.ets'), 'export interface ScanKitScanBarcodeInterface {\n  startScanForResult(): Promise<unknown>;\n}\n');
  writeFileSync(join(mod, 'impl', 'ScanKitScanBarcodeImpl.ets'), 'export class ScanKitScanBarcodeImpl {\n  public static getInterface(): ScanKitScanBarcodeInterface { return null as ESObject; }\n}\n');
  const projectRoot = mkdtempSync(join(tmpdir(), 'f4-nsproj-'));
  // n2b-stubs 含 scanBarcode 命名空间（含枚举 ScanType——业务码用 scanBarcode.ScanType.ALL）
  mkdirSync(join(projectRoot, 'entry/src/main/ets'), { recursive: true });
  writeFileSync(join(projectRoot, 'entry/src/main/ets/n2b-stubs.ets'),
    'export namespace scanBarcode {\n  export enum ScanType { ALL = 0, ONE = 1 }\n  export function startScanForResult(...args: ESObject[]): ESObject { return undefined; }\n}\n');
  writeFileSync(join(projectRoot, 'build-profile.json5'),
    '{ "app": { "products": [{ "name": "default" }] }, "modules": [] }');
  const artifact = { artifacts: [{ module: '@kit.ScanKit', name: 'ScanKitScanBarcode', symbol: 'scanBarcode', category: 'degraded_bridge',
    files: { interface: 'commons/kit-ScanKit/interface/ScanKitScanBarcodeInterface.ets' } }] };
  wireBridgeToProject(bridgeOut, projectRoot, 'modify', artifact);
  // namespace 镜像文件应在场（以 artifact.symbol=scanBarcode 匹配 n2b-stubs namespace）
  const nsFile = join(projectRoot, 'commons', 'kit_scankit', 'src', 'main', 'ets', 'kit_scankit_namespace.ets');
  assert.ok(existsSync(nsFile), 'namespace 镜像文件在場（artifact.symbol 候选名匹配成功）');
  const nsText = readFileSync(nsFile, 'utf8');
  assert.ok(nsText.includes('export namespace scanBarcode'), 'namespace scanBarcode 在场');
  assert.ok(nsText.includes('ScanType'), '枚举 ScanType 保留（业务码 scanBarcode.ScanType.ALL 可达）');
  const idx = readFileSync(join(projectRoot, 'commons', 'kit_scankit', 'Index.ets'), 'utf8');
  assert.ok(idx.includes("export * from './src/main/ets/kit_scankit_namespace'"), 'Index.ets 导出 namespace 镜像');
  rmSync(bridgeOut, { recursive: true, force: true });
  rmSync(projectRoot, { recursive: true, force: true });
});
