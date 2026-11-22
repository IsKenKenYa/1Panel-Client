---
name: hmos-performance-analysis-kit-hiappevent-freeze-events
description: 订阅应用冻屏事件，实时获取应用冻屏故障信息，支持自定义参数设置和页面切换日志配置，适用于应用性能监控、故障诊断场景
---

# 订阅应用冻屏事件技能

## 功能描述

本技能用于帮助开发者使用HarmonyOS HiAppEvent API订阅应用冻屏事件。当应用出现无响应（冻屏）时，系统会自动捕获并上报冻屏事件，开发者可通过订阅获取详细的故障信息，包括时间戳、前后台状态、进程信息、线程调用栈、内存信息、故障日志等。

**核心能力**：
- 实时订阅应用冻屏事件
- 设置自定义参数关联故障信息
- 配置页面切换日志（API Version 24+）
- 获取完整的冻屏事件参数（时间、进程、线程栈、内存、日志等）
- 迁移FaultLogger API订阅能力

**适用场景**：
- 应用性能监控和故障诊断
- 自动化崩溃收集和分析
- 线上问题追踪和定位

## 使用场景

### 触发词
- "订阅应用冻屏事件"
- "监听应用无响应"
- "应用卡死事件订阅"
- "冻屏事件回调"
- "HiAppEvent订阅APP_FREEZE"
- "应用ANR事件监听"

### 能做
- 订阅系统应用冻屏事件（APP_FREEZE）
- 获取冻屏事件的详细参数信息
- 设置自定义参数追踪故障上下文
- 配置页面切换日志辅助诊断（API Version 24+）
- 迁移FaultLogger API订阅冻屏事件

### 绝不做
- 不订阅非冻屏类型的系统事件
- 不处理应用自定义事件
- 不替代崩溃事件订阅
- 不修改系统冻屏检测机制

### 补充
- 系统捕获冻屏维测日志典型耗时30s，极端情况2min
- API Version 24+支持页面切换日志配置
- 订阅接口名称唯一，重复调用会覆盖之前订阅
- 建议在子线程调用addWatcher接口避免性能影响

## 调用规范和规则

### 输入约束
- 自定义参数名：首字符必须为字母或$，中间为数字/字母/下划线，结尾为数字/字母，长度≤32字符
- 自定义参数值：支持string/number/boolean/数组，string长度≤1024字符，数组元素≤100个
- 自定义参数个数：≤64个
- 观察者名称：首字符为字母，中间为数字/字母/下划线，结尾为数字/字母，长度≤32字符
- 事件域名：hiAppEvent.domain.OS
- 事件名称：hiAppEvent.event.APP_FREEZE

### 执行约束
- addWatcher接口涉及I/O操作，建议在子线程调用
- 订阅回调函数中避免执行移除观察者操作
- 确保子线程在整个接口使用周期内不被销毁
- 系统捕获维测日志典型耗时30s，极端情况2min

### 内容约束
- 禁止使用eval、exec等高危函数
- 禁止在回调中执行耗时操作阻塞主线程
- 禁止订阅名称使用系统保留字
- 禁止修改系统事件参数

### 降级约束
- 网络失败：重试订阅或使用takeNext主动获取
- 参数校验失败：使用默认参数继续订阅
- API版本不支持：降级到基础订阅功能
- 回调未触发：使用takeNext轮询获取事件

## 调用流程和步骤

### 步骤1：导入依赖模块

**导入必要模块**：

```typescript
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2：设置事件自定义参数

**前置校验**：
1. 检查API版本是否支持页面切换日志（API Version 24+）
2. 验证自定义参数格式和长度
3. 确认应用冻屏事件领域和名称

**参数设置代码**：

```typescript
// 设置自定义参数
let params: Record<string, hiAppEvent.ParamType> = {
  "test_data": 100,
};

hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.APP_FREEZE).then(() => {
  hilog.info(0x0000, 'testTag', `HiAppEvent success to set event param`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
});

// API Version 24+支持页面切换日志配置
if (deviceInfo.sdkApiVersion >= 24) {
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "appFreezePolicy": {
      "pageSwitchLogEnable": true
    }
  };
  
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(0x0000, 'testTag', `HiAppEvent success to config event policy.`);
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

### 步骤3：添加事件观察者订阅冻屏事件

**订阅实现代码**：

```typescript
hiAppEvent.addWatcher({
  // 观察者名称，唯一标识
  name: "freeze_watcher",
  
  // 订阅应用冻屏事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  
  // 实时回调函数
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 基础信息
        hilog.info(0x0000, 'testTag', `eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `eventInfo.name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `eventInfo.eventType=${eventInfo.eventType}`);
        
        // 时间和状态
        hilog.info(0x0000, 'testTag', `eventInfo.params.time=${eventInfo.params['time']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.foreground=${eventInfo.params['foreground']}`);
        
        // 应用信息
        hilog.info(0x0000, 'testTag', `eventInfo.params.app_running_unique_id=${eventInfo.params['app_running_unique_id']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.process_name=${eventInfo.params['process_name']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.pid=${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.uid=${eventInfo.params['uid']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.uuid=${eventInfo.params['uuid']}`);
        
        // 异常信息
        hilog.info(0x0000, 'testTag', `eventInfo.params.exception=${JSON.stringify(eventInfo.params['exception'])}`);
        
        // 日志和调用栈
        hilog.info(0x0000, 'testTag', `eventInfo.params.hilog.size=${eventInfo.params['hilog'].length}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.event_handler.size=${eventInfo.params['event_handler'].length}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.event_handler_size_3s=${eventInfo.params['event_handler_size_3s']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.event_handler_size_6s=${eventInfo.params['event_handler_size_6s']}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.peer_binder.size=${eventInfo.params['peer_binder'].length}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.threads.size=${eventInfo.params['threads'].length}`);
        
        // 内存信息
        hilog.info(0x0000, 'testTag', `eventInfo.params.memory=${JSON.stringify(eventInfo.params['memory'])}`);
        
        // 故障日志
        hilog.info(0x0000, 'testTag', `eventInfo.params.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
        hilog.info(0x0000, 'testTag', `eventInfo.params.log_over_limit=${eventInfo.params['log_over_limit']}`);
        
        // 自定义参数
        hilog.info(0x0000, 'testTag', `eventInfo.params.test_data=${eventInfo.params['test_data']}`);
        
        // 进程存活时间
        hilog.info(0x0000, 'testTag', `eventInfo.params.process_life_time=${eventInfo.params['process_life_time']}`);
        
        // 回调日志
        hilog.info(0x0000, 'testTag', `eventInfo.params.external_callback_log=${eventInfo.params['external_callback_log']}`);
        
        // 页面切换日志
        hilog.info(0x0000, 'testTag', `eventInfo.params.page_switch_log=${JSON.stringify(eventInfo.params['page_switch_log'])}`);
      }
    }
  }
});
```

### 步骤4：触发测试场景（可选）

**测试代码**：

```typescript
// 构造冻屏场景测试
Button("触发冻屏测试").onClick(() => {
  setTimeout(() => {
    let t = Date.now();
    while (Date.now() - t <= 15000) {} // 阻塞主线程15秒
  }, 5000);
});
```

### 步骤5：错误处理

```typescript
try {
  hiAppEvent.addWatcher({
    name: "freeze_watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_FREEZE]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 处理事件
    }
  });
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'testTag', `Parameter error: ${err.message}`);
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', `Invalid watcher name: ${err.message}`);
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', `Invalid filtering event domain: ${err.message}`);
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: code=${err.code}, message=${err.message}`);
  }
}
```

### 步骤6：降级处理

```typescript
// 降级方案：使用takeNext主动获取事件
let holder: hiAppEvent.AppEventPackageHolder | null = null;

try {
  holder = hiAppEvent.addWatcher({
    name: "freeze_watcher_fallback",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_FREEZE]
      }
    ]
  });
} catch (error) {
  hilog.error(0x0000, 'testTag', 'Failed to add watcher, using fallback method');
}

// 延时重试获取事件
if (holder) {
  setTimeout(() => {
    let eventPkg: hiAppEvent.AppEventPackage | null = null;
    while ((eventPkg = holder!.takeNext()) != null) {
      hilog.info(0x0000, 'testTag', `eventPkg.row=${eventPkg.row}`);
      for (const eventInfo of eventPkg.appEventInfos) {
        hilog.info(0x0000, 'testTag', `event=${JSON.stringify(eventInfo)}`);
      }
    }
  }, 30000); // 30秒后尝试获取
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误，可能原因：1.必填参数未指定；2.参数类型不正确 | 检查参数是否完整且类型正确 |
| 11102001 | 观察者名称无效，可能原因：1.包含非法字符；2.长度无效 | 使用合法的观察者名称：首字符为字母，中间为数字/字母/下划线，结尾为数字/字母，长度≤32 |
| 11102002 | 事件领域过滤条件无效，可能原因：1.包含非法字符；2.长度无效 | 使用hiAppEvent.domain.OS等系统定义的领域常量 |
| 11102003 | row值无效，可能原因：row值小于0 | 设置非负的row值 |
| 11102004 | size值无效，可能原因：size值小于0 | 设置非负的size值 |
| 11102005 | timeout值无效，可能原因：timeout值小于0 | 设置非负的timeout值 |
| 11100001 | 功能禁用，可能原因：ConfigOption中disable参数为true | 检查配置选项，确保disable未设置为true |
| 11101001 | 事件领域无效，可能原因：1.包含非法字符；2.长度无效 | 使用合法的事件领域：数字/字母/下划线，字母开头，非下划线结尾，长度≤32 |
| 11101002 | 事件名称无效，可能原因：1.包含非法字符；2.长度无效 | 使用合法的事件名称：首字符为字母或$，中间为数字/字母/下划线，结尾为数字/字母，长度≤48 |
| 11101004 | 事件参数字符串长度无效 | 确保参数字符串长度≤8*1024字符 |
| 11101005 | 事件参数名称无效，可能原因：1.包含非法字符；2.长度无效 | 使用合法的参数名：首字符为字母或$，中间为数字/字母/下划线，结尾为数字/字母，长度≤32 |
| 11101007 | 参数键数量超过限制 | 确保参数个数≤64 |

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "latest",
    "@kit.BasicServicesKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS SDK: API Version 9+ （基础功能）
- HarmonyOS SDK: API Version 12+ （setEventParam）
- HarmonyOS SDK: API Version 22+ （configEventPolicy）
- HarmonyOS SDK: API Version 24+ （页面切换日志配置）
- 开发环境: DevEco Studio 3.1+

### 常见编译问题

**问题1：找不到hiAppEvent模块**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit' or its corresponding type declarations.
```
**解决方法**：确保HarmonyOS SDK版本≥API 9，在oh-package.json5中添加依赖。

**问题2：deviceInfo.sdkApiVersion未定义**
```
Error: Property 'sdkApiVersion' does not exist on type 'DeviceInfo'.
```
**解决方法**：导入正确的deviceInfo模块：`import { deviceInfo } from '@kit.BasicServicesKit';`

**问题3：configEventPolicy方法不存在**
```
Error: Property 'configEventPolicy' does not exist on type 'typeof hiAppEvent'.
```
**解决方法**：确保API Version≥22，添加版本判断：`if (deviceInfo.sdkApiVersion >= 22)`。

**问题4：订阅回调未触发**
```
订阅成功但回调函数未被调用
```
**解决方法**：系统捕获冻屏维测日志需要时间，建议：
1. 使用takeNext方法主动轮询获取事件
2. 延时30秒后重试获取事件
3. 检查是否在回调中执行了移除观察者操作

## 常见问题与解决方法

### Q1：如何验证订阅是否成功？
**原因**：订阅成功后没有明显提示
**解决方法**：
- 检查addWatcher返回值，订阅失败返回null
- 触发测试冻屏场景验证回调
- 使用hilog查看日志输出

### Q2：冻屏事件回调未及时触发？
**原因**：系统捕获维测日志耗时，典型30s，极端2min
**解决方法**：
- 使用takeNext方法主动获取事件
- 延时重试获取（建议30秒后）
- 在onReceive回调中实时处理事件

### Q3：如何从FaultLogger API迁移？
**原因**：FaultLogger从API Version 18开始废弃
**解决方法**：
- 使用hiAppEvent.addWatcher替代FaultLogger.query
- 设置domain为hiAppEvent.domain.OS
- 设置names为[hiAppEvent.event.APP_FREEZE]
- 通过eventInfo.params获取字段信息
- 参考字段对应关系：pid→pid, uid→uid, timestamp→time, module→bundle_name, fullLog→external_log

### Q4：自定义参数未出现在事件信息中？
**原因**：参数设置时机或格式不正确
**解决方法**：
- 确保在订阅前调用setEventParam
- 检查参数名称格式（字母开头，≤32字符）
- 验证参数值类型和长度
- 使用try-catch捕获setEventParam错误

### Q5：页面切换日志为空？
**原因**：API版本不支持或未启用配置
**解决方法**：
- 确认API Version≥24
- 调用configEventPolicy启用pageSwitchLogEnable
- 在onCreate中配置，早于冻屏发生

### Q6：回调中能否移除观察者？
**原因**：在回调中移除观察者会导致订阅失效
**解决方法**：
- 不建议在回调中执行removeWatcher操作
- 如需移除，在回调外执行
- 避免在回调中执行耗时操作

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcher_name": "freeze_watcher",
  "subscribed_event": "APP_FREEZE",
  "custom_params": ["test_data"],
  "page_switch_log_enabled": true,
  "api_used": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.setEventParam",
    "hiAppEvent.configEventPolicy"
  ]
}
```

## 参考文档

- [API开发指南 - 订阅应用冻屏事件（ArkTS）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events-arkts)
- [API参考 - @ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [API参考 - 通用错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-universal)
- [API参考 - 应用事件打点错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-hiappevent)

## 完整示例代码

- [ArkTS示例 - 订阅应用冻屏事件](assets/freeze_event_watcher.ets)
- [完整应用工程示例](https://gitcode.com/HarmonyOS_Samples/exception-handling)

## 测试用例

### 正向测试用例
- [基本订阅测试](tests/test_basic_subscription.ts)：测试基本的应用冻屏事件订阅功能
- [自定义参数测试](tests/test_custom_params.ts)：测试设置自定义参数并验证参数出现在事件中
- [页面切换日志测试](tests/test_page_switch_log.ts)：测试API 24+页面切换日志配置

### 边界测试用例
- [参数长度边界测试](tests/test_param_boundary.ts)：测试参数名称、值长度的边界值
- [参数个数边界测试](tests/test_param_count.ts)：测试参数个数的边界值（最多64个）
- [API版本兼容测试](tests/test_api_version.ts)：测试不同API版本的功能兼容性

### 异常测试用例
- [非法观察者名称测试](tests/test_invalid_watcher_name.ts)：测试非法观察者名称的错误处理
- [无效参数测试](tests/test_invalid_params.ts)：测试无效参数的错误处理
- [重复订阅测试](tests/test_duplicate_subscription.ts)：测试重复订阅同名观察者的处理