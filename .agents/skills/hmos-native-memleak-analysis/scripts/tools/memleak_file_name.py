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
"""Parsers for native memory leak artifact file names."""

import re
from pathlib import Path
from typing import Dict, Optional, Union


PathLike = Union[str, Path]

_NATIVE_SAMPLE_RE = re.compile(
    r"^memleak-native-(?P<process_name>.+)-(?P<pid>\d+)-(?P<kind>sample|smaps)\.txt$"
)
_NATIVE_PROFILE_RE = re.compile(
    r"^memleak-native-(?P<process_name>.+)-(?P<pid>\d+)-(?P<timestamp>\d+)\.txt$"
)
_KERNEL_RE = re.compile(
    r"^memleak-kernel-(?P<hiapp>hiapp-)?(?P<process_name>.+)-"
    r"(?P<pid>\d+)-(?P<timestamp>\d+)\.txt$"
)


def parse_native_file_name(path: PathLike) -> Optional[Dict[str, object]]:
    """Return normalized metadata for a native sample/smaps/profile file."""
    name = Path(path).name
    match = _NATIVE_SAMPLE_RE.fullmatch(name)
    if match:
        return {
            "process_name": match.group("process_name"),
            "pid": match.group("pid"),
            "kind": match.group("kind"),
            "timestamp": None,
        }

    match = _NATIVE_PROFILE_RE.fullmatch(name)
    if not match:
        return None
    return {
        "process_name": match.group("process_name"),
        "pid": match.group("pid"),
        "kind": "profile",
        "timestamp": int(match.group("timestamp")),
    }


def parse_kernel_file_name(path: PathLike) -> Optional[Dict[str, object]]:
    """Return normalized metadata for a kernel memory leak artifact."""
    match = _KERNEL_RE.fullmatch(Path(path).name)
    if not match:
        return None
    return {
        "process_name": match.group("process_name"),
        "pid": match.group("pid"),
        "timestamp": int(match.group("timestamp")),
        "is_hiapp": bool(match.group("hiapp")),
    }
