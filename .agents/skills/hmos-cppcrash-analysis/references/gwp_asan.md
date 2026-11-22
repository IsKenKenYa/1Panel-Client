# GWP-ASan 日志分析参考

> 仅当用户输入明确提到 `gwpasen`、`gwpasan`、`GWP-ASan`、`GWP-ASAN` 或“GWP-ASan日志”时读取并使用本文档。普通 CppCrash tombstone 不套用本规则。

## 1. 能力定位

GWP-ASan 是面向 Native 堆内存错误的低开销、采样式检测能力。它通过对少量堆分配使用保护页，在线上或开发态捕获难复现的堆内存安全问题。

可重点识别：

| 错误类型 | 含义 | 根因方向 |
|----------|------|----------|
| `Use After Free` | 释放后继续访问堆内存 | 生命周期管理错误、异步回调未取消、跨线程释放后访问 |
| `Double Free` | 同一块堆内存被重复释放 | 所有权不清晰、多个对象重复管理同一指针 |
| `Buffer Overflow` | 写/读越过堆缓冲区右边界 | 长度计算错误、数组下标越界、拷贝长度超限 |
| `Buffer Underflow` | 写/读越过堆缓冲区左边界 | 指针回退、负下标、错误偏移 |
| `Invalid Free` | 释放非法地址 | 释放非 malloc/new 获得的地址、释放偏移后的指针 |

能力边界：
- 只对被采样保护的堆分配生效，检测具有概率性。
- 主要定位堆 UAF、堆越界、重复释放、非法释放；不要用于定性栈越界或全局变量越界。
- 若日志缺少 allocation / deallocation 栈，可能与 frame pointer 缺失、32 位进程或符号不足有关。
- GWP-ASan 报告代表真实内存破坏证据，但本地复现可能困难；必要时建议使用 HWASan / ASan / fuzz 继续复现。

---

## 2. 触发和日志获取

### 2.1 触发条件

只有当用户输入明确包含以下关键词时才进入本分析：

```text
gwpasen
gwpasan
GWP-ASan
GWP-ASAN
GWP-ASan日志
Reason:GWP-ASAN
*** GWP-ASan detected a memory error ***
```

如果日志中只包含普通 `SIGSEGV` / `SIGABRT` / `CPP_CRASH`，且用户没有提到 GWP-ASan，不执行本分支。

### 2.2 启用提示

若用户询问如何启用或复现 GWP-ASan：

- HarmonyOS 文档中提到可通过 `app.json5` 的 `GWPAsanEnabled` 标签配置。
- `true` 表示 100% 开启 GWP-ASan。
- `false` 表示应用冷启动时按概率开启，文档示例为 1/128 概率。
- 由于检测是采样式，单次复现未命中不代表问题不存在。

### 2.3 运维态日志来源

如果用户只有故障事件而没有完整日志，提示优先获取：

- faultlog / tombstone 中 `Reason:GWP-ASAN` 的完整段落。
- HiAppEvent / 稳定性事件中的 external_log 指向的日志文件。
- 包含 `*** GWP-ASan detected a memory error ***` 到 `* End GWP-ASan report *` 的完整内容。

---

## 3. 日志规格识别

典型 GWP-ASan 日志结构：

```text
Device info:<设备信息>
Build info:<版本信息>
Fingerprint:<特征信息>
Timestamp:<时间戳>
Module name:<模块名>
Version:<版本号>
Pid:<进程号>
Uid:<用户ID>
Reason:GWP-ASAN
*** GWP-ASan detected a memory error ***
<问题概述>
<违规访问调用栈>
<释放调用栈>
<申请调用栈>
* End GWP-ASan report *
```

必须校验：

1. `Reason:GWP-ASAN`
2. `*** GWP-ASan detected a memory error ***`
3. 至少存在一段问题概述和违规访问栈

如果缺少第 2 项，不要强行按 GWP-ASan 报告输出；应标注“疑似 GWP-ASan 但证据不足”。

---

## 4. 基础字段提取

| 字段 | 提取目标 | 说明 |
|------|----------|------|
| `Device info` | 设备信息 | 辅助环境定位 |
| `Build info` | 版本信息 | 用于版本定界 |
| `Fingerprint` | 特征信息 | 用于去重和版本指纹 |
| `Timestamp` | 故障时间 | 报告时间 |
| `Module name` | 模块名 / 包名 | 可能是应用包名或系统进程/组件名 |
| `Version` | 故障模块版本 | 应用或系统组件版本号 |
| `Pid` | 进程号 | 故障进程 |
| `Uid` | 用户 ID | 应用 UID |
| `Reason` | 固定为 `GWP-ASAN` | GWP-ASan 分支判定依据 |

---

## 5. 问题概述解析

Use After Free 典型格式：

```text
Use After Free at 0x5b46ddaff0 (0 bytes into a 16-byte allocation at 0x5b46ddaff0) by thread 13305 here:
```

需要提取：

| 信息 | 示例 | 含义 |
|------|------|------|
| 内存错误类型 | `Use After Free` | 释放后访问 |
| 违规访问地址 | `0x5b46ddaff0` | 当前被访问的地址 |
| 访问偏移 | `0 bytes into` | 访问点相对 allocation 起始地址的偏移 |
| allocation 大小 | `16-byte allocation` | 被访问内存块大小 |
| allocation 起始地址 | `0x5b46ddaff0` | 分配得到的内存块起始地址 |
| 触发线程 | `thread 13305` | 发生违规访问的线程 |

越界类常见概述可按类似方式解析：

```text
Buffer Overflow at 0x... (<N> bytes after a <SIZE>-byte allocation at 0x...) by thread <tid> here:
Buffer Underflow at 0x... (<N> bytes before a <SIZE>-byte allocation at 0x...) by thread <tid> here:
```

重复释放 / 非法释放类日志可能没有完整“访问偏移”，应优先保留原文并提取地址、线程和相关栈。

---

## 6. 三段调用栈解析

### 6.1 违规访问栈

起始标记：

```text
by thread <tid> here:
```

含义：对象释放后被再次访问、越界访问或非法释放的发生位置，是直接触发点。

分析要求：
- 跳过 allocator、检测器和运行时帧，找第一个能够确认实现归属的责任候选帧；同时检查 `/data/` 应用产物和 `/system/` 系统模块。
- 记录 `.so` 路径与偏移，例如 `(/data/storage/xxxxxx.so+0x3049c)`。
- 如果只有裸地址，标注“缺少符号信息，需要符号文件解析”。
- 若栈顶是 `ld-musl` / allocator，继续向下找第一个有实际内存访问语义的责任候选帧。

### 6.2 释放栈

起始标记：

```text
0x<addr> was deallocated by thread <tid> here:
```

含义：该内存块被释放的位置，是判断生命周期提前结束的关键证据。

分析要求：
- 提取释放线程 ID。
- 找第一个能够确认实现归属的释放责任候选帧。
- 与违规访问栈对比，判断是否同一业务调用链重复释放、释放后继续使用、或跨线程释放后访问。

### 6.3 申请栈

起始标记：

```text
0x<addr> was allocated by thread <tid> here:
```

含义：该内存块最初申请的位置，用于还原对象创建来源和生命周期。

分析要求：
- 提取申请线程 ID。
- 找第一个能够确认实现归属的申请责任候选帧。
- 与释放栈、违规访问栈串联，形成“申请 -> 释放 -> 再访问”的完整证据链。

---

## 7. 根因判断规则

| 条件 | 根因判断 | 置信度 |
|------|----------|--------|
| 概述包含 `Use After Free` | UAF / 释放后访问 | HIGH |
| 概述包含 `Buffer Overflow` | 堆缓冲区右越界 | HIGH |
| 概述包含 `Buffer Underflow` | 堆缓冲区左越界 | HIGH |
| 概述包含 `Double Free` | 重复释放 | HIGH |
| 概述包含 `Invalid Free` | 非法释放 | HIGH |
| 违规访问地址与释放/申请地址一致 | 同一内存块生命周期错误 | HIGH |
| 释放线程与访问线程不同 | 跨线程生命周期未同步 | MEDIUM/HIGH |
| 三段栈均指向同一应用侧 `/data/` 实现链 | 优先定界应用侧 | HIGH |
| 三段栈均指向同一系统模块实现链，且排除应用错误入参/生命周期触发 | 定界系统侧 | HIGH |
| 只有运行时/检测器帧或裸地址 | 需要符号解析，置信度降低 | LOW/MEDIUM |

定界优先级：

1. 优先使用违规访问栈第一个责任候选帧定位直接触发模块。
2. 使用释放栈第一个责任候选帧定位对象生命周期结束位置。
3. 使用申请栈第一个责任候选帧定位对象创建来源。
4. 若三段栈均指向同一 `.so` 或同一业务链，责任模块优先定为该 `.so`。
5. 若释放栈和访问栈分属不同线程/模块，结论中必须说明“跨线程/跨模块对象所有权不清晰”。
6. 根据最终责任模块输出同责任域修复：系统侧根因只修改系统模块，应用侧根因只修改应用模块；责任未定时只给继续定界建议。

---

## 8. 缺失信息处理

| 缺失项 | 处理方式 |
|--------|----------|
| 缺少释放栈 | 标注无法确认释放位置；建议补充完整 GWP-ASan 日志或检查 frame pointer |
| 缺少申请栈 | 标注无法确认对象创建来源；仍可基于违规访问栈和错误类型定性 |
| 缺少符号 | 输出 `.so+offset`；仅对最近的应用帧建议提供匹配 BuildID 的应用符号，并使用 `scripts/ohos_llvm_tools.py addr2line` 解析，不要求应用反解系统栈 |
| 只有裸地址 | 结论置信度降级；要求补充 maps / so / BuildID |
| 32 位进程栈不完整 | 标注 GWP-ASan 对 32 位进程分配/释放栈支持可能不足 |

---

## 9. 分析流程

```text
Step 1: 确认 Reason:GWP-ASAN
Step 2: 提取基础信息和问题概述
Step 3: 解析错误类型、地址、allocation 大小、偏移、线程
Step 4: 切分违规访问栈、释放栈、申请栈
Step 5: 找每段栈的首个责任候选帧并判定实现归属
Step 6: 串联申请 -> 释放 -> 违规访问，判断生命周期或越界路径
Step 7: 输出责任领域、根因模块、证据链和同责任域修复建议
```

---

## 10. 输出模板

```text
================================================================================
GWP-ASan 内存错误分析报告
================================================================================

【基础信息】
故障时间     : <Timestamp>
模块名       : <Module name>
版本号       : <Version>
进程信息     : Pid=<Pid>, Uid=<Uid>
Reason       : GWP-ASAN

【内存错误摘要】
错误类型     : <Use After Free / Buffer Overflow / ...>
访问地址     : <addr>
分配起始地址 : <allocation addr>
分配大小     : <N-byte>
访问偏移     : <N bytes into/after/before>
触发线程     : <tid>

【三段调用栈定位】
| 栈类型 | 线程 | 首个责任候选帧 | 关键证据 |
|--------|------|--------------|----------|
| 违规访问栈 | <tid> | <so+offset> | <原始帧> |
| 释放栈 | <tid> | <so+offset> | <原始帧> |
| 申请栈 | <tid> | <so+offset> | <原始帧> |

【根因分析】
诊断结果 : <一句话结论>
故障类别 : <UAF / 堆越界 / 重复释放 / 非法释放>
可信度   : HIGH / MEDIUM / LOW

【证据链】
1. <问题概述原文与解释>
2. <违规访问栈证据>
3. <释放栈证据>
4. <申请栈证据>

【根本原因】
直接原因 : <释放后访问/越界/重复释放的直接代码路径>
深层原因 : <生命周期、所有权、跨线程同步、边界检查等设计问题>
触发路径 : <申请 -> 释放 -> 再访问，或申请 -> 越界访问>

【根因模块】
责任领域 : <应用 / 系统 / 混合 / 未定>
责任模块 : <实际责任 so + 函数/偏移>
定界依据 : <为何定界到该模块>

【修复建议】
1. <责任模块未反解时：提供该模块匹配 BuildID 的符号；已反解时，系统侧根因填写系统模块修复，应用侧根因填写应用模块修复>
2. <由责任模块修复释放后引用、所有权或生命周期问题>
3. <由责任模块修复跨线程同步、异步回调注销或重复释放问题>
4. <由责任模块补充长度校验、边界保护与回归测试>
================================================================================
```
