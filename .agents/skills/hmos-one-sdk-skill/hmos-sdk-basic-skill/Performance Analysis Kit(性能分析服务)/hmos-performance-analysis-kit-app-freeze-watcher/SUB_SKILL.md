---
name: hmos-performance-analysis-kit-app-freeze-watcher
description: 订阅应用冻屏事件(APP_FREEZE),获取冻屏事件详细信息(时间戳、前后台状态、异常类型、调用栈等),支持自定义参数设置和页面切换日志配置,适用于应用性能监控、故障排查场景
---

# 订阅应用冻屏事件技能

## 功能描述

本技能实现HarmonyOS应用冻屏事件的订阅和处理功能。通过HiAppEvent提供的ArkTS接口订阅应用冻屏事件(APP_FREEZE),实时获取冻屏发生时的详细信息,包括时间戳、前后台状态、进程信息、异常类型、调用栈、内存信息等。支持设置自定义参数和页面切换日志配置,帮助开发者快速定位和解决应用冻屏问题。

**核心能力**:
- 订阅应用冻屏事件(APP_FREEZE)
- 实时获取冻屏事件详细信息
- 设置事件自定义参数
- 配置页面切换日志
- 提取冻屏事件的各项参数字段

**适用范围**:
- HarmonyOS应用开发
- API version 11及以上
- ArkTS语言开发

**典型场景**:
- 应用性能监控和调优
- 应用冻屏故障排查
- 应用稳定性分析
- 用户体验优化

## 使用场景

### 触发词
- "订阅应用冻屏事件"
- "监听应用冻屏"
- "应用冻屏事件"
- "APP_FREEZE事件"
- "应用无响应监控"
- "应用卡死检测"

### 能做
- 订阅应用冻屏事件并实时接收回调通知
- 获取冻屏事件的完整参数信息(时间戳、前后台状态、进程信息、异常类型等)
- 设置冻屏事件的自定义参数
- 配置页面切换日志采集
- 处理冻屏事件的回调数据
- 提取冻屏日志文件路径

### 绝不做
- 不订阅非冻屏事件(如崩溃事件APP_CRASH)
- 不处理应用主动退出的场景
- 不修改系统冻屏检测阈值
- 不在回调函数中移除观察者(可能导致部分事件丢失)

### 补充
- 应用冻屏事件是指应用主线程连续6秒无响应的场景
- 系统捕获维测日志有一定耗时,典型情况下30s内完成,极端情况下2min左右完成
- API version 24及以后版本支持设置页面切换日志配置
- 相同的观察者name会被后一次调用覆盖前一次的订阅

## 调用规范和规则

### 输入约束
- 观察者名称:首字符必须为字母字符,中间字符必须为数字字符、字母字符或下划线字符,结尾字符必须为数字字符或字母字符,长度非空且不超过32个字符
- 事件领域:必须使用hiAppEvent.domain.OS(系统事件领域)
- 事件名称:必须使用hiAppEvent.event.APP_FREEZE(应用冻屏事件)
- 自定义参数名:首字符必须为字母字符或$字符,中间字符必须为数字字符、字母字符或下划线字符,结尾字符必须为数字字符或字母字符,长度非空且不超过32个字符
- 自定义参数值:长度需在1024个字符以内
- 自定义参数个数:需在64个以内

### 执行约束
- addWatcher接口涉及I/O操作,建议根据性能需求选择主线程或子线程调用
- 如果在子线程调用addWatcher,需确保子线程在整个接口使用周期内不会被销毁
- 系统捕获维测日志耗时30s-2min,建议进程启动后延时重试获取冻屏事件
- 最大事件订阅观察者数量受系统限制(详见HiAppEvent约束与限制)

### 内容约束
- 禁止在回调函数中执行移除观察者操作
- 禁止订阅与系统事件冲突的自定义事件名称
- 禁止使用高危函数(eval、exec等)
- 回调函数中避免执行耗时操作

### 降级约束
- 网络失败:使用本地缓存日志文件路径
- 订阅失败:检查参数规格并重新订阅
- 回调数据缺失:延时重试调用takeNext()获取事件
- 日志文件过大:系统自动清理旧日志文件

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查API版本:确保设备API version >= 11(hiAppEvent首批接口从API version 9开始支持,APP_FREEZE事件从API version 11开始支持)
2. 检查设备类型:确认设备支持HiAppEvent功能
3. 检查权限配置:确保应用已配置必要的权限(元服务API从API version 11开始支持)

**参数准备**:
```typescript
// 导入依赖模块
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';

// 定义观察者名称(需符合命名规范)
const watcherName: string = "freezeWatcher";

// 定义事件自定义参数
let params: Record<string, hiAppEvent.ParamType> = {
  "test_data": 100,
  "custom_key": "custom_value",
};
```

### 步骤2:设置事件自定义参数

**示例代码**:
```typescript
// 设置应用冻屏事件的自定义参数
hiAppEvent.setEventParam(params, hiAppEvent.domain.OS, hiAppEvent.event.APP_FREEZE).then(() => {
  hilog.info(0x0000, 'testTag', `HiAppEvent success to set event param`);
}).catch((err: BusinessError) => {
  hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
});

// API version 24及以后版本,支持设置页面切换日志
if (deviceInfo.sdkApiVersion >= 24) {
  // 配置页面切换日志
  let switchLogPolicy: hiAppEvent.EventPolicy = {
    "appFreezePolicy": {
      "pageSwitchLogEnable": true
    }
  };
  
  // 设置应用冻屏日志配置参数
  hiAppEvent.configEventPolicy(switchLogPolicy).then(() => {
    hilog.info(0x0000, 'testTag', `HiAppEvent success to config event policy.`);
  }).catch((err: BusinessError) => {
    hilog.error(0x0000, 'testTag', `HiAppEvent code: ${err.code}, message: ${err.message}`);
  });
}
```

### 步骤3:添加事件观察者

**示例代码**:
```typescript
// 添加应用冻屏事件观察者
hiAppEvent.addWatcher({
  // 开发者可以自定义观察者名称,系统会使用名称来标识不同的观察者
  name: watcherName,
  // 订阅感兴趣的系统事件,此处是订阅了应用冻屏事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  // 开发者可以自行实现订阅实时回调函数,以便对订阅获取到的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      // 开发者可以根据事件集合中的事件名称区分不同的系统事件
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 处理冻屏事件数据
        processFreezeEvent(eventInfo);
      }
    }
  }
});

// 处理冻屏事件的函数
function processFreezeEvent(eventInfo: hiAppEvent.AppEventInfo) {
  // 获取冻屏事件的基本信息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
  
  // 获取冻屏事件发生的时间戳
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
  
  // 获取冻屏事件发生时应用的前后台状态
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.foreground=${eventInfo.params['foreground']}`);
  
  // 获取冻屏事件发生时应用的唯一关联id
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.app_running_unique_id=${eventInfo.params['app_running_unique_id']}`);
  
  // 获取冻屏事件发生时应用的版本信息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
  
  // 获取冻屏事件发生时应用的包名
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
  
  // 获取冻屏事件发生时应用的进程名称
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.process_name=${eventInfo.params['process_name']}`);
  
  // 获取冻屏事件发生时应用的进程id
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
  
  // 获取冻屏事件发生时应用的uid
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
  
  // 获取冻屏事件发生时应用的uuid
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uuid=${eventInfo.params['uuid']}`);
  
  // 获取冻屏事件发生的异常类型、异常原因
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.exception=${JSON.stringify(eventInfo.params['exception'])}`);
  
  // 获取冻屏事件发生时日志信息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.hilog.size=${eventInfo.params['hilog'].length}`);
  
  // 获取冻屏事件发生时主线程未处理消息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler.size=${eventInfo.params['event_handler'].length}`);
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler_size_3s=${eventInfo.params['event_handler_size_3s']}`);
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler_size_6s=${eventInfo.params['event_handler_size_6s']}`);
  
  // 获取冻屏事件发生时同步binder调用信息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.peer_binder.size=${eventInfo.params['peer_binder'].length}`);
  
  // 获取冻屏事件发生时全量线程调用栈
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.threads.size=${eventInfo.params['threads'].length}`);
  
  // 获取冻屏事件发生时内存信息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.memory=${JSON.stringify(eventInfo.params['memory'])}`);
  
  // 获取冻屏事件发生时的故障日志文件
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.log_over_limit=${eventInfo.params['log_over_limit']}`);
  
  // 获取冻屏事件的自定义数据
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.test_data=${eventInfo.params['test_data']}`);
  
  // 获取冻屏事件的故障进程存活时间
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.process_life_time=${eventInfo.params['process_life_time']}`);
  
  // 获取冻屏事件的回调日志信息
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_callback_log=${eventInfo.params['external_callback_log']}`);
  
  // 获取冻屏事件的页面切换日志
  hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.page_switch_log=${JSON.stringify(eventInfo.params['page_switch_log'])}`);
}
```

### 步骤4:错误处理

```typescript
// 错误处理代码
try {
  // 尝试添加观察者
  hiAppEvent.addWatcher({
    name: watcherName,
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_FREEZE]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 处理事件回调
    }
  });
} catch (error) {
  const err = error as BusinessError;
  switch (err.code) {
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types.');
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', 'Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid.');
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', 'Invalid filtering event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid.');
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: code=${err.code}, message=${err.message}`);
  }
}
```

### 步骤5:移除观察者(可选)

```typescript
// 移除应用冻屏事件观察者
let watcher: hiAppEvent.Watcher = {
  name: watcherName,
};

hiAppEvent.removeWatcher(watcher);
```

### 步骤6:触发冻屏事件(测试场景)

```typescript
// 仅用于测试,构造应用冻屏场景
Button("triggerFreeze").onClick(()=>{
  // 在按钮点击函数中构造一个freeze场景,触发应用冻屏事件
  setTimeout(() => {
    let t = Date.now();
    while (Date.now() - t <= 15000) {}
  }, 5000);
})
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. 参数错误。可能的错误原因:1.必填参数未指定;2.参数类型错误。 | 检查参数是否完整且类型正确,确保观察者名称、事件领域、事件名称符合命名规范 |
| 11102001 | Invalid watcher name. 观察者名称无效。可能的错误原因:1.包含无效字符;2.长度无效。 | 确保观察者名称首字符为字母字符,中间字符为数字字符、字母字符或下划线字符,结尾字符为数字字符或字母字符,长度不超过32个字符 |
| 11102002 | Invalid filtering event domain. 事件领域无效。可能的错误原因:1.包含无效字符;2.长度无效。 | 使用hiAppEvent.domain.OS作为系统事件领域 |
| 11100001 | Function disabled. 功能被禁用。可能是ConfigOption中的disable参数设置为true。 | 检查hiAppEvent.configure配置,确保disable参数为false |
| 11101001 | Invalid event domain. 事件领域无效。可能的错误原因:1.包含无效字符;2.长度无效。 | 检查事件领域参数是否符合规范 |
| 11101002 | Invalid event name. 事件名称无效。可能的错误原因:1.包含无效字符;2.长度无效。 | 使用hiAppEvent.event.APP_FREEZE作为应用冻屏事件名称 |
| 11101004 | Invalid string length of the event parameter. 事件参数字符串长度无效。 | 确保自定义参数值长度不超过1024个字符 |
| 11101005 | Invalid event parameter name. 事件参数名称无效。可能的错误原因:1.包含无效字符;2.长度无效。 | 确保参数名首字符为字母字符或$字符,中间字符为数字字符、字母字符或下划线字符,结尾字符为数字字符或字母字符,长度不超过32个字符 |
| 11101007 | The number of parameter keys exceeds the limit. 参数数量超过限制。 | 确保自定义参数个数不超过64个 |

## 编译和修复问题

### 依赖声明

**在entry模块的oh-package.json5中添加依赖**:
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "latest",
    "@kit.BasicServicesKit": "latest"
  }
}
```

**导入模块**:
```typescript
import { BusinessError, deviceInfo } from '@kit.BasicServicesKit';
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 环境要求
- HarmonyOS SDK: API version 11及以上(APP_FREEZE事件从API version 11开始支持)
- DevEco Studio: 3.1及以上版本
- 设备类型:支持HarmonyOS的手机、平板等设备

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit' or its corresponding type declarations.
```
**解决方法**:在oh-package.json5中添加正确的依赖声明,并执行ohpm install

**问题2:API不存在错误**
```
Error: Property 'APP_FREEZE' does not exist on type 'typeof hiAppEvent.event'.
```
**解决方法**:确保API version >= 11,在build-profile.json5中配置正确的compileSdkVersion

**问题3:参数类型错误**
```
Error: Type 'string' is not assignable to type 'ParamType'.
```
**解决方法**:确保自定义参数值类型为number、string、boolean或Array<string>之一

**问题4:观察者名称格式错误**
```
Error: Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid.
```
**解决方法**:检查观察者名称格式,确保首字符为字母字符,不包含特殊字符,长度不超过32个字符

## 常见问题与解决方法

### Q1:订阅成功但未收到冻屏事件回调
**原因**:系统捕获维测日志有一定耗时,典型情况下30s内完成,极端情况下2min左右完成。应用可能未真正发生冻屏事件。
**解决方法**:
- 确认应用确实发生了主线程连续6秒无响应的场景
- 检查onReceive回调函数是否正确实现
- 确认观察者名称是否唯一且未被覆盖
- 延时重试获取事件(针对手动处理订阅事件的方法)

### Q2:如何区分不同的冻屏事件类型
**原因**:冻屏事件参数中的exception字段包含name子字段,用于区分具体的冻屏类型。
**解决方法**:
- 从eventInfo.params['exception']中获取exception对象
- 解析exception.name字段获取冻屏类型(如THREAD_BLOCK_6S)
- 根据不同类型进行不同的处理

### Q3:如何获取完整的故障日志
**原因**:external_log字段包含故障日志文件在应用沙箱中的路径。
**解决方法**:
- 从eventInfo.params['external_log']获取日志文件路径数组
- 访问沙箱路径/data/storage/el2/log/hiappevent/下的日志文件
- 使用文件读取API获取完整日志内容

### Q4:页面切换日志未生效
**原因**:页面切换日志配置需要API version >= 24。
**解决方法**:
- 检查设备API版本是否 >= 24
- 在调用configEventPolicy前先检查deviceInfo.sdkApiVersion
- 确保appFreezePolicy.pageSwitchLogEnable设置为true

### Q5:如何从FaultLogger接口迁移到HiAppEvent
**原因**:FaultLogger接口从API version 18开始废弃使用。
**解决方法**:
- 使用hiAppEvent.addWatcher替代FaultLogger.query
- 订阅hiAppEvent.event.APP_FREEZE替代FaultType.APP_FREEZE
- 从AppEventInfo.params中获取对应字段信息(详见迁移文档中的字段对应关系表)

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "watcherName": "freezeWatcher",
  "eventType": "APP_FREEZE",
  "eventReceived": true,
  "eventParams": {
    "time": 1711440881768,
    "foreground": true,
    "bundle_name": "com.example.myapplication",
    "pid": 3197,
    "exception": {
      "name": "THREAD_BLOCK_6S",
      "message": "App main thread is not response!"
    },
    "external_log": [
      "/data/storage/el2/log/hiappevent/APP_FREEZE_1711440899240_3197.log"
    ]
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.setEventParam",
    "hiAppEvent.configEventPolicy",
    "hiAppEvent.removeWatcher"
  ]
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-freeze-events-arkts.md)
- [API参考说明](references/js-apis-hiviewdfx-hiappevent.md)
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
- [FaultLogger迁移指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-faultlogger)

## 完整示例代码

- [ArkTS示例](assets/example_freeze_watcher.ets)
- [完整应用工程](https://gitcode.com/HarmonyOS_Samples/exception-handling)

## 测试用例

### 正向测试用例
- [测试订阅应用冻屏事件](tests/test_positive.ts):验证正常订阅和接收冻屏事件
- [测试自定义参数设置](tests/test_positive.ts):验证自定义参数成功设置
- [测试页面切换日志配置](tests/test_positive.ts):验证页面切换日志配置生效(API version >= 24)

### 边界测试用例
- [测试观察者名称长度边界](tests/test_boundary.ts):验证观察者名称长度32字符边界值
- [测试自定义参数数量边界](tests/test_boundary.ts):验证自定义参数64个边界值
- [测试参数值长度边界](tests/test_boundary.ts):验证参数值长度1024字符边界值

### 异常测试用例
- [测试观察者名称格式错误](tests/test_exception.ts):验证无效字符和长度错误处理
- [测试事件领域错误](tests/test_exception.ts):验证错误事件领域错误处理
- [测试参数类型错误](tests/test_exception.ts):验证错误参数类型错误处理