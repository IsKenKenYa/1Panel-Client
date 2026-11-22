---
name: hmos-hiappevent-watcher-apphicollie-events
description: 订阅任务执行超时事件能力，支持APP_HICOLLIE系统事件实时监听，API version 21+，适用于性能调测、故障诊断、线程阻塞检测场景
---

# 订阅任务执行超时事件技能

## 功能描述

本技能提供使用HiAppEvent接口订阅任务执行超时事件（APP_HICOLLIE）的完整实现方案。通过添加事件观察者（Watcher）实时监听系统生成的任务执行超时事件，获取事件详情包括超时时间、进程信息、内存状态、异常堆栈等关键维测数据，帮助开发者快速定位和解决性能瓶颈问题。

**核心能力**：
- 实时订阅系统任务执行超时事件
- 获取完整的超时事件参数信息
- 支持自定义事件回调处理逻辑
- 支持Native层触发超时事件注入

**适用范围**：
- HarmonyOS API version 21及以上
- 支持ArkTS语言开发
- 仅适用于系统事件订阅（APP_HICOLLIE）

## 使用场景

### 触发词
- "订阅任务执行超时事件"
- "监听线程阻塞事件"
- "HiCollie事件订阅"
- "APP_HICOLLIE事件"
- "任务超时检测"
- "性能超时事件监听"

### 能做
- 实时订阅并接收任务执行超时事件（APP_HICOLLIE）
- 获取超时事件的完整参数信息（时间、进程、内存、堆栈等）
- 自定义事件回调处理逻辑（日志记录、数据上报等）
- 移除事件观察者取消订阅
- 在开发阶段通过Native代码触发超时事件进行测试

### 绝不做
- 不订阅其他类型的系统事件（如崩溃事件APP_CRASH）
- 不处理应用自定义事件（仅处理系统事件）
- 不在回调函数中移除观察者（会导致回调失效）
- 不在已销毁的子线程中调用addWatcher

### 补充
- 需配合Native C++工程使用，在ArkTS层订阅，C++层构造故障注入
- 观察者名称必须唯一，重复名称会覆盖前一次订阅
- API涉及I/O操作，建议根据性能需求选择调用线程
- APP_HICOLLIE事件参数包含丰富的维测信息，建议完整记录所有字段

## 调用规范和规则

### 输入约束
- 观察者名称：首字符必须为字母，中间字符可为数字/字母/下划线，结尾字符必须为数字或字母，长度1-32字符
- 事件领域：必须使用`hiAppEvent.domain.OS`（系统事件领域）
- 事件名称：必须为`hiAppEvent.event.APP_HICOLLIE`
- 回调函数参数：domain为string，appEventGroups为Array<hiAppEvent.AppEventGroup>
- 无文件、数量、大小限制

### 执行约束
- addWatcher接口执行时间：毫秒级别（I/O操作）
- 最大订阅观察者数量：无明确限制（建议不超过10个）
- API调用频次：无明确限制
- 回调函数执行：实时触发，建议避免耗时操作

### 内容约束
- 禁止生成：虚假的API接口、错误的参数类型、不存在的错误码
- 禁止使用高危函数：eval、exec、系统命令执行
- 禁止操作：在回调中移除观察者、在销毁线程中调用API
- 必须校验：参数类型、事件领域、事件名称

### 降级约束
- API调用失败：捕获错误码，记录日志，提示用户检查参数
- 订阅失败：holder返回null，提示观察者添加失败
- 回调未触发：检查事件是否发生、观察者是否有效
- Native层故障注入失败：检查C++代码配置和依赖库

## 调用流程和步骤

### 步骤1：创建Native C++工程

**前置校验**：
1. 检查DevEco Studio环境是否安装
2. 检查HarmonyOS SDK版本是否支持API 21+
3. 检查工程模板是否为Native C++类型

**工程结构准备**：
```
entry:
  src:
    main:
      cpp:
        types:
          libentry:
            - index.d.ts
        - CMakeLists.txt
        - napi_init.cpp
      ets:
        entryability:
          - EntryAbility.ets
        pages:
          - Index.ets
```

### 步骤2：配置CMake依赖

编辑"CMakeLists.txt"文件，添加必要的动态库依赖：

```cmake
# 添加动态库依赖
target_link_libraries(entry PUBLIC libace_napi.z.so libhilog_ndk.z.so libohhicollie.so)
```

**依赖说明**：
- `libace_napi.z.so`：NAPI基础库
- `libhilog_ndk.z.so`：日志输出库
- `libohhicollie.so`：HiCollie检测库（用于故障注入）

### 步骤3：导入依赖模块

编辑"EntryAbility.ets"文件，导入必要的模块：

```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

### 步骤4：订阅任务执行超时事件

编辑"EntryAbility.ets"文件，在onCreate函数中添加订阅代码：

```typescript
let watcher: hiAppEvent.Watcher = {
  // 开发者自定义观察者名称，系统使用名称标识不同观察者
  name: "watcher",
  // 订阅感兴趣的系统事件，此处订阅任务执行超时事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,
      names: [hiAppEvent.event.APP_HICOLLIE]
    }
  ],
  // 实现订阅实时回调函数，对订阅获取的事件数据进行自定义处理
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      for (const eventInfo of eventGroup.appEventInfos) {
        // 记录事件基本信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.eventType=${eventInfo.eventType}`);
        
        // 记录事件参数详细信息
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.time=${eventInfo.params['time']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.foreground=${eventInfo.params['foreground']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.bundle_version=${eventInfo.params['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.process_name=${eventInfo.params['process_name']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.pid=${eventInfo.params['pid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uid=${eventInfo.params['uid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.uuid=${eventInfo.params['uuid']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.exception=${eventInfo.params['exception']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.hilog.size=${eventInfo.params['hilog'].length}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.peer_binder.size=${JSON.stringify(eventInfo.params['peer_binder'].length)}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.memory=${eventInfo.params['memory']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_log=${JSON.stringify(eventInfo.params['external_log'])}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.log_over_limit=${eventInfo.params['log_over_limit']}`);
        hilog.info(0x0000, 'testTag', `HiAppEvent eventInfo.params.external_callback_log=${eventInfo.params['external_callback_log']}`);
      }
    }
  }
};

// 添加观察者订阅事件
hiAppEvent.addWatcher(watcher);
```

**参数说明**：
- `name`：观察者唯一标识，建议使用有意义的名称
- `domain`：事件领域，系统事件固定为`hiAppEvent.domain.OS`
- `names`：事件名称数组，订阅APP_HICOLLIE事件
- `onReceive`：实时回调函数，事件发生后立即触发

### 步骤5：实现Native层故障注入

编辑"napi_init.cpp"文件，添加TestHiCollieTimerNdk函数用于构造超时事件：

```cpp
#include "napi/native_api.h"
#include "hicollie/hicollie.h"
#include "hilog/log.h"
#include <unistd.h>

#undef LOG_TAG
#define LOG_TAG "testTag"

static napi_value TestHiCollieTimerNdk(napi_env env, napi_callback_info exports)
{
    // 定义执行任务超时id值
    int id;
    
    // 定义任务超时检测参数：超时时间阈值1s，动作级别为生成日志
    HiCollie_SetTimerParam param = {"testTimer", 1, nullptr, nullptr, HiCollie_Flag::HICOLLIE_FLAG_LOG};
    
    // 设置检测
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &id);
    
    if (errorCode == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Timer Id is %{public}d", id);
        
        // 构造超时2s（超过阈值1s，触发超时事件）
        sleep(2);
        
        // 取消定时器
        OH_HiCollie_CancelTimer(id);
    }
    
    return nullptr;
}
```

### 步骤6：注册Native接口

编辑"napi_init.cpp"文件，将TestHiCollieTimerNdk注册为ArkTS接口：

```cpp
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "TestHiCollieTimerNdk", nullptr, TestHiCollieTimerNdk, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void*)0),
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void)
{
    napi_module_register(&demoModule);
}
```

编辑"index.d.ts"文件，定义ArkTS接口类型：

```typescript
export const TestHiCollieTimerNdk: () => void;
```

### 步骤7：触发超时事件

编辑"Index.ets"文件，添加按钮触发测试：

```typescript
import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
  @State message: string = 'Hello World';
  
  build() {
    Row() {
      Column() {
        Button("TestHiCollieTimerNdk")
          .fontSize(50)
          .fontWeight(FontWeight.Bold)
          .onClick(testNapi.TestHiCollieTimerNdk)
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

### 步骤8：验证事件订阅结果

运行应用工程，点击按钮触发超时事件，在Log窗口查看订阅的事件数据：

```
HiAppEvent eventInfo.domain=OS
HiAppEvent eventInfo.name=APP_HICOLLIE
HiAppEvent eventInfo.eventType=1
HiAppEvent eventInfo.params.time=1754914806680
HiAppEvent eventInfo.params.foreground=true
HiAppEvent eventInfo.params.bundle_version=1.0.0
HiAppEvent eventInfo.params.process_name=com.example.myapplication
HiAppEvent eventInfo.params.pid=20317
HiAppEvent eventInfo.params.uid=20020198
HiAppEvent eventInfo.params.uuid=4asd360e18f5d6d84cf4f0c9e80d66we5786c1cc2343d9632e07abb0d3552asd
HiAppEvent eventInfo.params.exception={"message":"","name":"APP_HICOLLIE"}
HiAppEvent eventInfo.params.hilog.size=28
HiAppEvent eventInfo.params.peer_binder.size=0
HiAppEvent eventInfo.params.memory={"pss":0,"rss":150748,"sys_avail_mem":5387264,"sys_free_mem":218902,"sys_total_mem":11679236,"vss":38306936}
HiAppEvent eventInfo.params.external_log=["/data/storage/el2/log/hiappevent/APP_HICOLLIE_1754914811140_20317.log"]
HiAppEvent eventInfo.params.log_over_limit=false
HiAppEvent eventInfo.params.external_callback_log=THREAD_BLOCK_3S:log3s THREAD_BLOCK_6S:log6s
```

### 步骤9：移除事件观察者

取消订阅时调用removeWatcher：

```typescript
// 移除应用事件观察者以取消订阅事件
hiAppEvent.removeWatcher(watcher);
```

**注意事项**：
- 移除观察者后，回调函数将不再触发
- 不建议在回调函数中执行移除操作

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定；2. 参数类型错误。 | 检查观察者参数是否完整，类型是否正确 |
| 11102001 | 观察者名称无效。可能原因：1. 包含无效字符；2. 长度无效。 | 检查名称格式，确保首字符为字母，长度1-32字符 |
| 11102002 | 事件领域过滤无效。可能原因：1. 包含无效字符；2. 长度无效。 | 使用正确的领域值hiAppEvent.domain.OS |
| 11102003 | row值无效。row值小于0。 | 检查triggerCondition.row参数值 |
| 11102004 | size值无效。size值小于0。 | 检查triggerCondition.size参数值 |
| 11102005 | timeout值无效。timeout值小于0。 | 检查triggerCondition.timeOut参数值 |

## 编译和修复问题

### 依赖声明

**ArkTS依赖**：
```json
{
  "dependencies": {
    "@kit.PerformanceAnalysisKit": "系统Kit，无需额外声明"
  }
}
```

**Native C++依赖**：
```cmake
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libohhicollie.so
)
```

### 环境要求
- HarmonyOS SDK：API version 21及以上
- DevEco Studio：最新版本
- Node.js：建议v14及以上（用于ArkTS编译）

### 常见编译问题

**问题1：找不到libohhicollie.so库**
```
error: cannot find -libohhicollie.so
```
**解决方法**：检查CMakeLists.txt中是否正确添加依赖，确保使用HarmonyOS SDK API 21+

**问题2：Native接口注册失败**
```
Uncaught SyntaxError: Cannot import value 'TestHiCollieTimerNdk'
```
**解决方法**：
- 检查index.d.ts文件是否定义接口
- 检查napi_init.cpp中Init函数是否正确注册
- 确保模块名称nm_modname与导入路径一致

**问题3：回调函数未触发**
```
无日志输出，订阅未生效
```
**解决方法**：
- 检查观察者名称是否唯一
- 检查事件领域和事件名称是否正确
- 检查Native层故障注入是否成功
- 确认应用进程是否发生超时

**问题4：API版本不支持**
```
Property 'APP_HICOLLIE' does not exist on type 'event'
```
**解决方法**：升级HarmonyOS SDK到API version 21及以上

## 常见问题与解决方法

### Q1：订阅后未收到事件回调
**原因**：
1. 事件未发生（线程未超时）
2. 观察者被覆盖或移除
3. 回调函数实现有误

**解决方法**：
- 使用Native层故障注入触发超时事件
- 确保观察者名称唯一且未被移除
- 检查回调函数参数类型和实现逻辑
- 使用hilog记录回调触发情况

### Q2：事件参数获取失败
**原因**：
1. params字段名称错误
2. 参数类型转换有误

**解决方法**：
- 参考API文档中APP_HICOLLIE事件的参数字段定义
- 使用正确的字段名称（time, foreground, pid, uid等）
- 注意某些参数为数组或对象类型，需使用JSON.stringify处理

### Q3：Native层故障注入失败
**原因**：
1. HiCollie库未正确依赖
2. 定时器参数配置错误
3. sleep时间未超过阈值

**解决方法**：
- 检查CMakeLists.txt是否添加libohhicollie.so依赖
- 确保HiCollie_SetTimerParam参数正确（名称、阈值、标志）
- 确保sleep时间超过设置的阈值（如阈值1s，sleep至少2s）

### Q4：移除观察者后订阅失效
**原因**：
- removeWatcher调用时机不当

**解决方法**：
- 在应用生命周期结束时移除观察者（如onDestroy）
- 避免在回调函数中移除观察者
- 确保移除的是正确的观察者对象

### Q5：多线程调用addWatcher异常
**原因**：
- 子线程在API使用周期内被销毁

**解决方法**：
- 确保子线程生命周期足够长
- 或在主线程调用addWatcher接口
- 参考Worker简介文档实现多线程调用

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "watcher",
  "eventDomain": "OS",
  "eventName": "APP_HICOLLIE",
  "subscriptionTime": "1754914806680",
  "eventParams": {
    "time": "1754914806680",
    "foreground": true,
    "bundle_version": "1.0.0",
    "process_name": "com.example.myapplication",
    "pid": 20317,
    "uid": 20020198,
    "uuid": "4asd360e18f5d6d84cf4f0c9e80d66we5786c1cc2343d9632e07abb0d3552asd",
    "exception": "{\"message\":\"\",\"name\":\"APP_HICOLLIE\"}",
    "hilog_size": 28,
    "peer_binder_size": 0,
    "memory": "{\"pss\":0,\"rss\":150748,\"sys_avail_mem\":5387264,\"sys_free_mem\":218902,\"sys_total_mem\":11679236,\"vss\":38306936}",
    "external_log": "[\"/data/storage/el2/log/hiappevent/APP_HICOLLIE_1754914811140_20317.log\"]",
    "log_over_limit": false,
    "external_callback_log": "THREAD_BLOCK_3S:log3s THREAD_BLOCK_6S:log6s"
  },
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.removeWatcher",
    "OH_HiCollie_SetTimer",
    "OH_HiCollie_CancelTimer"
  ]
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-apphicollie-events-arkts.md)
- [API参考说明](references/js-apis-hiviewdfx-hiappevent.md)
- [崩溃事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events)
- [应用冻屏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events)
- [资源泄漏事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events)
- [Worker简介](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/worker-introduction)

## 完整示例代码

- [ArkTS订阅示例](assets/example_subscribe.ets)
- [Native故障注入示例](assets/example_napi_init.cpp)
- [CMake配置示例](assets/example_CMakeLists.txt)
- [接口类型定义示例](assets/example_index.d.ts)
- [UI触发示例](assets/example_index_ui.ets)

## 测试用例

### 正向测试用例
- [正常订阅APP_HICOLLIE事件](tests/test_positive_subscribe.ts)：验证观察者添加成功，回调触发正常
- [完整获取事件参数](tests/test_positive_params.ts)：验证所有事件参数字段获取正确

### 边界测试用例
- [观察者名称边界值](tests/test_boundary_name.ts)：测试名称长度1和32字符
- [事件名称匹配](tests/test_boundary_eventname.ts)：测试仅订阅APP_HICOLLIE事件

### 异常测试用例
- [参数类型错误](tests/test_exception_param.ts)：验证错误码401处理
- [观察者名称无效](tests/test_exception_name.ts)：验证错误码11102001处理
- [移除未添加的观察者](tests/test_exception_remove.ts)：验证移除操作异常处理
- [Native故障注入失败](tests/test_exception_native.ts)：验证HiCollie库依赖缺失处理