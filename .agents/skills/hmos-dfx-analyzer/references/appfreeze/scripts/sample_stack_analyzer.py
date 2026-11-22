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
from collections import defaultdict

sys.path.append(os.path.abspath(os.path.dirname(__file__)))
from freeze.common import fmt_time, parse_time, read_lines
from freeze.stack import parse_frames


class SampleStackAnalyzer:
    """Standalone sample stack analyzer - processes sample_stacks.txt directly."""

    def __init__(self):
        self.time_stack_dict = {}
        self.cpu_time = 0
        self.statics_dur = 0
        self.cpu_usage = {}

    def build(self, file_path: str):
        context = read_lines(file_path)
        basic_statistical_start = 0
        cpu_usage_start = 0
        tid_stack_start = 0
        for index, line in enumerate(context):
            if "#Basic Statistical" in line:
                basic_statistical_start = index
            if "#CpuFreq Usage" in line:
                cpu_usage_start = index
            if "#ThreadInfos Tid:" in line:
                tid_stack_start = index
        self.basic_statistical_build(context[basic_statistical_start:cpu_usage_start])
        self.cpu_usage_build(context[cpu_usage_start:tid_stack_start])
        self.build_time_stack(context[tid_stack_start:])
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

    def build_time_stack(self, context):
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
            if index == len(index_list) - 1:
                self.time_stack_dict[time_stamp_list[index]] = parse_frames(
                    context[value + 1 :]
                )
                break
            self.time_stack_dict[time_stamp_list[index]] = parse_frames(
                context[value + 1 : index_list[index + 1]]
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
        }

        parent_node_dict = defaultdict(list)
        snapshot_business_chains = {}

        for timestamp, frames in sorted(self.time_stack_dict.items()):
            business_chain = []
            parent_node = None

            for stack_frame in reversed(frames):
                if stack_frame.area == "system":
                    continue
                if "anonymous" in stack_frame.brief:
                    continue
                if parent_node is None:
                    parent_node = stack_frame.brief
                business_chain.append(stack_frame.brief)

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
        )
        print(
            f"  CPU Usage: {', '.join([f'cpu{k}: {v}%' for k, v in basic['cpu_usage'].items()])}"
        )
        print(f"  Total Snapshots: {basic['snapshot_count']}")

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


def main():
    if len(sys.argv) < 2:
        print("Usage: python sample_stack_analyzer.py <sample_stacks.txt path>")
        sys.exit(1)

    file_path = sys.argv[1]
    if not os.path.exists(file_path):
        print(f"File not found: {file_path}")
        sys.exit(1)

    analyzer = SampleStackAnalyzer()
    analyzer.build(file_path)
    result = analyzer.analyze()
    analyzer.print_report(result)


if __name__ == "__main__":
    main()
