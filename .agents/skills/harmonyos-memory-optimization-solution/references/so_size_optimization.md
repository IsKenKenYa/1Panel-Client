# SO 包体积与内存劣化优化指南（编译选项/手段）

## 适用场景

- 应用自研 so（`libs/arm64-v8a/*.so`、`libs/armeabi-v7a/*.so`）体积相比上一版本明显增长。
- smaps 对比显示 `.so` 映射 Pss 增大（代码段 r-xp、rodata r--p 驻留内存变大），根因为二进制膨胀。
- 编译选项变更（如 `-O2` 改 `-O3`、去掉 `--gc-sections`）或新增功能导致 so 变大。

## 编译选项/手段总览

下表中链接器选项的前缀统一为 `-Wl,`（小写 L，"linker" 的缩写），表示把逗号后的选项透传给链接器 lld。**不要写成 `-WI,`（大写 i）**——大写 `I` 是"包含目录"语义，lld 无法识别 `-gc-sections` 这样的编译选项拼写时会被静默忽略，实测不产生任何裁剪效果（见文末验证记录）。

| 编译选项/手段 | 作用 | 副作用 | 类型 |
|---|---|---|---|
| `-ffunction-sections -fdata-sections` + `-Wl,--gc-sections` | 让每个函数/每个全局数据符号作为独立 section，链接器删除未被使用的非导出符号 | 无 | 编译+链接 |
| `-Oz` / `-Os` | 相比 `-O3`/`-O2` 进行更进一步的 code size 优化 | 可能造成性能劣化 | 编译 |
| `-fvisibility=hidden -fvisibility-inlines-hidden` | 未显式声明为公开的符号（函数、变量）及内联类成员函数都标记为隐藏，减少产物符号段大小 | 无 | 编译 |
| `-fno-rtti` | 禁用 C++ 的 RTTI 机制 | 用户不能使用 RTTI，如 `dynamic_cast`（编译报错 `use of dynamic_cast requires -frtti`）、`typeid` | 编译 |
| `-fno-exceptions` | 禁用 C++ 的异常机制 | 用户不能使用异常，如 `try/catch`、`throw` | 编译 |
| `-Wl,-z,pack-relative-relocs` / `-Wl,--pack-dyn-relocs=relr` | 使用 RELR 编码格式压缩动态重定位段（`.rela.dyn` 中 R_AARCH64_RELATIVE 类条目） | 无（要求内核/加载器支持，OHOS 支持） | 链接 |
| `-Wl,--hash-style=gnu` | 动态符号表仅生成 GNU 扩展哈希表（不生成 `.hash`，只保留 `.gnu.hash`） | 无 | 链接 |
| `-Wl,--icf=all` | 链接阶段对相似代码片段（Identical Code Folding）合并处理 | 可能造成性能劣化；极端场景下合并了"恰好字节相同但语义不同"的函数（如依赖函数指针地址判等） | 链接 |
| `-moutline`（gcc）/ `-mllvm -enable-machine-outliner`（clang） | 编译阶段对相似代码片段做 outlining 合并 | 仅 aarch64/arm 下支持，会造成性能劣化（函数调用开销）。**注意：OHOS 的 clang 15 不认识 gcc 的 `-moutline`，会被静默忽略，clang 需用 `-mllvm -enable-machine-outliner`** | 编译 |
| `-mllvm -inline-threshold=<数值>` | 设置编译器 inline 优化时最大可 inline 的函数成本阈值（调小以减少 inline 膨胀） | 可能造成性能劣化（调用开销增大） | 编译 |
| 在 libc++.so 中显式实例化 STL 模板（`_GLIBCXX_USE_CXX11_ABI` 类似的库级收敛方案，OHOS 为 libc++ 的显式模板实例化导出） | 避免每个动态库中都存在 STL 模板的实例化副本 | 造成性能劣化（跨 so 调用无法内联） | 库级手段 |

## 各选项详解与使用约束

### 1. section 裁剪：`-ffunction-sections -fdata-sections` + `-Wl,--gc-sections`

**原理**：编译阶段把每个函数/全局变量放入独立 section；链接阶段 `--gc-sections` 以入口符号为根做可达性分析，未到达的 section 被删除。两者必须配合使用，只加编译选项不裁剪无效。

```cmake
# CMakeLists.txt（ohos 工程原生 C++ 模块）
target_compile_options(mylib PRIVATE
    -ffunction-sections
    -fdata-sections)
target_link_options(mylib PRIVATE
    -Wl,--gc-sections)
```

**注意**：

- `--gc-sections` 只能删除**未被引用且未被导出**的符号。如果符号通过 `__attribute__((visibility("default")))` 导出（或未加 `-fvisibility=hidden` 时默认导出），即使无人使用也不会被删除——因此通常与 `-fvisibility=hidden` 配合使用。
- 注册/反射类代码（函数指针表、静态对象构造函数中自注册）可能被误裁剪。clang 下如有误删，需用 `__attribute__((used))` 保留。

### 2. 优化等级：`-Oz` / `-Os`

- `-Os`：以不显著增大体积为前提优化（接近 `-O2`）。
- `-Oz`：最小体积优先，禁用向量化、降低 inline 热情， aggressively 缩小指令序列。
- 对启动路径/热点函数建议保持 `-O2`，仅对非热点模块使用 `-Oz`，兼顾体积与性能。

### 3. 符号隐藏：`-fvisibility=hidden -fvisibility-inlines-hidden`

- 默认所有符号可见时，导出符号表（`.dynsym`）、字符串表（`.dynstr`）会很大，且阻止 `--gc-sections` 回收。
- JNI/napi 模块只需导出入口函数：

```cpp
// 只导出必要的 napi 注册函数
__attribute__((visibility("default")))
napi_value Init(napi_env env, napi_value exports) { ... }
```

- `-fvisibility-inlines-hidden` 针对类内联成员函数，避免每个 so 内联函数都进导出表。

### 4. 禁用语言特性：`-fno-rtti` / `-fno-exceptions`

- 收益：删除 `.gcc_except_table`、typeinfo、unwind 相关代码与数据段。
- **副作用是硬约束**：业务代码中不能出现 `dynamic_cast`、`typeid`（`-fno-rtti`），不能出现 `try/catch`、`throw`、以及依赖异常的标准库用法如 `std::bad_alloc`（`-fno-exceptions`）。OHOS 推荐错误码处理，与该选项方向一致。
- 与第三方库集成时注意：三方库若使用异常，链接其头文件的翻译单元不能加该选项（按 target 或按文件粒度添加）。

### 5. 重定位压缩：`-Wl,-z,pack-relative-relocs` / `-Wl,--pack-dyn-relocs=relr`

- 两者是同一能力的不同写法：前者是 glibc 风格的 `-z` 选项，后者是 lld 原生选项。OHOS lld 两者均支持，产物中生成 `DT_RELR/DT_RELRSZ/DT_RELRENT` 动态段，R_AARCH64_RELATIVE 类重定位按位图编码，体积从 24 字节/条压缩到平均约 1 字节/条。
- so 中全局数据越多、重定位条目越多，收益越大。
- 前提是运行时加载器支持 RELR（OHOS musl 加载器支持；如需兼容老系统需确认）。

### 6. 哈希表裁剪：`-Wl,--hash-style=gnu`

- 默认 `sysv+gnu` 双哈希表并存；仅保留 `.gnu.hash` 可删除 `.hash` 段（SysV 哈希表及其字符串引用）。
- 单独使用收益有限，常与其他选项一起配置。

### 7. 相似代码合并（链接期）：`-Wl,--icf=all`

- lld 的 Identical Code Folding：把字节级相同的函数合并为一个。模板重实例化、自动生成的 thunk 收敛明显。
- `--icf=all` 比 `--icf=safe` 更激进（不保证保守的地址唯一性）。
- **副作用**：
  - 函数地址相等可能破坏 `funcA != funcB` 的地址判等逻辑。
  - 与 `--emit-relocs`、某些增量修复工具不兼容。
  - 收敛出的跳转可能略微破坏局部性，极端情况性能劣化。

### 8. 相似代码合并（编译期）：outlining

- **gcc 写法 `-moutline` 仅适用于 gcc；OHOS 工具链为 LLVM/clang 15，`-moutline` 不被识别（实测静默忽略、产物不变）。**
- clang 下等价能力是 MachineOutliner：`-mllvm -enable-machine-outliner`（配合 `-Oz` 效果更佳）；IR 级别还可用 `-mllvm -ir-outliner=1`。
- 仅 aarch64/arm 后端支持；提取的公共序列以函数调用替代重复指令，体积换性能。

### 9. inline 阈值：`-mllvm -inline-threshold=<数值>`

- clang 的 inline 成本模型阈值，默认随 `-O` 等级变化（`-Os`/`-Oz` 已内置较小阈值）。进一步调小（如 `50`、`25`）可继续压缩 inline 膨胀。
- 数值越小体积越小、调用开销越大。建议从默认值的 1/2 开始试，按体积/性能数据回调。

### 10. STL 模板库级收敛：libc++.so 显式实例化

- STL 模板（`std::vector<int>::push_back`、`std::string` 等）在每个 so 中都会实例化一份代码。
- OHOS 系统的 libc++.so 已对常用模板做显式实例化并导出（`_LIBCPP_ABI_...` 机制），应用 so 链接后直接复用，不必自带副本。
- 应用侧注意不要用 `-fvisibility=hidden` 之外的手段强制静态/内联 STL；避免 `extern template` 缺失导致每个 so 重复实例化大模板。
- 副作用：跨 so 调用无法内联，性能劣化。

## 推荐组合（应用自研 so 体积优化基线）

```cmake
# 编译选项
target_compile_options(mylib PRIVATE
    -ffunction-sections
    -fdata-sections
    -fvisibility=hidden
    -fvisibility-inlines-hidden
    -Oz                        # 非热点模块；热点保持 -O2
    -fno-rtti                  # 确认无 dynamic_cast/typeid 后启用
    -fno-exceptions            # 确认无 try/catch/throw 后启用
    -mllvm -inline-threshold=50
)

# 链接选项
target_link_options(mylib PRIVATE
    -Wl,--gc-sections
    -Wl,--hash-style=gnu
    -Wl,-z,pack-relative-relocs
    -Wl,--icf=all
)
```

> 按模块实际情况裁剪：性能敏感模块去掉 `-Oz`/`--icf=all`；使用异常的模块去掉 `-fno-exceptions`；依赖函数地址唯一性的模块去掉 `--icf=all`。

## 劣化排查步骤（so 变大时）

1. **确认劣化类型**：用 smaps 对比（参见 so-size/hap 工作流）判断是"二进制体积增大"（Size 与 Pss 同步增长）还是"运行时数据膨胀"（仅 Pss 增长）。本指南只针对前者。
2. **对比产物段大小**：`llvm-readelf -S old.so` vs `new.so`，定位增长的段（`.text` 代码、`.rodata` 常量、`.dynsym/.dynstr` 符号、`.rela.dyn` 重定位）。
3. **按段定选项**：
   - `.text` 增长 → `-Oz`、`--gc-sections`（配合 `-ffunction-sections`）、`--icf=all`、outlining、调小 inline-threshold。
   - `.dynsym/.dynstr` 增长 → `-fvisibility=hidden -fvisibility-inlines-hidden`。
   - `.rela.dyn` 增长 → `pack-relative-relocs`（RELR）。
   - `.hash` 存在 → `--hash-style=gnu`。
   - `.gcc_except_table` 大 → `-fno-exceptions` / `-fno-rtti`。
4. **符号级 diff**：`llvm-nm -C --defined-only old.so > old.sym` / `new.so > new.sym`，`diff` 找新增大符号，确认是新增功能（代码层收敛）还是选项回退（恢复选项）。
5. **回归验证**：改选项后重新编译，用 `llvm-size`/`llvm-readelf` 确认段回落，并跑性能测试确认无不可接受的劣化（`-Oz`/`--icf=all`/低 inline 阈值都有性能代价）。

## 验证记录（OHOS clang 15.0.4，aarch64-unknown-linux-ohos，2026-09 实测）

以下结论均在本机 DevEco SDK 工具链上实测得出，修改本指南前建议复测：

| 选项 | 实测结论 |
|---|---|
| `-Wl,--gc-sections` | 生效：`-ffunction-sections` 编译的 `unused_func`（未被引用）在加 `-Wl,--gc-sections` 链接后被删除 |
| `-WI,-gc-sections`（错误拼写） | **无效且静默**：链接成功退出码 0，但 `unused_func` 仍保留，未做任何裁剪 |
| `-Wl,-z,pack-relative-relocs` / `-Wl,--pack-dyn-relocs=relr` | 均生效：产物出现 `DT_RELR/DT_RELRSZ/DT_RELRENT` 3 个动态条目 |
| `-Wl,--hash-style=gnu` | 生效：`DT-gnu_hash` 条目存在 |
| `-Wl,--icf=all` | lld 接受，无报错 |
| `-moutline` | **clang 15 不支持**：编译静默通过但产物与不加时完全相同（被忽略）；gcc 语义的该选项勿用于 OHOS clang |
| `-mllvm -enable-machine-outliner` / `-mllvm -ir-outliner=1` | clang 下可用的 outlining 写法 |
| `-mllvm -inline-threshold=50` | 生效，无报错 |
| `-fno-rtti` | 生效：使用 `dynamic_cast` 的代码直接编译报错 `use of dynamic_cast requires -frtti` |
| `-Oz` / `-Os` | 生效：较大样例 `.text` 从 `-O2` 的 1408 字节降到 `-Oz` 的 628 字节（`.o` 文件总大小受调试/异常表影响需用段大小对比） |

## 核心约束

- `-ffunction-sections -fdata-sections`（编译）必须与 `-Wl,--gc-sections`（链接）配合使用，只加其一无效；`--gc-sections` 只能删除未被引用且未被导出的符号，需配合 `-fvisibility=hidden` 才能回收未导出的多余符号。
- 链接器选项前缀必须是 `-Wl,`（小写 L）。写成 `-WI,`（大写 i）不会报错但会被**静默忽略**，无任何裁剪效果（已实测验证）。
- `-moutline` 是 gcc 专属选项；OHOS 工具链为 clang 15，该选项被**静默忽略**（产物不变）。clang 下等价能力为 `-mllvm -enable-machine-outliner`（machine outliner）或 `-mllvm -ir-outliner=1`（IR outliner），仅 aarch64/arm 后端支持。
- `-Oz`/`-Os`、`-Wl,--icf=all`、调小 `-mllvm -inline-threshold` 均可能造成性能劣化，仅对非热点 so/模块启用；热点模块保持 `-O2`。
- `-fno-rtti` 启用后代码中不能出现 `dynamic_cast`、`typeid`（编译直接报错）；`-fno-exceptions` 启用后不能出现 `try/catch`/`throw` 及依赖异常的标准库用法。使用异常的第三方库翻译单元不能加该选项。
- `-Wl,-z,pack-relative-relocs` 与 `-Wl,--pack-dyn-relocs=relr` 是同一能力的两种写法（glibc 风格 vs lld 原生），OHOS lld 均支持，产物生成 `DT_RELR/DT_RELRSZ/DT_RELRENT` 段。
- `-Wl,--icf=all` 会合并字节相同的函数，可能破坏依赖函数地址判等（`funcA != funcB`）的逻辑，此类模块不要启用。
- `-Wl,--hash-style=gnu` 仅保留 `.gnu.hash`、删除 `.hash` 段，收益有限，作为组合配置项。
- libc++.so 已显式实例化并导出常用 STL 模板，应用 so 应复用系统 libc++，避免每个 so 携带模板实例化副本；跨 so 调用无法内联，有性能代价。
- SO 劣化排查先区分类型：Size 与 Pss 同步增长为二进制膨胀（本指南编译选项方案适用）；仅 Pss 增长为运行时数据膨胀（应排查运行时分配行为，编译选项无效）。
