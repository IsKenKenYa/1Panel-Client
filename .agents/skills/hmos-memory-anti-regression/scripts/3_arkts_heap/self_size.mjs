#!/usr/bin/env node
/**
 * self_size.mjs — 通过 memlab 获取堆对象 → GC Root 的最短引用链(带 mem_size / 同链聚合)
 *
 * 依赖:  npm i @memlab/heap-analysis
 * 用法:
 *   node self_size.mjs <heap.heapsnapshot> [选项]
 *
 * mem_size:每条最短引用链一个值 = 该链上**所有节点 self_size 的总和**(leaf 自身到 GC Root,
 *   逐节点 self_size 累加;self 不嵌套,可直接相加)。输出到 JSON 的 memSize 字段 / MD 表格列。
 *
 * 引用链聚类(**merge 之后对剩余的最短引用链聚**):--merge 时先做子串合并(吸收前缀链),
 *   再对剩余保留链按链签名(root→leaf 各节点名去除 id 等干扰项 —— [N] 序号、(line:N)/:N
 *   行号,nodeId 不参与)归为一类,类内 mem_size 求和,并**按类折叠输出**(同签名的多条链
 *   合成一条:代表链 + Σmem_size + count,按 Σmem_size 降序)。不带 --merge 时逐链输出,
 *   仅附聚类标注(sig / clusterMemSize / clusterCount);--cluster N 展开该条目所属类成员链。
 *
 * 选项:
 *   --top <N>      按 retainedSize 取 Top N 个对象(默认 10)
 *   --name <regex> 只输出名称匹配该正则的对象
 *   --type <t>     只输出指定 type 的对象(如 object / hidden / closure)
 *   --all          对所有 retainedSize>0 的可达对象输出(量大,慎用)
 *   --json         额外把结果写到 <snapshot>.shortest-path.json
 *   --md           额外把可读报告写到 <snapshot>.shortest-path.md(markdown 格式)
 *   --merge        两步合并:① 子串合并 —— 字典树按 root→leaf nodeId 序列建,前缀链(中间
 *                  dominator)被最深叶子吸收;② 签名折叠 —— 剩余链按链签名聚成一类、
 *                  mem_size 求和、合成一条输出(代表链 + count + Σmem_size)。
 *                  条目 memSize=类Σ,clusterMemSize/clusterCount 同值,sig 为链签名
 *   --cluster <N>  展开第 N 个条目(1-based)**所属引用链类**的所有同签名链(含各自 mem_size),
 *                  无论是否 --merge 都可用(写入 --md / --json,JSON 字段 cluster_members)
 *   --sourcemap <p> 加载 DevEco sourceMap(.map),把引用链里 xxx.ts#Func(line:N)
 *                  还原成 'Func [xxx.ets:源码行号]'(与 arkts_top5.py --sourcemap 同口径,
 *                  生成的 shortest-path.json 可直接喂给 compare_diff.py 与 --diff TSV 对比)
 *
 * 实现说明:
 *   - 用 memlab 的 getFullHeapFromFile 加载快照,它内部会跑
 *     annotateShortestPaths(给每个节点算好 pathEdge/hasPathEdge)+ retained size。
 *   - 最短引用链:优先用 memlab 导出的 getShortestPath;若未导出,则沿
 *     node.pathEdge 回溯(即 memlab getShortestPath 的核心逻辑,见 core.js
 *     collectPathEdges/buildPathResultFromEdges)。
 */

import { writeFileSync, readFileSync, createWriteStream } from 'node:fs';
import path from 'node:path';

// ─── 1. 加载 memlab(多包探测:不同版本 getFullHeapFromFile 落点不同) ──
let getFullHeapFromFile = null, memlabGetShortestPath = null, memlabMod = null;
for (const mod of ['@memlab/core', '@memlab/heap-analysis', 'memlab']) {
  try {
    const m = await import(mod);
    const gh = m.getFullHeapFromFile || m.default?.getFullHeapFromFile;
    if (gh) {
      getFullHeapFromFile = gh;
      memlabGetShortestPath = m.getShortestPath || m.default?.getShortestPath || null;
      memlabMod = mod;
      break;
    }
  } catch { /* 该包未装,继续试下一个 */ }
}
if (!getFullHeapFromFile) {
  console.error('[错误] 未找到 memlab。请安装任一(任选其一即可):\n  npm i @memlab/core\n  npm i @memlab/heap-analysis\n  npm i memlab');
  process.exit(1);
}
console.error(`[memlab] 通过 ${memlabMod} 加载${memlabGetShortestPath ? '(含 getShortestPath)' : '(无 getShortestPath,用 pathEdge 回溯)'}`);

// sourceMap 索引(由 --sourcemap 加载);为空时 displayName 原样返回 name
let smIndex = null;

// ─── 2. CLI 解析 ───────────────────────────────────────────────────
function parseArgs(argv) {
  const o = { top: 10, name: null, type: null, all: false, json: false, md: false, merge: false, cluster: 0, sourcemap: null, file: null };
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (t === '--top') o.top = parseInt(argv[++i], 10) || 10;
    else if (t === '--name') o.name = new RegExp(argv[++i]);
    else if (t === '--type') o.type = argv[++i];
    else if (t === '--all') o.all = true;
    else if (t === '--json') o.json = true;
    else if (t === '--md') o.md = true;
    else if (t === '--merge') o.merge = true;
    else if (t === '--cluster') o.cluster = parseInt(argv[++i], 10) || 0;
    else if (t === '--sourcemap') o.sourcemap = argv[++i];
    else if (!t.startsWith('-') && !o.file) o.file = t;
  }
  return o;
}

const opt = parseArgs(process.argv.slice(2));
if (!opt.file) {
  console.error('用法: node self_size.mjs <heap.heapsnapshot> [--top N] [--name regex] [--type t] [--all] [--merge] [--cluster N] [--sourcemap map] [--json] [--md]');
  process.exit(1);
}

// ─── 3. 工具函数 ───────────────────────────────────────────────────
const fmt = (b) => b >= 1048576 ? `${(b / 1048576).toFixed(2)} MB`
  : b >= 1024 ? `${(b / 1024).toFixed(1)} KB` : `${b} B`;

// 节点字段兼容(memlab 不同版本字段名略有差异)
const retainedOf = (n) => n.retainedSize ?? n.retained_size ?? 0;
const selfOf = (n) => n.self_size ?? n.selfSize ?? 0;
const isRoot = (n) => !!(n.isRoot || n.isGCRoot);

// 责任侧分类(对齐 hmos-jsleak fault-modes)
function rootKind(name) {
  if (/(GlobalEnv|global_env|SourceText|GlobalObject|VMRoot)/.test(name)) return ['VMRoot', 'ArkTS'];
  if (/(Handle|napi_ref|Reference)/.test(name)) return ['GlobalHandleRoot', 'Native'];
  if (/LocalHandle/.test(name)) return ['LocalHandleRoot', 'Native'];
  if (/Frame/.test(name)) return ['FrameRoot', 'ArkTS'];
  return ['Unknown', '待确认'];
}

// ─── 3.5 sourceMap(.ts 编译行号 → .ets 源码行号)──────────────────────
// 与 arkts_top5.py 的 _vlq_decode / _decode_mappings / build_sm_index / display_name 同口径。
const _B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/';
const _B64_IDX = new Map([..._B64].map((c, i) => [c, i]));

function vlqDecode(seg) {
  // 解码一个 VLQ segment 为整数列表(Source Map V3)
  const vals = [];
  let i = 0;
  while (i < seg.length) {
    let v = 0, shift = 0;
    while (true) {
      const d = _B64_IDX.get(seg[i]); i++;
      v |= (d & 31) << shift; shift += 5;
      if (!(d & 32)) break;
    }
    vals.push(v & 1 ? -(v >> 1) : v >> 1);
  }
  return vals;
}

function decodeMappings(mappings) {
  // 解码 mappings,返回 Map<ts行(1-based), ets行(1-based)>;每行取首段映射(同 Python 版)
  const ts2ets = new Map();
  let gl = 0, sl = 0;              // gl=生成行(.ts) 0-based;sl=源码行(.ets) VLQ 累加
  for (const row of mappings.split(';')) {
    for (const seg of row.split(',')) {
      if (!seg) continue;
      const f = vlqDecode(seg);
      if (f.length >= 4) sl += f[2];
      const key = gl + 1;
      if (!ts2ets.has(key)) ts2ets.set(key, sl + 1);
    }
    gl++;
  }
  return ts2ets;
}

function buildSmIndex(sm) {
  // 构建 Map<'src/main/ets/.../*.ts', { ts2ets, etsName }>
  const index = new Map();
  for (const [key, entry] of Object.entries(sm)) {
    if (!entry || typeof entry !== 'object' || !entry.mappings) continue;
    const m = /(src\/main\/ets\/[\w./-]+\.ts)/.exec(key);
    if (!m) continue;
    index.set(m[1], { ts2ets: decodeMappings(entry.mappings), etsName: entry.file || '' });
  }
  return index;
}

// 二分左界(等价 Python bisect.bisect_left)
function bisectLeft(arr, x) {
  let lo = 0, hi = arr.length;
  while (lo < hi) { const mid = (lo + hi) >> 1; if (arr[mid] < x) lo = mid + 1; else hi = mid; }
  return lo;
}

function displayName(name) {
  // 把 xxx.ts#Func(line:N) 还原成 'Func [xxx.ets:源码行号]';无 sourceMap / 无映射则原样或保留 .ts 行号
  if (!smIndex || !smIndex.size) return name;
  const m = /([\w./$@-]+\.ts)#([\w$.]+)\(line:(\d+)\)/.exec(name);
  if (!m) return name;
  const fileInName = m[1], func = m[2], line = parseInt(m[3], 10);
  const pm = /(src\/main\/ets\/[\w./-]+\.ts)/.exec(fileInName);
  if (!pm || !smIndex.has(pm[1])) {
    return `${func} [${fileInName.split('/').pop()}:${line}]`;   // sourceMap 未覆盖
  }
  const { ts2ets, etsName } = smIndex.get(pm[1]);
  if (ts2ets.has(line)) return `${func} [${etsName}:${ts2ets.get(line)}]`;
  const mapped = [...ts2ets.keys()].sort((a, b) => a - b);
  if (mapped.length) {
    const i = bisectLeft(mapped, line);
    const near = i > 0 ? mapped[i - 1] : mapped[0];
    return `${func} [${etsName}:~${ts2ets.get(near)}(编译生成)]`;
  }
  return `${func} [${etsName}:?]`;
}

// ─── 4. 最短引用链:三层取法 ───────────────────────────────────────
// (a) memlab 公开导出
// (b) 沿 node.pathEdge 回溯(= memlab getShortestPath 内部逻辑)
// (c) BFS via forEachReferrer(纯公开 API 兜底)
function chainViaPathEdge(node) {
  const path = [];
  const seen = new Set();
  let cur = node;
  while (cur) {
    if (seen.has(cur.id)) break;          // 防环
    seen.add(cur.id);
    path.push(cur);
    if (!cur.hasPathEdge || !cur.pathEdge || !cur.pathEdge.fromNode) break;
    cur = cur.pathEdge.fromNode;          // pathEdge.fromNode 指向更靠近 root 的节点
  }
  return path;
}

function chainViaBFS(snapshot, node) {
  const prev = new Map();                  // id -> 父节点(更靠近 root)
  const q = [node];
  const seen = new Set([node.id]);
  let root = null;
  while (q.length) {
    const cur = q.shift();
    if (isRoot(cur)) { root = cur; break; }
    let advanced = false;
    const visit = (referrer) => {          // forEachReferrer 回调:可能是 node 或 edge
      const rn = referrer && (referrer.toNode || referrer.fromNode) ? null : referrer; // 粗略兼容
      const target = rn || (referrer && (referrer.toNode || referrer.fromNode));
      if (target && !seen.has(target.id)) { seen.add(target.id); prev.set(target.id, cur); q.push(target); advanced = true; }
    };
    try { if (cur.forEachReferrer) cur.forEachReferrer(visit); } catch {}
    if (!advanced && isRoot(cur)) { root = cur; break; }
  }
  // 回溯
  const path = [];
  let cur = root;
  while (cur) { path.push(cur); if (cur.id === node.id) break; cur = prev.get(cur.id) || null; }
  return path.reverse();                    // node(leaf) → ... → root
}

function getChain(snapshot, node) {
  // (a)
  if (memlabGetShortestPath) {
    try {
      const r = memlabGetShortestPath(node);
      // memlab 返回 [pathNodeIds, pathStrings, distance, rootInfo, pathEntries]
      const [, names, distance, rootInfo, entries] = r;
      const dn = (names || []).map(nm => displayName(nm));
      const de = (entries || []).map(e => ({ nodeId: e?.nodeId, name: displayName((e && e.name) || '(anon)'), retainedSize: e?.retainedSize ?? 0, selfSize: e?.selfSize ?? selfOf(node), distance: e?.distance ?? 0 }));
      const rn = rootInfo?.rootType || names?.[names.length - 1] || '';
      return { names: dn, entries: de, distance, rootName: displayName(rn) };
    } catch {}
  }
  // (b)
  if (node.hasPathEdge !== undefined) {
    const path = chainViaPathEdge(node);
    if (path.length > 1) return pathToResult(path);
  }
  // (c)
  const path = chainViaBFS(snapshot, node);
  return pathToResult(path);
}

function pathToResult(path) {
  const root = path[path.length - 1];
  return {
    names: path.map(n => displayName(n.name || '(anon)')),
    entries: path.map((n, i) => ({ nodeId: n.id, name: displayName(n.name || '(anon)'), retainedSize: retainedOf(n), selfSize: selfOf(n), distance: path.length - 1 - i })),
    distance: path.length - 1,
    rootName: root ? displayName(root.name || '') : '',
  };
}

// mem_size = 一条最短引用链上**所有节点 self_size 的总和**(leaf → GC Root 逐节点累加;
// self_size 不嵌套,可直接相加)。entries 缺 selfSize(memlab 导出路径)时能补多少补多少。
function chainMemSize(chain, node) {
  const ents = chain.entries?.length ? chain.entries : [];
  const sum = ents.reduce((s, e) => s + (e.selfSize || 0), 0);
  return sum > 0 ? sum : selfOf(node);   // 兜底:链上无 selfSize 数据时至少给 leaf 自身
}

// 链签名(聚类键):root→leaf 各节点名去掉 id 等干扰项后拼接。
// 干扰项口径与 compare_diff.py 的 _key_strip 完全一致:
//   (line:N) → 抹、[N] → 抹、:N(如 [File:N] 里的行号)→ 抹;nodeId 不参与签名(天然去除)。
function sigStrip(s) {
  return String(s || '').replace(/\(line:\d+\)/g, '').replace(/\[\d+\]/g, '').replace(/:\d+/g, '').trim() || '(anon)';
}

// item(root→leaf 方向)的链签名
function itemSig(it) {
  const ents = it.chain.entries?.length ? it.chain.entries : [];
  const names = ents.length ? ents.slice().reverse().map(e => e.name)
    : (it.chain.names || []).slice().reverse();
  return names.map(nm => sigStrip(nm)).join(' → ');
}

// 聚类 key(输出到 JSON 的 clusterKey):**去掉当前对象(leaf)** 后的剩余持有路径
// root → … → 直接持有者,逐节点去干扰项(与 compare_diff.py 的持有路径键同口径)。
// 语义:按"谁在持有"标识 —— 同一持有路径下的不同对象共享同一 clusterKey。
// 链长 1(对象直接挂 root)去掉后为空,保留 root 自身避免空 key。
function clusterKeyOf(it) {
  const ents = it.chain.entries?.length ? it.chain.entries : [];
  const names = ents.length ? ents.slice().reverse().map(e => e.name)
    : (it.chain.names || []).slice().reverse();
  const holder = names.length > 1 ? names.slice(0, -1) : names;
  return holder.map(nm => sigStrip(nm)).join(' → ');
}

// ─── 4.5a 引用链聚类(merge 之后对剩余保留链做)──────────────────────────
// 拆成三块:
//   ① groupKeyOf(it)          —— 分组规则函数:链 → 聚类键(想换聚类口径只改这里)
//   ② groupItems(items)       —— 过程1·分组:按键归桶,统计 count/代表/members
//   ③ calcGroupMemSize(items, groups) —— 过程2·算组内 size:节点并集记账(组内去重)
//   clusterBySignature = ②+③ 的编排入口(保持原签名,主流程不动)
//
// clusterMemSize = **节点并集口径**(组内去重):
//   本组所有链覆盖节点的并集 Σself_size。旧口径(逐链 mem_size 求和)会把 root 侧共享前缀
//   (GlobalEnv/SourceTextModule/容器)在同组内反复累加——最短路径是一棵树(每节点唯一父/
//   深度),同类链的公共前缀是同一串祖先,逐链求和虚高可达百倍(实测 29.87MB 堆算出 3038MB)。
//
// 记账规则(每组一个 Set<nodeId> 做组内去重):
//   • 节点在组内首次出现:clusterMemSize += self;
//   • 节点在组内已出现过:跳过(同组两条链撞同一节点只计一次);
//   • 跨组共享节点:在每个用到它的组里都计一次(组间允许重叠)。
// 依赖:chainMemSize 已把 entries[].selfSize 填好(pathToResult 路径);
//      memlab getShortestPath 路径 entries 无 selfSize 时退化为旧口径(逐链求和)。

// ① 分组规则函数:item → 聚类键。当前口径 = 链签名(root→leaf 节点名去干扰项拼接,
// 见 itemSig)。换聚类口径(如按持有路径 clusterKeyOf / 按最近业务对象)只需改这一处,
// groupItems / calcGroupMemSize / 下游折叠逻辑全部自动跟随。
function groupKeyOf(it) {
  return itemSig(it);
}

// 过程1·分组:按 groupKeyOf 把链归桶。每组统计:
//   clusterCount(链数)/ members[](成员链)/ clusterRep(类代表 = 组内 retainedSize 最大者)
//   clusterMemSize 由过程2 填
function groupItems(items) {
  const groups = new Map();                       // 键 → { sig, clusterMemSize, clusterCount, clusterRep, members[] }
  for (const it of items) {
    const sig = groupKeyOf(it);
    let g = groups.get(sig);
    if (!g) {
      g = { sig, clusterMemSize: 0, clusterCount: 0, clusterRep: null, members: [] };
      groups.set(sig, g);
    }
    g.clusterCount += 1;
    g.members.push(it);
    if (!g.clusterRep || retainedOf(it.node) > retainedOf(g.clusterRep.node)) {
      g.clusterRep = it;                          // 类代表 = 组内 retainedSize 最大者
    }
  }
  return groups;
}

// 过程2·计算组内 size:对已分好的 groups 做并集记账,原地写每个 group.clusterMemSize:
//   本组所有链覆盖节点的并集 Σself_size,**跨组共享节点在每个用到它的组里都计一次**
//   (组间允许重叠,回答"该组相关的总内存");仅**组内**去重(同组两条链撞同一节点只计一次)。
//   组内去重由 visited[ gid ](Set<nodeId>)挡;遍历整条链(leaf→root),不早停。
// 返回 { unionOk }:unionOk=false 表示数据不支持并集口径(缺 nodeId),已退回逐链求和。
function calcGroupMemSize(items, groups) {
  const key2gid = new Map();                      // 聚类键 → 顺序整数 id
  const gid2Group = [];                           // gid → group(取类 O(1) 反查)
  for (const g of groups.values()) { key2gid.set(g.sig, gid2Group.length); gid2Group.push(g); }

  // 每组的已计节点集(组内去重);组间故意不去重(共享节点各组都计)
  const gid2Visited = gid2Group.map(() => new Set());

  // 口径可用性:所有链的 entries 都得带 nodeId
  let unionOk = items.length > 0 && items.every((it) =>
    (it.chain.entries || []).length > 0 && (it.chain.entries || []).every((e) => e.nodeId != null));
  for (const it of items) {
    const g = groups.get(groupKeyOf(it));
    const gid = key2gid.get(g.sig);
    const visited = gid2Visited[gid];             // 本组已计节点(组内去重)
    const ents = it.chain.entries || [];
    if (unionOk) {
      // leaf → root 方向(entries[0]=leaf);遍历整条链,组内去重,跨组共享节点每组都计
      for (let i = 0; i < ents.length; i++) {
        const nid = ents[i].nodeId;
        if (nid == null) { unionOk = false; break; }   // 无 nodeId(旧产物)→ 退回逐链求和
        const self = ents[i].selfSize || 0;
        if (!visited.has(nid)) {
          visited.add(nid);
          g.clusterMemSize += self;
        }
      }
    }
    if (!unionOk) {
      // 退化:entries 缺 selfSize/nodeId(memlab 导出路径)→ 逐链求和(无去重)
      const m = it.memSize ?? chainMemSize(it.chain, it.node);
      g.clusterMemSize += m;
    }
  }
  return { unionOk };
}

// 编排入口:分组 → 算组内 size → 建 item→group 反查(条目渲染挂字段用)。
function clusterBySignature(items) {
  const groups = groupItems(items);               // 过程1:分组
  const { unionOk } = calcGroupMemSize(items, groups);   // 过程2:组内 size
  const byItem = new Map();
  for (const it of items) byItem.set(it.idx, groups.get(groupKeyOf(it)));
  return { groups, byItem, unionOk };
}

// ─── 4.5b 子串合并 mergeSimilarPaths(--merge:前缀去重、留叶子,供对比去冗余) ─
// 字典树按 root→leaf **nodeId 序列**建。DFS:某 target 的链是更长链的前缀(子串关系:
// root→…→target 恰为另一条 root→…→deeper 链的前缀)→ 删该前缀 target、深入子节点让最深
// 叶子各自独立输出;target 无后代(叶子)→ 输出该叶子。
// 用途:对比前去冗余(同前缀的中间 dominator 链不重复列出),保留具体叶子对象。
// 每个输出条目带 mergedCount(被吸收的前缀链数)与 merged[](被吸收链,供展开)。
function mergeSimilarPaths(items) {
  if (items.length === 0) return [];
  const idToItem = new Map();
  for (const it of items) idToItem.set(it.node.id, it);
  const root = { nodeId: null, children: new Map(), items: [] };
  for (const it of items) {
    const ents = it.chain.entries?.length ? it.chain.entries : [];
    const seq = ents.slice().reverse().map(e => e.nodeId);     // root(d0) ... leaf
    let cur = root;
    for (const nid of seq) {
      if (nid == null) continue;
      let nx = cur.children.get(nid);
      if (!nx) { nx = { nodeId: nid, children: new Map(), items: [] }; cur.children.set(nid, nx); }
      cur = nx;
    }
    cur.items.push(it);
  }
  // 后序预算:每节点「下方子树」是否有 target(判断前缀 target 有无后代)
  const subHasItem = new Map();
  const calcBelow = (node) => {
    let below = false;
    for (const c of node.children.values()) {
      if (c.items.length > 0) below = true;
      if (calcBelow(c)) below = true;   // 必须递归,给每个子节点都设 subHasItem(不能 || 短路)
    }
    subHasItem.set(node, below);
    return below;
  };
  for (const c of root.children.values()) calcBelow(c);

  const merged = [];
  const used = new Set();
  const absorbed = new Map();                     // 输出条目 idx → 被吸收的前缀链[]
  const dfs = (node, absorbInto) => {
    const target = idToItem.get(node.nodeId);
    if (target) {
      const hasOthers = subHasItem.get(node) || node.items.length > 1;  // 子树里是否有其他引用链
      if (hasOthers) {
        // 前缀 target → 被更深链吸收,记入其吸收列表,继续深入
        if (absorbInto != null && !used.has(target)) absorbed.get(absorbInto).push(target);
        for (const c of node.children.values()) dfs(c, absorbInto);
      } else {
        // 叶子 → 输出(带自身 retained/mem_size;吸收链挂 merged)
        if (!used.has(target)) {
          merged.push(target);
          absorbed.set(target.idx, []);
          used.add(target);
          for (const c of node.children.values()) dfs(c, target.idx);
        }
      }
    } else {
      for (const c of node.children.values()) dfs(c, absorbInto);
    }
  };
  for (const c of root.children.values()) dfs(c, null);
  // 组装输出结构:每条保留链 + 被吸收链计数
  const out = merged.map((t) => {
    const abs = absorbed.get(t.idx) || [];
    return { ...t, merged: [t, ...abs], mergedCount: abs.length,
             count: 1 + abs.length };
  });
  return out.sort((a, b) => retainedOf(b.node) - retainedOf(a.node));
}

// entries → JSON 输出格式:只保留 nodeId/name/retainedSize/distance(内部计算用的 selfSize 不输出)
function cleanEntries(entries) {
  return (entries || []).map(e => ({ nodeId: e.nodeId, name: e.name, retainedSize: e.retainedSize ?? 0, distance: e.distance ?? 0 }));
}

// 渲染单条 / 合并类的代表最短链到 stdout,并返回 jsonOut / md 用对象
function renderEntry(idx, node, chain, totalRetained, extra) {
  const [rk, side] = rootKind(chain.rootName || node.name || '');
  const pct = totalRetained ? (retainedOf(node) / totalRetained * 100).toFixed(1) : '0.0';
  const entries = chain.entries.length ? chain.entries : chain.names.map((nm, i) => ({ name: nm, distance: chain.distance - i, retainedSize: 0 }));
  return { rank: idx + 1, name: displayName(node.name), type: node.type, size: chainMemSize(chain, node),
    rootType: rk, side, rootName: chain.rootName,
    distance: chain.distance, names: chain.names, entries: cleanEntries(chain.entries), extra: extra || '' };
}

// ─── 5. 主流程 ─────────────────────────────────────────────────────
// 加载 sourceMap(可选)——放在所有 helper/const 定义之后,避免 VLQ 常量的 TDZ。
// DevEco 的 sourceMaps.map 顶层是 { 'entry|...|src/main/ets/.../*.ts': {mappings, file, ...} }。
// 解析成 { 'src/main/ets/.../*.ts': { ts2ets: Map<生成行, 源码行>, etsName } },
// 供 displayName 把引用链里的 xxx.ts#Func(line:N) 还原成 .ets 行号。
// 实现与 arkts_top5.py 的 build_sm_index / display_name 完全同口径(VLQ + 首段映射)。
// ⚠️ 用户显式传了 --sourcemap 却读不到/解析失败,属于"明确要求无法满足",直接退出 1——
//    既避免跑完漫长的 memlab 后给出"没还原行号"的报告让人困惑,也省下重算成本。
//    (想不要 sourceMap 就别带这个参数;0 匹配条目这种"文件有效但内容不符"则只警告不退出。)
if (opt.sourcemap) {
  let rawText;
  try {
    rawText = readFileSync(opt.sourcemap, 'utf8');
  } catch (e) {
    console.error('\n[sourceMap] ✗ 读取失败,无法还原行号,已终止。');
    console.error(`    --sourcemap 参数 : ${opt.sourcemap}`);
    console.error(`    解析为绝对路径  : ${path.resolve(opt.sourcemap)}`);
    console.error(`    当前工作目录    : ${process.cwd()}`);
    console.error(`    系统错误        : ${e.code || e.message}`);
    console.error('    → 请给出相对当前目录的正确路径(注意 heapsnapshot 与 sourceMap 常在不同目录)后重试。\n');
    process.exit(1);
  }
  let raw;
  try {
    raw = JSON.parse(rawText);
  } catch (e) {
    console.error(`\n[sourceMap] ✗ 解析失败:${opt.sourcemap} 不是合法 JSON(${e.message}),已终止。\n`);
    process.exit(1);
  }
  smIndex = buildSmIndex(raw);
  if (!smIndex.size) {
    console.error(`[sourceMap] ⚠ ${opt.sourcemap} 已加载,但未识别出任何 src/main/ets/*.ts 条目(将不还原行号)。确认这是 DevEco 生成的 sourceMaps.map。\n`);
  } else {
    console.error(`[sourceMap] 已加载 ${opt.sourcemap}(${smIndex.size} 个 .ts 文件)`);
  }
}

console.error(`[memlab] 加载并预处理 ${opt.file} ...(这一步含 dominator/retained/最短路径计算,大快照需等待)`);
const snapshot = await getFullHeapFromFile(opt.file);

// 收集节点
const all = [];
snapshot.nodes.forEach((n) => all.push(n));

// 过滤 + 排序(排除 id=0 虚拟 GC Root:它 retained 1B 会在 --top 全堆时排进 targets,
//   一旦当合并锚,因所有链 d0 都是 id=0,会 collectSubtree 吞掉全部链 → 塌成一个大簇)
let targets = all.filter((n) => retainedOf(n) > 0 && n.id !== 0);
if (opt.name) targets = targets.filter((n) => opt.name.test(n.name || ''));
if (opt.type) targets = targets.filter((n) => (n.type || '') === opt.type);
targets.sort((a, b) => retainedOf(b) - retainedOf(a));
if (!opt.all) targets = targets.slice(0, opt.top);

// ArkTS 堆内存大小 = 所有节点 selfSize 之和(不嵌套、即真实字节;
// retained 逐对象沿路径嵌套累计,Σretained 天然虚高,不能当堆总量)
const totalSelfSize = all.reduce((s, n) => s + selfOf(n), 0);
// totalRetained 仅留作各条目 retained 百分比的归一分母,不再作为堆合计输出
const totalRetained = all.reduce((s, n) => s + retainedOf(n), 0);
console.log('╔══════════════════════════════════════════════╗');
console.log('║          最短引用链报告 (memlab)             ║');
console.log('╚══════════════════════════════════════════════╝');
console.log(`快照: ${opt.file}`);
console.log(`节点数: ${all.length}  ArkTS 堆内存合计(Σ selfSize): ${fmt(totalSelfSize)}`);
console.log(`输出对象: ${targets.length} 个${opt.all ? '(全部)' : `(Top${opt.top})`}${opt.name ? `  name=~/${opt.name.source}/` : ''}${opt.type ? `  type=${opt.type}` : ''}`);
console.log('━'.repeat(48));

// 先算出每个目标对象的最短链 + mem_size + trace(leaf → root,与 memlab getShortestPath 的 pathStrs 同向)
const items = targets.map((node, idx) => {
  const chain = getChain(snapshot, node);
  const es = chain.entries?.length ? chain.entries : (chain.names || []).map(nm => ({ name: nm }));
  const trace = es.map(e => e.nodeId != null ? `${e.name}[${e.nodeId}]` : `${e.name}`).join(' <- ');
  const memSize = chainMemSize(chain, node);      // 该链上所有节点 self_size 之和
  return { node, chain, idx, trace, memSize };
});

// --merge:子串合并(前缀去重,吸收中间 dominator 链,保留最深叶子);否则逐对象输出
let list = items;
if (opt.merge) {
  list = mergeSimilarPaths(items);
  console.log(`(子串合并:${items.length} 条 → ${list.length} 条保留链,按 retained 降序)`);
}

// 引用链聚类(在 merge 之后的**保留链**上做):按链签名归为一类,组内节点并集 Σself_size
// (跨组共享节点每个用到它的组都计,仅组内去重)。
// 注意:--merge 时被吸收的前缀链不参与聚类(它们是保留链的子串,单列会重复计数)。
const { groups, unionOk } = clusterBySignature(list);
const nClusters = groups.size;
if (unionOk) {
  const sumClusters = [...groups.values()].reduce((s, g) => s + g.clusterMemSize, 0);
  console.log(`(口径:组内节点并集 Σ=${fmt(sumClusters)}(跨组共享节点各组都计,组间重叠))`);
}

// 输出粒度:--merge 时**按聚类结果折叠输出** —— 同签名类的多条保留链合并为一条输出条目
// (代表链 + Σmem_size + count);否则逐链输出(仅附聚类标注字段)。
// 这样 rank 21/22 这类"签名相同、nodeId 不同"的链会真正合成一条,不再各占一行。
let outItems = list;
if (opt.merge) {
  outItems = [...groups.values()]
    .sort((a, b) => b.clusterMemSize - a.clusterMemSize)
    .map((g) => ({ ...g.clusterRep, cluster: g }));
  console.log(`(签名折叠:${list.length} 条保留链 → ${nClusters} 个签名类,按 Σmem_size 降序)\n`);
} else {
  const byItem = new Map();
  for (const g of groups.values()) for (const m of g.members) byItem.set(m.idx, g);
  outItems = list.map((it) => ({ ...it, cluster: byItem.get(it.idx) }));
  console.log(`(引用链聚类:${list.length} 条链 → ${nClusters} 个签名类,逐链输出仅标注)\n`);
}

const jsonOut = [];
outItems.forEach((it, idx) => {
  const g = it.cluster;                           // 该条目所属引用链类(始终存在)
  const extra = opt.merge
    ? (it.mergedCount > 0 ? `(含子串吸收 ${it.mergedCount} 条前缀链) ` : '') +
      (g.clusterCount > 1 ? `(同链聚合 ${g.clusterCount} 条, Σmem_size=${fmt(g.clusterMemSize)})` : '')
    : '';
  const o = renderEntry(idx, it.node, it.chain, totalRetained, extra);
  if (opt.json || opt.md) {
    // 聚类信息(在 merge 后保留链上聚;组内节点并集口径)
    o.clusterKey = (it.chain.names || []).join(' <- ');
    o.count = g.clusterCount;
    if (opt.merge) {
      o.size = g.clusterMemSize;                    // --merge:条目 size = 类内 Σmem_size(与折叠口径一致)
    }
    if (opt.cluster && idx + 1 === opt.cluster) {
      // 展开第 N 个条目所属类的**所有同签名链**(含各自 mem_size),无论是否 --merge
      o.cluster_members = g.members.map(m => ({
        isRep: m.node.id === g.clusterRep.node.id, nodeId: m.node.id, name: displayName(m.node.name), type: m.node.type,
        size: m.memSize,
        distance: m.chain.distance, names: m.chain.names, entries: cleanEntries(m.chain.entries),
      }));
    }
    jsonOut.push(o);
  }
});

if (opt.json) {
  const out = opt.file.replace(/\.heapsnapshot$/i, '') + '.shortest-path.json';
  const ws = createWriteStream(out, { encoding: 'utf-8'});
  ws.write('[\n');
  jsonOut.forEach((item, i) => {
      ws.write(JSON.stringify(item, null, 2));
      if (i < jsonOut.length - 1) ws.write(',\n');
  })
  ws.write('\n]');
  ws.end();
  console.log(`\n📄 JSON 已保存: ${out}`);
}

if (opt.md) {
  const out = opt.file.replace(/\.heapsnapshot$/i, '') + '.shortest-path.md';
  // 流式写出:--all 时条目可达十万级,拼成单个大字符串会超 V8 字符串长度上限
  // 抛 RangeError: Invalid string length,故逐段 ws.write(与 --json 路径同法)
  const ws = createWriteStream(out, { encoding: 'utf-8' });
  ws.write(`# 最短引用链报告 (memlab)\n\n`);
  ws.write(`- 快照: ${opt.file}\n`);
  ws.write(`- 节点数: ${all.length}  ArkTS 堆内存合计(Σ selfSize): ${fmt(totalSelfSize)}\n`);
  ws.write(`- 输出对象: ${targets.length} 个${opt.all ? '(全部)' : `(Top${opt.top})`}${opt.name ? `  name=~/${opt.name.source}/` : ''}${opt.type ? `  type=${opt.type}` : ''}\n\n---\n\n`);
  for (const o of jsonOut) {
    const pct = totalRetained ? (o.size / totalRetained * 100).toFixed(1) : '0.0';
    ws.write(`### [#${o.rank}] ${o.name || '(anon)'} (${o.type})${o.extra ? ' ' + o.extra : ''}\n\n`);
    ws.write(`| size | distance | 根 | 责任侧 |\n|---|---|---|---|\n`);
    ws.write(`| ${fmt(o.size)} (${pct}%) | ${o.distance} | ${o.rootName || '-'} | ${o.rootType}/${o.side} |\n\n`);
    ws.write(`最短引用链 (leaf → GC Root):\n\n\`\`\`\n`);
    const ents = o.entries.length ? o.entries : o.names.map((nm, i) => ({ name: nm, distance: o.distance - i, retainedSize: 0 }));
    ents.forEach((e, j) => {
      const last = j === ents.length - 1;
      const mark = j === 0 ? '⬤' : last ? '└▶' : '├▶';
      const tag = last ? ' (GC Root)' : '';
      ws.write(`${mark} ${e.name} [id=${e.nodeId ?? '-'}] [${fmt(e.retainedSize || 0)}] d${e.distance}${tag}\n`);
    });
    ws.write(`\`\`\`\n\n`);
    ws.write(`- 所属类: ${o.count} 条同签名链\n\n`);
    if (opt.cluster && o.rank === opt.cluster && o.cluster_members && o.cluster_members.length > 0) {
      ws.write(`**该条目所属引用链类(指定 #${opt.cluster} 展开)所有同签名链(共 ${o.cluster_members.length} 条):**\n\n`);
      o.cluster_members.forEach((m, k) => {
        const tag = m.isRep ? '代表' : `成员${k}`;
        ws.write(`#### [${tag}] ${m.name || '(anon)'} [id=${m.nodeId}] size=${fmt(m.size)} dist=${m.distance}\n\n`);
        ws.write(`\`\`\`\n`);
        const me = m.entries?.length ? m.entries : (m.names || []).map((nm, i) => ({ name: nm, distance: m.distance - i, retainedSize: 0 }));
        me.forEach((e, j) => {
          const last = j === me.length - 1;
          const mark = j === 0 ? '⬤' : last ? '└▶' : '├▶';
          const gctag = last ? ' (GC Root)' : '';
          ws.write(`${mark} ${e.name} [id=${e.nodeId ?? '-'}] [${fmt(e.retainedSize || 0)}] d${e.distance}${gctag}\n`);
        });
        ws.write(`\`\`\`\n\n`);
      });
    }
  }
  ws.end();
  console.log(`\n📄 MD 已保存: ${out}`);
}
console.error('\n[完成]');
