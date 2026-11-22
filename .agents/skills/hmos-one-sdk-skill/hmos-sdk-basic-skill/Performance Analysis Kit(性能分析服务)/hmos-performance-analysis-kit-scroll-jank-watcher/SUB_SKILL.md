---
name: hmos-performance-analysis-kit-scroll-jank-watcher
description: 订阅滑动丢帧系统事件，实时监听并处理应用滑动丢帧信息，支持自定义回调处理，适用于性能调优和用户体验优化场景
---

# 订阅滑动丢帧事件技能

## 功能描述

本技能提供订阅和监听HarmonyOS系统滑动丢帧事件（SCROLL_JANK）的能力。通过hiAppEvent.addWatcher接口添加事件观察者，实时接收系统检测到的滑动丢帧事件，并通过onReceive回调函数对事件数据进行自定义处理。滑动丢帧事件由系统自动检测触发，开发者无需手动打点，只需订阅即可获取事件信息。

**核心功能**：
- 实时监听系统滑动丢帧事件
- 自动捕获应用滑动过程中的性能问题
- 提供详细的丢帧数据（丢帧数量、帧时间、渲染信息等）
- 支持自定义事件处理逻辑

**事件触发条件**：
- 用户滑动列表、网格等可滚动组件
- 滑动过程中发生超过50ms的卡顿
- 系统自动检测并生成事件，间隔5~35秒

**事件参数字段**：
- `bundle_name`：应用包名
- `bundle_version`：应用版本
- `ability_name`：Ability名称
- `begin_time`：事件开始时间
- `duration`：丢帧持续时间
- `total_app_frames`：应用层总帧数
- `total_app_missed_frames`：应用层丢帧数
- `total_render_frames`：渲染层总帧数
- `total_render_missed_frames`：渲染层丢帧数
- `max_app_frametime`：应用层最大帧时间
- `max_render_frametime`：渲染层最大帧时间
- `external_log`：维测日志文件路径

## 使用场景

### 触发词
- "订阅滑动丢帧事件"
- "监听滑动卡顿"
- "检测列表滑动性能"
- "捕获滑动丢帧"
- "滑动性能分析"
- "SCROLL_JANK事件订阅"

### 能做
- 订阅系统滑动丢帧事件（SCROLL_JANK）
- 实时接收滑动丢帧事件通知
- 获取详细的丢帧数据和维测日志
- 对丢帧事件进行自定义处理和分析
- 记录和上报丢帧信息到日志或服务器
- 移除已添加的事件观察者

### 绝不做
- 不订阅其他类型的系统事件（如崩溃、冻屏等）
- 不手动触发滑动丢帧事件打点
- 不处理非滑动丢帧的事件数据
- 不在回调函数中移除观察者（可能导致订阅失效）
- 不替换或修改系统事件参数字段

### 补充
- 滑动丢帧事件由系统自动检测，开发者无需手动打点
- 事件触发间隔为5~35秒，避免频繁上报影响性能
- 事件包含维测日志文件路径，可通过external_log字段获取
- 观察者名称（name）必须唯一，相同名称会覆盖之前的订阅
- API version 12开始支持，元服务API version 11开始支持
- 建议在Ability生命周期 onCreate 或 onForeground 中添加订阅

## 调用规范和规则

### 输入约束
- 观察者名称（name）：
  - 首字符必须为字母字符
  - 中间字符必须为数字字符、字母字符或下划线字符
  - 结尾字符必须为数字字符或字母字符
  - 长度非空且不超过32个字符
  - 示例：watcher1、scrollWatcher、performance_watcher
- 事件领域（domain）：必须使用系统领域 `hiAppEvent.domain.OS`
- 事件名称（names）：必须使用系统事件名称 `hiAppEvent.event.SCROLL_JANK`
- 回调函数：必须实现 `onReceive` 回调，可选实现 `onTrigger` 回调

### 执行约束
- addWatcher接口涉及I/O操作，执行时间在毫秒级别
- 最大回调处理时间：建议不超过100ms，避免影响UI线程
- 事件触发间隔：5~35秒（系统控制）
- 最大并发订阅：无明确限制，但建议不超过10个观察者
- 回调函数执行环境：主线程，需注意性能影响

### 内容约束
- 禁止在回调函数中调用 removeWatcher 移除观察者
- 禁止在回调函数中执行耗时操作（建议不超过100ms）
- 禁止修改系统事件参数字段（params对象）
- 禁止阻塞回调函数执行（避免死循环或同步锁）
- 禁止在回调中调用可能触发新丢帧的操作
- 禁止使用高危函数：eval、setTimeout(长时间)、同步XHR

### 降级约束
- 订阅失败：返回null，需检查参数格式和权限配置
- 回调未触发：检查事件是否满足触发条件（滑动+丢帧）
- 数据解析失败：使用try-catch包裹JSON.parse操作
- 维测日志文件不存在：external_log路径可能未生成，需验证文件存在性
- 观察者被覆盖：相同名称的新订阅会覆盖旧订阅，需确保名称唯一

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认应用已配置PerformanceAnalysisKit依赖
2. 确认Ability已创建并在合适生命周期阶段（onCreate/onForeground）
3. 确认观察者名称符合命名规范（字母开头，32字符以内）
4. 确认导入必要模块：`hiAppEvent` 和 `hilog`

**参数准备**：
```typescript
// 导入必要模块
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 定义观察者名称（唯一标识）
const watcherName: string = "scrollJankWatcher";

// 定义事件领域（系统领域）
const eventDomain: string = hiAppEvent.domain.OS;

// 定义事件名称（滑动丢帧事件）
const eventName: string = hiAppEvent.event.SCROLL_JANK;
```

### 步骤2：调用addWatcher订阅事件

**示例代码**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 添加滑动丢帧事件观察者
hiAppEvent.addWatcher({
  // 观察者名称，用于唯一标识不同的观察者
  name: "scrollJankWatcher",
  
  // 订阅过滤条件：订阅滑动丢帧系统事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,  // 系统事件领域
      names: [hiAppEvent.event.SCROLL_JANK]  // 滑动丢帧事件名称
    }
  ],
  
  // 实现onReceive回调，监听到事件后实时回调
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'ScrollJank', `Received event: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      // 根据事件名称区分不同的系统事件
      hilog.info(0x0000, 'ScrollJank', `Event name=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 处理事件数据：打印日志、上报服务器、存储数据库等
        hilog.info(0x0000, 'ScrollJank', `Event info=${JSON.stringify(eventInfo)}`);
        
        // 解析事件参数
        const params = eventInfo.params as Record<string, any>;
        const bundleName = params['bundle_name'] as string;
        const duration = params['duration'] as number;
        const totalMissedFrames = params['total_app_missed_frames'] as number;
        
        hilog.warn(0x0000, 'ScrollJank', 
          `App ${bundleName} experienced scroll jank: duration=${duration}ms, missed_frames=${totalMissedFrames}`);
      }
    }
  }
});

hilog.info(0x0000, 'ScrollJank', 'Watcher added successfully');
```

### 步骤3：错误处理

```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 带错误处理的订阅示例
function addScrollJankWatcher(): boolean {
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
        try {
          for (const eventGroup of appEventGroups) {
            for (const eventInfo of eventGroup.appEventInfos) {
              // 使用try-catch包裹JSON序列化
              const eventJson = JSON.stringify(eventInfo);
              hilog.info(0x0000, 'ScrollJank', `Event: ${eventJson}`);
            }
          }
        } catch (parseError) {
          hilog.error(0x0000, 'ScrollJank', 
            `Failed to parse event data: ${parseError.message}`);
        }
      }
    });
    
    // 检查订阅是否成功（失败时返回null）
    if (holder === null) {
      hilog.error(0x0000, 'ScrollJank', 'Failed to add watcher: holder is null');
      return false;
    }
    
    hilog.info(0x0000, 'ScrollJank', 'Watcher added successfully');
    return true;
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ScrollJank', 
      `Failed to add watcher: code=${err.code}, message=${err.message}`);
    
    // 根据错误码处理
    switch (err.code) {
      case 401:
        hilog.error(0x0000, 'ScrollJank', 'Parameter error: check watcher name format');
        break;
      case 11102001:
        hilog.error(0x0000, 'ScrollJank', 'Invalid watcher name: check naming rules');
        break;
      case 11102002:
        hilog.error(0x0000, 'ScrollJank', 'Invalid event domain: use hiAppEvent.domain.OS');
        break;
      default:
        hilog.error(0x0000, 'ScrollJank', 'Unknown error occurred');
    }
    return false;
  }
}
```

### 步骤4：移除观察者（取消订阅）

```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 定义观察者对象
let scrollJankWatcher: hiAppEvent.Watcher = {
  name: "scrollJankWatcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.SCROLL_JANK]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    // 处理事件数据
  }
};

// 添加观察者
hiAppEvent.addWatcher(scrollJankWatcher);

// 在Ability销毁时移除观察者（建议在onDestroy或onBackground中调用）
function removeScrollJankWatcher(): void {
  try {
    hiAppEvent.removeWatcher(scrollJankWatcher);
    hilog.info(0x0000, 'ScrollJank', 'Watcher removed successfully');
  } catch (error) {
    const err = error as BusinessError;
    hilog.error(0x0000, 'ScrollJank', 
      `Failed to remove watcher: code=${err.code}, message=${err.message}`);
  }
}
```

### 步骤5：完整应用示例（包含订阅和触发场景）

**EntryAbility.ets**（订阅事件）：
```typescript
import { UIAbility } from '@kit.AbilityKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { window } from '@kit.ArkUI';

export default class EntryAbility extends UIAbility {
  private scrollJankWatcher: hiAppEvent.Watcher = {
    name: "scrollJankWatcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.SCROLL_JANK]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      hilog.info(0x0000, 'ScrollJank', `Received domain=${domain}`);
      for (const eventGroup of appEventGroups) {
        hilog.info(0x0000, 'ScrollJank', `Event name=${eventGroup.name}`);
        for (const eventInfo of eventGroup.appEventInfos) {
          const params = eventInfo.params as Record<string, any>;
          hilog.warn(0x0000, 'ScrollJank', 
            `Scroll jank detected: bundle=${params['bundle_name']}, duration=${params['duration']}ms`);
        }
      }
    }
  };

  onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability created');
    
    // 在Ability创建时添加订阅
    const holder = hiAppEvent.addWatcher(this.scrollJankWatcher);
    if (holder !== null) {
      hilog.info(0x0000, 'ScrollJank', 'Watcher added on create');
    } else {
      hilog.error(0x0000, 'ScrollJank', 'Failed to add watcher');
    }
  }

  onDestroy(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability destroyed');
    
    // 在Ability销毁时移除订阅
    hiAppEvent.removeWatcher(this.scrollJankWatcher);
    hilog.info(0x0000, 'ScrollJank', 'Watcher removed on destroy');
  }

  onForeground(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability foreground');
  }

  onBackground(): void {
    hilog.info(0x0000, 'EntryAbility', 'Ability background');
  }
}
```

**Index.ets**（触发丢帧的列表页面）：
```typescript
@Entry
@Component
struct Index {
  private arr: number[] = Array.from({length: 24}, (_, i) => i);

  build() {
    Column() {
      Text('Scroll Jank Demo')
        .fontSize(20)
        .fontWeight(FontWeight.Bold)
        .margin({top: 20, bottom: 20})
      
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
        }, (item: number) => item.toString())
      }
      .width('100%')
      .height('80%')
      .onScrollIndex((firstIndex: number) => {
        // 模拟耗时操作：在滑动事件中添加卡顿逻辑
        let i = 1;
        while (i < 20000) {
          console.log("Simulating heavy work in scroll");
          i++;
        }
      })
    }
    .width('100%')
    .height('100%')
  }
}
```

**预期输出日志**：
```
ScrollJank: Received domain=OS
ScrollJank: Event name=SCROLL_JANK
ScrollJank: Scroll jank detected: bundle=com.example.app, duration=801ms
ScrollJank: Event info={"domain":"OS","name":"SCROLL_JANK","eventType":1,"params":{"bundle_name":"com.example.app","duration":801,"total_app_frames":98,"total_app_missed_frames":0,...}}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定或参数类型错误 | 检查观察者名称、事件领域、事件名称参数格式 |
| 11102001 | 观察者名称无效：包含非法字符或长度无效 | 确保名称：字母开头，仅包含字母/数字/下划线，32字符以内 |
| 11102002 | 事件领域过滤无效：包含非法字符或长度无效 | 使用系统领域 `hiAppEvent.domain.OS` |
| 11102003 | row值无效：row值小于零 | 检查triggerCondition.row参数（仅在使用onTrigger时） |
| 11102004 | size值无效：size值小于零 | 检查triggerCondition.size参数（仅在使用onTrigger时） |
| 11102005 | timeout值无效：timeout值小于零 | 检查triggerCondition.timeOut参数（仅在使用onTrigger时） |

**常见错误场景**：
- **订阅失败（holder为null）**：参数格式错误或权限不足，检查错误码并修正参数
- **回调未触发**：未发生滑动丢帧场景，需在实际滑动中触发事件
- **JSON解析失败**：eventInfo数据格式异常，使用try-catch包裹解析逻辑
- **观察者被覆盖**：相同名称的新订阅覆盖旧订阅，确保name唯一性

## 编译和修复问题

### 依赖声明
在 `oh-package.json5` 中添加依赖：
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "^12.0.0"
  }
}
```

### 环境要求
- HarmonyOS SDK：API version 12 或更高版本
- DevEco Studio：3.1 或更高版本
- 设备类型：支持系统事件订阅的HarmonyOS设备
- 元服务：API version 11 开始支持

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：
1. 检查 `oh-package.json5` 中是否配置了PerformanceAnalysisKit依赖
2. 执行 `ohpm install` 安装依赖
3. 检查SDK版本是否为API version 12+

**问题2：hiAppEvent.event.SCROLL_JANK未定义**
```
Error: Property 'SCROLL_JANK' does not exist on type 'event'
```
**解决方法**：
1. 确认SDK版本为API version 12+（SCROLL_JANK从API 12开始支持）
2. 检查导入语句：`import { hiAppEvent } from '@kit.PerformanceAnalysisKit'`
3. 使用正确的常量名：`hiAppEvent.event.SCROLL_JANK`

**问题3：观察者名称格式错误**
```
Error: Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid.
```
**解决方法**：
1. 确保名称首字符为字母（不能以数字或下划线开头）
2. 仅使用字母、数字、下划线字符
3. 长度不超过32个字符
4. 示例：`scrollJankWatcher`（正确），`1watcher`（错误），`scroll_jank_watcher_very_long_name_exceed_limit`（错误）

**问题4：回调函数参数类型错误**
```
Error: Parameter error. Incorrect parameter types.
```
**解决方法**：
1. 确保onReceive回调参数类型正确：
   - `domain: string`
   - `appEventGroups: Array<hiAppEvent.AppEventGroup>`
2. 检查eventInfo类型：`hiAppEvent.AppEventInfo`
3. 使用类型断言解析params：`eventInfo.params as Record<string, any>`

**问题5：运行时崩溃**
```
App crash when scrolling the list
```
**解决方法**：
1. 检查回调函数中的逻辑，避免耗时操作（建议不超过100ms）
2. 避免在回调中调用removeWatcher
3. 使用try-catch包裹回调内的所有逻辑
4. 验证JSON.stringify不会抛出异常（检查数据格式）

## 常见问题与解决方法

### Q1：订阅成功但回调从未触发
**原因**：未发生滑动丢帧场景，系统未检测到超过50ms的卡顿
**解决方法**：
- 确保应用包含可滚动组件（List、Grid、Scroll等）
- 在滑动事件中添加耗时操作模拟丢帧（如循环、复杂计算）
- 实际滑动操作触发系统检测（需持续滑动2秒以上）
- 系统事件间隔5~35秒，可能需要等待一段时间

### Q2：收到事件数据但无法解析params字段
**原因**：params对象包含多种类型字段，直接解析可能失败
**解决方法**：
```typescript
// 使用类型断言和try-catch
const params = eventInfo.params as Record<string, any>;
try {
  const bundleName = params['bundle_name'] as string;
  const duration = params['duration'] as number;
  const missedFrames = params['total_app_missed_frames'] as number;
} catch (error) {
  hilog.error(0x0000, 'ScrollJank', 'Failed to parse params');
}
```

### Q3：如何获取维测日志文件
**原因**：external_log字段包含日志路径，但文件可能未生成或权限不足
**解决方法**：
1. 检查params中的external_log字段（数组类型）
2. 验证文件路径：`/data/storage/el2/log/watchdog/SCROLL_JANK_xxxx.txt`
3. 使用文件API读取日志内容（需权限配置）
4. 注意：日志文件生成有延迟，建议30秒后再读取

### Q4：观察者名称冲突导致订阅被覆盖
**原因**：相同名称的新订阅会覆盖旧订阅，导致回调逻辑丢失
**解决方法**：
- 确保每个观察者使用唯一名称
- 建议命名规则：功能+场景+序号（如 `scrollJankWatcher1`）
- 移除旧订阅后再添加新订阅（调用removeWatcher）

### Q5：在回调中调用removeWatcher导致订阅失效
**原因**：移除观察者后，回调功能立即失效，后续事件无法接收
**解决方法**：
- 避免在onReceive回调中调用removeWatcher
- 在Ability生命周期函数（onDestroy/onBackground）中移除订阅
- 使用标志位控制移除时机，而非在回调内直接调用

### Q6：多次订阅同一事件是否会影响性能
**原因**：多个观察者订阅同一事件会增加系统负担
**解决方法**：
- 建议最多1-2个观察者订阅同一事件
- 使用单一观察者处理事件，避免重复订阅
- 及时移除不再使用的观察者
- 在回调中避免耗时操作，减少性能影响

## 输出结果报告

执行订阅滑动丢帧事件后，将输出以下信息：

```json
{
  "status": "success",
  "watcher_name": "scrollJankWatcher",
  "event_domain": "OS",
  "event_name": "SCROLL_JANK",
  "subscription_time": "2026-07-03T21:30:00Z",
  "callback_triggered": true,
  "event_count": 3,
  "api_used": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.event.SCROLL_JANK",
    "hiAppEvent.domain.OS"
  ],
  "event_data": {
    "bundle_name": "com.example.myapplication",
    "bundle_version": "1.0.0",
    "ability_name": "EntryAbility",
    "duration": 801,
    "total_app_frames": 98,
    "total_app_missed_frames": 0,
    "total_render_frames": 80,
    "total_render_missed_frames": 0,
    "max_app_frametime": 3,
    "max_render_frametime": 8,
    "external_log": [
      "/data/storage/el2/log/watchdog/SCROLL_JANK_20260703213000_6033.txt"
    ]
  }
}
```

**状态说明**：
- `success`：订阅成功，回调正常触发
- `failed`：订阅失败，检查参数和错误码
- `pending`：订阅成功但事件未触发，等待滑动操作

**关键指标**：
- `duration`：丢帧持续时间（ms），大于50ms表示严重丢帧
- `total_app_missed_frames`：应用层丢帧数量
- `total_render_missed_frames`：渲染层丢帧数量
- `external_log`：维测日志路径，用于深入分析

## 参考文档

- [订阅滑动丢帧事件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-scroll-jank-arkts)
- [应用事件打点API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS示例代码](assets/example_scroll_jank_watcher.ets)：包含订阅、回调处理、移除订阅的完整示例
- [测试应用示例](assets/test_scroll_jank_app.ets)：包含触发丢帧的列表页面示例

## 测试用例

### 正向测试用例
- [基本订阅测试](tests/test_positive.ets)：验证订阅成功并接收事件
- [数据解析测试](tests/test_positive.ets)：验证事件数据正确解析
- [多场景测试](tests/test_positive.ets)：验证不同滑动场景的事件触发

### 边界测试用例
- [观察者名称长度测试](tests/test_boundary.ets)：验证32字符名称边界
- [事件数据字段边界测试](tests/test_boundary.ets)：验证params字段长度和类型边界
- [并发订阅测试](tests/test_boundary.ets)：验证多个观察者并发订阅

### 异常测试用例
- [参数格式错误测试](tests/test_exception.ets)：验证错误码401处理
- [观察者名称非法测试](tests/test_exception.ets)：验证错误码11102001处理
- [回调解析异常测试](tests/test_exception.ets)：验证JSON解析失败处理
- [订阅失败测试](tests/test_exception.ets)：验证holder为null的降级处理