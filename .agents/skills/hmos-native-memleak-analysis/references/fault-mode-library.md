# Native PSS 内存泄漏故障模式库（LLM Reference）

> 本文档为模型检索与匹配设计，仅保留 PSS 泄漏相关故障模式。每个故障模式（FM）为独立条目，包含固定字段，支持按 ID 引用。

---

## Schema 说明

```text
FM-ID       : 唯一标识，格式 FM-<层级>-<编号>，L1/L2/L3 分别对应一/二/三级根因
name        : 根因名称
level       : L1 | L2 | L3
parent      : 上级 FM-ID（L1 为 null）
category    : 泄漏 | 不合理使用 | null（仅 L3 必填）
trigger     : 故障触发条件（仅 L1）
detect_ops  : 运维态检测方法
smaps_tag   : smaps 中对应的内存类型标识（L2 适用）
keywords    : 日志关键字列表（用于匹配）
description : 详细说明
children    : 子 FM-ID 列表
```

---

# L1 根因条目

## FM-L1-PSS

```text
FM-ID      : FM-L1-PSS
name       : 进程 PSS 泄漏
level      : L1
parent     : null
definition : 单进程按比例分摊后的内存占用持续增长，核心观测指标为 PSS
trigger    : RESOURCE_OVERLIMIT 事件中 resource_type == "pss_memory"，或 sample 文件中 totalpss 持续增长并达到泄漏判定阈值
detect_ops :
  - 订阅 RESOURCE_OVERLIMIT 事件
  - 过滤条件: resource_type == "pss_memory"
  - 分析 sample 文件中的 totalpss / totalmem 增长趋势
  - 分析 smaps 文件中的 PSS 子类型占比
keywords   : [pss_memory, RESOURCE_OVERLIMIT, totalpss, smaps]
children   : [FM-L2-PSS-01, FM-L2-PSS-02, FM-L2-PSS-03, FM-L2-PSS-04]
```

---

# L2 根因条目（PSS 泄漏分支）

## FM-L2-PSS-01

```text
FM-ID     : FM-L2-PSS-01
name      : NativeHeap 堆内存泄漏
level     : L2
parent    : FM-L1-PSS
smaps_tag : native_heap / jemalloc
detect_ops:
  - sample 文件显示 totalpss 持续增长
  - smaps 文件中 native_heap / jemalloc 占比最高或增长最明显
  - native_parser 结果中存在突出的 size / allocated 分档
children  : [FM-L3-PSS-01, FM-L3-PSS-02, FM-L3-PSS-03, FM-L3-PSS-04, FM-L3-PSS-05, FM-L3-PSS-06]
```

## FM-L2-PSS-02

```text
FM-ID     : FM-L2-PSS-02
name      : ArkTS / 虚拟机对象 PSS 泄漏
level     : L2
parent    : FM-L1-PSS
smaps_tag : arkts / jsvm / kmp / flutter / dart / rn / v8
detect_ops:
  - sample 文件显示 totalpss 持续增长
  - smaps 文件中虚拟机堆相关类型占比最高或增长最明显
  - 需要结合 heapsnapshot 或虚拟机对象快照进一步定位对象类型
children  : [FM-L3-PSS-07, FM-L3-PSS-08, FM-L3-PSS-09]
```

## FM-L2-PSS-03

```text
FM-ID     : FM-L2-PSS-03
name      : 匿名映射 PSS 泄漏
level     : L2
parent    : FM-L1-PSS
smaps_tag : anon / annon others
detect_ops:
  - sample 文件显示 totalpss 持续增长
  - smaps 文件中 anon / annon others 占比最高或增长最明显
  - profiler 或 native hook 栈显示 mmap / 内存映射相关调用持续增长
children  : [FM-L3-PSS-10, FM-L3-PSS-11]
```

## FM-L2-PSS-04

```text
FM-ID     : FM-L2-PSS-04
name      : 文件映射 PSS 占用过大
level     : L2
parent    : FM-L1-PSS
smaps_tag : shared library / database / font / hap / file others
detect_ops:
  - sample 文件显示 totalpss 持续增长或长期维持高位
  - smaps 文件中文件映射类内存占比最高或增长最明显
  - 结合文件类型判断是否存在资源未关闭或加载过量
children  : [FM-L3-PSS-12, FM-L3-PSS-13, FM-L3-PSS-14, FM-L3-PSS-15, FM-L3-PSS-16]
```

---

# L3 根因条目

## FM-L3-PSS-01

```text
FM-ID      : FM-L3-PSS-01
name       : 循环引用
level      : L3
parent     : FM-L2-PSS-01
category   : 泄漏
description: 多个智能指针或对象之间相互持有，构成环状引用，导致引用计数无法清零，NativeHeap PSS 持续增长
```

## FM-L3-PSS-02

```text
FM-ID      : FM-L3-PSS-02
name       : 生命周期管理不当
level      : L3
parent     : FM-L2-PSS-01
category   : 泄漏
description: 通过系统接口或三方库申请 Native 资源后未按生命周期释放，导致 NativeHeap PSS 持续增长
```

## FM-L3-PSS-03

```text
FM-ID      : FM-L3-PSS-03
name       : 跨语言对象持有导致泄漏
level      : L3
parent     : FM-L2-PSS-01
category   : 泄漏
description: ArkTS / JS 对象与 Native 对象跨语言互相持有，托管侧对象已无业务引用但 Native 对象无法回收
```

## FM-L3-PSS-04

```text
FM-ID      : FM-L3-PSS-04
name       : 过量缓存
level      : L3
parent     : FM-L2-PSS-01
category   : 不合理使用
description: 业务通过缓存机制保留 Native 内存，缓存阈值或清理策略不合理，导致 PSS 长期增长或维持高位
```

## FM-L3-PSS-05

```text
FM-ID      : FM-L3-PSS-05
name       : 业务过载（消费不及时）
level      : L3
parent     : FM-L2-PSS-01
category   : 不合理使用
description: 业务请求方持续申请内存，消费方因流程阻塞、处理变慢或系统负载原因消费不及时，导致内存堆积
```

## FM-L3-PSS-06

```text
FM-ID      : FM-L3-PSS-06
name       : 业务过载（资源消耗大）
level      : L3
parent     : FM-L2-PSS-01
category   : 不合理使用
description: 业务场景本身需要申请大量 Native 内存，资源规格或并发规模超出合理范围，导致 PSS 超限
```

## FM-L3-PSS-07

```text
FM-ID      : FM-L3-PSS-07
name       : ArkTS / JS 对象未释放
level      : L3
parent     : FM-L2-PSS-02
category   : 泄漏
description: 虚拟机堆相关 smaps 占比持续增长，需要结合 heapsnapshot 或对象快照定位未释放对象、引用链和 GC Root
```

## FM-L3-PSS-08

```text
FM-ID      : FM-L3-PSS-08
name       : 虚拟机缓存过量
level      : L3
parent     : FM-L2-PSS-02
category   : 不合理使用
description: 虚拟机侧缓存、编译产物、运行时对象池等增长过快或清理不及时，导致虚拟机堆 PSS 增长
```

## FM-L3-PSS-09

```text
FM-ID      : FM-L3-PSS-09
name       : 三方运行时对象堆积
level      : L3
parent     : FM-L2-PSS-02
category   : 泄漏
description: Flutter、Dart、RN、V8、KMP 等三方运行时对象未及时释放，导致对应虚拟机堆 PSS 持续增长
```

## FM-L3-PSS-10

```text
FM-ID      : FM-L3-PSS-10
name       : mmap 大内存申请
level      : L3
parent     : FM-L2-PSS-03
category   : 不合理使用
description: 业务通过 mmap 申请了过大的匿名映射内存，导致 anon PSS 占比异常
```

## FM-L3-PSS-11

```text
FM-ID      : FM-L3-PSS-11
name       : mmap 内存未释放
level      : L3
parent     : FM-L2-PSS-03
category   : 泄漏
description: 使用 mmap 申请内存后未调用 munmap 释放，导致匿名映射 PSS 持续增长
```

## FM-L3-PSS-12

```text
FM-ID      : FM-L3-PSS-12
name       : so 共享库占用过大
level      : L3
parent     : FM-L2-PSS-04
category   : 不合理使用
description: 进程加载的 .so 共享库数量或体积过大，文件映射 PSS 占用偏高
```

## FM-L3-PSS-13

```text
FM-ID      : FM-L3-PSS-13
name       : 数据库未关闭
level      : L3
parent     : FM-L2-PSS-04
category   : 泄漏
description: 数据库不再使用后未执行关闭操作，相关文件映射和缓存长期占用 PSS
```

## FM-L3-PSS-14

```text
FM-ID      : FM-L3-PSS-14
name       : 同时打开数据库过多
level      : L3
parent     : FM-L2-PSS-04
category   : 不合理使用
description: 并发打开大量数据库连接或数据库文件，占用内存累积，导致文件映射 PSS 偏高
```

## FM-L3-PSS-15

```text
FM-ID      : FM-L3-PSS-15
name       : 字体资源加载过多
level      : L3
parent     : FM-L2-PSS-04
category   : 不合理使用
description: 应用加载字体数量过多或单个字体文件体积过大，导致字体文件映射 PSS 占用偏高
```

## FM-L3-PSS-16

```text
FM-ID      : FM-L3-PSS-16
name       : HAP / 字节码资源过大
level      : L3
parent     : FM-L2-PSS-04
category   : 不合理使用
description: HAP 包、ArkTS 字节码或其他资源文件体积过大，导致文件映射 PSS 占用偏高
```

---

# 匹配决策树（模型使用）

```text
INPUT: sample / smaps / RESOURCE_OVERLIMIT 信息
│
├── Step 1: 判断是否为 PSS 泄漏
│     ├── RESOURCE_OVERLIMIT(resource_type=pss_memory) → FM-L1-PSS
│     └── sample 中 totalpss 持续增长              → FM-L1-PSS
│
├── Step 2: 解析 smaps / native_parser 输出确定 L2
│     ├── native_heap / jemalloc 占比最高或增长最明显 → FM-L2-PSS-01
│     ├── arkts / jsvm / kmp / flutter / dart / rn / v8 占比最高或增长最明显 → FM-L2-PSS-02
│     ├── anon / annon others 占比最高或增长最明显 → FM-L2-PSS-03
│     └── shared library / database / font / hap / file others 占比最高或增长最明显 → FM-L2-PSS-04
│
└── Step 3: 结合调用栈、对象快照、资源生命周期和业务上下文确定 L3
      ├── 对象引用/释放相关 → category=泄漏
      └── 资源申请量/配置相关 → category=不合理使用
```
