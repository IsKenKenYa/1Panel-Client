---
name: hmos-hiappevent-freeze-watch
description: 使用HiAppEvent C API订阅应用冻屏事件，支持onReceive实时接收和onTrigger触发回调两种模式，最大事件参数8KB，适用于应用稳定性监控、故障诊断场景
---

# 订阅应用冻屏事件（C/C++）技能

## 功能描述

本技能实现使用HiAppEvent提供的C/C++接口订阅应用冻屏事件（APP_FREEZE）。通过创建事件观察者（Watcher），开发者可以实时监听应用冻屏事件，获取详细的崩溃信息包括时间戳、进程信息、异常类型、内存状态等，用于应用稳定性分析和故障诊断。

**核心功能**：
- 创建和配置HiAppEvent事件观察者
- 订阅系统应用冻屏事件（DOMAIN_OS/EVENT_APP_FREEZE）
- 支持两种回调模式：onReceive实时接收、onTrigger触发回调
- 解析冻屏事件参数获取崩溃详情
- 正确管理观察者生命周期（添加、移除、销毁）

**技术限制**：
- 事件参数字符串最大长度：8*1024字符（超出会被丢弃）
- 参数个数限制：32个以内
- 数组参数元素个数：100以内
- API版本要求：HiAppEvent C API起始版本为12
- 需要链接动态库：libhiappevent_ndk.z.so、libhilog_ndk.z.so

## 使用场景

### 触发词
- "订阅应用冻屏事件"
- "监听应用卡顿"
- "应用无响应事件"
- "APP_FREEZE事件"
- "应用冻屏监控"
- "应用崩溃事件订阅C++"
- "HiAppEvent冻屏"

### 能做
- 创建应用冻屏事件观察者并订阅系统事件
- 配置onReceive回调实时接收冻屏事件
- 配置onTrigger回调按条件触发事件处理
- 解析冻屏事件的详细参数信息
- 在Native C++工程中集成HiAppEvent订阅功能
- 完整管理观察者生命周期（添加、移除、销毁）

### 绝不做
- 不处理非冻屏类型的系统事件
- 不在主线程执行耗时的回调处理（影响性能）
- 不直接缓存回调中的指针（生命周期仅限回调内）
- 不重复创建相同名称的观察者（会覆盖）
- 不替代ArkTS HiAppEvent订阅功能（仅C/C++）

### 补充
- 冻屏事件属于系统事件，领域为DOMAIN_OS，事件名为EVENT_APP_FREEZE
- 需要导入jsoncpp库解析事件参数中的JSON字符串
- 建议在应用启动时注册观察者（如EntryAbility.onCreate）
- 触发冻屏事件可通过代码模拟（如死循环）
- 对于无法启动的应用，可使用FaultLogExtensionAbility进行延迟上报

## 调用规范和规则

### 输入约束
- 观察者名称：非空字符串，唯一标识（重复名称会覆盖）
- 事件领域：DOMAIN_OS（系统事件领域）
- 事件名称：EVENT_APP_FREEZE（冻屏事件）
- 事件类型：故障类型（EventType=1）
- JSON解析器：必须使用jsoncpp库，严格模式解析

### 执行约束
- 回调处理最大耗时：建议<100ms（避免阻塞）
- 参数校验：事件参数字符串长度≤8KB
- 内存管理：必须销毁观察者释放内存（防止泄漏）
- 线程选择：AddWatcher涉及I/O，性能敏感场景应在子线程调用
- 最大观察者数量：建议≤10个（避免资源浪费）

### 内容约束
- 禁止生成：非冻屏事件的订阅代码
- 禁止高危函数：不使用eval、exec等动态执行
- 禁止操作：不直接缓存回调指针、不跨线程传递事件对象
- 参数校验：必须校验观察者指针有效性（nullptr检查）

### 降级约束
- jsoncpp解析失败：记录日志并跳过该事件
- 观察者创建失败：检查名称有效性并提示用户
- 回调超时：异步处理或降级为离线分析
- 应用无法启动：引导使用FaultLogExtensionAbility

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证工程类型为Native C++工程
2. 确认已导入jsoncpp库（json.h、json-forwards.h、jsoncpp.cpp）
3. 检查CMakeLists.txt配置正确（链接libhiappevent_ndk.z.so）
4. 验证开发环境API版本≥12（HiAppEvent C API起始版本）

**参数准备**：
```cpp
// 导入必要头文件
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

// 定义日志标签
#undef LOG_TAG
#define LOG_TAG "FreezeWatcher"

// 定义观察者指针（用于缓存）
static HiAppEvent_Watcher *freezeEventWatcher = nullptr;
```

### 步骤2：创建观察者并设置过滤器

**示例代码（onReceive模式）**：
```cpp
// 定义onReceive回调函数
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 检查是否为冻屏事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_FREEZE) == 0) {
                
                // 解析事件参数（JSON格式）
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    // 提取关键信息
                    auto time = params["time"].asInt64();
                    auto foreground = params["foreground"].asBool();
                    auto processName = params["process_name"].asString();
                    auto pid = params["pid"].asInt();
                    auto exception = params["exception"]["name"].asString();
                    
                    OH_LOG_INFO(LogType::LOG_APP, "Freeze detected: time=%{public}lld, process=%{public}s, pid=%{public}d", 
                                time, processName.c_str(), pid);
                    OH_LOG_INFO(LogType::LOG_APP, "Exception type: %{public}s", exception.c_str());
                    
                    // 详细参数提取
                    auto hilogSize = params["hilog"].size();
                    auto memory = params["memory"]["pss"].asInt();
                    OH_LOG_INFO(LogType::LOG_APP, "Hilog entries: %{public}d, PSS memory: %{public}d KB", 
                                hilogSize, memory);
                } else {
                    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse freeze event params");
                }
            }
        }
    }
}

// 创建并配置观察者
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 创建观察者（名称唯一）
    freezeEventWatcher = OH_HiAppEvent_CreateWatcher("freezeReceiverWatcher");
    if (freezeEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置事件过滤器（订阅冻屏事件）
    const char *names[] = {EVENT_APP_FREEZE};
    int result = OH_HiAppEvent_SetAppEventFilter(freezeEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    // 设置onReceive回调（实时接收）
    result = OH_HiAppEvent_SetWatcherOnReceive(freezeEventWatcher, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    // 添加观察者（开始监听）
    result = OH_HiAppEvent_AddWatcher(freezeEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Freeze event watcher registered successfully");
    return {};
}
```

**示例代码（onTrigger模式）**：
```cpp
// 定义OnTake回调（获取保存的事件）
static void OnTake(const char *const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            if (domain == DOMAIN_OS && name == EVENT_APP_FREEZE) {
                auto time = eventInfo["time"].asInt64();
                auto processName = eventInfo["process_name"].asString();
                auto exception = eventInfo["exception"]["name"].asString();
                
                OH_LOG_INFO(LogType::LOG_APP, "Frozen event retrieved: time=%{public}lld, process=%{public}s", 
                            time, processName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "Exception: %{public}s", exception.c_str());
            }
        }
    }
}

// 定义OnTrigger回调（触发条件满足时调用）
static void OnTrigger(int row, int size) {
    OH_LOG_INFO(LogType::LOG_APP, "Triggered with %{public}d events, size=%{public}d", row, size);
    
    // 获取保存的事件数据
    OH_HiAppEvent_TakeWatcherData(freezeEventWatcher, row, OnTake);
}

// 创建并配置观察者（onTrigger模式）
static napi_value RegisterTriggerWatcher(napi_env env, napi_callback_info info) {
    freezeEventWatcher = OH_HiAppEvent_CreateWatcher("freezeTriggerWatcher");
    if (freezeEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create trigger watcher");
        return {};
    }
    
    // 设置事件过滤器
    const char *names[] = {EVENT_APP_FREEZE};
    int result = OH_HiAppEvent_SetAppEventFilter(freezeEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Filter setup failed, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    // 设置onTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(freezeEventWatcher, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "OnTrigger setup failed, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    // 设置触发条件：新增1个事件时触发
    result = OH_HiAppEvent_SetTriggerCondition(freezeEventWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Trigger condition setup failed, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    // 添加观察者
    result = OH_HiAppEvent_AddWatcher(freezeEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Add watcher failed, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Trigger watcher registered successfully");
    return {};
}
```

### 步骤3：注册为ArkTS接口

**示例代码**：
```cpp
// 注册接口到ArkTS
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerFreezeWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

// index.d.ts接口定义
// export const registerFreezeWatcher: () => void;
```

### 步骤4：在ArkTS中调用

**示例代码**：
```typescript
// EntryAbility.ets
import freezeNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 应用启动时注册观察者
        freezeNapi.registerFreezeWatcher();
        hilog.info(0x0000, 'FreezeTag', 'Freeze watcher registered');
    }
}
```

### 步骤5：触发冻屏事件（测试）

**示例代码**：
```typescript
// Index.ets
Button("触发冻屏")
    .onClick(() => {
        // 模拟应用卡顿（死循环）
        setTimeout(() => {
            while(true) {}  // 触发APP_FREEZE事件
        }, 1000);
    });
```

### 步骤6：移除和销毁观察者

**示例代码**：
```cpp
// 移除观察者（停止监听）
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (freezeEventWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(freezeEventWatcher);
        if (result == 0) {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Remove failed, error=%{public}d", result);
        }
    }
    return {};
}

// 销毁观察者（释放内存）
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (freezeEventWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(freezeEventWatcher);
        freezeEventWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed and memory released");
    }
    return {};
}
```

### 步骤7：错误处理

```cpp
// 统一错误处理函数
static void HandleAppEventError(int errorCode, const char* operation) {
    switch (errorCode) {
        case 0:
            OH_LOG_INFO(LogType::LOG_APP, "%{public}s succeeded", operation);
            break;
        case -1:
            OH_LOG_ERROR(LogType::LOG_APP, "%{public}s failed: invalid event name", operation);
            break;
        case -4:
            OH_LOG_ERROR(LogType::LOG_APP, "%{public}s failed: invalid domain", operation);
            break;
        case -5:
            OH_LOG_ERROR(LogType::LOG_APP, "%{public}s failed: watcher is null", operation);
            break;
        case -6:
            OH_LOG_ERROR(LogType::LOG_APP, "%{public}s failed: watcher not added yet", operation);
            break;
        default:
            OH_LOG_ERROR(LogType::LOG_APP, "%{public}s failed: unknown error %{public}d", operation, errorCode);
    }
}
```

### 步骤8：降级处理

```cpp
// JSON解析失败降级
static void ParseEventParamsSafe(const char* paramsJson) {
    Json::Value params;
    Json::Reader reader(Json::Features::strictMode());
    
    if (!reader.parse(paramsJson, params)) {
        OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed, using fallback");
        // 降级方案：记录原始JSON字符串供离线分析
        OH_LOG_WARN(LogType::LOG_APP, "Raw params: %{public}s", paramsJson);
        return;
    }
    
    // 正常解析流程
    try {
        auto time = params["time"].asInt64();
        OH_LOG_INFO(LogType::LOG_APP, "Event time: %{public}lld", time);
    } catch (...) {
        OH_LOG_ERROR(LogType::LOG_APP, "Parameter extraction failed");
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| -1 | 非法的事件名称 | 检查事件名称格式（字母开头，不超过48字符） |
| -4 | 非法的事件领域名称 | 检查领域名称格式（字母开头，不超过32字符） |
| -5 | watcher入参空指针 | 检查观察者指针是否有效（CreateWatcher返回值） |
| -6 | 未调用OH_HiAppEvent_AddWatcher | 先调用AddWatcher再调用RemoveWatcher/TakeWatcherData |
| 1 | 非法的事件参数名称 | 检查参数名称格式（字母或$开头，不超过32字符） |
| 4 | 非法的事件参数字符串长度 | 减少参数字符串长度至8KB以内 |
| 5 | 非法的事件参数数量 | 减少参数数量至32个以内 |
| 6 | 非法的事件参数数组长度 | 减少数组元素个数至100以内 |
| 8 | 重复的事件参数名称 | 移除重复的参数定义 |
| -99 | 打点功能被关闭 | 检查HiAppEvent配置（DISABLE参数） |
| -100 | 操作失败 | 检查系统状态和权限配置 |
| -200 | 无效的用户标识 | 检查应用权限和UID配置 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 添加源文件（包含jsoncpp）
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 链接动态库
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

**jsoncpp文件导入**：
- 从 https://github.com/open-source-parsers/jsoncpp 下载源码
- 按README的 Amalgamated source 步骤生成三个文件：
  - jsoncpp.cpp
  - json.h
  - json-forwards.h

### 环境要求
- HarmonyOS SDK版本：≥API 12（HiAppEvent C API起始版本）
- DevEco Studio版本：≥3.1
- 编译工具：clang编译器（支持C++11及以上）
- jsoncpp库：版本≥1.9.0

### 常见编译问题

**问题1：找不到hiappevent.h头文件**
```
error: 'hiappevent/hiappevent.h' file not found
```
**解决方法**：
- 检查SDK路径配置，确保包含HiAppEvent头文件
- 在DevEco Studio中安装完整的Native SDK包
- 确认工程类型为Native C++工程

**问题2：链接libhiappevent_ndk.z.so失败**
```
error: undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**：
- 在CMakeLists.txt中添加 `libhiappevent_ndk.z.so` 链接
- 检查NDK库路径是否正确配置

**问题3：jsoncpp编译错误**
```
error: 'Json::Value' has incomplete type
```
**解决方法**：
- 确保导入完整的json.h和json-forwards.h
- 检查jsoncpp.cpp是否添加到编译源文件列表

**问题4：回调函数生命周期问题**
```
warning: pointer points to object whose lifetime is limited
```
**解决方法**：
- 在回调函数内深拷贝指针指向的内容
- 不要将回调指针保存到全局变量
- 使用JSON字符串拷贝而非直接引用

## 常见问题与解决方法

### Q1：观察者创建失败返回nullptr
**原因**：观察者名称无效或内存不足
**解决方法**：
- 检查名称是否为非空字符串
- 确认名称符合命名规范（字母开头）
- 检查系统内存状态
- 避免创建过多观察者

### Q2：未接收到冻屏事件
**原因**：事件过滤器配置错误或未触发冻屏
**解决方法**：
- 验证事件领域为DOMAIN_OS
- 确认事件名称为EVENT_APP_FREEZE
- 检查AddWatcher是否调用成功
- 确认应用确实发生了冻屏（主线程卡顿6秒）

### Q3：JSON解析失败
**原因**：事件参数格式错误或字符串过长
**解决方法**：
- 使用Json::Features::strictMode()严格解析
- 检查params字符串长度是否≤8KB
- 记录原始JSON字符串供离线分析
- 添加异常捕获处理解析错误

### Q4：观察者未正确销毁导致内存泄漏
**原因**：忘记调用DestroyWatcher或指针未置空
**解决方法**：
- 在应用退出时调用DestroyWatcher
- 销毁后立即将指针置为nullptr
- 使用RAII模式管理观察者生命周期
- 添加内存泄漏检测工具

### Q5：AddWatcher性能影响
**原因**：在主线程执行I/O操作
**解决方法**：
- 在子线程调用AddWatcher
- 使用异步任务注册观察者
- 避免在高频回调中重复添加
- 优化回调处理逻辑（减少耗时）

### Q6：相同名称观察者覆盖问题
**原因**：多次创建相同名称的观察者
**解决方法**：
- 使用唯一的观察者名称
- 创建前先检查是否已存在
- 使用命名规范：{module}_{function}_{timestamp}
- 移除旧观察者后再创建新观察者

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcher_name": "freezeReceiverWatcher",
  "event_subscribed": "APP_FREEZE",
  "api_used": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ],
  "event_params_parsed": {
    "time": "1502049167732",
    "foreground": true,
    "process_name": "com.example.myapplication",
    "pid": 1587,
    "exception": "THREAD_BLOCK_6S",
    "memory_pss": 0,
    "hilog_size": 6
  },
  "memory_released": true
}
```

## 参考文档

- [订阅应用冻屏事件开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-freeze-events-ndk)
- [hiappevent.h API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [HiAppEvent模块概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent)
- [使用FaultLogExtensionAbility订阅事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/fault-log-extension-app-events-arkts)

## 完整示例代码

- [C++示例代码（onReceive模式）](assets/example_freeze_receiver.cpp)
- [C++示例代码（onTrigger模式）](assets/example_freeze_trigger.cpp)
- [CMakeLists.txt配置示例](assets/cmakelists_template.txt)
- [ArkTS接口调用示例](assets/example_entry_ability.ets)

## 测试用例

### 正向测试用例
- [创建观察者订阅冻屏事件](tests/test_positive_create.cpp)：验证观察者创建成功
- [接收冻屏事件回调](tests/test_positive_receive.cpp)：验证事件回调触发
- [解析事件参数](tests/test_positive_parse.cpp)：验证JSON解析正确性
- [销毁观察者](tests/test_positive_destroy.cpp)：验证内存释放

### 边界测试用例
- [事件参数最大长度](tests/test_boundary_param_length.cpp)：测试8KB参数字符串
- [参数数量最大值](tests/test_boundary_param_count.cpp)：测试32个参数
- [回调并发处理](tests/test_boundary_concurrent.cpp)：测试多事件同时触发

### 异常测试用例
- [观察者名称为空](tests/test_exception_empty_name.cpp)：验证nullptr返回
- [重复创建观察者](tests/test_exception_duplicate.cpp)：验证覆盖行为
- [JSON解析失败](tests/test_exception_parse_fail.cpp)：验证降级处理
- [未调用AddWatcher](tests/test_exception_not_added.cpp)：验证-6错误码