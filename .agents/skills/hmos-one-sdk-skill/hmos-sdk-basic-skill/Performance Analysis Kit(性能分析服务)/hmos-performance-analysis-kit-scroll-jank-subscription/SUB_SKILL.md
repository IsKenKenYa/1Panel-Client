---
name: hmos-performance-analysis-kit-scroll-jank-subscription
description: 订阅滑动丢帧事件用于性能监控+适用于HarmonyOS应用列表滑动性能分析+支持ArkTS语言+限制单次滑动卡顿超过50ms才触发+适用于列表滑动性能优化场景
---

# 订阅滑动丢帧事件技能

## 功能描述

本技能用于订阅HarmonyOS系统自动检测并上报的滑动丢帧事件(SCROLL_JANK)，实现对应用列表滑动性能问题的实时监控和分析。当用户滑动列表时，如果系统检测到超过50ms的卡顿场景，会自动触发滑动丢帧事件，并通过订阅回调函数将详细的性能数据传递给开发者，包括丢帧时长、丢帧位置、应用帧率和渲染帧率等关键指标。

**核心能力**：
- 实时监听系统自动检测的滑动丢帧事件
- 获取详细的丢帧性能数据（丢帧时长、丢帧次数、最大帧时间等）
- 支持自定义事件数据处理逻辑
- 提供完整的事件参数信息用于性能分析

**适用范围**：
- 列表滑动性能监控和优化
- UI卡顿问题定位和分析
- 应用性能瓶颈识别
- 用户体验优化场景

**技术特点**：
- 系统自动检测，无需主动触发
- 基于HiAppEvent事件订阅机制
- 支持ArkTS语言开发
- API version 12及以上支持

## 使用场景

### 触发词
- "订阅滑动丢帧事件"
- "监听列表滑动卡顿"
- "滑动性能监控"
- "列表丢帧检测"
- "滑动卡顿分析"

### 能做
- 订阅系统自动检测的滑动丢帧事件SCROLL_JANK
- 实时接收滑动丢帧事件通知
- 获取完整的丢帧性能数据（包括丢帧时长、丢帧次数、应用帧率、渲染帧率等）
- 对丢帧事件数据进行自定义处理（如日志记录、数据上报、性能分析等）
- 移除事件观察者以取消订阅

### 绝不做
- 不主动触发滑动丢帧事件（由系统自动检测触发）
- 不用于非滑动场景的性能监控（如网络请求、文件读写等）
- 不替代专业的性能分析工具（如SmartPerf等）
- 不处理应用崩溃、冻屏等其他系统事件（需使用对应的订阅技能）
- 不在回调函数中执行移除观察者操作（会导致订阅失效）

### 补充
- 滑动丢帧事件触发条件：单次滑动卡顿超过50ms，间隔5~35秒
- 事件参数包含详细的性能指标，可用于深入分析丢帧原因
- 需在EntryAbility中配置事件订阅，在应用启动时生效
- 可通过日志文件路径获取更详细的维测日志信息
- 系统检测有一定阈值，不会频繁上报事件

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过32个字符
- 事件领域：使用系统领域hiAppEvent.domain.OS
- 事件名称：使用系统事件名称常量hiAppEvent.event.SCROLL_JANK
- 回调函数：必须实现onReceive回调函数处理事件数据

### 执行约束
- 订阅操作应在应用启动时完成（建议在EntryAbility中配置）
- 回调函数执行时间应尽量短，避免阻塞主线程
- 不建议在回调函数中执行移除观察者操作
- 如需在子线程处理事件数据，需确保子线程不会被销毁
- 事件数据处理应及时，避免数据丢失

### 内容约束
- 禁止在回调函数中执行耗时操作（如网络请求、大量数据计算等）
- 禁止在回调函数中移除观察者（会导致订阅失效）
- 禁止使用高危函数处理事件数据（如直接执行外部命令等）
- 禁止忽略事件数据的类型校验
- 禁止在回调函数中进行复杂的UI操作

### 降级约束
- 订阅失败时返回null，需检查订阅是否成功
- 观察者名称冲突时后一次订阅会覆盖前一次
- 参数校验失败时系统会忽略订阅请求
- 事件数据获取失败时应提供友好的错误提示
- 回调函数异常时应记录错误日志并继续执行

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用运行环境支持API version 12及以上
2. 确认已导入必要的模块：@kit.PerformanceAnalysisKit
3. 确认观察者名称符合规范（字母开头，不含非法字符，长度不超过32字符）
4. 确认订阅的事件领域和事件名称正确

**参数准备**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

const watcherConfig = {
  name: "scrollJankWatcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.SCROLL_JANK]
    }
  ]
};
```

### 步骤2：添加事件观察者订阅

**示例代码**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

hiAppEvent.addWatcher({
  name: "scrollJankWatcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.SCROLL_JANK]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'ScrollJank', `onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'ScrollJank', `eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'ScrollJank', `eventInfo=${JSON.stringify(eventInfo)}`);
        processScrollJankEvent(eventInfo);
      }
    }
  }
});

function processScrollJankEvent(eventInfo: hiAppEvent.AppEventInfo): void {
  const params = eventInfo.params as Record<string, Object>;
  const duration = params.duration as number;
  const maxAppFrametime = params.max_app_frametime as number;
  const totalAppMissedFrames = params.total_app_missed_frames as number;
  
  hilog.info(0x0000, 'ScrollJank', `丢帧时长: ${duration}ms`);
  hilog.info(0x0000, 'ScrollJank', `最大应用帧时间: ${maxAppFrametime}ms`);
  hilog.info(0x0000, 'ScrollJank', `总丢帧次数: ${totalAppMissedFrames}`);
}
```

### 步骤3：配置测试场景

**示例代码**：
```typescript
@Entry
@Component
struct Index {
  private arr: number[] = Array.from({length: 24}, (_, i) => i);

  build() {
    List({ space: 10 }) {
      ForEach(this.arr, (item: number) => {
        ListItem() {
          Text(`${item}`)
            .width('100%')
            .height(100)
            .fontSize(20)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .backgroundColor(0x007DFF)
        }
      })
    }
    .onScrollIndex((firstIndex: number) => {
      let i = 1;
      while (i < 20000) {
        console.log("模拟耗时操作");
        i++;
      }
    })
  }
}
```

### 步骤4：错误处理

```typescript
import { BusinessError } from '@kit.BasicServicesKit';

try {
  const holder = hiAppEvent.addWatcher({
    name: "scrollJankWatcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.SCROLL_JANK]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      handleScrollJankEvent(domain, appEventGroups);
    }
  });
  
  if (holder === null) {
    hilog.error(0x0000, 'ScrollJank', '订阅失败，请检查参数是否正确');
  }
} catch (error) {
  const err = error as BusinessError;
  hilog.error(0x0000, 'ScrollJank', `订阅异常: code=${err.code}, message=${err.message}`);
  handleSubscriptionError(err.code);
}

function handleSubscriptionError(errorCode: number): void {
  switch (errorCode) {
    case 401:
      hilog.error(0x0000, 'ScrollJank', '参数错误，请检查观察者名称和事件过滤条件');
      break;
    case 11102001:
      hilog.error(0x0000, 'ScrollJank', '观察者名称不合法，请检查名称格式');
      break;
    case 11102002:
      hilog.error(0x0000, 'ScrollJank', '事件领域名称不合法');
      break;
    default:
      hilog.error(0x0000, 'ScrollJank', '未知错误，请参考错误码文档');
  }
}
```

### 步骤5：移除订阅（可选）

```typescript
const watcher: hiAppEvent.Watcher = {
  name: "scrollJankWatcher"
};

hiAppEvent.removeWatcher(watcher);
hilog.info(0x0000, 'ScrollJank', '已移除滑动丢帧事件订阅');
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必选参数未指定；2. 参数类型错误 | 检查所有必选参数是否正确传入，确保参数类型符合要求 |
| 11102001 | 观察者名称不合法。可能原因：1. 包含非法字符；2. 长度不合法 | 观察者名称首字符必须为字母，中间字符为数字/字母/下划线，结尾字符为数字/字母，长度不超过32字符 |
| 11102002 | 过滤事件领域不合法。可能原因：1. 包含非法字符；2. 长度不合法 | 使用系统领域hiAppEvent.domain.OS，确保领域名称格式正确 |
| 11102003 | 条数值不合法。值小于零 | 传入自然数的条数值（仅适用于triggerCondition配置） |
| 11102004 | 大小值不合法。值小于零 | 传入自然数的大小值（仅适用于triggerCondition配置） |
| 11102005 | 超时值不合法。值小于零 | 传入自然数的超时值（仅适用于triggerCondition配置） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "^12.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 12及以上
- DevEco Studio: 3.1及以上版本
- 运行环境: HarmonyOS设备或模拟器

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保HarmonyOS SDK版本为API 12及以上，并在oh-package.json5中正确配置依赖

**问题2：API不存在错误**
```
Error: Property 'SCROLL_JANK' does not exist on type 'event'
```
**解决方法**：SCROLL_JANK事件常量从API version 12开始支持，请确认SDK版本

**问题3：观察者名称校验失败**
```
Error: Invalid watcher name
```
**解决方法**：检查观察者名称格式，确保首字符为字母，不以下划线结尾，长度不超过32字符

**问题4：订阅回调未触发**
```
订阅成功但未收到事件通知
```
**解决方法**：确认滑动场景是否触发系统检测（需超过50ms卡顿），检查事件过滤条件是否正确

## 常见问题与解决方法

### Q1：为什么订阅成功但没有收到事件通知？
**原因**：
- 滑动场景未触发系统检测阈值（需超过50ms卡顿）
- 事件过滤条件配置错误
- 回调函数未正确实现

**解决方法**：
- 在列表滑动事件中添加耗时操作，模拟卡顿场景
- 检查appEventFilters配置，确保domain和names正确
- 确认onReceive回调函数已正确实现且能正常执行

### Q2：如何获取更详细的丢帧日志信息？
**原因**：事件参数中的external_log字段包含日志文件路径，可获取详细维测日志

**解决方法**：
- 从eventInfo.params中提取external_log字段
- 日志文件路径格式：/data/storage/el2/log/watchdog/SCROLL_JANK_*.txt
- 使用文件读取API获取详细日志内容
- 注意日志文件可能包含敏感信息，需妥善处理

### Q3：事件参数中包含哪些关键性能指标？
**原因**：需要了解事件参数的具体含义才能进行有效分析

**解决方法**：
关键参数说明：
- duration: 丢帧时长（ms）
- max_app_frametime: 最大应用帧时间
- max_app_seq_frames: 最大应用连续丢帧次数
- max_render_frametime: 最大渲染帧时间
- max_render_seq_frames: 最大渲染连续丢帧次数
- total_app_frames: 总应用帧数
- total_app_missed_frames: 总应用丢帧次数
- total_render_frames: 总渲染帧数
- total_render_missed_frames: 总渲染丢帧次数

### Q4：如何避免订阅回调函数阻塞主线程？
**原因**：回调函数在主线程执行，耗时操作会影响应用性能

**解决方法**：
- 回调函数中只做简单的数据记录和日志输出
- 将复杂的数据分析和上报操作移到子线程
- 使用Worker或TaskPool进行异步处理
- 参考Worker简介实现多线程处理

### Q5：能否同时订阅多个系统事件？
**原因**：需要监控多种性能问题，如崩溃、冻屏、丢帧等

**解决方法**：
- 可以在同一个观察者中订阅多个事件（在names数组中添加多个事件名称）
- 或创建多个观察者分别订阅不同事件
- 注意不同系统事件的触发条件和参数结构不同
- 需在回调函数中根据eventName区分处理逻辑

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "scrollJankWatcher",
  "subscriptionResult": "已成功订阅滑动丢帧事件SCROLL_JANK",
  "eventDomain": "OS",
  "eventName": "SCROLL_JANK",
  "triggerCondition": "单次滑动卡顿超过50ms，间隔5~35秒",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.event.SCROLL_JANK",
    "hiAppEvent.domain.OS"
  ],
  "nextSteps": [
    "运行应用并滑动列表触发丢帧",
    "查看日志输出获取丢帧事件数据",
    "分析丢帧指标定位性能瓶颈",
    "优化列表滑动逻辑减少卡顿"
  ]
}
```

## 参考文档

- [API开发指南-订阅滑动丢帧事件(ArkTS)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-scroll-jank-arkts)
- [API参考文档-应用事件打点](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [错误码文档-应用事件打点错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent)
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [HiAppEvent介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-intro)
- [Worker简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/worker-introduction)
- [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)

## 完整示例代码

- [ArkTS订阅滑动丢帧事件示例](assets/scroll_jank_subscription_example.ets)
- [列表滑动测试示例](assets/list_scroll_test.ets)
- [错误处理示例](assets/error_handling_example.ets)

## 测试用例

### 正向测试用例
- [正常订阅滑动丢帧事件](tests/test_positive_subscription.ets)：验证订阅成功并收到事件通知
- [处理丢帧事件数据](tests/test_positive_event_processing.ets)：验证事件数据解析和处理逻辑正确
- [移除订阅](tests/test_positive_remove_watcher.ets)：验证移除订阅后不再收到事件通知

### 边界测试用例
- [观察者名称长度边界](tests/test_boundary_watcher_name.ets)：测试32字符长度的观察者名称
- [最小卡顿触发](tests/test_boundary_min_duration.ets)：测试刚好50ms卡顿是否触发事件
- [大量事件并发](tests/test_boundary_concurrent_events.ets)：测试短时间内多次丢帧事件的处理

### 异常测试用例
- [非法观察者名称](tests/test_exception_invalid_name.ets)：测试包含非法字符的观察者名称
- [参数缺失](tests/test_exception_missing_params.ets)：测试缺少必选参数的情况
- [回调函数异常](tests/test_exception_callback_error.ets)：测试回调函数抛出异常的处理