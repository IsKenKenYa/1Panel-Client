import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, rmSync, existsSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { applyRewrites } from './rewriter.js';

function setup() {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'entry/src/main/ets/pages'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'),
    `import deviceInfo from '@ohos.deviceInfo';\nimport map from '@hms.map';\n\nexport function test() {\n  const udid = deviceInfo.udid;\n  const loc = map.MapComponent.getLocation();\n  return udid + loc;\n}\n`);
  return root;
}

const DECISIONS = [
  { point: 'bd:@ohos.deviceInfo::udid', chosen: '裁剪', source: 'ohos-unique' },
  { point: 'bd:@hms.map::MapComponent', chosen: '降级为OH替代', source: 'hms-closed' },
  { point: 'uk:@ohos.sensor::sensor', chosen: 'equivalent_bridge', source: 'unknown' },
];

const SCAN = {
  adaptation: {
    full_direct: [],
    unknown: [],
    business_decision: [
      { module: '@ohos.deviceInfo', symbol: 'udid', locations: ['entry/src/main/ets/pages/Index.ets:5'] },
      { module: '@hms.map', symbol: 'MapComponent', locations: ['entry/src/main/ets/pages/Index.ets:6'] },
    ],
    equivalent_bridge: [
      { module: '@ohos.sensor', symbol: 'sensor', locations: ['entry/src/main/ets/pages/Index.ets:4'] },
    ],
  },
};

test('删除类——import 注释 + 调用点 TODO（幂等）', () => {
  const root = setup();
  const r = applyRewrites(root, DECISIONS, SCAN);
  assert.ok(r.commentedImports >= 1, `import 注释数=${r.commentedImports}`);
  assert.ok(r.todoSites >= 2, `TODO 数=${r.todoSites}`);
  const text = readFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8');
  assert.ok(text.includes('[MIG]'), '标注在场');
  assert.ok(/[MIG].*import\s+deviceInfo/.test(text), 'deviceInfo import 被注释');
  assert.ok(/[MIG].*import\s+map/.test(text), 'hms.map import 被注释');
  assert.ok(text.includes('裁剪'), '裁剪 TODO');
  assert.ok(text.includes('替代实现'), '降级替代 TODO');
  assert.ok(text.includes('切换到 F3 六件套'), '桥接切换 TODO');
  // 幂等
  const r2 = applyRewrites(root, DECISIONS, SCAN);
  assert.equal(r2.rewritten, 0, `二次改写=${r2.rewritten}（应 0）`);
  rmSync(root, { recursive: true, force: true });
});

test('import 注释后重定向到 stub 模块（namespace/type/function 提取）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'entry/src/main/ets'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/A.ets'),
    `import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';\n\nexport function go(w: WantAgent): string {\n  return wantAgent.bundleName(w);\n}\n`);
  const decisions = [{ point: 'bd:@ohos.app.ability.wantAgent::wantAgent', chosen: '裁剪', source: 'ohos-unique' }];
  const scan = { adaptation: { business_decision: [
    { module: '@ohos.app.ability.wantAgent', symbol: 'wantAgent', locations: [] },
  ] } };
  const r = applyRewrites(root, decisions, scan);
  assert.ok(r.commentedImports === 1 && r.stubNames === 2, `commented=${r.commentedImports} stubNames=${r.stubNames}`);
  const text = readFileSync(join(root, 'entry/src/main/ets/A.ets'), 'utf8');
  assert.ok(!text.includes('as ESObject'), '.ets 内零内联 stub 语句');
  assert.ok(/\[MIG\][^\n]*\nimport.*wantAgent.*n2b-stubs/.test(text), '注释行紧跟重定向 import');
  const stub = readFileSync(join(root, 'entry/src/main/ets/n2b-stubs.ets'), 'utf8');
  assert.ok(stub.includes('export namespace wantAgent'), '命名空间在场');
  assert.ok(stub.includes('export function bundleName('), '成员调用 wantAgent.bundleName(');
  assert.ok(stub.includes('export type WantAgent = ESObject;'), '纯类型名 WantAgent 顶层 type 别名');
  assert.ok(!stub.includes('declare namespace'), '非 ambient 形态');
  rmSync(root, { recursive: true, force: true });
});

test('类型限定用法 N.Type 与枚举 N.E.M 提取', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'phone/src/main/ets/pages'), { recursive: true });
  writeFileSync(join(root, 'phone/src/main/ets/pages/P.ets'),
    `import { scanBarcode, scanCore } from '@kit.ScanKit';\n\nconst opt: scanBarcode.ScanOptions = {};\nconst r: Array<scanBarcode.ScanResult> = [];\nscanBarcode.startScanForResult(opt);\nif (r[0].t === scanCore.ScanType.ALL) {}\n`);
  const decisions = [
    { point: 'bd:@kit.ScanKit::scanBarcode', chosen: '降级为OH替代', source: 'kit-closed' },
    { point: 'bd:@kit.ScanKit::scanCore', chosen: '降级为OH替代', source: 'kit-closed' },
  ];
  const scan = { adaptation: { business_decision: [
    { module: '@kit.ScanKit', symbol: 'scanBarcode', locations: [] },
    { module: '@kit.ScanKit', symbol: 'scanCore', locations: [] },
  ] } };
  const r = applyRewrites(root, decisions, scan);
  assert.equal(r.commentedImports, 1);
  const stub = readFileSync(join(root, 'phone/src/main/ets/n2b-stubs.ets'), 'utf8');
  assert.ok(stub.includes('export type ScanOptions = ESObject;'), 'ScanOptions 类型 stub');
  assert.ok(stub.includes('export type ScanResult = ESObject;'), 'ScanResult 类型 stub');
  assert.ok(stub.includes('export function startScanForResult('), 'startScanForResult() 成员 stub');
  assert.ok(/export enum ScanType \{ ALL = 0/.test(stub), 'ScanType 枚举 stub');
  const text = readFileSync(join(root, 'phone/src/main/ets/pages/P.ets'), 'utf8');
  assert.ok(text.includes("import { scanBarcode, scanCore } from '../n2b-stubs';"), 'kit 全命中→重定向 stub（子目录相对路径）');
  rmSync(root, { recursive: true, force: true });
});

test('⑥降级为平台原生桥接——import 注释+stub 重定向+六件套切换 TODO（与 uk→③④同款）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'entry/src/main/ets/pages'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/pages/S.ets'),
    `import { customScan } from '@kit.ScanKit';\n\nexport function go(): void {\n  customScan.startScan();\n}\n`);
  const decisions = [{ point: 'bd:@kit.ScanKit::customScan', chosen: '降级为平台原生桥接', source: 'kit-closed' }];
  const scan = { adaptation: { degraded_bridge: [
    { module: '@kit.ScanKit', symbol: 'customScan', locations: ['entry/src/main/ets/pages/S.ets:4'] },
  ] } };
  const r = applyRewrites(root, decisions, scan);
  assert.equal(r.commentedImports, 1, `import 注释数=${r.commentedImports}`);
  const text = readFileSync(join(root, 'entry/src/main/ets/pages/S.ets'), 'utf8');
  assert.ok(/[MIG].*import\s+\{ customScan \}\s+from\s+'@kit\.ScanKit'/.test(text), '原 kit import 被注释');
  assert.ok(/import \{ customScan \} from '\.\.\/n2b-stubs';/.test(text), '重定向 stub 编译保绿（pages 子目录相对路径）');
  assert.ok(text.includes('切换到 F3 六件套'), '调用点六件套切换 TODO');
  rmSync(root, { recursive: true, force: true });
});

test('kit 聚合导入拆分——命中决策模块的符号改自 stub 导入，其余符号重发 kit import', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  const kits = mkdtempSync(join(tmpdir(), 'f4-kits-'));
  mkdirSync(join(root, 'entry/src/main/ets'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/B.ets'),
    `import { wantAgent, ability } from '@kit.AbilityKit';\n\nexport function go(): void {\n  ability.getContext();\n  wantAgent.getWantAgent();\n}\n`);
  writeFileSync(join(kits, '@kit.AbilityKit.d.ts'),
    `import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';\nimport { ability } from '@ohos.app.ability.ability';\n`);
  const decisions = [{ point: 'bd:@ohos.app.ability.wantAgent::wantAgent', chosen: '裁剪', source: 'ohos-unique' }];
  const scan = { adaptation: { business_decision: [
    { module: '@ohos.app.ability.wantAgent', symbol: 'wantAgent', locations: [] },
  ] } };
  const r = applyRewrites(root, decisions, scan, { kitsDir: kits });
  assert.equal(r.kitSplits, 1, `kit 拆分数=${r.kitSplits}`);
  assert.equal(r.stubNames, 1, `stub 名字数=${r.stubNames}`);
  const text = readFileSync(join(root, 'entry/src/main/ets/B.ets'), 'utf8');
  assert.ok(/\[MIG\][^\n]*@kit\.AbilityKit[^\n]*→ @ohos\.app\.ability\.wantAgent/.test(text), '原 kit import 被注释并标注模块映射');
  assert.ok(text.includes("import { ability } from '@kit.AbilityKit';"), '未命中符号重发 kit import');
  assert.ok(text.includes("import { wantAgent } from './n2b-stubs';"), '命中符号重定向 stub 模块');
  const stub = readFileSync(join(root, 'entry/src/main/ets/n2b-stubs.ets'), 'utf8');
  assert.ok(stub.includes('export namespace wantAgent'), '命中符号 stub 命名空间');
  assert.ok(stub.includes('export function getWantAgent('), '成员 getWantAgent(');
  // 幂等
  const r2 = applyRewrites(root, decisions, scan, { kitsDir: kits });
  assert.equal;
  rmSync(root, { recursive: true, force: true });
  rmSync(kits, { recursive: true, force: true });
});

test('kit 全部符号命中→不重发 import；无 kit 索引→kit 行不动（降级）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  const kits = mkdtempSync(join(tmpdir(), 'f4-kits-'));
  mkdirSync(join(root, 'entry/src/main/ets'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/C.ets'),
    `import { wantAgent } from '@kit.AbilityKit';\n\nexport function go(): void {\n  wantAgent.getWantAgent();\n}\n`);
  writeFileSync(join(kits, '@kit.AbilityKit.d.ts'),
    `import wantAgent, { WantAgent } from '@ohos.app.ability.wantAgent';\n`);
  const decisions = [{ point: 'bd:@ohos.app.ability.wantAgent::wantAgent', chosen: '裁剪', source: 'ohos-unique' }];
  const scan = { adaptation: { business_decision: [
    { module: '@ohos.app.ability.wantAgent', symbol: 'wantAgent', locations: [] },
  ] } };
  const r = applyRewrites(root, decisions, scan, { kitsDir: kits });
  const text = readFileSync(join(root, 'entry/src/main/ets/C.ets'), 'utf8');
  assert.ok(!/^\s*import\s.*@kit\.AbilityKit/m.test(text), '全部命中→无活跃重发 kit import 行');
  assert.ok(text.includes("import { wantAgent } from './n2b-stubs';"), '重定向 stub 模块');
  assert.ok(readFileSync(join(root, 'entry/src/main/ets/n2b-stubs.ets'), 'utf8').includes('export namespace wantAgent'), 'stub 在场');
  // 无索引降级
  const root2 = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root2, 'entry/src/main/ets'), { recursive: true });
  writeFileSync(join(root2, 'entry/src/main/ets/C.ets'),
    `import { wantAgent } from '@kit.AbilityKit';\n\nexport function go(): void {\n  wantAgent.getWantAgent();\n}\n`);
  const r2 = applyRewrites(root2, decisions, scan, { kitsDir: null });
  assert.equal(r2.commentedImports, 0, '无索引→kit 行不改（宁缺毋错）');
  rmSync(root, { recursive: true, force: true });
  rmSync(kits, { recursive: true, force: true });
  rmSync(root2, { recursive: true, force: true });
});

test('② reduced_direct 编译阻断项——调用点 TODO（不动 import）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'entry/src/main/ets'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/D.ets'),
    `import { window } from '@kit.ArkUI';\n\nexport function f(): void {\n  window.getLastWindow();\n}\n`);
  const scan = { adaptation: { reduced_direct: [
    { module: '@ohos.window', symbol: 'window', advice: '按页内平台标注调整用法',
      locations: ['entry/src/main/ets/D.ets:3'] },
  ] } };
  const r = applyRewrites(root, [], scan); // 无决策——仅②阻断项也触发改写
  assert.equal(r.rdSites, 1, `rd TODO=${r.rdSites}`);
  assert.equal(r.commentedImports, 0, '不动 import');
  const text = readFileSync(join(root, 'entry/src/main/ets/D.ets'), 'utf8');
  assert.ok(text.includes('import { window }'), 'import 原样保留');
  assert.ok(text.includes('②部分支持'), 'TODO 含②阻断标注');
  assert.ok(text.includes('@ohos.window::window → ②部分支持'), 'module::symbol 标注');
  const r2 = applyRewrites(root, [], scan);
  assert.equal(r2.rewritten, 0, '幂等');
  rmSync(root, { recursive: true, force: true });
});

test('行号降序应用——TODO 落点不被改写漂移', () => {
  const root = setup();
  const r = applyRewrites(root, DECISIONS, SCAN);
  assert.ok(r.todoSites >= 2 && r.stubNames >= 2);
  const text = readFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8');
  // 调用点 TODO 应紧贴其目标行上方（import 注释不漂移后续 TODO 落点）
  assert.ok(/\[MIG\][^\n]*@ohos\.deviceInfo::udid[^\n]*\n\s*const udid/.test(text), 'deviceInfo TODO 紧贴调用行');
  assert.ok(/\[MIG\][^\n]*@hms\.map::MapComponent[^\n]*\n\s*const loc/.test(text), 'map TODO 紧贴调用行');
  rmSync(root, { recursive: true, force: true });
});

test('字面量赋值站点提取属性 → interface 形状 stub（嵌套字面量编译兼容）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'player/src/main/ets/util'), { recursive: true });
  writeFileSync(join(root, 'player/src/main/ets/util/BackgroundUtil.ets'),
    `import { wantAgent } from '@kit.BackgroundTasksKit';\n\nexport function start(): void {\n  const info: wantAgent.WantAgentInfo = {\n    wants: [\n      { bundleName: 'com.x', abilityName: 'Main' }\n    ],\n    actionType: wantAgent.OperationType.START_ABILITY,\n    requestCode: 0\n  };\n  wantAgent.getWantAgent(info);\n}\n`);
  const decisions = [{ point: 'bd:@ohos.app.ability.wantAgent::wantAgent', chosen: '降级为OH替代', source: 'ohos-unique' }];
  const scan = { adaptation: { business_decision: [
    { module: '@ohos.app.ability.wantAgent', symbol: 'wantAgent', locations: [] },
  ] } };
  const kits = mkdtempSync(join(tmpdir(), 'f4-kits-'));
  writeFileSync(join(kits, '@kit.BackgroundTasksKit.d.ts'),
    `import { wantAgent } from '@ohos.app.ability.wantAgent';\n`);
  const r = applyRewrites(root, decisions, scan, { kitsDir: kits });
  const stub = readFileSync(join(root, 'player/src/main/ets/n2b-stubs.ets'), 'utf8');
  const iface = stub.match(/export interface WantAgentInfo \{[\s\S]*?\n\}/)?.[0] ?? '';
  for (const p of ['wants?: Array<WantAgentInfoWants>;', 'actionType?: ESObject;', 'requestCode?: ESObject;']) {
    assert.ok(iface.includes(p), `interface 形状缺 ${p}：${iface}`);
  }
  const wantsIface = stub.match(/export interface WantAgentInfoWants \{[\s\S]*?\n\}/)?.[0] ?? '';
  assert.ok(wantsIface.includes('bundleName?: ESObject;') && wantsIface.includes('abilityName?: ESObject;'), `数组元素形状：${wantsIface}`);
  assert.ok(/export enum OperationType \{ START_ABILITY = 0 \}/.test(stub), '枚举提取');
  assert.ok(stub.includes('export function getWantAgent('), '函数提取');
  rmSync(root, { recursive: true, force: true });
  rmSync(kits, { recursive: true, force: true });
});

test('返回类型/直接注解的顶层名 → interface 形状', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'playlist/src/main/ets/view'), { recursive: true });
  writeFileSync(join(root, 'playlist/src/main/ets/view/P.ets'),
    `import { HdsNavigationTitleBarOptions } from '@hms.hds';\n\nexport class A {\n  private getBar(): HdsNavigationTitleBarOptions {\n    if (this.x) {\n      return {\n        padding: { start: 1, end: 2 },\n        style: { originalStyle: {} }\n      };\n    }\n    const b: HdsNavigationTitleBarOptions = { padding: { start: 3, end: 4 } };\n    return b;\n  }\n}\n`);
  const decisions = [{ point: 'bd:@hms.hds::HdsNavigationTitleBarOptions', chosen: '降级为OH替代', source: 'hms-closed' }];
  const scan = { adaptation: { business_decision: [
    { module: '@hms.hds', symbol: 'HdsNavigationTitleBarOptions', locations: [] },
  ] } };
  const r = applyRewrites(root, decisions, scan);
  const stub = readFileSync(join(root, 'playlist/src/main/ets/n2b-stubs.ets'), 'utf8');
  // 对象值递归为具名嵌套接口；数组值平铺
  assert.ok(stub.includes('padding?: HdsNavigationTitleBarOptionsPadding;'), '对象值 → 嵌套接口引用');
  const nested = stub.match(/export interface HdsNavigationTitleBarOptionsPadding \{[\s\S]*?\n\}/)?.[0] ?? '';
  assert.ok(nested.includes('start?: ESObject;') && nested.includes('end?: ESObject;'), `嵌套字段：${nested}`);
  assert.ok(stub.includes('style?: HdsNavigationTitleBarOptionsStyle;'), '多层嵌套引用');
  const styleNested = stub.match(/export interface HdsNavigationTitleBarOptionsStyle \{[\s\S]*?\n\}/)?.[0] ?? '';
  assert.ok(styleNested.includes('originalStyle?: HdsNavigationTitleBarOptionsStyleOriginalStyle;') || styleNested.includes('originalStyle?:'), `二级嵌套：${styleNested}`);
  assert.ok(!stub.includes('export namespace HdsNavigationTitleBarOptions'), '类型位名不应发 namespace');
  const text = readFileSync(join(root, 'playlist/src/main/ets/view/P.ets'), 'utf8');
  assert.ok(text.includes("import { HdsNavigationTitleBarOptions } from '../n2b-stubs';"), '重定向在场');
  rmSync(root, { recursive: true, force: true });
});

test('无决策时零改写', () => {
  const root = setup();
  const r = applyRewrites(root, [], SCAN);
  assert.equal(r.rewritten, 0);
  const r2 = applyRewrites(root, [{ point: 'bd:x::y', source: 'hms' }], SCAN); // 无 chosen
  assert.equal;
  rmSync(root, { recursive: true, force: true });
});

test('改写安全性——.ets 内 N2B 行均为注释或 kit 重发 import（零内联语句）', () => {
  const root = setup();
  applyRewrites(root, DECISIONS, SCAN);
  const text = readFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8');
  const lines = text.split('\n');
  for (const l of lines) {
    if (!l.includes('[MIG]')) continue;
    assert.ok(l.trim().startsWith('//') || /^\s*import\s/.test(l), `改写行应为注释/重发 import: ${l}`);
  }
  rmSync(root, { recursive: true, force: true });
});

test('stub 模块手改区保护——重跑同名 namespace 成员级合并、已有声明不重写、缺失声明追加', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'entry/src/main/ets'), { recursive: true });
  const stubPath = join(root, 'entry/src/main/ets/n2b-stubs.ets');
  writeFileSync(stubPath, [
    '/**',
    ' * [MIG] 自动生成的编译保绿 stub 模块。',
    ' */',
    'export namespace wantAgent {',
    '  export function getWantAgent(...args: ESObject[]): ESObject {',
    '    return undefined;',
    '  }',
    '  export function myHandWritten(...args: ESObject[]): ESObject { // 手改区',
    '    return undefined;',
    '  }',
    '}',
    'export interface HandMadeShape { x?: ESObject; } // 手改声明',
    '',
  ].join('\n'));
  writeFileSync(join(root, 'entry/src/main/ets/A.ets'),
    `import { wantAgent } from '@ohos.app.ability.wantAgent';\n\nexport function go(): void {\n  wantAgent.getWantAgent();\n  wantAgent.cancelWantAgent();\n}\n`);
  const decisions = [{ point: 'bd:@ohos.app.ability.wantAgent::wantAgent', chosen: '裁剪', source: 'ohos-unique' }];
  const scan = { adaptation: { business_decision: [
    { module: '@ohos.app.ability.wantAgent', symbol: 'wantAgent', locations: [] },
  ] } };
  applyRewrites(root, decisions, scan);
  const stub = readFileSync(stubPath, 'utf8');
  assert.ok(stub.includes('myHandWritten'), '手改成员保留');
  assert.ok(stub.includes('export interface HandMadeShape'), '手改声明保留');
  assert.ok(stub.includes('export function cancelWantAgent('), '新用例成员补入');
  assert.ok((stub.match(/export namespace wantAgent/g) ?? []).length === 1, '无重复 namespace');
  rmSync(root, { recursive: true, force: true });
});

test('TODO 落点同名歧义 → 宁缺毋错跳过并计数', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-rw-'));
  mkdirSync(join(root, 'entry/src/main/ets/pages'), { recursive: true });
  mkdirSync(join(root, 'phone/src/main/ets/pages'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'), `import deviceInfo from '@ohos.deviceInfo';\n`);
  writeFileSync(join(root, 'phone/src/main/ets/pages/Index.ets'), `import deviceInfo from '@ohos.deviceInfo';\n`);
  const decisions = [{ point: 'bd:@ohos.deviceInfo::udid', chosen: '裁剪', source: 'ohos-unique' }];
  const scan = { adaptation: { business_decision: [
    { module: '@ohos.deviceInfo', symbol: 'udid', locations: ['oldmodule/src/main/ets/pages/Index.ets:1'] },
  ] } };
  const r = applyRewrites(root, decisions, scan);
  assert.ok(r.ambiguous >= 1, `歧义计数=${r.ambiguous}`);
  assert.equal(r.todoSites, 0, '歧义 TODO 不落盘');
  assert.ok(r.log.some((l) => l.includes('歧义跳过')), '歧义入日志');
  rmSync(root, { recursive: true, force: true });
});

// ── N.Sub.member(...) 调用形态：占位须为 class+静态方法（枚举成员不可调用，保证编译绿）──
test('类形态成员——MapComponent.getLocation() 调用 → class static 占位而非 enum', () => {
  const root = setup();
  applyRewrites(root, DECISIONS, SCAN);
  const stub = readFileSync(join(root, 'entry/src/main/ets/n2b-stubs.ets'), 'utf8');
  assert.ok(stub.includes('export class MapComponent'), 'class 占位在场');
  assert.ok(/public static getLocation\(/.test(stub), '静态方法占位在场');
  assert.ok(!stub.includes('export enum MapComponent'), '不得以 enum 占位（enum 成员不可调用）');
  rmSync(root, { recursive: true, force: true });
});

// ── lazy import 关键字剥离：import lazy { X } from '@kit.X' → X 进 stub，不把 lazy 当导入名 ──
test('lazy 前缀剥离：import lazy { scanCore, scanBarcode } from "@kit.ScanKit" → 命中符号改 stub，重发不含 lazy', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-lazy-'));
  mkdirSync(join(root, 'entry/src/main/ets/pages'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'),
    'import lazy { scanCore, scanBarcode } from "@kit.ScanKit";\n\nexport function call() {\n  scanCore.scan();\n  scanBarcode.startScanForResult();\n}\n');
  const DECISIONS = [
    { point: 'bd:@kit.ScanKit::scanCore', chosen: '降级为平台原生桥接', source: 'kit-closed' },
    { point: 'bd:@kit.ScanKit::scanBarcode', chosen: '降级为平台原生桥接', source: 'kit-closed' },
  ];
  const SCAN = {
    adaptation: { full_direct: [], reduced_direct: [], equivalent_bridge: [], degraded_bridge: [],
      platform_trim: [], business_decision: [
        { module: '@kit.ScanKit', symbol: 'scanCore', locations: ['entry/src/main/ets/pages/Index.ets:4'] },
        { module: '@kit.ScanKit', symbol: 'scanBarcode', locations: ['entry/src/main/ets/pages/Index.ets:5'] },
      ], unknown: [] },
  };
  const r = applyRewrites(root, DECISIONS, SCAN);
  const text = readFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'), 'utf8');
  assert.ok(text.match(/from\s+'[^']*n2b-stubs'/), '命中符号改 stub（路径随文件深度变化）');
  assert.ok(!text.match(/^import\s+\{[^}]*\blazy\b/m), 'stub 重定向行不含 lazy（前缀已剥离）');
  rmSync(root, { recursive: true, force: true });
});

// ── 跨模块 n2b-stubs 路径：lazy 导入在非 entry 模块 → stub 落该模块根，路径可达 ──
test('跨模块 lazy 导入：sample_common 模块的 @kit lazy 导入 → stub 落 sample_common/src/main/ets/，路径可达', () => {
  const root = mkdtempSync(join(tmpdir(), 'f4-xmod-'));
  mkdirSync(join(root, 'entry/src/main/ets/pages'), { recursive: true });
  mkdirSync(join(root, 'sample_common/src/main/ets/utils'), { recursive: true });
  writeFileSync(join(root, 'entry/src/main/ets/pages/Index.ets'),
    'import { scanBarcode } from "@kit.ScanKit";\nscanBarcode.startScanForResult();\n');
  writeFileSync(join(root, 'sample_common/src/main/ets/utils/CommonUtils.ets'),
    'import lazy { scanCore, scanBarcode } from "@kit.ScanKit";\nexport function f() { scanCore.scan(); }\n');
  const DECISIONS = [
    { point: 'bd:@kit.ScanKit::scanBarcode', chosen: '降级为平台原生桥接', source: 'kit-closed' },
    { point: 'bd:@kit.ScanKit::scanCore', chosen: '降级为平台原生桥接', source: 'kit-closed' },
  ];
  const SCAN = { adaptation: { full_direct: [], reduced_direct: [], equivalent_bridge: [], degraded_bridge: [],
    platform_trim: [], business_decision: [
      { module: '@kit.ScanKit', symbol: 'scanBarcode', locations: ['entry/src/main/ets/pages/Index.ets:2'] },
      { module: '@kit.ScanKit', symbol: 'scanCore', locations: ['sample_common/src/main/ets/utils/CommonUtils.ets:2'] },
    ], unknown: [] } };
  applyRewrites(root, DECISIONS, SCAN);
  // 两模块各应有自己的 n2b-stubs.ets（stubSpecifierOf 按模块根计算路径）
  assert.ok(existsSync(join(root, 'entry/src/main/ets/n2b-stubs.ets')), 'entry 模块根有 n2b-stubs');
  assert.ok(existsSync(join(root, 'sample_common/src/main/ets/n2b-stubs.ets')), 'sample_common 模块根有 n2b-stubs');
  // CommonUtils 的 import 重定向路径可达（../n2b-stubs 从 utils/ 到 ets/）
  const cu = readFileSync(join(root, 'sample_common/src/main/ets/utils/CommonUtils.ets'), 'utf8');
  assert.ok(cu.match(/from\s+'[^']*n2b-stubs'/), 'CommonUtils 重定向到 n2b-stubs（路径可达）');
  assert.ok(!cu.match(/^import\s+\{[^}]*\blazy\b/m), '重定向行不含 lazy');
  rmSync(root, { recursive: true, force: true });
});
