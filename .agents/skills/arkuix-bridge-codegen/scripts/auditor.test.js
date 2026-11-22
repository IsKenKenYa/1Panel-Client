import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join, dirname } from 'node:path';
import { fileURLToPath } from 'node:url';
import { auditPieces } from './auditor.js';
import { netBracketDepth } from './local-extractor.js';

const ROOT = join(dirname(dirname(fileURLToPath(import.meta.url))), 'benchmark');
const OUT = join(ROOT, '.tmp-auditor');

const NAME = 'SensorSensor';

function piecePaths() {
  return {
    interface: `commons/sensor/interface/${NAME}Interface.ets`,
    local: `commons/sensor/utils/${NAME}Local.ets`,
    arkui_x: `commons/sensor/utils/${NAME}ArkUIX.ets`,
    impl: `commons/sensor/impl/${NAME}Impl.ets`,
    android: `.arkui-x/android/app/src/main/java/com/arkuix/bridge/Bridge${NAME}.java`,
    ios: `.arkui-x/ios/app/BridgeSrc/Bridge${NAME}.h`,
    ios_m: `.arkui-x/ios/app/BridgeSrc/Bridge${NAME}.m`,
  };
}

function writeGoodPieces(overrides = {}) {
  const p = piecePaths();
  const put = (rel, text) => { const f = join(OUT, rel); mkdirSync(dirname(f), { recursive: true }); writeFileSync(f, text, 'utf8'); };
  put(p.interface, `import Bridge from '@arkui-x.bridge';\nexport interface ${NAME}Interface {\n  on(p0: string, p1: ESObject): Promise<Bridge.ResultValue>;\n}\n`);
  put(p.local, `import sensor from '@ohos.sensor';\nsensor.on(sensor.SensorId.HALL, (data) => { return; });\n`);
  put(p.arkui_x, `import Bridge from '@arkui-x.bridge';\nconst b = Bridge.createBridge('${NAME}');\nexport function on(p0: string, p1: ESObject) { return b.callMethod('on', p0, p1); }\n`);
  put(p.android, `package com.arkuix.bridge;\npublic class Bridge${NAME} extends BridgePlugin { }\n`);
  put(p.impl, `import { PlatformInfo, PlatformTypeEnum } from '../../utils/PlatformInfo';\nimport { ${NAME}Interface } from '../interface/${NAME}Interface';\nimport { ${NAME}ArkUIX } from '../utils/${NAME}ArkUIX';\nimport { ${NAME}Local } from '../utils/${NAME}Local';\n\nexport class ${NAME}Impl {\n  public static getInterface(): ${NAME}Interface {\n    return ${NAME}Local.getInstance();\n  }\n}\n`);
  put(p.ios, `@interface Bridge${NAME} : BridgePlugin\n@end\n`);
  put(p.ios_m, `@implementation Bridge${NAME}\n@end\n`);
  for (const [rel, text] of Object.entries(overrides)) put(rel, text);
  return p;
}

function mkPiece(paths, extra = {}) {
  return {
    item: { name: NAME, symbol: 'sensor', module: '@ohos.sensor', category: 'equivalent_bridge',
      locations: ['entry/src/main/ets/pages/Index.ets:12'] },
    paths, texts: {}, localStatus: 'migrated', derived: 'local', ...extra,
  };
}

test('完好五件套 → 自检通过（deficient 空）', (t) => {
  rmSync(OUT, { recursive: true, force: true });
  mkdtempSync(OUT);
  t.after(() => rmSync(OUT, { recursive: true, force: true })); // 兜底清理——断言失败中断不残留临时目录
  const paths = writeGoodPieces();
  const r = auditPieces(OUT, [mkPiece(paths)]);
  assert.equal(r.checked, 1);
  assert.equal(r.deficient_count, 0, JSON.stringify(r.deficient));
  rmSync(OUT, { recursive: true, force: true });
});

test('②Local 括号不闭合 → local-unbalanced（action 指向源 locations）', (t) => {
  rmSync(OUT, { recursive: true, force: true });
  mkdtempSync(OUT);
  t.after(() => rmSync(OUT, { recursive: true, force: true })); // 兜底清理——断言失败中断不残留临时目录
  const p = writeGoodPieces({ [piecePaths().local]: 'sensor.on(id, (data) => {\n  return;\n' });
  const r = auditPieces(OUT, [mkPiece(p)]);
  assert.equal(r.deficient_count, 1);
  const issue = r.deficient[0].issues.find((i) => i.kind === 'local-unbalanced');
  assert.ok(issue, JSON.stringify(r.deficient[0].issues));
  assert.match(issue.detail, /净深度 \+\d+/);
  assert.ok(issue.action.includes('Index.ets:12'), 'action 指向源工程 locations');
  rmSync(OUT, { recursive: true, force: true });
});

test('失败占位/空壳/缺件/契约空壳/结构缺失 全形态识别', (t) => {
  rmSync(OUT, { recursive: true, force: true });
  mkdtempSync(OUT);
  t.after(() => rmSync(OUT, { recursive: true, force: true })); // 兜底清理——断言失败中断不残留临时目录
  // 占位（localStatus=failed）
  let p = writeGoodPieces({ [piecePaths().local]: '// 迁移源：\n// 源码读取失败：迁移语句为空壳（仅 import/注释），需手动补入\n' });
  let r = auditPieces(OUT, [mkPiece(p, { localStatus: 'failed', derived: 'default' })]);
  assert.ok(r.deficient[0].issues.some((i) => i.kind === 'local-placeholder'), '失败占位识别');
  // 空壳（仅注释）
  p = writeGoodPieces({ [piecePaths().local]: '// 只有注释\n' });
  r = auditPieces(OUT, [mkPiece(p)]);
  assert.ok(r.deficient[0].issues.some((i) => i.kind === 'local-shell'), '空壳识别');
  // 契约空壳（无方法声明）
  p = writeGoodPieces({ [piecePaths().interface]: `export interface ${NAME}Interface {\n}\n` });
  r = auditPieces(OUT, [mkPiece(p)]);
  assert.ok(r.deficient[0].issues.some((i) => i.kind === 'interface-thin'), '契约空壳识别');
  // ④缺类结构
  p = writeGoodPieces({ [piecePaths().android]: 'package com.arkuix.bridge;\n// 类体缺失\n' });
  r = auditPieces(OUT, [mkPiece(p)]);
  assert.ok(r.deficient[0].issues.some((i) => i.kind === 'android-shape'), '④结构识别');
  // ⑤.m 缺 @implementation
  p = writeGoodPieces({ [piecePaths().ios_m]: '// 空 m\n' });
  r = auditPieces(OUT, [mkPiece(p)]);
  assert.ok(r.deficient[0].issues.some((i) => i.kind === 'ios-shape'), '⑤.m 结构识别');
  // ⑥分发器结构缺失
  p = writeGoodPieces({ [piecePaths().impl]: '// 仅注释\n' });
  r = auditPieces(OUT, [mkPiece(p)]);
  assert.ok(r.deficient[0].issues.some((i) => i.kind === 'impl-shape'), '⑥Impl 结构识别');
  // 契约兜底（其余完好）→ contract-thin 建议级（不进 deficient）
  p = writeGoodPieces();
  r = auditPieces(OUT, [mkPiece(p, { derived: 'default' })]);
  assert.equal(r.deficient_count, 0, '建议级不进 deficient');
  assert.equal(r.suggestion_count, 1);
  assert.ok(r.suggestions[0].issues.some((i) => i.kind === 'contract-thin'), '契约兜底建议');
  rmSync(OUT, { recursive: true, force: true });
});

test('缺件 → file-missing + action 可执行（⑥impl 亦可检出）', (t) => {
  rmSync(OUT, { recursive: true, force: true });
  mkdtempSync(OUT);
  t.after(() => rmSync(OUT, { recursive: true, force: true })); // 兜底清理——断言失败中断不残留临时目录
  const p = writeGoodPieces();
  rmSync(join(OUT, p.android));
  rmSync(join(OUT, p.impl));
  const r = auditPieces(OUT, [mkPiece(p)]);
  const issues = r.deficient[0].issues.filter((i) => i.kind === 'file-missing');
  assert.equal(issues.length, 2, 'android+impl 两缺件（六件）');
  assert.ok(issues.some((i) => i.file === p.android) && issues.some((i) => i.file === p.impl));
  assert.ok(issues.every((i) => i.action.length > 0));
  rmSync(OUT, { recursive: true, force: true });
});

test('netBracketDepth——字符串/注释括号不计（0=平衡）', (t) => {
  assert.equal(netBracketDepth('const s = "a{b(c)"; // ({\nfoo(1);'), 0);
  assert.equal(netBracketDepth('foo(() => {\n  return;\n'), 2, '缺闭合为正净深度');
  assert.equal(netBracketDepth('`t${x};` }'), -1);
});

test('contract-incomplete 语义自检——契约面 < SDK 声明面 → 建议级呈报', (t) => {
  rmSync(OUT, { recursive: true, force: true });
  mkdtempSync(OUT);
  t.after(() => rmSync(OUT, { recursive: true, force: true })); // 兜底清理——断言失败中断不残留临时目录
  const paths = writeGoodPieces();
  const r = auditPieces(OUT, [mkPiece(paths, { contractMethodCount: 2, sdkFaceMethodCount: 24 })]);
  assert.equal(r.deficient_count, 0, '语义缺口非硬残缺');
  assert.equal(r.suggestion_count, 1);
  const issue = r.suggestions[0].issues.find((i) => i.kind === 'contract-incomplete');
  assert.ok(issue, JSON.stringify(r.suggestions[0].issues));
  assert.match(issue.detail, /契约面 2 方法 < SDK 声明面 24 方法/);
  assert.ok(issue.action.includes('SDK d.ts'), 'action 指引对照声明面补全');
  // 面追平（或声明面源缺失=0）→ 不触发
  const r2 = auditPieces(OUT, [mkPiece(paths, { contractMethodCount: 24, sdkFaceMethodCount: 24 })]);
  assert.equal(r2.suggestions.filter((s) => s.issues.some((i) => i.kind === 'contract-incomplete')).length, 0, '追平不触发');
  const r3 = auditPieces(OUT, [mkPiece(paths, { contractMethodCount: 1, sdkFaceMethodCount: 0 })]);
  assert.equal(r3.suggestions.filter((s) => s.issues.some((i) => i.kind === 'contract-incomplete')).length, 0, '无声明面源不触发');
  rmSync(OUT, { recursive: true, force: true });
});
