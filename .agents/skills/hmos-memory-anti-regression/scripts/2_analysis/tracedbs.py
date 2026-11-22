
import sys
from pathlib import Path
import datetime
import fnmatch
import json
import logging
import os
import re
import sqlite3
from collections import defaultdict
from typing import Any, List, Optional

sys.path.insert(0, str(Path(__file__).resolve().parent / "../_lib"))
from encoding import *  # noqa: E402  # Force UTF-8 output (fixes Windows GBK garbled text)
sys.path.insert(0, str(Path(__file__).resolve().parent / "."))
sys.path.insert(0, str(Path(__file__).resolve().parent / "so_field"))
from callchain import OptimizedCallChain
from analysis_utils import timing_decorator
from config import TraceType, config_data

START_TS = None
END_TS = None


# 只读查询 PRAGMA 调优: 大库(数 GB+) I/O 主要瓶颈在默认 2MB page cache + 无 mmap。
# mmap_size: 把库文件 mmap 进页缓存(惰性, 按访问页数占用, 不实占); cache_size: SQLite 自身页缓存;
# temp_store=MEMORY: GROUP BY 等临时结果走内存(仅在用户未指定 temp_dir 时, 尊重其磁盘选择)。
_DB_MMAP_SIZE = 30_000_000_000   # 30 GB mmap 上限(惰性)
_DB_CACHE_KB = 1_000_000         # ~1 GB SQLite 页缓存


def _apply_read_pragmas(cursor):
    cursor.execute(f"PRAGMA mmap_size = {int(config_data.get('db_mmap_size', _DB_MMAP_SIZE))};")
    cursor.execute(f"PRAGMA cache_size = -{int(config_data.get('db_cache_kb', _DB_CACHE_KB))};")
    if not config_data.get("temp_dir"):
        cursor.execute("PRAGMA temp_store = MEMORY;")


# 关键查询索引(与 convert_htrace_to_sqlitedb._INDEXES 保持一致, 兜底老库缺索引)
_QUERY_INDEXES = [
    "CREATE INDEX IF NOT EXISTS idx_nh_type_callchain_ipid ON native_hook_statistic(type, callchain_id, ipid)",
    "CREATE INDEX IF NOT EXISTS idx_nhf_callchain_id ON native_hook_frame(callchain_id)",
    "CREATE INDEX IF NOT EXISTS idx_process_ipid ON process(ipid)",
    "CREATE INDEX IF NOT EXISTS idx_native_hook_main ON native_hook(start_ts, end_ts, event_type, callchain_id)",
    "CREATE INDEX IF NOT EXISTS idx_native_hook_addr_heap ON native_hook(addr, heap_size)",
]


def _ensure_query_indexes(cursor):
    for sql in _QUERY_INDEXES:
        try:
            cursor.execute(sql)
        except sqlite3.Error as e:
            print(f"   [WARN] 建索引失败(跳过): {e}")
    cursor.connection.commit()


def get_realtime(sys_boottime, sys_realttime, ts):
    relative_time = ts - sys_boottime
    t = relative_time + sys_realttime
    seconds = t // 10 ** 9
    nanoseconds = t % 10 ** 9
    return "{}.{}".format(datetime.datetime.fromtimestamp(seconds), nanoseconds), relative_time / 10 ** 9


def get_ts_from_realtime(sys_boottime, sys_realttime, time_str):
    """
    将真实时间字符串（例如 '20251102-022418'）转换为对应的 ts。
    sys_boottime 和 sys_realttime 都是纳秒级时间戳。
    """
    # 解析时间字符串 -> datetime
    dt = datetime.datetime.strptime(time_str, "%Y%m%d-%H%M%S")

    # 转为 Unix 时间戳（秒）再转纳秒
    realtime_ns = int(dt.timestamp() * 1e9)

    # 按公式反推 ts
    ts = realtime_ns - sys_realttime + sys_boottime
    return ts


# noinspection SqlResolve,SqlNoDataSourceInspection
def get_boottime_and_realtime(source_cursor):
    find_time_sql = "SELECT cs.ts, cs.clock_name FROM clock_snapshot cs"
    sys_boottime = None
    sys_realtime = None
    source_cursor.execute(find_time_sql)
    rows = source_cursor.fetchall()
    for i in rows:
        if i[1] == 'boottime':
            sys_boottime = i[0]
        elif i[1] == 'realtime':
            sys_realtime = i[0]
    return sys_boottime, sys_realtime

def create_if_not_exist_intermediate_table(source_cursor):
    table_exists_query = "SELECT name FROM sqlite_master WHERE type='table' AND name='native_hook_agg';"

    # 执行检查表是否存在
    source_cursor.execute(table_exists_query)
    table_exists = source_cursor.fetchone()
    if not table_exists:
        agg_table_sql = """
            CREATE TABLE native_hook_agg AS
            SELECT nhf.callchain_id,
                json_group_array(
                    json_object(
                        'depth', nhf.depth,
                        'symbol_id', nhf.symbol_id,
                        'file_id', nhf.file_id
                    )
                ) AS result_json
            FROM native_hook_frame nhf
            GROUP BY nhf.callchain_id
        """
        index_sql = "CREATE INDEX IF NOT EXISTS idx_callchain_id ON native_hook_agg(callchain_id)"
        print(f"native_hook_agg 表不存在，创建表和索引...\n{agg_table_sql}\n{index_sql}")
        source_cursor.execute(agg_table_sql)
        source_cursor.execute(index_sql)

def detect_db_mode(source_db_dir: str) -> bool:
    """自动检测DB是详细模式还是统计模式。
    返回 True 表示详细模式（native_hook 表有数据），False 表示统计模式（native_hook_statistic 表有数据）。
    """
    source_db_paths = __get_query_dbs(None, source_db_dir)
    db_path = source_db_paths[0]
    conn = sqlite3.connect(db_path)
    try:
        cursor = conn.cursor()
        cursor.execute("SELECT COUNT(*) FROM native_hook LIMIT 1;")
        if cursor.fetchone()[0] > 0:
            return True
        cursor.execute("SELECT COUNT(*) FROM native_hook_statistic LIMIT 1;")
        if cursor.fetchone()[0] > 0:
            return False
        raise RuntimeError(f"DB {db_path} 中 native_hook 和 native_hook_statistic 表均无数据，无法自动检测模式")
    finally:
        conn.close()


def build_condition(conds):
    parts = []
    for c in conds:
        if isinstance(c, str):
            parts.append(c)
        elif isinstance(c, (tuple, list)):
            or_cond = " OR ".join(c)
            parts.append(f"({or_cond})")
        else:
            raise ValueError("Unsupported type")
    return " AND ".join(parts)


# noinspection SqlNoDataSourceInspection,SqlResolve
def query_string_table(source_db_dir: str):
    source_db_paths = __get_query_dbs(None, source_db_dir)
    string_table = {}
    for db_idx, db_path in enumerate(source_db_paths, 1):
        source_conn = sqlite3.connect(db_path)
        source_cursor = source_conn.cursor()
        if "temp_dir" in config_data:
            source_cursor.execute("PRAGMA temp_store_directory = " + config_data["temp_dir"])
        _apply_read_pragmas(source_cursor)

        try:
            source_cursor.execute("select id, data from data_dict")
            string_dict = {}
            for r in source_cursor:
                _id = r[0]
                _data = r[1]
                string_dict[_id] = _data
            string_table.update(string_dict)
        except sqlite3.Error as e:
            print(f"   处理源DB失败：{str(e)}，跳过该DB")
        finally:
            source_conn.close()
    return string_table

@timing_decorator(description="数据库查询统计")
def merge_multiple_dbs_to_json(
        source_db_dir: str,
        _types: list,
        exclude_patterns: Optional[List[str]] = None,
        startts: str = None,
        endts: str = None,
        pid: int = -1
) -> OptimizedCallChain:
    source_db_paths = __get_query_dbs(exclude_patterns, source_db_dir)

    # 3. 动态生成源DB查询SQL（支持时间范围筛选）
    base_conditions: list[Any] = [
        "1==1"
    ]
    inner_conditions = []
    for _t in _types:
        inner_conditions.append(f"nh.type=={_t}")
    base_conditions.append(inner_conditions)
    query_params = []
    res = OptimizedCallChain()
    # 6. 循环处理源DB
    for db_idx, db_path in enumerate(source_db_paths, 1):
        source_db_name = os.path.basename(db_path)
        print(f"\n===== 处理第 {db_idx}/{len(source_db_paths)} 个源DB：{source_db_name} =====")

        source_conn = sqlite3.connect(db_path)
        source_cursor = source_conn.cursor()
        if "temp_dir" in config_data:
            source_cursor.execute("PRAGMA temp_store_directory = " + config_data["temp_dir"])
        _apply_read_pragmas(source_cursor)
        _ensure_query_indexes(source_cursor)

        try:
            sys_boottime, sys_realtime = get_boottime_and_realtime(source_cursor)
            if sys_boottime is None or sys_realtime is None:
                print(f"   处理源DB失败：没有系统时间，跳过该DB")
                continue
            create_if_not_exist_intermediate_table(source_cursor)
            # native_hook_statistic.ts 是 trace_streamer 的聚合时间戳，
            # 所有行值相同，不适合用于时间范围过滤。
            # 统计表数据本身就是整个采集期间的聚合结果，
            # apply_size - release_size 已代表存活内存，无需按 ts 过滤。

            if not pid == -1:
                base_conditions.append("p.pid == ?")
                query_params.append(pid)
            source_query_sql = f"""
                SELECT 
                    p.pid,
                    p.name,
                    nh.callchain_id,
                    MAX(nh.ts) AS ts,
                    MAX(nh.apply_size) AS apply_size,
                    MAX(nh.release_size) AS release_size,
                    MAX(nh.apply_count) AS apply_count,
                    MAX(nh.release_count) AS release_count,
                    nf.result_json,
                    CASE 
                        WHEN nh.type = 0 THEN '{TraceType.NATIVE_HEAP.name}'
                        WHEN nh.type = 1 THEN '{TraceType.MMAP.name}'
                        WHEN nh.type = 2 THEN '{TraceType.FILE_PAGE_MSG.name}'
                        WHEN nh.type = 3 THEN '{TraceType.MEMORY_USING_MSG.name}'
                        WHEN nh.type = 4 THEN '{TraceType.FD.name}'
                        WHEN nh.type = 5 THEN '{TraceType.THREAD.name}'
                        WHEN nh.type = 6 THEN '{TraceType.GPU_VK.name}'
                        WHEN nh.type = 7 THEN '{TraceType.GPU_GLES.name}'
                        WHEN nh.type = 8 THEN '{TraceType.GPU_CL.name}'
                        WHEN nh.type = 9 THEN '{TraceType.SO_SIZE.name}'
                        WHEN nh.type = 10 THEN '{TraceType.ARKTS_HEAP.name}'
                        WHEN nh.type = 11 THEN '{TraceType.JS_HEAP.name}'
                        WHEN nh.type = 12 THEN '{TraceType.KMP_HEAP.name}'
                        WHEN nh.type = 13 THEN '{TraceType.RN_HEAP.name}'
                        WHEN nh.type = 14 THEN '{TraceType.ASHMEM.name}'
                        WHEN nh.type = 15 THEN '{TraceType.DMA.name}'
                    END AS type
                FROM 
                    native_hook_statistic nh
                INNER JOIN 
                    process p ON nh.ipid = p.ipid
                LEFT JOIN 
                    native_hook_agg nf ON nh.callchain_id = nf.callchain_id
                WHERE {build_condition(base_conditions)}
                GROUP BY nh.callchain_id;
                """
            print(f"   正在执行查询：{source_query_sql}")
            source_cursor.execute(source_query_sql, query_params)

            for row in source_cursor:
                heap_size = row[4] - row[5]
                res.append({
                    "pid": row[0],
                    "process_name": row[1],
                    "callchain_id": row[2],
                    "ts": get_realtime(sys_boottime, sys_realtime, row[3])[0],
                    "type": row[9],
                    "heap_size": heap_size,
                    "frames": json.loads(row[8]) if row[8] else [],
                    "apply_count": row[6],
                    "release_count": row[7],
                    "apply_size": row[4],
                    "release_size": row[5]
                })
            print(f"   从源DB查询到 {len(res)} 条符合条件的记录")

        except sqlite3.Error as e:
            print(f"   处理源DB失败：{str(e)}，跳过该DB")
        finally:
            source_conn.close()

    # 7. 输出结果
    print(f"\n" + "=" * 60)
    print(f"所有源DB处理完成！")
    print(f"合并统计：")
    print(f"   - 源DB数量：{len(source_db_paths)} 个")
    print(f"   - 总插入记录数：{len(res)} 条")
    print("=" * 60)
    return res


def __get_query_dbs(exclude_patterns: list[str] | None, source_db_dir: str) -> list[Any]:
    """
    从多个源DB读取指定时间段的数据，合并后写入目标DB的新表中
    """
    # 1. 初始化参数
    if exclude_patterns is None:
        exclude_patterns = ["merged_*.db", "temp_*.db", "统计结果.db"]

    # 2. 收集所有源DB路径（修复模式匹配问题）
    source_db_paths = []
    for file in os.listdir(source_db_dir):
        file_path = os.path.join(source_db_dir, file)
        # 修复：使用fnmatch.fnmatch替代字符串的match方法
        if (os.path.isfile(file_path) and
                file.endswith(".db") and
                not any(fnmatch.fnmatch(file, pattern) for pattern in exclude_patterns)):
            source_db_paths.append(file_path)

    if not source_db_paths:
        raise RuntimeError(f"在 {source_db_dir} 中未找到符合条件的源DB文件")

    print(f"发现 {len(source_db_paths)} 个源DB文件，准备合并：")
    for db in source_db_paths:
        print(f"   - {os.path.basename(db)}")
    return source_db_paths


# noinspection SqlNoDataSourceInspection,SqlResolve,DuplicatedCode
def build_memory_usage_over_time(source_db_dir: str):
    target_db_path = Path(source_db_dir) / "统计结果.db"
    source_db_paths = []
    for file in os.listdir(source_db_dir):
        file_path = os.path.join(source_db_dir, file)
        # 修复：使用fnmatch.fnmatch替代字符串的match方法
        if os.path.isfile(file_path) and file.endswith(".db") and "统计结果.db" != file:
            source_db_paths.append(file_path)
    if not source_db_paths:
        raise RuntimeError(f"在 {source_db_dir} 中未找到符合条件的源DB文件")
    res = []
    # 6. 循环处理源DB
    total_inserted = 0
    result = []
    base_conditions: list[Any] = [
        "1=1"
    ]
    inner_conditions = []
    for _t in config_data["type"]:
        inner_conditions.append(f"type={_t}")
    base_conditions.append(inner_conditions)

    for db_idx, db_path in enumerate(source_db_paths, 1):
        source_conn = sqlite3.connect(db_path)
        try:
            source_cursor = source_conn.cursor()
            sys_boottime, sys_realtime = get_boottime_and_realtime(source_cursor)
            if sys_boottime is None or sys_realtime is None:
                continue
            if config_data["endts"] is not None:
                endts = get_ts_from_realtime(sys_boottime, sys_realtime, config_data["endts"])
                base_conditions.append(f"ts <= {endts}")
            aggregate_sql = f"""
                SELECT 
                    ts,
                    type,
                    callchain_id,
                    CASE
                        WHEN type = 9 THEN (apply_size - release_size) / (apply_count - release_count)
                        ELSE apply_size - release_size
                    END AS heap_size
                FROM native_hook_statistic
                WHERE {build_condition(base_conditions)} 
            """
            print(aggregate_sql)
            source_cursor.execute(aggregate_sql)
            rows = source_cursor.fetchall()
            if not rows:
                continue
            # 当前状态：(type, callchain_id) -> heap_size
            current_state = {}
            # 当前 ts 下，各 type 的总内存
            current_type_sum = defaultdict(int)
            # 结果：(ts, type) -> total_heap_size
            current_ts = None
            for row in rows:
                ts, type_, callchain_id, heap_size = row
                # ts 推进，先落盘上一个 ts 的结果
                if current_ts is not None and ts != current_ts:
                    for t, total in current_type_sum.items():
                        result.append((current_ts, t, total))
                current_ts = ts
                key = (type_, callchain_id)
                # 如果该 callchain 之前已有值，需要先减掉旧值
                if key in current_state:
                    current_type_sum[type_] -= current_state[key]
                # 更新状态
                current_state[key] = heap_size
                current_type_sum[type_] += heap_size
            # 最后一个 ts
            if current_ts is not None:
                for t, total in current_type_sum.items():
                    result.append((current_ts, t, total))
            result.sort(key=lambda x: (x[0], x[1]))
            for ts, type_, ths in result:
                time_str, relative_time = get_realtime(sys_boottime, sys_realtime, ts)
                res.append({
                    "ts": ts,
                    "type": type_,
                    "heap_size": ths,
                    "time_str": time_str,
                    "relative_time": relative_time,
                    "type_name": TraceType(type_).name
                })
        except sqlite3.Error as e:
            print(f"   处理源DB失败：{str(e)}，跳过该DB")
        finally:
            source_conn.close()
    conn = sqlite3.connect(target_db_path)
    cur = conn.cursor()
    cur.execute(
        """
            CREATE TABLE IF NOT EXISTS mem_usage
            (
                ts                  INTEGER,
                type                INT,
                heap_size           INTEGER,
                time_str            TEXT,
                relative_time       REAL,
                type_name           TEXT
            )
        """
    )
    insert_sql = """
         INSERT INTO mem_usage (ts, type, heap_size, time_str, relative_time, type_name) 
         VALUES (:ts, :type, :heap_size, :time_str, :relative_time, :type_name)
    """
    cur.executemany(insert_sql, res)
    conn.commit()
    conn.close()
    return res


@timing_decorator(description="查询明细数据")
# noinspection SqlNoDataSourceInspection,DuplicatedCode
def query_native_hook(
        source_db_dir: str,
        event_types: list[str],
        exclude_patterns: Optional[List[str]] = None,
        startts: str = None,
        endts: str = None,
        aggregate: bool = True):
    """查询 native_hook 表。

    Args:
        aggregate: True=SQL级 GROUP BY callchain_id 聚合（按 callchain_id 合并
            heap_size，frames 只解析一次，适用于 add_detail_data 等只需聚合
            结果的场景，大幅减少内存）；False=返回逐条记录（含 addr 字段，
            适用于 add_anno_data 等需逐条处理后再聚合的场景）。
    """
    source_db_paths = __get_query_dbs(exclude_patterns, source_db_dir)
    res = []
    for db_idx, db_path in enumerate(source_db_paths, 1):
        source_conn = sqlite3.connect(db_path)
        source_cursor = source_conn.cursor()
        _apply_read_pragmas(source_cursor)
        _ensure_query_indexes(source_cursor)
        try:
            sys_boottime, sys_realtime = get_boottime_and_realtime(source_cursor)
            if sys_boottime is None or sys_realtime is None:
                print(f"   处理源DB失败：没有系统时间，跳过该DB")
                continue
            create_if_not_exist_intermediate_table(source_cursor)
            conditions = f"1==1"
            if startts is not None:
                conditions += f" AND (nh.start_ts>={get_ts_from_realtime(sys_boottime, sys_realtime, startts)})"
            if endts is not None:
                end_ts = get_ts_from_realtime(sys_boottime, sys_realtime, endts)
                conditions += f" AND ((nh.end_ts is NULL) or (nh.end_ts>={end_ts})) AND (nh.start_ts < {end_ts})"
            else:
                conditions += " AND (end_ts is NULL)"
            if len(event_types) > 0:
                event_type_str = "({})".format(", ".join(f"'{v}'" for v in event_types))
                conditions += f" AND (event_type in {event_type_str})"

            if aggregate:
                source_query_sql = f"""
                    SELECT
                        nh.callchain_id,
                        SUM(nh.heap_size) as heap_size,
                        MAX(nh.start_ts) as ts,
                        MIN(nh.event_type) as event_type,
                        MAX(nf.result_json) as result_json,
                        MAX(p.pid) as pid,
                        MAX(p.name) as name,
                        COUNT(*) as apply_count
                    FROM
                        native_hook nh
                    INNER JOIN
                        process p ON nh.ipid = p.ipid
                    LEFT JOIN native_hook_agg nf ON nh.callchain_id = nf.callchain_id
                    WHERE {conditions}
                    GROUP BY nh.callchain_id
                """
            else:
                source_query_sql = f"""
                    SELECT
                        nh.callchain_id,
                        nh.addr,
                        nh.event_type,
                        nh.heap_size,
                        nh.start_ts,
                        nf.result_json,
                        p.pid,
                        p.name
                    FROM
                        native_hook nh
                    INNER JOIN
                        process p ON nh.ipid = p.ipid
                    LEFT JOIN native_hook_agg nf ON nh.callchain_id = nf.callchain_id
                    WHERE {conditions}
                """
            print(f"   正在执行查询：{source_query_sql}")
            source_cursor.execute(source_query_sql)
            if aggregate:
                for row in source_cursor:
                    res.append({
                        "ts": get_realtime(sys_boottime, sys_realtime, row[2])[0],
                        "callchain_id": row[0],
                        "event_type": row[3],
                        "heap_size": row[1],
                        "frames": json.loads(row[4]) if row[4] else [],
                        "pid": row[5],
                        "process_name": row[6],
                        "apply_count": row[7],
                    })
            else:
                res_cc = OptimizedCallChain()
                for row in source_cursor:
                    res_cc.append({
                        "ts": get_realtime(sys_boottime, sys_realtime, row[4])[0],
                        "callchain_id": row[0],
                        "addr": row[1],
                        "event_type": row[2],
                        "heap_size": row[3],
                        "frames": json.loads(row[5]) if row[5] else [],
                        "pid": row[6],
                        "process_name": row[7]
                    })
                res = res_cc.to_dict()
            print(f"   从源DB查询到 {len(res)} 条 {'聚合' if aggregate else 'anno'} 记录")

        except sqlite3.Error as e:
            print(f"   处理源DB失败：{str(e)}，跳过该DB")
        finally:
            source_conn.close()
    return res


# def _get_clock_snapshot(db_path: str) -> dict[str, int]:
#     """Read clock_snapshot table, return {clock_name: ts} mapping.

#     clock_snapshot columns: id, clock_id, ts, clock_name
#     Typical clock_name values: sys_boottime, sys_realtime, realtime_corse, monotonic

#     Returns: dict mapping clock_name to ts (nanoseconds).
#     """
#     with sqlite3.connect(db_path) as conn:
#         conn.row_factory = sqlite3.Row
#         cursor = conn.execute("SELECT clock_name, ts FROM clock_snapshot")
#         clocks = {}
#         for row in cursor.fetchall():
#             name = row["clock_name"]
#             if name:
#                 clocks[name] = row["ts"]

#     return clocks


# def _get_clock_offset(db_path: str) -> int:
#     """Compute boottime-to-realtime offset in nanoseconds from clock_snapshot.

#     Uses clock_name (sys_boottime / sys_realtime) instead of clock_id
#     for more robust time conversion.

#     Returns: (sys_realtime_ts - sys_boottime_ts) offset in nanoseconds.
#     """
#     clocks = _get_clock_snapshot(db_path)

#     boottime_ts = clocks.get("sys_boottime", 0)
#     realtime_ts = clocks.get("sys_realtime", 0)
#     return realtime_ts - boottime_ts


# def _create_native_hook_agg(conn: sqlite3.Connection) -> None:
#     """Create native_hook_agg intermediate table if not exists.

#     Aggregates native_hook_frame rows by callchain_id into JSON:
#     [{depth, symbol_id, file_id}, ...]
#     Stored as result_json column.
#     """
#     conn.execute("""
#         CREATE TABLE IF NOT EXISTS native_hook_agg (
#             callchain_id INTEGER PRIMARY KEY,
#             result_json TEXT
#         )
#     """)

#     cursor = conn.execute("""
#         SELECT callchain_id, depth, symbol_id, file_id
#         FROM native_hook_frame
#         ORDER BY callchain_id, depth
#     """)

#     groups: dict[int, list] = {}
#     for row in cursor.fetchall():
#         cid = row[0]
#         if cid not in groups:
#             groups[cid] = []
#         groups[cid].append({
#             "depth": row[1],
#             "symbol_id": row[2],
#             "file_id": row[3],
#         })

#     if groups:
#         conn.execute("DELETE FROM native_hook_agg")
#         for cid, frames in groups.items():
#             conn.execute(
#                 "INSERT INTO native_hook_agg (callchain_id, result_json) VALUES (?, ?)",
#                 (cid, json.dumps(frames)),
#             )
#         conn.commit()


# def _parse_yyyymmdd_hhmmss(ts_str: str) -> int:
#     """Parse yyyymmdd-hhmmss format to milliseconds timestamp."""
#     dt = datetime.strptime(ts_str, "%Y%m%d-%H%M%S")
#     return int(dt.timestamp() * 1000)


# def merge_multiple_dbs_to_json(
#     db_dir: str,
#     _types: list[int],
#     exclude_patterns: Optional[list[str]] = None,
#     startts: str = None,
#     endts: str = None,
#     pid: int = -1,
# ) -> OptimizedCallChain:
#     source_db_paths = __get_query_dbs(exclude_patterns, db_dir)

#     res = OptimizedCallChain()

#     for db_path in source_db_paths:
#         logger.info("Processing db: %s", db_path)

#         try:
#             clock_snapshot = _get_clock_snapshot(db_path)
#         except sqlite3.OperationalError as e:
#             logger.warning("clock_snapshot not found in %s: %s", db_path, e)
#             clock_snapshot = {}

#         clock_offset = clock_snapshot.get("sys_realtime", 0) - clock_snapshot.get("sys_boottime", 0)
#         res.set_clock_snapshot(clock_snapshot)

#         start_ns = None
#         end_ns = None
#         if startts is not None:
#             start_ms = _parse_yyyymmdd_hhmmss(startts)
#             start_ns = start_ms * 1_000_000 + clock_offset
#         if endts is not None:
#             end_ms = _parse_yyyymmdd_hhmmss(endts)
#             end_ns = end_ms * 1_000_000 + clock_offset

#         symbol_map, file_map = _resolve_data_dict(db_path)

#         with sqlite3.connect(db_path) as conn:
#             try:
#                 _create_native_hook_agg(conn)
#             except sqlite3.OperationalError as e:
#                 logger.warning("native_hook_frame not found in %s: %s", db_path, e)
#                 continue

#             sql = """
#                 SELECT
#                     nh.callchain_id,
#                     p.pid,
#                     p.name,
#                     CASE nh.type
#                         WHEN 0 THEN 'NATIVE_HEAP'
#                         WHEN 1 THEN 'MMAP'
#                         WHEN 2 THEN 'FILE_PAGE_MSG'
#                         WHEN 3 THEN 'MEMORY_USAGE_MSG'
#                         WHEN 4 THEN 'FD'
#                         WHEN 5 THEN 'THREAD'
#                         WHEN 6 THEN 'GPU_VK'
#                         WHEN 7 THEN 'GPU_GLES'
#                         WHEN 8 THEN 'GPU_CL'
#                         WHEN 9 THEN 'SO_SIZE'
#                         WHEN 10 THEN 'ARKTS_HEAP'
#                         WHEN 11 THEN 'JS_HEAP'
#                         WHEN 12 THEN 'KMP_HEAP'
#                         WHEN 13 THEN 'RN_HEAP'
#                         WHEN 14 THEN 'ASHMEM'
#                         WHEN 15 THEN 'DMA'
#                     END as type,
#                     MAX(nh.apply_size) as apply_size,
#                     MAX(nh.release_size) as release_size,
#                     MAX(nh.apply_count) as apply_count,
#                     MAX(nh.release_count) as release_count,
#                     MAX(nh.ts) as ts,
#                     nf.result_json
#                 FROM native_hook_statistic nh
#                 INNER JOIN process p ON nh.ipid = p.ipid
#                 LEFT JOIN native_hook_agg nf ON nh.callchain_id = nf.callchain_id
#                 WHERE 1=1
#             """

#             params: list = []

#             if _types:
#                 type_placeholders = ",".join(["?"] * len(_types))
#                 sql += f" AND nh.type IN ({type_placeholders})"
#                 params.extend(_types)

#             if pid != -1:
#                 sql += " AND p.pid = ?"
#                 params.append(pid)

#             if start_ns is not None:
#                 sql += " AND nh.ts >= ?"
#                 params.append(start_ns)

#             if end_ns is not None:
#                 sql += " AND nh.ts <= ?"
#                 params.append(end_ns)

#             sql += " GROUP BY nh.callchain_id"

#             try:
#                 cursor = conn.execute(sql, params)
#                 columns = [desc[0] for desc in cursor.description]
#                 rows = cursor.fetchall()

#                 for row in rows:
#                     row_dict = dict(zip(columns, row))
#                     res.append(row_dict, symbol_map, file_map)

#             except sqlite3.OperationalError as e:
#                 logger.warning("Query failed on %s: %s", db_path, e)
#                 continue

#     return res


# def _resolve_data_dict(db_path: str) -> tuple[dict[int, str], dict[int, str]]:
#     """Read data_dict table, build id→string mappings for symbols and files."""
#     symbol_map: dict[int, str] = {}
#     file_map: dict[int, str] = {}

#     with sqlite3.connect(db_path) as conn:
#         conn.row_factory = sqlite3.Row
#         try:
#             cursor = conn.execute("SELECT id, data FROM data_dict")
#             for row in cursor.fetchall():
#                 rid = row["id"]
#                 data = row["data"] or ""
#                 if data.startswith("/"):
#                     file_map[rid] = data
#                 else:
#                     symbol_map[rid] = data
#         except sqlite3.OperationalError as e:
#             logger.warning("data_dict not found in %s: %s", db_path, e)

#     return symbol_map, file_map


# def _resolve_callchain_frames(
#     conn: sqlite3.Connection,
#     callchain_id: int,
#     symbol_map: dict[int, str],
#     file_map: dict[int, str],
# ) -> list[dict]:
#     """Resolve callchain frames for a given callchain_id.

#     Returns list of {depth, symbol, file} dicts.
#     """
#     try:
#         cursor = conn.execute(
#             "SELECT depth, symbol_id, file_id FROM native_hook_frame "
#             "WHERE callchain_id = ? ORDER BY depth",
#             (callchain_id,),
#         )
#         frames = []
#         for row in cursor.fetchall():
#             depth = row[0]
#             sym_id = row[1]
#             fid = row[2]
#             frames.append({
#                 "depth": depth,
#                 "symbol": symbol_map.get(sym_id, f"<symbol_{sym_id}>") if sym_id is not None else "<unknown>",
#                 "file": file_map.get(fid, f"<file_{fid}>") if fid is not None else "<unknown>",
#             })
#         return frames
#     except sqlite3.OperationalError:
#         return []


# def _matches_exclude_pattern(callchain: list[dict], exclude_patterns: list[str]) -> bool:
#     """Check if any frame in the callchain matches an exclude pattern.

#     Returns True if the callchain should be excluded.
#     """
#     for frame in callchain:
#         symbol = frame.get("symbol", "")
#         file_path = frame.get("file", "")
#         for pattern in exclude_patterns:
#             if re.search(pattern, symbol) or re.search(pattern, file_path):
#                 return True
#     return False


# def _resolve_result_json(
#     result_json: str | None,
#     symbol_map: dict[int, str],
#     file_map: dict[int, str],
# ) -> list[dict]:
#     """Parse native_hook_agg result_json and resolve symbol/file IDs via data_dict.

#     result_json format: [{"depth":0,"symbol_id":2720,"file_id":307}, ...]

#     Returns list of {depth, symbol, file} dicts with resolved names.
#     """
#     if not result_json:
#         return []

#     try:
#         raw_frames = json.loads(result_json)
#     except (json.JSONDecodeError, TypeError):
#         return []

#     frames = []
#     for f in raw_frames:
#         sym_id = f.get("symbol_id")
#         fid = f.get("file_id")
#         frames.append({
#             "depth": f.get("depth", 0),
#             "symbol": symbol_map.get(sym_id, f"<symbol_{sym_id}>") if sym_id is not None else "<unknown>",
#             "file": file_map.get(fid, f"<file_{fid}>") if fid is not None else "<unknown>",
#         })
#     return frames


# def __get_query_dbs(
#     exclude_patterns: list[str] | None,
#     source_db_dir: str,
# ) -> list[str]:
#     """Collect source DB file paths from source_db_dir, excluding filenames
#     matching exclude_patterns.

#     Args:
#         exclude_patterns: regex patterns to exclude source DB filenames.
#             If None or empty, defaults to ["merged_.*\\.db", "temp_.*\\.db", "统计结果\\.db"]
#         source_db_dir: directory containing .db files from trace_streamer

#     Returns:
#         List of source DB file paths.
#     """
#     DEFAULT_EXCLUDE_PATTERNS = [
#         r"merged_.*\.db",
#         r"temp_.*\.db",
#         r"统计结果\.db",
#     ]

#     if not exclude_patterns:
#         exclude_patterns = DEFAULT_EXCLUDE_PATTERNS

#     source_db_paths: list[str] = []
#     for db_file in os.listdir(source_db_dir):
#         db_file_path = os.path.join(source_db_dir, db_file)
#         if (os.path.isfile(db_file_path)
#                 and db_file.endswith(".db")
#                 and not any(re.search(pattern, db_file) for pattern in exclude_patterns)):
#             source_db_paths.append(db_file_path)

#     if not source_db_paths:
#         raise RuntimeError(f"在{source_db_dir}中未找到符合条件的源DB文件")

#     for db in source_db_paths:
#         logger.info("  - %s", os.path.basename(db))

#     return source_db_paths
    


# def query_native_hook(
#     source_db_dir: str,
#     event_types: list[str],
#     exclude_patterns: Optional[list[str]] = None,
#     startts: Optional[int] = None,
#     endts: Optional[int] = None,
# ):
#     source_db_paths = __get_query_dbs(exclude_patterns, source_db_dir)

#     res = OptimizedCallChain()

#     for db_path in source_db_paths:
#         logger.info("Querying native_hook detail from %s", db_path)

#         try:
#             clock_snapshot = _get_clock_snapshot(db_path)
#         except sqlite3.OperationalError as e:
#             logger.warning("clock_snapshot not found in %s: %s", db_path, e)
#             clock_snapshot = {}

#         clock_offset = clock_snapshot.get("sys_realtime", 0) - clock_snapshot.get("sys_boottime", 0)
#         res.set_clock_snapshot(clock_snapshot)

#         start_ns = None
#         end_ns = None
#         if startts is not None:
#             start_ms = _parse_yyyymmdd_hhmmss(str(startts))
#             start_ns = start_ms * 1_000_000 + clock_offset
#         if endts is not None:
#             end_ms = _parse_yyyymmdd_hhmmss(str(endts))
#             end_ns = end_ms * 1_000_000 + clock_offset

#         symbol_map, file_map = _resolve_data_dict(db_path)

#         with sqlite3.connect(db_path) as conn:
#             try:
#                 _create_native_hook_agg(conn)
#             except sqlite3.OperationalError as e:
#                 logger.warning("native_hook_frame not found in %s: %s", db_path, e)

#             sql = """
#                 SELECT
#                     nh.callchain_id,
#                     nh.event_type,
#                     nh.start_ts,
#                     nh.addr,
#                     nh.heap_size,
#                     nf.result_json,
#                     p.pid,
#                     p.name
#                 FROM native_hook nh
#                 INNER JOIN process p ON nh.ipid = p.ipid
#                 LEFT JOIN native_hook_agg nf ON nh.callchain_id = nf.callchain_id
#                 WHERE 1=1
#             """

#             params: list = []

#             if event_types:
#                 placeholders = ",".join(["?"] * len(event_types))
#                 sql += f" AND nh.event_type IN ({placeholders})"
#                 params.extend(event_types)

#             if start_ns is not None:
#                 sql += " AND nh.start_ts >= ?"
#                 params.append(start_ns)

#             if end_ns is not None:
#                 sql += " AND nh.start_ts <= ?"
#                 params.append(end_ns)
#                 sql += " AND (nh.end_ts = 0 OR nh.end_ts > ?)"
#                 params.append(end_ns)

#             try:
#                 cursor = conn.execute(sql, params)
#                 columns = [desc[0] for desc in cursor.description]
#                 rows = cursor.fetchall()

#                 for row in rows:
#                     row_dict = dict(zip(columns, row))
#                     res.append(row_dict, symbol_map, file_map)

#             except sqlite3.OperationalError as e:
#                 logger.warning("Query failed on %s: %s", db_path, e)

#     return res.to_dict()


# def query_string_table(source_db_dir: str) -> dict[int, str]:

#     db_files = __get_query_dbs(None, source_db_dir)

#     all_rows: dict[int, str] = {}
#     for db_path in db_files:
#         logger.info("Querying data_dict from %s", db_path)

#         with sqlite3.connect(db_path) as conn:
#             conn.row_factory = sqlite3.Row
#             try:
#                 cursor = conn.execute("SELECT id, data FROM data_dict")
#                 for row in cursor.fetchall():
#                     all_rows[row["id"]] = row["data"] or ""
#             except sqlite3.OperationalError as e:
#                 logger.warning("data_dict not found in %s: %s", db_path, e)

#     return all_rows
