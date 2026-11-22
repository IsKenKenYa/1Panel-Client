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
"""线程堆栈解析：把 'Tid:xxx, Name:yyy' + 栈帧文本解析为结构化对象。"""

import re
from dataclasses import dataclass, field
from typing import Dict, List

# 'Tid:20020, Name:com.example.app'
THREAD_HEADER_RE = re.compile(r'^Tid:(?P<tid>\d+)(?:,|\s)+Name:(?P<name>.*)')
# native 帧：'#02 pc 0000000000123456 /system/lib64/libipc_common.z.so(Func+100)(buildid)'
NATIVE_FRAME_RE = re.compile(r'^#\d+ [\w\s]+ .*')
# js/ets 帧：'at funcName (entry/src/main/ets/pages/Index.ets:42:8)'
JS_FRAME_RE = re.compile(r'at\s+(\w+)\s+\((.*\.\w+):\d+:\d+\)')

# 等锁特征：这些函数出现在 libc/musl 帧中说明线程在等锁/等条件变量
_LOCK_WAIT_RE = re.compile(r'mutex_lock|unique_lock|lock_guard|mutex_timedlock|pthread_cond_timedwait')
_SYSTEM_LIB_RE = re.compile(r'libc\.so|libc\+\+|ld-musl-|libutils|libsec_shared')

# 抓栈失败时 faultlog 中的报错关键字及其含义
_STACK_ERROR_HINTS = [
    (r'has been crashed', '目标进程Crash：抓栈时进程已收到crash，请参考附近时间点的Crash日志'),
    (r'SIGDUMP error', '目标进程在dump堆栈前就已经退出'),
    (r'is dumping', '目标进程正在dump，短时间内连续请求，请参考附近时间点该进程的其他报错日志'),
    (r'State:\tS \(sleeping\)', 'dump堆栈时进程正在睡眠'),
    (r'errno\(2\)', '目标进程无响应信号，超时后已经退出'),
    (r'pid\(\d+\) process has exited', 'dump堆栈失败，进程已经退出'),
    (r'Failed to dump normal stacktrace', '正常抓栈失败'),
]


@dataclass
class StackFrame:
    """单个栈帧。"""
    raw: str            # 原始帧文本
    brief: str = ''     # 去掉编号/pc地址/buildid 后的简化帧
    file_name: str = ''  # so 名或 ets/ts 文件名
    function_name: str = ''
    is_native: bool = True
    area: str = 'other'  # system / app / other，用于过滤系统帧

    @staticmethod
    def build(line: str) -> 'StackFrame':
        frame = StackFrame(raw=line)
        parts = line.split()
        frame.is_native = len(parts) > 1 and parts[1] == 'pc'
        if frame.is_native:
            frame._build_native(parts)
        else:
            frame._build_js()
        return frame

    def _build_native(self, parts: List[str]):
        # 去掉 '#NN pc xxxxxxxx' 前缀和末尾 '(buildid)' 后缀
        brief = re.sub(r'^#\d+ pc \w+', '', self.raw)
        brief = re.sub(r'\([\da-fA-F]{16,}\)', '', brief).strip()
        self.brief = brief
        so_uri = brief.split('(')[0].strip()
        self.file_name = so_uri.split('/')[-1]
        func_split = re.split(r'[(<\[]', brief)
        if len(func_split) > 1:
            self.function_name = func_split[1].split('+')[0].strip()
        if len(parts) > 3 and parts[3].startswith(('/system', '/vendor', '/prod')):
            self.area = 'system'
        elif 'libarkweb_engine.so' in self.raw or '[shmm]' in self.raw:
            self.area = 'system'
        elif len(parts) > 3 and parts[3].startswith('/data'):
            self.area = 'app'

    def _build_js(self):
        # js 帧保留 文件:行:列，便于业务直接定位代码位置
        self.brief = re.sub(r'^#\d+', '', self.raw).strip()
        match = JS_FRAME_RE.search(self.raw)
        if match:
            self.function_name = match.group(1)
            self.file_name = match.group(2).split('/')[-1]
        self.area = 'system' if '/foundation/arkui' in self.raw else 'app'


@dataclass
class ThreadStack:
    """一个线程的完整堆栈。"""
    tid: str = ''
    name: str = ''
    frames: List[StackFrame] = field(default_factory=list)

    def brief_str(self, max_frames: int = None) -> str:
        """输出 'Tid:x, Name:y' + 简化栈帧，调用方向从栈顶(#00)到栈底。"""
        header = f'Tid:{self.tid}, Name:{self.name}'.rstrip() + '\n'
        frames = self.frames if max_frames is None else self.frames[:max_frames]
        if not frames:
            return header + '未获取到该线程堆栈\n'
        body = ''.join(f'#{index:02d} {frame.brief}\n' for index, frame in enumerate(frames))
        if max_frames is not None and len(self.frames) > max_frames:
            body += f'...（其余 {len(self.frames) - max_frames} 帧省略）\n'
        return header + body

    def is_lock_waiting(self) -> bool:
        """判断栈顶是否呈现等锁特征。"""
        for frame in self.frames:
            if _SYSTEM_LIB_RE.search(frame.raw) and _LOCK_WAIT_RE.search(frame.raw):
                return True
        if len(self.frames) > 2 \
                and self.frames[0].brief == '/lib/ld-musl-aarch64.so.1' \
                and self.frames[1].brief == '/lib/ld-musl-aarch64.so.1':
            return True
        return False

    def has_ipc_wait(self) -> bool:
        """判断该线程是否阻塞在 binder 同步调用上（IPC 栈）。"""
        text = ''.join(frame.raw for frame in self.frames)
        return bool(re.search(r'libipc_common\.z\.so.*WriteBinder', text)
                    and re.search(r'libipc_(core|single)\.z\.so.*(TransactWithDriver|WaitForCompletion)', text))


def parse_frames(lines: List[str]) -> List[StackFrame]:
    """从若干行文本中解析出所有栈帧（native + js）。"""
    frames = []
    for line in lines:
        if NATIVE_FRAME_RE.search(line) or JS_FRAME_RE.search(line):
            frames.append(StackFrame.build(line))
    return frames


def parse_thread_stacks(lines: List[str]) -> Dict[str, ThreadStack]:
    """把一段堆栈文本按 'Tid:xxx, Name:yyy' 拆分为 {tid: ThreadStack}。"""
    stacks: Dict[str, ThreadStack] = {}
    current: ThreadStack = None
    for line in lines:
        header_match = THREAD_HEADER_RE.search(line)
        if header_match:
            current = ThreadStack(tid=header_match.group('tid'),
                                  name=header_match.group('name').strip())
            stacks[current.tid] = current
            continue
        if current and (NATIVE_FRAME_RE.search(line) or JS_FRAME_RE.search(line)):
            current.frames.append(StackFrame.build(line))
    return stacks


def extract_stack_errors(lines: List[str]) -> List[str]:
    """提取抓栈失败的报错行及其含义说明。"""
    errors = []
    seen = set()
    for line in lines:
        for pattern, hint in _STACK_ERROR_HINTS:
            if re.search(pattern, line):
                text = line.strip()
                if text not in seen:
                    seen.add(text)
                    errors.append(f'{text} （{hint}）')
    return errors
