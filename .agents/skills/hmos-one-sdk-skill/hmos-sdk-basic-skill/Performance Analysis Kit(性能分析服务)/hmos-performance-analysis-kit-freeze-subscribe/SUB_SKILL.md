---
name: hmos-performance-analysis-kit-freeze-subscribe
description: 订阅应用冻屏事件(C/C++)，支持onReceive和onTrigger两种回调模式，仅限Native C++工程，适用于性能监控、故障诊断场景
---

# 订阅应用冻屏事件技能

## 功能描述

使用HiAppEvent C API订阅系统应用冻屏事件(APP_FREEZE)，当应用发生冻屏(主线程阻塞超过6秒)时，通过回调函数接收事件数据，包括冻屏时间、进程信息、异常详情、内存状态等关键诊断信息。支持两种回调模式：

- **onReceive模式**：实时接收冻屏事件，事件触发时立即回调
- **onTrigger模式**：批量接收冻屏事件，满足触发条件后回调

## 使用场景

### 触发词
- "订阅应用冻屏"
- "监听APP_FREEZE事件"
- "应用冻屏监控"
- "应用无响应检测"
- "应用卡顿监听"
- "性能分析事件订阅"

### 能做
- 订阅系统应用冻屏事件(APP_FREEZE)
- 实时接收冻屏事件通知(onReceive模式)
- 批量接收冻屏事件数据(onTrigger模式)
- 解析冻屏事件的详细参数(time, foreground, exception, memory, hilog等)
- 监控应用主线程阻塞状态
- 提取冻屏诊断信息用于问题分析

### 绝不做
- 订阅其他系统事件(如APP_CRASH、MAIN_THREAD_JANK等)
- 处理非冻屏类型的事件
- 用于ArkTS/JS工程(仅支持Native C++工程)
- 直接修改冻屏事件数据
- 在回调函数中执行耗时操作

### 补充
- 需要导入jsoncpp库解析JSON数据
- 观察者名称必须唯一，重复名称会覆盖前一次订阅
- onReceive回调中的指针生命周期仅限回调函数内，需要深拷贝
- OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景建议在子线程调用
- 仅支持API version 12及以上版本

## 调用规范和规则

### 输入约束
- **监听器名称**：非空字符串，建议具有描述性，长度不超过32字符
- **事件领域**：必须为DOMAIN_OS(系统事件域)
- **事件名称**：必须为EVENT_APP_FREEZE(应用冻屏事件)
- **观察者数量**：单个应用可创建多个观察者，但名称不能重复
- **回调函数**：必须实现回调函数逻辑，不能为nullptr

### 执行约束
- **最大回调处理时间**：建议不超过5秒，避免阻塞事件处理流程
- **JSON解析模式**：使用Json::Features::strictMode()避免解析错误
- **内存管理**：必须在观察者不再使用时调用OH_HiAppEvent_DestroyWatcher释放内存
- **操作顺序**：必须先调用OH_HiAppEvent_AddWatcher添加观察者，才能接收事件
- **线程安全**：OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景应在子线程调用

### 内容约束
- **禁止耗时操作**：回调函数中禁止执行文件I/O、网络请求等耗时操作
- **禁止保存指针**：禁止直接保存回调中的指针，必须进行深拷贝
- **禁止修改数据**：禁止修改事件数据内容
- **禁止高危函数**：禁止使用eval、exec、system等高危函数
- **必须异常捕获**：JSON解析和数据提取必须使用try-catch捕获异常

### 降级约束
- **JSON解析失败**：记录错误日志，跳过该事件处理，继续监听后续事件
- **观察者创建失败**：检查名称有效性，重新创建观察者
- **回调未触发**：检查事件过滤条件是否正确，确认订阅已添加成功
- **内存不足**：及时销毁不用的观察者，释放内存资源

## 调用流程和步骤

### 步骤1：准备开发环境

**前置校验**：
1. 确认开发环境为Native C++工程
2. 确认API version >= 12
3. 确认已安装DevEco Studio开发工具

**参数准备**：
```cmake
# CMakeLists.txt配置
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 添加jsoncpp源文件
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 添加依赖库
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

**导入头文件**：
```cpp
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#undef LOG_TAG
#define LOG_TAG "FreezeWatcher"
```

### 步骤2：创建观察者

**示例代码(onReceive模式)**：
```cpp
// 定义观察者指针变量
static HiAppEvent_Watcher *freezeWatcher = nullptr;

// 创建观察者
freezeWatcher = OH_HiAppEvent_CreateWatcher("freezeEventWatcher");
if (freezeWatcher == nullptr) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
    return;
}
```

**示例代码(onTrigger模式)**：
```cpp
// 定义观察者指针变量
static HiAppEvent_Watcher *freezeWatcher = nullptr;

// 创建观察者
freezeWatcher = OH_HiAppEvent_CreateWatcher("freezeTriggerWatcher");
if (freezeWatcher == nullptr) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
    return;
}
```

### 步骤3：设置事件过滤

**示例代码**：
```cpp
// 设置订阅的事件为APP_FREEZE(应用冻屏事件)
const char *names[] = {EVENT_APP_FREEZE};

// 设置事件过滤器
// domain: DOMAIN_OS(系统事件域)
// eventTypes: 0表示监听所有类型事件
// names: 事件名称数组
// namesLen: 数组长度
int result = OH_HiAppEvent_SetAppEventFilter(
    freezeWatcher, 
    DOMAIN_OS, 
    0, 
    names, 
    1
);

if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(freezeWatcher);
    freezeWatcher = nullptr;
    return;
}
```

### 步骤4：设置回调函数

**onReceive模式回调函数**：
```cpp
// 定义onReceive回调函数
static void OnReceive(const char *domain, 
                      const struct HiAppEvent_AppEventGroup *appEventGroups, 
                      uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 记录事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "Event domain=%{public}s", 
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "Event name=%{public}s", 
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "Event type=%{public}d", 
                        appEventGroups[i].appEventInfos[j].type);
            
            // 检查是否为冻屏事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_FREEZE) == 0) {
                
                // 解析事件参数(JSON格式)
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                try {
                    if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                        // 提取冻屏事件关键参数
                        auto time = params["time"].asInt64();
                        auto foreground = params["foreground"].asBool();
                        auto bundleName = params["bundle_name"].asString();
                        auto processName = params["process_name"].asString();
                        auto pid = params["pid"].asInt();
                        auto uid = params["uid"].asInt();
                        auto exception = writer.write(params["exception"]);
                        
                        OH_LOG_INFO(LogType::LOG_APP, 
                                    "Freeze detected: bundle=%{public}s, pid=%{public}d, time=%{public}lld",
                                    bundleName.c_str(), pid, time);
                        OH_LOG_INFO(LogType::LOG_APP, 
                                    "Exception: %{public}s", exception.c_str());
                    }
                } catch (const std::exception& e) {
                    OH_LOG_ERROR(LogType::LOG_APP, 
                                 "JSON parse error: %{public}s", e.what());
                }
            }
        }
    }
}

// 设置onReceive回调
int result = OH_HiAppEvent_SetWatcherOnReceive(freezeWatcher, OnReceive);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(freezeWatcher);
    freezeWatcher = nullptr;
    return;
}
```

**onTrigger模式回调函数**：
```cpp
// 定义OnTake回调函数(用于获取事件数据)
static void OnTake(const char* const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        try {
            if (reader.parse(events[i], eventInfo)) {
                auto domain = eventInfo["domain_"].asString();
                auto name = eventInfo["name_"].asString();
                
                // 检查是否为冻屏事件
                if (domain == DOMAIN_OS && name == EVENT_APP_FREEZE) {
                    auto time = eventInfo["time"].asInt64();
                    auto foreground = eventInfo["foreground"].asBool();
                    auto bundleName = eventInfo["bundle_name"].asString();
                    auto processName = eventInfo["process_name"].asString();
                    auto pid = eventInfo["pid"].asInt();
                    auto exception = writer.write(eventInfo["exception"]);
                    
                    OH_LOG_INFO(LogType::LOG_APP, 
                                "Freeze event: bundle=%{public}s, pid=%{public}d",
                                bundleName.c_str(), pid);
                    OH_LOG_INFO(LogType::LOG_APP, 
                                "Exception: %{public}s", exception.c_str());
                }
            }
        } catch (const std::exception& e) {
            OH_LOG_ERROR(LogType::LOG_APP, "Parse error: %{public}s", e.what());
        }
    }
}

// 定义OnTrigger回调函数
static void OnTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, 
                "Triggered: row=%{public}d, size=%{public}d", row, size);
    
    // 获取事件数据
    int result = OH_HiAppEvent_TakeWatcherData(freezeWatcher, row, OnTake);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, 
                     "Failed to take data: %{public}d", result);
    }
}

// 设置onTrigger回调
int result = OH_HiAppEvent_SetWatcherOnTrigger(freezeWatcher, OnTrigger);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(freezeWatcher);
    freezeWatcher = nullptr;
    return;
}

// 设置触发条件: 新增1个事件时触发
result = OH_HiAppEvent_SetTriggerCondition(freezeWatcher, 1, 0, 0);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set condition: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(freezeWatcher);
    freezeWatcher = nullptr;
    return;
}
```

### 步骤5：启动监听

**示例代码**：
```cpp
// 添加观察者，开始监听事件
int result = OH_HiAppEvent_AddWatcher(freezeWatcher);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(freezeWatcher);
    freezeWatcher = nullptr;
    return;
}

OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher started successfully");
```

### 步骤6：处理冻屏事件

**事件参数说明**：

冻屏事件(APP_FREEZE)包含以下关键参数：

| 参数名 | 类型 | 说明 |
|-------|------|------|
| time | int64 | 冻屏发生时间戳(毫秒) |
| foreground | bool | 应用是否在前台 |
| bundle_name | string | 应用包名 |
| process_name | string | 进程名 |
| pid | int | 进程ID |
| uid | int | 用户ID |
| uuid | string | 事件唯一标识 |
| exception | object | 异常详情(message, name) |
| hilog | array | 系统日志信息 |
| event_handler | array | 事件处理器信息 |
| memory | object | 内存状态(pss, rss, sys_avail_mem等) |
| threads | array | 线程信息 |
| external_log | array | 外部日志文件路径 |

**参数提取示例**：
```cpp
// 提取所有冻屏参数
auto time = params["time"].asInt64();
auto foreground = params["foreground"].asBool();
auto appRunningUniqueId = params["app_running_unique_id"].asString();
auto bundleVersion = params["bundle_version"].asString();
auto bundleName = params["bundle_name"].asString();
auto processName = params["process_name"].asString();
auto pid = params["pid"].asInt();
auto uid = params["uid"].asInt();
auto uuid = params["uuid"].asString();
auto exception = writer.write(params["exception"]);
auto hilogSize = params["hilog"].size();
auto handleSize = params["event_handler"].size();
auto memory = writer.write(params["memory"]);
auto externalLog = writer.write(params["external_log"]);
auto logOverLimit = params["log_over_limit"].asBool();
```

### 步骤7：移除和销毁观察者

**移除观察者**：
```cpp
// 停止监听事件
int result = OH_HiAppEvent_RemoveWatcher(freezeWatcher);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
}
```

**销毁观察者**：
```cpp
// 销毁观察者并释放内存
OH_HiAppEvent_DestroyWatcher(freezeWatcher);
freezeWatcher = nullptr;  // 置空指针防止重复使用
OH_LOG_INFO(LogType::LOG_APP, "Freeze watcher destroyed");
```

### 步骤8：注册为ArkTS接口

**导出函数示例**：
```cpp
// 注册观察者函数
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 执行步骤2-5的逻辑
    // 创建观察者、设置过滤、设置回调、添加观察者
    return {};
}

// 移除观察者函数
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (freezeWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(freezeWatcher);
    }
    return {};
}

// 销毁观察者函数
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (freezeWatcher != nullptr) {
        OH_HiAppEvent_RemoveWatcher(freezeWatcher);
        OH_HiAppEvent_DestroyWatcher(freezeWatcher);
        freezeWatcher = nullptr;
    }
    return {};
}

// 注册接口
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**ArkTS接口定义(index.d.ts)**：
```typescript
export const registerWatcher: () => void;
export const removeWatcher: () => void;
export const destroyWatcher: () => void;
```

**ArkTS调用示例**：
```typescript
import freezeNapi from 'libentry.so';

// 在应用启动时注册观察者
freezeNapi.registerWatcher();

// 在应用退出时销毁观察者
freezeNapi.destroyWatcher();
```

### 步骤9：触发测试事件

**测试代码示例**：
```typescript
// 在Index.ets中添加测试按钮
Button("触发冻屏")
  .onClick(() => {
    setTimeout(() => {
      while(true) {}  // 主线程阻塞，触发冻屏
    }, 1000)
  })
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| -1 | names参数异常(事件名称数组无效) | 检查事件名称是否正确，确认为EVENT_APP_FREEZE |
| -4 | domain参数异常(事件域无效) | 检查事件域是否正确，确认为DOMAIN_OS |
| -5 | watcher入参空指针 | 检查观察者指针是否为nullptr，确认已成功创建观察者 |
| -6 | 还未调用OH_HiAppEvent_AddWatcher | 先调用OH_HiAppEvent_AddWatcher添加观察者，再调用OH_HiAppEvent_TakeWatcherData |
| HIAPPEVENT_INVALID_PARAM_VALUE | 参数值无效 | 检查参数类型和取值范围是否正确 |
| HIAPPEVENT_OPERATE_FAILED | 操作失败 | 检查系统状态和权限配置 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 添加jsoncpp源文件
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 添加依赖库
target_link_libraries(entry PUBLIC 
    libace_napi.z.so        # NAPI接口库
    libhilog_ndk.z.so       # 日志库
    libhiappevent_ndk.z.so  # HiAppEvent库
)

# 添加头文件路径
target_include_directories(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)
```

**jsoncpp导入说明**：
1. 从 [jsoncpp开源库](https://github.com/open-source-parsers/jsoncpp) 下载源码
2. 按照README的 **Amalgamated source** 步骤生成三个文件：
   - jsoncpp.cpp
   - json.h
   - json-forwards.h
3. 将文件放入工程cpp/json目录

### 环境要求
- **API version**：最低12
- **开发环境**：DevEco Studio 3.1及以上
- **编程语言**：C/C++ (Native开发)
- **系统能力**：SystemCapability.HiviewDFX.HiAppEvent

### 常见编译问题

**问题1：找不到json头文件**
```
fatal error: 'json/json.h' file not found
```
**解决方法**：
1. 检查json.h和json-forwards.h是否在cpp/json目录
2. 检查CMakeLists.txt中的target_include_directories配置
3. 确保jsoncpp.cpp已添加到add_library源文件列表

**问题2：找不到hiappevent头文件**
```
fatal error: 'hiappevent/hiappevent.h' file not found
```
**解决方法**：
1. 确认API version >= 12
2. 确认已添加libhiappevent_ndk.z.so依赖
3. 检查DevEco Studio SDK版本是否正确

**问题3：链接错误**
```
undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**：
1. 检查target_link_libraries是否包含libhiappevent_ndk.z.so
2. 确认库名拼写正确
3. 清理工程重新编译(Clean Project)

**问题4：观察者创建返回nullptr**
```
freezeWatcher is nullptr
```
**解决方法**：
1. 检查观察者名称是否为空字符串
2. 检查观察者名称是否已存在(名称必须唯一)
3. 确认系统资源充足

**问题5：回调未触发**
```
回调函数未被调用
```
**解决方法**：
1. 检查OH_HiAppEvent_AddWatcher是否成功调用
2. 检查事件过滤条件是否正确(DOMAIN_OS, EVENT_APP_FREEZE)
3. 确认应用发生了冻屏事件(主线程阻塞超过6秒)
4. 检查回调函数是否正确设置

## 常见问题与解决方法

### Q1：如何选择onReceive和onTrigger模式？

**原因**：两种模式适用于不同场景
**解决方法**：
- **onReceive模式**：适合实时监控，事件触发时立即回调，响应速度快
- **onTrigger模式**：适合批量处理，可设置触发条件(事件数量、大小、超时)，减少回调频率
- 建议：性能监控场景使用onReceive，数据上报场景使用onTrigger

### Q2：如何避免回调函数阻塞事件处理？

**原因**：回调函数执行时间过长会影响系统事件处理性能
**解决方法**：
- 在回调中仅提取关键数据，深拷贝后立即返回
- 将耗时操作(如文件写入、网络上报)放到独立线程执行
- 使用消息队列将事件数据传递到工作线程处理
- 控制回调执行时间不超过5秒

### Q3：JSON解析失败如何处理？

**原因**：事件参数JSON字符串格式异常或数据类型不匹配
**解决方法**：
- 使用Json::Features::strictMode()进行严格模式解析
- 使用try-catch捕获解析异常
- 记录错误日志并跳过该事件处理
- 检查参数类型是否匹配(如int64、bool、string)

### Q4：如何获取完整的冻屏诊断信息？

**原因**：需要提取所有冻屏事件参数用于问题分析
**解决方法**：
- 提取exception字段分析异常原因(message: "App main thread is not response!", name: "THREAD_BLOCK_6S")
- 提取hilog数组查看系统日志
- 提取memory字段分析内存状态(pss, rss, sys_avail_mem)
- 提取threads数组查看线程状态
- 检查external_log路径获取详细日志文件

### Q5：观察者名称重复会怎样？

**原因**：相同名称的观察者会覆盖前一次订阅
**解决方法**：
- 确保每个观察者使用唯一名称
- 建议使用描述性命名(如"freezeEventWatcher")
- 如果需要重新订阅，先销毁旧观察者再创建新观察者

### Q6：如何在应用启动时自动订阅？

**原因**：需要在应用生命周期管理观察者
**解决方法**：
- 在EntryAbility的onCreate()函数中调用registerWatcher()
- 在onDestroy()函数中调用destroyWatcher()
- 确保观察者生命周期与应用生命周期同步
- 参考ArkTS调用示例实现自动注册

### Q7：如何测试冻屏事件？

**原因**：需要触发冻屏事件验证订阅功能
**解决方法**：
- 在应用中添加测试按钮，点击后执行死循环阻塞主线程
- 使用while(true) {}阻塞超过6秒触发冻屏
- 观察Log窗口是否输出冻屏事件数据
- 注意：测试会导致应用崩溃退出，这是正常现象

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherName": "freezeEventWatcher",
  "eventType": "APP_FREEZE",
  "eventDomain": "DOMAIN_OS",
  "callbackMode": "onReceive/onTrigger",
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_SetWatcherOnTrigger",
    "OH_HiAppEvent_SetTriggerCondition",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher",
    "OH_HiAppEvent_TakeWatcherData"
  ],
  "eventParams": [
    "time",
    "foreground",
    "bundle_name",
    "process_name",
    "pid",
    "uid",
    "exception",
    "memory",
    "hilog",
    "threads"
  ]
}
```

## 参考文档

- [API开发指南 - 订阅应用冻屏事件(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events-ndk)
- [API参考说明 - hiappevent.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [使用FaultLogExtensionAbility订阅事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts)

## 完整示例代码

- [C++示例代码(onReceive模式)](assets/example_freeze_watcher_onreceive.cpp)
- [C++示例代码(onTrigger模式)](assets/example_freeze_watcher_ontrigger.cpp)
- [CMakeLists.txt配置示例](assets/cmakelists_config.txt)
- [ArkTS接口定义示例](assets/index_d_ts.txt)

## 测试用例

### 正向测试用例
- [测试订阅冻屏事件成功](tests/test_positive.cpp)：验证观察者创建和订阅成功
- [测试接收冻屏事件数据](tests/test_receive_event.cpp)：验证回调函数正确接收事件数据
- [测试JSON解析成功](tests/test_json_parse.cpp)：验证事件参数正确解析

### 边界测试用例
- [测试观察者名称长度限制](tests/test_watcher_name_length.cpp)：验证名称长度不超过32字符
- [测试事件数量触发条件](tests/test_trigger_condition.cpp)：验证onTrigger触发条件正确执行
- [测试并发多个观察者](tests/test_multiple_watchers.cpp)：验证多个观察者同时订阅

### 异常测试用例
- [测试观察者创建失败](tests/test_watcher_create_fail.cpp)：验证nullptr检查和错误处理
- [测试JSON解析异常](tests/test_json_parse_error.cpp)：验证异常捕获和降级处理
- [测试重复名称订阅](tests/test_duplicate_name.cpp)：验证名称唯一性检查
- [测试回调未触发](tests/test_callback_not_triggered.cpp)：验证事件过滤条件检查