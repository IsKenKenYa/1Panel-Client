import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, readFileSync, existsSync, rmSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { migrateSources, verifyMigration } from './migrate.js';


test('AppScope 项目级资源随迁——源覆盖同名、scaffold 独有保留、app.json5 保留定制版', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-as-src-'));
  const outDir = mkdtempSync(join(tmpdir(), 'f1-as-out-'));
  mkdirSync(join(srcRoot, 'entry/src/main/ets/pages'), { recursive: true });
  mkdirSync(join(srcRoot, 'AppScope/media'), { recursive: true });
  writeFileSync(join(srcRoot, 'entry/src/main/ets/pages/A.ets'), '@Entry struct A {}');
  writeFileSync(join(srcRoot, 'AppScope/media/tietu.png'), 'png');
  writeFileSync(join(srcRoot, 'AppScope/app.json5'), '{ "app": { "bundleName": "com.src.real" } }');
  // scaffold 侧预置：定制 app.json5 + 独有资源
  mkdirSync(join(outDir, 'AppScope/resources/base/element'), { recursive: true });
  writeFileSync(join(outDir, 'AppScope/app.json5'), '{ "app": { "bundleName": "com.scaffold.custom" } }');
  writeFileSync(join(outDir, 'AppScope/resources/base/element/string.json'), '{"string":[{"name":"app_name","value":"X"}]}');
  const r = migrateSources(srcRoot, outDir);
  assert.equal(r.ok, true, r.reason);
  assert.ok(existsSync(join(outDir, 'AppScope/media/tietu.png')), '源媒体资源随迁');
  assert.ok(existsSync(join(outDir, 'AppScope/resources/base/element/string.json')), 'scaffold 独有资源保留');
  assert.ok(readFileSync(join(outDir, 'AppScope/app.json5'), 'utf8').includes('com.scaffold.custom'), 'app.json5 保留 scaffold 定制');
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});

test('verify：AppScope 键路径校验（场景实测回归）', () => {
  const srcRoot = mkdtempSync(join(tmpdir(), 'f1-asv-src-'));
  const outDir = mkdtempSync(join(tmpdir(), 'f1-asv-out-'));
  mkdirSync(join(srcRoot, 'entry/src/main/ets/pages'), { recursive: true });
  mkdirSync(join(srcRoot, 'AppScope/media'), { recursive: true });
  writeFileSync(join(srcRoot, 'entry/src/main/ets/pages/A.ets'), '@Entry struct A {}');
  writeFileSync(join(srcRoot, 'AppScope/media/tietu.png'), 'png');
  const r = migrateSources(srcRoot, outDir);
  assert.equal(r.ok, true, r.reason);
  const v = verifyMigration(srcRoot, outDir, r);
  assert.equal(v.ok, true, v.reason ?? 'AppScope 键应校验通过');
  // 篡改 AppScope 文件 → 校验必须失败
  writeFileSync(join(outDir, 'AppScope/media/tietu.png'), 'tampered');
  const v2 = verifyMigration(srcRoot, outDir, r);
  assert.notEqual(v2.ok, true, '篡改应被检出');
  rmSync(srcRoot, { recursive: true, force: true });
  rmSync(outDir, { recursive: true, force: true });
});
