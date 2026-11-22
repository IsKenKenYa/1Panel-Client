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

import re
import sys
import os
import argparse
from collections import defaultdict
from dataclasses import asdict

sys.path.append(os.path.abspath(os.path.dirname(__file__)))
from freeze.common import fmt_time, parse_time, read_lines
from freeze.stack import parse_frames
from freeze.symbol_alignment import align_sample


def _snapshot_bounds(context, start, end):
    """Find execution and submission ranges within one timestamp block."""
    current_end = end
    submitter_start = None
    submitter_end = end
    for frame_index in range(start, end):
        line = context[frame_index]
        if re.match(r'^\s*(?:=+\s*)?SubmitterStacktrace\s*(?::|=+|$)', line):
            if submitter_start is not None:
                submitter_end = frame_index
                break
            current_end = frame_index
            submitter_start = frame_index + 1
        elif re.match(r'^\s*(?:#?ThreadInfos\b|Tid\s*:|'
                      r'(?:SnapshotEnd|EndSnapshot)\b|'
                      r'Catche stack trace end time:|={3,})', line):
            if submitter_start is None:
                current_end = frame_index
            submitter_end = frame_index
            break
    return current_end, submitter_start, submitter_end


class SampleStackAnalyzer:
    """Standalone sample stack analyzer - processes sample_stacks.txt directly."""

    def __init__(self):
        self.time_stack_dict = {}
        self.submitter_stack_dict = {}
        self.sample_path = ''
        self.cpu_time = 0
        self.statics_dur = 0
        self.cpu_usage = {}
        self.symbol_alignment = {}

    @staticmethod
    def _print_alignment(alignment):
        print(f"\n[Cross-log Symbol Alignment] {alignment['status']}")
        print(f"  Frame counts: {alignment['counts']}")
        for path in alignment['matched_faultlogs']:
            print(f"  Matched faultlog: {path}")
        for rejected in alignment['rejected_faultlogs']:
            print(f"  Skipped: {rejected['path']} ({rejected['reason']})")
        seen = set()
        for frame in alignment['frames']:
            key = (frame['module'], frame['build_id'], frame['pc'],
                   frame['original_symbol'], frame['status'])
            if frame['status'] not in ('filled', 'replaced', 'conflict') or key in seen:
                continue
            seen.add(key)
            print(f"  {frame['status']}: {alignment['sample']}:{frame['line']}")
            print(f"    Original: {frame['raw']}")
            print(f"    Effective: {frame['effective_frame']}")
            for source in frame['sources']:
                print(f"    Source: {source['path']}:{source['line']} {source['symbol']}")

    def build(self, file_path: str, faultlog_paths=None):
        self.__init__()
        self.sample_path = os.path.abspath(file_path)
        context = read_lines(file_path)
        if not context:
            raise ValueError(f'采样栈文件不存在或为空: {file_path}')
        tids = set(re.findall(r'^#ThreadInfos Tid:\s*(\d+)', ''.join(context), re.M))
        if len(tids) > 1:
            raise ValueError('采样文件包含多个 TID，请按目标线程拆分后分析，避免混合聚类')
        basic_statistical_start = 0
        cpu_usage_start = 0
        tid_stack_start = None
        for index, line in enumerate(context):
            if "#Basic Statistical" in line:
                basic_statistical_start = index
            if "#CpuFreq Usage" in line:
                cpu_usage_start = index
            if "#ThreadInfos Tid:" in line and tid_stack_start is None:
                tid_stack_start = index
        tid_stack_start = tid_stack_start if tid_stack_start is not None else 0
        self.basic_statistical_build(context[basic_statistical_start:cpu_usage_start])
        self.cpu_usage_build(context[cpu_usage_start:tid_stack_start])
        self.build_time_stack(context[tid_stack_start:], tid_stack_start + 1)
        frames = [frame for stack in self.time_stack_dict.values() for frame in stack]
        self.symbol_alignment = align_sample(file_path, context, frames, faultlog_paths)
        return self

    def basic_statistical_build(self, context):
        statics_dur_res = re.compile(r"^StaticsDuration:\s+(\d+)\s+ms")
        cpu_time_res = re.compile(r"^CpuTime:\s+(\d+)\s+ms")
        for line in context:
            if statics_dur_res.search(line):
                self.statics_dur = float(statics_dur_res.search(line).group(1))
            if cpu_time_res.search(line):
                self.cpu_time = float(cpu_time_res.search(line).group(1))

    def cpu_usage_build(self, context):
        cpu_use_res = re.compile(r"^cpu(\d+) Usage (\d+.\d+)%")
        for line in context:
            match = cpu_use_res.search(line)
            if match:
                self.cpu_usage[match.group(1)] = float(match.group(2))

    def build_time_stack(self, context, start_line=1):
        index_list = []
        time_stamp_list = []
        for index, line in enumerate(context):
            if "Timestamp:" in line or "SnapshotTime:" in line:
                time_stamp = line.split(":", 1)[-1].strip()
                index_list.append(index)
                time_stamp_list.append(parse_time(time_stamp))
        for index, value in enumerate(index_list):
            if time_stamp_list[index] is None:
                continue
            if time_stamp_list[index] in self.time_stack_dict:
                raise ValueError('采样时间戳重复，无法唯一标识 Snapshot')
            end = index_list[index + 1] if index + 1 < len(index_list) else len(context)
            current_end, submitter_start, submitter_end = _snapshot_bounds(context, value + 1, end)
            timestamp = time_stamp_list[index]
            self.time_stack_dict[timestamp] = parse_frames(
                context[value + 1:current_end], start_line + value + 1
            )
            # Preserve asynchronous origin independently; it is never passed to
            # align_sample or used in execution hotspots / full-stack clusters.
            self.submitter_stack_dict[timestamp] = (
                parse_frames(context[submitter_start:submitter_end], start_line + submitter_start)
                if submitter_start is not None else []
            )

    def analyze(self) -> dict:
        """Perform analysis and return result dictionary."""
        result = {
            "basic_info": {
                "cpu_time": self.cpu_time,
                "statics_dur": self.statics_dur,
                "cpu_usage": self.cpu_usage,
                "snapshot_count": len(self.time_stack_dict),
            },
            "parent_node_stats": [],
            "snapshot_details": [],
            "symbol_alignment": self.symbol_alignment,
            "stack_clusters": [],
        }

        parent_node_dict = defaultdict(list)
        snapshot_business_chains = {}
        stack_clusters = {}

        for timestamp, frames in sorted(self.time_stack_dict.items()):
            # Full stack clustering happens after alignment, including system
            # frames. The existing business-parent statistics remain available.
            key = tuple(frame.cluster_key for frame in frames)
            if frames:
                cluster = stack_clusters.setdefault(key, {
                    "stack": [frame.effective_brief for frame in frames],
                    "count": 0, "timestamps": [],
                })
                cluster["count"] += 1
                cluster["timestamps"].append(timestamp.isoformat())
            result["snapshot_details"].append({
                "timestamp": timestamp.isoformat(),
                "frames": [dict(asdict(frame), effective_frame=frame.effective_brief)
                           for frame in frames],
                "submitter_frames": [dict(asdict(frame), source_path=self.sample_path)
                                     for frame in self.submitter_stack_dict.get(timestamp, [])],
            })
            business_chain = []
            parent_node = None

            for stack_frame in reversed(frames):
                if stack_frame.area == "system":
                    continue
                if "anonymous" in stack_frame.effective_brief:
                    continue
                if parent_node is None:
                    parent_node = stack_frame.effective_brief
                business_chain.append(stack_frame.effective_brief)

            if parent_node:
                parent_node_dict[parent_node].append(timestamp)
                snapshot_business_chains[timestamp] = {
                    "parent_node": parent_node,
                    "business_chain": list(reversed(business_chain))
                    if business_chain
                    else [],
                }

        sorted_parent_nodes = sorted(
            parent_node_dict.items(), key=lambda x: len(x[1]), reverse=True
        )

        for parent_node, timestamps in sorted_parent_nodes:
            count = len(timestamps)
            snapshots = []
            for ts in sorted(timestamps):
                if ts in snapshot_business_chains:
                    chain_info = snapshot_business_chains[ts]
                    snapshots.append(
                        {
                            "timestamp": fmt_time(ts),
                            "parent_node": chain_info["parent_node"],
                            "business_chain": chain_info["business_chain"],
                        }
                    )
            result["parent_node_stats"].append(
                {
                    "parent_node": parent_node,
                    "count": count,
                    "total_snapshots": len(self.time_stack_dict),
                    "snapshots": snapshots,
                }
            )

        result["stack_clusters"] = sorted(stack_clusters.values(),
                                          key=lambda cluster: cluster["count"], reverse=True)
        return result

    def print_report(self, result: dict):
        """Print analysis report."""
        print("=" * 80)
        print("Sample Stack Analysis Report")
        print("=" * 80)

        basic = result["basic_info"]
        print(f"\n[Basic Info]")
        print(f"  Statics Duration: {basic['statics_dur']:.0f} ms")
        print(f"  Process CPU Time: {basic['cpu_time']:.0f} ms")
        print(
            f"  CPU Time Ratio: {basic['cpu_time'] * 100 / basic['statics_dur']:.2f}%"
            if basic['statics_dur'] else "  CPU Time Ratio: unavailable"
        )
        print(
            f"  CPU Usage: {', '.join([f'cpu{k}: {v}%' for k, v in basic['cpu_usage'].items()])}"
        )
        print(f"  Total Snapshots: {basic['snapshot_count']}")

        self._print_alignment(result['symbol_alignment'])

        print("\n[Aligned Full Stack Clusters] (each snapshot counts once)")
        for index, cluster in enumerate(result['stack_clusters'], 1):
            print(f"  Cluster {index}: {cluster['count']} snapshots")
            print(f"    Times: {', '.join(cluster['timestamps'])}")
            for frame in cluster['stack']:
                print(f"    {frame}")

        print(f"\n[Parent Node Business Function Stats] (each snapshot counts once)")
        print("-" * 80)

        for i, stat in enumerate(result["parent_node_stats"], 1):
            print(f"\n{i}. Parent Node: {stat['parent_node']}")
            print(
                f"   Occurrences: {stat['count']} / {stat['total_snapshots']} snapshots"
            )
            print(
                f"   Total Time: {stat['count'] * 300} ms (= {stat['count']} x 300ms)"
            )

            for snap in stat["snapshots"]:
                print(f"\n   Snapshot {snap['timestamp']}:")
                for j, func in enumerate(snap["business_chain"]):
                    prefix = "  -> " if j == 0 else "     "
                    print(f"{prefix}{func}")

        submitter_snapshots = [s for s in result['snapshot_details'] if s['submitter_frames']]
        if submitter_snapshots:
            print("\n[Async Submission Context — not sampled execution]")
            print("  仅用于追溯异步任务来源；不参与当前执行栈符号对齐、热点或聚类。")
            for snapshot in submitter_snapshots:
                print(f"  Snapshot {snapshot['timestamp']}:")
                for frame in snapshot['submitter_frames']:
                    print(f"    {frame['source_path']}:{frame['source_line']} {frame['raw'].rstrip()}")


def main():
    parser = argparse.ArgumentParser(description='采样栈分析与跨日志符号对齐')
    parser.add_argument('sample', help='cpuinfo-ext / sample_stacks 文件')
    args = parser.parse_args()
    try:
        analyzer = SampleStackAnalyzer().build(args.sample)
        result = analyzer.analyze()
        analyzer.print_report(result)
    except (ValueError, OSError) as err:
        parser.exit(1, f'采样栈分析失败：{err}\n')


if __name__ == "__main__":
    main()
