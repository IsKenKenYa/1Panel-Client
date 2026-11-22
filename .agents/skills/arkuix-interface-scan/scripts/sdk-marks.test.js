import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { scanMarks, parseMarks } from './sdk-marks.js';

function makeApiDir(files) {
  const root = mkdtempSync(join(tmpdir(), 'f2-marks-'));
  const apiDir = join(root, 'ets', 'api');
  mkdirSync(apiDir, { recursive: true });
  for (const [name, content] of Object.entries(files)) {
    writeFileSync(join(apiDir, name), content, 'utf8');
  }
  return { root, apiDir };
}

test('模块级标记：文件头 @crossplatform → moduleMarked=true', () => {
  const entry = parseMarks([
    '/**',
    ' * @crossplatform',
    ' */',
    'declare namespace demo {',
    '  function foo(): void;',
    '}',
    'export default demo;'
  ].join('\n'));
  assert.equal(entry.moduleMarked, true);
});

test('符号级标记：头无标记、成员函数带 @crossplatform → symbols 命中', () => {
  const entry = parseMarks([
    '/**',
    ' * @syscap SystemCapability.Test',
    ' */',
    'declare namespace demo {',
    '  /**',
    '   * @crossplatform [since 12]',
    '   */',
    '  function foo(): void;',
    '  /**',
    '   * @syscap SystemCapability.Test',
    '   */',
    '  function bar(): void;',
    '}',
    'export default demo;'
  ].join('\n'));
  assert.equal(entry.moduleMarked, false);
  assert.equal(entry.symbols.get('foo'), true);
  assert.equal(entry.symbols.has('bar'), false);
});

test('无任何标记 → moduleMarked=false，symbols 空', () => {
  const entry = parseMarks('declare namespace demo {\n  function foo(): void;\n}\n');
  assert.equal(entry.moduleMarked, false);
  assert.equal(entry.symbols.size, 0);
});

test('scanMarks：索引含模块名键；读取失败目录抛错（构建失败回退依据）', () => {
  const { root, apiDir } = makeApiDir({
    '@ohos.alpha.d.ts': '/**\n * @crossplatform\n */\ndeclare namespace alpha { function a(): void; }\n',
    '@ohos.beta.d.ts': 'declare namespace beta { function b(): void; }\n'
  });
  const marks = scanMarks(apiDir);
  assert.equal(marks.get('@ohos.alpha').moduleMarked, true);
  assert.equal(marks.get('@ohos.beta').moduleMarked, false);
  assert.throws(() => scanMarks(join(root, 'no-such-dir')));
  rmSync(root, { recursive: true, force: true });
});

test('export default class/enum 声明形态的 @crossplatform 符号级标记不丢失', () => {
  const text = [
    '/**',
    ' * @syscap X.Y.Z',
    ' * @crossplatform [since 10]',
    ' */',
    'export default class Want {',
    '  a: number;',
    '}'
  ].join('\n');
  const { moduleMarked, symbols } = parseMarks(text);
  assert.equal(symbols.get('Want'), true, 'default class 声明应挂上符号级标记');
  assert.equal(moduleMarked, false);
});

test('import 前置于模块 doc 注释时模块级标记不丢失（59 SDK 模块实测根因）', () => {
  const text = [
    "import { AsyncCallback } from './@ohos.base';",
    "import image from './@ohos.multimedia.image';",
    '/**',
    ' * @syscap SystemCapability.WindowManager.SessionManager',
    ' * @crossplatform',
    ' * @since 6',
    ' */',
    'declare namespace window {',
    '  function create(): void;',
    '}',
    'export default window;'
  ].join('\n');
  const { moduleMarked } = parseMarks(text);
  assert.equal(moduleMarked, true, 'import 前置不应丢失模块级 @crossplatform');
});

test('barrel re-export 前置注释的 @crossplatform 逐符号计入（@ohos.arkui.node 实证形态）', () => {
  const text = [
    "import { AsyncCallback } from './@ohos.base';",
    '/**',
    ' * @syscap SystemCapability.ArkUI.ArkUI.Full',
    ' * @crossplatform',
    ' * @since 11',
    ' */',
    "export { NodeRenderType, RenderOptions, BuilderNode } from './arkui/BuilderNode';",
    '/**',
    ' * @syscap SystemCapability.ArkUI.ArkUI.Full',
    ' * @since 12',
    ' */',
    "export { LengthUnit, SizeT, LengthMetrics } from './arkui/Graphics';"
  ].join('\n');
  const { moduleMarked, symbols } = parseMarks(text);
  assert.equal(moduleMarked, false, 'barrel 无 namespace：非模块级');
  assert.equal(symbols.get('NodeRenderType'), true, '标记块导出清单逐符号计入');
  assert.equal(symbols.get('BuilderNode'), true, '同标记块其他符号也计入');
  assert.equal(symbols.get('LengthUnit'), undefined, '无标记块的导出不计入');
});

test('.d.ets 文件纳入索引（ArkSlider 形态）', () => {
  const text = [
    '/**',
    ' * @crossplatform',
    ' */',
    'declare namespace arkui {',
    '  namespace advanced {',
    '    class ArcSlider { }',
    '  }',
    '}',
    'export default arkui;'
  ].join('\n');
  const { moduleMarked } = parseMarks(text);
  assert.equal(moduleMarked, true);
});

test('declare struct 声明的 @crossplatform 标记计入（.d.ets 组件常见形态）', () => {
  const text = [
    '/**',
    ' * @crossplatform',
    ' * @since 12',
    ' */',
    'declare struct ArcSlider {',
    '  build() {}',
    '}'
  ].join('\n');
  const { symbols } = parseMarks(text);
  assert.equal(symbols.get('ArcSlider'), true, 'declare struct 应挂上符号级标记');
});
