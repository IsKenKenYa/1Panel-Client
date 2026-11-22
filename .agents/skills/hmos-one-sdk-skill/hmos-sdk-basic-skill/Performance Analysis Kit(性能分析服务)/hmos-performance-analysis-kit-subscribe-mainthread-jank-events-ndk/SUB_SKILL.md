---
name: hmos-performance-analysis-kit-subscribe-mainthread-jank-events-ndk
description: 订阅主线程超时事件，支持C/C++ NDK接口，监听系统事件MAIN_THREAD_JANK，捕获主线程卡顿信息，适用于性能监控、故障诊断场景
---

# 订阅主线程超时事件（C/C++）技能

## 功能描述

本技能使用HiAppEvent C/C++ API订阅系统主线程超时事件(MAIN_THREAD_JANK)，用于监控应用主线程的卡顿情况。当主线程执行超时时，系统会自动上报事件，开发者通过订阅该事件可以获取详细的卡顿信息，包括超时时间、进程信息、bundle信息、超时时间段以及相关的日志文件路径。

**核心能力**：
- 创建事件监听器(Watcher)订阅系统事件
- 设置事件过滤规则(领域、事件名称)
- 实现回调函数接收和处理事件数据
- 解析JSON格式的事件参数
- 移除和销毁监听器释放资源

**适用范围**：
- HarmonyOS应用性能监控
- 主线程卡顿故障诊断
- 应用稳定性分析

**技术限制**：
- 仅支持C/C++语言开发
- 需要API Version 12及以上(Watcher相关接口)
- 需要依赖第三方JSON解析库(如jsoncpp)

## 使用场景

### 触发词
- "订阅主线程超时事件"
- "监控主线程卡顿"
- "HiAppEvent C++订阅"
- "MAIN_THREAD_JANK事件"
- "主线程性能监控"
- "应用卡顿检测"

### 能做
- 创建和配置事件监听器
- 订阅系统主线程超时事件
- 解析事件参数获取卡顿详情
- 实现自定义的事件处理逻辑
- 正确管理监听器生命周期(创建、添加、移除、销毁)

### 绝不做
- 不订阅其他类型的系统事件(如非性能相关事件)
- 不在回调函数外直接使用回调指针(需深拷贝)
- 不忘记销毁监听器导致内存泄漏
- 不在性能敏感场景的主线程调用OH_HiAppEvent_AddWatcher

### 补充
- 主线程超时事件默认触发规格：单个任务执行超过一定时间(具体时间阈值参考系统配置)
- 事件包含详细的卡顿信息和日志文件路径
- 需要配合jsoncpp等第三方库解析JSON参数

## 调用规范和规则

### 输入约束
- 监听器名称：字符串类型，必须唯一，长度合理
- 事件领域：DOMAIN_OS(系统领域)
- 事件名称：EVENT_MAIN_THREAD_JANK
- 无输入文件要求

### 执行约束
- 最大耗时：OH_HiAppEvent_AddWatcher涉及I/O操作，建议不超过100ms
- 回调函数执行时间：建议不超过50ms，避免阻塞事件处理
- 监听器数量：建议不超过10个，避免资源浪费
- API调用顺序：CreateWatcher → SetAppEventFilter → SetWatcherOnReceive → AddWatcher

### 内容约束
- 禁止在回调函数中执行耗时操作
- 禁止在回调函数外直接使用回调指针
- 禁止使用相同名称创建多个监听器(会覆盖)
- 必须在适当时机移除和销毁监听器

### 降级约束
- 监听器创建失败：记录错误日志，放弃订阅
- 回调函数解析失败：记录错误信息，继续监听后续事件
- JSON解析失败：跳过当前事件参数解析，处理下一个事件

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证API版本是否≥12(HiAppEvent_Watcher接口)
2. 验证系统能力：SystemCapability.HiviewDFX.HiAppEvent
3. 准备第三方JSON解析库(如jsoncpp)
4. 配置CMakeLists.txt添加依赖库

**参数准备**：
```cpp
// 定义必要的头文件和宏
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "MainThreadJankWatcher"

// 定义监听器指针缓存变量
static HiAppEvent_Watcher *systemEventWatcher = nullptr;
```

**依赖配置**：
```cmake
# CMakeLists.txt配置
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 添加必要的动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

### 步骤2：创建监听器

**示例代码**：
```cpp
// 创建监听器
static napi_value CreateWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "CreateWatcher start");
    
    // 创建监听器，名称必须唯一
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("MainThreadJankWatcher");
    
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher created successfully");
    return {};
}
```

### 步骤3：设置事件过滤规则

**示例代码**：
```cpp
// 设置过滤规则，订阅主线程超时事件
static napi_value SetEventFilter(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Watcher is null");
        return {};
    }
    
    // 设置订阅的事件名称为EVENT_MAIN_THREAD_JANK
    const char *names[] = {EVENT_MAIN_THREAD_JANK};
    
    // 设置事件过滤规则
    // domain: DOMAIN_OS(系统领域)
    // eventTypes: 0表示所有类型
    // names: 事件名称数组
    // namesLen: 数组长度
    int result = OH_HiAppEvent_SetAppEventFilter(
        systemEventWatcher, 
        DOMAIN_OS, 
        0, 
        names, 
        1
    );
    
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, result=%d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Event filter set successfully");
    return {};
}
```

### 步骤4：实现回调函数

**示例代码**：
```cpp
// OnReceive回调函数实现
static void OnReceive(const char *domain, 
                      const struct HiAppEvent_AppEventGroup *appEventGroups, 
                      uint32_t groupLen) {
    OH_LOG_INFO(LogType::LOG_APP, "OnReceive triggered, groupLen=%d", groupLen);
    
    // 遍历所有事件组
    for (uint32_t i = 0; i < groupLen; ++i) {
        // 遍历事件组中的所有事件
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 打印事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "Event domain=%{public}s", 
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "Event name=%{public}s", 
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "Event type=%{public}d", 
                        appEventGroups[i].appEventInfos[j].type);
            
            // 检查是否是主线程超时事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_MAIN_THREAD_JANK) == 0) {
                
                // 解析JSON参数
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    // 提取参数值
                    auto time = params["time"].asInt64();
                    auto pid = params["pid"].asInt();
                    auto uid = params["uid"].asInt();
                    auto bundleName = params["bundle_name"].asString();
                    auto bundleVersion = params["bundle_version"].asString();
                    auto beginTime = params["begin_time"].asInt64();
                    auto endTime = params["end_time"].asInt64();
                    auto externalLog = writer.write(params["external_log"]);
                    auto logOverLimit = params["log_over_limit"].asBool();
                    
                    // 打印详细参数信息
                    OH_LOG_INFO(LogType::LOG_APP, "time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "pid=%{public}d", pid);
                    OH_LOG_INFO(LogType::LOG_APP, "uid=%{public}d", uid);
                    OH_LOG_INFO(LogType::LOG_APP, "bundle_name=%{public}s", 
                                bundleName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "bundle_version=%{public}s", 
                                bundleVersion.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "begin_time=%{public}lld", beginTime);
                    OH_LOG_INFO(LogType::LOG_APP, "end_time=%{public}lld", endTime);
                    OH_LOG_INFO(LogType::LOG_APP, "external_log=%{public}s", 
                                externalLog.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "log_over_limit=%{public}d", 
                                logOverLimit);
                } else {
                    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse JSON params");
                }
            }
        }
    }
}

// 设置回调函数
static napi_value SetCallback(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Watcher is null");
        return {};
    }
    
    int result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set callback, result=%d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Callback set successfully");
    return {};
}
```

### 步骤5：添加监听器

**示例代码**：
```cpp
// 添加监听器，开始监听
static napi_value AddWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Watcher is null");
        return {};
    }
    
    // 添加监听器，开始监听系统消息
    // 注意：此接口涉及I/O操作，在性能敏感场景需谨慎选择线程
    int result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, result=%d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher added successfully, start monitoring");
    return {};
}
```

### 步骤6：移除和销毁监听器

**示例代码**：
```cpp
// 移除监听器
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Watcher is null");
        return {};
    }
    
    // 移除监听器，停止监听
    int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
    
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher, result=%d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
    return {};
}

// 销毁监听器
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Watcher is null");
        return {};
    }
    
    // 销毁监听器，释放内存
    OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
    
    // 将指针置空，防止误用
    systemEventWatcher = nullptr;
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed successfully");
    return {};
}
```

### 步骤7：注册为ArkTS接口

**示例代码**：
```cpp
// 将C++函数注册为ArkTS接口
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "createWatcher", nullptr, CreateWatcher, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "setEventFilter", nullptr, SetEventFilter, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "setCallback", nullptr, SetCallback, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "addWatcher", nullptr, AddWatcher, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, 
          napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, 
          napi_default, nullptr }
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**ArkTS接口定义**：
```typescript
// index.d.ts
export const createWatcher: () => void;
export const setEventFilter: () => void;
export const setCallback: () => void;
export const addWatcher: () => void;
export const removeWatcher: () => void;
export const destroyWatcher: () => void;
```

### 步骤8：ArkTS调用示例

**示例代码**：
```typescript
// EntryAbility.ets
import testNapi from 'libentry.so';

export default class EntryAbility {
    onCreate() {
        // 启动时注册监听器
        testNapi.createWatcher();
        testNapi.setEventFilter();
        testNapi.setCallback();
        testNapi.addWatcher();
    }
    
    onDestroy() {
        // 销毁时移除监听器
        testNapi.removeWatcher();
        testNapi.destroyWatcher();
    }
}

// Index.ets - 模拟触发主线程超时
@Entry
@Component
struct Index {
    build() {
        Column() {
            Button("触发主线程超时(350ms)")
                .fontSize(20)
                .onClick(() => {
                    let t = Date.now();
                    while (Date.now() - t <= 350) {}
                })
        }
    }
}
```

### 步骤9：错误处理

**错误处理代码**：
```cpp
// 统一的错误处理函数
static void HandleError(int errorCode, const char* operation) {
    switch (errorCode) {
        case 0:
            OH_LOG_INFO(LogType::LOG_APP, "%s succeeded", operation);
            break;
        case -1:
            OH_LOG_ERROR(LogType::LOG_APP, "%s failed: invalid event name", operation);
            break;
        case -4:
            OH_LOG_ERROR(LogType::LOG_APP, "%s failed: invalid domain", operation);
            break;
        case -5:
            OH_LOG_ERROR(LogType::LOG_APP, "%s failed: watcher is null", operation);
            break;
        case -6:
            OH_LOG_ERROR(LogType::LOG_APP, "%s failed: operation sequence error", operation);
            break;
        default:
            OH_LOG_ERROR(LogType::LOG_APP, "%s failed: unknown error %d", 
                         operation, errorCode);
            break;
    }
}
```

### 步骤10：降级处理

**降级处理代码**：
```cpp
// 创建监听器失败时的降级方案
static HiAppEvent_Watcher* CreateWatcherWithFallback(const char* name) {
    HiAppEvent_Watcher* watcher = OH_HiAppEvent_CreateWatcher(name);
    
    if (watcher == nullptr) {
        // 第一次创建失败，尝试使用不同的名称
        OH_LOG_WARN(LogType::LOG_APP, "First creation failed, trying alternative name");
        watcher = OH_HiAppEvent_CreateWatcher("FallbackWatcher");
        
        if (watcher == nullptr) {
            // 第二次仍然失败，记录错误并放弃
            OH_LOG_ERROR(LogType::LOG_APP, "Watcher creation failed after fallback");
            return nullptr;
        }
    }
    
    return watcher;
}

// JSON解析失败时的降级方案
static bool ParseParamsWithFallback(const char* paramsStr, Json::Value& params) {
    Json::Reader reader(Json::Features::strictMode());
    
    if (!reader.parse(paramsStr, params)) {
        // 严格模式解析失败，尝试宽松模式
        OH_LOG_WARN(LogType::LOG_APP, "Strict parse failed, trying relaxed mode");
        Json::Reader relaxedReader(Json::Features::all());
        
        if (!relaxedReader.parse(paramsStr, params)) {
            // 两种模式都失败，记录原始字符串
            OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed: %s", paramsStr);
            return false;
        }
    }
    
    return true;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| -1 | 非法的事件名称 | 检查事件名称是否符合规范，使用系统定义的EVENT_MAIN_THREAD_JANK |
| -4 | 非法的事件领域名称 | 检查事件领域，使用系统定义的DOMAIN_OS |
| -5 | watcher入参空指针 | 检查监听器指针是否为nullptr，确保已创建监听器 |
| -6 | 操作顺序有误 | 确保按照正确顺序调用API：CreateWatcher → SetFilter → SetCallback → AddWatcher |
| -99 | 打点功能被关闭 | 检查系统配置，确认HiAppEvent功能已启用 |
| 1 | 非法的事件参数名称 | 检查参数名称格式(首字符必须为字母或$) |
| 4 | 非法的事件参数字符串长度 | 字符串参数长度需在8*1024字符以内 |
| 5 | 非法的事件参数数量 | 参数个数需在32个以内 |
| 8 | 重复的事件参数名称 | 避免重复添加同名参数 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置C++标准
set(CMAKE_CXX_STANDARD 11)

# 添加源文件
add_library(entry SHARED 
    napi_init.cpp 
    jsoncpp.cpp  # jsoncpp源文件
)

# 添加头文件路径
include_directories(
    ${CMAKE_CURRENT_SOURCE_DIR}/json
)

# 添加动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so       # NAPI接口
    libhilog_ndk.z.so      # 日志输出
    libhiappevent_ndk.z.so # HiAppEvent NDK
)
```

**模块配置(build-profile.json5)**：
```json
{
  "apiType": 'stageMode',
  "buildOption": {
    "externalNativeOptions": {
      "path": "./src/main/cpp/CMakeLists.txt",
      "arguments": "",
      "cppFlags": "",
      "targets": [
        {
          "name": "entry",
          "runtimeOS": "HarmonyOS"
        }
      ]
    }
  }
}
```

### 环境要求
- HarmonyOS SDK: API Version 12及以上
- DevEco Studio: 3.1及以上版本
- C++编译器: 支持C++11标准
- jsoncpp库: 需手动导入(json.h, json-forwards.h, jsoncpp.cpp)

### 常见编译问题

**问题1：找不到hiappevent头文件**
```
error: 'hiappevent/hiappevent.h' file not found
```
**解决方法**：
- 确认HarmonyOS SDK版本≥12
- 在CMakeLists.txt中添加正确的头文件路径
- 检查build-profile.json5中的externalNativeOptions配置

**问题2：jsoncpp编译错误**
```
error: undefined reference to 'Json::Reader::parse'
```
**解决方法**：
- 确保jsoncpp.cpp已添加到add_library源文件列表
- 确保json目录下的json.h和json-forwards.h文件存在
- 检查include_directories是否正确指向json目录

**问题3：动态库链接失败**
```
error: cannot find -lhiappevent_ndk
```
**解决方法**：
- 确认libhiappevent_ndk.z.so库文件存在于SDK目录
- 检查target_link_libraries是否正确配置库名称
- 确认API Version≥12才包含该库

**问题4：NAPI注册失败**
```
error: napi_define_properties failed
```
**解决方法**：
- 检查Init函数的导出模块名称是否与libentry.so匹配
- 确认index.d.ts文件中的接口定义与C++函数名称一致
- 检查napi_property_descriptor数组配置是否正确

## 常见问题与解决方法

### Q1：监听器创建失败返回nullptr
**原因**：
- 监听器名称不合法(长度超限或包含非法字符)
- 内存分配失败
- 系统资源不足

**解决方法**：
- 使用合法的监听器名称(建议使用简单的英文字符串)
- 检查系统内存状态
- 尝试使用不同的名称创建

### Q2：无法接收到主线程超时事件
**原因**：
- 主线程未触发超时(执行时间未达到阈值)
- 事件过滤规则设置错误
- 监听器未添加或添加失败

**解决方法**：
- 模拟主线程超时场景(如循环延时350ms)
- 检查事件过滤规则(DOMAIN_OS和EVENT_MAIN_THREAD_JANK)
- 确认已调用OH_HiAppEvent_AddWatcher且返回成功

### Q3：回调函数中解析JSON失败
**原因**：
- JSON格式不正确
- jsoncpp库版本问题
- 参数字符串损坏

**解决方法**：
- 使用宽松模式解析(Json::Features::all())
- 打印原始params字符串查看格式
- 检查jsoncpp库是否正确导入

### Q4：监听器无法销毁导致内存泄漏
**原因**：
- 未调用OH_HiAppEvent_DestroyWatcher
- 销毁顺序错误(应先Remove再Destroy)
- 指针未置空导致误用

**解决方法**：
- 在应用退出时必须调用DestroyWatcher
- 按正确顺序：RemoveWatcher → DestroyWatcher → pointer=nullptr
- 使用RAII模式自动管理监听器生命周期

### Q5：OH_HiAppEvent_AddWatcher性能问题
**原因**：
- 该接口涉及I/O操作，在主线程调用可能阻塞
- 多次调用创建多个监听器

**解决方法**：
- 在性能敏感场景，在子线程调用AddWatcher
- 只创建必要的监听器，避免频繁添加移除
- 使用异步方式管理监听器

### Q6：事件参数解析时指针生命周期问题
**原因**：
- 回调函数中的指针生命周期仅限于回调内
- 在回调外直接使用指针导致访问无效内存

**解决方法**：
- 在回调函数内对指针内容进行深拷贝
- 使用std::string或Json::Value等对象保存数据
- 不要缓存原始指针，立即处理数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherCreated": true,
  "eventFilterSet": true,
  "callbackSet": true,
  "watcherAdded": true,
  "eventsReceived": [
    {
      "domain": "OS",
      "name": "MAIN_THREAD_JANK",
      "type": 1,
      "params": {
        "time": 1717597063727,
        "pid": 45572,
        "uid": 20020151,
        "bundle_name": "com.example.nativemainthread",
        "bundle_version": "1.0.0",
        "begin_time": 1717597063225,
        "end_time": 1717597063727,
        "external_log": "[\"/data/storage/el2/log/watchdog/MAIN_THREAD_JANK_20240613221239_45572.txt\"]",
        "log_over_limit": false
      }
    }
  ],
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ]
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-mainthreadjank-events-ndk.md) - 订阅主线程超时事件开发指南
- [API参考说明](references/capi-hiappevent-h.md) - HiAppEvent C API头文件详细说明
- [主线程超时事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-mainthreadjank-events) - 主线程超时事件规格说明
- [主线程超时事件默认时间规格](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/apptask-timeout-guidelines) - 系统事件触发时间阈值

## 完整示例代码

- [C++完整示例](assets/example_mainthread_jank_watcher.cpp) - 包含完整的监听器创建、配置、回调、销毁流程
- [CMakeLists.txt示例](assets/example_cmake.txt) - CMake配置文件示例
- [ArkTS接口定义](assets/example_index_d_ts.txt) - TypeScript接口定义示例
- [ArkTS调用示例](assets/example_entry_ability_ets.txt) - ArkTS端调用示例

## 测试用例

### 正向测试用例
- [创建监听器并订阅事件](tests/test_positive.cpp)：验证监听器创建和事件订阅成功
- [接收并解析事件](tests/test_parse_event.cpp)：验证事件接收和JSON解析正确性
- [完整生命周期管理](tests/test_lifecycle.cpp)：验证创建、添加、移除、销毁完整流程

### 边界测试用例
- [监听器名称边界](tests/test_watcher_name_boundary.cpp)：测试监听器名称长度限制
- [事件参数边界](tests/test_event_params_boundary.cpp)：测试事件参数数量和长度限制
- [多次创建监听器](tests/test_multiple_watchers.cpp)：测试相同名称监听器的覆盖行为

### 异常测试用例
- [监听器创建失败](tests/test_create_failure.cpp)：测试监听器创建失败的处理
- [JSON解析失败](tests/test_json_parse_failure.cpp)：测试JSON解析错误的降级处理
- [空指针处理](tests/test_null_pointer.cpp)：测试空指针异常的处理
- [顺序错误调用](tests/test_wrong_sequence.cpp)：测试API调用顺序错误的处理