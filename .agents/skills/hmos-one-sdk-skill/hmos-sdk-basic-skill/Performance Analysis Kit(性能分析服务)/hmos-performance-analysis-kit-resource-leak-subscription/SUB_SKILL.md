---
name: hmos-performance-analysis-kit-resource-leak-subscription
description: 订阅系统资源泄漏事件（PSS内存泄漏和JS内存泄漏），支持设置事件自定义参数、配置和策略，通过onReceive回调实时接收事件信息，适用于内存泄漏检测和性能调优场景
---

# 订阅资源泄漏事件技能

## 功能描述

本技能提供HarmonyOS系统资源泄漏事件订阅能力，支持订阅PSS内存泄漏事件和JS内存泄漏事件。开发者可以通过设置事件自定义参数、配置和策略来定制事件信息，通过onReceive回调函数实时接收事件数据，包括内存信息、页面切换日志等详细维测信息。该技能是Performance Analysis Kit（性能分析服务）的核心功能之一，主要用于应用内存泄漏检测和性能调优。

## 使用场景

### 触发词
- "订阅资源泄漏事件"
- "内存泄漏检测"
- "PSS内存泄漏"
- "JS内存泄漏"
- "HiAppEvent订阅"
- "资源泄漏监控"
- "RESOURCE_OVERLIMIT事件"

### 能做
- 订阅PSS内存泄漏事件，获取进程PSS内存信息
- 订阅JS内存泄漏事件，获取JS堆快照信息
- 设置事件自定义参数，附加业务数据到事件信息中
- 配置事件策略，启用页面切换日志记录
- 通过onReceive回调实时接收事件数据
- 获取外部日志文件路径，用于后续分析
- 在nolog版本生成虚拟机堆快照文件

### 绝不做
- 不能订阅其他类型的系统事件（如崩溃事件APP_CRASH、应用冻屏事件APP_FREEZE）
- 不能直接修复内存泄漏问题，仅提供检测和事件上报
- 不能订阅超出API version支持范围的配置项
- 不能在没有开启"系统资源泄漏日志"开关的情况下强制触发事件
- 不能在onReceive回调中执行移除观察者操作（会导致回调失效）

### 补充
- 需要在"开发者选项"中开启"系统资源泄漏日志"开关，开关状态变更后需重启设备
- 同一个应用24小时内至多上报一次资源泄漏事件，短时间二次上报需重启设备
- API version 20开始支持设置资源泄漏事件的自定义参数
- API version 22开始支持配置页面切换日志策略
- nolog版本生成堆快照文件大小约0.4至1.2GB，整机每周限制5次，应用每周限制1次
- 整机剩余存储空间不足30GB时不会触发oomdump功能

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符必须为数字、字母或下划线，结尾字符必须为数字或字母，长度不超过32个字符
- 事件领域：必须是hiAppEvent.domain.OS（系统事件领域）
- 事件名称：必须是hiAppEvent.event.RESOURCE_OVERLIMIT（资源泄漏事件）
- 自定义参数名称：首字符必须为字母或$，中间字符必须为数字、字母或下划线，结尾字符必须为数字或字母，长度不超过32个字符，参数个数不超过64个
- 自定义参数值：字符串长度不超过1024个字符
- 配置参数：参数名非空且长度不超过1024个字符，参数值长度不超过1024个字符

### 执行约束
- 订阅操作涉及I/O操作，建议在子线程调用，确保子线程在整个接口使用周期内不会被销毁
- onReceive回调是实时触发，监听到事件后立即回调
- addWatcher接口名称name唯一，相同name会覆盖前一次订阅
- 系统捕获维测日志典型情况下30s内完成，极端情况下2min左右完成
- nolog版本堆快照生成需等待3到5秒应用闪退后上报

### 内容约束
- 禁止在onReceive回调中执行removeWatcher操作
- 禁止使用相同的观察者名称订阅不同的系统事件（会被覆盖）
- 禁止订阅系统事件领域下的非资源泄漏事件（如APP_CRASH、APP_FREEZE）
- 禁止设置超出规格限制的参数值（会导致参数被丢弃）

### 降级约束
- 网络失败或权限不足：提示用户检查"开发者选项"中的"系统资源泄漏日志"开关状态
- 参数设置失败：使用默认配置，记录错误日志
- 堆快照生成失败：提示存储空间不足或配额用完，建议等待7天后重试或重启设备
- 事件未上报：提示用户等待15-30分钟（PSS泄漏）或3-5秒后重新打开应用（JS泄漏）

## 调用流程和步骤

### 步骤1：导入依赖模块

**导入必要的模块**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
import { deviceInfo, BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：设置事件自定义参数

**前置校验**：
1. 确认API version >= 12（setEventParam接口要求）
2. 确认参数名称和参数值符合规格限制
3. 确认domain为hiAppEvent.domain.OS，name为hiAppEvent.event.RESOURCE_OVERLIMIT

**参数设置示例**：
```typescript
// 完成参数键值对赋值
let params: Record<string, hiAppEvent.ParamType> = {
  "test_data": 100,
};

// 设置资源泄漏事件的自定义参数
hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT).then(() => {
  hilog.info(0x0000, 'testTag', `HiAppEvent success to set event param`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
});
```

### 步骤3：设置事件配置参数

**前置校验**：
1. 确认API version >= 15（setEventConfig接口要求）
2. 确认配置项名称有效（js_heap_logtype等）
3. 确认配置值格式正确

**配置设置示例**：
```typescript
// 完成自定义配置键值对赋值
let configParams: Record<string, hiAppEvent.ParamType> = {
  "js_heap_logtype": "event", // 仅获取事件
};

// 设置资源泄漏事件的自定义配置
hiAppEvent.setEventConfig(hiAppEvent.event.RESOURCE_OVERLIMIT, configParams);
```

### 步骤4：配置事件策略（可选）

**前置校验**：
1. 确认API version >= 24（页面切换日志支持）
2. 确认配置策略参数符合规格

**策略配置示例**：
```typescript
if (deviceInfo.sdkApiVersion >= 24) {  // API Version 24及以后版本
  // 配置页面切换日志
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "resourceOverlimitPolicy": {
      "pageSwitchLogEnable": true
    }
  };
  
  // 开发者可以设置资源泄漏日志配置参数
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(0x0000, 'testTag', `HiAppEvent success to config event policy.`);
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

### 步骤5：添加观察者订阅事件

**核心订阅代码**：
```typescript
hiAppEvent.addWatcher({
  // 自定义观察者名称，系统会使用名称来标识不同的观察者
  name: "watcher",
  
  // 订阅感兴趣的系统事件，此处是订阅了资源泄漏事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
    }
  ],
  
  // 自行实现订阅实时回调函数，以便对订阅获取到的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      // 根据事件集合中的事件名称区分不同的系统事件
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 获取到资源泄漏事件发生时内存信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo=${JSON.stringify(eventInfo)}`);
        // 开发者可以获取到资源泄漏事件的页面切换日志
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.page_switch_log=${JSON.stringify(eventInfo.params['page_switch_log'])}`);
      }
    }
  }
});
```

### 步骤6：错误处理

**错误码处理示例**：
```typescript
hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT).then(() => {
  hilog.info(0x0000, 'testTag', `Success to set event param`);
}).catch((err: BusinessError) => {
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'testTag', `Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types.`);
      break;
    case 11100001:
      hilog.error(0x0000, 'testTag', `Function disabled. Possible caused by the param disable in ConfigOption is true.`);
      break;
    case 11101001:
      hilog.error(0x0000, 'testTag', `Invalid event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid.`);
      break;
    case 11101002:
      hilog.error(0x0000, 'testTag', `Invalid event name. Possible causes: 1. Contain invalid characters; 2. Length is invalid.`);
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', `Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid.`);
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: code ${err.code}, message ${err.message}`);
  }
});
```

### 步骤7：降级处理

**降级方案示例**：
```typescript
async function subscribeResourceLeakEventWithFallback(): Promise<void> {
  try {
    // 尝试设置自定义参数
    await hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.RESOURCE_OVERLIMIT);
    hilog.info(0x0000, 'testTag', `Successfully set custom params`);
  } catch (err) {
    // 降级方案：使用默认配置，记录日志
    hilog.warn(0x0000, 'testTag', `Failed to set custom params, using default configuration`);
  }
  
  try {
    // 尝试添加观察者
    let holder = hiAppEvent.addWatcher({
      name: "watcher",
      appEventFilters: [
        {
          domain: hiAppEvent.domain.OS,
          names: [hiAppEvent.event.RESOURCE_OVERLIMIT]
        }
      ],
      onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
        // 处理事件数据
        processEventData(domain, appEventGroups);
      }
    });
    
    if (holder === null) {
      hilog.error(0x0000, 'testTag', `Failed to add watcher, subscription not active`);
    }
  } catch (err) {
    hilog.error(0x0000, 'testTag', `Failed to subscribe resource leak event`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必选参数未指定；2. 参数类型错误 | 检查参数名称、类型和取值范围是否符合规格要求 |
| 11100001 | 打点功能被关闭 | 调用configure接口开启打点功能：`hiAppEvent.configure({disable: false})` |
| 11101001 | 非法的事件领域名称 | 传入合法的事件领域名称（使用hiAppEvent.domain.OS） |
| 11101002 | 非法的事件名称 | 传入合法的事件名称（使用hiAppEvent.event.RESOURCE_OVERLIMIT） |
| 11101004 | 非法的事件参数字符串长度 | 减少参数值长度至1024个字符以内 |
| 11101005 | 非法的事件参数名称 | 传入符合规格的参数名称（首字母或$开头，长度不超过32） |
| 11101007 | 非法的事件自定义参数数量 | 减少参数数量至64个以内 |
| 11102001 | 非法的观察者名称 | 传入合法的观察者名称（字母开头，长度不超过32） |
| 11102002 | 非法的过滤事件领域 | 传入合法的过滤事件领域（使用hiAppEvent.domain.OS） |
| 11102003 | 非法的条数值 | 传入自然数值的条数值（row参数） |
| 11102004 | 非法的大小值 | 传入自然数值的大小值（size参数） |
| 11102005 | 非法的超时值 | 传入自然数值的超时值（timeOut参数） |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "API version 9+",
    "@kit.BasicServicesKit": "API version 9+"
  }
}
```

### 环境要求
- DevEco Studio: 最新版本
- HarmonyOS SDK: API version 9+（基础功能），API version 12+（setEventParam），API version 15+（setEventConfig），API version 20+（资源泄漏事件参数），API version 22+（configEventPolicy），API version 24+（页面切换日志）
- 设备要求：需要在"开发者选项"中开启"系统资源泄漏日志"开关

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**：确保DevEco Studio已安装最新版本的HarmonyOS SDK，检查API version是否满足最低要求（API 9+）

**问题2：API不存在错误**
```
Error: Property 'setEventParam' does not exist on type 'hiAppEvent'
```
**解决方法**：检查deviceInfo.sdkApiVersion是否满足API version要求（setEventParam需要API 12+）

**问题3：参数类型错误**
```
Error: Type 'string' is not assignable to type 'ParamType'
```
**解决方法**：确保参数值类型为ParamType（支持string、number、boolean类型）

**问题4：观察者订阅失败**
```
HiAppEvent code: 11102001, message: Invalid watcher name
```
**解决方法**：检查观察者名称是否符合规格（字母开头，不含下划线结尾，长度不超过32）

## 常见问题与解决方法

### Q1：为什么订阅后没有收到事件回调？
**原因**：
- 未在"开发者选项"中开启"系统资源泄漏日志"开关
- 未构造资源泄漏场景或泄漏程度未达到阈值
- 同一应用24小时内已上报过一次资源泄漏事件
- 观察者名称不符合规格导致订阅失败

**解决方法**：
- 在"开发者选项"中开启"系统资源泄漏日志"开关并重启设备
- 使用hidebug.setAppResourceLimit设置内存限制或构造JS内存泄漏场景
- 等待24小时后或重启设备以触发二次上报
- 检查观察者名称是否符合规格（使用hilog记录订阅结果）

### Q2：如何区分PSS内存泄漏和JS内存泄漏？
**原因**：两种泄漏类型的事件信息结构不同，需要根据resource_type字段判断

**解决方法**：
在onReceive回调中检查eventInfo.params.resource_type字段：
```typescript
onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
  for (const eventGroup of appEventGroups) {
    for (const eventInfo of eventGroup.appEventInfos) {
      if (eventInfo.params['resource_type'] === 'pss_memory') {
        // PSS内存泄漏事件处理
        let memoryInfo = eventInfo.params['memory'];
        hilog.info(0x0000, 'testTag', `PSS: ${memoryInfo.pss} KB`);
      } else if (eventInfo.params['resource_type'] === 'js_heap') {
        // JS内存泄漏事件处理
        let memoryInfo = eventInfo.params['memory'];
        hilog.info(0x0000, 'testTag', `JS Heap: ${memoryInfo.live_object_size}`);
      }
    }
  }
}
```

### Q3：如何在nolog版本获取JS堆快照文件？
**原因**：nolog版本需要配置oomdump参数才能生成堆快照文件

**解决方法**：
有两种配置方法（任选其一）：

方法1：在AppScope/app.json5文件中配置环境变量
```json5
"appEnvironments": [
  {
    "name": "DFX_RESOURCE_OVERLIMIT_OPTIONS",
    "value": "oomdump:enable"
  }
]
```

方法2：调用setEventConfig接口配置
```typescript
let configParams: Record<string, hiAppEvent.ParamType> = {
  "js_heap_logtype": "event_rawheap",
};
hiAppEvent.setEventConfig(hiAppEvent.event.RESOURCE_OVERLIMIT, configParams);
```

**注意**：
- 堆快照文件约0.4至1.2GB，整机每周限制5次，应用每周限制1次
- 需要将.log文件后缀修改为.rawheap，再使用translator工具转换为.heapsnapshot文件
- API version 14后可直接导入DevEco Studio展示

### Q4：页面切换日志未获取到怎么办？
**原因**：
- API version < 24不支持页面切换日志
- 未配置resourceOverlimitPolicy.pageSwitchLogEnable参数
- 应用运行期间未发生页面切换

**解决方法**：
- 检查deviceInfo.sdkApiVersion >= 24
- 调用configEventPolicy配置页面切换日志策略
```typescript
let switchLogPolicy: hiAppEvent.EventPolicy = {
  "resourceOverlimitPolicy": {
    "pageSwitchLogEnable": true
  }
};
hiAppEvent.configEventPolicy(switchLogPolicy);
```
- 在应用运行期间进行页面切换操作

### Q5：堆快照文件生成失败怎么办？
**原因**：
- 整机或应用配额已用完
- 整机剩余存储空间不足30GB
- 未开启系统资源泄漏日志开关

**解决方法**：
- 等待7天后自动重置配额，或调整系统时间至7天后并重启设备（调试期间）
- 清理设备存储空间至30GB以上
- 在"开发者选项"中开启"系统资源泄漏日志"开关并重启设备

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "subscriptionStatus": "active",
  "watcherName": "watcher",
  "eventDomain": "OS",
  "eventName": "RESOURCE_OVERLIMIT",
  "customParams": {
    "test_data": 100
  },
  "eventConfig": {
    "js_heap_logtype": "event"
  },
  "pageSwitchLogEnabled": true,
  "apiUsed": [
    "hiAppEvent.setEventParam",
    "hiAppEvent.setEventConfig",
    "hiAppEvent.configEventPolicy",
    "hiAppEvent.addWatcher"
  ],
  "apiVersion": {
    "setEventParam": "12+",
    "setEventConfig": "15+",
    "configEventPolicy": "22+",
    "pageSwitchLog": "24+"
  }
}
```

事件回调数据示例：

**PSS内存泄漏事件**：
```json
{
  "domain": "OS",
  "name": "RESOURCE_OVERLIMIT",
  "eventType": 1,
  "params": {
    "bundle_name": "com.example.myapplication",
    "app_running_unique_id": "26457812872126536953",
    "bundle_version": "1.0.0",
    "memory": {
      "pss": 2100257,
      "rss": 1352644,
      "sys_avail_mem": 250272,
      "sys_free_mem": 60004,
      "sys_total_mem": 1992340,
      "vss": 2462936
    },
    "pid": 20731,
    "resource_type": "pss_memory",
    "time": 1502348798106,
    "uid": 20010044,
    "external_log": [
      "/data/storage/el2/log/resourcelimit/RESOURCE_OVERLIMIT_1725614572401_6808.log",
      "/data/storage/el2/log/resourcelimit/RESOURCE_OVERLIMIT_1725614572412_6808.log"
    ],
    "log_over_limit": false,
    "page_switch_log": "[\"/data/storage/el2/log/page_switch/snapshot/page_switch-com.example.myapplication-1-1-20260427162423841.log\"]"
  }
}
```

**JS内存泄漏事件**：
```json
{
  "domain": "OS",
  "name": "RESOURCE_OVERLIMIT",
  "eventType": 1,
  "params": {
    "bundle_name": "com.example.myapplication",
    "app_running_unique_id": "45354125624752145258",
    "bundle_version": "1.0.0",
    "external_log": [],
    "log_over_limit": true,
    "memory": {
      "limit_size": 0,
      "live_object_size": 0
    },
    "pid": 14941,
    "resource_type": "js_heap",
    "test_data": 100,
    "time": 1752564700511,
    "uid": 20020181,
    "page_switch_log": "[\"/data/storage/el2/log/page_switch/snapshot/page_switch-com.example.myapplication-1-1-20260427162423841.log\"]"
  }
}
```

## 参考文档

- [API开发指南：订阅资源泄漏事件（ArkTS）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events-arkts)
- [API参考说明：@ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [错误码说明：应用事件打点错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent)
- [故障检测：Resource Leak（资源泄漏）检测](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/resource-leak-guidelines)
- [调试命令：rawheap-translator工具](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/rawheap-translator)
- [内存分析：Snapshot模板基本操作](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ide-snapshot-basic-operations)
- [系统事件：资源泄漏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events)

## 完整示例代码

- [ArkTS示例代码](assets/example_resource_leak_subscription.ets)
- [Native C++示例代码](assets/example_native_leak.cpp)
- [配置文件示例](assets/config_example.json5)

## 测试用例

### 正向测试用例
- [订阅PSS内存泄漏事件](tests/test_pss_leak_positive.ets)：构造PSS内存泄漏场景，验证事件订阅成功并获取内存信息
- [订阅JS内存泄漏事件](tests/test_js_leak_positive.ets)：构造JS内存泄漏场景，验证事件订阅成功并获取堆快照
- [设置自定义参数](tests/test_custom_params_positive.ets)：设置合法的自定义参数，验证参数附加到事件信息中
- [配置页面切换日志](tests/test_page_switch_log_positive.ets)：启用页面切换日志策略，验证获取页面切换日志路径

### 边界测试用例
- [最大参数数量测试](tests/test_max_params_boundary.ets)：设置64个自定义参数，验证参数数量限制
- [最大参数长度测试](tests/test_max_param_length_boundary.ets)：设置1024字符长度的参数值，验证参数长度限制
- [观察者名称边界测试](tests/test_watcher_name_boundary.ets)：使用32字符长度的观察者名称，验证名称长度限制
- [API版本边界测试](tests/test_api_version_boundary.ets)：在不同API version设备上验证接口可用性

### 异常测试用例
- [非法观察者名称测试](tests/test_invalid_watcher_name.ets)：使用非法观察者名称，验证返回11102001错误码
- [非法事件领域测试](tests/test_invalid_domain.ets)：使用非法事件领域，验证返回11101001错误码
- [参数超限测试](tests/test_param_exceed_limit.ets)：设置超出规格的参数，验证参数被丢弃或接口返回错误
- [未开启系统开关测试](tests/test_switch_disabled.ets)：未开启"系统资源泄漏日志"开关，验证事件未上报
- [堆快照配额用完测试](tests/test_quota_exhausted.ets)：堆快照配额用完后验证生成失败并提示降级方案