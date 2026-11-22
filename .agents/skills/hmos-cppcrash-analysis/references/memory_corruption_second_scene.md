# 踩内存（aimm: illegal memory modification）第2现场定界参考手册

---

## 一、ld-musl-aarch64.so库

### jemalloc模块元数据被踩写损坏

#### 前置：典型cppcrash相关栈

**案例**

```text
#00 pc 00000000000f0068 /system/lib/ld-musl-aarch64.so.1(edata_heap_remove+616)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#01 pc 00000000000f3b5c /system/lib/ld-musl-aarch64.so.1(eset_remove+268)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#02 pc 00000000000f4430 /system/lib/ld-musl-aarch64.so.1(extent_recycle+364)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#03 pc 000000000012c2a8 /system/lib/ld-musl-aarch64.so.1(pac_alloc_real+104)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#04 pc 00000000000fdbc8 /system/lib/ld-musl-aarch64.so.1(pac_alloc_impl+192)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#05 pc 00000000000e0720 /system/lib/ld-musl-aarch64.so.1(arena_slab_alloc+144)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#06 pc 00000000000e018c /system/lib/ld-musl-aarch64.so.1(arena_cache_bin_fill_small+620)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#07 pc 00000000001044f8 /system/lib/ld-musl-aarch64.so.1(je_tcache_alloc_small_hard+256)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#08 pc 00000000000bc5a4 /system/lib/ld-musl-aarch64.so.1(malloc_default+4600)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#09 pc 00000000000bdad8 /system/lib/ld-musl-aarch64.so.1(je_malloc+884)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#10 pc 00000000001f8b74 /system/lib/ld-musl-aarch64.so.1(malloc+72)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
```

#### 规则

1. 崩溃信号为 `SIGSEGV(SEGV_MAPERR)`、`SIGSEGV(SEGV_ACCERR)` 或 `SIGBUS(BUS_ADRALN)`。
2. `#00` 栈特征为 `edata_heap_remove` 或 `emap_update_edata_state`。

#### 定界结论

踩内存的第2现场。

#### 原因

jemalloc属于底层系统模块，非常稳定。根据经验数据，崩溃栈中 `#00` 栈是此类特征时，基本上是其他模块非法踩写jemalloc元数据导致。

### jemalloc释放后内存被访问，导致崩溃

#### 前置：典型cppcrash相关栈

**案例**

```text
Reason:Signal:SIGSEGV(SEGV_MAPERR)@0x006b9cacf62f37a1
Fault thread info:
Tid:52019, Name:ecom.esmarthome
#00 pc 000000000102102c /system/lib64/platformsdk/libace_compatible.z.so(OHOS::Ace::NG::WaterFlowLayoutUtils::GetUserDefHeight(OHOS::Ace::RefPtr<OHOS::Ace::NG::WaterFlowSections> const&, int, int)+136)(c4a1ba26998bbf4a8ba076c9c02215df)
#01 pc 0000000001246fa8 /system/lib64/platformsdk/libace_compatible.z.so(OHOS::Ace::NG::WaterFlowSegmentedLayout::MeasureToTarget(int, std::__h::optional<long>, bool)+288)(c4a1ba26998bbf4a8ba076c9c02215df)
#02 pc 0000000001246dd4 /system/lib64/platformsdk/libace_compatible.z.so(OHOS::Ace::NG::WaterFlowSegmentedLayout::PreloadItem(OHOS::Ace::NG::LayoutWrapper*, int, long)+120)(c4a1ba26998bbf4a8ba076c9c02215df)
#03 pc 00000000010beaa0 /system/lib64/platformsdk/libace_compatible.z.so(c4a1ba26998bbf4a8ba076c9c02215df)
```

#### 规则

1. 崩溃信号为 `SIGSEGV(SEGV_MAPERR)` 或 `SIGBUS(BUS_ADRALN)`。
2. 崩溃地址以 `0x006b` 或 `0x6b6b` 开头。
3. `#00` 栈为系统栈，路径特征为 `/system/lib64/`。

#### 定界结论

踩内存的第2现场。

#### 原因

`0x006b` 是jemalloc对已释放内存的填充值。由于访问此类地址触发的崩溃问题，大概率是UAF踩内存导致的第2现场。

---

### jemalloc检测到重复释放（cache_bin_dalloc_safety_checks）

#### 前置：典型CPPCRASH相关日志

**案例**
```
Reason:Signal:SIGTRAP(TRAP_BRKPT)@0x0000005aa2af4db4
LastFatalMessage:This is an unexpected memory usage behavior.may double free
Fault thread info:
Tid:22476, Name:etccst.chengxun
#00 pc 00000000000b5db4 /system/lib/ld-musl-aarch64.so.1(cache_bin_dalloc_safety_checks+116)(35422f66114500c7d794bf84b3fd302b)
#01 pc 00000000000c28a4 /system/lib/ld-musl-aarch64.so.1(je_free+416)(35422f66114500c7d794bf84b3fd302b)
#02 pc 000000000003ed60 /system/lib64/platformsdk/libace_napi.z.so(NativeSafeAsyncWork::CleanUp()+176)(007d3dfdfbceca6f770655c180be87b0)
#03 pc 000000000001ba6c /system/lib64/platformsdk/libuv.so(uv_run+1536)
```

#### 规则

1. 崩溃信号为`SIGTRAP(TRAP_BRKPT)`
2. `LastFatalMessage`或`Abort message`包含 **"may double free"** 或 **"unexpected memory usage behavior"**
3. #00栈特征为 **cache_bin_dalloc_safety_checks**
4. 调用栈通常经过 je_free → free_default 路径，属于内存释放过程中jemalloc安全检查机制检测到重复释放

#### 定界结论

踩内存的第2现场。属于**double free**问题。

#### 原因

jemalloc内置了安全检查机制（cache_bin_dalloc_safety_checks），当检测到同一块内存被重复释放时会主动触发SIGTRAP终止进程。这类崩溃表明上层模块存在double free问题，即对同一块内存执行了多次free操作。

**排查方向**：跳过musl栈帧，找调用方首栈排查是否存在重复释放。如果报栈都是musl栈，这种情况基本都是在线程退出流程，需要找进程模块排查。建议开启asan压测复现。

---

### jemalloc检测到重复释放（je_arena_dalloc_small）

#### 前置：典型CPPCRASH相关日志

**案例1 - 带double free提示（SIGTRAP）**
```
Reason:Signal:SIGTRAP(TRAP_BRKPT)@0x00000059b8e12588
LastFatalMessage:This is an unexpected memory usage behavior.may double free
Fault thread info:
Tid:41499, Name:com.amap.hmapp
#00 pc 00000000000b6588 /system/lib/ld-musl-aarch64.so.1(je_arena_dalloc_small+496)(35422f66114500c7d794bf84b3fd302b)
#01 pc 00000000000c1718 /system/lib/ld-musl-aarch64.so.1(free_default+1976)(35422f66114500c7d794bf84b3fd302b)
#02 pc 0000000000b2a620 /system/lib64/platformsdk/libace_compatible.z.so(OHOS::Ace::NG::FlexLayoutProperty::~FlexLayoutProperty()+108)
```

**案例2 - SIGSEGV异常（元数据被踩写）**
```
Reason:Signal:SIGSEGV(SEGV_MAPERR)@000000000000000000 probably caused by NULL pointer dereference
Fault thread info:
Tid:22476, Name:etccst.chengxun
#00 pc 00000000000ad024 /system/lib/ld-musl-aarch64.so.1(je_arena_dalloc_small+108)(74af18f25df370c42380f0e9415a82a2)
#01 pc 00000000000b8580 /system/lib/ld-musl-aarch64.so.1(free_default+2560)(74af18f25df370c42380f0e9415a82a2)
#02 pc 00000000000100f4 /system/lib64/chipset-sdk-sp/libbegetutil.z.so
```

#### 规则

1. 崩溃信号为`SIGTRAP(TRAP_BRKPT)`或`SIGSEGV(SEGV_MAPERR)`
2. #00栈特征为 **je_arena_dalloc_small**
3. 若信号为SIGTRAP，通常伴随`LastFatalMessage`包含 **"may double free"**，表示jemalloc安全检查检测到重复释放
4. 若信号为SIGSEGV，表示jemalloc内部元数据已被踩写，在释放内存时访问到非法地址

#### 定界结论

- 信号为SIGTRAP时：踩内存的第2现场。属于**double free**问题。
- 信号为SIGSEGV时：踩内存的第2现场。属于**踩内存**问题。

#### 原因

当信号为SIGTRAP时，jemalloc的arena释放安全检查机制检测到同一块内存被重复释放（double free），主动终止进程。当信号为SIGSEGV时，jemalloc的arena内部管理数据已被其它模块非法踩写，导致在执行小内存释放操作时访问非法地址。

**排查方向**：
- **double free（SIGTRAP）**：跳过musl栈帧，找调用方首栈排查是否存在重复释放。如果报栈都是musl栈，这种情况基本都是在线程退出流程，需要找进程模块排查。建议开启asan压测复现。
- **踩内存（SIGSEGV）**：此问题发生在free流程中，需跳过musl栈帧找调用方首栈排查。建议开启asan压测复现。

---

### jemalloc tcache flush异常（je_tcache_bin_flush_small）

#### 前置：典型CPPCRASH相关日志

**案例1 - #00为raise，#01为je_tcache_bin_flush_small（double free）**
```
Reason:Signal:SIGSEGV(SI_TKILL)@0x01317bdb0000f464 from:62564:20020187
LastFatalMessage:This is an unexpected memory usage behavior.[NAPI] Crash occured on ProcessAll, callback: 386515829180
Fault thread info:
Tid:62564, Name:.netease.ohmail
#00 pc 000000000019ca00 /system/lib/ld-musl-aarch64.so.1(raise+228)(f77c0346c0084ebbadf721ea319f5f77)
#01 pc 00000000000f05d8 /system/lib/ld-musl-aarch64.so.1(je_tcache_bin_flush_small+1284)(f77c0346c0084ebbadf721ea319f5f77)
#02 pc 00000000000ae95c /system/lib/ld-musl-aarch64.so.1(free_default+1412)(f77c0346c0084ebbadf721ea319f5f77)
#03 pc 00000000002346a8 /system/lib64/chipset-pub-sdk/libcrypto_openssl.z.so(op_cache_free+24)
```

**案例2 - 线程退出时tcache清理异常（报栈都是musl栈）**
```
Abort message:This is an unexpected memory usage behavior.may double free
Fault thread info:
Tid:44058, Name:OS_FFRT_3_14
#00 pc 00000000000adcb4 /system/lib/ld-musl-aarch64.so.1(je_tcache_bin_flush_small+1344)
#01 pc 00000000000fce44 /system/lib/ld-musl-aarch64.so.1(tcache_destroy+620)
#02 pc 00000000000ff5d8 /system/lib/ld-musl-aarch64.so.1(je_tsd_cleanup+288)
#03 pc 0000000000125990 /system/lib/ld-musl-aarch64.so.1(tsd_cleanup_wrapper+36)
#04 pc 00000000001d25ec /system/lib/ld-musl-aarch64.so.1(__pthread_tsd_run_dtors+184)
#05 pc 00000000001d0014 /system/lib/ld-musl-aarch64.so.1(pthread_exit+80)
```

**案例3 - SIGTRAP（double free检测）**
```
Reason:Signal:SIGTRAP(TRAP_BRKPT)@0x0000005b529e45b4
LastFatalMessage:This is an unexpected memory usage behavior.may double free
Fault thread info:
Tid:44058, Name:OS_FFRT_3_14
#00 pc 00000000000b85b4 /system/lib/ld-musl-aarch64.so.1(je_tcache_bin_flush_small+1344)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#01 pc 00000000000c2b34 /system/lib/ld-musl-aarch64.so.1(free_default+1396)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#02 pc 0000000001f01810 /system/lib64/platformsdk/libace_compatible.z.so(OHOS::Ace::NG::UINode::ExecuteAfterAttachMainTreeTasks()+128)
```

#### 规则

1. 崩溃信号为`SIGSEGV(SI_TKILL)`或`SIGTRAP(TRAP_BRKPT)`
2. `LastFatalMessage`或`Abort message`包含 **"unexpected memory usage behavior"** 或 **"may double free"**
3. #00栈特征为 **je_tcache_bin_flush_small**（当#00为raise时，#01为je_tcache_bin_flush_small也满足）
4. 属于jemalloc tcache刷新过程中检测到内存异常

#### 定界结论

踩内存的第2现场。属于**double free**问题。

#### 原因

jemalloc的tcache（thread-local cache）是每个线程的本地内存缓存。当jemalloc在tcache刷新过程中检测到异常时（如同一块内存被重复释放），会主动触发raise(SIGSEGV)或SIGTRAP终止进程。

**排查方向**：跳过musl栈帧，找调用方首栈排查是否存在重复释放。如果报栈都是musl栈（如案例2，在线程退出流程中tcache_destroy → je_tsd_cleanup），这种情况基本都是在线程退出流程，需要找进程模块排查。建议开启asan压测复现。

---

### jemalloc tcache stash刷新异常（tcache_bin_flush_stashed）

#### 前置：典型CPPCRASH相关日志

**案例**
```
Signal:SIGSEGV(SEGV_MAPERR)@0xffffffffffffff60
Thread name:CompositorGpuTh
#00 pc 00000000000fa048 /system/lib/ld-musl-aarch64.so.1(tcache_bin_flush_stashed+208)(6dfe4ecea22714b3e8fc8be36e2d9484)
#01 pc 00000000000ad7b0 /system/lib/ld-musl-aarch64.so.1(je_tcache_bin_flush_small+60)(6dfe4ecea22714b3e8fc8be36e2d9484)
#02 pc 00000000000b8234 /system/lib/ld-musl-aarch64.so.1(free_default+1396)(6dfe4ecea22714b3e8fc8be36e2d9484)
#03 pc 000000000020bf74 /vendor/lib64/passthrough/libmaleoon_v300.so
```

#### 规则

1. 崩溃信号为`SIGSEGV(SEGV_MAPERR)`或`SIGSEGV(SEGV_ACCERR)`
2. #00栈特征为 **tcache_bin_flush_stashed**
3. 调用栈通常经过 je_tcache_bin_flush_small → free_default 路径，属于内存释放过程中tcache stash队列元数据被踩写

#### 定界结论

踩内存的第2现场。属于**踩内存**问题。

#### 原因

jemalloc的tcache_bin_flush_stashed函数负责将tcache中被暂存（stashed）的内存块刷新回arena。当该数据结构被其它模块非法踩写后，在执行刷新操作时访问到非法地址（如0xffffffffffffff60）而触发SIGSEGV崩溃。

**排查方向**：此问题发生在free流程中，需跳过musl栈帧找调用方首栈排查。建议开启asan压测复现。

---

### jemalloc检测到use-after-free（cache_bin_uaf_safety_check）

#### 前置：典型CPPCRASH相关日志

**案例**
```
Reason:Signal:SIGSEGV(SEGV_MAPERR)@000000000000000000  probably caused by NULL pointer dereference
Fault thread info:
Tid:44058, Name:OS_FFRT_3_14
#00 pc 00000000000b75a0 /system/lib/ld-musl-aarch64.so.1(cache_bin_uaf_safety_check+4)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#01 pc 00000000000bda54 /system/lib/ld-musl-aarch64.so.1(je_malloc+752)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#02 pc 00000000001f8b74 /system/lib/ld-musl-aarch64.so.1(malloc+72)(8c2ca4e308a1de9ed1e6b4ccc14c7443)
#03 pc 00000000000b31a4 /system/lib64/chipset-sdk-sp/libc++.so(operator new(unsigned long)+28)
```

#### 规则

1. 崩溃信号为`SIGSEGV(SEGV_MAPERR)`
2. #00栈特征为 **cache_bin_uaf_safety_check**
3. 调用栈通常经过 je_malloc → malloc 路径，属于内存分配过程中jemalloc的UAF安全检查检测到已释放内存被继续使用

#### 定界结论

踩内存的第2现场。属于**UAF（use-after-free）**问题。

#### 原因

jemalloc内置了UAF（Use-After-Free）安全检查机制。当jemalloc在内存分配（malloc）过程中检测到正在分配的内存块仍被标记为"已释放但仍在使用"状态时，会触发安全检查异常。这表明上层模块存在释放后继续使用（use-after-free）的内存问题。

**排查方向**：UAF问题无法检测到业务模块什么时候对已释放内存进行了写操作等，只能在malloc等业务中再次分配时去检测。所以UAF问题crash报栈基本都不是发生UAF的第一现场，需跳过musl栈帧，由进程模块主导排查。建议开启asan压测复现。

---

### jemalloc free路径中tss访问异常（tss_get）

#### 前置：典型CPPCRASH相关日志

**案例**
```
Reason:Signal:SIGSEGV(SEGV_MAPERR)@000000000000000000  probably caused by NULL pointer dereference
LastFatalMessage:Current Event Caller is empty. Nothing to dump
Fault thread info:
Tid:1862, Name:RSUniRenderThre
#00 pc 00000000001d9094 /system/lib/ld-musl-aarch64.so.1(tss_get+12)(a05d5a74f4849881cab5177e9296b750)
#01 pc 00000000000be7c4 /system/lib/ld-musl-aarch64.so.1(je_free+48)(a05d5a74f4849881cab5177e9296b750)
#02 pc 00000000002b1928 /system/lib64/librender_service.z.so(OHOS::Rosen::DrawableV2::RSSurfaceRenderNodeDrawable::OnDraw(OHOS::Rosen::Drawing::Canvas&)+1416)
```

#### 规则

1. 崩溃信号为`SIGSEGV(SEGV_MAPERR)`
2. #00栈特征为 **tss_get**，且#01栈为 **je_free** 或其它je相关函数
3. 属于jemalloc在free路径中获取线程特定存储（TSS/TSD）时访问异常

#### 定界结论

踩内存的第2现场。属于**踩内存**问题。

#### 原因

jemalloc依赖线程特定存储（Thread-Specific Storage, TSS/TSD）来管理每个线程的tcache。当TSS数据结构被其它模块非法踩写后，jemalloc在执行free操作时调用tss_get获取线程本地缓存上下文，访问到被踩写的非法地址而触发SIGSEGV崩溃。

**排查方向**：此问题发生在free流程中，需跳过musl栈帧找调用方首栈排查。建议开启asan压测复现。

---

### #00为raise且#01为je安全检查函数（double free检测）

#### 前置：典型CPPCRASH相关日志

**案例 - raise + je_tcache_bin_flush_small**
```
Reason:Signal:SIGSEGV(SI_TKILL)@0x01317b350000f31c from:62236:20020021
LastFatalMessage:This is an unexpected memory usage behavior.
Fault thread info:
Tid:65472, Name:OS_AVPlayerNapi
#00 pc 000000000019ca00 /system/lib/ld-musl-aarch64.so.1(raise+228)(f77c0346c0084ebbadf721ea319f5f77)
#01 pc 00000000000f05d8 /system/lib/ld-musl-aarch64.so.1(je_tcache_bin_flush_small+1284)(f77c0346c0084ebbadf721ea319f5f77)
#02 pc 00000000000ae95c /system/lib/ld-musl-aarch64.so.1(free_default+1412)(f77c0346c0084ebbadf721ea319f5f77)
#03 pc 00000000000559e4 /system/lib64/platformsdk/libmedia_client.z.so
```

#### 规则

1. 崩溃信号为`SIGSEGV(SI_TKILL)`
2. `LastFatalMessage`或`Abort message`包含 **"unexpected memory usage behavior"** 或 **"may double free"**
3. #00栈为 **raise**，#01栈为以下任一jemalloc安全检查函数：

| #00栈顶 | #01次栈顶 | 问题类型 |
|---------|----------|---------|
| raise | cache_bin_dalloc_safety_checks | double free |
| raise | je_arena_dalloc_small | double free |
| raise | je_tcache_bin_flush_small | double free |
| raise | large_dalloc_doublefree_check | double free |
| raise | tcache_bin_flush_size_check_fail | double free |

4. 属于jemalloc安全检测机制检测到double free后调用raise终止进程

#### 定界结论

踩内存的第2现场。属于**double free**问题。

#### 原因

由于jemalloc安全检测对`security_assert`进行了修改，把crash_brk换成了raise，所以旧版本中很多double free的检测栈顶显示为raise。当jemalloc检测到double free时，会调用raise(SIGSEGV)终止进程，#00栈显示为raise，实际的je安全检查函数在#01栈。

**排查方向**：跳过musl栈帧，找调用方首栈排查是否存在重复释放。如果报栈都是musl栈，这种情况基本都是在线程退出流程，需要找进程模块排查。建议开启asan压测复现。

---

### #00栈为crash_brk且后续栈为je_free（double free检测）

#### 前置：说明

jemalloc对`security_assert`进行了修改，部分版本中double free检测触发的是crash_brk而非raise，此时Reason signal报TRAP_BRKPT。栈顶不会直接显示crash_brk，而是显示调用crash_brk的je函数。

#### 规则

1. 崩溃信号为`SIGTRAP(TRAP_BRKPT)`
2. `LastFatalMessage`或`Abort message`包含 **"may double free"** 或 **"unexpected memory usage behavior"**
3. #00栈为以下任一jemalloc函数（内部调用了crash_brk）：

| #00栈顶 | 问题类型 |
|---------|---------|
| cache_bin_dalloc_safety_checks | double free |
| je_arena_dalloc_small | double free |
| je_tcache_bin_flush_small | double free |
| large_dalloc_doublefree_check | double free |
| tcache_bin_flush_size_check_fail | double free |

#### 定界结论

踩内存的第2现场。属于**double free**问题。

#### 原因

当jemalloc安全检测机制检测到double free时，在`security_assert`中调用crash_brk触发SIGTRAP终止进程。由于crash_brk不会显示在栈顶，栈顶显示的是调用crash_brk的je安全检查函数。

**排查方向**：跳过musl栈帧，找调用方首栈排查是否存在重复释放。如果报栈都是musl栈，这种情况基本都是在线程退出流程，需要找进程模块排查。建议开启asan压测复现。

---

### #00栈非jemalloc相关业务但Reason为JEMALLOC信号（UAF/double free）

#### 前置：说明

当Reason为`Signal:DEBUG SIGNAL(JEMALLOC)`，#00号栈未显示业务接口（或在syscall），#01号栈为`save_debug_message`时，属于jemalloc的DFX检测机制检测到异常。

#### 规则

1. Reason为 **`Signal:DEBUG SIGNAL(JEMALLOC)`**
2. #00号栈未显示业务接口，或手动解析是在syscall
3. #01号栈为 **save_debug_message**
4. 根据je函数所在流程进一步区分：
   - 如果在jemalloc的**内存分配**流程中出现 → **UAF问题**
   - 如果在jemalloc的**内存释放**流程中出现，需解析判断：
     - `je_free`流程 → **double free**
     - `je_tcache_bin_flush_small`流程 → **UAF**

#### 定界结论

踩内存的第2现场。属于**UAF**或**double free**问题。

#### 原因

jemalloc的DFX检测机制在检测到异常内存使用行为时，会通过save_debug_message保存调试信息并触发DEBUG SIGNAL。由于此时#00栈不在je业务函数中，需要根据上下文中的je函数判断是分配流程还是释放流程，进而确定问题类型。

**排查方向**：
- **UAF问题**：UAF问题无法检测到业务模块什么时候对已释放内存进行了写操作等，只能在malloc等业务中再次分配时去检测。所以UAF问题crash报栈基本都不是发生UAF的第一现场，需跳过musl栈帧，由进程模块主导排查。建议开启asan压测复现。
- **double free问题**：跳过musl栈帧，找调用方首栈排查是否存在重复释放。如果报栈都是musl栈，这种情况基本都是在线程退出流程，需要找进程模块排查。建议开启asan压测复现。

---

## 通用判定规则

当崩溃日志满足以下**任一**条件时，均可判定为踩内存的第2现场：

1. **#00栈为jemalloc元数据管理函数**（alloc路径）→ **踩内存**：
   - `emap_update_edata_state`
   - `edata_heap_remove`
   - `eset_remove`

2. **#00栈为jemalloc安全检查函数**（free路径的主动检测）→ **double free**：
   - `cache_bin_dalloc_safety_checks`
   - `je_arena_dalloc_small`（SIGTRAP时）
   - `large_dalloc_doublefree_check`
   - `tcache_bin_flush_size_check_fail`

3. **#00栈为jemalloc UAF检查函数** → **UAF**：
   - `cache_bin_uaf_safety_check`

4. **#00栈为jemalloc tcache管理函数** → **double free**或**踩内存**：
   - `je_tcache_bin_flush_small`（带"may double free"提示时为double free，SIGSEGV时为踩内存）
   - `tcache_bin_flush_stashed`
   - `tcache_destroy`
   - `je_tsd_cleanup`

5. **#00栈为raise，但#01栈为je相关函数**，且`LastFatalMessage`包含"unexpected memory usage behavior" → **double free**：
   - `raise` + `cache_bin_dalloc_safety_checks`
   - `raise` + `je_arena_dalloc_small`
   - `raise` + `je_tcache_bin_flush_small`
   - `raise` + `large_dalloc_doublefree_check`
   - `raise` + `tcache_bin_flush_size_check_fail`

6. **#00栈为tss_get/tsd_get，且后续栈为je_free等je函数** → **踩内存**：
   - `tss_get` + `je_free`

7. **#00栈非je相关，但Reason为DEBUG SIGNAL(JEMALLOC)，#01为save_debug_message** → **UAF**或**double free**

**核心原则**：所有栈顶落在`ld-musl-aarch64.so.1`中jemalloc相关函数（函数名包含`je_`、`emap_`、`edata_`、`eset_`、`tcache_`、`cache_bin_`、`arena_`、`pac_`、`tss_`、`tsd_`、`save_debug_message`等jemalloc内部符号）的崩溃，均可认为是踩内存的第2现场。jemalloc作为底层内存管理模块非常稳定，这类崩溃的根因均为其它模块的非法内存操作，跳过jemalloc栈帧由调用方模块主导排查。

---

## 二、输出要求

命中本参考手册任一规则后，严格使用 `SKILL.md` 中的“模板B：踩内存场景”输出，不得与常规CppCrash模板混用，也不得增加模板之外的字段。
