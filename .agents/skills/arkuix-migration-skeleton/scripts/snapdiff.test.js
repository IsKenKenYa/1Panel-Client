import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mkdtempSync, mkdirSync, writeFileSync, rmSync, appendFileSync } from 'node:fs';
import { tmpdir } from 'node:os';
import { join } from 'node:path';
import { snapshotProject, diffSnapshots } from './snapdiff.js';

test('快照 diff 覆盖新增+改写+删除（全工程，不限于 .arkui-x）', () => {
  const root = mkdtempSync(join(tmpdir(), 'f1-snapdiff-'));
  mkdirSync(join(root, '.arkui-x', 'android'), { recursive: true });
  writeFileSync(join(root, 'hvigorfile.ts'), 'export {};\n');
  writeFileSync(join(root, 'keep.txt'), 'x\n');
  const before = snapshotProject(root);
  writeFileSync(join(root, '.arkui-x', 'android', 'build.gradle'), 'g\n');            // 新增
  appendFileSync(join(root, 'hvigorfile.ts'), '// ace inject\n');                       // 改写（既有文件）
  rmSync(join(root, 'keep.txt'));                                                       // 删除
  const diff = diffSnapshots(before, snapshotProject(root));
  assert.ok(diff.includes('+ .arkui-x/android/build.gradle'));
  assert.ok(diff.includes('~ hvigorfile.ts'), '既有文件改写必须入清单（实测漏报点）');
  assert.ok(diff.includes('- keep.txt'));
  rmSync(root, { recursive: true, force: true });
});
