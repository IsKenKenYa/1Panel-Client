---
name: hmos-performance-analysis-kit-hiappevent-watch-app-launch
description: 订阅应用启动耗时系统事件，仅支持C/C++ Native开发，使用HiAppEvent观察者机制捕获APP_LAUNCH事件，适用于性能分析、启动优化场景
---

# 订阅启动耗时事件技能（C/C++）

## 功能描述

本技能用于在HarmonyOS应用中通过C/C++ Native代码订阅系统启动耗时事件（APP_LAUNCH）。通过HiAppEvent观察者机制，开发者可以实时捕获应用启动过程中的各项性能指标数据，包括启动时间、进程创建时长、Ability生命周期各阶段耗时等详细信息，用于性能分析和启动优化。

**核心能力**：
- 创建观察者监听系统启动耗时事件
- 支持onReceive实时回调模式（事件立即触发）
- 支持onTrigger条件触发模式（批量处理）
- 解析JSON格式的事件参数数据

**适用范围**：
- 仅支持C/C++ Native开发
- 仅监听DOMAIN_OS领域的EVENT_APP_LAUNCH事件
- 需配合jsoncpp库解析事件参数

**限制条件**：
- API版本要求：HiAppEvent C API起始版本12
- 系统能力：SystemCapability.HiviewDFX.HiAppEvent
- 必须在应用启动时注册观察者
- 观察者名称必须唯一

**典型场景**：
- 应用启动性能分析和优化
- 启动耗时问题定位和调试
- 性能数据采集和统计

## 使用场景

### 触发词
- "订阅启动耗时事件"
- "监听应用启动事件"
- "APP_LAUNCH事件订阅"
- "应用启动性能分析"
- "HiAppEvent C/C++订阅"
- "启动耗时监控"

### 能做
- 创建HiAppEvent观察者订阅系统启动事件
- 实现onReceive回调实时接收启动耗时数据
- 实现onTrigger回调批量处理启动事件
- 解析启动事件的各项性能参数指标
- 移除和销毁观察者释放资源

### 绝不做
- 不用于订阅自定义应用事件（仅支持系统启动事件）
- 不用于ArkTS开发场景（仅支持C/C++ Native）
- 不用于实时性能监控（仅捕获启动时刻的静态数据）
- 不直接处理事件上报到云端（仅本地订阅和处理）

### 补充
- 需要集成jsoncpp开源库解析JSON数据
- 推荐在EntryAbility.onCreate()中注册观察者
- 观察者生命周期需合理管理，避免内存泄漏

## 调用规范和规则

### 输入约束
- 观察者名称：字符串长度不超过32字符，系统内唯一
- 事件过滤：domain为"OS"，事件名为"APP_LAUNCH"
- 回调函数：必须实现OnReceive或OnTrigger回调
- 触发条件：row、size、timeout至少设置一个（onTrigger模式）

### 执行约束
- 注册时机：必须在应用启动阶段完成观察者注册
- 最大观察者数量：系统无明确限制，建议不超过10个
- 内存管理：观察者不再使用必须销毁，防止内存泄漏
- 性能考虑：OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景需评估线程选择

### 内容约束
- 禁止在回调函数外直接使用回调指针
- 禁止缓存回调指针数据而不进行深拷贝
- 禁止使用已销毁的观察者指针
- 禁止在回调中进行耗时阻塞操作

### 降级约束
- json解析失败：跳过当前事件，记录日志继续处理后续事件
- 观察者创建失败：返回nullptr，记录错误日志，提示用户检查参数
- 回调未触发：检查触发条件设置，增加调试日志确认事件是否到达
- 内存不足：优先销毁不必要的观察者，释放资源后重新尝试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认开发环境为Native C++工程
2. 确认已导入jsoncpp三方库（json.h、json-forwards.h、jsoncpp.cpp）
3. 确认CMakeLists.txt已添加libhiappevent_ndk.z.so和libhilog_ndk.z.so依赖
4. 确认API版本>=12，系统支持SystemCapability.HiviewDFX.HiAppEvent

**参数准备**：
```cpp
// 导入必要头文件
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

// 定义日志标签
#undef LOG_TAG
#define LOG_TAG "AppLaunchWatcher"

// 定义观察者指针缓存变量
static HiAppEvent_Watcher *systemEventWatcherR = nullptr;  // onReceive模式
static HiAppEvent_Watcher *systemEventWatcherT = nullptr;  // onTrigger模式
```

### 步骤2：实现回调函数

**onReceive回调实现**（实时接收模式）：
```cpp
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 过滤非启动耗时事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_LAUNCH) != 0) {
                continue;
            }
            
            // 记录事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", 
                        appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", 
                        appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", 
                        appEventGroups[i].appEventInfos[j].type);
            
            // 解析JSON参数
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                // 提取启动耗时关键指标
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", 
                            params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", 
                            params["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.start_type=%{public}d", 
                            params["start_type"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.response_latency=%{public}d", 
                            params["response_latency"].asInt());
            } else {
                OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event params JSON");
            }
        }
    }
}
```

**onTrigger回调实现**（条件触发模式）：
```cpp
static void OnTake(const char *const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    for (uint32_t i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            // 过滤启动耗时事件
            if (domain == DOMAIN_OS && name == EVENT_APP_LAUNCH) {
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", 
                            eventInfo["time"].asInt64());
            }
        } else {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event JSON");
        }
    }
}

static void OnTrigger(int row, int size)
{
    // 获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTake);
}
```

### 步骤3：创建并配置观察者

**onReceive模式注册函数**：
```cpp
static napi_value RegisterWatcherReceive(napi_env env, napi_callback_info info)
{
    // 创建观察者
    systemEventWatcherR = OH_HiAppEvent_CreateWatcher("AppLaunchWatcherR");
    if (systemEventWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置事件过滤条件
    const char *names[] = {EVENT_APP_LAUNCH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    // 设置回调函数
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive callback, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    // 添加观察者开始监听
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}
```

**onTrigger模式注册函数**：
```cpp
static napi_value RegisterWatcherTrigger(napi_env env, napi_callback_info info)
{
    // 创建观察者
    systemEventWatcherT = OH_HiAppEvent_CreateWatcher("AppLaunchWatcherT");
    if (systemEventWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置事件过滤条件
    const char *names[] = {EVENT_APP_LAUNCH};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set event filter, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    // 设置回调函数
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger callback, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    // 设置触发条件（新增1个事件时触发）
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    // 添加观察者开始监听
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}
```

### 步骤4：注册ArkTS接口

**napi_init.cpp中注册接口**：
```cpp
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        {"registerWatcherReceive", nullptr, RegisterWatcherReceive, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"registerWatcherTrigger", nullptr, RegisterWatcherTrigger, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**index.d.ts接口定义**：
```typescript
export const registerWatcherReceive: () => void;
export const registerWatcherTrigger: () => void;
```

### 步骤5：在应用启动时调用

**EntryAbility.ets中调用**：
```typescript
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 注册系统事件观察者
        testNapi.registerWatcherReceive();
        testNapi.registerWatcherTrigger();
    }
}
```

### 步骤6：销毁观察者

**资源释放处理**：
```cpp
// 在合适时机移除和销毁观察者
void CleanupWatchers()
{
    if (systemEventWatcherR != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcherR);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherR);
        systemEventWatcherR = nullptr;
    }
    
    if (systemEventWatcherT != nullptr) {
        OH_HiAppEvent_RemoveWatcher(systemEventWatcherT);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcherT);
        systemEventWatcherT = nullptr;
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 接口调用成功 | 无需处理 |
| -1 | names参数异常 | 检查事件名称数组是否正确设置 |
| -4 | domain参数异常 | 检查domain是否为有效字符串（DOMAIN_OS） |
| -5 | watcher入参空指针 | 检查观察者指针是否为nullptr，确保创建成功 |
| -6 | 操作顺序有误 | 确保先调用OH_HiAppEvent_AddWatcher再调用TakeWatcherData |
| -7 | 事件处理者为空 | 检查Processor创建是否成功（此场景不涉及） |
| -8 | 事件处理者不存在 | 检查Processor ID是否正确（此场景不涉及） |
| -9 | 参数值无效 | 检查传入参数值是否符合规范 |
| -10 | 事件配置为空 | 检查Config对象是否创建成功 |
| -100 | 操作失败 | 检查系统状态和权限配置 |
| -200 | 无效的用户标识 | 检查UID是否正确（此场景不涉及） |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 添加源文件
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 添加依赖库
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

**jsoncpp集成**：
从 https://github.com/open-source-parsers/jsoncpp 下载源码，按照README中Amalgamated source操作步骤生成：
- jsoncpp.cpp
- json/json.h
- json/json-forwards.h

### 环境要求
- HarmonyOS API版本：>=12
- DevEco Studio：最新版本
- Native C++工程模板
- 系统能力：SystemCapability.HiviewDFX.HiAppEvent

### 常见编译问题

**问题1：找不到hiappevent.h头文件**
```
fatal error: hiappevent/hiappevent.h: No such file or directory
```
**解决方法**：确认工程为Native C++模板，检查SDK路径配置正确

**问题2：jsoncpp编译错误**
```
undefined reference to 'Json::Reader::parse'
```
**解决方法**：确保jsoncpp.cpp已添加到CMakeLists.txt的add_library源文件列表中

**问题3：libhiappevent_ndk.z.so链接失败**
```
cannot find -lhiappevent_ndk.z
```
**解决方法**：检查target_link_libraries中库名是否正确（应为libhiappevent_ndk.z.so）

**问题4：NAPI接口注册失败**
```
TypeError: testNapi.registerWatcherReceive is not a function
```
**解决方法**：检查Init函数中napi_property_descriptor是否正确导出，确认index.d.ts接口定义

## 常见问题与解决方法

### Q1：观察者回调未触发
**原因**：
- 观察者未成功添加
- 事件过滤条件设置错误
- 应用启动未触发APP_LAUNCH事件

**解决方法**：
- 检查OH_HiAppEvent_AddWatcher返回值是否为0
- 确认domain设置为DOMAIN_OS，事件名设置为EVENT_APP_LAUNCH
- 运行应用后退出，再次点击桌面图标启动应用触发事件

### Q2：JSON解析失败
**原因**：
- jsoncpp库未正确集成
- params字段JSON格式异常
- 使用了strict模式解析非标准JSON

**解决方法**：
- 确认jsoncpp.cpp已正确编译链接
- 使用Json::Features::strictMode()确保严格解析
- 添加reader.parse失败的错误处理逻辑

### Q3：观察者内存泄漏
**原因**：
- 观察者创建后未销毁
- 仅调用RemoveWatcher未调用DestroyWatcher
- 观察者指针未置空

**解决方法**：
- 在应用退出或合适时机调用OH_HiAppEvent_DestroyWatcher
- 先RemoveWatcher停止监听，再DestroyWatcher释放内存
- 销毁后将指针置nullptr防止重复释放

### Q4：回调中访问崩溃
**原因**：
- 在回调函数外使用回调指针数据
- 未对回调指针数据进行深拷贝
- 回调函数已返回但指针数据已失效

**解决方法**：
- 仅在回调函数内使用指针数据
- 需缓存数据时进行深拷贝（如strdup复制字符串）
- 不在回调外直接访问appEventGroups指针

### Q5：多个观察者冲突
**原因**：
- 观察者名称重复
- 相同name的观察者会覆盖

**解决方法**：
- 确保每个观察者name唯一
- 使用不同名称区分onReceive和onTrigger模式观察者
- 后注册的同名观察者会覆盖前一个

## 输出结果报告

执行完成后输出以下信息：

**日志输出示例**：
```
HiAppEvent eventInfo.domain=OS
HiAppEvent eventInfo.name=APP_LAUNCH
HiAppEvent eventInfo.eventType=4
HiAppEvent eventInfo.params.time=1780919598366
HiAppEvent eventInfo.params.bundle_version=1.0.0
HiAppEvent eventInfo.params.bundle_name=com.example.myapplication
HiAppEvent eventInfo.params.process_name=com.example.myapplication
HiAppEvent eventInfo.params.start_type=1
HiAppEvent eventInfo.params.icon_input_time=1780919593178
HiAppEvent eventInfo.params.animation_finish_time=568
HiAppEvent eventInfo.params.extend_time=0
HiAppEvent eventInfo.params.response_latency=61
HiAppEvent eventInfo.params.laun_to_start_ability_dur=28
HiAppEvent eventInfo.params.startability_processstart_dur=0
HiAppEvent eventInfo.params.processstart_to_appattach_dur=0
HiAppEvent eventInfo.params.appattach_to_appforeground_dur=0
HiAppEvent eventInfo.params.startability_appforeground_dur=6
HiAppEvent eventInfo.params.appforegr_abilityonforegr_dur=2
HiAppEvent eventInfo.params.abilityonforeg_startwindow_dur=0
```

**启动耗时参数说明**：
- `time`: 启动事件发生的时间戳
- `bundle_version`: 应用版本号
- `bundle_name`: 应用包名
- `process_name`: 进程名称
- `start_type`: 启动类型（1=冷启动，2=热启动）
- `icon_input_time`: 图标输入时间
- `animation_finish_time`: 动画完成时长
- `response_latency`: 响应延迟时长
- `laun_to_start_ability_dur`: Launcher到启动Ability时长
- `startability_processstart_dur`: StartAbility到进程启动时长
- `processstart_to_appattach_dur`: 进程启动到AppAttach时长
- `appattach_to_appforeground_dur`: AppAttach到前台时长
- `startability_appforeground_dur`: StartAbility到前台时长
- `appforegr_abilityonforegr_dur`: 前台到Ability前台时长
- `abilityonforeg_startwindow_dur`: Ability前台到启动窗口时长

**API调用列表**：
- OH_HiAppEvent_CreateWatcher
- OH_HiAppEvent_SetAppEventFilter
- OH_HiAppEvent_SetWatcherOnReceive
- OH_HiAppEvent_SetWatcherOnTrigger
- OH_HiAppEvent_SetTriggerCondition
- OH_HiAppEvent_AddWatcher
- OH_HiAppEvent_TakeWatcherData
- OH_HiAppEvent_RemoveWatcher
- OH_HiAppEvent_DestroyWatcher

## 参考文档

- [API开发指南：订阅启动耗时事件（C/C++）](references/hiappevent-watcher-app-launch-c.md)
- [API参考：HiAppEvent C API头文件](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [API参考：HiAppEvent_Watcher结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-watcher)
- [API参考：HiAppEvent_AppEventGroup结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-appeventgroup)

## 完整示例代码

- [C++完整示例：napi_init.cpp](assets/napi_init.cpp)
- [CMakeLists配置示例](assets/CMakeLists.txt)
- [ArkTS接口定义示例](assets/index.d.ts)
- [EntryAbility调用示例](assets/EntryAbility.ets)

## 测试用例

### 正向测试用例
- [测试正常订阅启动事件](tests/test_positive.cpp)：验证观察者成功创建和回调触发
- [测试JSON参数解析](tests/test_json_parse.cpp)：验证启动耗时参数正确解析

### 边界测试用例
- [测试观察者名称长度限制](tests/test_watcher_name_length.cpp)：验证32字符名称限制
- [测试触发条件临界值](tests/test_trigger_condition.cpp)：验证row=1、size=0、timeout=0条件

### 异常测试用例
- [测试观察者创建失败处理](tests/test_watcher_create_fail.cpp)：验证参数异常时的错误处理
- [测试JSON解析失败处理](tests/test_json_parse_fail.cpp)：验证异常JSON数据的降级处理
- [测试观察者销毁场景](tests/test_watcher_destroy.cpp)：验证重复销毁和空指针销毁的安全性