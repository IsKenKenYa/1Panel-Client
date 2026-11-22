---
name: hmos-performance-analysis-kit-hiappevent-watcher
description: 使用HiAppEvent订阅应用事件，支持订阅系统事件和应用自定义事件，通过观察者回调实时处理或批量获取事件数据，适用于应用崩溃监控、用户行为追踪、性能分析场景
---

# HiAppEvent 事件订阅技能

## 功能描述

本技能提供 HarmonyOS 应用事件订阅能力，通过 HiAppEvent API 实现对系统事件和应用自定义事件的订阅监听。支持三种订阅模式：

1. **OnReceive 模式**：事件发生后实时触发回调，适用于需要即时响应的场景
2. **OnTrigger 模式**：满足预设条件后触发回调，适用于批量处理或定时处理场景
3. **手动获取模式**：通过 holder 对象主动获取订阅事件，适用于自定义处理逻辑

核心功能包括：
- 订阅系统事件（崩溃、冻屏、资源泄漏等）
- 订阅应用自定义事件
- 事件打点写入
- 事件数据提取和处理
- 观察者生命周期管理

## 使用场景

### 触发词
- "订阅应用事件"
- "监听崩溃事件"
- "事件打点"
- "HiAppEvent"
- "事件观察者"
- "应用性能监控"
- "用户行为追踪"

### 能做
- 订阅系统预定义事件（崩溃、冻屏、资源泄漏等）
- 订阅应用自定义事件
- 配置事件过滤条件（领域、名称、类型）
- 设置回调触发条件（数量、大小、超时）
- 实现事件实时回调处理（OnReceive）
- 实现事件批量回调处理（OnTrigger）
- 手动获取订阅事件数据
- 应用事件打点写入
- 移除事件观察者

### 绝不做
- 不在回调函数中移除观察者（会导致订阅失效）
- 不订阅与系统事件名称冲突的自定义事件
- 不在性能敏感场景的主线程调用 addWatcher（建议在子线程调用）
- 不在回调函数中执行耗时操作（会影响事件处理性能）

### 补充
- addWatcher 涉及 I/O 操作，建议在子线程调用时确保线程不会被销毁
- write 接口执行时间通常在毫秒级别，可根据业务需求选择线程
- 系统崩溃/冻屏事件日志抓取可能需要 30s-2min，建议延时重试获取
- 观察者名称必须唯一，相同名称会覆盖前一次订阅
- 不同应用类型的系统事件订阅规格不同，详见约束文档

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间为数字/字母/下划线，结尾为数字/字母，长度不超过32字符
- 事件领域：支持数字/字母/下划线，以字母开头且不以下划线结尾，长度不超过32字符
- 事件名称：首字符为字母或$，中间为数字/字母/下划线，结尾为数字/字母，长度不超过48字符
- 事件参数：参数名不超过32字符，参数值长度不超过8KB，参数个数不超过32个
- 回调触发条件：row（数量）、size（字节）、timeOut（30秒为单位）均为正整数

### 执行约束
- addWatcher 调用：涉及 I/O 操作，建议根据性能需求选择线程
- write 调用：执行时间毫秒级别，可根据业务需求选择线程
- 系统事件获取：崩溃/冻屏事件建议延时30s-2min后重试
- 回调处理：避免在回调中执行耗时操作或移除观察者

### 内容约束
- 禁止订阅系统事件名称常量作为自定义事件名称
- 禁止在回调函数中调用 removeWatcher
- 禁止在回调中执行超过100ms的耗时操作
- 禁止使用高危函数（eval、exec等）处理事件数据

### 降级约束
- holder 为 null：记录错误日志并返回
- 订阅失败：检查参数规格并重试
- 事件获取失败：延时重试（针对系统崩溃/冻屏事件）
- 回调触发失败：检查 triggerCondition 设置

## 调用流程和步骤

### 步骤1：准备阶段

**导入模块**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

**参数校验**：
1. 验证观察者名称格式（首字母、中间字符、结尾字符、长度）
2. 验证事件领域格式（字母开头、不以下划线结尾、长度）
3. 验证事件名称格式（首字母/$、中间字符、结尾字符、长度）
4. 验证事件参数规格（参数名、参数值长度、参数个数）

### 步骤2：订阅崩溃事件（OnReceive 模式）

**实时订阅示例**：
```typescript
hiAppEvent.addWatcher({
  name: 'AppCrashWatcher',
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_CRASH]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', 'HiAppEvent success to read event with onReceive callback');
    hilog.info(0x0000, 'testTag', `domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'testTag', `time=${JSON.stringify(eventInfo.params['time'])}`);
        hilog.info(0x0000, 'testTag', `bundle_name=${JSON.stringify(eventInfo.params['bundle_name'])}`);
        hilog.info(0x0000, 'testTag', `external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
      }
    }
  }
});
```

### 步骤3：订阅按钮点击事件（OnTrigger 模式）

**批量订阅示例**：
```typescript
hiAppEvent.addWatcher({
  name: 'ButtonClickWatcher',
  appEventFilters: [{ domain: 'button' }],
  triggerCondition: { row: 1 },
  onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
    if (holder == null) {
      hilog.error(0x0000, 'testTag', 'HiAppEvent holder is null');
      return;
    }
    hilog.info(0x0000, 'testTag', 'HiAppEvent success to read event with onTrigger callback');
    hilog.info(0x0000, 'testTag', `onTrigger: curRow=${curRow}, curSize=${curSize}`);
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(0x0000, 'testTag', `eventPkg.packageId=${eventPkg.packageId}`);
      hilog.info(0x0000, 'testTag', `eventPkg.row=${eventPkg.row}`);
      hilog.info(0x0000, 'testTag', `eventPkg.size=${eventPkg.size}`);
      for (const eventInfo of eventPkg.data) {
        hilog.info(0x0000, 'testTag', `eventPkg.info=${eventInfo}`);
      }
    }
  }
});
```

### 步骤4：事件打点写入

**打点示例（Promise 模式）**：
```typescript
let eventParams: Record<string, number> = { 'clickTime': 100 };
let eventInfo: hiAppEvent.AppEventInfo = {
  domain: 'button',
  name: 'click',
  eventType: hiAppEvent.EventType.BEHAVIOR,
  params: eventParams,
};
hiAppEvent.write(eventInfo).then(() => {
  hilog.info(0x0000, 'testTag', `HiAppEvent write success`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', `HiAppEvent err.code: ${err.code}, err.message: ${err.message}`);
});
```

**打点示例（Callback 模式）**：
```typescript
hiAppEvent.write(eventInfo, (err: BusinessError) => {
  if (err) {
    hilog.error(0x0000, 'testTag', `code: ${err.code}, message: ${err.message}`);
    return;
  }
  hilog.info(0x0000, 'testTag', `success to write event`);
});
```

### 步骤5：错误处理

**错误码处理**：
```typescript
try {
  hiAppEvent.addWatcher({
    name: 'TestWatcher',
    appEventFilters: [{ domain: 'test' }]
  });
} catch (error) {
  const err: BusinessError = error as BusinessError;
  switch (err.code) {
    case 11102001:
      hilog.error(0x0000, 'testTag', 'Invalid watcher name');
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', 'Invalid filtering event domain');
      break;
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error');
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: ${err.message}`);
  }
}
```

### 步骤6：降级处理

**holder 为 null 处理**：
```typescript
onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
  if (holder == null) {
    hilog.error(0x0000, 'testTag', 'holder is null, subscription failed');
    return;
  }
  let eventPkg: hiAppEvent.AppEventPackage | null = null;
  while ((eventPkg = holder.takeNext()) != null) {
    hilog.info(0x0000, 'testTag', `Processing event package: ${eventPkg.packageId}`);
  }
}
```

**系统事件延时获取**：
```typescript
setTimeout(() => {
  let holder: hiAppEvent.AppEventPackageHolder = hiAppEvent.addWatcher({
    name: 'CrashWatcher',
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_CRASH]
      }
    ],
  });
  if (holder != null) {
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(0x0000, 'testTag', `eventPkg.data=${eventPkg.data}`);
    }
  }
}, 30000);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，可能原因：必填参数未指定、参数类型错误 | 检查参数是否完整且类型正确 |
| 11102001 | 观察者名称无效，可能原因：包含无效字符、长度无效 | 使用合规的观察者名称格式 |
| 11102002 | 事件领域无效，可能原因：包含无效字符、长度无效 | 使用合规的事件领域格式 |
| 11102003 | row 值无效，值为负数 | 使用正整数作为 row 值 |
| 11102004 | size 值无效，值为负数 | 使用正整数作为 size 值 |
| 11102005 | timeout 值无效，值为负数 | 使用正整数作为 timeout 值 |
| 11100001 | 打点功能禁用，disable 参数为 true | 在 configure 中设置 disable: false |
| 11101001 | 事件领域无效，可能原因：包含无效字符、长度无效 | 使用合规的事件领域格式 |
| 11101002 | 事件名称无效，可能原因：包含无效字符、长度无效 | 使用合规的事件名称格式 |
| 11101003 | 事件参数个数超过32个 | 减少参数数量至32个以内 |
| 11101004 | 事件参数字符串长度超过8KB | 缩短参数值长度 |
| 11101005 | 事件参数名无效，可能原因：包含无效字符、长度无效 | 使用合规的参数名格式 |
| 11101006 | 事件参数数组长度超过100 | 减少数组元素数量至100以内 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "系统依赖，无需额外安装",
    "@kit.BasicServicesKit": "系统依赖，无需额外安装"
  }
}
```

### 环境要求
- HarmonyOS API Version：>= 9
- DevEco Studio：>= 3.1
- ArkTS 语言支持

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保项目基于 HarmonyOS SDK 创建，使用 DevEco Studio 自动配置

**问题2：类型定义错误**
```
Error: Property 'addWatcher' does not exist on type 'hiAppEvent'
```
**解决方法**：检查导入语句是否正确，确保使用 `import { hiAppEvent } from '@kit.PerformanceAnalysisKit'`

**问题3：参数类型错误**
```
Error: Argument of type 'string' is not assignable to parameter of type 'Watcher'
```
**解决方法**：检查参数是否符合接口定义，使用 TypeScript 类型检查

## 常见问题与解决方法

### Q1：订阅崩溃事件后无法获取事件数据
**原因**：系统崩溃事件日志抓取耗时，典型30s，极端2min
**解决方法**：
- 使用延时重试策略，建议30s后开始获取
- 使用 onReceive 回调实时处理崩溃事件
- 确保观察者在应用重启后重新添加

### Q2：观察者名称相同导致订阅覆盖
**原因**：addWatcher 的 name 参数唯一，相同名称会覆盖
**解决方法**：
- 为不同订阅场景使用不同的观察者名称
- 避免在多处使用相同的观察者名称

### Q3：回调函数中移除观察者导致订阅失效
**原因**：在回调中移除观察者会影响订阅回调功能
**解决方法**：
- 不在回调函数中调用 removeWatcher
- 在独立的函数或线程中管理观察者生命周期

### Q4：性能敏感场景调用 addWatcher 影响性能
**原因**：addWatcher 涉及 I/O 操作，执行时间较长
**解决方法**：
- 在子线程中调用 addWatcher
- 确保子线程在整个使用周期内不被销毁
- 参考多线程并发文档实现子线程调用

### Q5：事件参数超过限制导致打点失败
**原因**：参数个数超过32个或参数值长度超过8KB
**解决方法**：
- 控制参数个数在32个以内
- 缩短参数值长度，特别是字符串类型
- 使用数据压缩或分批打点策略

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "AppCrashWatcher",
  "subscriptionMode": "onReceive",
  "eventsReceived": 5,
  "eventTypes": ["APP_CRASH", "click"],
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.write",
    "hiAppEvent.removeWatcher"
  ],
  "logsGenerated": [
    "/data/storage/el2/log/hiappevent/APP_CRASH_xxx.log"
  ]
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-app-events-arkts.md)
- [API参考说明](references/js-apis-hiviewdfx-hiappevent.md)
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
- [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)
- [Worker简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/worker-introduction)

## 完整示例代码

- [ArkTS 订阅示例](assets/hiappevent_watcher_example.ets)
- [ArkTS 打点示例](assets/hiappevent_write_example.ets)
- [完整应用示例](assets/hiappevent_complete_example.ets)

## 测试用例

### 正向测试用例
- [订阅系统崩溃事件](tests/test_positive_system_event.ets)：验证订阅系统事件的正确性
- [订阅应用自定义事件](tests/test_positive_custom_event.ets)：验证订阅自定义事件的正确性
- [事件打点写入](tests/test_positive_write_event.ets)：验证事件打点功能

### 边界测试用例
- [观察者名称边界](tests/test_boundary_watcher_name.ets)：测试名称长度和字符限制
- [事件参数边界](tests/test_boundary_event_params.ets)：测试参数个数和长度限制
- [回调触发条件边界](tests/test_boundary_trigger_condition.ets)：测试触发条件的临界值

### 异常测试用例
- [无效观察者名称](tests/test_exception_invalid_name.ets)：测试名称格式错误处理
- [无效事件领域](tests/test_exception_invalid_domain.ets)：测试领域格式错误处理
- [holder 为 null](tests/test_exception_holder_null.ets)：测试订阅失败降级处理
- [参数个数超限](tests/test_exception_params_overflow.ets)：测试参数超限错误处理