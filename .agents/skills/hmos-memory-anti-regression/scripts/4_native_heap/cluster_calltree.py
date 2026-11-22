"""
调用栈聚类：对指定 SO 或帧名关键字生成前缀树聚类树（JSON）

用法:
    python cluster_calltree.py --db <版本.db> --so <so_name> [--output <path>]
    python cluster_calltree.py --db <版本.db> --frame <substr[,substr2...]> --label <name> [--output <path>]

功能:
    1. 从 SQLite db 查询所有调用栈及其帧
    2. 筛选：--so 按帧所属 SO 名匹配（file_data/symbol_data 含 so_name）；
       --frame 按帧名子串匹配（symbol_data 含任一关键字即命中，适合 DMA 型 SO
       如 libbuffer_handle.z.so —— 其 DMA 内存不经 malloc，但 SurfaceBuffer
       读取/请求路径的调用栈存在于 native_hook 表中，按帧名聚类可还原路径）
    3. 对筛选后的调用栈做前缀树聚类
    4. 输出 JSON 格式的聚类树

输出:
    <so_name 或 label>_tree.json — 聚类树（含 string_table + tree）
    （下游 diff_cluster_tree.py / build_flame_summary.py 按文件名衔接，--label
     建议传 SO 名以保持命名一致；--frame 聚类的口径是"调用路径归因辅助"，
     树上的 value 是栈上 malloc 存活分配量，不代表 DMA 内存量本身，
     产物不得并入 native heap 统计，报告挂在 DMA 归因小节）
"""

import json
import re
import sqlite3
import argparse
import sys
from pathlib import Path
from collections import OrderedDict

# Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402

HOOK_SO_DEFAULT = ['libnative_hook']

# hook 机制注入的帧（非原始调用路径的一部分），始终排除
HOOK_NOISE_PATTERNS = [
    'libnative_hook.z.so',
]

# 基础设施库（真实调用路径的组成部分），不排除
# 排除这些帧会导致仅在这些库上不同的调用栈被错误合并，丢失聚类信息
# 保留列表供未来可选的 --exclude-infra 参数使用
INFRA_SO_PATTERNS = [
    'libuv.so',
    'libc++.so',
    'libc++_shared.so',
    'ld-musl-aarch64.so.1',
    'libc.so',
    'libm.so',
    'libdl.so',
    'libpthread.so',
]


def _is_excluded_so(so_name):
    """仅排除 hook 机制注入的噪声帧，不排除基础设施库的真实调用路径帧"""
    if not so_name:
        return True
    return any(p in so_name for p in HOOK_NOISE_PATTERNS)


def normalize_symbol(name):
    """Strip /proc/<PID>/root/ prefix so app-bundle SO names match across captures."""
    if not name:
        return name
    return re.sub(r'^/proc/\d+/root/', '', name)


# ── 从 DB 查询调用栈 + 帧 ─────────────────────────────────────
#
# DB 中的核心表（trace_streamer 转换 htrace 时生成，一定存在）：
#   native_hook          — 每条 AllocEvent/FreeEvent 的原始记录（addr, heap_size, callchain_id 等）
#   native_hook_frame    — 每条调用栈的帧序列（callchain_id, depth, symbol_id, file_id）
#   data_dict            — 字符串映射表（id → 函数名/文件路径），symbol_id/file_id 指向此表
#
# 可能存在的表（不一定有，取决于 trace_streamer 版本和前置流程）：
#   native_hook_statistic — 按 callchain_id 预聚合的统计表（apply_size, release_size 等）
#   native_hook_agg       — 帧聚合中间表（native_hook 库的统计流程生成，列名 result_json）
#
# 本函数的逻辑：
#   1. 确定帧聚合中间表（native_hook_agg / _cc_agg，都没有则现场构建 _cc_agg）
#   2. 判断用统计模式还是明细模式查存活内存
#   3. 通过 data_dict 将 symbol_id/file_id 还原为可读字符串
#   4. 只保留存活内存 > 0 的调用栈（已完全释放的不参与聚类）

def query_callchains(db_path):
    """查询 DB 中所有存活调用栈，返回 [{callchain_id, heap_size, frames, ...}]"""
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 帧聚合中间表：将 native_hook_frame 按 callchain_id 聚合成 JSON 数组
    # 优先复用已有的 native_hook_agg（列名 result_json），其次复用 _cc_agg（列名 frames_json）
    # 都没有则现场构建 _cc_agg（首次运行耗时较长，后续复用）
    agg_table = None
    agg_col = None
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='native_hook_agg'")
    if cur.fetchone():
        agg_table = 'native_hook_agg'
        agg_col = 'result_json'
    else:
        cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='_cc_agg'")
        if cur.fetchone():
            agg_table = '_cc_agg'
            agg_col = 'frames_json'
    if agg_table is None:
        print('  构建帧聚合中间表（首次运行，耗时较长）...')
        cur.execute('''
            CREATE TABLE _cc_agg AS
            SELECT nhf.callchain_id,
                json_group_array(
                    json_object('depth', nhf.depth, 'symbol_id', nhf.symbol_id, 'file_id', nhf.file_id)
                ) AS frames_json
            FROM native_hook_frame nhf
            WHERE nhf.callchain_id > 0
            GROUP BY nhf.callchain_id
        ''')
        cur.execute("CREATE INDEX idx_cc_agg ON _cc_agg(callchain_id)")
        agg_table = '_cc_agg'
        agg_col = 'frames_json'
        print('  帧聚合中间表构建完成')

    # 统计模式 vs 明细模式：
    #   有 native_hook_statistic 且有数据 → 统计模式（直接查聚合表，快）
    #   否则 → 明细模式（从 native_hook 自行 GROUP BY 计算 heap_size，慢但结果等价）
    cur.execute("SELECT name FROM sqlite_master WHERE type='table' AND name='native_hook_statistic'")
    has_statistic = False
    if cur.fetchone():
        cur.execute("SELECT count(*) FROM native_hook_statistic")
        has_statistic = cur.fetchone()[0] > 0

    if has_statistic:
        cur.execute(f'''
            SELECT nh.callchain_id,
                   MAX(nh.apply_size) - MAX(nh.release_size) AS heap_size,
                   MAX(nh.apply_count) AS apply_count,
                   MAX(nh.release_count) AS release_count,
                   agg.{agg_col}
            FROM native_hook_statistic nh
            LEFT JOIN {agg_table} agg ON nh.callchain_id = agg.callchain_id
            WHERE nh.type = 0
            GROUP BY nh.callchain_id
            HAVING heap_size > 0
        ''')
    else:
        # 明细模式：trace_streamer 已在 htrace→SQLite 转换时完成 alloc/free 配对，
        # AllocEvent 的 end_ts 字段记录释放时刻（未释放则为 NULL）。
        # 直接用 end_ts IS NULL 筛选存活分配，按 callchain_id 聚合。
        cur.execute(f'''
            SELECT nh.callchain_id,
                   SUM(nh.heap_size) AS heap_size,
                   COUNT(*) AS apply_count,
                   0 AS release_count,
                   agg.{agg_col}
            FROM native_hook nh
            LEFT JOIN {agg_table} agg ON nh.callchain_id = agg.callchain_id
            WHERE nh.event_type = 'AllocEvent'
              AND nh.callchain_id > 0
              AND nh.end_ts IS NULL
            GROUP BY nh.callchain_id
            HAVING heap_size > 0
        ''')

    # 先保存主查询结果
    rows = cur.fetchall()

    # 用单独 cursor 加载字符串表
    cur2 = conn.cursor()
    cur2.execute("SELECT id, data FROM data_dict")
    string_table = {r[0]: r[1] for r in cur2.fetchall()}

    callchains = []
    for row in rows:
        cc_id, heap_size, apply_count, release_count, frames_json = row
        if heap_size is None or heap_size <= 0:
            continue
        frames_raw = json.loads(frames_json) if frames_json else []
        frames = []
        for f in frames_raw:
            sym = string_table.get(f.get('symbol_id'), '') or ''
            filepath = string_table.get(f.get('file_id'), '') or ''
            frames.append({
                'depth': f.get('depth', 0),
                'symbol_data': sym,
                'file_data': filepath,
            })
        callchains.append({
            'callchain_id': cc_id,
            'heap_size': heap_size,
            'apply_count': apply_count or 0,
            'release_count': release_count or 0,
            'frames': frames,
        })

    conn.close()
    print(f'[OK] 从 {db_path} 查询到 {len(callchains)} 条存活调用栈')
    return callchains


# ── SO 帧筛选 ──────────────────────────────────────────────────

def filter_by_so(callchains, so_name):
    """筛选包含指定 SO 帧的调用栈（帧的 file_data 或 symbol_data 包含 so_name 即匹配）"""
    matched = []
    for cc in callchains:
        for frame in cc['frames']:
            file_data = frame.get('file_data', '')
            symbol_data = frame.get('symbol_data', '')
            if so_name in file_data or so_name in symbol_data:
                matched.append(cc)
                break
    return matched


def filter_by_frame(callchains, keywords):
    """筛选帧名包含任一关键字的调用栈（DMA 型 SO 的调用路径归因用）。

    DMA 型 SO（libbuffer_handle.z.so 等）的 DMA 内存由 gralloc/dmabuf 承载、
    不经应用进程 malloc，按 SO 名聚类必然为空；但其 SurfaceBuffer 读取/请求
    路径（ReadSurfaceBufferImpl / SurfaceBufferImpl::* 等）发生在应用进程内、
    调用栈被 native_hook 抓到。按帧名子串（如 'SurfaceBuffer'）筛选可还原
    这些路径。注意：树上 value 是栈上 malloc 存活分配量，≠ DMA 内存量。
    """
    matched = []
    for cc in callchains:
        for frame in cc['frames']:
            symbol_data = frame.get('symbol_data', '')
            if any(kw in symbol_data for kw in keywords):
                matched.append(cc)
                break
    return matched


def query_events_by_frame(db_path, keywords):
    """--frame 模式专用查询：聚合含关键字帧的调用链上的**全部 hook 事件**。

    与 query_callchains（仅 AllocEvent + 存活过滤）不同，本函数覆盖全部事件类型
    （ION_Alloc_Event / MmapEvent / AllocEvent / FD_Open_Event 等，含已释放）：
    DMA 型 SO 的关键路径事件不是 AllocEvent——dmabuf 的分配/映射/fd 传递分别记录为
    ION_Alloc_Event（heap_size 即 DMA 字节数）、MmapEvent、FD_Open_Event，若按
    malloc 存活口径过滤，这些链几乎全部丢失、树上 value≈0，火焰图呈空白。
    全量口径下树 value = 关键字路径事件的累计字节（A/B 差分 delta = 新增分配量，
    与 dmabuf 快照差值可直接对账），实际调用栈帧按真实字节宽度渲染可见。
    """
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()

    # 1) 命中调用链：任一帧 symbol_data 含关键字
    like_clause = ' OR '.join(f"d.data LIKE '%' || ? || '%'" for _ in keywords)
    cur.execute(f'''
        SELECT DISTINCT f.callchain_id
        FROM native_hook_frame f
        JOIN data_dict d ON f.symbol_id = d.id
        WHERE {like_clause}
    ''', tuple(keywords))
    hit_ids = [r[0] for r in cur.fetchall()]
    if not hit_ids:
        conn.close()
        return []

    # 2) 事件聚合：全部类型、含已释放；value = 累计字节, apply_count = 事件次数
    id_placeholders = ','.join('?' for _ in hit_ids)
    cur.execute(f'''
        SELECT callchain_id,
               SUM(heap_size) AS total_bytes,
               COUNT(*) AS event_count,
               SUM(CASE WHEN end_ts IS NULL THEN 1 ELSE 0 END) AS alive_count
        FROM native_hook
        WHERE callchain_id IN ({id_placeholders})
        GROUP BY callchain_id
    ''', tuple(hit_ids))

    event_agg = {r[0]: (r[1] or 0, r[2] or 0, r[3] or 0) for r in cur.fetchall()}

    # 3) 帧序列（命中链数通常 ~几十条，直接查询无需中间表）
    cur.execute(f'''
        SELECT f.callchain_id, f.depth, f.symbol_id, f.file_id
        FROM native_hook_frame f
        WHERE f.callchain_id IN ({id_placeholders})
        ORDER BY f.callchain_id, f.depth
    ''', tuple(hit_ids))
    frame_rows = cur.fetchall()

    cur2 = conn.cursor()
    cur2.execute("SELECT id, data FROM data_dict")
    string_table = {r[0]: r[1] for r in cur2.fetchall()}
    conn.close()

    frames_by_chain = {}
    for cc_id, depth, sym_id, file_id in frame_rows:
        frames_by_chain.setdefault(cc_id, []).append({
            'depth': depth,
            'symbol_data': string_table.get(sym_id, '') or '',
            'file_data': string_table.get(file_id, '') or '',
        })

    callchains = []
    for cc_id in hit_ids:
        if cc_id not in event_agg:
            continue  # 有帧无事件的孤儿链（如纯统计残留），跳过
        total_bytes, event_count, alive_count = event_agg[cc_id]
        callchains.append({
            'callchain_id': cc_id,
            'heap_size': total_bytes,
            'apply_count': event_count,
            'release_count': event_count - alive_count,
            'frames': frames_by_chain.get(cc_id, []),
        })
    return callchains


def diagnose_no_match(db_path, so_name):
    """无匹配调用栈时的根因诊断（不生成 tree.json 的原因定位）。

    DMA/SO_SIZE/HAP 型 SO（如 libhdi.z.so、libbuffer_handle.z.so）的内存由
    gralloc/dmabuf 或文件映射承载，不经 malloc 分配，native_hook 表中无其帧——
    属数据本质限制而非脚本故障。此函数区分"SO 名写错"与"该 SO 无 native heap 数据"
    两种情况，并给出可操作的去向提示。
    """
    conn = sqlite3.connect(db_path)
    cur = conn.cursor()
    cur.execute("SELECT data FROM data_dict WHERE data LIKE ?", (f'%{so_name}%',))
    rows = [r[0] for r in cur.fetchall()]
    if not rows:
        # SO 名在 db 中完全不存在：可能是 .z 变体等名称写法差异
        stem = so_name.rsplit('.so', 1)[0]
        cur.execute("SELECT DISTINCT data FROM data_dict WHERE data LIKE ? AND data LIKE '%.so%'", (f'%{stem}%',))
        variants = sorted(set(r[0].split('/')[-1] for r in cur.fetchall()))
        conn.close()
        print(f'错误: SO "{so_name}" 无匹配调用栈，且 db 符号表中不存在该名称。')
        if variants:
            print(f'  相近名称（可能是目标 SO 的另一种写法）: {", ".join(variants[:8])}')
        print('  提示: 子串精确匹配需与 so 实名一致（如 libhdi.so 与 libhdi.z.so 互不匹配）。')
        return 1
    # 名称存在但无帧：该 SO 无 native heap 分配（DMA/SO_SIZE 型）
    conn.close()
    print(f'错误: SO "{so_name}" 无匹配调用栈。')
    print(f'  db 符号表中存在该 SO 条目（如 {rows[0][:100]}），但 native_hook 调用栈中无其帧——')
    print('  该 SO 的内存为 DMA/SO_SIZE/HAP 型（gralloc/dmabuf 或文件映射，不经 malloc 分配），')
    print('  native heap 聚类树/火焰图对它必然为空，属数据本质限制。')
    print('  去向: 改走步骤 5 smaps 对比（含 SO_SIZE/HAP 明细时）或第五章 DMA 对比分析（dma_detail.xlsx）。')
    return 1


# ── 聚类树构建 ─────────────────────────────────────────────────

class StringTable:
    """字符串去重编号表"""

    def __init__(self):
        self._table = OrderedDict()

    def intern(self, s):
        if s not in self._table:
            self._table[s] = len(self._table)
        return self._table[s]

    def dump(self):
        return list(self._table.keys())


class Node:
    """聚类树节点"""
    __slots__ = (
        'name', 'lib', 'value', 'apply_count', 'release_count',
        'children', 'is_leaf', 'callchain_id',
    )

    def __init__(self, name, lib):
        self.name = name
        self.lib = lib
        self.value = 0
        self.apply_count = 0
        self.release_count = 0
        self.children = {}
        self.is_leaf = False
        self.callchain_id = None


def insert_stack(root, st, frames, heap_size, apply_count, release_count, callchain_id):
    """逐帧插入聚类树（前缀树聚类核心）"""
    # 过滤掉 hook 库等排除 SO 的帧
    frames = [f for f in frames if not _is_excluded_so(f.get('file_data', ''))]
    node = root
    node.value += heap_size

    for frame in frames:
        sym = st.intern(normalize_symbol(frame.get('symbol_data', '')))
        lib = st.intern(normalize_symbol(frame.get('file_data', '')))

        child = node.children.get(sym)
        if child is None:
            child = Node(sym, lib)
            node.children[sym] = child

        child.value += heap_size
        child.apply_count += apply_count
        child.release_count += release_count
        node = child

    # 挂叶子节点，保留原始 callchain_id
    leaf_name = st.intern(f'meta:{callchain_id}')
    leaf = Node(leaf_name, st.intern(''))
    leaf.value = heap_size
    leaf.apply_count = apply_count
    leaf.release_count = release_count
    leaf.is_leaf = True
    leaf.callchain_id = callchain_id
    node.children[leaf_name] = leaf


def tree_to_json(node, st, threshold=0.0):
    """将聚类树转为可序列化的 dict（阈值剪枝）"""
    str_table = st.dump()

    def _convert(n):
        res = {
            'name': str_table[n.name],
            'value': n.value,
            'value_mb': round(n.value / 1048576, 2),
        }
        if n.apply_count:
            res['apply_count'] = n.apply_count
        if n.release_count:
            res['release_count'] = n.release_count
        if n.is_leaf:
            res['is_leaf'] = True
            if n.callchain_id is not None:
                res['callchain_id'] = n.callchain_id
        if n.children:
            visible = []
            for ch in n.children.values():
                if ch.is_leaf or ch.value > threshold:
                    visible.append(_convert(ch))
            if visible:
                res['children'] = visible
        return res

    return _convert(node)


def build_cluster_tree(callchains):
    """对调用栈列表构建聚类树，返回 (string_table, tree_dict)"""
    st = StringTable()
    root = Node(st.intern('root'), st.intern('root'))

    for cc in callchains:
        insert_stack(root, st, cc['frames'], cc['heap_size'],
                     cc['apply_count'], cc['release_count'], cc['callchain_id'])

    threshold = root.value * 0.00001  # 0.001% 剪枝
    tree = tree_to_json(root, st, threshold)
    return st.dump(), tree


# ── 主流程 ──────────────────────────────────────────────────────

def main():
    parser = argparse.ArgumentParser(description='调用栈聚类：按 SO 名或帧名关键字生成前缀树聚类树（JSON）')
    parser.add_argument('--db', required=True, help='SQLite db 路径')
    group = parser.add_mutually_exclusive_group(required=True)
    group.add_argument('--so', help='目标 SO 名称（如 libentry.so），按帧所属 SO 匹配')
    group.add_argument('--frame', help='帧名关键字（逗号分隔多个，如 SurfaceBuffer），按 symbol_data 子串匹配；'
                                       '适合 DMA 型 SO 的调用路径归因（DMA 不经 malloc，但 SurfaceBuffer '
                                       '路径调用栈在 native_hook 表中）')
    parser.add_argument('--label', default='', help='输出文件名标签（默认取 --so/--frame 值；'
                                                     '--frame 模式建议传 SO 名保持下游命名一致）')
    parser.add_argument('--output', default='', help='输出文件路径（默认 db 同级目录下 <label>_tree.json）')
    args = parser.parse_args()

    db_path = Path(args.db)
    if not db_path.exists():
        print(f'错误: 数据库不存在: {db_path}')
        return

    print(f'分析数据库: {db_path}')
    callchains = []
    if args.so:
        # --so 模式需要存活 AllocEvent 调用栈（native heap 归因口径）
        callchains = query_callchains(str(db_path))

    if args.so:
        matched = filter_by_so(callchains, args.so)
        if not matched:
            sys.exit(diagnose_no_match(str(db_path), args.so))
        mode_desc = args.so
    else:
        keywords = [kw.strip() for kw in args.frame.split(',') if kw.strip()]
        # --frame 走全事件口径（ION_Alloc/Mmap/Alloc/FD 全类型、含已释放）：
        # DMA 路径的关键事件不是存活 AllocEvent，malloc 存活口径会丢栈且 value≈0
        matched = query_events_by_frame(str(db_path), keywords)
        if not matched:
            # A/B 对比场景中"无匹配"本身是有效结果（如旧版未走该路径）：
            # 生成空树基线（value=0）保证下游 diff/火焰图流水线可跑，而非中断。
            print(f'[WARN] 帧名关键字 {keywords} 无匹配事件调用链，生成空树基线（value=0）。')
            print('  提示: 若关键字疑似写错，可先检索 data_dict 确认帧名存在：')
            print("        sqlite3 <db> \"SELECT DISTINCT data FROM data_dict WHERE data LIKE '%SurfaceBuffer%'\"")
        mode_desc = f'帧名关键字 {keywords}'
        print('  [口径提示] --frame 聚类覆盖全部 hook 事件类型（ION_Alloc/Mmap/Alloc/FD，含已释放），')
        print('             树上 value = 关键字路径事件累计字节；DMA 内存量看 ION_Alloc_Event 子树，')
        print('             产物不并入 native heap 统计（native heap 口径仅 AllocEvent 存活分配）。')

    print(f'[OK] 筛选到 {len(matched)} 条包含 {mode_desc} 的调用栈')

    str_table, tree = build_cluster_tree(matched)

    # 输出路径
    label = args.label or args.so or args.frame
    if args.output:
        out_path = Path(args.output)
    else:
        _dangerous = set('/\\<>:"|?*')
        safe_name = ''.join('_' if (c in _dangerous or ord(c) < 32) else c for c in label)
        out_path = db_path.parent / f'{safe_name}_tree.json'
    out_path.parent.mkdir(parents=True, exist_ok=True)

    out_path.write_text(
        json.dumps({'string_table': str_table, 'tree': tree}, indent=2, ensure_ascii=False),
        encoding='utf-8')
    print(f'[OK] {label}: 聚类树已保存 ({tree["value_mb"]}MB, {out_path})')


if __name__ == '__main__':
    main()