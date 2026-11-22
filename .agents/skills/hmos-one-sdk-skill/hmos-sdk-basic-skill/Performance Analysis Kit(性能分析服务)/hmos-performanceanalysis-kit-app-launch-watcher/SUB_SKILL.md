---
name: hmos-performanceanalysis-kit-app-launch-watcher
description: 订阅应用启动耗时系统事件，支持实时监听APP_LAUNCH事件并获取启动性能数据，适用于应用性能监控、启动优化分析场景
---

# 订阅启动耗时事件技能

## 功能描述

本技能实现HarmonyOS应用启动耗时事件的订阅功能，通过HiAppEvent模块添加事件观察者，实时监听系统生成的APP_LAUNCH事件。该事件包含应用启动过程的详细性能数据，如启动类型、启动耗时、动画完成时间等关键指标，帮助开发者分析应用启动性能，优化用户体验。

**核心能力**：
- 添加事件观察者订阅启动耗时事件
- 实时接收启动耗时事件回调
- 解析启动耗时事件数据字段
- 移除事件观察者取消订阅

**适用范围**：
- 监控应用冷启动/热启动性能
- 分析启动耗时瓶颈
- 收集启动性能数据用于优化

**限制条件**：
- 仅支持ArkTS语言
- 需API version 9及以上
- onReceive回调中不建议执行关键业务逻辑

## 使用场景

### 触发词
- "订阅启动耗时事件"
- "监控应用启动性能"
- "APP_LAUNCH事件订阅"
- "应用启动时间分析"
- "启动性能监控"

### 能做
- 添加观察者订阅启动耗时系统事件
- 实时接收并处理启动耗时事件数据
- 解析事件数据中的启动性能指标
- 移除观察者取消事件订阅
- 在日志中记录启动耗时事件信息

### 绝不做
- 不在onReceive回调中执行关键业务逻辑（如移除观察者、资源释放）
- 不在onReceive回调中进行可能导致崩溃的复杂操作
- 不修改系统事件的数据字段结构
- 不依赖回调函数的单次触发（可能在一次启动中被多次调用）

### 补充
- 应用退出或崩溃时，onReceive回调可能不被触发，导致事件回调失败
- 应用重启时，未完成回调的事件会在新启动中重新传递，可能导致onReceive被多次调用
- 建议onReceive仅用于事件接收和简单记录，避免复杂业务逻辑
- APP_LAUNCH事件在应用启动完成时由系统自动生成

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过32个字符
- 事件领域：使用hiAppEvent.domain.OS（系统事件领域）
- 事件名称：使用hiAppEvent.event.APP_LAUNCH（启动耗时事件常量）
- 参数类型：Watcher对象必须包含name字段，可选包含appEventFilters和onReceive字段

### 执行约束
- addWatcher接口涉及I/O操作，执行时间通常在毫秒级别
- 不建议在性能敏感场景的主线程中调用（可选择子线程）
- 若在子线程调用，需确保子线程在整个接口使用周期内不被销毁
- 相同name的观察者，后一次调用会覆盖前一次的订阅
- onReceive回调可能在一次应用启动中被多次调用

### 内容约束
- 禁止在onReceive回调中执行移除观察者操作（removeWatcher）
- 禁止在onReceive回调中执行资源释放等关键业务逻辑
- 禁止在onReceive回调中执行可能导致崩溃的复杂操作
- 禁止修改或伪造系统事件数据
- 禁止在回调中进行网络请求或文件写入等耗时操作

### 降级约束
- 观察者名称格式错误：抛出11102001错误码，需检查名称格式规范
- 事件领域格式错误：抛出11102002错误码，需使用正确的系统事件领域常量
- 回调未被触发：应用退出或崩溃导致回调失败，重启后会重新传递事件
- 多次回调触发：应用重启后未完成回调的事件会重新传递，需处理重复事件

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本：确保设备支持API version 9及以上
2. 检查模块导入：确保已导入@kit.PerformanceAnalysisKit中的hiAppEvent和hilog模块
3. 检查应用配置：确保应用已正确配置，能够正常运行和启动
4. 检查观察者名称：确保名称符合格式规范（字母开头，字母/数字/下划线组成，不超过32字符）

**参数准备**：
```typescript
// 导入必要模块
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 定义观察者名称（需符合命名规范）
const watcherName: string = "watcher"; // 示例名称，开发者可自定义

// 定义事件过滤条件
const appEventFilters: Array<hiAppEvent.AppEventFilter> = [
  {
    domain: hiAppEvent.domain.OS,  // 系统事件领域
    names: [hiAppEvent.event.APP_LAUNCH]  // 启动耗时事件名称
  }
];
```

### 步骤2：添加观察者订阅事件

**示例代码**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 添加启动耗时事件观察者
hiAppEvent.addWatcher({
  // 开发者可以自定义观察者名称，系统会使用名称来标识不同的观察者
  name: "watcher",
  
  // 开发者可以订阅感兴趣的系统事件，此处是订阅了启动耗时事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ],
  
  // 开发者可以自行实现订阅回调函数，以便对订阅获取到的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    // 记录回调触发的事件领域
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    
    // 遍历事件组
    for (const eventGroup of appEventGroups) {
      // 开发者可以根据事件集合中的事件名称区分不同的系统事件
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      
      // 遍历事件信息
      for (const eventInfo of eventGroup.appEventInfos) {
        // 开发者可以对事件集合中的事件数据进行自定义处理，此处是将事件数据打印在日志中
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo=${JSON.stringify(eventInfo)}`);
        
        // 解析启动耗时事件的具体参数字段
        if (eventInfo.params) {
          const params = eventInfo.params;
          hilog.info(0x0000, 'testTag', `启动类型: ${params.start_type}`);
          hilog.info(0x0000, 'testTag', `启动耗时: ${params.time}ms`);
          hilog.info(0x0000, 'testTag', `动画完成时间: ${params.animation_finish_time}ms`);
          hilog.info(0x0000, 'testTag', `应用包名: ${params.bundle_name}`);
          hilog.info(0x0000, 'testTag', `应用版本: ${params.bundle_version}`);
        }
      }
    }
  }
});
```

### 步骤3：触发事件

**触发方式**：
1. 运行应用工程：点击DevEco Studio运行按钮启动应用
2. 退出应用：完成首次启动后退出应用
3. 再次启动：点击桌面应用图标，触发启动耗时事件
4. 查看日志：在Log窗口查看onReceive回调输出的事件数据

**事件触发时机**：
- APP_LAUNCH事件在应用启动完成时由系统自动生成
- 不需要开发者手动调用打点接口

### 步骤4：移除观察者（可选）

**示例代码**：
```typescript
import { hiAppEvent } from '@kit.PerformanceAnalysisKit';

// 定义观察者对象
let watcher: hiAppEvent.Watcher = {
  name: "watcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ]
};

// 添加观察者订阅事件
hiAppEvent.addWatcher(watcher);

// 在合适的时机移除观察者（注意：不要在onReceive回调中执行）
// 建议：在应用退出前或其他非回调场景中移除
hiAppEvent.removeWatcher(watcher);
```

### 步骤5：错误处理

**错误处理代码**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

try {
  // 尝试添加观察者
  hiAppEvent.addWatcher({
    name: "watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_LAUNCH]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 简单的回调处理逻辑
      hilog.info(0x0000, 'testTag', `onReceive triggered, domain=${domain}`);
    }
  });
  
  hilog.info(0x0000, 'testTag', '观察者添加成功');
} catch (error) {
  // 捕获并处理错误
  hilog.error(0x0000, 'testTag', `观察者添加失败: code=${error.code}, message=${error.message}`);
  
  // 根据错误码进行针对性处理
  switch (error.code) {
    case 401:
      hilog.error(0x0000, 'testTag', '参数错误：请检查必填参数是否缺失或参数类型是否正确');
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', '观察者名称无效：请检查名称格式和长度');
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', '事件领域无效：请使用正确的系统事件领域常量');
      break;
    default:
      hilog.error(0x0000, 'testTag', `未知错误: ${error.message}`);
  }
}
```

### 步骤6：降级处理

**降级处理方案**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 降级方案1：使用triggerCondition和onTrigger回调代替onReceive实时回调
// 适用于不需要实时处理的场景，可以批量处理事件
hiAppEvent.addWatcher({
  name: "watcher_backup",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ],
  triggerCondition: {
    row: 10,  // 事件数量达到10个触发回调
    size: 1000,  // 事件大小达到1000byte触发回调
    timeOut: 1  // 超时30s触发回调（timeOut单位为30s）
  },
  onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
    if (holder == null) {
      hilog.error(0x0000, 'testTag', "holder is null");
      return;
    }
    
    hilog.info(0x0000, 'testTag', `onTrigger triggered: curRow=${curRow}, curSize=${curSize}`);
    
    // 通过holder主动获取事件
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder.takeNext()) != null) {
      for (const eventInfo of eventPkg.appEventInfos) {
        hilog.info(0x0000, 'testTag', `eventInfo=${JSON.stringify(eventInfo)}`);
      }
    }
  }
});

// 降级方案2：手动获取事件（不使用回调）
let holder: hiAppEvent.AppEventPackageHolder | null = hiAppEvent.addWatcher({
  name: "watcher_manual",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_LAUNCH]
    }
  ]
});

// 在合适的时机手动获取事件
if (holder != null) {
  let eventPkg: hiAppEvent.AppEventPackage | null = null;
  while ((eventPkg = holder.takeNext()) != null) {
    for (const eventInfo of eventPkg.appEventInfos) {
      hilog.info(0x0000, 'testTag', `eventInfo=${JSON.stringify(eventInfo)}`);
    }
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型不正确。 | 检查Watcher对象是否包含必填字段name，检查参数类型是否正确。 |
| 11102001 | 观察者名称无效。可能原因：1. 包含无效字符；2. 长度无效。 | 检查观察者名称：首字符必须为字母，中间字符为数字/字母/下划线，结尾字符为数字/字母，长度不超过32字符。 |
| 11102002 | 事件过滤领域无效。可能原因：1. 包含无效字符；2. 长度无效。 | 使用正确的系统事件领域常量：hiAppEvent.domain.OS。 |
| 11102003 | row值无效。row值小于零。 | 检查triggerCondition中的row值是否为非负数。 |
| 11102004 | size值无效。size值小于零。 | 检查triggerCondition中的size值是否为非负数。 |
| 11102005 | timeout值无效。timeout值小于零。 | 检查triggerCondition中的timeOut值是否为非负数。 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "系统Kit，无需显式声明版本"
  }
}
```

### 环境要求
- HarmonyOS API：最低版本API version 9
- 开发环境：DevEco Studio 3.1及以上
- 运行环境：HarmonyOS设备或模拟器

### 常见编译问题

**问题1：模块导入失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit' or its corresponding type declarations.
```
**解决方法**：检查DevEco Studio版本和HarmonyOS SDK版本，确保支持API version 9及以上。确保项目配置正确。

**问题2：类型定义错误**
```
Error: Property 'APP_LAUNCH' does not exist on type 'event'.
```
**解决方法**：检查hiAppEvent.event常量的使用方式，确保使用正确的API版本。APP_LAUNCH事件从API version 9开始支持。

**问题3：观察者名称格式错误**
```
Error: Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid.
```
**解决方法**：检查观察者名称是否符合规范：首字符为字母，中间字符为数字/字母/下划线，结尾字符为数字/字母，长度不超过32字符。

## 常见问题与解决方法

### Q1：onReceive回调未被触发
**原因**：应用在启动过程中退出或崩溃，导致回调未被执行。
**解决方法**：
- 检查应用启动流程是否完整
- 确保应用没有在启动过程中异常退出
- 注意：应用重启后，未完成回调的事件会重新传递

### Q2：onReceive回调被多次调用
**原因**：应用退出或崩溃后重启，之前未完成回调的事件会在新启动中重新传递。
**解决方法**：
- 不要依赖回调的单次触发特性
- 在回调中实现幂等处理逻辑
- 建议仅用于事件接收和简单记录

### Q3：在onReceive中执行复杂操作导致应用崩溃
**原因**：在回调中执行了移除观察者、资源释放等关键业务逻辑，或进行了耗时操作。
**解决方法**：
- 不在onReceive中执行关键业务逻辑
- 不在回调中进行耗时操作（网络请求、文件写入等）
- 仅在回调中进行事件接收和简单记录
- 将复杂处理逻辑移到其他非回调场景中执行

### Q4：启动耗时事件数据字段含义不清楚
**原因**：未了解APP_LAUNCH事件的params字段定义。
**解决方法**：
- 参考API文档了解事件字段含义
- params包含：start_type（启动类型）、time（启动耗时）、animation_finish_time（动画完成时间）、bundle_name（应用包名）、bundle_version（应用版本）等字段

### Q5：无法获取到启动耗时事件
**原因**：事件订阅时机不对或观察者名称配置错误。
**解决方法**：
- 确保在应用启动前已添加观察者（如在EntryAbility.ets的onCreate中添加）
- 检查观察者名称是否唯一且符合规范
- 确认事件过滤条件配置正确（domain和names）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "watcher",
  "eventType": "APP_LAUNCH",
  "eventDomain": "OS",
  "eventData": {
    "domain": "OS",
    "name": "APP_LAUNCH",
    "eventType": 4,
    "params": {
      "animation_finish_time": 662,
      "bundle_name": "com.example.myapplication",
      "bundle_version": "1.0.0",
      "extend_time": 0,
      "icon_input_time": 1709367533224,
      "process_name": "com.example.myapplication",
      "start_type": 0,
      "time": 1709367533901
    }
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.domain.OS",
    "hiAppEvent.event.APP_LAUNCH"
  ]
}
```

## 参考文档

- [订阅启动耗时事件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-app-launch-arkts)
- [应用事件打点API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS完整示例](assets/example_app_launch_watcher.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常订阅启动耗时事件](tests/test_positive.ets)：验证观察者添加成功并接收事件回调
- [解析事件数据字段](tests/test_positive.ets)：验证正确解析启动耗时事件的所有字段

### 边界测试用例
- [观察者名称边界测试](tests/test_boundary.ets)：测试名称长度32字符边界
- [多次启动事件测试](tests/test_boundary.ets)：测试应用重启后多次回调触发场景

### 异常测试用例
- [无效观察者名称](tests/test_exception.ets)：测试名称格式错误场景
- [回调中移除观察者](tests/test_exception.ets)：测试在回调中执行关键操作的异常场景