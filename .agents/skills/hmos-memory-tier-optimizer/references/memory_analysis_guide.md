# HarmonyOS 内存分析指南

## meminfo 输出格式详解

### 列说明

| 列名 | 说明 |
|------|------|
| Pss Total | 按比例分摊的内存（Proportional Set Size） |
| Shared Clean | 共享的干净页（未被修改，可回收） |
| Shared Dirty | 共享的脏页（已被修改） |
| Private Clean | 私有的干净页 |
| Private Dirty | 私有的脏页 |
| Swap Total | 交换到磁盘的总内存 |
| SwapPss Total | 按比例分摊的交换内存 |
| Heap Size | 堆总大小 |
| Heap Alloc | 堆已分配大小 |
| Heap Free | 堆空闲大小 |

### PSS 计算公式

```
单项类型 PSS = PSS Total + SwapPss Total
Total PSS = 仅 PSS Total（不包含 Swap）

验证: 所有类型的 (PSS Total + SwapPss Total) 之和 = Total PSS Total
```

## 内存类型详解

### 1. native heap

**定义**: 通过 malloc/free、new/delete 分配的 Native 内存

**组成**:
- jemalloc meta: jemalloc 内存分配器元数据
- jemalloc heap: jemalloc 管理的堆内存
- brk heap: 通过 brk/sbrk 分配的内存
- musl heap: musl libc 堆内存

**优化方向**:
- 检查 C/C++ 代码中的内存泄漏
- 使用 Native Memory Profiler 分析
- 检查第三方库的内存管理

### 2. ark ts heap

**定义**: ArkTS/JavaScript 运行时堆内存

**特点**:
- 由 Ark 引擎管理
- 包含 JS 对象、闭包、数组等
- 会触发 GC 回收

**优化方向**:
- 避免全局变量持有大对象
- 及时移除事件监听器
- 检查闭包引用链
- 使用 ArkTS Memory Profiler

### 3. .so

**定义**: 动态链接库占用的内存

**来源**:
- 系统库（libc、libm 等）
- 第三方库
- 应用 Native 库

**优化方向**:
- 减少不必要的库依赖
- 使用动态加载替代静态依赖
- 检查库的符号导出

### 4. .hap

**定义**: 应用安装包（HAP）占用的内存

**内容**:
- 代码段
- 资源文件（图片、配置等）

**优化方向**:
- 压缩资源文件
- 按需加载资源
- 减少冗余代码

### 5. GL / Graph

**定义**: 图形相关内存

**内容**:
- OpenGL ES 资源
- 纹理内存
- Framebuffer

**优化方向**:
- 优化图片大小和格式
- 及时释放纹理资源
- 使用纹理压缩格式

### 6. .ttf

**定义**: 字体文件占用的内存

**优化方向**:
- 按需加载字体
- 使用系统字体
- 减少自定义字体数量

### 7. stack

**定义**: 线程栈内存

**计算**: 栈内存 ≈ 线程数 × 栈大小（通常 1MB/线程）

**优化方向**:
- 减少线程数量
- 使用线程池
- 检查线程泄漏

## 内存分析方法

### 1. 占比分析法

计算各内存类型占总内存的比例：

```
占比 = (类型 PSS / Total PSS) × 100%
```

**关注点**:
- native heap > 50%: 可能存在 Native 内存问题
- ark ts heap > 40%: 可能存在 JS 内存问题
- .so > 20%: 检查库依赖

### 2. 对比分析法

在不同时间点采样对比：

```
内存增长 = 采样2 PSS - 采样1 PSS
```

**关注点**:
- 持续增长: 可能内存泄漏
- 突然增长: 检查操作触发点
- 无法回收: 检查 GC/释放逻辑

### 3. 组件分析法

结合 UI 树分析内存分布：

1. 识别复杂 UI 组件
2. 关联组件与内存占用
3. 优化高频渲染组件

## 常见问题诊断

### 问题 1: 应用启动后内存持续增长

**诊断步骤**:
1. 多次采样 meminfo
2. 对比各类型内存变化
3. 定位增长最快的类型
4. 使用对应 Profiler 深入分析

### 问题 2: 滑动列表时内存增长

**可能原因**:
- List/Grid 的 cacheCount 设置过大
- Item 组件未正确复用
- 图片未及时释放

**解决方案**:
- 参考 harmony-scroll-memory-optimizer skill
- 调整 cacheCount 配置
- 实现图片懒加载和缓存

### 问题 3: 后台内存未释放

**可能原因**:
- 全局变量持有引用
- 事件监听器未移除
- 定时器未清除

**解决方案**:
- 在 aboutToDisappear 中清理资源
- 使用弱引用
- 检查生命周期管理

## 工具对比

| 工具 | 用途 | 优势 |
|------|------|------|
| hidumper --mem | 查看进程内存分布 | 快速、全面 |
| Memory Profiler | 实时内存监控 | 可视化、时间线 |
| Native Memory Profiler | Native 内存分析 | 详细分配栈 |
| ArkTS Memory Profiler | JS 堆分析 | 对象引用链 |

## 分析报告模板

```markdown
# 内存分析报告

## 基本信息
- 应用: {bundleName}
- PID: {pid}
- 采样时间: {timestamp}

## 内存概览
| 类型 | PSS (kB) | 占比 |
|------|----------|------|
| native heap | xxx | xx% |
| ark ts heap | xxx | xx% |
| .so | xxx | xx% |
| Total | xxx | 100% |

## 主要问题
1. {问题描述}
2. {问题描述}

## 优化建议
1. {建议}
2. {建议}

## 详细数据
见附件: meminfo.txt
```
