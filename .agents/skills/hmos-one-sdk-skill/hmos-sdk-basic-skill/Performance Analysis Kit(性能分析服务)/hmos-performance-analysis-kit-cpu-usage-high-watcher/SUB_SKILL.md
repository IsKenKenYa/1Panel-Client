---
name: hmos-performance-analysis-kit-cpu-usage-high-watcher
description: 订阅应用CPU高负载事件，支持自定义阈值策略配置，适用于性能监控、异常诊断、功耗优化场景
---

# 订阅CPU高负载事件技能

## 功能描述

本技能提供订阅HarmonyOS应用CPU高负载事件的能力。通过HiAppEvent接口，开发者可以实时监听应用CPU使用率异常事件，并自定义CPU高负载检测策略，包括前台/后台阈值、线程阈值、采样次数等参数。适用于应用性能监控、异常诊断、功耗优化等场景。

**核心能力**：
- 实时订阅CPU高负载系统事件（CPU_USAGE_HIGH）
- 自定义CPU高负载检测策略（前台阈值、后台阈值、线程阈值等）
- 获取CPU高负载事件的详细信息（线程使用率、采样栈日志等）
- 配置采样栈采集次数和检测周期

**适用范围**：
- API version 12及以上
- 仅支持ArkTS语言
- 需导入@kit.PerformanceAnalysisKit

**技术特点**：
- 支持实时回调（onReceive）和条件回调（onTrigger）两种订阅模式
- 支持自定义CPU负载阈值策略
- 自动抓取采样栈日志，辅助定位高负载线程
- 事件信息包含线程级CPU使用率数据

## 使用场景

### 触发词
- "订阅CPU高负载事件"
- "监听CPU使用率异常"
- "CPU性能监控"
- "CPU高负载检测"
- "CPU阈值配置"
- "性能分析订阅"
- "HiAppEvent CPU事件"

### 能做
- 订阅系统级CPU高负载事件，实时获取事件信息
- 自定义CPU高负载检测策略参数（前台/后台阈值、线程阈值、采样次数等）
- 处理CPU高负载事件回调，获取线程级CPU使用率数据
- 配置采样栈日志采集策略
- 移除CPU高负载事件订阅

### 绝不做
- 不订阅非CPU高负载的系统事件（如崩溃事件、冻屏事件等）
- 不修改超出API规范的阈值参数（如前台阈值超过100%）
- 不在回调函数中执行移除观察者操作
- 不直接订阅应用自定义事件
- 不处理超出Performance Analysis Kit范围的请求

### 补充
- CPU高负载事件默认抓取次数有限制，可通过configEventPolicy配置
- Debug版本应用采样栈次数范围：[-1, 100]，Release版本范围：[0, 20]
- 抓取采样栈有内存开销和功耗影响，建议仅在本地调试时使用自定义参数
- CPU高负载事件检测周期可配置，最小5秒，最大3600秒
- 事件信息包含external_log字段，指向采样栈日志文件路径

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符为数字/字母/下划线，结尾字符为数字/字母，长度不超过32字符
- CPU阈值：前台阈值范围[1, 100]，后台阈值范围[1, 100]，线程阈值范围[15, 100]
- 采样次数：Debug版本[-1, 100]，Release版本[0, 20]
- 检测周期：范围[5, 3600]秒
- 参数数量：策略参数个数不超过5个

### 执行约束
- 最大耗时：configEventPolicy接口为异步Promise调用，耗时通常在毫秒级
- 最大迭代次数：单次配置策略调用1次API
- API调用频次：建议应用生命周期内调用1次策略配置
- 回调执行时间：onReceive回调应在100ms内完成，避免阻塞主线程

### 内容约束
- 禁止生成：禁止生成非HiAppEvent API的调用代码
- 禁止使用高危函数：禁止使用eval、exec等高危函数
- 禁止操作：禁止在回调中移除观察者、禁止超出阈值范围配置

### 降级约束
- 网络失败：不涉及网络请求，无需降级
- 配置失败：策略配置失败时使用系统默认值（前台30%、后台10%、线程70%）
- 订阅失败：订阅失败时返回null，需检查观察者名称和事件过滤器参数
- 参数错误：超出范围的参数值会被系统置为默认值

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本：确保设备支持API version 12及以上
2. 检查依赖模块：确保已导入@kit.PerformanceAnalysisKit和@kit.BasicServicesKit
3. 检查权限配置：无需特殊权限配置

**参数准备**：
```typescript
// 导入必要模块
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义观察者名称（唯一标识）
const watcherName: string = "cpuWatcher";

// 定义订阅的事件过滤器
const appEventFilters: hiAppEvent.AppEventFilter[] = [
  {
    domain: hiAppEvent.domain.OS,  // 系统事件领域
    names: [hiAppEvent.event.CPU_USAGE_HIGH]  // CPU高负载事件名称
  }
];
```

### 步骤2：订阅CPU高负载事件

**示例代码**：
```typescript
// 添加事件观察者，订阅CPU高负载事件
hiAppEvent.addWatcher({
  name: watcherName,  // 观察者名称
  appEventFilters: appEventFilters,  // 事件过滤器
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo=${JSON.stringify(eventInfo)}`);
      }
    }
  }
});
```

### 步骤3：配置CPU高负载策略（可选）

**示例代码**：
```typescript
// 自定义CPU高负载事件的配置策略
let policy: hiAppEvent.EventPolicy = {
  "cpuUsageHighPolicy": {
    "foregroundLoadThreshold": 10,   // 应用前台CPU负载异常阈值10%
    "backgroundLoadThreshold": 5,    // 应用后台CPU负载异常阈值5%
    "threadLoadThreshold": 50,       // 应用线程CPU负载异常阈值50%
    "perfLogCaptureCount": 3,        // 采样栈每日采集次数上限3次
    "threadLoadInterval": 30,        // 应用线程负载异常检测周期30秒
  }
};

hiAppEvent.configEventPolicy(policy).then(() => {
  hilog.info(0x0000, 'hiAppEvent', `Successfully set cpu usage high event policy.`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'hiAppEvent', `Failed to set cpu usage high event policy. Code: ${err?.code}, message: ${err?.message}`);
});
```

### 步骤4：处理事件回调

**示例代码**：
```typescript
// 处理CPU高负载事件回调
onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
  hilog.info(0x0000, 'CPUWatcher', `Received CPU_USAGE_HIGH event from domain: ${domain}`);
  
  for (const eventGroup of appEventGroups) {
    if (eventGroup.name === hiAppEvent.event.CPU_USAGE_HIGH) {
      for (const eventInfo of eventGroup.appEventInfos) {
        // 解析事件参数
        const params = eventInfo.params;
        const threads = params.threads;  // 线程列表
        const usage = params.usage;      // 总CPU使用率
        const externalLog = params.external_log;  // 采样栈日志路径
        
        hilog.info(0x0000, 'CPUWatcher', `Total CPU usage: ${usage}%`);
        for (const thread of threads) {
          hilog.info(0x0000, 'CPUWatcher', `Thread: ${thread.name}, tid: ${thread.tid}, usage: ${thread.usage}%`);
        }
        
        if (externalLog && externalLog.length > 0) {
          hilog.info(0x0000, 'CPUWatcher', `External log files: ${externalLog.join(',')}`);
        }
      }
    }
  }
}
```

### 步骤5：移除订阅（可选）

**示例代码**：
```typescript
// 移除事件观察者，取消订阅
let watcher: hiAppEvent.Watcher = {
  name: watcherName,
};
hiAppEvent.removeWatcher(watcher);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，必填参数未指定或参数类型错误 | 检查参数是否完整、类型是否正确 |
| 11102001 | 观察者名称无效，包含无效字符或长度无效 | 使用规范命名：字母开头、字母/数字/下划线中间、字母/数字结尾、长度≤32 |
| 11102002 | 事件领域过滤无效，包含无效字符或长度无效 | 使用hiAppEvent.domain.OS系统领域常量 |
| 11102003 | row值无效，小于零 | 设置正整数或使用默认值 |
| 11102004 | size值无效，小于零 | 设置正整数或使用默认值 |
| 11102005 | timeout值无效，小于零 | 设置正整数或使用默认值 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "API 12+",
    "@kit.BasicServicesKit": "API 12+"
  }
}
```

### 环境要求
- HarmonyOS API version：12及以上
- DevEco Studio：3.1及以上
- 设备类型：支持所有HarmonyOS设备

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保项目API版本≥12，在build-profile.json5中配置正确的compileSdkVersion

**问题2：事件名称未定义**
```
Error: Property 'CPU_USAGE_HIGH' does not exist on type 'event'
```
**解决方法**：检查API版本是否≥12，CPU_USAGE_HIGH常量从API 12开始支持

**问题3：策略配置参数错误**
```
Error: Invalid parameter value for foregroundLoadThreshold
```
**解决方法**：确保阈值参数在有效范围内，前台阈值[1, 100]，后台阈值[1, 100]，线程阈值[15, 100]

## 常见问题与解决方法

### Q1：未触发CPU高负载事件回调
**原因**：
- CPU使用率未达到默认阈值（前台30%、后台10%、线程70%）
- 应用在前台且CPU使用率低于前台阈值
- 观察者名称重复或无效

**解决方法**：
- 使用多线程执行死循环触发CPU高负载（如示例代码中的worker线程）
- 自定义降低CPU阈值策略，使用configEventPolicy接口
- 检查观察者名称是否唯一、符合规范
- 确保应用在前台运行，保持屏幕亮屏状态

### Q2：未获取到采样栈日志（external_log字段为空）
**原因**：
- 采样栈采集次数已达到每日上限
- Release版本应用默认采集次数限制为20次
- Debug版本应用未配置perfLogCaptureCount参数

**解决方法**：
- 使用configEventPolicy配置perfLogCaptureCount参数
- Debug版本可设置-1表示不限制采集次数
- 重启测试设备重新抓取
- 检查事件信息中的log_over_limit字段

### Q3：策略配置失败，返回错误码
**原因**：
- 参数超出有效范围（如前台阈值>100）
- 参数类型错误（如字符串而非数字）
- 未导入BusinessError模块处理错误

**解决方法**：
- 检查参数值是否在有效范围内
- 确保参数类型正确（foregroundLoadThreshold等为number类型）
- 使用Promise.catch捕获错误，打印错误码和message

### Q4：订阅后长时间未收到事件
**原因**：
- CPU高负载检测周期默认60秒，需等待检测周期
- 应用未触发足够的CPU负载
- 系统事件上报延迟

**解决方法**：
- 使用configEventPolicy配置threadLoadInterval缩短检测周期（最小5秒）
- 应用保持前台运行，触发多线程高负载操作
- 等待5-10分钟观察日志输出

### Q5：事件信息中的线程数据不准确
**原因**：
- 线程CPU使用率数据为检测周期内的平均值
- Worker线程创建时间短，未纳入检测
- 系统采样间隔导致数据延迟

**解决方法**：
- 硿保线程持续运行超过检测周期
- 配置threadLoadInterval缩短检测周期
- 解析threads数组数据，结合时间戳分析

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "cpuWatcher",
  "eventType": "CPU_USAGE_HIGH",
  "configPolicy": {
    "foregroundLoadThreshold": 10,
    "backgroundLoadThreshold": 5,
    "threadLoadThreshold": 50,
    "perfLogCaptureCount": 3,
    "threadLoadInterval": 30
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.configEventPolicy",
    "hiAppEvent.event.CPU_USAGE_HIGH",
    "hiAppEvent.domain.OS"
  ],
  "eventInfo": {
    "domain": "OS",
    "name": "CPU_USAGE_HIGH",
    "params": {
      "usage": 25,
      "threads": [
        {"name": "WorkerThread", "tid": 60856, "usage": 7.43}
      ],
      "external_log": [
        "/data/storage/el2/log/hiappevent/CPU_USAGE_HIGH_xxx.log"
      ]
    }
  }
}
```

## 参考文档

- [API开发指南 - 订阅CPU高负载事件(ArkTS)](references/hiappevent-watcher-cpu-usage-high-arkts.md)
- [API参考说明 - @ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [系统事件 - 崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [功耗检测限制说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/power-detection)

## 完整示例代码

- [ArkTS示例 - 完整CPU高负载订阅流程](assets/cpu_usage_high_watcher_example.ets)
- [ArkTS示例 - 多线程CPU加压测试](assets/cpu_stress_test.ets)
- [ArkTS示例 - Worker线程死循环](assets/worker_cpu_stress.ets)
- [配置示例 - CPU策略配置JSON](assets/cpu_policy_config.json)

## 测试用例

### 正向测试用例
- [测试：订阅CPU高负载事件并接收回调](tests/test_positive_cpu_watcher.py) - 验证基本订阅功能
- [测试：配置自定义CPU阈值策略](tests/test_positive_policy_config.py) - 验证策略配置功能
- [测试：获取事件线程数据](tests/test_positive_event_data.py) - 验证事件信息解析

### 边界测试用例
- [测试：CPU阈值边界值（1%和100%）](tests/test_boundary_threshold.py) - 验证阈值边界范围
- [测试：采样次数边界值](tests/test_boundary_capture_count.py) - 验证采集次数范围
- [测试：检测周期边界值（5秒和3600秒）](tests/test_boundary_interval.py) - 验证周期范围

### 异常测试用例
- [测试：观察者名称包含无效字符](tests/test_exception_invalid_name.py) - 验证名称规范校验
- [测试：CPU阈值超出范围](tests/test_exception_threshold_range.py) - 验证参数范围校验
- [测试：订阅重复观察者名称](tests/test_exception_duplicate_watcher.py) - 验证唯一性校验