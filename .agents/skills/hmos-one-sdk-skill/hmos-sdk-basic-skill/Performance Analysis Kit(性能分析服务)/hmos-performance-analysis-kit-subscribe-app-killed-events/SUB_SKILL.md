---
name: hmos-performance-analysis-kit-subscribe-app-killed-events
description: 订阅应用终止事件，接收系统终止应用的通知，包含事件观察者创建、事件过滤、回调处理、监听管理等功能，适用于C/C++开发场景
---

# 订阅应用终止事件技能

## 功能描述

本技能提供在HarmonyOS应用中订阅应用终止事件的能力。通过HiAppEvent API，开发者可以创建事件观察者，监听系统终止应用的事件，获取终止原因、时间、前后台状态等详细信息。适用于应用崩溃分析、性能监控、故障排查等场景。

应用终止是指应用程序被系统强制退出的一种现象，与应用崩溃不同，终止主要归因于系统基于资源管控策略而对应用实施的终止行为，如内存超限、线程泄漏、CPU高负载等。

## 使用场景

### 触发词
- "订阅应用终止事件"
- "监听应用被杀"
- "应用终止事件订阅"
- "APP_KILLED事件"
- "应用强制退出监控"
- "HiAppEvent订阅终止事件"

### 能做
- 创建和配置事件观察者，订阅应用终止事件
- 接收系统终止应用的通知，获取详细的终止原因
- 解析终止事件参数，包括时间、原因、前后台状态、应用版本等
- 处理多种终止原因，如LowMemoryKill、ResourceLeak、OomKiller等
- 提供完整的观察者生命周期管理，包括添加、移除、销毁

### 绝不做
- 不订阅其他系统事件（如主线程超时事件）
- 不处理应用崩溃事件（CppCrash、JsError等）
- 不替代崩溃分析工具的专业功能
- 不用于前台业务逻辑处理
- 不直接上报事件到云端（需额外配置Processor）

### 补充
- 仅支持Native C++开发，ArkTS开发请使用对应ArkTS API
- 需要导入jsoncpp库解析事件参数的JSON字符串
- 回调函数中指针的生命周期仅限于回调函数内，需深拷贝缓存数据
- 终止事件在应用下次启动时上报，非实时上报
- 从API version 20开始支持，API version 24新增app_running_unique_id和bundle_version参数

## 调用规范和规则

### 输入约束
- 观察者名称：字符串，非空，用于识别不同观察者
- 事件领域：DOMAIN_OS（系统事件领域）
- 事件名称：EVENT_APP_KILLED（应用终止事件）
- 事件类型：可设置为0（所有类型）或指定类型值
- 回调函数：必须实现OnReceive回调，接收事件组数据

### 执行约束
- 创建观察者后必须设置过滤器和回调
- 添加观察者后才开始监听事件
- 移除观察者仅停止监听，不释放内存
- 销毁观察者必须先移除，避免内存泄漏
- 销毁后必须将观察者指针置为nullptr

### 内容约束
- 禁止在回调函数外直接使用回调中的指针
- 禁止使用相同的观察者名称添加多个观察者（会覆盖）
- 禁止在未添加观察者前销毁观察者
- 禁止在回调函数中执行耗时操作（会影响事件处理）
- 禁止订阅非系统事件领域的事件

### 降级约束
- 观察者创建失败：返回nullptr，需检查名称参数
- 过滤器设置失败：返回负值错误码，检查domain和names参数
- 回调设置失败：返回-5，检查watcher指针
- 添加观察者失败：返回-5，检查watcher指针
- JSON解析失败：使用try-catch捕获，跳过该事件处理

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认使用Native C++开发环境
2. 确认已导入jsoncpp库（用于解析JSON字符串）
3. 确认已导入libhiappevent_ndk.z.so和libhilog_ndk.z.so
4. 确认API version >= 20

**参数准备**：
```cpp
// 导入必要的头文件
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"
#include <thread>

// 定义LOG_TAG用于日志输出
#undef LOG_TAG
#define LOG_TAG "AppKilledEventWatcher"

// 定义观察者指针，用于缓存创建的观察者
static HiAppEvent_Watcher *systemEventWatcher = nullptr;
```

**CMakeLists.txt配置**：
```cmake
# 添加源文件（包括jsoncpp.cpp用于解析JSON）
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 添加动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

### 步骤2：实现回调函数

**示例代码**：
```cpp
/**
 * OnReceive回调函数
 * 接收事件组数据，解析应用终止事件参数
 * 
 * @param domain 事件领域
 * @param appEventGroups 事件组数组
 * @param groupLen 事件组数组长度
 */
static void OnReceive(const char *domain, 
                      const struct HiAppEvent_AppEventGroup *appEventGroups, 
                      uint32_t groupLen) {
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 输出事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s",
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s",
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d",
                        appEventGroups[i].appEventInfos[j].type);
            
            // 检查是否为应用终止事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_KILLED) == 0) {
                
                // 解析事件参数JSON字符串
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    // 提取事件参数
                    auto time = params["time"].asInt64();
                    auto reason = params["reason"].asString();
                    auto foreground = params["foreground"].asString();
                    auto appRunningUniqueId = params["app_running_unique_id"].asString();
                    auto bundleVersion = params["bundle_version"].asString();
                    
                    // 输出事件参数日志
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.reason=%{public}s",
                                reason.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}s",
                                foreground.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.app_running_unique_id=%{public}s",
                                appRunningUniqueId.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s",
                                bundleVersion.c_str());
                    
                    // 根据终止原因进行业务处理
                    // 开发者可以在此处添加自定义处理逻辑
                    // 例如：上报到服务器、记录到文件、触发告警等
                } else {
                    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event params JSON");
                }
            }
        }
    }
}
```

### 步骤3：创建并注册观察者

**示例代码**：
```cpp
/**
 * 创建并注册事件观察者
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value
 */
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent RegisterWatcher");
    
    // 1. 创建观察者
    // 开发者自定义观察者名称，系统根据不同的名称来识别不同的观察者
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onReceiverWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 2. 设置事件过滤器
    // 设置订阅的事件为EVENT_APP_KILLED
    const char *names[] = {EVENT_APP_KILLED};
    // 开发者订阅感兴趣的事件，此处订阅了系统事件
    // DOMAIN_OS: 系统事件领域
    // 0: 所有事件类型（也可以指定具体类型值）
    // names: 事件名称数组
    // 1: 数组长度
    int ret = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (ret != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set app event filter, error=%{public}d", ret);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    // 3. 设置回调函数
    // 开发者设置已实现的回调函数，观察者接收到事件后会立即触发OnReceive回调
    ret = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    if (ret != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set watcher on receive, error=%{public}d", ret);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    // 4. 添加观察者，开始监听
    // 使观察者开始监听订阅的事件
    ret = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (ret != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", ret);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}
```

### 步骤4：移除观察者

**示例代码**：
```cpp
/**
 * 移除事件观察者
 * 仅停止监听，观察者仍常驻内存
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value
 */
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher is already null");
        return {};
    }
    
    // 使观察者停止监听事件
    int ret = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
    if (ret != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher, error=%{public}d", ret);
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
    }
    
    return {};
}
```

### 步骤5：销毁观察者

**示例代码**：
```cpp
/**
 * 销毁事件观察者
 * 释放内存，防止内存泄漏
 * 销毁后需将指针置为nullptr
 * 
 * @param env napi环境
 * @param info napi回调信息
 * @return napi_value
 */
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher == nullptr) {
        OH_LOG_WARN(LogType::LOG_APP, "Watcher is already null");
        return {};
    }
    
    // 销毁创建的观察者，并置systemEventWatcher为nullptr
    OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
    systemEventWatcher = nullptr;
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed successfully");
    return {};
}
```

### 步骤6：注册ArkTS接口

**示例代码**：
```cpp
/**
 * 初始化模块，注册ArkTS接口
 */
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeWatcher", nullptr, RemoveWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyWatcher", nullptr, DestroyWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**ArkTS接口定义**（index.d.ts）：
```typescript
export const registerWatcher: () => void;
export const removeWatcher: () => void;
export const destroyWatcher: () => void;
```

### 步骤7：ArkTS调用接口

**示例代码**：
```typescript
// 导入依赖模块
import testNapi from 'libentry.so';

// 在EntryAbility的onCreate()函数中注册观察者
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 启动时，注册系统事件观察者
        testNapi.registerWatcher();
        
        OH_LOG.info(LogType::LOG_APP, 'Ability onCreate');
    }
    
    onDestroy(): void {
        // 应用退出时，移除并销毁观察者
        testNapi.removeWatcher();
        testNapi.destroyWatcher();
        
        OH_LOG.info(LogType::LOG_APP, 'Ability onDestroy');
    }
}
```

### 步骤8：处理终止事件

**事件触发流程**：
1. 应用运行过程中触发资源超限或其他终止条件
2. 系统终止应用进程
3. 应用下次启动时，HiAppEvent上报终止事件
4. 观察者OnReceive回调被触发
5. 解析事件参数，获取终止原因等信息

**事件参数说明**：
| 参数名 | 类型 | 说明 | API版本 |
|--------|------|------|---------|
| time | number | 事件触发时间，单位为ms | 20+ |
| reason | string | 终止原因，详见reason字段说明 | 20+ |
| foreground | boolean | 应用是否处于前台状态 | 20+ |
| app_running_unique_id | string | 应用运行时唯一关联的id | 24+ |
| bundle_version | string | 应用版本信息 | 24+ |

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|--------|------|---------|
| 0 | 接口调用成功 | 正常执行 |
| -1 | names参数异常（事件名称数组无效） | 检查事件名称数组是否正确，确保EVENT_APP_KILLED宏定义正确 |
| -4 | domain参数异常（事件领域无效） | 检查DOMAIN_OS宏定义是否正确 |
| -5 | watcher入参空指针 | 检查观察者指针是否为nullptr，确保创建成功 |
| -6 | 操作顺序有误（未调用OH_HiAppEvent_AddWatcher） | 确保在调用TakeWatcherData前已添加观察者 |
| -9 | 参数值无效 | 检查传入的参数值是否符合要求 |
| -100 | 操作失败 | 检查系统状态，确认HiAppEvent功能正常 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置C++标准
set(CMAKE_CXX_STANDARD 17)

# 添加源文件
add_library(entry SHARED 
    napi_init.cpp 
    jsoncpp.cpp
)

# 添加动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)

# 添加头文件路径
target_include_directories(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}
)
```

**jsoncpp库导入**：
- 需要将jsoncpp源码导入到工程中，目录结构如下：
```
entry/src/main/cpp/
  - json/
    - json.h
    - json-forwards.h
  - jsoncpp.cpp
```

### 环境要求
- HarmonyOS SDK：API version 20及以上
- 开发工具：DevEco Studio 3.1及以上
- 编译工具：CMake 3.4.1及以上
- C++标准：C++17

### 常见编译问题

**问题1：找不到hiappevent头文件**
```
fatal error: 'hiappevent/hiappevent.h' file not found
```
**解决方法**：
1. 确认HarmonyOS SDK已正确安装
2. 在CMakeLists.txt中添加正确的头文件路径
3. 确认API version >= 12（hiappevent.h起始版本为8）

**问题2：jsoncpp编译错误**
```
error: 'Json::Value' has not been declared
```
**解决方法**：
1. 确认jsoncpp源码已正确导入工程
2. 确认json.h和json-forwards.h头文件存在
3. 确认jsoncpp.cpp已添加到CMakeLists.txt的源文件列表

**问题3：链接错误**
```
undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**：
1. 确认libhiappevent_ndk.z.so已添加到链接库列表
2. 确认HarmonyOS NDK已正确配置
3. 确认API version >= 12（CreateWatcher起始版本为12）

**问题4：运行时崩溃**
```
SIGSEGV: segmentation fault
```
**解决方法**：
1. 检查观察者指针是否为nullptr
2. 检查回调函数是否正确实现
3. 检查JSON解析是否成功，避免访问无效数据
4. 确认不在回调函数外使用回调中的指针

## 常见问题与解决方法

### Q1：为什么看不到终止事件日志？
**原因**：
1. 应用未被系统终止
2. 终止事件在下次启动时上报，需要重新打开应用
3. 观察者未正确注册或添加

**解决方法**：
- 触发应用终止条件（如内存泄漏）等待2-3分钟
- 重新打开应用，查看日志
- 检查RegisterWatcher是否在onCreate中调用

### Q2：JSON解析失败怎么办？
**原因**：
- params参数格式异常
- jsoncpp库版本不兼容
- params字符串为空

**解决方法**：
- 使用Json::Features::strictMode()严格模式解析
- 添加异常捕获，跳过无效事件
- 检查params是否为空字符串

### Q3：观察者名称冲突怎么办？
**原因**：
- 使用相同的观察者名称添加多个观察者会覆盖

**解决方法**：
- 使用不同的观察者名称区分不同观察者
- 在添加新观察者前，移除旧观察者
- 确认观察者名称的唯一性

### Q4：如何处理不同终止原因？
**原因**：
- 终止原因种类繁多，需针对性处理

**解决方法**：
- 查阅reason字段说明文档，了解各原因含义
- 根据业务需求，重点处理常见原因（如ResourceLeak、LowMemoryKill）
- 对特殊原因触发告警或特殊处理逻辑

### Q5：回调函数性能问题？
**原因**：
- 回调函数中执行耗时操作影响事件处理

**解决方法**：
- 回调函数仅做必要的数据解析和缓存
- 耗时业务处理异步执行（如使用线程）
- 避免在回调中访问IO或网络

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "eventType": "APP_KILLED",
  "eventDomain": "OS",
  "eventParams": {
    "time": 1717597063727,
    "reason": "RssThresholdKiller",
    "foreground": true,
    "app_running_unique_id": "207544",
    "bundle_version": "1000000"
  },
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ],
  "description": "应用终止事件订阅成功，事件观察者已创建并开始监听，终止事件将在下次应用启动时上报"
}
```

## 参考文档

- [应用终止事件介绍](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-app-killed-events)
- [HiAppEvent API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)

## 完整示例代码

- [C++完整示例](assets/example_complete.cpp)
- [CMakeLists.txt配置](assets/CMakeLists.txt)
- [ArkTS接口定义](assets/index.d.ts)
- [EntryAbility示例](assets/EntryAbility.ets)

## 测试用例

### 正向测试用例
- [正常订阅终止事件](tests/test_positive.cpp)：创建观察者、设置过滤器、添加观察者、接收事件
- [解析事件参数](tests/test_parse_params.cpp)：正确解析JSON参数，提取时间、原因等字段
- [完整生命周期](tests/test_lifecycle.cpp)：创建、添加、移除、销毁观察者完整流程

### 边界测试用例
- [多次添加移除](tests/test_boundary.cpp)：重复添加移除观察者，检查状态
- [大量事件处理](tests/test_many_events.cpp)：处理多个终止事件，检查内存和性能
- [API版本兼容](tests/test_api_version.cpp)：在不同API版本下测试功能

### 异常测试用例
- [空指针处理](tests/test_null_pointer.cpp)：传入nullptr，检查错误处理
- [JSON解析失败](tests/test_json_parse_error.cpp)：无效JSON字符串，检查异常捕获
- [重复销毁](tests/test_double_destroy.cpp)：销毁已销毁的观察者，检查崩溃