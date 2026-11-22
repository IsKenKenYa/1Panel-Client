---
name: hmos-hiappevent-appfreeze-warning
description: 订阅应用冻屏告警事件+实时回调监听冻屏数据+仅支持HarmonyOS应用开发+适用于性能监控、异常诊断、调试优化场景
---

# 订阅应用冻屏告警事件技能

## 功能描述

使用HiAppEvent提供的ArkTS接口订阅应用冻屏告警事件(APP_FREEZE),通过实时回调onReceive监听事件数据,获取冻屏发生时的详细信息包括时间戳、前后台状态、异常类型、调用栈、内存信息等,用于应用性能监控和异常诊断。

## 使用场景

### 触发词
- "订阅应用冻屏告警事件"
- "监听应用冻屏"
- "应用冻屏事件订阅"
- "HiAppEvent冻屏告警"
- "APP_FREEZE事件"

### 能做
- 订阅应用冻屏告警事件(APP_FREEZE)
- 实时回调监听冻屏事件数据
- 获取冻屏发生时的时间戳、前后台状态
- 获取冻屏发生时的异常类型、异常原因
- 获取冻屏发生时的调用栈信息
- 获取冻屏发生时的内存信息
- 自定义处理冻屏事件数据
- 移除观察者取消订阅

### 绝不做
- 不处理其他系统事件(如崩溃事件APP_CRASH)
- 不订阅应用自定义事件
- 不修改或过滤系统事件数据
- 不在回调函数中移除观察者(会导致回调失效)

### 补充
- 应用冻屏告警事件由系统自动检测,主线程阻塞超过阈值时触发
- 事件数据包含完整的调试信息,可用于问题定位
- 订阅名称name必须唯一,相同name会覆盖之前的订阅
- 回调函数建议避免耗时操作,以免影响性能
- 需导入@kit.PerformanceAnalysisKit模块

## 调用规范和规则

### 输入约束
- 观察者名称:首字符必须字母,中间字符必须数字/字母/下划线,结尾字符必须数字/字母,长度不超过32字符
- 事件领域:必须使用hiAppEvent.domain.OS系统领域
- 事件名称:必须使用hiAppEvent.event.APP_FREEZE冻屏事件常量
- 回调函数:onReceive回调函数参数类型必须匹配(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>)

### 执行约束
- 最大耗时:回调函数建议不超过100ms,避免阻塞主线程
- API调用频次:无限制,但订阅名称唯一,相同name会覆盖
- 订阅时机:建议在应用启动时(onCreate)添加观察者
- 移除时机:建议在应用退出时移除观察者,避免内存泄漏

### 内容约束
- 禁止在回调函数中执行removeWatcher操作(会导致回调失效)
- 禁止订阅其他系统事件名称(如APP_CRASH等)
- 禁止修改系统事件数据结构
- 禁止使用高危函数(如eval、exec等)
- 禁止在回调中进行耗时IO操作

### 降级约束
- 订阅失败:检查参数规格,修正后重新订阅
- 回调未触发:检查冻屏事件是否发生,可手动触发测试
- 事件数据为空:等待系统捕获完成,典型30s内,极端2min
- 参数错误:根据错误码修正参数,重新订阅

## 调用流程和步骤

### 步骤1:导入依赖模块

**前置校验**:
1. 确认使用ArkTS语言开发HarmonyOS应用
2. 确认工程已配置@kit.PerformanceAnalysisKit依赖
3. 确认API version >= 11(支持元服务API)

**参数准备**:
```typescript
// 导入HiAppEvent和HiLog模块
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤2:添加事件观察者订阅冻屏告警事件

**示例代码**:
```typescript
// 在EntryAbility.ets的onCreate函数中添加订阅
hiAppEvent.addWatcher({
  // 开发者自定义观察者名称,系统使用名称标识不同观察者
  name: "watcher",
  // 订阅感兴趣的系统事件,此处订阅应用冻屏告警事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  // 开发者自行实现订阅实时回调函数,对事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      // 根据事件集合中的事件名称区分不同系统事件
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 对事件数据进行自定义处理,此处将事件数据打印在日志中
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
        // 获取冻屏告警事件发生的时间戳
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
        // 获取冻屏告警事件发生时应用的前台/后台状态
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.foreground=${eventInfo.params['foreground']}`);
        // 获取冻屏告警事件发生时应用的唯一关联id
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.app_running_unique_id=${eventInfo.params['app_running_unique_id']}`);
        // 获取冻屏告警事件发生时应用的版本信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version_code=${eventInfo.params['bundle_version_code']}`);
        // 获取冻屏告警事件发生时应用的包名
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_name=${eventInfo.params['bundle_name']}`);
        // 获取冻屏告警事件发生时应用的进程名称
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.process_name=${eventInfo.params['process_name']}`);
        // 获取冻屏告警事件发生时应用的进程id
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
        // 获取冻屏告警事件发生的异常类型、异常原因
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.exception=${JSON.stringify(eventInfo.params['exception'])}`);
        // 获取冻屏告警事件发生时日志信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.hilog.size=${eventInfo.params['hilog'].length}`);
        // 获取冻屏告警事件发生时主线程未处理消息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.event_handler.size=${eventInfo.params['event_handler'].length}`);
        // 获取冻屏告警事件发生时同步binder调用信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.peer_binder.size=${eventInfo.params['peer_binder'].length}`);
        // 获取冻屏告警事件发生时全量线程调用栈
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.threads.size=${eventInfo.params['threads'].length}`);
        // 获取冻屏告警事件发生时内存信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.memory=${JSON.stringify(eventInfo.params['memory'])}`);
        // 获取冻屏告警事件的故障进程存活时间
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.process_life_time=${eventInfo.params['process_life_time']}`);
      }
    }
  }
});
```

### 步骤3:触发冻屏告警事件进行测试

**示例代码**:
```typescript
// 在Index.ets中新增按钮触发冻屏告警事件
@Entry
@Component
struct Index {
  build() {
    RelativeContainer() {
      Column() {
        Button("appFreezeWarning", { stateEffect: true, type: ButtonType.Capsule })
          .width('75%')
          .height(50)
          .margin(15)
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .onClick(() => {
            // 在按钮点击函数中构造appFreezeWarning场景,触发应用冻屏告警事件
            const t = Date.now();
            while (Date.now() - t <= 6500) {}
          })
      }.width('100%')
    }
    .height('100%')
    .width('100%')
  }
}
```

### 步骤4:错误处理

```typescript
// 错误处理代码
try {
  hiAppEvent.addWatcher({
    name: "watcher",
    appEventFilters: [
      {
        domain: hiAppEvent.domain.OS,
        names: [hiAppEvent.event.APP_FREEZE]
      }
    ],
    onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
      // 处理事件数据
      hilog.info(0x0000, 'testTag', `Received freeze event`);
    }
  });
} catch (error) {
  switch (error.code) {
    case 401:
      hilog.error(0x0000, 'testTag', 'Parameter error. Check watcher name and filters.');
      break;
    case 11102001:
      hilog.error(0x0000, 'testTag', 'Invalid watcher name. Must start with letter, contain letters/numbers/underscores, end with letter/number, max 32 chars.');
      break;
    case 11102002:
      hilog.error(0x0000, 'testTag', 'Invalid filtering event domain. Use hiAppEvent.domain.OS.');
      break;
    default:
      hilog.error(0x0000, 'testTag', `Unknown error: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤5:移除观察者取消订阅

```typescript
// 移除观察者取消订阅
let watcher: hiAppEvent.Watcher = {
  name: "watcher",
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_FREEZE]
    }
  ],
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    // 处理事件数据
  }
};

// 添加观察者
hiAppEvent.addWatcher(watcher);

// 在需要取消订阅时移除观察者
hiAppEvent.removeWatcher(watcher);
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | Parameter error. Possible causes: 1. Mandatory parameters are left unspecified; 2. Incorrect parameter types. | 检查必填参数是否指定,检查参数类型是否正确 |
| 11102001 | Invalid watcher name. Possible causes: 1. Contain invalid characters; 2. Length is invalid. | 观察者名称首字符必须字母,中间字符必须数字/字母/下划线,结尾字符必须数字/字母,长度不超过32字符 |
| 11102002 | Invalid filtering event domain. Possible causes: 1. Contain invalid characters; 2. Length is invalid. | 事件领域必须使用hiAppEvent.domain.OS系统领域常量 |
| 11102003 | Invalid row value. Possible caused by the row value is less than zero. | triggerCondition.row必须为正整数 |
| 11102004 | Invalid size value. Possible caused by the size value is less than zero. | triggerCondition.size必须为正整数 |
| 11102005 | Invalid timeout value. Possible caused by the timeout value is less than zero. | triggerCondition.timeOut必须为正整数 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "API version >= 11"
  }
}
```

### 环境要求
- HarmonyOS API version: >= 11(支持元服务API)
- 开发语言: ArkTS
- 开发工具: DevEco Studio

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.PerformanceAnalysisKit'
```
**解决方法**: 确认DevEco Studio已安装HarmonyOS SDK,检查API version配置

**问题2:订阅失败返回null**
```
AppEventPackageHolder is null
```
**解决方法**: 检查观察者名称、事件领域、事件名称是否符合规格,参考错误码说明修正参数

**问题3:回调函数未触发**
```
No callback received after freeze event
```
**解决方法**: 
- 确认冻屏事件是否发生(主线程阻塞超过阈值)
- 等待系统捕获完成(典型30s内,极端2min)
- 检查回调函数参数类型是否匹配

**问题4:参数类型错误**
```
Type 'string' is not assignable to type 'hiAppEvent.domain'
```
**解决方法**: 使用hiAppEvent.domain.OS常量而非字符串,使用hiAppEvent.event.APP_FREEZE常量而非字符串

## 常见问题与解决方法

### Q1:订阅后未收到冻屏事件回调
**原因**: 
- 冻屏事件未发生(主线程阻塞未超过阈值)
- 系统捕获事件耗时(典型30s,极端2min)
- 观察者名称重复被覆盖

**解决方法**:
- 使用测试代码主动触发冻屏(主线程阻塞6.5秒)
- 等待系统捕获完成后再检查回调
- 确认观察者名称唯一,避免重复订阅

### Q2:回调函数中获取事件数据失败
**原因**: 
- 事件数据字段名称错误
- 事件数据结构不匹配
- JSON序列化失败

**解决方法**:
- 使用正确的字段名称(参考API文档中的params字段列表)
- 检查eventInfo.params对象结构
- 使用JSON.stringify()序列化复杂对象

### Q3:移除观察者后回调仍触发
**原因**: 
- 移除操作在回调函数中执行(不建议)
- 移除的观察者对象不匹配

**解决方法**:
- 不在回调函数中执行removeWatcher操作
- 移除时使用添加时的同一个watcher对象
- 在应用退出时移除观察者

### Q4:订阅参数验证失败
**原因**: 
- 观察者名称包含非法字符
- 事件领域未使用系统常量
- 事件名称未使用系统常量

**解决方法**:
- 观察者名称符合规格:首字母,中间数字/字母/下划线,结尾数字/字母,最长32字符
- 使用hiAppEvent.domain.OS系统领域常量
- 使用hiAppEvent.event.APP_FREEZE冻屏事件常量

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "订阅成功",
  "watcherName": "自定义观察者名称",
  "eventDomain": "OS",
  "eventName": "APP_FREEZE",
  "callbackType": "onReceive实时回调",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.event.APP_FREEZE",
    "hiAppEvent.domain.OS"
  ],
  "eventDataFields": [
    "time",
    "foreground",
    "app_running_unique_id",
    "bundle_version",
    "bundle_version_code",
    "bundle_name",
    "process_name",
    "pid",
    "uid",
    "exception",
    "hilog",
    "event_handler",
    "peer_binder",
    "threads",
    "memory",
    "process_life_time"
  ]
}
```

## 参考文档

- [API开发指南:订阅应用冻屏告警事件(ArkTS)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-appfreezewarning-events-arkts)
- [API参考说明:@ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)

## 完整示例代码

- [ArkTS完整示例:EntryAbility订阅冻屏事件](assets/entry_ability_example.ets)
- [ArkTS完整示例:Index触发冻屏事件](assets/index_example.ets)
- [配置文件示例:module.json5依赖声明](assets/module.json5)

## 测试用例

### 正向测试用例
- [订阅冻屏事件成功](tests/test_positive.ets):使用正确参数订阅冻屏事件,验证回调触发
- [获取完整事件数据](tests/test_positive.ets):验证事件数据字段完整性,获取所有冻屏信息
- [移除观察者成功](tests/test_positive.ets):验证移除观察者后不再触发回调

### 边界测试用例
- [观察者名称边界值](tests/test_boundary.ets):测试观察者名称长度32字符边界
- [主线程阻塞阈值](tests/test_boundary.ets):测试主线程阻塞6秒触发冻屏事件
- [事件数据数组边界](tests/test_boundary.ets):验证hilog、threads等数组数据长度

### 异常测试用例
- [参数类型错误](tests/test_exception.ets):测试观察者名称包含非法字符,验证错误码11102001
- [事件领域错误](tests/test_exception.ets):测试使用非系统领域,验证错误码11102002
- [订阅其他事件](tests/test_exception.ets):测试订阅崩溃事件APP_CRASH,验证不触发冻屏回调