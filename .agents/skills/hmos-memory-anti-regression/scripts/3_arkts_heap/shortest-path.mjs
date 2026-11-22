#!/usr/bin/env node
/**
 * shortest-path.mjs — 通过 memlab 获取堆对象 → GC Root 的最短引用链
 *
 * 依赖:  npm i @memlab/heap-analysis
 * 用法:
 *   node shortest-path.mjs <heap.heapsnapshot> [选项]
 *
 * 选项:
 *   --top <N>      按 retainedSize 取 Top N 个对象(默认 10)
 *   --name <regex> 只输出名称匹配该正则的对象
 *   --type <t>     只输出指定 type 的对象(如 object / hidden / closure)
 *   --all          对所有 retainedSize>0 的可达对象输出(量大,慎用)
 *   --json         额外把结果写到 <snapshot>.shortest-path.json
 *   --md           额外把可读报告写到 <snapshot>.shortest-path.md(markdown 格式)
 *   --merge        对输出的最短链做前缀去重(mergeSimilarPaths):被更长链覆盖的前缀 target 不输出,
 *                  保留最深叶子(带其自身 retained)。用于**对比前去冗余**(A、B 都带),count 不累加
 *   --aggregate    对输出的最短链按路径字符串聚类(clusterByShortestPath):最短引用链(归一化:
 *                  抹行号/版本)相同的对象归为一簇,retainedSize/selfSize 求和、count 累加,
 *                  clusterKey 写入 JSON 供 compare_diff.py 直接 join(不再在 compare_diff.py 里聚类)。
 *                  可与 --merge 叠加(--merge 去父子冗余 → --aggregate 按路径字符串聚类)
 *   --cluster <N>  配合 --merge/--aggregate:只展开第 N 个簇(1-based),输出该簇所有被合并/聚类
 *                  对象的最短链,其它簇只保留代表链(写入 --md / --json)
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
  const o = { top: 10, name: null, type: null, all: false, json: false, md: false, merge: false, aggregate: false, cluster: 0, sourcemap: null, file: null };
  for (let i = 0; i < argv.length; i++) {
    const t = argv[i];
    if (t === '--top') o.top = parseInt(argv[++i], 10) || 10;
    else if (t === '--name') o.name = new RegExp(argv[++i]);
    else if (t === '--type') o.type = argv[++i];
    else if (t === '--all') o.all = true;
    else if (t === '--json') o.json = true;
    else if (t === '--md') o.md = true;
    else if (t === '--merge') o.merge = true;
    else if (t === '--aggregate') o.aggregate = true;
    else if (t === '--cluster') o.cluster = parseInt(argv[++i], 10) || 0;
    else if (t === '--sourcemap') o.sourcemap = argv[++i];
    else if (!t.startsWith('-') && !o.file) o.file = t;
  }
  return o;
}

const opt = parseArgs(process.argv.slice(2));
if (!opt.file) {
  console.error('用法: node shortest-path.mjs <heap.heapsnapshot> [--top N] [--name regex] [--type t] [--all] [--merge] [--aggregate] [--cluster N] [--sourcemap map] [--json] [--md]');
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
      const de = (entries || []).map(e => ({ nodeId: e?.nodeId, name: displayName((e && e.name) || '(anon)'), retainedSize: e?.retainedSize ?? 0, distance: e?.distance ?? 0 }));
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
    entries: path.map((n, i) => ({ nodeId: n.id, name: displayName(n.name || '(anon)'), retainedSize: retainedOf(n), distance: path.length - 1 - i })),
    distance: path.length - 1,
    rootName: root ? displayName(root.name || '') : '',
  };
}

// ─── 4.5 链合并 mergeSimilarPaths(前缀去重、留叶子,供对比去冗余) ─
// 字典树按 root→leaf nodeId 序列建。DFS:某 target 被更长链覆盖(子树里有其他 target)→ 删该前缀
// target、深入子节点让最深叶子各自独立输出;target 无后代(叶子)→ 输出该叶子(带其自身 retained)。
// 用途:对比前去冗余(同前缀的中间 dominator 链不重复列出),保留具体叶子对象;count 不累加。
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
    const below = node.children.size > 0;   // 布尔结果直接定
    for (const c of node.children.values()) {
        calcBelow(c);                       // 仍须递归(副作用:标后代节点)
    }
    subHasItem.set(node, below);
    return below;
  };
  for (const c of root.children.values()) calcBelow(c);

  const merged = [];
  const used = new Set();
  const dfs = (node) => {
    const target = idToItem.get(node.nodeId);
    if (target) {
      const hasOthers = subHasItem.get(node) || node.items.length > 1;  // 子树里是否有其他引用链
      if (hasOthers) {
        // 被更长链覆盖 → 删该前缀 target,深入子节点让最深叶子各自输出
        for (const c of node.children.values()) dfs(c);
      } else {
        // 叶子 → 输出(retained 用叶子自身;A/B 同口径,Δ 仍有效)
        if (!used.has(target)) {
          merged.push({ node: target.node, chain: target.chain, idx: target.idx, trace: target.trace,
            count: 1, merged: [target], mergedCount: 0 });
          used.add(target);
        }
      }
    } else {
      for (const c of node.children.values()) dfs(c);
    }
  };
  for (const c of root.children.values()) dfs(c);
  return merged.sort((a, b) => retainedOf(b.node) - retainedOf(a.node));
}

// ─── 4.6 最短引用链聚类(按路径字符串分组,参考 meminsight aggregateSpecificObjectNameByReference)──
// 将最短引用链完全相同的对象归为一簇:names(leaf→root,原始节点名)join(' <- ')作为 clusterKey,
// 同 key 的对象 retainedSize/selfSize 求和、count 累加。与 meminsight 完全同口径——不做任何
// 归一化(不抹行号/版本/索引),保证簇划分和 retainedSize 求和结果与 meminsight 一致。
// 用途:对比前聚类——clusterKey 供 compare_diff.py 直接 join(不再在 compare_diff.py 里聚类)。
// 与 --merge 的区别:--merge 去的是"父子包含"的冗余链(dominator 树前缀去重,保留最深叶子);
// --aggregate 聚的是"路径相同"的多个对象(字符串等价,retained 求和),二者可叠加(--merge → --aggregate)。
function clusterByShortestPath(items) {
  if (items.length === 0) return [];
  const clusters = new Map();
  for (const it of items) {
    const names = it.chain.names?.length ? it.chain.names : (it.chain.entries || []).map(e => e.name || '(anon)');
    // clusterKey = 原始完整最短引用链(leaf→root, 不做归一化),与 meminsight getShortestPath 同口径
    const key = names.join(' <- ');
    let c = clusters.get(key);
    if (!c) {
      c = { clusterKey: key, count: 0, retainedSize: 0, selfSize: 0, representative: it, items: [] };
      clusters.set(key, c);
    }
    c.count += 1;
    c.retainedSize += retainedOf(it.node);
    c.selfSize += selfOf(it.node);
    c.items.push(it);
  }
  return [...clusters.values()].sort((a, b) => b.retainedSize - a.retainedSize);
}

// 渲染单条 / 合并簇的代表最短链到 stdout,并返回 jsonOut / md 用对象
function renderEntry(idx, node, chain, totalRetained, extra) {
  const [rk, side] = rootKind(chain.rootName || node.name || '');
  const pct = totalRetained ? (retainedOf(node) / totalRetained * 100).toFixed(1) : '0.0';
//   console.log(extra
//     ? `\n[#${idx + 1}] ${node.name || '(anon)'}  <${node.type}>  ${extra}`
//     : `\n[#${idx + 1}] ${node.name || '(anon)'}  <${node.type}>`);
//   console.log(`     retained: ${fmt(retainedOf(node))} (${pct}%)   self: ${fmt(selfOf(node))}   distance: ${chain.distance}   根: ${chain.rootName} [${rk}/${side}]`);
//   console.log('     最短引用链 (leaf → GC Root):');
  const entries = chain.entries.length ? chain.entries : chain.names.map((nm, i) => ({ name: nm, distance: chain.distance - i, retainedSize: 0 }));
  entries.forEach((e, j) => {
    const last = j === entries.length - 1;
    const mark = j === 0 ? '⬤' : last ? '└▶' : '├▶';
    const tag = last ? ' (GC Root)' : '';
//     console.log(`       ${mark} ${e.name} [id=${e.nodeId ?? '-'}] [${fmt(e.retainedSize || 0)}] d${e.distance}${tag}`);
  });
  return { rank: idx + 1, name: displayName(node.name), type: node.type, size: retainedOf(node),
    rootType: rk, side, rootName: chain.rootName,
    distance: chain.distance, names: chain.names, entries: chain.entries, extra: extra || '' };
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

// 先算出每个目标对象的最短链 + trace(leaf → root,与 memlab getShortestPath 的 pathStrs 同向)
const items = targets.map((node, idx) => {
  const chain = getChain(snapshot, node);
//   console.log('zhangzihang1', chain);
  const es = chain.entries?.length ? chain.entries : (chain.names || []).map(nm => ({ name: nm }));
  const trace = es.map(e => e.nodeId != null ? `${e.name}[${e.nodeId}]` : `${e.name}`).join(' <- ');
  return { node, chain, idx, trace };
});

// --merge:父子链合并(mergeSimilarPaths);否则逐对象输出
let list = items;
if (opt.merge) {
  list = mergeSimilarPaths(items);
  console.log(`(父子链合并:${items.length} 条 → ${list.length} 簇)\n`);
}

// --aggregate:按最短引用链聚类(clusterByShortestPath);归一化后路径相同的对象归为一簇,
// retainedSize/selfSize 求和、count 累加,clusterKey 写入 JSON 供 compare_diff.py 直接 join
if (opt.aggregate) {
  const clusters = clusterByShortestPath(list);
  console.log(`(按最短引用链聚类:${list.length} 条 → ${clusters.length} 簇)\n`);
  list = clusters.map((c, idx) => ({
    node: c.representative.node,
    chain: c.representative.chain,
    idx,
    trace: c.representative.trace,
    _cluster: c,
  }));
}

const jsonOut = [];
list.forEach((it, idx) => {
  let extra = '';
  if (it._cluster) {
    extra = `(聚类 ${it._cluster.count} 对象, Σretained ${fmt(it._cluster.retainedSize)})`;
  } else if (opt.merge && it.mergedCount > 0) {
    extra = `(合并 ${it.mergedCount} 条父子链, 共 ${it.count} 对象)`;
  }
  const o = renderEntry(idx, it.node, it.chain, totalRetained, extra);
  if (it._cluster) {
    // 聚类:override size 为簇内求和,加 clusterKey/count 供 compare_diff.py join
    o.size = it._cluster.retainedSize;
    o.count = it._cluster.count;
    o.clusterKey = it._cluster.clusterKey;
  }
  if (opt.json || opt.md) {
    if (it._cluster) {
      if (opt.cluster && idx + 1 === opt.cluster) {
        o.merged = it._cluster.items.map(m => ({
          isRep: m.node.id === it.node.id, nodeId: m.node.id, name: displayName(m.node.name), type: m.node.type,
          size: retainedOf(m.node),
          distance: m.chain.distance, names: m.chain.names, entries: m.chain.entries,
        }));
      }
    } else if (opt.merge) {
      o.count = it.count;
      if (opt.cluster && idx + 1 === opt.cluster) {
        // 只展开指定簇(第 opt.cluster 个):输出该簇所有被合并对象的最短链(父子链),含代表
        o.merged = it.merged.map(m => ({
          isRep: m.node.id === it.node.id, nodeId: m.node.id, name: displayName(m.node.name), type: m.node.type,
          size: retainedOf(m.node),
          distance: m.chain.distance, names: m.chain.names, entries: m.chain.entries,
        }));
      }
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
    if (opt.cluster && o.rank === opt.cluster && o.merged && o.merged.length > 1) {
      ws.write(`**该簇(指定 #${opt.cluster} 展开)所有链(共 ${o.merged.length} 条,含代表):**\n\n`);
      o.merged.forEach((m, k) => {
        const tag = m.isRep ? '代表' : `父子链${k}`;
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
