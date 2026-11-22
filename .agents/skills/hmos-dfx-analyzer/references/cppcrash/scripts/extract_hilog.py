# Copyright (c) 2021-2026 Huawei Device Co., Ltd.
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
"""Extract HiLog section from a faultlog file.

The HiLog section starts at the first line beginning with "HiLog:" and
continues to the end of the file.
"""
import argparse
import sys


def extract_hilog(faultlog_path: str) -> str:
    with open(faultlog_path, 'r', encoding='utf-8', errors='replace') as f:
        lines = f.readlines()

    for i, line in enumerate(lines):
        if line.lstrip().startswith('HiLog:'):
            return ''.join(lines[i:])
    return ''


def main():
    _configure_output_encoding()
    parser = argparse.ArgumentParser(description='Extract HiLog section from a faultlog file.')
    parser.add_argument('faultlog', help='Path to the faultlog file')
    parser.add_argument('-o', '--output', help='Optional output file (defaults to stdout)')
    args = parser.parse_args()

    try:
        hilog = extract_hilog(args.faultlog)
    except FileNotFoundError:
        print(f"Error: file not found: {args.faultlog}", file=sys.stderr)
        sys.exit(1)
    except OSError as e:
        print(f"Error reading {args.faultlog}: {e}", file=sys.stderr)
        sys.exit(1)

    if not hilog:
        print("No 'HiLog:' section found in the faultlog.", file=sys.stderr)
        sys.exit(2)

    if args.output:
        with open(args.output, 'w', encoding='utf-8') as f:
            f.write(hilog)
        print(f"HiLog extracted to {args.output}")
    else:
        sys.stdout.write(hilog)


def _configure_output_encoding():
    for stream in (sys.stdout, sys.stderr):
        if hasattr(stream, 'reconfigure'):
            stream.reconfigure(encoding='utf-8', errors='replace')


if __name__ == '__main__':
    main()
