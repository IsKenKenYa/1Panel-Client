---
name: hmos-performance-analysis-kit-crash-event-watcher
description: 订阅应用崩溃事件，支持JsError和NativeCrash类型，提供onReceive和onTrigger两种回调模式，适用于崩溃监控、故障分析场景
---

# 订阅崩溃事件技能

## 功能描述

使用HiAppEvent提供的C/C++接口订阅应用崩溃事件，包括JsError和NativeCrash两种类型。支持两种观察者模式：onReceive类型观察者（实时接收崩溃事件）和onTrigger类型观察者（按条件触发回调）。支持配置崩溃事件采集参数，如寄存器扩展内存打印、日志截断大小、minidump采集等。

## 使用场景

### 触发词
- "订阅崩溃事件"
- "监控应用崩溃"
- "崩溃事件回调"
- "NativeCrash订阅"
- "JsError订阅"

### 能做
- 订阅应用崩溃事件（JsError和NativeCrash）
- 实时接收崩溃事件（onReceive模式）
- 按条件批量接收崩溃事件（onTrigger模式）
- 配置崩溃事件采集参数
- 解析崩溃事件详细信息（崩溃类型、堆栈、内存等）
- 移除并销毁崩溃事件观察者

### 绝不做
- 不订阅非崩溃类型的系统事件
- 不处理应用主动捕获的异常（通过errorManager.on捕获）
- 不替代应用层的崩溃恢复机制
- 不直接修改崩溃日志文件

### 补充
- **重要**：必须在应用启动后、执行业务逻辑前添加事件观察者，否则应用可能因崩溃退出而无法订阅崩溃事件
- JsError崩溃事件通过进程内采集，回调速度快
- NativeCrash崩溃事件通过进程外采集，平均耗时约2秒
- 从API version 21开始，若应用无法启动或长时间未启动，可使用FaultLogExtensionAbility订阅事件进行延迟上报

## 调用规范和规则

### 输入约束
- 观察者名称：长度不超过48个字符，仅支持字母、数字、下划线，不能以下划线开头或结尾
- 事件域名：DOMAIN_OS（系统事件域）
- 事件名称：EVENT_APP_CRASH（崩溃事件）
- 回调函数：必须实现onReceive或onTrigger回调
- 配置参数值：字符串格式，需符合配置项要求

### 执行约束
- 最大观察者数量：无限制（但建议不超过10个）
- API调用时机：应用启动后立即调用（在Ability onCreate中）
- 性能考虑：OH_HiAppEvent_AddWatcher涉及I/O操作，在性能敏感场景建议在子线程调用
- 回调时机：JsError崩溃事件在应用下次启动时回调（未主动捕获异常场景），NativeCrash崩溃事件在应用下次启动时回调（未主动捕获异常场景）

### 内容约束
- 禁止生成：不生成与崩溃无关的事件订阅代码
- 禁止使用高危函数：不使用malloc/free直接管理HiAppEvent对象内存（使用API提供的创建和销毁接口）
- 禁止操作：不直接操作崩溃日志文件路径

### 降级约束
- 网络失败：崩溃事件订阅为本地操作，不涉及网络
- 权限不足：崩溃事件订阅无需特殊权限
- 回调失败：若回调函数异常，不影响崩溃事件采集，但需开发者自行处理回调中的异常

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认工程为Native C++工程
2. 确认已导入必要的头文件：hiappevent.h、hiappevent_param.h、hilog.h
3. 确认已添加必要的动态库依赖：libhiappevent_ndk.z.so、libhilog_ndk.z.so
4. 确认已导入jsoncpp库（用于解析崩溃事件中的json参数）

**参数准备**：
```cpp
// 导入必要的头文件
#include "napi/native_api.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_param.h"
#include "hilog/log.h"
#include "json/json.h"  // jsoncpp库

// 定义日志标签
#undef LOG_TAG
#define LOG_TAG "CrashEventWatcher"

// 定义观察者名称（全局变量，用于缓存观察者指针）
static HiAppEvent_Watcher *systemEventWatcherR = nullptr;
static HiAppEvent_Watcher *systemEventWatcherT = nullptr;
```

### 步骤2：创建崩溃事件观察者

**onReceive类型观察者示例**：
```cpp
// 定义onReceive回调函数
static void OnReceiveCrashEvent(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups,
    uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            const struct HiAppEvent_AppEventInfo &appEventInfo = appEventGroups[i].appEventInfos[j];
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventInfo.domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventInfo.name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventInfo.type);
            
            // 过滤崩溃事件
            if (strcmp(appEventInfo.domain, DOMAIN_OS) != 0 || strcmp(appEventInfo.name, EVENT_APP_CRASH) != 0) {
                continue;
            }
            
            // 解析崩溃事件参数（使用jsoncpp库）
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            if (reader.parse(appEventInfo.params, params)) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld",
                    params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.crash_type=%{public}s",
                    params["crash_type"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d",
                    params["foreground"].asBool());
                // 解析其他崩溃事件参数...
            }
        }
    }
}

// 注册onReceive类型观察者
static napi_value RegisterWatcherCrashEvent(napi_env env, napi_callback_info info)
{
    // 创建观察者
    systemEventWatcherR = OH_HiAppEvent_CreateWatcher("AppCrashWatcherR");
    if (systemEventWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置订阅的事件（崩溃事件）
    const char *names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set app event filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    // 设置onReceive回调
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceiveCrashEvent);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set watcher onReceive, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    // 配置崩溃事件采集参数
    HiAppEvent_Config* config = OH_HiAppEvent_CreateConfig();
    if (config != nullptr) {
        // 开启寄存器扩展内存打印
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_EXTEND_PC_LR_PRINTING, "true");
        // 设置日志截断大小为2MB
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_LOG_FILE_CUTOFF_SZ_BYTES, "2097152");
        // 开启简化VMA映射信息打印
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_SIMPLIFY_VMA_PRINTING, "true");
        // 开启拼接应用日志
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_MERGE_CPPCRASH_APP_LOG, "true");
        // native崩溃场景，使能minidump
        OH_HiAppEvent_SetConfigItem(config, OH_APP_CRASH_PARAM_COLLECT_MINIDUMP, "true");
        
        // 应用配置到崩溃事件
        result = OH_HiAppEvent_SetEventConfig(EVENT_APP_CRASH, config);
        if (result == HIAPPEVENT_SUCCESS) {
            OH_LOG_INFO(LogType::LOG_APP, "Successfully set APP_CRASH event configurations.");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event config, error=%{public}d", result);
        }
        
        // 销毁配置对象
        OH_HiAppEvent_DestroyConfig(config);
    }
    
    // 添加观察者，开始监听崩溃事件
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Successfully registered crash event watcher");
    return {};
}
```

**onTrigger类型观察者示例**：
```cpp
// 定义OnTake回调函数（用于处理获取的崩溃事件）
static void OnTakeCrash(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnTrigger");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            if (domain == DOMAIN_OS && name == EVENT_APP_CRASH) {
                // 解析崩溃事件参数...
            }
        }
    }
}

// 定义OnTrigger回调函数（触发条件满足时调用）
static void OnTriggerCrash(int row, int size)
{
    // 获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTakeCrash);
}

// 注册onTrigger类型观察者
static napi_value RegisterWatcherClickCrash(napi_env env, napi_callback_info info)
{
    // 创建观察者
    systemEventWatcherT = OH_HiAppEvent_CreateWatcher("AppCrashWatcherT");
    if (systemEventWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置订阅的事件（崩溃事件）
    const char *names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set app event filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    // 设置onTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTriggerCrash);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set watcher onTrigger, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    // 设置触发条件：新增事件数量为1个时触发回调
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    // 添加观察者，开始监听崩溃事件
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Successfully registered crash event watcher with trigger");
    return {};
}
```

### 步骤3：注册为ArkTS接口

**napi_init.cpp示例**：
```cpp
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherCrashEvent", nullptr, RegisterWatcherCrashEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerWatcherClickCrash", nullptr, RegisterWatcherClickCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcherCrash", nullptr, RemoveWatcherCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcherCrash", nullptr, DestroyWatcherCrash, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**index.d.ts示例**：
```typescript
export const registerWatcherCrashEvent: () => void;
export const registerWatcherClickCrash: () => void;
export const removeWatcherCrash: () => void;
export const destroyWatcherCrash: () => void;
```

### 步骤4：在Ability中调用

**EntryAbility.ets示例**：
```typescript
// 在onCreate()函数中添加C API接口调用
// 启动时，注册崩溃事件观察者
testNapi.registerWatcherClickCrash();
testNapi.registerWatcherCrashEvent();
```

### 步骤5：错误处理

**移除观察者示例**：
```cpp
static napi_value RemoveWatcherCrash(napi_env env, napi_callback_info info)
{
    // 使观察者停止监听崩溃事件
    if (systemEventWatcherR != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcherR);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher R, error=%{public}d", result);
        }
    }
    
    if (systemEventWatcherT != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcherT);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher T, error=%{public}d", result);
        }
    }
    
    return {};
}
```

**销毁观察者示例**：
```cpp
static napi_value DestroyWatcherCrash(napi_env env, napi_callback_info info)
{
    // 销毁创建的观察者，并置指针为nullptr
    if (systemEventWatcherR != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
    }
    
    if (systemEventWatcherT != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Successfully destroyed crash event watchers");
    return {};
}
```

### 步骤6：降级处理

**异常处理示例**：
```cpp
// 在回调函数中捕获异常
static void OnReceiveCrashEvent(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups,
    uint32_t groupLen)
{
    try {
        // 处理崩溃事件...
        for (int i = 0; i < groupLen; ++i) {
            for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
                // 解析事件参数
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                if (!reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    OH_LOG_WARN(LogType::LOG_APP, "Failed to parse event params");
                    continue;  // 降级：跳过解析失败的事件
                }
                // 处理事件...
            }
        }
    } catch (const std::exception& e) {
        OH_LOG_ERROR(LogType::LOG_APP, "Exception in OnReceiveCrashEvent: %{public}s", e.what());
        // 降级：记录异常但不影响崩溃事件采集
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| -1 | 非法的事件名称 | 检查事件名称是否符合规范：首字符为字母或$，中间为数字、字母或下划线，结尾为数字或字母，长度不超过48字符 |
| -4 | 非法的事件领域名称 | 检查domain参数是否为DOMAIN_OS |
| -5 | watcher入参空指针 | 检查观察者指针是否有效，是否已通过OH_HiAppEvent_CreateWatcher创建 |
| -6 | 还未调用OH_HiAppEvent_AddWatcher | 确保在调用OH_HiAppEvent_TakeWatcherData前已添加观察者 |
| -7 | 事件处理者为空 | 检查Processor对象是否有效 |
| -8 | 事件处理者不存在 | 检查Processor对象是否已创建 |
| -9 | 参数值无效 | 检查配置参数值是否符合规范 |
| -10 | 事件配置为空 | 检查Config对象是否已创建 |
| -100 | 操作失败 | 检查参数和调用顺序，参考API文档 |
| -200 | 无效的用户标识 | 检查UID参数是否有效 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
add_library(entry SHARED napi_init.cpp)

# 新增动态库依赖libhiappevent_ndk.z.so和libhilog_ndk.z.so
target_link_libraries(entry PUBLIC libace_napi.z.so libhilog_ndk.z.so libhiappevent_ndk.z.so)

# 配置jsoncpp三方库
set(GZ_FILE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/src/jsoncpp-1.9.6.tar.gz")
set(DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR})
execute_process(COMMAND tar -xzf ${GZ_FILE} -C ${DEST_DIR} WORKING_DIRECTORY ${DEST_DIR})
target_link_libraries(entry PRIVATE ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so)
target_include_directories(entry PRIVATE ${DEST_DIR}/jsoncpp-1.9.6/include/json)
```

**jsoncpp下载**：
- 下载地址：https://github.com/open-source-parsers/jsoncpp/archive/refs/tags/1.9.6.tar.gz
- 示例工程：https://gitcode.com/openharmony/applications_app_samples/tree/master/code/DocsSample/PerformanceAnalysisKit/HiAppEvent/EventSub

### 环境要求
- HarmonyOS SDK：API version 12及以上
- DevEco Studio：3.1及以上
- C++编译器：支持C++11标准
- jsoncpp库：1.9.6版本

### 常见编译问题

**问题1：找不到hiappevent头文件**
```
fatal error: hiappevent/hiappevent.h: No such file or directory
```
**解决方法**：
- 确保HarmonyOS SDK已正确安装
- 检查CMakeLists.txt中是否正确配置了头文件搜索路径
- 确保工程为Native C++工程

**问题2：找不到jsoncpp库**
```
undefined reference to `Json::Reader::parse'
```
**解决方法**：
- 下载jsoncpp库文件并放置在thirdparty/jsoncpp目录
- 在CMakeLists.txt中正确配置jsoncpp库的链接路径和头文件路径
- 确保jsoncpp版本为1.9.6

**问题3：动态库链接失败**
```
cannot find -lhiappevent_ndk.z
```
**解决方法**：
- 检查HarmonyOS SDK安装路径
- 确保target_link_libraries中正确添加libhiappevent_ndk.z.so
- 检查OHOS_ARCH变量是否正确设置

**问题4：观察者名称重复**
```
订阅接口传入的名称name是唯一的，相同的name，后一次调用会覆盖前一次的订阅
```
**解决方法**：
- 为每个观察者使用不同的名称
- 在创建观察者前检查是否已存在同名观察者
- 使用不同的观察者名称前缀（如"AppCrashWatcherR"、"AppCrashWatcherT"）

## 常见问题与解决方法

### Q1：崩溃事件回调时机不确定
**原因**：
- 应用未主动捕获崩溃异常：崩溃事件在应用下次启动时回调
- 应用主动捕获崩溃异常（通过errorManager.on）：崩溃事件在应用退出前回调

**解决方法**：
- 在应用启动时（Ability onCreate）立即注册崩溃事件观察者
- 区分两种回调场景，分别处理
- 从API version 21开始，可使用FaultLogExtensionAbility订阅事件进行延迟上报

### Q2：无法订阅到崩溃事件
**原因**：
- 未在应用启动时注册观察者
- 观察者名称重复
- 事件过滤规则设置错误

**解决方法**：
- 确保在Ability onCreate中注册观察者
- 使用不同的观察者名称
- 检查OH_HiAppEvent_SetAppEventFilter参数：domain=DOMAIN_OS、names={EVENT_APP_CRASH}

### Q3：崩溃事件参数解析失败
**原因**：
- jsoncpp库未正确配置
- json字符串格式错误
- 回调函数中异常未捕获

**解决方法**：
- 确保jsoncpp库正确配置和链接
- 使用Json::Features::strictMode()进行严格解析
- 在回调函数中添加try-catch异常捕获

### Q4：NativeCrash崩溃事件采集耗时过长
**原因**：
- NativeCrash采用进程外采集故障信息，平均耗时约2秒
- 受业务线程数量和进程间通信影响

**解决方法**：
- 理解NativeCrash采集机制为异步上报，不阻塞当前业务
- 调整崩溃事件采集配置参数（如开启minidump、简化VMA映射信息）
- 在性能敏感场景，可减少崩溃事件的详细参数采集

### Q5：崩溃日志文件路径不确定
**原因**：
- 崩溃日志文件路径由系统自动生成
- external_log参数包含日志文件路径数组

**解决方法**：
- 在崩溃事件回调中解析external_log参数，获取日志文件路径
- 日志文件路径格式：/data/storage/el2/log/hiappevent/APP_CRASH_[timestamp]_[pid].log
- minidump文件路径格式：/data/storage/el2/log/hiappevent/APP_CRASH_[timestamp]_[pid].dmp

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherRegistered": true,
  "watcherName": "AppCrashWatcherR/AppCrashWatcherT",
  "eventSubscribed": "EVENT_APP_CRASH",
  "configApplied": {
    "extend_pc_lr_printing": "true",
    "log_file_cutoff_sz_bytes": "2097152",
    "simplify_vma_printing": "true",
    "merge_cppcrash_app_log": "true",
    "collect_minidump": "true"
  },
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_SetWatcherOnTrigger",
    "OH_HiAppEvent_SetTriggerCondition",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher",
    "OH_HiAppEvent_CreateConfig",
    "OH_HiAppEvent_SetConfigItem",
    "OH_HiAppEvent_SetEventConfig",
    "OH_HiAppEvent_DestroyConfig",
    "OH_HiAppEvent_TakeWatcherData"
  ]
}
```

## 参考文档

- [API开发指南：订阅崩溃事件（C/C++）](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-crash-events-ndk)
- [API参考：HiAppEvent模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent)
- [API参考：hiappevent.h头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [API参考：hiappevent_param.h头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-param-h)
- [API参考：hiappevent_cfg.h头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-cfg-h)

## 完整示例代码

- [C++示例代码（onReceive类型观察者）](assets/example_crash_event_watcher_onreceive.cpp)
- [C++示例代码（onTrigger类型观察者）](assets/example_crash_event_watcher_ontrigger.cpp)
- [ArkTS示例代码（Ability调用）](assets/example_ability_crash_event.ets)
- [CMakeLists.txt配置示例](assets/example_cmakelists.txt)
- [index.d.ts接口定义示例](assets/example_index.d.ts)

## 测试用例

### 正向测试用例
- [测试正常订阅崩溃事件](tests/test_positive.cpp)：在应用启动时注册观察者，触发崩溃事件后验证回调
- [测试配置崩溃事件采集参数](tests/test_config_positive.cpp)：设置崩溃事件配置参数，验证配置生效

### 边界测试用例
- [测试观察者名称边界](tests/test_boundary.cpp)：测试观察者名称长度为48字符（最大值）
- [测试崩溃事件参数数量边界](tests/test_params_boundary.cpp)：测试崩溃事件参数数量为32个（最大值）

### 异常测试用例
- [测试观察者创建失败](tests/test_exception.cpp)：测试观察者名称为nullptr或非法名称
- [测试API调用顺序错误](tests/test_sequence_exception.cpp)：测试未调用OH_HiAppEvent_AddWatcher前调用OH_HiAppEvent_TakeWatcherData
- [测试回调函数异常](tests/test_callback_exception.cpp)：测试回调函数中发生异常，验证不影响崩溃事件采集