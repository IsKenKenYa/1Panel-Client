#!/usr/bin/env python3
"""分析差分树: 输出 root 信息 + Top N 劣化叶子完整调用链 (临时辅助脚本, 不改动被保护脚本)"""
import json
import sys


def collect_leaves(node):
    leaves = []
    if node.get('is_leaf'):
        leaves.append(node)
    for ch in node.get('children', []):
        leaves.extend(collect_leaves(ch))
    return leaves


def find_leaf_path(tree, target_cid):
    def _walk(node, path):
        current = path + [node]
        if node.get('is_leaf') and node.get('callchain_id') == target_cid:
            return current
        for ch in node.get('children', []):
            r = _walk(ch, current)
            if r:
                return r
        return None
    return _walk(tree, [])


def main():
    so_name = sys.argv[1]
    top_n = int(sys.argv[2]) if len(sys.argv) > 2 else 5
    with open(f'output/next_hongguo_old/{so_name}_diff.json') as f:
        diff = json.load(f)

    leaves = collect_leaves(diff)
    leaves.sort(key=lambda x: -x['delta_mb'])
    degraded = [l for l in leaves if l['delta_mb'] > 0]

    print(f'=== {so_name} ===')
    print(f'root delta_mb: {diff["delta_mb"]}, a_value_mb: {diff["a_value_mb"]}, '
          f'b_value_mb: {diff["b_value_mb"]}, match_type: {diff["match_type"]}')
    print(f'Total leaves: {len(leaves)}, degraded: {len(degraded)}')
    print()

    for leaf in degraded[:top_n]:
        cid = leaf.get('callchain_id')
        path = find_leaf_path(diff, cid)
        print(f'--- Leaf callchain_id={cid}, delta_mb={leaf["delta_mb"]}, '
              f'b_value_mb={leaf["b_value_mb"]}, a_value_mb={leaf["a_value_mb"]}, '
              f'match_type={leaf["match_type"]} ---')
        if path:
            frames = path[1:]
            for f in frames:
                print(f'  {f.get("name", "?")}')
        print()


if __name__ == '__main__':
    main()
