#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
resolve-lines.py — 吃 compare_diff.py 的 JSON 输出 + sourceMap,把引用链里的
.ts 编译行号还原成 .ets 源码行号。

用法:
    python3 resolve-lines.py <compare.json> <sourceMaps.map> [--out PATH]
    # compare.json  — compare_diff.py --json 生成(rows.chain 带 .ts 行号)
    # sourceMaps.map — DevEco 生成的 sourceMap(对应"链所来自的那版构建",即 B/当前版本)
    # --out PATH     — 解析后 JSON 落地路径(默认 <compare-stem>.resolved.json)

sourceMap 解析(VLQ + 每行取首段映射)与 shortest-path.mjs --sourcemap **同口径**,
由本脚本完成;大模型不参与 sourceMap 的查找与解析。

输出:
    <stem>.resolved.json —— 结构同 compare.json,但 rows.chain 已还原成 .ets 行号;
                            原始 .ts 链另存为 rows.chain_ts。
                            应用自身模块节点名末尾的 [so] 角标(如 xxx.ts#Func(line:N)[module.hap])会被保留。
    stdout 文本表        —— 按 Δ 降序列出还原后的链,便于人读定位。

注意:sourceMap 必须对应"差异输出里展示的那版构建"。compare 的 rows 展示的是 B(当前/新版)
的链,故这里用 B 版本的 sourceMap;链里若是 A 版独有对象则不在 B 的差异输出中。
"""
import bisect
import json
import os
import re
import sys
from pathlib import Path

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402

_B64 = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789+/'
_B64_IDX = {c: i for i, c in enumerate(_B64)}


def vlq_decode(seg):
    """解码一个 VLQ segment 为整数列表(Source Map V3)。与 shortest-path.mjs vlqDecode 同口径。"""
    vals = []
    i = 0
    while i < len(seg):
        v = 0
        shift = 0
        while True:
            d = _B64_IDX[seg[i]]
            i += 1
            v |= (d & 31) << shift
            shift += 5
            if not (d & 32):
                break
        vals.append(-(v >> 1) if (v & 1) else (v >> 1))
    return vals


def decode_mappings(mappings):
    """解析 mappings → {ts行(1-based): ets行(1-based)},每行取首段映射。"""
    ts2ets = {}
    gl = 0           # 生成行(.ts) 0-based
    sl = 0           # 源码行(.ets) VLQ 累加
    for row in mappings.split(';'):
        for seg in row.split(','):
            if not seg:
                continue
            f = vlq_decode(seg)
            if len(f) >= 4:
                sl += f[2]
            key = gl + 1
            if key not in ts2ets:
                ts2ets[key] = sl + 1
        gl += 1
    return ts2ets


def build_sm_index(sm):
    """构建 { 'src/main/ets/.../*.ts': {ts2ets, etsName} }。"""
    index = {}
    if isinstance(sm, dict):
        items = sm.items()
    elif isinstance(sm, list):
        items = ((e.get('file', ''), e) for e in sm if isinstance(e, dict))
    else:
        return index
    for key, entry in items:
        if not isinstance(entry, dict) or 'mappings' not in entry:
            continue
        m = re.search(r'(src/main/ets/[\w./\-]+\.ts)', str(key))
        ts_path = m.group(1) if m else str(key)
        ets = entry.get('file') or os.path.basename(ts_path).replace('.ts', '.ets')
        index[ts_path] = {'ts2ets': decode_mappings(entry['mappings']), 'etsName': ets}
    return index


def display_name(name, index, stats):
    """把 xxx.ts#Func(line:N) 还原成 'Func [xxx.ets:源码行号]';无 map/无映射则保留 .ts 行号。
    应用自身模块节点名末尾的 [so] 角标(compare_diff.py annotate_node_so 添加)会被保留——
    先剥离再解析,解析结果后重新追加,确保 [so] 信息不丢失。"""
    so_tag = ''
    m_so = re.search(r'(\[[^\[\]]*\.(?:so|hap)\])$', name)
    if m_so:
        so_tag = m_so.group(1)
        name = name[:m_so.start()].strip()
    m = re.search(r'([\w./$@\-]+\.ts)#([\w$.]+)\(line:(\d+)\)', name)
    if not m:
        return name + so_tag
    file_in, func, line = m.group(1), m.group(2), int(m.group(3))
    pm = re.search(r'(src/main/ets/[\w./\-]+\.ts)', file_in)
    ts_path = pm.group(1) if pm else None
    if not ts_path or ts_path not in index:
        stats['uncovered'] += 1
        return f"{func} [{os.path.basename(file_in)}:{line}]{so_tag}"   # sourceMap 未覆盖,保留 .ts 行
    stats['covered'] += 1
    ts2ets = index[ts_path]['ts2ets']
    ets = index[ts_path]['etsName']
    if line in ts2ets:
        return f"{func} [{ets}:{ts2ets[line]}]{so_tag}"
    mapped = sorted(ts2ets)
    if mapped:
        i = bisect.bisect_left(mapped, line)
        near = mapped[i - 1] if i > 0 else mapped[0]
        return f"{func} [{ets}:~{ts2ets[near]}(编译生成)]{so_tag}"
    return f"{func} [{os.path.basename(file_in)}:{line}]{so_tag}"


def resolve_chain(chain, index, stats):
    return ' → '.join(display_name(n, index, stats) for n in chain.split(' → '))


def main():
    argv = sys.argv[1:]
    if not argv or '-h' in argv or '--help' in argv:
        print(__doc__)
        sys.exit(0 if argv else 1)
    out = None
    pos = []
    i = 0
    while i < len(argv):
        t = argv[i]
        if t == '--out':
            if i + 1 >= len(argv):
                print('错误:--out 需指定路径'); sys.exit(1)
            out = argv[i + 1]; i += 2
        elif t.startswith('--out='):
            out = t[len('--out='):]; i += 1
        else:
            pos.append(t); i += 1
    if len(pos) < 2:
        print(__doc__); sys.exit(1)
    cmp_path, sm_path = pos[0], pos[1]

    try:
        cmp = json.load(open(cmp_path, encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as e:
        sys.exit(f'错误:无法解析 compare JSON {cmp_path}({e})')
    try:
        sm = json.load(open(sm_path, encoding='utf-8'))
    except (OSError, json.JSONDecodeError) as e:
        sys.exit(f'错误:无法解析 sourceMap {sm_path}({e})')

    index = build_sm_index(sm)
    if not index:
        sys.exit(f'错误:{sm_path} 未识别出 src/main/ets/*.ts 条目,确认是 DevEco 生成的 sourceMaps.map')
    sys.stderr.write(f'[sourceMap] 已加载 {sm_path}({len(index)} 个 .ts 文件)\n')

    stats = {'covered': 0, 'uncovered': 0}
    resolved = {k: cmp[k] for k in ('a', 'b', 'threshold_kb', 'summary', 'side_dist') if k in cmp}
    resolved_rows = []
    for r in cmp.get('rows', []):
        rr = dict(r)
        rr['chain_ts'] = r.get('chain', '')
        rr['chain'] = resolve_chain(r.get('chain', ''), index, stats)
        resolved_rows.append(rr)
    resolved['rows'] = resolved_rows

    if out is None:
        d = os.path.dirname(cmp_path)
        stem = os.path.basename(cmp_path)
        stem = stem.rsplit('.', 1)[0] if '.' in stem else stem
        out = os.path.join(d, stem + '.resolved.json') if d else (stem + '.resolved.json')
    with open(out, 'w', encoding='utf-8') as f:
        json.dump(resolved, f, ensure_ascii=False, indent=2)

    tot = stats['covered'] + stats['uncovered']
    cov = f"{stats['covered']}/{tot}" if tot else '0/0'
    print(f"📄 已解析行号 → {out}   (sourceMap 覆盖 {cov} 个带行号节点)")
    print()
    for r in resolved_rows:
        print(f"  {r.get('delta_kb', 0):>6.2f}KB  {r.get('tag', ''):<5}  {r.get('seq', ''):<10}  {r['chain']}")


if __name__ == '__main__':
    main()
