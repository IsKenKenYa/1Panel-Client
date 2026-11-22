"""
聚类树差分：对同一 SO 的两个版本聚类树做节点级差分，输出差分聚类树

用法:
    python diff_cluster_tree.py --tree-a <A版_tree.json> --tree-b <B版_tree.json> [--top 20] [--output <diff.json>]

输入:
    两个聚类树 JSON（由 cluster_calltree.py 生成）

输出:
    差分聚类树 JSON，结构与输入聚类树一致，每个节点额外增加:
      - a_value_mb: A 版本该节点的内存
      - b_value_mb: B 版本该节点的内存
      - delta_mb: 增量（正=劣化，负=改善）
    children 按 delta_mb 降序排列，第一条分支就是最劣化的。
    Top N 控制终端摘要打印的劣化叶子数量，不影响差分树输出（差分树始终完整输出）。
"""

import json
import re
import argparse
import sys
from pathlib import Path

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402

# ArkTS JS 帧格式: func_name:[url:<scope>|<package>|<version>|<file>:<line>:<col>]
# ohpm 包升级时只有 <version> 字段变化；scope、package 是稳定标识符
# （rule.py 的 THIRD_ARKTS_FRAGMENT 列表 + get_so_of_frame 均依赖包名稳定）。
# 此正则须与 scripts/2_analysis/rule.py 的 TS_PATTERN 保持一致。
_ARKTS_FRAME_RE = re.compile(
    r'^(?P<func>[^:]+):\[url:'
    r'(?P<scope>[^:|]+)\|'
    r'(?P<package>[^|]+)\|'
    r'(?P<version>[^:|]+)\|'
    r'(?P<file>[^|\]]*):(?P<line>\d+):(?P<col>\d+)]:?$'
)


def _diff_key(name):
    """跨版本帧名匹配键：剥离 ArkTS JS 帧 URL 中的 version 字段。

    仅用于 diff 匹配——tree.json / 火焰图保留原始完整帧名（含版本号）。
    只剥离第 3 个 | 字段（version），保留 scope|package 做消歧。
    非 ArkTS 帧（native C/C++、未符号化、运行时内建）不匹配此格式，
    原样返回，走精确匹配（与改动前行为一致）。
    """
    m = _ARKTS_FRAME_RE.match(name)
    if not m:
        return name
    return (f"{m['func']}:[url:{m['scope']}|{m['package']}|"
            f"{m['file']}:{m['line']}:{m['col']}]")


def _mb(val):
    return round(val / 1048576, 2)


def diff_trees(tree_a, tree_b):
    """对两棵聚类树做节点级差分，返回差分树"""
    name_a = tree_a['name'] if tree_a else None
    name_b = tree_b['name'] if tree_b else None

    val_a = tree_a['value'] if tree_a else 0
    val_b = tree_b['value'] if tree_b else 0
    delta = val_b - val_a

    active = tree_b or tree_a

    # Determine match type
    if tree_a and tree_b:
        match_type = 'both'
    elif tree_b:
        match_type = 'only_b'
    else:
        match_type = 'only_a'

    result = {
        'name': name_b or name_a,
        'a_value_mb': _mb(val_a),
        'b_value_mb': _mb(val_b),
        'delta_mb': _mb(delta),
        'match_type': match_type,
    }

    if active.get('is_leaf'):
        result['is_leaf'] = True
        if active.get('callchain_id') is not None:
            result['callchain_id'] = active['callchain_id']
        # A 版叶子也存在时，保留 A 版 callchain_id 供下游对比
        if tree_a and tree_a.get('is_leaf') and tree_a.get('callchain_id') is not None:
            result['callchain_id_a'] = tree_a['callchain_id']

    # 匹配子节点
    children_a = {}
    children_b = {}
    if tree_a and tree_a.get('children'):
        for ch in tree_a['children']:
            children_a[_diff_key(ch['name'])] = ch
    if tree_b and tree_b.get('children'):
        for ch in tree_b['children']:
            children_b[_diff_key(ch['name'])] = ch

    # 分离叶子节点和非叶子节点
    # 叶子节点 name 格式为 meta:<callchain_id>，跨版本 callchain_id 不一致
    # 当父节点为 both 时，叶子按路径位置匹配（同一路径下的叶子是同一调用链）
    leaf_a = {}
    leaf_b = {}
    nonleaf_a = {}
    nonleaf_b = {}
    for name, ch in children_a.items():
        if name.startswith('meta:'):
            leaf_a[name] = ch
        else:
            nonleaf_a[name] = ch
    for name, ch in children_b.items():
        if name.startswith('meta:'):
            leaf_b[name] = ch
        else:
            nonleaf_b[name] = ch

    child_results = []

    # 非叶子节点：按 name 匹配（当前逻辑，正常工作）
    all_nonleaf_names = list(dict.fromkeys(list(nonleaf_a.keys()) + list(nonleaf_b.keys())))
    for ch_name in all_nonleaf_names:
        ch_a = nonleaf_a.get(ch_name)
        ch_b = nonleaf_b.get(ch_name)
        if ch_a or ch_b:
            child_results.append(diff_trees(ch_a, ch_b))

    # 叶子节点：按路径位置匹配
    # 当父节点 both 时，A/B 各最多一个叶子（同一调用链），合并 a/b 值
    # 当父节点 only_b 时，B 的叶子为新增
    # 当父节点 only_a 时，A 的叶子为消失
    if tree_a and tree_b:
        # both: 合并 A/B 叶子（按位置配对，实际每侧至多 1 个叶子）
        a_leaves = list(leaf_a.values())
        b_leaves = list(leaf_b.values())
        for i in range(max(len(a_leaves), len(b_leaves))):
            la = a_leaves[i] if i < len(a_leaves) else None
            lb = b_leaves[i] if i < len(b_leaves) else None
            if la or lb:
                child_results.append(diff_trees(la, lb))
    elif tree_b:
        # only_b: B 的叶子为新增
        for leaf_name, leaf_b_node in leaf_b.items():
            child_results.append(diff_trees(None, leaf_b_node))
    elif tree_a:
        # only_a: A 的叶子为消失
        for leaf_name, leaf_a_node in leaf_a.items():
            child_results.append(diff_trees(leaf_a_node, None))

    if child_results:
        # 按 delta_mb 降序排列
        child_results.sort(key=lambda c: -c['delta_mb'])
        result['children'] = child_results

    return result


def _collect_leaves(node):
    """收集所有叶子节点的 (delta_mb, callchain_id)"""
    leaves = []
    if node.get('is_leaf') and node.get('callchain_id') is not None:
        leaves.append((node['delta_mb'], node['callchain_id']))
    for ch in node.get('children', []):
        leaves.extend(_collect_leaves(ch))
    return leaves


def main():
    parser = argparse.ArgumentParser(description='聚类树差分：对两个版本聚类树做节点级差分')
    parser.add_argument('--tree-a', required=True, help='A 版本聚类树 JSON')
    parser.add_argument('--tree-b', required=True, help='B 版本聚类树 JSON')
    parser.add_argument('--top', type=int, default=20, help='终端摘要打印 Top N 劣化叶子（默认 20）')
    parser.add_argument('--output', default='', help='输出文件路径（默认 A 版同级目录下 <so_name>_diff.json）')
    args = parser.parse_args()

    path_a = Path(args.tree_a)
    path_b = Path(args.tree_b)
    for label, p in [('A', path_a), ('B', path_b)]:
        if not p.exists():
            print(f'错误: {label} 版本聚类树不存在: {p}')
            return

    data_a = json.loads(path_a.read_text(encoding='utf-8'))
    data_b = json.loads(path_b.read_text(encoding='utf-8'))

    diff_tree = diff_trees(data_a['tree'], data_b['tree'])

    # 输出路径
    if args.output:
        out_path = Path(args.output)
    else:
        # 从输入文件名推导 SO 名：libtaskpool.z.so_tree.json -> libtaskpool.z.so
        stem = path_b.stem  # e.g. libtaskpool.z.so_tree
        so_name = stem.rsplit('_tree', 1)[0] if stem.endswith('_tree') else stem
        out_path = path_a.parent / f'{so_name}_diff.json'
    out_path.parent.mkdir(parents=True, exist_ok=True)

    out_path.write_text(
        json.dumps(diff_tree, indent=2, ensure_ascii=False),
        encoding='utf-8')

    # 从完整差分树中筛出 Top N 叶子节点摘要
    all_leaves = _collect_leaves(diff_tree)
    all_leaves.sort(key=lambda x: -x[0])
    degraded = [d for d in all_leaves if d[0] > 0]

    print(f'差分完成: {len(all_leaves)} 个叶子, {len(degraded)} 个劣化')
    print(f'Top {min(args.top, len(all_leaves))} 叶子节点:')
    print(f'  {"delta(MB)":>11}  callchain_id')
    print('  ' + '-' * 40)
    for delta, cid in all_leaves[:args.top]:
        print(f'  {delta:>+10.2f}  {cid}')
    print(f'\n差分树已保存到: {out_path}')


if __name__ == '__main__':
    main()
