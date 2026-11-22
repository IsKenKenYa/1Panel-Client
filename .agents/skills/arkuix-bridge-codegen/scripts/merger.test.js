import { test } from 'node:test';
import assert from 'node:assert/strict';
import { mergeFile, mergeLocal, refillFences } from './merger.js';

const JAVA_DRAFT = [
  'public class BridgeX extends BridgePlugin {',
  '    public String ping(String p0) {',
  '        // ARKUIX-BRIDGE-HANDOFF BEGIN',
  '        // 原占位',
  '        // ARKUIX-BRIDGE-HANDOFF END',
  '        return null;',
  '    }',
  '}',
].join('\n');

test('mergeFile：首生成（existing=null）→草案直写', () => {
  const r = mergeFile(null, JAVA_DRAFT, 'java');
  assert.equal(r.content, JAVA_DRAFT);
  assert.equal(r.kept, false);
});

test('mergeFile：围栏内手改保留、骨架区幂等更新', () => {
  const existing = JAVA_DRAFT.replace('// 原占位', '// 开发者手改：调用原生 API');
  const draft2 = JAVA_DRAFT.replace('public String ping', 'public String ping2'); // 骨架区变更
  const r = mergeFile(existing, draft2, 'java');
  assert.equal(r.kept, true);
  assert.ok(r.content.includes('// 开发者手改：调用原生 API')); // 手改区保留
  assert.ok(r.content.includes('ping2')); // 围栏外骨架区已更新
  assert.ok(r.content.includes('ARKUIX-BRIDGE-HANDOFF BEGIN'));
});

test('mergeFile：同输入再生成→幂等（骨架区与首生成一致）', () => {
  const existing = JAVA_DRAFT.replace('// 原占位', '// 手改');
  const r = mergeFile(existing, JAVA_DRAFT, 'java');
  assert.ok(r.content.includes('ping('));
  assert.ok(r.content.includes('// 手改'));
});

test('mergeFile：无合法围栏→整体替换 kept=false', () => {
  const r = mergeFile('完全无关的既有内容', JAVA_DRAFT, 'java');
  assert.equal(r.kept, false);
  assert.equal(r.content, JAVA_DRAFT);
});

test('mergeFile：①③（无围栏 kind=null）整体幂等替换', () => {
  const r = mergeFile('旧内容', '新草案', null);
  assert.equal(r.content, '新草案');
});

test('mergeLocal：已存在→保留开发者版本', () => {
  const r = mergeLocal('开发者已调整的 Local 实现', '重新迁移内容');
  assert.equal(r.kept, true);
  assert.equal(r.content, '开发者已调整的 Local 实现');
});

test('mergeLocal：不存在→写入迁移内容', () => {
  const r = mergeLocal(null, '迁移内容');
  assert.equal(r.content, '迁移内容');
});
