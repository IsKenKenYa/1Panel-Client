import { test } from 'node:test';
import assert from 'node:assert/strict';
import { loadTypeMap, checkSignatures, _setCache } from './signature-checker.js';

const ITEM = { name: 'X', module: '@ohos.x', symbol: 'y' };

test('loadTypeMap+checkSignatures：可映射类型零报告项（一致侧）', () => {
  const map = loadTypeMap();
  const contracts = [{ interfaceName: 'XI', methods: [{ name: 'm', params: [{ type: 'string', name: 'p0' }, { type: 'number', name: 'p1' }] }] }];
  assert.deepEqual(checkSignatures([ITEM], contracts, map), []);
});

test('checkSignatures：无映射/歧义类型全量检出入报告', () => {
  const map = loadTypeMap();
  const contracts = [{ interfaceName: 'XI', methods: [{ name: 'm', params: [{ type: 'CustomType', name: 'p0' }, { type: 'ArrayBuffer', name: 'p1' }] }] }];
  const ms = checkSignatures([ITEM], contracts, map);
  // CustomType：java+objc 无映射 2 项；ArrayBuffer：java+objc 歧义 2 项
  assert.equal(ms.length, 4);
  assert.ok(ms.every((m) => m.issue.includes('需人工')));
  assert.ok(ms.some((m) => m.issue.includes('映射歧义')));
});

test('checkSignatures：歧义项含两侧映射值（宁缺毋错）', () => {
  const map = loadTypeMap();
  const contracts = [{ interfaceName: 'XI', methods: [{ name: 'm', params: [{ type: 'ArrayBuffer', name: 'p0' }] }] }];
  const ms = checkSignatures([ITEM], contracts, map);
  assert.ok(ms.find((m) => m.side === 'java').issue.includes('byte[]'));
  assert.ok(ms.find((m) => m.side === 'objc').issue.includes('NSData'));
});
