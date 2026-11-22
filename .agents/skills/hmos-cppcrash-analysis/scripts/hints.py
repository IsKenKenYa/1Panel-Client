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

"""常见崩溃特征匹配。

每条规则 = (匹配函数, 提示文本)。命中的提示会进入报告的【特征匹配提示】小节，
作为大模型分析的线索，不替代人工/模型的根因判断。
规则沉淀自历史问题：JS 堆 OOM、跨线程使用 JS 对象、napi 野指针、
libuv 异步任务生命周期、libuv 句柄关闭（uv_close）误用、fd double close、
XComponent 回调生命周期、sqlite 文件页异常等。
"""

import re
from typing import List

from crash_log import CppCrashLog


def _stack_text(crash: CppCrashLog) -> str:
    return ''.join(frame.raw for frame in crash.fault_stack.frames)


def _first_frame(crash: CppCrashLog) -> str:
    frames = crash.fault_stack.frames
    return frames[0].raw if frames else ''


def _first_matching_frame(crash: CppCrashLog, pattern: str) -> str:
    for frame in crash.fault_stack.frames:
        if re.search(pattern, frame.raw):
            return frame.raw
    return ''


def _is_js_oom(crash: CppCrashLog) -> bool:
    if re.search(r'libark_jsruntime\.so\(.*(HandleUncatchableError|AllocateAlignedRegion|'
                 r'CollectGarbageFinish|ThrowOutOfMemoryError)', _stack_text(crash)):
        return True
    return bool(re.search(r'\[gc].*(Out of Memory|OOM fatal when trying to allocate|'
                          r'pool is empty in GC unexpectedly|SharedHeap OOM)',
                          crash.header.last_fatal_message))


def _is_vm_multi_thread(crash: CppCrashLog) -> bool:
    return bool(re.search(r'Fatal: ecma_vm cannot run in multi-thread!',
                          crash.header.last_fatal_message))


def _has_js_binding_path(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    return bool(re.search(r'libark_jsruntime|libace_napi|napi_|ArkNativeReference|'
                          r'InternalJSMemberFunctionCallback|ThreadSafeCallback|'
                          r'NativeAsyncWork|TaskPool', stack))


def _address_contains_ascii(crash: CppCrashLog) -> bool:
    address = crash.header.crash_address()
    if address is None or address.bit_length() > 64:
        return False
    little_endian = address.to_bytes(8, byteorder='little')
    big_endian = address.to_bytes(8, byteorder='big')
    return bool(re.search(rb'[\x20-\x7e]{4,}', little_endian) or
                re.search(rb'[\x20-\x7e]{4,}', big_endian))


def _is_small_offset_js_crash(crash: CppCrashLog) -> bool:
    address = crash.header.crash_address()
    if address is None or address > 0x1000:
        return False
    stack = _stack_text(crash)
    has_js_access = bool(re.search(r'libark_jsruntime|JSFunction|'
                                   r'InternalJSMemberFunctionCallback|XComponent', stack))
    return has_js_access and _has_js_binding_path(crash)


def _is_ascii_js_object_corruption(crash: CppCrashLog) -> bool:
    return _address_contains_ascii(crash) and _has_js_binding_path(crash)


def _is_napi_object_access_crash(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    has_object_access = bool(re.search(r'napi_wrap|ObjectRef::DefineProperty|'
                                       r'ObjectOperator::AddProperty', stack))
    has_async_path = bool(re.search(r'ThreadSafeCallback|NativeSafeAsyncWork|'
                                    r'NativeAsyncWork|TaskPool', stack))
    return crash.header.crash_address() is not None and has_object_access and has_async_path


def _has_only_gc_runtime_frames(crash: CppCrashLog) -> bool:
    frames = crash.fault_stack.frames
    if not frames:
        return False
    runtime_pattern = (r'libark_jsruntime|libc\.so|libc\+\+|ld-musl|libffrt|'
                       r'Not mapped|Unknown')
    return all(re.search(runtime_pattern, frame.raw) for frame in frames)


def _is_gc_mark_delayed_corruption(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    is_gc_thread = crash.fault_stack.name == 'OS_GC_Thread'
    has_marker = bool(re.search(r'ConcurrentMarker|NonMovableMarker|ProcessMarkStack', stack))
    has_invalid_access = crash.header.signal() in ('SIGSEGV', 'SIGBUS') and \
        crash.header.crash_address() is not None
    return is_gc_thread and has_marker and has_invalid_access and \
        _has_only_gc_runtime_frames(crash)


def _is_gc_move_type_corruption(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    is_gc_thread = crash.fault_stack.name == 'OS_GC_Thread'
    has_mover = bool(re.search(r'EvacuateObject|FullGCRunner|CompressGCMarker', stack))
    has_invalid_type = bool(re.search(r'this branch is unreachable|unreachable type|'
                                      r'illegal.*type',
                                      crash.header.last_fatal_message,
                                      re.IGNORECASE))
    return is_gc_thread and has_mover and has_invalid_type and \
        _has_only_gc_runtime_frames(crash)


def _is_napi_wild_pointer(crash: CppCrashLog) -> bool:
    napi_frame = _first_matching_frame(crash, r'libace_napi\.z\.so.*napi_|ArkNativeReference')
    if not napi_frame:
        return False
    return bool(re.search(r'napi_delete_reference|napi_get_reference_value|'
                          r'napi_get_(undefined|null|boolean)|'
                          r'napi_create_(object|array|int64|int32|uint32|string_\w+|reference)|'
                          r'ArkNativeReference::ArkNativeReference', napi_frame))


def _is_napi_in_worker(crash: CppCrashLog) -> bool:
    has_napi = bool(re.search(r'napi_|ArkNativeReference', _stack_text(crash)))
    worker = bool(re.search(r'OS_(FFRT|IPC)|Worker|TaskPool', crash.fault_stack.name))
    return has_napi and worker


def _is_uv_async_task(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    return 'libuv.so' in stack and \
        bool(re.search(r'uv_ffrt_work|uv_queue_done|uv_queue_work|uv_async_send', stack))


def _is_uv_close_misuse(crash: CppCrashLog) -> bool:
    first = _first_frame(crash)
    return 'libuv.so' in first and \
        bool(re.search(r'uv_run|uv__run_closing_handles|uv__finish_close|'
                       r'uv__queue_remove|uv_close', first))


def _is_fd_double_close(crash: CppCrashLog) -> bool:
    return bool(re.search(r'errno is (9|22)\b', crash.header.last_fatal_message))


def _is_xcomponent_lifecycle(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    return 'XComponentPattern::OnSurfaceDestroyed' in stack or \
        ('libace_ndk.z.so' in stack and 'OH_NativeXComponent' in stack)


def _is_sqlite_bus_error(crash: CppCrashLog) -> bool:
    return 'SIGBUS' in crash.header.signal() and \
        crash.header.signal_code() == 'BUS_OBJERR' and \
        'sqlite' in _stack_text(crash)


def _is_memtracker(crash: CppCrashLog) -> bool:
    stack = _stack_text(crash)
    return 'libmemtracker.so' in stack or 'mem_abort' in stack


def _uncaught_exception_type(crash: CppCrashLog) -> str:
    match = re.search(r'terminating due to uncaught exception of type (\S+)',
                      crash.header.last_fatal_message)
    return match.group(1).rstrip(':') if match else ''


def _is_uncaught_exception(crash: CppCrashLog) -> bool:
    return bool(_uncaught_exception_type(crash))


_HINT_RULES = [
    (_is_uncaught_exception,
     'C++未捕获异常导致abort：LastFatalMessage 给出了异常类型，'
     '请保留 LastFatalMessage 原始信息，根据其中的异常类型提示在崩溃栈/业务代码中定位 '
     'throw 该异常的位置并补充捕获或入参校验'),
    (_is_js_oom,
     'JS堆OOM特征：堆栈/LastFatalMessage 出现 GC OOM 关键字，'
     '请保留 LastFatalMessage 原始信息，根据其中的 OOM 关键字提示定位崩溃原因；'
     '候选原因包括内存泄漏、瞬时峰值、超大分配、堆上限或系统内存压力，需结合内存趋势确认'),
    (_is_vm_multi_thread,
     '跨线程使用JS对象：LastFatalMessage 中包含 ecma_vm cannot run in multi-thread，'
     '请保留 LastFatalMessage 原始信息，根据其中的线程 ID 提示定位崩溃原因；'
     '当前env和相关JS对象具有线程归属，请排查是否在非所属线程直接使用这些对象'),
    (_is_ascii_js_object_corruption,
     'JS对象疑似被踩坏：故障地址包含连续可打印ASCII字节，且调用链存在N-API或JS绑定路径；'
     '这通常是指针或对象字段被字符数据覆盖后的延迟崩溃，优先核对跨线程env，同时排查越界写和UAF'),
    (_is_small_offset_js_crash,
     'JS对象内部指针疑似为空：故障地址为NULL小偏移，且调用链存在JS访问和N-API/绑定路径；'
     '优先核对跨线程env和对象线程归属，同时排查未初始化、提前释放及普通UAF'),
    (_is_napi_object_access_crash,
     'N-API对象操作访问非法地址：异步回调在napi_wrap或对象属性操作中崩溃，可能是跨线程env导致的延迟破坏；'
     '请核对env与目标对象的线程归属，并同步排查对象生命周期、UAF和越界写'),
    (_is_gc_mark_delayed_corruption,
     'GC并发标记阶段访问异常：故障线程只有GC/Runtime帧，通常是更早发生的对象内存破坏在GC阶段延迟爆炸；'
     '不应默认归因于GC自身，优先排查跨线程env，并用线程检测或代码路径确认第一现场'),
    (_is_gc_move_type_corruption,
     'GC搬迁阶段遇到非法对象类型：对象头或类型字段已被破坏的可信度高，当前GC栈不是第一现场；'
     '优先排查跨线程env，并同步排除UAF和越界写'),
    (_is_napi_wild_pointer,
     'N-API接口崩溃特征：调用链包含引用/创建类接口，需联合检查入参、napi_ref/env生命周期、'
     '线程归属和更早的内存破坏证据，不能仅凭该栈定性野指针'),
    (_is_napi_in_worker,
     '工作线程调用链包含N-API：请确认接口是否允许当前线程调用，并核对env、JS对象和回调的线程归属'),
    (_is_uv_async_task,
     'libuv异步任务特征：常见原因是 uv_work_t/napi_async_work/loop 生命周期管理不当'
     '（env 已退出仍触发回调、loop 为空、fd double close），请排查异步任务代码，'
     '详见 references/libuv.md'),
    (_is_uv_close_misuse,
     'libuv句柄关闭特征：栈顶在 libuv.so 的 uv_run/uv__run_closing_handles，'
     '常见原因是忽视 uv_close 的异步语义——uv_close 后 handle 需到 uv__run_closing_handles '
     '执行 close_cb 才真正移除，期间（如析构中 uv_close 后对象即释放）释放 handle 会导致'
     '事件循环访问已释放节点，详见 references/libuv.md'),
    (_is_fd_double_close,
     'fd double close 特征：LastFatalMessage 中 errno=9(EBADF)/22(EINVAL) 是事件循环 fd '
     '被重复关闭的典型表现（遵循谁申请谁释放、透传 fd 不得 close、关闭后置 -1）；'
     '请保留 LastFatalMessage 原始信息，根据其中的 errno 和 fd 信息定位崩溃原因；'
     '若 fd 被同类型复用，回调会触发到错误线程的事件循环，详见 references/libuv.md'),
    (_is_xcomponent_lifecycle,
     'XComponent生命周期特征：疑似在 OnSurfaceDestroyed 前析构回调所在对象，'
     '或回调结束后继续调用 OH_NativeXComponent 接口（裸指针管理），请排查相关生命周期'),
    (_is_sqlite_bus_error,
     'sqlite文件页异常特征：SIGBUS(BUS_OBJERR) + sqlite 栈，'
     '常见原因是使用非数据库接口操作数据库文件（文件锁失效/fd double close）'),
    (_is_memtracker,
     'memtracker监控栈：崩溃由内存检测工具触发，请保留 LastFatalMessage 原始信息，'
     '根据其中的地址信息提示定位崩溃原因；若监控到的内存值为全 e 填充，可能为误报'),
]


def match_hints(crash: CppCrashLog) -> List[str]:
    """返回所有命中的崩溃特征提示。"""
    return [hint for rule, hint in _HINT_RULES if rule(crash)]
