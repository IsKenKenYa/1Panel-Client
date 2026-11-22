---
name: hmos-performance-analysis-kit-crash-event-subscription
description: 订阅应用崩溃事件，支持NativeCrash和JsError两种崩溃类型，最大支持5MB日志文件（启用minidump时35MB），适用于应用崩溃监控、故障定位、调试分析场景
---

# 订阅崩溃事件（ArkTS）技能

## 功能描述

使用HiAppEvent ArkTS接口订阅应用崩溃事件，实时捕获应用运行过程中发生的崩溃故障。支持两种崩溃类型：
- **NativeCrash**：Native代码崩溃，通过进程外采集故障信息，平均耗时约2秒
- **JsError**：ArkTS/JS代码异常，通过进程内采集故障信息，实时回调

订阅崩溃事件可帮助开发者：
- 快速定位崩溃原因和调用栈信息
- 获取崩溃时的系统状态（内存、进程信息等）
- 收集完整的崩溃日志文件用于深度分析
- 监控应用稳定性，及时发现和修复问题

**关键特性**：
- 实时回调：崩溃发生后立即通知观察者
- 自定义参数：可设置崩溃事件自定义参数，附加业务信息
- 日志配置：可配置崩溃日志规格（截断大小、内存打印范围等）
- 页面切换日志：从API version 24开始支持页面切换日志采集
- 多种回调模式：支持onReceive实时回调、onTrigger条件触发、手动takeNext获取

## 使用场景

### 触发词
- "订阅崩溃事件"
- "监控应用崩溃"
- "捕获崩溃日志"
- "崩溃事件回调"
- "HiAppEvent订阅"
- "应用故障监控"
- "NativeCrash订阅"
- "JsError订阅"

### 能做
- 在应用启动时订阅崩溃事件，确保能够捕获所有崩溃故障
- 设置崩溃事件自定义参数，附加业务相关数据（如用户ID、操作步骤等）
- 配置崩溃日志规格，控制日志大小和详细程度
- 开启页面切换日志，记录崩溃前的页面导航路径
- 在崩溃回调中实时处理崩溃数据，打印日志或上报服务器
- 从崩溃事件中提取关键信息：崩溃类型、异常原因、调用栈、内存状态等
- 获取崩溃日志文件路径，读取完整的故障日志
- 区分应用主动捕获异常和系统捕获崩溃两种场景
- 从FaultLogger接口迁移到HiAppEvent接口

### 绝不做
- 不订阅其他类型的系统事件（如应用冻屏事件、资源泄漏事件）
- 不在回调函数中移除观察者（可能导致事件丢失）
- 不处理崩溃日志文件清理（开发者需自行管理）
- 不修改崩溃日志文件的存储路径（系统固定存储在应用沙箱目录）
- 不阻塞崩溃回调函数执行（应快速处理，避免影响应用退出）
- 不在子线程调用addWatcher（需要确保子线程不会被销毁）
- 不设置超出规格的参数（如参数名超过32字符、参数值超过1024字符）

### 补充
- **回调时机差异**：
  - 应用未主动捕获崩溃异常：崩溃事件在应用下次启动时回调
  - 应用主动捕获崩溃异常：崩溃事件在应用退出前回调
  
- **日志文件限制**：
  - 最大总大小5MB（启用minidump时35MB）
  - 日志文件处理完后需及时删除，避免空间超限导致新日志写入失败
  
- **API版本要求**：
  - 基础崩溃事件订阅：API version 9+
  - setEventParam自定义参数：API version 12+
  - setEventConfig日志配置：API version 20+
  - configEventPolicy页面切换日志：API version 24+
  
- **性能考虑**：
  - addWatcher涉及I/O操作，建议在主线程调用
  - NativeCrash日志采集耗时约2秒，不阻塞当前业务
  - JsError实时回调，速度快

## 调用规范和规则

### 输入约束
- **观察者名称**：
  - 长度：非空且不超过32个字符
  - 格式：首字符必须为字母，中间字符为数字/字母/下划线，结尾字符为数字或字母
  - 示例：`crashWatcher`, `testName1`, `app_CrashMonitor`
  
- **事件领域**：固定为 `hiAppEvent.domain.OS`（系统事件领域）
  
- **事件名称**：固定为 `hiAppEvent.event.APP_CRASH`（崩溃事件）
  
- **自定义参数**：
  - 参数名长度：不超过32个字符
  - 参数值长度：不超过1024个字符
  - 参数数量：不超过64个
  
- **日志配置参数**：
  - `log_file_cutoff_sz_bytes`：取值范围[0, 5242880]（0-5MB）
  - `extend_pc_lr_printing`：布尔值
  - `simplify_vma_printing`：布尔值
  
- **页面切换日志配置**：
  - `pageSwitchLogEnable`：布尔值（从API version 24支持）

### 执行约束
- **调用时机**：建议在应用启动后、执行业务逻辑前添加观察者
- **最大耗时**：addWatcher调用耗时毫秒级，不阻塞应用启动
- **回调处理时间**：应尽快完成回调处理，避免影响应用退出
- **日志文件处理**：崩溃日志文件应在处理完后立即删除
- **并发限制**：相同观察者名称会被后一次调用覆盖

### 内容约束
- **禁止生成**：
  - 不生成订阅其他系统事件的代码（如APP_FREEZE、RESOURCE_OVERLIMIT）
  - 不生成在回调中移除观察者的代码
  - 不生成阻塞回调执行的代码
  
- **禁止使用高危函数**：
  - 不在回调中使用耗时操作（如网络请求、大文件读写）
  - 不在回调中执行可能导致崩溃的操作
  
- **禁止操作**：
  - 不修改崩溃日志文件的默认存储路径
  - 不删除正在使用的观察者对象
  - 不在子线程中创建观察者（除非确保线程不会被销毁）

### 降级约束
- **网络失败**：无法上报崩溃数据到服务器时，保存到本地文件待后续上报
- **日志文件过大**：启用日志截断配置（log_file_cutoff_sz_bytes）
- **参数设置失败**：使用默认配置，记录失败日志
- **权限不足**：提示用户检查应用权限配置
- **多次崩溃**：崩溃回调未处理完成时再次崩溃，系统自动重启应用并上报上次崩溃事件

## 调用流程和步骤

### 步骤1：导入模块和准备阶段

**前置校验**：
1. 确认应用已启动，在EntryAbility.onCreate函数中执行
2. 确认已导入必要的模块：hiAppEvent、hilog、deviceInfo
3. 确认API版本满足需求（基础功能需API version 9+）

**模块导入**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo } from '@kit.BasicServicesKit';
```

### 步骤2：设置崩溃事件自定义参数

**示例代码**：
```typescript
// 构建崩溃事件的自定义参数
let crashParams: Record<string, hiAppEvent.ParamType> = {
  "test_data": 100, // test_data为自定义数据，开发者可根据实际需求自定义params参数
  "user_id": "user_001", // 可附加用户ID等业务信息
  "operation": "button_click" // 可附加操作步骤信息
};

// 设置崩溃事件的自定义参数（API version 12+）
hiAppEvent.setEventParam(crashParams, hiAppEvent.domain.OS, hiAppEvent.event.APP_CRASH).then(() => {
  hilog.info(0x0000, 'CrashWatcher', `HiAppEvent success to set event param`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'CrashWatcher', `HiAppEvent code: ${err.code}, message: ${err.message}`);
});
```

### 步骤3：配置崩溃日志规格（可选）

**API version 20+支持**：
```typescript
if (deviceInfo.sdkApiVersion >= 20) {
  // 构建崩溃日志规格自定义参数
  let crashConfigParams: Record<string, hiAppEvent.ParamType> = {
    "extend_pc_lr_printing": true, // 使能扩展打印pc和lr寄存器附近的内存值
    "log_file_cutoff_sz_bytes": 1024000, // 截断崩溃日志到1000KB
    "simplify_vma_printing": true // 使能精简打印maps
  };
  
  // 设置崩溃日志配置参数（仅支持NativeCrash类型）
  hiAppEvent.setEventConfig(hiAppEvent.event.APP_CRASH, crashConfigParams).then(() => {
    hilog.info(0x0000, 'CrashWatcher', `HiAppEvent success to set event config.`);
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'CrashWatcher', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

### 步骤4：配置页面切换日志（可选）

**API version 24+支持**：
```typescript
if (deviceInfo.sdkApiVersion >= 24) {
  // 配置页面切换日志
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "appCrashPolicy": {
      "pageSwitchLogEnable": true // 开启页面切换日志采集
    }
  };
  
  // 设置崩溃事件策略参数
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(0x0000, 'CrashWatcher', `HiAppEvent success to config event policy.`);
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'CrashWatcher', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

### 步骤5：添加崩溃事件观察者

**示例代码（onReceive实时回调）**：
```typescript
// 添加崩溃事件观察者
let watcher: hiAppEvent.Watcher = {
  // 观察者名称，系统会使用名称来标识不同的观察者
  name: 'crashEventWatcher',
  
  // 订阅感兴趣的系统事件，此处订阅崩溃事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS, // 系统事件领域
      names: [hiAppEvent.event.APP_CRASH] // 崩溃事件名称
    }
  ],
  
  // 实现订阅实时回调函数，对订阅获取到的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'CrashWatcher', `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      // 根据事件集合中的事件名称区分不同的系统事件
      hilog.info(0x0000, 'CrashWatcher', `HiAppEvent eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 处理崩溃事件数据
        processCrashEvent(eventInfo);
      }
    }
  }
};

// 添加观察者
hiAppEvent.addWatcher(watcher);
```

### 步骤6：处理崩溃事件回调数据

**崩溃事件数据处理函数**：
```typescript
function processCrashEvent(eventInfo: hiAppEvent.AppEventInfo) {
  // 提取崩溃事件基本信息
  hilog.info(0x0000, 'CrashWatcher', `eventInfo.domain=${eventInfo.domain}`);
  hilog.info(0x0000, 'CrashWatcher', `eventInfo.name=${eventInfo.name}`);
  hilog.info(0x0000, 'CrashWatcher', `eventInfo.eventType=${eventInfo.eventType}`);
  
  // 提取崩溃类型（NativeCrash或JsError）
  const crashType = eventInfo.params['crash_type'] as string;
  hilog.info(0x0000, 'CrashWatcher', `crash_type=${crashType}`);
  
  // 提取崩溃时间戳
  const crashTime = eventInfo.params['time'] as number;
  hilog.info(0x0000, 'CrashWatcher', `crash_time=${crashTime}`);
  
  // 提取应用前后台状态
  const foreground = eventInfo.params['foreground'] as boolean;
  hilog.info(0x0000, 'CrashWatcher', `foreground=${foreground}`);
  
  // 提取应用信息
  hilog.info(0x0000, 'CrashWatcher', `bundle_name=${eventInfo.params['bundle_name']}`);
  hilog.info(0x0000, 'CrashWatcher', `bundle_version=${eventInfo.params['bundle_version']}`);
  hilog.info(0x0000, 'CrashWatcher', `pid=${eventInfo.params['pid']}`);
  hilog.info(0x0000, 'CrashWatcher', `uid=${eventInfo.params['uid']}`);
  
  // 提取异常信息
  const exception = eventInfo.params['exception'];
  hilog.info(0x0000, 'CrashWatcher', `exception=${JSON.stringify(exception)}`);
  
  // 提取崩溃日志文件路径
  const externalLog = eventInfo.params['external_log'] as string[];
  hilog.info(0x0000, 'CrashWatcher', `external_log=${JSON.stringify(externalLog)}`);
  
  // 检查日志是否超过大小限制
  const logOverLimit = eventInfo.params['log_over_limit'] as boolean;
  hilog.info(0x0000, 'CrashWatcher', `log_over_limit=${logOverLimit}`);
  
  // 提取自定义参数
  const testData = eventInfo.params['test_data'];
  if (testData !== undefined) {
    hilog.info(0x0000, 'CrashWatcher', `test_data=${testData}`);
  }
  
  // 提取页面切换日志路径（API version 24+）
  const pageSwitchLog = eventInfo.params['page_switch_log'];
  if (pageSwitchLog !== undefined) {
    hilog.info(0x0000, 'CrashWatcher', `page_switch_log=${JSON.stringify(pageSwitchLog)}`);
  }
  
  // 根据崩溃类型进行针对性处理
  if (crashType === 'JsError') {
    processJsError(exception);
  } else if (crashType === 'NativeCrash') {
    processNativeCrash(exception, externalLog);
  }
}
```

### 步骤7：处理JsError类型崩溃

**JsError崩溃处理**：
```typescript
function processJsError(exception: any) {
  // JsError异常信息包含：name、message、stack、thread_name
  hilog.error(0x0000, 'CrashWatcher', `JsError name: ${exception.name}`);
  hilog.error(0x0000, 'CrashWatcher', `JsError message: ${exception.message}`);
  hilog.error(0x0000, 'CrashWatcher', `JsError stack: ${exception.stack}`);
  
  if (exception.thread_name !== undefined) {
    hilog.info(0x0000, 'CrashWatcher', `thread_name: ${exception.thread_name}`);
  }
  
  // JsError通过进程内采集，实时回调，速度快
  // 可以立即进行错误上报或保存到本地
}
```

### 步骤8：处理NativeCrash类型崩溃

**NativeCrash崩溃处理**：
```typescript
function processNativeCrash(exception: any, externalLog: string[]) {
  // NativeCrash异常信息包含：message、signal、thread_name、tid、frames
  hilog.error(0x0000, 'CrashWatcher', `NativeCrash message: ${exception.message}`);
  hilog.error(0x0000, 'CrashWatcher', `NativeCrash signal: ${JSON.stringify(exception.signal)}`);
  hilog.error(0x0000, 'CrashWatcher', `NativeCrash tid: ${exception.tid}`);
  
  if (exception.thread_name !== undefined) {
    hilog.info(0x0000, 'CrashWatcher', `thread_name: ${exception.thread_name}`);
  }
  
  // 打印调用栈帧
  if (exception.frames !== undefined) {
    for (const frame of exception.frames) {
      hilog.info(0x0000, 'CrashWatcher', 
        `frame: file=${frame.file}, symbol=${frame.symbol}, pc=${frame.pc}`);
    }
  }
  
  // NativeCrash通过进程外采集，耗时约2秒
  // 崩溃日志文件存储在externalLog路径中
  if (externalLog && externalLog.length > 0) {
    hilog.info(0x0000, 'CrashWatcher', `Crash log files: ${externalLog.length}`);
    // 可以读取崩溃日志文件进行深度分析
    // 注意：处理完后应及时删除日志文件
  }
}
```

### 步骤9：错误处理

**错误处理代码**：
```typescript
// 在设置参数和配置时捕获错误
try {
  await hiAppEvent.setEventParam(crashParams, hiAppEvent.domain.OS, hiAppEvent.event.APP_CRASH);
} catch (err) {
  const error = err as BusinessError;
  switch (error.code) {
    case 11100001:
      hilog.error(0x0000, 'CrashWatcher', 'Function disabled. Enable hiAppEvent first.');
      break;
    case 11101001:
      hilog.error(0x0000, 'CrashWatcher', 'Invalid event domain. Check domain format.');
      break;
    case 11101002:
      hilog.error(0x0000, 'CrashWatcher', 'Invalid event name. Check event name format.');
      break;
    case 11101004:
      hilog.error(0x0000, 'CrashWatcher', 'Invalid string length of event parameter.');
      break;
    case 11101005:
      hilog.error(0x0000, 'CrashWatcher', 'Invalid event parameter name.');
      break;
    case 11101007:
      hilog.error(0x0000, 'CrashWatcher', 'Number of parameter keys exceeds limit (max 64).');
      break;
    default:
      hilog.error(0x0000, 'CrashWatcher', `Unknown error: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤10：降级处理

**降级处理代码**：
```typescript
// 如果设置自定义参数失败，使用默认配置
async function setupCrashWatcherWithFallback() {
  try {
    // 尝试设置自定义参数
    await hiAppEvent.setEventParam(crashParams, hiAppEvent.domain.OS, hiAppEvent.event.APP_CRASH);
    hilog.info(0x0000, 'CrashWatcher', 'Successfully set custom crash params.');
  } catch (err) {
    // 降级：使用默认配置，不设置自定义参数
    hilog.warn(0x0000, 'CrashWatcher', 'Failed to set custom params, using default config.');
  }
  
  // 无论参数设置是否成功，都添加观察者
  try {
    hiAppEvent.addWatcher(watcher);
    hilog.info(0x0000, 'CrashWatcher', 'Successfully added crash watcher.');
  } catch (err) {
    const error = err as BusinessError;
    hilog.error(0x0000, 'CrashWatcher', `Failed to add watcher: ${error.message}`);
    
    // 最终降级方案：记录错误日志，提示用户检查配置
    hilog.error(0x0000, 'CrashWatcher', 'Crash monitoring disabled. Check app configuration.');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误 | 检查参数类型和必填参数是否正确 |
| 11100001 | 打点功能被关闭 | 调用`hiAppEvent.configure({disable: false})`开启打点功能 |
| 11101001 | 非法的事件领域名称 | 确保事件领域名称只包含数字/字母/下划线，以字母开头，长度不超过32字符 |
| 11101002 | 非法的事件名称 | 确保事件名称首字符为字母或$，中间为数字/字母/下划线，结尾为数字或字母，长度不超过48字符 |
| 11101004 | 非法的事件参数字符串长度 | 确保参数值字符串长度不超过1024字符 |
| 11101005 | 非法的事件参数名称 | 确保参数名首字符为字母或$，中间为数字/字母/下划线，结尾为数字或字母，长度不超过32字符 |
| 11101007 | 非法的事件自定义参数数量 | 确保自定义参数数量不超过64个 |
| 11102001 | 非法的观察者名称 | 确保观察者名称首字符为字母，不以下划线结尾，长度不超过32字符 |
| 11102002 | 非法的过滤事件领域 | 确保事件领域名称格式正确 |
| 11102003 | 非法的条数值 | 确保row值为非负整数 |
| 11102004 | 非法的大小值 | 确保size值为非负整数 |
| 11102005 | 非法的超时值 | 确保timeout值为非负整数 |
| 11104001 | 非法的事件包大小值 | 确保size值为正整数 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "系统Kit，无需额外安装",
    "@kit.BasicServicesKit": "系统Kit，无需额外安装"
  }
}
```

### 环境要求
- **HarmonyOS API版本**：基础功能需API version 9+
  - setEventParam：API version 12+
  - setEventConfig：API version 20+
  - configEventPolicy：API version 24+
  
- **DevEco Studio版本**：建议使用最新版本（支持HarmonyOS Next开发）

- **应用类型支持**：
  - 普通应用
  - 元服务（API version 11+）
  - 应用分身
  - 输入法应用（API version 22+）

### 常见编译问题

**问题1：找不到hiAppEvent模块**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保使用HarmonyOS Next SDK，PerformanceAnalysisKit是系统Kit，无需额外安装

**问题2：deviceInfo.sdkApiVersion未定义**
```
Error: Property 'sdkApiVersion' does not exist on type 'DeviceInfo'
```
**解决方法**：确保导入正确的deviceInfo模块：`import { deviceInfo } from '@kit.BasicServicesKit';`

**问题3：API版本检查条件错误**
```
if (deviceInfo.sdkApiVersion >= 20) // 编译时报错
```
**解决方法**：检查API版本时，确保在运行时判断，不是编译时判断

**问题4：回调函数类型错误**
```
Error: Type 'void' is not assignable to type '(domain: string, appEventGroups: Array<AppEventGroup>) => void'
```
**解决方法**：确保onReceive回调函数签名正确，包含domain和appEventGroups参数

## 常见问题与解决方法

### Q1：崩溃事件订阅后没有回调
**原因**：
- 应用未发生崩溃
- 观察者名称重复，被后一次调用覆盖
- 未在应用启动时添加观察者
- 应用崩溃但未重启（应用未主动捕获异常场景）

**解决方法**：
- 构造崩溃场景测试订阅功能（如调用`JSON.parse('')`触发JsError）
- 确保观察者名称唯一
- 在EntryAbility.onCreate中添加观察者
- 重启应用查看崩溃事件回调

### Q2：崩溃事件回调时机不符合预期
**原因**：
- 应用未主动捕获崩溃异常：崩溃事件在下次启动时回调
- 应用主动捕获崩溃异常：崩溃事件在退出前回调

**解决方法**：
- 理解两种场景的回调时机差异
- 若应用长时间未启动，可使用FaultLogExtensionAbility延迟上报
- 在异常处理中主动退出，避免应用崩溃后不退出

### Q3：崩溃日志文件读取失败
**原因**：
- 日志文件路径错误
- 应用权限不足
- 日志文件被系统清理

**解决方法**：
- 从external_log字段获取正确的日志文件路径
- 确保应用有文件读取权限
- 及时读取和处理日志文件，避免文件被清理

### Q4：崩溃日志文件占用空间过大
**原因**：
- 多次崩溃产生大量日志文件
- 日志文件未及时清理
- 日志总大小超过5MB限制（启用minidump时35MB）

**解决方法**：
- 设置log_file_cutoff_sz_bytes截断日志大小
- 处理完日志文件后立即删除
- 启用simplify_vma_printing精简打印maps信息

### Q5：自定义参数未附加到崩溃事件中
**原因**：
- setEventParam调用失败
- 参数名或参数值不符合规格
- 打点功能被关闭

**解决方法**：
- 检查setEventParam调用是否成功，捕获错误码
- 确保参数名长度不超过32字符，参数值不超过1024字符
- 调用`hiAppEvent.configure({disable: false})`开启打点功能

### Q6：页面切换日志未生成
**原因**：
- API版本低于24
- 未配置pageSwitchLogEnable
- 应用崩溃前未发生页面切换

**解决方法**：
- 确保API版本>=24
- 调用configEventPolicy配置pageSwitchLogEnable为true
- 确保应用有页面导航行为

### Q7：NativeCrash日志采集耗时过长
**原因**：
- NativeCrash通过进程外采集故障信息，平均耗时约2秒
- 业务线程数量多，进程间通信耗时

**解决方法**：
- 理解NativeCrash采集机制，不阻塞当前业务
- 崩溃事件异步上报，不影响应用退出
- 如需快速回调，考虑使用JsError崩溃场景测试

### Q8：从FaultLogger迁移到HiAppEvent的接口对应关系
**原因**：FaultLogger接口从API version 18开始废弃

**解决方法**：
- FaultLogger.FaultType.CPP_CRASH → hiAppEvent.event.APP_CRASH，params.crash_type='NativeCrash'
- FaultLogger.FaultType.JS_CRASH → hiAppEvent.event.APP_CRASH，params.crash_type='JsError'
- FaultLogInfo.pid → params.pid
- FaultLogInfo.uid → params.uid
- FaultLogInfo.timestamp → params.time
- FaultLogInfo.module → params.bundle_name
- FaultLogInfo.fullLog → params.external_log（日志文件路径）
- FaultLogger.query → hiAppEvent.addWatcher + onReceive回调

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "crashEventSubscription": {
    "watcherName": "crashEventWatcher",
    "eventDomain": "OS",
    "eventName": "APP_CRASH",
    "customParamsSet": true,
    "logConfigSet": true,
    "pageSwitchLogEnabled": false
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.setEventParam",
    "hiAppEvent.setEventConfig",
    "hiAppEvent.configEventPolicy"
  ],
  "subscriptionMode": "onReceive",
  "supportedCrashTypes": ["NativeCrash", "JsError"],
  "logFileLimit": "5MB",
  "apiVersion": {
    "minimum": 9,
    "customParams": 12,
    "logConfig": 20,
    "pageSwitchLog": 24
  }
}
```

## 参考文档

- [API开发指南：订阅崩溃事件（ArkTS）](references/hiappevent-watcher-crash-events-arkts.md)
- [API参考说明：@ohos.hiviewdfx.hiAppEvent](references/js-apis-hiviewdfx-hiappevent.md)
- [崩溃事件介绍](references/hiappevent-watcher-crash-events.md)
- [错误码说明](references/errorcode-hiappevent.md)

**在线文档链接**：
- https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events-arkts
- https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent
- https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events

## 完整示例代码

- [ArkTS完整示例](assets/crash_event_subscription_example.ets) - 包含崩溃事件订阅、参数设置、日志配置、回调处理的完整示例
- [崩溃事件处理工具类](assets/crash_event_processor.ets) - 提供崩溃事件数据解析和处理的工具类
- [配置文件示例](assets/crash_watcher_config.json) - 崩溃观察者配置参数示例

## 测试用例

### 正向测试用例
- [测试：订阅崩溃事件并成功回调](tests/test_positive_crash_subscription.ets) - 测试正常订阅崩溃事件并在崩溃后成功回调
- [测试：设置自定义参数成功](tests/test_positive_custom_params.ets) - 测试成功设置崩溃事件自定义参数
- [测试：配置崩溃日志成功](tests/test_positive_log_config.ets) - 测试成功配置崩溃日志规格参数

### 边界测试用例
- [测试：观察者名称长度边界](tests/test_boundary_watcher_name.ets) - 测试观察者名称长度为32字符的边界情况
- [测试：自定义参数数量边界](tests/test_boundary_params_count.ets) - 测试自定义参数数量为64个的边界情况
- [测试：日志截断大小边界](tests/test_boundary_log_size.ets) - 测试日志截断大小为5MB的边界情况

### 异常测试用例
- [测试：观察者名称格式错误](tests/test_exception_invalid_watcher_name.ets) - 测试观察者名称包含非法字符的情况
- [测试：参数值长度超限](tests/test_exception_param_length_exceed.ets) - 测试参数值长度超过1024字符的情况
- [测试：打点功能关闭](tests/test_exception_function_disabled.ets) - 测试打点功能关闭时订阅失败的情况
- [测试：日志文件空间超限](tests/test_exception_log_over_limit.ets) - 测试日志文件总大小超过5MB限制的情况