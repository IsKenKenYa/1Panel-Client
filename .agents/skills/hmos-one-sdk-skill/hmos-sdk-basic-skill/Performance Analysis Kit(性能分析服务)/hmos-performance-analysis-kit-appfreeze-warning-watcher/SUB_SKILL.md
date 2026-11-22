---
name: hmos-performance-analysis-kit-appfreeze-warning-watcher
description: 订阅应用冻屏告警事件，监听应用主线程阻塞超过5秒的系统事件，获取冻屏时的进程信息、线程调用栈、内存信息等维测数据，适用于应用性能监控、异常诊断场景
---

# 订阅应用冻屏告警事件技能

## 功能描述

本技能实现HarmonyOS应用冻屏告警事件的订阅与处理。当应用主线程阻塞超过5秒时，系统会触发应用冻屏告警事件（APP_FREEZE_WARNING），开发者可通过订阅该事件获取详细的维测信息，包括：

- 冻屏发生的时间戳和前后台状态
- 应用进程信息和版本信息
- 主线程未处理消息队列
- 同步Binder调用信息
- 全量线程调用栈
- 内存使用情况
- 异常类型和异常原因

这些信息可用于分析应用卡顿、性能瓶颈、线程阻塞等问题，帮助开发者快速定位和解决性能问题。

## 使用场景

### 触发词
- "订阅应用冻屏事件"
- "监听应用冻屏告警"
- "应用卡顿事件订阅"
- "应用冻屏检测"
- "Performance Analysis Kit冻屏监控"

### 能做
- 实时订阅应用冻屏告警事件
- 获取冻屏发生时的详细维测数据
- 提取进程、线程、内存等关键信息
- 支持自定义回调处理冻屏事件
- 配合日志系统输出维测信息

### 绝不做
- 不订阅其他类型的系统事件（如崩溃、资源泄漏等）
- 不处理应用自定义事件的订阅
- 不修改或伪造冻屏事件数据
- 不在回调函数中移除观察者（会导致订阅失效）
- 不在回调中执行耗时操作（可能阻塞事件处理）

### 补充
- 冻屏告警事件由系统自动检测触发，开发者无需手动触发
- 主线程阻塞超过5秒才会触发冻屏告警
- 系统捕获维测日志有耗时，典型情况下30s内完成，极端情况下2min左右完成
- 建议在应用启动时添加观察者，进程生命周期内保持订阅
- 订阅失败时会返回null，需要进行错误处理

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符为数字/字母/下划线，结尾字符为数字或字母，长度不超过32个字符
- 事件领域：必须使用系统领域（hiAppEvent.domain.OS）
- 事件名称：必须使用应用冻屏事件常量（hiAppEvent.event.APP_FREEZE）
- 回调函数：不能为空，必须实现onReceive回调

### 执行约束
- 最大订阅耗时：毫秒级，建议在应用启动时调用
- 最大回调处理耗时：不超过100ms，避免阻塞事件处理
- API调用频次：每个观察者名称只能订阅一次，重复订阅会覆盖前一次
- 观察者生命周期：建议在应用整个生命周期内保持订阅

### 内容约束
- 禁止在回调函数中调用removeWatcher（会导致订阅失效）
- 禁止在回调中执行异步耗时操作
- 禁止修改eventInfo.params中的数据
- 禁止使用高危函数（如eval、exec等）
- 禁止阻塞主线程超过5秒（会触发新的冻屏事件）

### 降级约束
- 订阅失败（返回null）：检查参数格式，重新调用addWatcher
- 回调未触发：等待系统捕获维测日志，最长等待2分钟
- 数据获取失败：检查事件名称和领域是否正确
- 网络或I/O异常：降级为本地日志记录，不影响订阅功能
- 观察者已存在：使用新的观察者名称或先移除旧观察者

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用已导入HiAppEvent模块
2. 确认应用运行环境支持API version 11及以上
3. 确认观察者名称符合规范（字母开头，不超过32字符）
4. 确认回调函数已实现并符合接口签名

**参数准备**：
```typescript
// 定义观察者配置
const watcherConfig: hiAppEvent.Watcher = {
  name: "freezeWatcher",  // 观察者名称，唯一标识
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,  // 系统领域
      names: [hiAppEvent.event.APP_FREEZE]  // 应用冻屏事件
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    // 回调函数实现
  }
};
```

### 步骤2：导入依赖模块

**示例代码**：
```typescript
// 在entry/src/main/ets/entryability/EntryAbility.ets文件中导入
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤3：添加事件观察者

**示例代码**：
```typescript
// 在EntryAbility的onCreate函数中添加观察者
hiAppEvent.addWatcher({
  name: "freezeWatcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'freezeTag', `domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'freezeTag', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 处理冻屏事件数据
        processFreezeEvent(eventInfo);
      }
    }
  }
});
```

### 步骤4：处理冻屏事件数据

**示例代码**：
```typescript
function processFreezeEvent(eventInfo: hiAppEvent.AppEventInfo): void {
  // 获取冻屏基本信息
  hilog.info(0x0000, 'freezeTag', `domain=${eventInfo.domain}`);
  hilog.info(0x0000, 'freezeTag', `name=${eventInfo.name}`);
  hilog.info(0x0000, 'freezeTag', `eventType=${eventInfo.eventType}`);
  
  // 获取冻屏发生时间
  const freezeTime = eventInfo.params['time'];
  hilog.info(0x0000, 'freezeTag', `freezeTime=${freezeTime}`);
  
  // 获取前后台状态
  const foreground = eventInfo.params['foreground'];
  hilog.info(0x0000, 'freezeTag', `foreground=${foreground}`);
  
  // 获取进程信息
  const bundleName = eventInfo.params['bundle_name'];
  const processName = eventInfo.params['process_name'];
  const pid = eventInfo.params['pid'];
  const uid = eventInfo.params['uid'];
  hilog.info(0x0000, 'freezeTag', `bundle=${bundleName}, process=${processName}, pid=${pid}, uid=${uid}`);
  
  // 获取异常信息
  const exception = eventInfo.params['exception'];
  hilog.info(0x0000, 'freezeTag', `exception=${JSON.stringify(exception)}`);
  
  // 获取线程调用栈
  const threads = eventInfo.params['threads'];
  hilog.info(0x0000, 'freezeTag', `threadsCount=${threads.length}`);
  
  // 获取内存信息
  const memory = eventInfo.params['memory'];
  hilog.info(0x0000, 'freezeTag', `memory=${JSON.stringify(memory)}`);
  
  // 获取未处理消息
  const eventHandler = eventInfo.params['event_handler'];
  hilog.info(0x0000, 'freezeTag', `eventHandlerSize=${eventHandler.length}`);
  
  // 获取Binder调用信息
  const peerBinder = eventInfo.params['peer_binder'];
  hilog.info(0x0000, 'freezeTag', `peerBinderSize=${peerBinder.length}`);
}
```

### 步骤5：错误处理

**示例代码**：
```typescript
try {
  const holder = hiAppEvent.addWatcher({
    name: "freezeWatcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_FREEZE]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 回调实现
    }
  });
  
  if (holder === null) {
    hilog.error(0x0000, 'freezeTag', 'Failed to add watcher');
    // 降级处理：使用本地日志记录
  }
} catch (error) {
  hilog.error(0x0000, 'freezeTag', `Error: ${error.code}, ${error.message}`);
  // 根据错误码进行降级处理
  handleWatcherError(error);
}
```

### 步骤6：移除观察者（可选）

**示例代码**：
```typescript
// 在需要取消订阅时调用
const watcher: hiAppEvent.Watcher = {
  name: "freezeWatcher",
};

hiAppEvent.removeWatcher(watcher);
hilog.info(0x0000, 'freezeTag', 'Watcher removed');
```

### 步骤7：触发冻屏测试（仅用于测试）

**示例代码**：
```typescript
// 在测试页面中添加按钮触发冻屏
@Entry
@Component
struct TestPage {
  build() {
    Column() {
      Button("触发冻屏告警")
        .onClick(() => {
          // 主线程阻塞超过5秒，触发冻屏告警
          const startTime = Date.now();
          while (Date.now() - startTime <= 6500) {
            // 空循环阻塞主线程
          }
        })
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：必填参数未指定、参数类型错误 | 检查watcher对象的name、appEventFilters等参数是否符合规范 |
| 11102001 | 观察者名称无效。可能原因：包含非法字符、长度无效 | 确保name首字符为字母，长度不超过32字符，只包含数字字母下划线 |
| 11102002 | 事件领域无效。可能原因：包含非法字符、长度无效 | 使用系统领域常量hiAppEvent.domain.OS，不要自定义领域名称 |
| 11102003 | row值无效。row值小于零 | 如果设置triggerCondition.row，确保为正整数 |
| 11102004 | size值无效。size值小于零 | 如果设置triggerCondition.size，确保为正整数 |
| 11102005 | timeout值无效。timeout值小于零 | 如果设置triggerCondition.timeOut，确保为正整数 |

## 编译和修复问题

### 依赖声明
确保应用已正确导入PerformanceAnalysisKit模块：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 环境要求
- HarmonyOS API version：11及以上
- 系统能力：SystemCapability.HiviewDFX.HiAppEvent
- 开发工具：DevEco Studio 3.1及以上

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：检查DevEco Studio版本是否支持API version 11，确保项目配置正确。

**问题2：类型定义错误**
```
Error: Property 'APP_FREEZE' does not exist on type 'event'
```
**解决方法**：确保使用正确的常量名称，API version 11及以上支持APP_FREEZE常量。

**问题3：回调函数签名错误**
```
Error: Type 'void' is not assignable to type '(domain: string, appEventGroups: Array<AppEventGroup>) => void'
```
**解决方法**：确保回调函数参数类型正确，domain为string，appEventGroups为Array<AppEventGroup>。

**问题4：观察者添加失败返回null**
```
holder is null
```
**解决方法**：检查观察者名称是否符合规范，确保不重复添加同名观察者。

## 常见问题与解决方法

### Q1：订阅后回调未触发
**原因**：
- 应用未发生冻屏事件（主线程阻塞未超过5秒）
- 系统捕获维测日志耗时较长（最长2分钟）
- 回调函数签名错误

**解决方法**：
- 确认应用确实发生了冻屏（主线程阻塞超过5秒）
- 等待足够时间让系统完成维测日志捕获
- 检查回调函数参数类型和签名是否正确
- 使用hilog确认回调函数是否被调用

### Q2：获取的事件数据不完整
**原因**：
- 维测日志未完全捕获
- 事件字段名称错误
- params对象解析失败

**解决方法**：
- 等待系统完成维测日志捕获（最长2分钟）
- 使用正确的事件字段名称（如time、foreground、exception等）
- 使用JSON.stringify输出完整params对象进行调试
- 检查eventInfo.params的类型和结构

### Q3：观察者添加失败返回null
**原因**：
- 观察者名称不符合规范
- 参数类型错误
- 系统资源不足

**解决方法**：
- 检查name参数格式（字母开头，不超过32字符）
- 确保appEventFilters中的domain和names正确
- 使用try-catch捕获异常，输出错误信息
- 检查系统资源使用情况

### Q4：重复添加观察者导致覆盖
**原因**：
- 使用相同的观察者名称多次调用addWatcher
- 后一次调用覆盖前一次的订阅

**解决方法**：
- 使用唯一的观察者名称
- 在添加新观察者前先移除旧观察者
- 避免在应用运行期间重复添加观察者

### Q5：回调函数阻塞导致性能问题
**原因**：
- 回调函数中执行耗时操作
- 回调函数阻塞事件处理流程

**解决方法**：
- 回调函数只做轻量级处理（如日志输出）
- 将耗时操作放到子线程执行
- 避免在回调中调用removeWatcher
- 使用Worker实现异步处理

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "freezeWatcher",
  "eventType": "APP_FREEZE",
  "eventDomain": "OS",
  "subscriptionTime": "应用启动时",
  "dataFields": [
    "time - 冻屏发生时间戳",
    "foreground - 前后台状态",
    "app_running_unique_id - 应用唯一关联ID",
    "bundle_version - 应用版本",
    "bundle_name - 应用包名",
    "process_name - 进程名称",
    "pid - 进程ID",
    "uid - 用户ID",
    "exception - 异常类型和原因",
    "hilog - 日志信息数组",
    "event_handler - 未处理消息数组",
    "peer_binder - Binder调用数组",
    "threads - 线程调用栈数组",
    "memory - 内存信息对象",
    "process_life_time - 进程存活时间"
  ],
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.removeWatcher",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.APP_FREEZE"
  ]
}
```

## 参考文档

- [订阅应用冻屏告警事件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-appfreezewarning-events-arkts)
- [应用事件打点API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS完整示例](assets/appfreeze_watcher_example.ets) - 包含订阅、回调处理、错误处理的完整代码
- [测试页面示例](assets/test_page.ets) - 用于触发冻屏告警的测试页面

## 测试用例

### 正向测试用例
- [正常订阅冻屏事件](tests/test_positive.ets) - 验证订阅成功，回调正常触发
- [获取完整冻屏数据](tests/test_positive.ets) - 验证所有事件字段正确获取

### 边界测试用例
- [观察者名称长度边界](tests/test_boundary.ets) - 测试name长度为32字符时的处理
- [连续冻屏事件](tests/test_boundary.ets) - 测试连续触发多个冻屏事件的处理

### 异常测试用例
- [无效观察者名称](tests/test_exception.ets) - 测试非法字符和超长名称的错误处理
- [重复添加观察者](tests/test_exception.ets) - 测试同名观察者覆盖场景
- [订阅失败降级](tests/test_exception.ets) - 测试返回null时的降级处理