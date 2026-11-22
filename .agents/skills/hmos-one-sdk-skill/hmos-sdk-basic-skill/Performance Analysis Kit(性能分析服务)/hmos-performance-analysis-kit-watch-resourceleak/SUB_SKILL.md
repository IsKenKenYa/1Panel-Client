---
name: hmos-performance-analysis-kit-watch-resourceleak
description: 使用HiAppEvent C/C++接口订阅系统资源泄漏事件,支持onReceive和onTrigger两种回调模式,监听内存泄漏、文件描述符泄漏、线程泄漏等资源异常,最大支持订阅系统事件RESOURCE_OVERLIMIT,适用于应用性能调优和故障排查场景
---

# 订阅资源泄漏事件技能（C/C++）

## 功能描述

本技能提供使用HiAppEvent C/C++接口订阅系统资源泄漏事件的完整实现方案。支持两种回调模式:
- **onReceive模式**: 监听器接收到事件后立即触发回调,实时处理事件数据
- **onTrigger模式**: 监听器保存事件,满足触发条件后批量处理事件数据

可监听的资源泄漏类型:
- **pss_memory**: Native内存泄漏
- **js_heap**: JS堆内存泄漏
- **fd**: 文件描述符泄漏
- **thread**: 线程泄漏

## 使用场景

### 触发词
- "订阅资源泄漏事件"
- "监听内存泄漏"
- "检测资源泄漏"
- "HiAppEvent订阅系统事件"
- "资源泄漏事件订阅C++"

### 能做
- 创建并配置HiAppEvent监听器订阅系统资源泄漏事件
- 实现onReceive回调实时接收并处理事件数据
- 实现onTrigger回调批量获取并处理事件数据
- 解析资源泄漏事件的详细信息(内存、FD、线程等)
- 移除和销毁监听器释放资源
- 构造资源泄漏测试场景验证订阅功能

### 绝不做
- 不订阅非系统领域(DOMAIN_OS)的事件
- 不处理非RESOURCE_OVERLIMIT名称的事件
- 不在回调函数外直接使用回调中的指针(生命周期仅限回调内)
- 不重复调用OH_HiAppEvent_AddWatcher(相同name会覆盖)
- 不忘记销毁监听器(会导致内存泄漏)

### 补充
- 监听器名称必须唯一,相同名称的后一次订阅会覆盖前一次
- 回调函数中的指针生命周期仅限于回调函数内,需深拷贝才能缓存
- 同一应用24小时内至多上报一次资源泄漏事件,二次上报需重启设备
- OH_HiAppEvent_AddWatcher接口涉及I/O操作,性能敏感场景应考虑线程选择
- 需在"开发者选项"中打开"系统资源泄漏日志"并重启设备才能触发事件

## 调用规范和规则

### 输入约束
- 监听器名称: 字符串类型,必须唯一且非空
- 事件领域: 必须为DOMAIN_OS(系统事件)
- 事件名称: 必须为EVENT_RESOURCE_OVERLIMIT
- 回调函数: 必须实现OH_HiAppEvent_OnReceive或OH_HiAppEvent_OnTrigger
- 触发条件: 至少设置row、size或timeOut其中一个(仅onTrigger模式)

### 执行约束
- 监听器创建后必须调用OH_HiAppEvent_AddWatcher才能开始监听
- onTrigger模式下必须设置触发条件才能触发回调
- 移除监听器后必须销毁监听器才能释放内存
- 最大监听器数量: 无明确限制,但建议合理使用避免资源浪费
- 最大事件保存数量: 由OH_HiAppEvent_SetTriggerCondition的row参数控制

### 内容约束
- 禁止在回调函数外直接使用回调指针参数
- 禁止使用未初始化的监听器指针
- 禁止重复添加同名监听器
- 禁止在回调函数中进行耗时操作(影响事件处理性能)
- 必须对回调中的指针内容进行深拷贝才能缓存

### 降级约束
- 监听器创建失败: 检查name参数是否合法,返回nullptr时需处理
- API调用返回错误码: 根据错误码进行相应处理(-5为空指针,-1为参数异常等)
- 事件解析失败: json解析失败时需跳过该事件,继续处理后续事件
- 资源泄漏事件未触发: 检查开发者选项开关是否打开,是否重启设备

## 调用流程和步骤

### 步骤1: 准备阶段

**前置校验**:
1. 确认已创建Native C++工程
2. 确认已导入必要的头文件(hiappevent/hiappevent.h, hilog/log.h)
3. 确认已链接必要的动态库(libhiappevent_ndk.z.so, libhilog_ndk.z.so)
4. 确认已准备jsoncpp库用于解析事件数据

**参数准备**:
```cpp
// 导入必要头文件
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

// 定义LOG_TAG
#undef LOG_TAG
#define LOG_TAG "ResourceLeakWatcher"

// 定义监听器指针变量
static HiAppEvent_Watcher *systemEventWatcher = nullptr;
```

### 步骤2: 创建监听器

**示例代码**:
```cpp
// 创建监听器
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 开发者自定义观察者名称,系统根据不同名称识别不同观察者
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("ResourceLeakWatcher");
    
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置订阅的事件为EVENT_RESOURCE_OVERLIMIT
    const char *names[] = {EVENT_RESOURCE_OVERLIMIT};
    
    // 订阅系统事件(DOMAIN_OS领域)
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    // ... 继续设置回调
    
    return {};
}
```

### 步骤3: 设置回调函数

**onReceive模式示例**:
```cpp
// 定义OnReceive回调函数
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            // 处理资源泄漏事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_RESOURCE_OVERLIMIT) == 0) {
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    auto time = params["time"].asInt64();
                    auto pid = params["pid"].asInt();
                    auto uid = params["uid"].asInt();
                    auto resourceType = params["resourceType"].asString();
                    auto bundleName = params["bundle_name"].asString();
                    
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.resource_type=%{public}s", resourceType.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                    // ... 处理其他参数
                }
            }
        }
    }
}

// 设置OnReceive回调
int result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set OnReceive: %{public}d", result);
}
```

**onTrigger模式示例**:
```cpp
// 定义OnTake回调函数
static void OnTake(const char *const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            if (domain == DOMAIN_OS && name == EVENT_RESOURCE_OVERLIMIT) {
                auto time = eventInfo["time"].asInt64();
                auto pid = eventInfo["pid"].asInt();
                auto resourceType = eventInfo["resourceType"].asString();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.resource_type=%{public}s", resourceType.c_str());
                // ... 处理其他参数
            }
        }
    }
}

// 定义OnTrigger回调函数
static void OnTrigger(int row, int size) {
    // 接收回调后,获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcher, row, OnTake);
}

// 设置OnTrigger回调和触发条件
int result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcher, OnTrigger);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set OnTrigger: %{public}d", result);
}

// 设置触发条件:新增事件数量为1个时触发
result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcher, 1, 0, 0);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition: %{public}d", result);
}
```

### 步骤4: 添加监听器

**示例代码**:
```cpp
// 使观察者开始监听订阅的事件
int result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
    systemEventWatcher = nullptr;
} else {
    OH_LOG_INFO(LogType::LOG_APP, "Watcher added successfully");
}
```

### 步骤5: 移除和销毁监听器

**示例代码**:
```cpp
// 移除监听器
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher: %{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "Watcher removed successfully");
        }
    }
    return {};
}

// 销毁监听器
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher destroyed successfully");
    }
    return {};
}
```

### 步骤6: 错误处理

**错误处理代码**:
```cpp
// 错误码处理
void HandleErrorCode(int errorCode) {
    switch (errorCode) {
        case 0:
            OH_LOG_INFO(LogType::LOG_APP, "Operation succeeded");
            break;
        case -1:
            OH_LOG_ERROR(LogType::LOG_APP, "Invalid event name");
            break;
        case -4:
            OH_LOG_ERROR(LogType::LOG_APP, "Invalid domain name");
            break;
        case -5:
            OH_LOG_ERROR(LogType::LOG_APP, "Watcher is null pointer");
            break;
        case -6:
            OH_LOG_ERROR(LogType::LOG_APP, "Operation sequence error, need to call AddWatcher first");
            break;
        default:
            OH_LOG_ERROR(LogType::LOG_APP, "Unknown error: %{public}d", errorCode);
            break;
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 接口调用成功 | 无需处理 |
| -1 | names参数异常(names为空指针或非法) | 检查事件名称数组是否正确初始化 |
| -4 | domain参数异常(domain为空指针或非法) | 确认使用DOMAIN_OS作为领域 |
| -5 | watcher入参空指针 | 检查监听器指针是否有效,是否成功创建 |
| -6 | 还未调用OH_HiAppEvent_AddWatcher,操作顺序有误 | 先调用AddWatcher再调用TakeWatcherData |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**:
```cmake
# 新增jsoncpp.cpp(解析订阅事件中的json字符串)源文件
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 新增动态库依赖libhiappevent_ndk.z.so和libhilog_ndk.z.so(日志输出)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

**头文件导入**:
```cpp
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
```

### 环境要求
- HarmonyOS API version: 12+
- DevEco Studio: 最新版本
- 开发者选项: 需打开"系统资源泄漏日志"开关并重启设备
- jsoncpp库: 需从GitHub下载并编译

### 常见编译问题

**问题1: jsoncpp库找不到**
```
error: 'json/json.h' file not found
```
**解决方法**: 从[jsoncpp代码仓](https://github.com/open-source-parsers/jsoncpp)下载源码,按照README的Amalgamated source步骤生成json.h和json-forwards.h文件,放入cpp/json目录

**问题2: hiappevent头文件找不到**
```
error: 'hiappevent/hiappevent.h' file not found
```
**解决方法**: 确保在CMakeLists.txt中正确链接libhiappevent_ndk.z.so库

**问题3: 链接错误**
```
undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**: 在CMakeLists.txt中添加libhiappevent_ndk.z.so到target_link_libraries

## 常见问题与解决方法

### Q1: 监听器创建后没有收到事件
**原因**: 
- 开发者选项中"系统资源泄漏日志"开关未打开
- 设备未重启
- 未构造资源泄漏场景触发事件

**解决方法**:
- 打开"开发者选项"中的"系统资源泄漏日志"开关
- 重启设备使开关生效
- 使用hidebug.setAppResourceLimit构造资源泄漏场景
- 同一应用24小时内至多上报一次,二次上报需重启设备

### Q2: json解析失败
**原因**: 
- 事件参数格式不符合json规范
- jsoncpp库配置不正确

**解决方法**:
- 使用Json::Features::strictMode()进行严格模式解析
- 解析失败时跳过该事件,继续处理后续事件
- 检查jsoncpp库是否正确导入和链接

### Q3: 回调函数中的指针在回调外使用导致崩溃
**原因**: 回调函数中的指针生命周期仅限于回调函数内

**解决方法**:
- 需缓存数据时,对指针指向的内容进行深拷贝
- 示例: `std::string domainStr = std::string(domain);` 而非直接使用domain指针

### Q4: 监听器添加失败返回错误码-5
**原因**: 监听器指针为nullptr

**解决方法**:
- 检查OH_HiAppEvent_CreateWatcher是否成功
- 检查name参数是否合法(非空且长度合适)
- 创建失败时返回nullptr,需判断后再使用

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "watcherName": "ResourceLeakWatcher",
  "domain": "DOMAIN_OS",
  "eventName": "EVENT_RESOURCE_OVERLIMIT",
  "callbackMode": "onReceive/onTrigger",
  "eventsReceived": 1,
  "eventDetails": {
    "time": 1502049167732,
    "pid": 1587,
    "uid": 20010043,
    "resourceType": "pss_memory",
    "bundleName": "com.example.myapplication",
    "appRunningUniqueId": "12369547851223645271",
    "bundleVersion": "1.0.0"
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
    "OH_HiAppEvent_TakeWatcherData"
  ]
}
```

## 参考文档

- [API开发指南: 订阅资源泄漏事件(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-resourceleak-events-ndk)
- [API参考说明: hiappevent.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [API参考说明: hidebug.setAppResourceLimit](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-hidebug)

## 完整示例代码

- [C++完整示例(onReceive模式)](assets/resourceleak_watcher_onreceive.cpp)
- [C++完整示例(onTrigger模式)](assets/resourceleak_watcher_ontrigger.cpp)
- [CMakeLists.txt配置示例](assets/CMakeLists.txt)
- [资源泄漏测试示例](assets/resourceleak_test.cpp)

## 测试用例

### 正向测试用例
- [创建监听器并订阅资源泄漏事件](tests/test_positive.cpp): 正常创建监听器,设置回调,添加监听器
- [接收并解析资源泄漏事件](tests/test_positive.cpp): 接收RESOURCE_OVERLIMIT事件并解析所有参数
- [移除并销毁监听器](tests/test_positive.cpp): 正确移除监听器并销毁释放资源

### 边界测试用例
- [监听器名称长度测试](tests/test_boundary.cpp): 测试监听器名称的最大长度限制
- [事件数量触发条件测试](tests/test_boundary.cpp): 测试不同的row、size、timeOut触发条件
- [多监听器并发测试](tests/test_boundary.cpp): 测试多个监听器同时订阅事件

### 异常测试用例
- [监听器创建失败测试](tests/test_exception.cpp): 测试name参数为nullptr或非法时的创建失败
- [回调指针错误使用测试](tests/test_exception.cpp): 测试在回调外使用回调指针的错误
- [API调用顺序错误测试](tests/test_exception.cpp): 测试未调用AddWatcher直接调用TakeWatcherData的错误