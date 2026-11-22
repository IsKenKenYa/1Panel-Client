# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
# SPDX-License-Identifier: Apache-2.0
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
Native Memory Leak Analyzer (Python Implementation)
用于从 SQLite 数据库查询 native 内存泄露的调用栈信息

功能：
- 查询 Create & Existing（未释放）的内存块
- 按 tid + symbolId + fileId 分组（匹配原项目逻辑）
- 支持按泄露类型过滤
- 支持按内存块大小过滤
- 计算调用栈内存占比
- 支持 JS 堆栈过滤
"""
import os
import sqlite3
import argparse
import subprocess
import sys
import re
from dataclasses import dataclass, field
import platform
from typing import List, Dict, Tuple, Optional, Set
from collections import defaultdict

# JS 相关符号关键字
JS_SYMBOL_KEYWORDS = [
    "JS::", "Js::", "hermes::", "ark::", "JSI::",
    "javascript", "JsStackTrace", "NativeCallback"
]

# JS 相关文件路径关键字
JS_PATH_KEYWORDS = [
    "libark_jsruntime.so", "libhermes.so", "libnode.so", "libuv.so",
    "JavaScriptCore", "v8", "hermes", "ark", "JSGlobal", "JsRt"
]

_JS_SYMBOL_PATTERN = re.compile('|'.join(JS_SYMBOL_KEYWORDS))
_JS_PATH_PATTERN = re.compile('|'.join(JS_PATH_KEYWORDS))

# 内存泄露类型到 event_type 的映射
LEAK_TYPE_TO_EVENT_TYPE = {
    "malloc": "AllocEvent",
    "mmap": "MmapEvent",
    "js_heap": "JS_Alloc",
    "arkts_heap": "ARKTS_Alloc",
    "dart_heap": "DART_HEAP_Alloc",
    "ark_global_handle": "ARK_GLOBAL_HANDLE_Alloc",
    "ark_local_handle": "ARK_LOCAL_HANDLE_Alloc",
    "kmp_heap": "KMP_Alloc",
    "rn_hermes_heap": "RN_HERMES_HEAP_Alloc",
    "so": "SO_Alloc",
    "fd": "FD_Open",
    "thread": "Thread_Create",
    "gpu_vk": "GPU_VK_Alloc",
    "gpu_gles": "GPU_GLES_Alloc",
}

# event_type 到 type 的映射（用于 statistic 表查询）
EVENT_TYPE_TO_TYPE_ID = {
    "AllocEvent": 0,
    "MmapEvent": 1,
    "ARKTS_Alloc": 3,
    "KMP_Alloc": 4,
    "JS_Alloc": 5,
    "DART_HEAP_Alloc": 6,
    "RN_HERMES_HEAP_Alloc": 7,
    "ARK_GLOBAL_HANDLE_Alloc": 8,
    "ARK_LOCAL_HANDLE_Alloc": 9,
    "SO_Alloc": 10,
}


@dataclass
class StackFrame:
    """单个栈帧"""
    depth: int = 0
    ip: int = 0
    symbol_id: int = 0
    file_id: int = 0
    offset: int = 0
    symbol_offset: int = 0
    symbol_name: str = ""
    file_path: str = ""
    is_js_stack: bool = False


@dataclass
class MemoryBlock:
    """单个内存分配事件"""
    callchain_id: int = 0
    pid: int = 0
    tid: int = 0
    addr: int = 0
    mem_size: int = 0
    timestamp: int = 0
    end_timestamp: int = 0
    event_type: str = ""
    sub_type: str = ""
    frames: List[StackFrame] = field(default_factory=list)


@dataclass
class CallChainStats:
    """调用链统计信息"""
    callchain_id: int = 0
    tid: int = 0
    total_size: int = 0
    hit_count: int = 0
    percentage: float = 0.0
    is_js_stack: bool = False
    frames: List[StackFrame] = field(default_factory=list)
    memory_sizes: List[int] = field(default_factory=list)
    stack_key: str = ""  # 用于分组的 key: tid + symbolId + fileId


class NativeMemoryAnalyzer:
    """Native 内存泄露分析器"""

    def __init__(self, db_path: str):
        self.db_path = db_path
        self.conn: Optional[sqlite3.Connection] = None
        self.cursor: Optional[sqlite3.Cursor] = None
        self.data_dict: Dict[int, str] = {}  # string_id -> string_value
        self.frame_cache: Dict[int, List[StackFrame]] = {}  # callchain_id -> frames

    def connect(self):
        """连接到数据库"""
        self.conn = sqlite3.connect(self.db_path)
        self.conn.execute("PRAGMA cache_size = -65536")
        self.conn.execute("PRAGMA temp_store = MEMORY")
        self.conn.execute("PRAGMA mmap_size = 268435456")
        self.conn.execute("PRAGMA synchronous = OFF")
        self.conn.execute("PRAGMA journal_mode = OFF")
        self.cursor = self.conn.cursor()

    def close(self):
        """关闭数据库连接"""
        if self.cursor:
            self.cursor.close()
        if self.conn:
            self.conn.close()

    def load_data_dict(self):
        """加载字符串映射表"""
        self.cursor.execute("SELECT id, data FROM data_dict")
        for row in self.cursor.fetchall():
            self.data_dict[row[0]] = row[1]

    def query_callchain_frames(self, callchain_id: int) -> List[StackFrame]:
        """查询调用链帧"""
        if callchain_id in self.frame_cache:
            return self.frame_cache[callchain_id]

        self.cursor.execute("""
                            SELECT depth, ip, symbol_id, file_id, offset, symbol_offset
                            FROM native_hook_frame
                            WHERE callchain_id = ?
                            ORDER BY depth ASC
                            """, (callchain_id,))

        frames = []
        for row in self.cursor.fetchall():
            frame = StackFrame(
                depth=row[0],
                ip=row[1],
                symbol_id=row[2],
                file_id=row[3],
                offset=row[4],
                symbol_offset=row[5]
            )
            # 解析符号
            frame.symbol_name = self.data_dict.get(frame.symbol_id, "")
            frame.file_path = self.data_dict.get(frame.file_id, "")
            frames.append(frame)

        self.frame_cache[callchain_id] = frames
        return frames

    def batch_query_callchain_frames(self, callchain_ids: List[int]):
        """批量查询调用链帧"""
        if not callchain_ids:
            return

        placeholders = ",".join(["?" for _ in callchain_ids])
        self.cursor.execute(f"""
            SELECT depth, ip, symbol_id, file_id, offset, symbol_offset, callchain_id
            FROM native_hook_frame
            WHERE callchain_id IN ({placeholders})
            ORDER BY callchain_id, depth ASC
        """, callchain_ids)

        frames_map: Dict[int, List[StackFrame]] = defaultdict(list)
        for row in self.cursor.fetchall():
            frame = StackFrame(
                depth=row[0],
                ip=row[1],
                symbol_id=row[2],
                file_id=row[3],
                offset=row[4],
                symbol_offset=row[5]
            )
            # 解析符号
            frame.symbol_name = self.data_dict.get(frame.symbol_id, "")
            frame.file_path = self.data_dict.get(frame.file_id, "")
            frames_map[row[6]].append(frame)

        self.frame_cache.update(frames_map)

    def is_js_stack(self, frames: List[StackFrame]) -> bool:
        """判断是否是 JS 堆栈"""
        if not frames:
            return False

        # 检查顶层帧
        top_frame = frames[0]

        return bool(
            _JS_SYMBOL_PATTERN.search(top_frame.symbol_name) or _JS_SYMBOL_PATTERN.search(top_frame.symbol_name))

    def resolve_frames_symbols(self, frames: List[StackFrame]):
        """解析帧的符号信息"""
        for frame in frames:
            frame.symbol_name = self.data_dict.get(frame.symbol_id, "")
            frame.file_path = self.data_dict.get(frame.file_id, "")

        # 判断是否是 JS 堆栈（只检查顶层帧）
        if frames:
            frames[0].is_js_stack = self.is_js_stack(frames)

    def query_all_memory_blocks(self, event_type_filter: str = "") -> List[MemoryBlock]:
        """
        查询所有未释放的内存块（Create & Existing）

        优先从 native_hook 表查询，如果没有数据则从 native_hook_statistic 表查询
        """
        blocks = []

        # 优先尝试 native_hook 表
        blocks = self._query_from_native_hook(event_type_filter)

        # 如果 native_hook 表没有数据，尝试 native_hook_statistic 表
        if not blocks:
            blocks = self._query_from_native_hook_statistic(event_type_filter)

        return blocks

    def query_memory_blocks_by_sizes(self, sizes: List[int], event_type_filter: str = "") -> List[MemoryBlock]:
        """根据内存块大小查询"""
        if not sizes:
            return []
        blocks = self._query_native_hook_by_sizes(sizes, event_type_filter)
        return blocks or self._query_statistic_by_sizes(sizes, event_type_filter)

    def generate_stack_key(self, frames: List[StackFrame], tid: int) -> str:
        """生成堆栈的唯一键（用于分组）"""
        if not frames:
            return f"{tid}-0-0"

        key = f"{tid}_"
        start_frame = 1 if len(frames) > 1 else 0
        for i in range(start_frame, len(frames)):
            sym_id = frames[i].symbol_id or 2 ** 64 - 1
            file_id = frames[i].file_id or 2 ** 64 - 1
            key += f"{sym_id}_{file_id}"

        alloc_size = 0
        if frames:
            ip = frames[-1].ip
            ALLOC_IP_MASK = 0xFFFFFFFFFFFFFF00
            IP_BIT_MASK = 0xFFFFFFFFFF
            if (ip & ALLOC_IP_MASK) == ALLOC_IP_MASK:
                alloc_size = ip & IP_BIT_MASK
        key += f"_{alloc_size}"
        return key

    def aggregate_by_callchain(self, blocks: List[MemoryBlock], total_memory: int) -> List[CallChainStats]:
        """
        按调用链聚合

        匹配原项目逻辑：按 tid + symbolId + fileId 分组
        """
        stats_map: Dict[str, CallChainStats] = {}

        for block in blocks:
            # 获取调用链帧
            frames = self.frame_cache.get(block.callchain_id, [])
            if frames:
                self.resolve_frames_symbols(frames)

            # 生成堆栈键
            stack_key = self.generate_stack_key(frames, block.tid)

            if stack_key not in stats_map:
                stats = CallChainStats(
                    callchain_id=block.callchain_id,
                    tid=block.tid,
                    total_size=block.mem_size,
                    hit_count=1,
                    frames=frames,
                    is_js_stack=self.is_js_stack(frames) if frames else False,
                    memory_sizes=[block.mem_size],
                    stack_key=stack_key
                )
                stats_map[stack_key] = stats
            else:
                stats_map[stack_key].total_size += block.mem_size
                stats_map[stack_key].hit_count += 1
                stats_map[stack_key].memory_sizes.append(block.mem_size)

        # 计算百分比
        result = []
        for stats in stats_map.values():
            stats.percentage = (stats.total_size / total_memory * 100) if total_memory > 0 else 0
            result.append(stats)

        return result

    def sort_results(self, stats: List[CallChainStats]):
        """排序结果"""
        stats.sort(key=lambda x: x.total_size, reverse=True)

    def filter_by_percentage(self, stats: List[CallChainStats], min_percentage: float) -> List[CallChainStats]:
        """过滤百分比小于阈值的调用栈"""
        return [s for s in stats if s.percentage >= min_percentage]

    def filter_js_stacks(self, blocks: List[MemoryBlock]) -> List[MemoryBlock]:
        """过滤 JS 堆栈"""
        result = []
        for block in blocks:
            frames = self.query_callchain_frames(block.callchain_id)
            if frames:
                self.resolve_frames_symbols(frames)
            if not self.is_js_stack(frames):
                block.frames = frames
                result.append(block)
        return result

    def analyze(self, query_sizes: List[int] = None, leak_type: str = "",
                min_percentage: float = 5.0, max_results: int = 5) -> Dict:
        """执行内存块聚合分析。"""
        # 获取 event_type 过滤值
        event_type_filter = LEAK_TYPE_TO_EVENT_TYPE.get(leak_type, "")

        # 查询所有未释放的内存块
        all_blocks = self.query_all_memory_blocks(event_type_filter)

        if not all_blocks:
            return {
                "success": False,
                "message": "No un-released memory blocks found",
                "total_memory": 0,
                "total_allocations": 0,
                "results": []
            }

        # 计算总内存（使用所有数据）
        total_memory = sum(block.mem_size for block in all_blocks)
        total_allocations = len(all_blocks)

        # 如果指定了内存块大小，则过滤
        blocks = all_blocks
        if query_sizes:
            size_set = set(query_sizes)
            blocks = [b for b in all_blocks if b.mem_size in size_set]

        # 批量加载调用链帧
        callchain_ids = list(set(block.callchain_id for block in blocks))
        self.batch_query_callchain_frames(callchain_ids)

        # 聚合计算
        stats = self.aggregate_by_callchain(blocks, total_memory)

        # 排序
        self.sort_results(stats)

        # 过滤百分比小于指定阈值的调用栈
        stats = self.filter_by_percentage(stats, min_percentage)

        # 限制结果数量
        stats = stats[:max_results]

        return {
            "success": True,
            "total_memory": total_memory,
            "total_allocations": total_allocations,
            "results": self._serialize_stats(stats)
        }

    def format_stack_string(self, frames: List[StackFrame]) -> str:
        """格式化堆栈为字符串（鸿蒙 cppcrash 风格）"""
        if not frames:
            return "unknown"

        # 从叶子到根的顺序输出（栈顶在下）
        stack_parts = []
        for frame in reversed(frames):
            if frame.symbol_name:
                offset = frame.symbol_offset or 0
                if offset > 0:
                    stack_parts.append(f"{frame.symbol_name}+0x{offset:x}")
                else:
                    stack_parts.append(frame.symbol_name)
            else:
                stack_parts.append(f"0x{frame.ip:x}")

        return " <- ".join(stack_parts)

    def _query_from_native_hook(self, event_type_filter: str = "") -> List[MemoryBlock]:
        """从 native_hook 表查询"""
        sql, params = self._native_hook_query(event_type_filter)
        self.cursor.execute(sql, params)
        return self._native_rows_to_blocks(self.cursor.fetchall())

    def _query_from_native_hook_statistic(self, event_type_filter: str = "") -> List[MemoryBlock]:
        """从 native_hook_statistic 表查询

        匹配原项目逻辑：按 callchain_id 和 type 分组聚合
        """
        type_filter = -1
        if event_type_filter:
            type_filter = EVENT_TYPE_TO_TYPE_ID.get(event_type_filter, -1)

        if type_filter >= 0:
            # 按 type 过滤，且只查询 Create & Existing (apply_size > release_size)
            # 使用 GROUP BY callchain_id, type 分组，与原项目逻辑一致
            sql = """
                  SELECT callchain_id, ipid, MAX(apply_size), MAX(release_size), type, sub_type_id
                  FROM native_hook_statistic
                  WHERE type = ?
                    AND apply_size > release_size
                  GROUP BY callchain_id, type
                  ORDER BY (MAX(apply_size) - MAX(release_size)) DESC \
                  """
            params = (type_filter,)
        else:
            # 没有指定类型过滤时，查询所有 Create & Existing
            # 按 callchain_id 和 type 分组聚合
            sql = """
                  SELECT callchain_id, ipid, MAX(apply_size), MAX(release_size), type, sub_type_id
                  FROM native_hook_statistic
                  WHERE apply_size > release_size
                  GROUP BY callchain_id, type
                  ORDER BY (MAX(apply_size) - MAX(release_size)) DESC \
                  """
            params = ()

        self.cursor.execute(sql, params)

        blocks = []
        type_id_to_name = {v: k for k, v in EVENT_TYPE_TO_TYPE_ID.items()}

        for row in self.cursor.fetchall():
            # 使用 MAX(apply_size) - MAX(release_size) 作为未释放的内存大小
            block = MemoryBlock(
                callchain_id=row[0],
                pid=row[1],
                mem_size=row[2] - row[3],  # MAX(apply_size) - MAX(release_size)
                event_type=type_id_to_name.get(row[4], "unknown"),
                sub_type=str(row[5]) if row[5] is not None else ""
            )
            block.end_timestamp = 0
            blocks.append(block)

        return blocks

    def _native_hook_query(self, event_type_filter: str):
        fields = "callchain_id, ipid, itid, addr, heap_size, start_ts, end_ts, event_type, sub_type_id"
        if event_type_filter:
            sql = f"""
                SELECT {fields}
                FROM native_hook
                WHERE end_ts = 0 AND event_type = ?
                ORDER BY heap_size DESC
            """
            return sql, (event_type_filter,)
        sql = f"""
            SELECT {fields}
            FROM native_hook
            WHERE end_ts = 0
            ORDER BY heap_size DESC
        """
        return sql, ()

    def _native_rows_to_blocks(self, rows) -> List[MemoryBlock]:
        return [
            MemoryBlock(
                callchain_id=row[0], pid=row[1], tid=row[2], addr=row[3],
                mem_size=row[4], timestamp=row[5], end_timestamp=row[6],
                event_type=row[7] if row[7] else "",
                sub_type=str(row[8]) if row[8] is not None else "",
            )
            for row in rows
        ]

    def _query_native_hook_by_sizes(self, sizes, event_type_filter):
        placeholders = ",".join("?" for _ in sizes)
        fields = "callchain_id, ipid, itid, addr, heap_size, start_ts, end_ts, event_type, sub_type_id"
        type_clause = " AND event_type = ?" if event_type_filter else ""
        sql = f"""
            SELECT {fields} FROM native_hook
            WHERE heap_size IN ({placeholders}) AND end_ts = 0{type_clause}
            ORDER BY heap_size DESC
        """
        params = tuple(sizes) + ((event_type_filter,) if event_type_filter else ())
        self.cursor.execute(sql, params)
        return self._native_rows_to_blocks(self.cursor.fetchall())

    def _query_statistic_by_sizes(self, sizes, event_type_filter):
        placeholders = ",".join("?" for _ in sizes)
        type_filter = EVENT_TYPE_TO_TYPE_ID.get(event_type_filter, -1) if event_type_filter else -1
        type_clause = " AND type = ?" if type_filter >= 0 else ""
        sql = f"""
            SELECT callchain_id, ipid, apply_size, type, sub_type_id
            FROM native_hook_statistic
            WHERE apply_size IN ({placeholders}) AND apply_size > release_size{type_clause}
            ORDER BY apply_size DESC
        """
        params = tuple(sizes) + ((type_filter,) if type_filter >= 0 else ())
        self.cursor.execute(sql, params)
        return self._statistic_rows_to_blocks(self.cursor.fetchall())

    def _statistic_rows_to_blocks(self, rows) -> List[MemoryBlock]:
        type_names = {value: key for key, value in EVENT_TYPE_TO_TYPE_ID.items()}
        blocks = []
        for row in rows:
            block = MemoryBlock(
                callchain_id=row[0], pid=row[1], mem_size=row[2],
                event_type=type_names.get(row[3], "unknown"),
                sub_type=str(row[4]) if row[4] is not None else "",
            )
            block.end_timestamp = 0
            blocks.append(block)
        return blocks

    def _serialize_stats(self, stats) -> List[Dict]:
        return [
            {
                "callchain_id": stat.callchain_id, "tid": stat.tid,
                "total_size": stat.total_size, "percentage": stat.percentage,
                "hit_count": stat.hit_count,
                "is_js_stack": "JS" if stat.is_js_stack else "Native",
                "stack": self.format_stack_string(stat.frames),
                "memory_blocks": ",".join(str(size) for size in stat.memory_sizes),
                "frames": stat.frames,
            }
            for stat in stats
        ]


def format_stack_trace(frames):
    """格式化堆栈为字符串"""
    if not frames:
        return "    [No stack trace available]\n"

    stack_parts = []
    for i, frame in enumerate(reversed(frames)):
        ip_str = f"0x{frame.ip:016x}" if frame.ip > 0 else " " * 18
        if frame.file_path:
            offset_str = f"+0x{frame.symbol_offset:x}" if frame.symbol_offset else ""
            stack_parts.append(f"   #{i:02d} {ip_str} {frame.file_path}({frame.symbol_name}{offset_str})")
        elif frame.symbol_name:
            stack_parts.append(f"   #{i:02d} {ip_str} {frame.symbol_name}")
        else:
            stack_parts.append(f"   #{i:02d} {ip_str}")

    return "\n".join(stack_parts) + "\n"


def _parse_arguments():
    parser = argparse.ArgumentParser(description="Native Memory Leak Analyzer (Python)")
    parser.add_argument("database", help="SQLite database path")
    parser.add_argument("-s", "--sizes", nargs="+", type=int, help="Memory block sizes to query")
    parser.add_argument("-t", "--type", default="", help="Leak type (js_heap, arkts_heap, malloc, mmap, etc.)")
    parser.add_argument("--min-percentage", type=float, default=5.0, help="Minimum percentage threshold (default: 5.0)")
    parser.add_argument("--max-results", type=int, default=5, help="Maximum number of results (default: 5)")
    return parser.parse_args()


def _prepare_database(profiler_path: str) -> str:
    if not profiler_path.lower().endswith(".txt"):
        return profiler_path
    db_path = os.path.splitext(profiler_path)[0] + ".db"
    streamer_names = {
        "Windows": "trace_streamer_windows.exe",
        "Linux": "trace_streamer_linux",
    }
    streamer_name = streamer_names.get(platform.system(), "trace_streamer_mac")
    streamer_path = os.path.join(os.path.abspath(os.path.dirname(__file__)), streamer_name)
    if not os.path.isfile(streamer_path):
        raise RuntimeError(f"trace_streamer not found: {streamer_path}")
    result = subprocess.run(
        [streamer_path, profiler_path, "-e", db_path], text=True, capture_output=True
    )
    if result.returncode != 0:
        detail = f": {result.stderr.strip()}" if result.stderr else ""
        raise RuntimeError(f"database parse failed{detail}")
    return db_path


def _print_analysis_result(result):
    print(f"Total Sample Memory: {result['total_memory']} bytes\n")
    for index, item in enumerate(result["results"], 1):
        print(f"---- #{index} ---")
        print(
            f"  Memory: {item['total_size']} bytes,{item['percentage']:.2f}%, "
            f"Count: {item['hit_count']}, Type: {item['is_js_stack']}"
        )
        print(f"Block: {item['memory_blocks'].split(',')[0]} bytes")
        print(format_stack_trace(item.get('frames', [])))


def main() -> int:
    args = _parse_arguments()
    try:
        db_path = _prepare_database(args.database)
    except RuntimeError as error:
        print(f"Error: {error}")
        return 1
    analyzer = NativeMemoryAnalyzer(db_path)
    try:
        analyzer.connect()
        analyzer.load_data_dict()
        result = analyzer.analyze(
            query_sizes=args.sizes,
            leak_type=args.type,
            min_percentage=args.min_percentage,
            max_results=args.max_results,
        )
        if not result["success"]:
            print(f"Error: {result['message']}")
            return 1
        _print_analysis_result(result)
        return 0
    except Exception as error:
        print(f"Error: {error}")
        return 1
    finally:
        analyzer.close()


if __name__ == "__main__":
    raise SystemExit(main())
