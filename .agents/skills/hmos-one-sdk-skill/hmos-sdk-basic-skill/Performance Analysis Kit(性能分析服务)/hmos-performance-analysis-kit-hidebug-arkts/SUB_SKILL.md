---
name: hmos-performance-analysis-kit-hidebug-arkts
description: 获取HarmonyOS应用调试信息,包括CPU使用率、内存信息、线程信息等,支持调试和调优阶段使用,适用于应用性能分析和故障排查场景
---

# HiDebug接口使用示例(ArkTS)

## 功能描述

本技能提供HarmonyOS应用调试信息获取能力,通过@ohos.hidebug模块实现。支持获取系统CPU使用率、进程内存信息、线程CPU使用情况、VM内存信息等多种调试数据,帮助开发者在调试和调优阶段分析应用性能问题。

**主要功能**:
- 获取系统CPU使用率
- 获取应用进程CPU使用率
- 获取内存信息(PSS、VSS、Native内存等)
- 获取线程CPU使用情况
- 获取VM内存信息和GC统计信息
- 应用trace采集和profiling
- 内存泄漏检测和资源限制设置

**限制条件**:
- 接口调用较为耗时,仅建议在应用调试、调优阶段使用
- 部分接口涉及跨进程通信,不建议在主线程直接调用
- 生产环境使用时需谨慎评估对应用性能的影响

## 使用场景

### 触发词
- "获取系统CPU使用率"
- "获取应用CPU使用率"
- "获取内存信息"
- "获取线程信息"
- "应用性能分析"
- "HiDebug接口"
- "hidebug调试"
- "应用调试信息"

### 能做
- 获取系统和应用的CPU使用率,用于性能监控
- 获取应用内存信息(PSS、VSS、堆内存等),用于内存泄漏排查
- 获取线程CPU使用情况,用于线程性能分析
- 获取VM内存信息和GC统计,用于内存优化
- 启动和停止应用trace采集,用于性能trace分析
- 启动和停止JS CPU profiling,用于性能剖析
- 导出VM堆快照,用于内存分析
- 设置资源限制,用于模拟资源泄漏场景
- 获取显存信息,用于图形性能分析

### 绝不做
- 不在生产环境的正式版本中调用耗时较长的接口(如getPss、getSharedDirty、getPrivateDirty等)
- 不在主线程中直接调用涉及跨进程通信的接口(如getCpuUsage、getSystemCpuUsage、getAppThreadCpuUsage等)
- 不在性能敏感的场景中频繁调用调试接口
- 不使用已废弃的接口(startProfiling/stopProfiling/dumpHeapData)
- 不重复调用startJsCpuProfiling/startAppTraceCapture而不配对stop调用

### 补充
- 建议使用异步接口(如getAppNativeMemInfoAsync)替代同步接口,避免应用卡顿
- 使用taskpool或worker开启异步线程调用耗时接口
- getSystemCpuUsage从API version 12开始支持
- 显存相关接口从API version 14开始支持
- 详细的API版本支持请参考API文档中的版本标注

## 调用规范和规则

### 输入约束
- 无文件输入要求
- 接口参数类型必须符合API定义
- 字符串参数长度限制:
  - startJsCpuProfiling的filename参数最大128字符
  - dumpJsHeapData的filename参数最大128字符
  - getServiceDump的args参数中string最大254字符
- 数值参数范围限制:
  - setAppResourceLimit的value参数需在指定范围内:
    - pss_memory: [1024, 4 * 1024 * 1024] KB
    - js_heap: [85, 95] (JS堆内存上限百分比)
    - fd: [10, 10000]
    - thread: [1, 1000]
  - startAppTraceCapture的limitSize参数最大500MB

### 执行约束
- 单次接口调用耗时:
  - 同步接口: 1ms - 数秒(如getPss耗时较长)
  - 异步接口: 使用Promise回调
- 最大并发调用: 建议串行调用,避免频繁调用影响性能
- trace采集时长: 根据limitSize和trace单位流量评估,系统推荐trace单位流量300KB/s
- profiling时长: 开发者自行控制start和stop之间的时间

### 内容约束
- 禁止在生产环境的正式版本中调用以下接口:
  - getPss (读取/proc/{pid}/smaps_rollup耗时较长)
  - getSharedDirty
  - getPrivateDirty
  - dumpJsHeapData (虚拟机堆导出极其耗时,可能导致冻屏)
  - getGraphicsMemorySync (多次跨进程通信,耗时可能达到秒级)
- 禁止在主线程中直接调用以下接口:
  - getPss
  - getSharedDirty
  - getPrivateDirty
  - getCpuUsage
  - getSystemCpuUsage
  - getAppThreadCpuUsage
  - getGraphicsMemorySync
  - getAppNativeMemInfo
- 禁止重复调用start接口而不配对stop调用:
  - startJsCpuProfiling必须与stopJsCpuProfiling配对
  - startAppTraceCapture必须与stopAppTraceCapture配对
- 禁止使用已废弃接口:
  - startProfiling (废弃,使用startJsCpuProfiling替代)
  - stopProfiling (废弃,使用stopJsCpuProfiling替代)
  - dumpHeapData (废弃,使用dumpJsHeapData替代)

### 降级约束
- 网络失败或远程调用异常: 捕获错误码11400104,提示用户重试或稍后再试
- 参数错误: 捕获错误码401,提示用户检查参数类型和范围
- trace采集失败:
  - 错误码11400102: 提示用户trace采集已开启,需先停止当前采集
  - 错误码11400103: 提示用户检查文件权限
  - 错误码11400104: 提示用户trace状态异常,建议重启应用
  - 错误码11400105: 提示用户无运行中的trace采集
- 性能敏感场景: 
  - 优先使用异步接口(getAppNativeMemInfoAsync替代getAppNativeMemInfo)
  - 使用缓存接口(getAppNativeMemInfoWithCache)
  - 使用taskpool或worker在异步线程调用

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认当前处于调试或调优阶段,非生产环境
2. 确认应用已导入@kit.PerformanceAnalysisKit模块
3. 确认调用线程:耗时接口不应在主线程调用
4. 确认API版本:部分接口需要特定API版本支持

**参数准备**:
```typescript
// 导入所需模块
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义日志标签
const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;
```

### 步骤2: 获取系统CPU使用率(示例场景)

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 获取系统CPU使用率
function getSystemCpuUsage(): void {
  try {
    const cpuUsage: number = hidebug.getSystemCpuUsage();
    hilog.info(DOMAIN, TAG, `System CPU Usage: ${(cpuUsage * 100).toFixed(2)}%`);
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    // 错误码11400104: 系统CPU使用率状态异常
    if (err.code === 11400104) {
      hilog.error(DOMAIN, TAG, 'System CPU usage status is abnormal');
    }
  }
}

// 注意: 该接口涉及跨进程通信,耗时较长,建议不要在主线程直接调用
// 可使用taskpool或worker开启异步线程调用
```

### 步骤3: 获取应用进程CPU使用率

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 获取应用进程CPU使用率
function getAppCpuUsage(): void {
  try {
    const cpuUsage: number = hidebug.getCpuUsage();
    hilog.info(DOMAIN, TAG, `App CPU Usage: ${(cpuUsage * 100).toFixed(2)}%`);
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 注意: 该接口涉及跨进程通信,建议不要在主线程直接调用
```

### 步骤4: 获取内存信息

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 获取应用Native内存信息(推荐使用异步接口)
async function getAppNativeMemInfo(): Promise<void> {
  try {
    const memInfo: hidebug.NativeMemInfo = await hidebug.getAppNativeMemInfoAsync();
    hilog.info(DOMAIN, TAG, `PSS: ${memInfo.pss} KB`);
    hilog.info(DOMAIN, TAG, `VSS: ${memInfo.vss} KB`);
    hilog.info(DOMAIN, TAG, `RSS: ${memInfo.rss} KB`);
    hilog.info(DOMAIN, TAG, `Shared Dirty: ${memInfo.sharedDirty} KB`);
    hilog.info(DOMAIN, TAG, `Private Dirty: ${memInfo.privateDirty} KB`);
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 获取VM内存信息
function getAppVMMemoryInfo(): void {
  try {
    const vmMemory: hidebug.VMMemoryInfo = hidebug.getAppVMMemoryInfo();
    hilog.info(DOMAIN, TAG, `Total Heap: ${vmMemory.totalHeap} KB`);
    hilog.info(DOMAIN, TAG, `Heap Used: ${vmMemory.heapUsed} KB`);
    hilog.info(DOMAIN, TAG, `All Array Size: ${vmMemory.allArraySize} KB`);
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 获取系统内存信息
function getSystemMemInfo(): void {
  try {
    const systemMem: hidebug.SystemMemInfo = hidebug.getSystemMemInfo();
    hilog.info(DOMAIN, TAG, `Total Memory: ${systemMem.totalMem} KB`);
    hilog.info(DOMAIN, TAG, `Free Memory: ${systemMem.freeMem} KB`);
    hilog.info(DOMAIN, TAG, `Available Memory: ${systemMem.availableMem} KB`);
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 注意: getPss、getSharedDirty、getPrivateDirty等同步接口耗时较长,不建议在主线程使用
```

### 步骤5: 获取线程CPU使用情况

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 获取应用线程CPU使用情况
function getAppThreadCpuUsage(): void {
  try {
    const threadCpuUsage: hidebug.ThreadCpuUsage[] = hidebug.getAppThreadCpuUsage();
    threadCpuUsage.forEach((thread) => {
      hilog.info(DOMAIN, TAG, `Thread ID: ${thread.threadId}, CPU Usage: ${(thread.cpuUsage * 100).toFixed(2)}%`);
    });
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 注意: 该接口涉及跨进程通信,建议不要在主线程直接调用
```

### 步骤6: JS CPU Profiling

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 启动JS CPU Profiling
function startProfiling(): void {
  try {
    hidebug.startJsCpuProfiling('cpu_profiling');
    hilog.info(DOMAIN, TAG, 'JS CPU Profiling started');
    
    // 执行需要分析的代码
    // ...
    
    // 停止Profiling
    stopProfiling();
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 停止JS CPU Profiling
function stopProfiling(): void {
  try {
    hidebug.stopJsCpuProfiling();
    hilog.info(DOMAIN, TAG, 'JS CPU Profiling stopped. Check files directory for cpu_profiling.json');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 注意: startJsCpuProfiling和stopJsCpuProfiling必须配对调用
// 输出文件位于应用的files目录下,文件名为cpu_profiling.json
```

### 步骤7: VM堆快照转储

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 导出VM堆快照
function dumpHeapSnapshot(): void {
  try {
    hidebug.dumpJsHeapData('heap_snapshot');
    hilog.info(DOMAIN, TAG, 'Heap snapshot dumped. Check files directory for heap_snapshot.heapsnapshot');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
  }
}

// 注意: 该接口极其耗时,建议不要在上架版本中调用,以避免应用冻屏
// 输出文件位于应用的files目录下,文件名为heap_snapshot.heapsnapshot
```

### 步骤8: 应用Trace采集

**示例代码**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 启动应用Trace采集
function startTraceCapture(): void {
  try {
    const tags: number[] = [hidebug.tags.ABILITY_MANAGER, hidebug.tags.ARKUI];
    const flag: hidebug.TraceFlag = hidebug.TraceFlag.MAIN_THREAD;
    const limitSize: number = 1024 * 1024; // 1MB
    
    const fileName: string = hidebug.startAppTraceCapture(tags, flag, limitSize);
    hilog.info(DOMAIN, TAG, `Trace capture started. Output file: ${fileName}`);
    
    // 执行需要trace分析的代码
    // ...
    
    // 停止Trace采集
    stopTraceCapture();
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    // 错误码11400102: Trace采集已开启
    // 错误码11400103: 文件无写入权限
    // 错误码11400104: Trace状态异常
  }
}

// 停止应用Trace采集
function stopTraceCapture(): void {
  try {
    hidebug.stopAppTraceCapture();
    hilog.info(DOMAIN, TAG, 'Trace capture stopped');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(DOMAIN, TAG, `Error code: ${err.code}, message: ${err.message}`);
    // 错误码11400104: Trace状态异常
    // 错误码11400105: 无运行中的trace采集
  }
}

// 注意: startAppTraceCapture和stopAppTraceCapture必须配对调用
// limitSize需根据实际需求评估: limitSize = 预期trace采集时长 * trace单位流量
// 系统推荐trace单位流量为300KB/s
```

### 步骤9: 错误处理

**通用错误处理模式**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

function handleHiDebugError(operation: string, error: BusinessError): void {
  hilog.error(DOMAIN, TAG, `${operation} failed: code=${error.code}, message=${error.message}`);
  
  switch (error.code) {
    case 401:
      hilog.error(DOMAIN, TAG, 'Parameter error: invalid parameter type or value');
      break;
    case 11400101:
      hilog.error(DOMAIN, TAG, 'ServiceId invalid: the system ability does not exist');
      break;
    case 11400102:
      hilog.error(DOMAIN, TAG, 'Capture trace already enabled');
      break;
    case 11400103:
      hilog.error(DOMAIN, TAG, 'No write permission on the file');
      break;
    case 11400104:
      hilog.error(DOMAIN, TAG, 'Abnormal status: remote exception or trace status abnormal');
      break;
    case 11400105:
      hilog.error(DOMAIN, TAG, 'No capture trace running');
      break;
    default:
      hilog.error(DOMAIN, TAG, `Unknown error: ${error.code}`);
  }
}

// 使用示例
function safeGetSystemCpuUsage(): number | null {
  try {
    return hidebug.getSystemCpuUsage();
  } catch (error) {
    handleHiDebugError('getSystemCpuUsage', error as BusinessError);
    return null;
  }
}
```

### 步骤10: 降级处理

**使用异步接口替代同步接口**:
```typescript
import { hidebug, hilog } from '@kit.PerformanceAnalysisKit';

const TAG = 'HiDebugDemo';
const DOMAIN = 0xFF00;

// 优先使用异步接口获取内存信息
async function getMemoryInfoAsync(): Promise<void> {
  try {
    const memInfo = await hidebug.getAppNativeMemInfoAsync();
    hilog.info(DOMAIN, TAG, `Memory info retrieved: PSS=${memInfo.pss} KB`);
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Failed to get memory info, skip analysis');
    // 降级方案:跳过内存分析,继续其他逻辑
  }
}

// 使用缓存接口提高性能
function getMemoryInfoWithCache(): void {
  try {
    // 使用缓存,有效期5分钟
    const memInfo = hidebug.getAppNativeMemInfoWithCache(false);
    hilog.info(DOMAIN, TAG, `Cached memory info: PSS=${memInfo.pss} KB`);
    
    // 强制刷新缓存
    const freshMemInfo = hidebug.getAppNativeMemInfoWithCache(true);
    hilog.info(DOMAIN, TAG, `Fresh memory info: PSS=${freshMemInfo.pss} KB`);
  } catch (error) {
    hilog.error(DOMAIN, TAG, 'Failed to get memory info');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误,参数类型错误或参数值不在有效范围内 | 检查参数类型和取值范围是否符合API要求 |
| 11400101 | ServiceId无效,系统服务不存在 | 检查serviceId参数是否正确,确保系统服务存在 |
| 11400102 | Trace采集已开启 | 先停止当前trace采集,再启动新的采集 |
| 11400103 | 文件无写入权限 | 检查应用文件权限,确保有写入权限 |
| 11400104 | 状态异常,远程调用失败或trace状态异常 | 检查系统状态,建议重启应用或设备 |
| 11400105 | 无运行中的trace采集 | 确保已启动trace采集后再调用stop |

**常见错误场景**:

1. **参数错误(401)**:
   - startJsCpuProfiling的filename参数超过128字符
   - setAppResourceLimit的value参数超出范围
   - startAppTraceCapture的limitSize参数小于最小值或超过500MB

2. **Trace采集错误**:
   - 重复调用startAppTraceCapture而不stop: 11400102
   - 未启动trace直接调用stop: 11400105
   - limitSize设置不当导致trace数据不足: 需根据实际场景评估limitSize

3. **性能问题**:
   - 主线程调用耗时接口导致应用卡顿: 使用异步线程或异步接口
   - 频繁调用调试接口影响性能: 减少调用频率,使用缓存接口

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API: 8+ (基础接口), 部分接口需要更高版本:
  - API 9+: getCpuUsage, getPrivateDirty, startJsCpuProfiling, stopJsCpuProfiling, dumpJsHeapData, getServiceDump
  - API 12+: getVss, getAppVMMemoryInfo, getAppThreadCpuUsage, startAppTraceCapture, stopAppTraceCapture, getAppMemoryLimit, getSystemCpuUsage, setAppResourceLimit, getAppNativeMemInfo, getSystemMemInfo, getVMRuntimeStats, getVMRuntimeStat, isDebugState
  - API 14+: getGraphicsMemory, getGraphicsMemorySync
  - API 18+: dumpJsRawHeapData
  - API 20+: getAppNativeMemInfoAsync, getAppNativeMemInfoWithCache, getGraphicsMemorySummary
  - API 21+: getAppVMObjectUsedSize
- 开发工具: DevEco Studio 3.1+
- 模型: 仅建议在调试和调优阶段使用

### 常见编译问题

**问题1: 模块导入错误**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit' or its corresponding type declarations.
```
**解决方法**: 
- 确保项目已升级到支持@kit方式的API导入
- 检查SDK版本是否满足要求
- 在项目配置中确保已添加必要的Kit依赖

**问题2: API版本不匹配**
```
Error: Property 'getSystemCpuUsage' does not exist on type 'typeof hidebug'.
```
**解决方法**: 
- 检查API版本,getSystemCpuUsage需要API 12+
- 在ts配置中确保target API version正确设置
- 使用条件编译或运行时检查API可用性

**问题3: 类型定义错误**
```
Error: Property 'tags' does not exist on type 'typeof hidebug'.
```
**解决方法**: 
- 确保使用正确的类型定义
- 检查API文档中hidebug.tags的正确使用方式
- 更新到最新的SDK版本

**问题4: 权限错误**
```
Error: Permission denied: ohos.permission.DUMP
```
**解决方法**: 
- getServiceDump接口需要ohos.permission.DUMP权限
- 该权限仅系统应用可申请
- 普通应用无法使用getServiceDump接口

## 常见问题与解决方法

### Q1: 调用getPss等耗时接口导致应用卡顿
**原因**: 这些接口读取/proc/{pid}/smaps_rollup节点,耗时较长
**解决方法**:
- 使用异步接口getAppNativeMemInfoAsync替代同步接口
- 使用缓存接口getAppNativeMemInfoWithCache
- 使用taskpool或worker在异步线程调用
- 避免在主线程调用这些接口

### Q2: getSystemCpuUsage返回错误码11400104
**原因**: 系统CPU使用率状态异常
**解决方法**:
- 检查系统状态,确保系统正常运行
- 重启应用后再试
- 检查是否有其他应用占用过多CPU资源

### Q3: startJsCpuProfiling报错,提示已开启
**原因**: 重复调用startJsCpuProfiling而没有stop
**解决方法**:
- 确保startJsCpuProfiling和stopJsCpuProfiling配对调用
- 在调用start之前先检查是否有profiling正在运行
- 添加异常捕获,处理重复调用的错误

### Q4: dumpJsHeapData导致应用冻屏
**原因**: 虚拟机堆导出极其耗时,且为同步接口
**解决方法**:
- 仅在调试阶段使用,不要在上架版本中调用
- 减少堆大小后再导出
- 考虑使用其他内存分析工具

### Q5: trace采集生成的文件大小不足
**原因**: limitSize设置过小,系统自动调用stopAppTraceCapture
**解决方法**:
- 根据公式评估limitSize: limitSize = 预期trace采集时长 * trace单位流量
- 系统推荐trace单位流量为300KB/s
- 实测应用trace单位流量: 设置limitSize为最大值500MB,采集N秒后查看文件大小S,计算单位流量=S/N

### Q6: 如何在非主线程调用耗时接口
**原因**: 避免在主线程调用耗时接口导致应用卡顿
**解决方法**:
- 使用@ohos.taskpool创建任务池执行耗时操作
- 使用@ohos.worker创建Worker线程执行
- 使用Promise异步接口(getAppNativeMemInfoAsync等)

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "get_debug_info",
  "timestamp": "2024-01-01T12:00:00Z",
  "apiUsed": [
    "hidebug.getSystemCpuUsage",
    "hidebug.getCpuUsage",
    "hidebug.getAppNativeMemInfoAsync",
    "hidebug.getAppVMMemoryInfo",
    "hidebug.getSystemMemInfo"
  ],
  "results": {
    "systemCpuUsage": "0.287",
    "appCpuUsage": "0.15",
    "memoryInfo": {
      "pss": "102400 KB",
      "vss": "204800 KB",
      "rss": "153600 KB"
    },
    "vmMemoryInfo": {
      "totalHeap": "51200 KB",
      "heapUsed": "30720 KB",
      "allArraySize": "10240 KB"
    }
  }
}
```

## 参考文档

- [HiDebug接口使用指南](references/hidebug-guidelines-arkts.md)
- [@ohos.hidebug API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hidebug)

## 完整示例代码

- [ArkTS示例代码](assets/hidebug-example.ets)

## 测试用例

### 正向测试用例
- [获取系统CPU使用率](tests/test_positive.py): 验证getSystemCpuUsage接口正常调用
- [获取应用内存信息](tests/test_positive.py): 验证getAppNativeMemInfoAsync接口正常调用
- [启动JS CPU Profiling](tests/test_positive.py): 验证startJsCpuProfiling/stopJsCpuProfiling配对调用

### 边界测试用例
- [参数边界测试](tests/test_boundary.py): 验证参数边界值处理
- [limitSize最大值测试](tests/test_boundary.py): 验证startAppTraceCapture的limitSize参数设置为500MB
- [并发调用测试](tests/test_boundary.py): 验证多个调试接口并发调用

### 异常测试用例
- [参数错误测试](tests/test_exception.py): 验证错误参数的处理
- [权限错误测试](tests/test_exception.py): 验证getServiceDump权限错误处理
- [重复调用测试](tests/test_exception.py): 验证重复调用start接口的错误处理