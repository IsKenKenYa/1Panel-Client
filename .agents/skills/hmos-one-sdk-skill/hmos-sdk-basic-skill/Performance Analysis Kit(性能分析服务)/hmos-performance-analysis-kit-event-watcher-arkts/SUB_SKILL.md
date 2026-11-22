---
name: hmos-performance-analysis-kit-event-watcher-arkts
description: 订阅应用崩溃事件和自定义事件，支持OnReceive和OnTrigger两种回调模式，最大支持订阅32个参数的事件，适用于应用性能监控和故障排查场景
---

# 事件订阅（ArkTS）技能

## 功能描述

本技能实现HarmonyOS应用的事件订阅功能，通过HiAppEvent API监听应用运行过程中的关键事件。支持订阅系统事件（崩溃、冻屏、资源泄漏等）和应用自定义事件，提供实时回调（OnReceive）和条件触发回调（OnTrigger）两种处理模式，帮助开发者快速定位和诊断应用问题。

**核心能力**：
- 订阅系统预定义事件：崩溃、冻屏、资源泄漏、主线程超时等
- 订阅应用自定义事件：用户行为、业务流程等
- 实时事件回调：事件发生后立即触发OnReceive回调
- 条件触发回调：累积满足条件后触发OnTrigger回调
- 事件打点写入：自定义事件参数并持久化存储

## 使用场景

### 触发词
- "订阅崩溃事件"
- "监听应用事件"
- "事件打点"
- "HiAppEvent订阅"
- "应用性能监控"
- "故障日志收集"

### 能做
- 订阅系统崩溃事件，获取崩溃时间戳、包名、故障日志文件路径
- 订阅应用自定义事件，记录用户点击、业务流程等行为数据
- 实时监听事件发生，立即触发回调处理
- 条件累积触发回调，批量处理事件数据
- 自定义事件参数，最多32个参数字段
- 移除订阅观察者，取消事件监听

### 绝不做
- 不订阅未定义的系统事件名称
- 不超过32个事件参数限制
- 不在回调函数中移除观察者（会导致订阅失效）
- 不写入超过1024字符的字符串参数值
- 不超过100个数组元素的限制
- 不订阅与系统事件名称冲突的应用事件

### 补充
- addWatcher涉及I/O操作，性能敏感场景建议子线程调用
- write接口执行时间毫秒级，根据业务需求选择线程
- 系统崩溃事件捕获耗时30s-2min，建议延时重试获取
- 相同watcher name会覆盖前一次订阅
- OnReceive和OnTrigger同时存在时，优先触发OnReceive

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须字母，中间字符数字/字母/下划线，结尾字符数字/字母，长度不超过32字符
- 事件领域：支持数字/字母/下划线，字母开头，非下划线结尾，长度不超过32字符
- 事件名称：首字符字母或$，中间字符数字/字母/下划线，结尾字符数字/字母，长度不超过48字符
- 事件参数：最多32个参数，参数名长度不超过32字符，字符串值不超过8KB，数组元素不超过100个
- triggerCondition：row正整数，size正整数byte，timeOut正整数单位30s

### 执行约束
- 最大参数数量：32个
- 最大字符串参数长度：8KB（超出会丢弃）
- 最大数组元素数：100个
- 最大观察者名称长度：32字符
- 最大事件领域长度：32字符
- 最大事件名称长度：48字符

### 内容约束
- 禁止使用系统事件名称作为应用事件名称（避免冲突）
- 禁止在回调函数中执行移除观察者操作
- 禁止订阅未在domain.OS或自定义domain中的事件
- 禁止参数值超出Number.MIN_SAFE_INTEGER~Number.MAX_SAFE_INTEGER范围

### 降级约束
- 订阅失败：返回null holder对象，记录错误日志
- 崩溃事件未生成：延时30s-2min后重试调用takeNext
- 参数超限：超出的参数自动丢弃，不抛异常
- 字符串过长：超出8KB的参数自动丢弃对应参数名和值

## 调用流程和步骤

### 步骤1：导入依赖模块

```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：订阅崩溃事件（OnReceive实时回调）

**前置校验**：
1. 确认应用在Ability onCreate中初始化订阅
2. 确认观察者名称符合命名规范
3. 确认订阅domain为hiAppEvent.domain.OS

**示例代码**：
```typescript
// 在EntryAbility.ets的onCreate函数中添加崩溃事件订阅
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

### 步骤3：订阅按钮点击事件（OnTrigger条件触发）

**前置校验**：
1. 确认triggerCondition.row设置为正整数
2. 确认自定义domain命名符合规范
3. 确认eventType为BEHAVIOR类型

**示例代码**：
```typescript
// 订阅按钮点击事件，累积1个事件后触发回调
hiAppEvent.addWatcher({
  name: 'ButtonClickWatcher',
  appEventFilters: [{ domain: 'button' }],
  triggerCondition: { row: 1 },
  
  onTrigger: (curRow: number, curSize: number, holder: hiAppEvent.AppEventPackageHolder) => {
    if (holder == null) {
      hilog.error(0x0000, 'testTag', 'holder is null');
      return;
    }
    
    hilog.info(0x0000, 'testTag', `onTrigger: curRow=${curRow}, curSize=${curSize}`);
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    
    while ((eventPkg = holder.takeNext()) != null) {
      hilog.info(0x0000, 'testTag', `packageId=${eventPkg.packageId}`);
      hilog.info(0x0000, 'testTag', `row=${eventPkg.row}`);
      hilog.info(0x0000, 'testTag', `size=${eventPkg.size}`);
      
      for (const eventInfo of eventPkg.data) {
        hilog.info(0x0000, 'testTag', `eventInfo=${eventInfo}`);
      }
    }
  }
});
```

### 步骤4：触发事件打点

**前置校验**：
1. 确认domain、name、eventType定义完整
2. 确认params参数数量不超过32个
3. 确认参数值类型为string/number/boolean或数组

**示例代码**：
```typescript
// 在按钮点击函数中进行事件打点
Button('writeEvent ArkTS')
  .onClick(() => {
    let eventParams: Record<string, number> = { 'clickTime': 100 };
    let eventInfo: hiAppEvent.AppEventInfo = {
      domain: 'button',
      name: 'click',
      eventType: hiAppEvent.EventType.BEHAVIOR,
      params: eventParams,
    };
    
    hiAppEvent.write(eventInfo).then(() => {
      hilog.info(0x0000, 'testTag', 'writeEvent success');
    }).catch((err: BusinessError) => {
      hilog.error(0x0000, 'testTag', `err.code: ${err.code}, err.message: ${err.message}`);
    });
  });
```

### 步骤5：移除观察者

**示例代码**：
```typescript
let watcher: hiAppEvent.Watcher = { name: 'testWatcher' };
hiAppEvent.addWatcher(watcher);
hiAppEvent.removeWatcher(watcher);
```

### 步骤6：错误处理

```typescript
try {
  hiAppEvent.addWatcher({
    name: 'InvalidWatcher',
    appEventFilters: [{ domain: 'test' }]
  });
} catch (error) {
  const err = error as BusinessError;
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

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定或类型错误 | 检查watcher.name、appEventFilters等参数是否正确 |
| 11102001 | 观察者名称无效：包含非法字符或长度错误 | 名称首字符必须字母，长度不超过32字符 |
| 11102002 | 事件领域无效：包含非法字符或长度错误 | 领域首字符字母，长度不超过32字符 |
| 11102003 | row值无效：负值或非数字 | row必须为正整数，默认0不触发 |
| 11102004 | size值无效：负值或非数字 | size必须为正整数byte单位 |
| 11102005 | timeout值无效：负值或非数字 | timeout必须为正整数单位30s |
| 11100001 | 功能已禁用：disable参数为true | 调用configure设置disable=false |
| 11101001 | 事件领域无效：包含非法字符或长度错误 | 检查domain命名规范 |
| 11101002 | 事件名称无效：包含非法字符或长度错误 | 检查name命名规范 |
| 11101003 | 事件参数数量超过32个 | 减少params参数数量至32个以内 |
| 11101004 | 事件参数字符串长度超过8KB | 缩短字符串参数值至8KB以内 |
| 11101005 | 事件参数名称无效：包含非法字符或长度错误 | 参数名长度不超过32字符，符合命名规范 |
| 11101006 | 事件参数数组长度超过100个元素 | 减少数组元素至100个以内 |
| 11104001 | size值无效：小于等于零 | setSize参数必须大于0 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "HarmonyOS SDK",
    "@kit.BasicServicesKit": "HarmonyOS SDK"
  }
}
```

### 环境要求
- HarmonyOS API Version：最低9（首批接口）
- 开发环境：DevEco Studio 3.0+
- 运行环境：HarmonyOS设备或模拟器

### 常见编译问题

**问题1：导入模块失败**
```
Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保项目已配置HarmonyOS SDK，检查build-profile.json5中SDK版本配置

**问题2：类型定义错误**
```
Property 'domain' does not exist on type 'hiAppEvent'
```
**解决方法**：确认使用API version 11+（domain.OS从11开始支持）

**问题3：回调参数类型错误**
```
Type 'AppEventGroup' is not defined
```
**解决方法**：从API version 11开始支持，确认SDK版本≥11

**问题4：事件名称常量错误**
```
Property 'APP_CRASH' does not exist
```
**解决方法**：APP_CRASH从API version 11开始支持，使用event.APP_CRASH

## 常见问题与解决方法

### Q1：订阅崩溃事件后没有收到回调？
**原因**：崩溃事件捕获耗时30s-2min，应用重启后事件可能未生成
**解决方法**：
- 使用手动处理方式，延时30s后重试调用takeNext
- 在onCreate中添加订阅，确保应用启动后立即监听
- 检查HiLog窗口搜索"AppEvents"关键字

### Q2：write接口返回11101003错误？
**原因**：事件参数数量超过32个限制
**解决方法**：
- 减少params对象中的参数数量
- 检查参数定义，移除非必要参数
- 确保参数数量≤32

### Q3：OnTrigger回调未触发？
**原因**：triggerCondition参数设置不当或onTrigger回调未定义
**解决方法**：
- 确认triggerCondition.row设置为正整数（如row: 1）
- 确认onTrigger回调函数已实现
- 检查holder对象是否为null

### Q4：相同名称的观察者订阅被覆盖？
**原因**：相同name的watcher，后一次订阅覆盖前一次
**解决方法**：
- 为每个观察者使用唯一的name标识
- 如需重新订阅，先removeWatcher再addWatcher

### Q5：子线程调用addWatcher时订阅失效？
**原因**：子线程在接口使用周期内被销毁
**解决方法**：
- 确保子线程在整个订阅周期内不会被销毁
- 使用Worker或长期运行的TaskPool线程
- 参考Worker简介实现子线程调用

### Q6：崩溃日志路径external_log为空？
**原因**：崩溃事件日志生成未完成或权限不足
**解决方法**：
- 延时重试获取事件，等待日志生成完成
- 检查应用是否具有读取/data/storage/el2/log目录权限
- 确认设备未限制日志文件生成

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherAdded": ["AppCrashWatcher", "ButtonClickWatcher"],
  "eventsReceived": [
    {
      "eventName": "APP_CRASH",
      "domain": "OS",
      "params": {
        "time": 1750747995874,
        "bundle_name": "com.example.myapplication",
        "external_log": "/data/storage/el2/log/hiappevent/APP_CRASH_xxx.log"
      }
    },
    {
      "eventName": "click",
      "domain": "button",
      "params": {
        "clickTime": 100
      }
    }
  ],
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.write",
    "hiAppEvent.removeWatcher"
  ]
}
```

## 参考文档

- [API开发指南 - 事件订阅（ArkTS）](references/hiappevent-watcher-app-events-arkts.md)
- [API参考说明 - @ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [多线程并发概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/multi-thread-concurrency-overview)

## 完整示例代码

- [ArkTS示例 - 崩溃事件订阅](assets/crash_event_watcher.ets)
- [ArkTS示例 - 自定义事件订阅与打点](assets/custom_event_watcher.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [测试崩溃事件订阅成功](tests/test_crash_watcher_positive.ets)：验证OnReceive回调触发并获取崩溃参数
- [测试自定义事件订阅成功](tests/test_custom_watcher_positive.ets)：验证OnTrigger回调触发并批量处理事件

### 边界测试用例
- [测试32个参数边界](tests/test_params_boundary.ets)：验证最大参数数量限制
- [测试字符串长度8KB边界](tests/test_string_length_boundary.ets)：验证字符串参数长度限制

### 异常测试用例
- [测试无效观察者名称](tests/test_invalid_watcher_name.ets)：验证名称命名规范校验
- [测试参数数量超限](tests/test_params_overflow.ets)：验证参数超过32个的丢弃处理
- [测试holder为null处理](tests/test_holder_null.ets)：验证订阅失败时的降级处理