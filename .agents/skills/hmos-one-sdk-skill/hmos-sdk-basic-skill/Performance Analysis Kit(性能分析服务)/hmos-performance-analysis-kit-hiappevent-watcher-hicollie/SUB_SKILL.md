---
name: hmos-performance-analysis-kit-hiappevent-watcher-hicollie
description: 订阅任务执行超时事件（APP_HICOLLIE），通过HiAppEvent ArkTS接口实现事件观察者的添加和移除，支持实时回调处理，需配合Native C++代码构造故障注入触发事件，适用于性能调优和故障诊断场景
---

# 订阅任务执行超时事件技能

## 功能描述

本技能提供订阅HarmonyOS系统事件中的任务执行超时事件（APP_HICOLLIE）的能力。通过HiAppEvent提供的ArkTS接口添加事件观察者，监听任务执行超时事件，并通过回调函数实时处理事件数据。支持配置事件过滤条件、自定义回调处理逻辑，适用于开发阶段的性能问题诊断和故障分析。

**核心能力**：
- 添加/移除事件观察者（addWatcher/removeWatcher）
- 配置事件过滤条件（domain、names）
- 实时回调处理事件数据（onReceive）
- 解析任务执行超时事件参数

**技术特点**：
- 需要Native C++工程配合构造故障注入
- 使用OH_HiCollie_SetTimer C API触发超时事件
- 支持API version 21及以上
- 涉及跨语言调用（ArkTS + C++）

## 使用场景

### 触发词
- "订阅任务执行超时事件"
- "监听APP_HICOLLIE事件"
- "HiAppEvent watcher hicollie"
- "任务超时检测"
- "HiCollie事件订阅"

### 能做
- 添加事件观察者订阅任务执行超时事件
- 配置事件过滤条件（指定domain和event name）
- 实现onReceive回调处理事件数据
- 解析事件参数（time、foreground、pid、uid、memory等）
- 移除事件观察者取消订阅
- 配合C++代码构造故障注入触发超时事件

### 绝不做
- 不订阅其他系统事件（如APP_CRASH、APP_FREEZE）
- 不处理应用自定义事件
- 不在回调函数中执行移除观察者操作
- 不替代HiCollie检测功能本身
- 不处理非任务执行超时相关的性能问题

### 补充
- 需要创建Native C++工程才能完整演示功能
- 事件回调中包含完整的系统维测日志信息
- 开发阶段建议使用故障注入方式触发事件进行测试
- 生产环境可通过实际超时场景触发事件
- 观察者名称必须唯一，相同名称会覆盖之前的订阅

## 调用规范和规则

### 输入约束
- **观察者名称**：首字符必须为字母字符，中间字符必须为数字字符、字母字符或下划线字符，结尾字符必须为数字字符或字母字符，长度非空且不超过32个字符
- **事件领域**：必须使用hiAppEvent.domain.OS（系统事件领域）
- **事件名称**：必须使用hiAppEvent.event.APP_HICOLLIE（任务执行超时事件）
- **回调函数**：必须实现onReceive回调函数，参数类型为(domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>)
- **工程类型**：必须创建Native C++工程，不能是纯ArkTS工程

### 执行约束
- **订阅时机**：建议在应用启动时（如EntryAbility.onCreate）添加观察者
- **回调处理**：回调函数中避免执行耗时操作，建议仅做日志记录和数据解析
- **取消订阅**：应用退出前移除观察者，避免内存泄漏
- **线程安全**：addWatcher接口涉及I/O操作，不建议在性能敏感场景的主线程调用
- **生命周期**：观察者在整个应用生命周期内有效，直到被移除

### 内容约束
- **禁止移除操作**：不要在onReceive回调中调用removeWatcher，会导致回调失效
- **禁止错误订阅**：不要订阅非APP_HICOLLIE事件到同一个观察者
- **禁止空回调**：必须实现完整的回调逻辑，不能留空
- **禁止高危函数**：C++代码中禁止使用无限循环、内存泄漏代码
- **禁止异常抛出**：回调函数中应捕获异常，不应向外抛出

### 降级约束
- **订阅失败**：检查观察者名称是否合法，检查API version是否>=21
- **回调未触发**：检查事件是否实际发生，检查Native代码是否正确触发
- **参数解析错误**：使用可选链操作符(?.)访问params字段，避免undefined错误
- **编译失败**：检查CMakeLists.txt配置，确保libohhicollie.so正确链接
- **运行时崩溃**：检查Native代码的线程安全和内存管理

## 调用流程和步骤

### 步骤1：创建Native C++工程

**前置校验**：
1. DevEco Studio版本支持Native C++模板
2. HarmonyOS SDK版本>=API 21
3. 开发环境配置完整（CMake、NDK）

**工程创建**：
```
选择模板：Native C++ Template
工程结构：
entry/
  src/main/
    cpp/
      types/libentry/
        index.d.ts
      CMakeLists.txt
      napi_init.cpp
    ets/
      entryability/
        EntryAbility.ets
      pages/
        Index.ets
```

### 步骤2：配置CMakeLists.txt

**添加依赖库**：
```cmake
# 新增动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so      # NAPI基础库
    libhilog_ndk.z.so     # 日志输出
    libohhicollie.so      # HiCollie检测库
)
```

**验证配置**：
- 检查库文件路径是否正确
- 检查库名称是否匹配（libohhicollie.so）
- 确保链接顺序正确

### 步骤3：导入依赖模块

**ArkTS代码**：
```typescript
import { hiAppEvent, hilog } from '@kit.PerformanceAnalysisKit';
```

**说明**：
- hiAppEvent：事件订阅API
- hilog：日志输出API
- PerformanceAnalysisKit：性能分析服务Kit

### 步骤4：添加事件观察者

**订阅代码示例**：
```typescript
let watcher: hiAppEvent.Watcher = {
  // 观察者名称（唯一标识）
  name: "watcher",
  
  // 事件过滤条件：订阅任务执行超时事件
  appEventFilters: [
    {
      domain: hiAppEvent.domain.OS,          // 系统事件领域
      names: [hiAppEvent.event.APP_HICOLLIE] // 任务执行超时事件
    }
  ],
  
  // 实时回调函数
  onReceive: (domain: string, appEventGroups: Array<hiAppEvent.AppEventGroup>) => {
    hilog.info(0x0000, 'testTag', `HiAppEvent onReceive: domain=${domain}`);
    
    for (const eventGroup of appEventGroups) {
      hilog.info(0x0000, 'testTag', `HiAppEvent eventName=${eventGroup.name}`);
      
      for (const eventInfo of eventGroup.appEventInfos) {
        // 解析事件基本信息
        hilog.info(0x0000, 'testTag', `domain=${eventInfo.domain}`);
        hilog.info(0x0000, 'testTag', `name=${eventInfo.name}`);
        hilog.info(0x0000, 'testTag', `eventType=${eventInfo.eventType}`);
        
        // 解析事件参数（可选链访问避免undefined）
        hilog.info(0x0000, 'testTag', `time=${eventInfo.params?.['time']}`);
        hilog.info(0x0000, 'testTag', `foreground=${eventInfo.params?.['foreground']}`);
        hilog.info(0x0000, 'testTag', `bundle_version=${eventInfo.params?.['bundle_version']}`);
        hilog.info(0x0000, 'testTag', `process_name=${eventInfo.params?.['process_name']}`);
        hilog.info(0x0000, 'testTag', `pid=${eventInfo.params?.['pid']}`);
        hilog.info(0x0000, 'testTag', `uid=${eventInfo.params?.['uid']}`);
        hilog.info(0x0000, 'testTag', `uuid=${eventInfo.params?.['uuid']}`);
        
        // 解析异常信息
        const exception = eventInfo.params?.['exception'];
        if (exception) {
          hilog.info(0x0000, 'testTag', `exception=${JSON.stringify(exception)}`);
        }
        
        // 解析系统维测日志
        const hilogData = eventInfo.params?.['hilog'];
        if (hilogData && Array.isArray(hilogData)) {
          hilog.info(0x0000, 'testTag', `hilog.size=${hilogData.length}`);
        }
        
        // 解析peer_binder信息
        const peerBinder = eventInfo.params?.['peer_binder'];
        if (peerBinder && Array.isArray(peerBinder)) {
          hilog.info(0x0000, 'testTag', `peer_binder.size=${peerBinder.length}`);
        }
        
        // 解析内存信息
        const memory = eventInfo.params?.['memory'];
        if (memory) {
          hilog.info(0x0000, 'testTag', `memory=${JSON.stringify(memory)}`);
        }
        
        // 解析外部日志路径
        const externalLog = eventInfo.params?.['external_log'];
        if (externalLog && Array.isArray(externalLog)) {
          hilog.info(0x0000, 'testTag', `external_log=${JSON.stringify(externalLog)}`);
        }
        
        // 解析日志超限标记
        hilog.info(0x0000, 'testTag', `log_over_limit=${eventInfo.params?.['log_over_limit']}`);
        
        // 解析外部回调日志
        const externalCallbackLog = eventInfo.params?.['external_callback_log'];
        if (externalCallbackLog) {
          hilog.info(0x0000, 'testTag', `external_callback_log=${externalCallbackLog}`);
        }
      }
    }
  }
};

// 添加观察者
hiAppEvent.addWatcher(watcher);
```

**参数说明**：
- `name`：观察者唯一标识，长度<=32字符，格式符合规范
- `domain`：固定为hiAppEvent.domain.OS
- `names`：固定为[hiAppEvent.event.APP_HICOLLIE]
- `onReceive`：回调函数，处理事件数据

### 步骤5：构造故障注入（C++代码）

**引入头文件**：
```cpp
#include "napi/native_api.h"
#include "hicollie/hicollie.h"
#include "hilog/log.h"
#include <unistd.h>

#undef LOG_TAG
#define LOG_TAG "testTag"
```

**实现测试函数**：
```cpp
static napi_value TestHiCollieTimerNdk(napi_env env, napi_callback_info exports)
{
    // 定义执行任务超时id值
    int id;
    
    // 定义任务超时检测参数
    HiCollie_SetTimerParam param = {
        "testTimer",                    // 定时器名称
        1,                              // 超时时间阈值（1秒）
        nullptr,                        // 回调函数（可选）
        nullptr,                        // 回调参数（可选）
        HiCollie_Flag::HICOLLIE_FLAG_LOG // 动作级别：生成日志
    };
    
    // 设置检测
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &id);
    
    if (errorCode == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Timer Id is %{public}d", id);
        
        // 构造超时2秒（超过阈值1秒）
        sleep(2);
        
        // 取消定时器（若未取消，触发超时事件）
        OH_HiCollie_CancelTimer(id);
    }
    
    return nullptr;
}
```

**说明**：
- `OH_HiCollie_SetTimer`：设置定时器，检测任务执行超时
- `param.timeout`：超时阈值，单位秒
- `param.flag`：超时动作，HICOLLIE_FLAG_LOG表示生成日志
- `sleep(2)`：模拟任务执行超时
- `OH_HiCollie_CancelTimer`：取消定时器

### 步骤6：注册ArkTS接口

**napi_init.cpp注册**：
```cpp
EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "TestHiCollieTimerNdk", nullptr, TestHiCollieTimerNdk, 
          nullptr, nullptr, nullptr, napi_default, nullptr }
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

**index.d.ts类型定义**：
```typescript
export const TestHiCollieTimerNdk: () => void;
```

### 步骤7：UI触发按钮

**Index.ets代码**：
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
          .onClick(testNapi.TestHiCollieTimerNdk);
      }
      .width('100%')
    }
    .height('100%')
  }
}
```

### 步骤8：运行验证

**验证步骤**：
1. DevEco Studio运行应用
2. 点击"TestHiCollieTimerNdk"按钮触发超时
3. 查看Log窗口输出事件回调日志
4. 验证事件参数完整性

**预期日志输出**：
```
HiAppEvent onReceive: domain=OS
HiAppEvent eventName=APP_HICOLLIE
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
HiAppEvent eventInfo.params.memory={"pss":0,"rss":150748,"sys_avail_mem":5387264,...}
HiAppEvent eventInfo.params.external_log=["/data/storage/el2/log/hiappevent/APP_HICOLLIE_1754914811140_20317.log"]
HiAppEvent eventInfo.params.log_over_limit=false
HiAppEvent eventInfo.params.external_callback_log=THREAD_BLOCK_3S:log3s THREAD_BLOCK_6S:log6s
```

### 步骤9：移除观察者（可选）

**取消订阅**：
```typescript
// 移除该应用事件观察者以取消订阅事件
hiAppEvent.removeWatcher(watcher);
```

**说明**：
- 应用退出前建议移除观察者
- 移除后回调函数不再触发
- 同名观察者可被覆盖，无需显式移除

## 错误码说明

### ArkTS API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定或类型错误 | 检查watcher参数是否完整且类型正确 |
| 11102001 | 无效的观察者名称：包含非法字符或长度无效 | 检查name是否符合命名规范（字母开头，<=32字符） |
| 11102002 | 无效的事件过滤领域：包含非法字符或长度无效 | 确保domain为hiAppEvent.domain.OS |
| 11102003 | 无效的row值：row值小于零 | 检查triggerCondition.row是否为正整数 |
| 11102004 | 无效的size值：size值小于零 | 检查triggerCondition.size是否为正整数 |
| 11102005 | 无效的timeout值：timeout值小于零 | 检查triggerCondition.timeOut是否为正整数 |

### C API错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| HICOLLIE_SUCCESS (0) | 成功 | 正常执行 |
| HICOLLIE_INVALID_ARGUMENT (401) | 无效参数 | 检查param参数是否完整 |
| HICOLLIE_WRONG_THREAD_CONTEXT (29800001) | 调用线程错误 | 在非主线程调用（本场景主线程可用） |
| HICOLLIE_REMOTE_FAILED (29800002) | 远程调用错误 | 检查IPC服务连接 |
| HICOLLIE_INVALID_TIMER_NAME (29800003) | 无效的定时器名称 | 检查param.name不为空字符串 |
| HICOLLIE_INVALID_TIMEOUT_VALUE (29800004) | 无效的超时时间阈值 | 检查param.timeout为正整数 |
| HICOLLIE_WRONG_PROCESS_CONTEXT (29800005) | 无效的进程上下文 | 不在appspawn/nativespawn进程调用 |
| HICOLLIE_WRONG_TIMER_ID_OUTPUT_PARAM (29800006) | 计时器ID指针为NULL | 检查id参数指针不为NULL |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

set(CMAKE_CXX_STANDARD 17)

# 添加源文件
add_library(entry SHARED
    napi_init.cpp
)

# 链接动态库
target_link_libraries(entry PUBLIC
    libace_napi.z.so      # NAPI接口库
    libhilog_ndk.z.so     # HiLog日志库
    libohhicollie.so      # HiCollie检测库（关键依赖）
)
```

**说明**：
- 必须链接libohhicollie.so
- 库文件在HarmonyOS SDK中提供
- API version >= 12支持

### 环境要求
- **DevEco Studio**：版本 >= 3.1
- **HarmonyOS SDK**：API version >= 21（HiAppEvent订阅支持）
- **CMake**：版本 >= 3.4.1
- **NDK**：HarmonyOS Native Development Kit

### 常见编译问题

**问题1：找不到libohhicollie.so**
```
error: cannot find -libohhicollie.so
```
**解决方法**：
- 检查HarmonyOS SDK版本是否>=API 12
- 检查SDK路径配置是否正确
- 更新SDK到最新版本

**问题2：头文件hicollie.h不存在**
```
fatal error: 'hicollie/hicollie.h' file not found
```
**解决方法**：
- 检查NDK路径配置
- 确保SDK包含Native头文件
- 重新下载完整的HarmonyOS SDK

**问题3：NAPI注册失败**
```
napi_module_register failed
```
**解决方法**：
- 检查nm_modname是否为"entry"
- 检查Init函数签名是否正确
- 确保CMakeLists.txt中库名为"entry"

**问题4：订阅接口返回null**
```
addWatcher returned null
```
**解决方法**：
- 检查观察者名称格式是否合法
- 检查API version是否>=21
- 检查domain和names参数是否正确

**问题5：回调函数未触发**
```
onReceive callback not triggered
```
**解决方法**：
- 检查Native代码是否正确触发超时事件
- 检查OH_HiCollie_SetTimer参数配置
- 查看hilog是否有错误日志
- 增加超时时间阈值确保触发

## 常见问题与解决方法

### Q1：订阅后回调未触发？
**原因**：
- Native代码未正确触发事件
- OH_HiCollie_CancelTimer过早取消
- 事件未实际发生

**解决方法**：
- 检查OH_HiCollie_SetTimer调用是否成功
- 确保超时时间阈值设置合理（至少1秒）
- 在Native代码中增加日志验证执行流程
- 确认sleep时间超过超时阈值

### Q2：事件参数解析出现undefined？
**原因**：
- params字段可能不存在某些属性
- 直接访问未检查的字段

**解决方法**：
- 使用可选链操作符：`eventInfo.params?.['field']`
- 增加类型检查：`if (field && Array.isArray(field))`
- 使用try-catch包裹解析逻辑

### Q3：移除观察者后再次订阅失败？
**原因**：
- 观察者名称重复
- 未正确移除之前的观察者

**解决方法**：
- 确保每次订阅使用不同的观察者名称
- 在移除后等待一段时间再重新订阅
- 检查removeWatcher是否成功执行

### Q4：Native代码编译链接失败？
**原因**：
- CMakeLists.txt配置错误
- 库文件路径不正确
- SDK版本过低

**解决方法**：
- 检查target_link_libraries是否包含libohhicollie.so
- 更新HarmonyOS SDK到最新版本
- 检查DevEco Studio构建配置

### Q5：运行时崩溃或无响应？
**原因**：
- Native代码内存泄漏
- 线程安全问题
- 回调函数执行耗时操作

**解决方法**：
- 检查Native代码是否有内存管理问题
- 避免在回调中执行复杂计算或I/O操作
- 使用hilog记录关键步骤排查问题
- 检查是否有无限循环或死锁

### Q6：如何在生产环境触发事件？
**原因**：
- 生产环境不应使用sleep构造故障

**解决方法**：
- 实际业务场景中任务执行超时自然触发
- 监控关键业务流程的执行时间
- 配置合理的超时阈值
- 记录超时事件日志用于问题分析

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "skillName": "hmos-performance-analysis-kit-hiappevent-watcher-hicollie",
  "apiUsed": [
    "hiAppEvent.addWatcher",
    "hiAppEvent.removeWatcher",
    "OH_HiCollie_SetTimer",
    "OH_HiCollie_CancelTimer"
  ],
  "eventSubscribed": "APP_HICOLLIE",
  "callbackTriggered": true,
  "eventParamsParsed": [
    "time",
    "foreground",
    "bundle_version",
    "process_name",
    "pid",
    "uid",
    "uuid",
    "exception",
    "hilog",
    "peer_binder",
    "memory",
    "external_log",
    "log_over_limit",
    "external_callback_log"
  ],
  "nativeCodeExecuted": true,
  "validationPassed": true
}
```

## 参考文档

- [API开发指南：订阅任务执行超时事件（ArkTS）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-apphicollie-events-arkts)
- [API参考说明：@ohos.hiviewdfx.hiAppEvent](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hiviewdfx-hiappevent)
- [API参考说明：HiCollie C API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie)
- [API参考说明：hicollie.h头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie-h)

## 完整示例代码

- [ArkTS示例：订阅和回调处理](assets/example_hiappevent_watcher.ets)
- [C++示例：故障注入触发](assets/example_hicollie_timer.cpp)
- [CMakeLists示例：依赖配置](assets/example_cmake.txt)
- [TypeScript定义：接口声明](assets/example_index.d.ts)
- [UI示例：触发按钮](assets/example_ui.ets)

## 测试用例

### 正向测试用例
- [订阅APP_HICOLLIE事件成功](tests/test_positive_subscribe.ets)：验证订阅成功，回调触发
- [事件参数完整解析](tests/test_positive_parse_params.ets)：验证所有参数字段正确解析
- [移除观察者成功](tests/test_positive_remove_watcher.ets)：验证移除订阅无错误
- [Native触发超时事件](tests/test_positive_native_trigger.cpp)：验证C代码正确触发事件

### 边界测试用例
- [观察者名称长度边界](tests/test_boundary_watcher_name.ets)：测试32字符长度限制
- [超时阈值最小值](tests/test_boundary_min_timeout.cpp)：测试1秒最小超时阈值
- [回调处理大量事件](tests/test_boundary_many_events.ets)：测试连续多次事件触发
- [并发订阅多个观察者](tests/test_boundary_multiple_watchers.ets)：测试多个观察者并发订阅

### 异常测试用例
- [无效观察者名称](tests/test_exception_invalid_name.ets)：测试非法字符和超长名称
- [订阅非APP_HICOLLIE事件](tests/test_exception_wrong_event.ets)：测试订阅错误事件名称
- [回调函数为空](tests/test_exception_empty_callback.ets)：测试未实现回调函数
- [Native参数错误](tests/test_exception_native_param.cpp)：测试OH_HiCollie_SetTimer参数错误
- [移除不存在的观察者](tests/test_exception_remove_nonexist.ets)：测试移除未添加的观察者