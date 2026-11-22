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

## 二、输出要求

命中本参考手册任一规则后，严格使用 `SKILL.md` 中的“模板B：踩内存场景”输出，不得与常规CppCrash模板混用，也不得增加模板之外的字段。
