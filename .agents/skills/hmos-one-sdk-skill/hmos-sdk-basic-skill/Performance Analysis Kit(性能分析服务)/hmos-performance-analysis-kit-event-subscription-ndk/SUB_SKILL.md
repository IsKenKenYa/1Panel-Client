---
name: hmos-performance-analysis-kit-event-subscription-ndk
description: 订阅HarmonyOS应用事件+支持系统事件和应用事件+需要C/C++开发环境+适用于崩溃事件监控、用户行为分析场景
---

# HiAppEvent事件订阅技能（C/C++）

## 功能描述

本技能提供HarmonyOS应用事件订阅功能，使用HiAppEvent C API实现事件观察者的创建、配置和订阅。支持订阅系统事件（如崩溃事件）和应用自定义事件（如按钮点击事件），并提供事件打点功能。通过OnReceive和OnTrigger两种回调机制，开发者可以灵活处理订阅到的应用事件数据。

**核心能力**：
- 创建和配置事件观察者（Watcher）
- 设置事件过滤规则（按领域、类型、名称过滤）
- 实现OnReceive实时回调订阅（立即接收事件）
- 实现OnTrigger延迟回调订阅（条件触发接收）
- 应用事件打点（记录用户行为、故障等事件）
- 移除和销毁观察者

**技术特点**：
- C API接口，适用于Native C++开发
- 支持jsoncpp库解析事件JSON数据
- 系统能力：SystemCapability.HiviewDFX.HiAppEvent
- 起始版本：API 8（打点接口）、API 12（订阅接口）

## 使用场景

### 触发词
- "订阅应用事件" - 创建事件观察者订阅应用事件
- "订阅崩溃事件" - 监听系统崩溃事件并获取故障日志
- "订阅按钮点击" - 监听用户界面交互事件
- "事件打点" - 记录应用自定义事件
- "HiAppEvent订阅" - 使用HiAppEvent进行事件订阅
- "C++事件订阅" - 使用C/C++接口订阅事件
- "Performance Analysis Kit" - 性能分析服务事件订阅
- "事件观察者" - 创建和管理事件观察者

### 能做
- 创建事件观察者订阅系统崩溃事件，获取崩溃时间、包名、故障日志文件路径
- 创建事件观察者订阅应用自定义事件，如按钮点击、页面访问等用户行为
- 使用OnReceive回调实时接收事件数据，适用于需要立即处理的场景
- 使用OnTrigger回调延迟接收事件数据，支持批量处理和条件触发
- 实现应用事件打点，记录用户行为、业务流程、故障信息等
- 设置事件过滤规则，按领域、类型、名称精确筛选订阅事件
- 配置触发条件（事件数量、大小、超时时间）控制回调时机
- 移除和销毁观察者，释放系统资源

### 绝不做
- 不订阅系统以外的第三方应用事件（仅支持本应用和系统事件）
- 不在主线程高频调用OH_HiAppEvent_AddWatcher（涉及I/O操作，性能敏感场景需在子线程调用）
- 不直接缓存回调函数中的指针（生命周期仅限回调函数内，需深拷贝）
- 不使用重复的观察者名称订阅（相同name会覆盖前一次订阅）
- 不在未调用OH_HiAppEvent_AddWatcher前调用OH_HiAppEvent_TakeWatcherData（操作顺序错误）
- 不忘记销毁观察者和参数列表（会导致内存泄漏）

### 补充
- 需要Native C++工程环境，依赖libhiappevent_ndk.z.so和libhilog_ndk.z.so库
- 推荐使用jsoncpp库解析订阅事件的JSON字符串数据
- 订阅接口OH_HiAppEvent_AddWatcher传入的名称name是唯一的
- 观察者接收到的事件数据格式为JSON字符串，需使用JSON解析库处理
- 系统事件领域为DOMAIN_OS，崩溃事件名称为EVENT_APP_CRASH
- 事件参数列表支持布尔、数值、字符串、数组类型，参数个数限制32个以内
- 事件参数字符串长度限制8KB以内，数组元素个数限制100个以内

## 调用规范和规则

### 输入约束
- **观察者名称**：自定义字符串，用于标识不同观察者，不能重复
- **事件领域**：
  - 系统事件：DOMAIN_OS（固定值）
  - 应用事件：自定义字符串，字母开头，不含下划线结尾，不超过32字符
- **事件名称**：
  - 系统事件：EVENT_APP_CRASH（崩溃事件固定值）
  - 应用事件：自定义字符串，首字符字母或$，中间字符数字字母下划线，结尾数字字母，不超过48字符
- **事件类型**：EventType枚举值（FAULT=1, STATISTIC=2, SECURITY=3, BEHAVIOR=4）
- **过滤规则**：最多可添加多个过滤规则，监听器收到满足任一规则的事件
- **触发条件**：
  - row：新接收事件数量阈值（大于0生效）
  - size：新接收事件大小阈值（字节，大于0生效）
  - timeOut：超时时间（秒，大于0生效）
- **参数列表**：最多32个参数，字符串长度8KB以内，数组元素100个以内

### 执行约束
- **最大耗时**：OH_HiAppEvent_AddWatcher涉及I/O操作，避免在主线程高频调用
- **回调处理**：回调函数内指针生命周期仅限函数内，禁止缓存指针，需深拷贝数据
- **内存管理**：创建的观察者和参数列表必须销毁，否则内存泄漏
- **调用顺序**：
  1. OH_HiAppEvent_CreateWatcher创建观察者
  2. OH_HiAppEvent_SetAppEventFilter设置过滤规则（可多次）
  3. OH_HiAppEvent_SetWatcherOnReceive或OH_HiAppEvent_SetWatcherOnTrigger设置回调
  4. OH_HiAppEvent_SetTriggerCondition设置触发条件（OnTrigger模式）
  5. OH_HiAppEvent_AddWatcher添加观察者开始监听
  6. OH_HiAppEvent_RemoveWatcher移除观察者停止监听
  7. OH_HiAppEvent_DestroyWatcher销毁观察者释放内存

### 内容约束
- **禁止生成**：
  - 禁止生成未经验证的API调用代码
  - 禁止使用未导入的依赖库
  - 禁止缓存回调函数指针的数据（需深拷贝）
- **禁止高危操作**：
  - 禁止在回调函数外直接使用回调中的指针
  - 禁止忘记销毁观察者和参数列表
  - 禁止在未添加观察者前调用OH_HiAppEvent_TakeWatcherData
- **禁止操作**：
  - 禁止订阅其他应用的事件（仅支持本应用和系统事件）
  - 禁止使用重复的观察者名称订阅
  - 禁止在回调函数中执行耗时操作（会影响事件处理性能）

### 降级约束
- **API调用失败**：返回错误码，检查参数有效性，根据错误码调整参数
- **观察者创建失败**：name参数异常返回nullptr，检查名称格式
- **过滤规则设置失败**：返回-1（names异常）、-4（domain异常）、-5（watcher空指针），检查参数
- **回调设置失败**：返回-5（watcher空指针），检查观察者指针
- **添加观察者失败**：返回-5（watcher空指针），检查观察者指针
- **事件打点失败**：返回负值（参数校验失败），检查事件名称、领域、参数列表
- **网络异常**：不依赖网络，本地事件订阅功能不受网络影响
- **解析失败**：JSON解析失败，检查事件数据格式，使用strict模式解析

## 调用流程和步骤

### 步骤1：准备阶段（工程配置）

**前置校验**：
1. 检查是否为Native C++工程
2. 检查是否已导入libhiappevent_ndk.z.so和libhilog_ndk.z.so库
3. 检查是否已导入jsoncpp库（用于解析事件JSON数据）
4. 检查CMakeLists.txt配置是否正确

**参数准备**：
```cmake
# CMakeLists.txt配置示例
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 导入jsoncpp库（需先下载并放置在thirdparty目录）
set(GZ_FILE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/src/jsoncpp-1.9.6.tar.gz")
set(DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR})
execute_process(COMMAND tar -xzf ${GZ_FILE} -C ${DEST_DIR} WORKING_DIRECTORY ${DEST_DIR})

add_library(entry SHARED napi_init.cpp)

# 依赖库配置
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
target_link_libraries(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so
)
target_include_directories(entry PRIVATE 
    ${DEST_DIR}/jsoncpp-1.9.6/include/json
)
```

**导入依赖**：
```cpp
#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hilog/log.h"

#undef LOG_TAG
#define LOG_TAG "HiAppEventTag"
```

### 步骤2：订阅系统崩溃事件（OnReceive回调模式）

**示例代码**：
```cpp
// 定义观察者指针缓存变量
static HiAppEvent_Watcher *crashWatcher = nullptr;

// OnReceive回调函数定义
static void OnReceiveCrash(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    OH_LOG_INFO(LogType::LOG_APP, "OnReceive callback triggered, groupLen=%{public}u", groupLen);
    
    for (uint32_t i = 0; i < groupLen; ++i) {
        for (uint32_t j = 0; j < appEventGroups[i].infoLen; ++j) {
            // 输出事件基本信息
            OH_LOG_INFO(LogType::LOG_APP, "eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            // 过滤非崩溃事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 ||
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_CRASH) != 0) {
                continue;
            }
            
            // 解析崩溃事件参数JSON字符串
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                // 获取崩溃时间戳
                int64_t crashTime = params["time"].asInt64();
                OH_LOG_INFO(LogType::LOG_APP, "crashTime=%{public}lld", crashTime);
                
                // 获取崩溃应用包名
                std::string bundleName = params["bundle_name"].asString();
                OH_LOG_INFO(LogType::LOG_APP, "bundleName=%{public}s", bundleName.c_str());
                
                // 获取故障日志文件路径
                std::string externalLog = writer.write(params["external_log"]);
                OH_LOG_INFO(LogType::LOG_APP, "externalLog=%{public}s", externalLog.c_str());
                
                // 开发者可在此处理崩溃事件数据（如上传到服务器、本地存储等）
                // 注意：不要缓存指针，需要深拷贝数据
            }
        }
    }
}

// 创建并订阅崩溃事件观察者
static napi_value RegisterCrashWatcher(napi_env env, napi_callback_info info)
{
    // 创建观察者，设置唯一名称
    crashWatcher = OH_HiAppEvent_CreateWatcher("CrashWatcher001");
    if (crashWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateWatcher failed, name invalid");
        return {};
    }
    
    // 设置过滤规则：订阅系统崩溃事件
    const char *names[] = {EVENT_APP_CRASH};
    int result = OH_HiAppEvent_SetAppEventFilter(crashWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return {};
    }
    
    // 设置OnReceive回调（立即触发模式）
    result = OH_HiAppEvent_SetWatcherOnReceive(crashWatcher, OnReceiveCrash);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnReceive failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return {};
    }
    
    // 添加观察者，开始监听
    result = OH_HiAppEvent_AddWatcher(crashWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "CrashWatcher registered successfully");
    return {};
}
```

### 步骤3：订阅应用自定义事件（OnTrigger回调模式）

**示例代码**：
```cpp
// 定义观察者指针缓存变量
static HiAppEvent_Watcher *clickWatcher = nullptr;

// OnTake回调函数定义（在OnTrigger回调中调用）
static void OnTakeClickEvents(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    OH_LOG_INFO(LogType::LOG_APP, "OnTake callback, eventLen=%{public}u", eventLen);
    
    for (uint32_t i = 0; i < eventLen; ++i) {
        // 解析事件JSON字符串
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            std::string domain = eventInfo["domain_"].asString();
            std::string name = eventInfo["name_"].asString();
            int type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "event.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "event.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "event.type=%{public}d", type);
            
            // 处理按钮点击事件
            if (domain == "button" && name == "click") {
                int64_t clickTime = eventInfo["clickTime"].asInt64();
                OH_LOG_INFO(LogType::LOG_APP, "clickTime=%{public}lld", clickTime);
                
                // 开发者可在此处理点击事件数据（如统计用户行为）
            }
        }
    }
}

// OnTrigger回调函数定义（条件触发模式）
static void OnTriggerClick(int row, int size)
{
    OH_LOG_INFO(LogType::LOG_APP, "OnTrigger callback, row=%{public}d, size=%{public}d", row, size);
    
    // 获取指定数量的已保存事件
    OH_HiAppEvent_TakeWatcherData(clickWatcher, row, OnTakeClickEvents);
}

// 创建并订阅按钮点击事件观察者
static napi_value RegisterClickWatcher(napi_env env, napi_callback_info info)
{
    // 创建观察者，设置唯一名称
    clickWatcher = OH_HiAppEvent_CreateWatcher("ButtonClickWatcher001");
    if (clickWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateWatcher failed, name invalid");
        return {};
    }
    
    // 设置过滤规则：订阅应用按钮点击事件
    const char *names[] = {"click"};
    int result = OH_HiAppEvent_SetAppEventFilter(clickWatcher, "button", 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    // 设置OnTrigger回调（条件触发模式）
    result = OH_HiAppEvent_SetWatcherOnTrigger(clickWatcher, OnTriggerClick);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnTrigger failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    // 设置触发条件：新增1个事件时触发回调
    result = OH_HiAppEvent_SetTriggerCondition(clickWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTriggerCondition failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    // 添加观察者，开始监听
    result = OH_HiAppEvent_AddWatcher(clickWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed, result=%{public}d", result);
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "ClickWatcher registered successfully");
    return {};
}
```

### 步骤4：应用事件打点

**示例代码**：
```cpp
// 应用事件打点函数
static napi_value WriteButtonClickEvent(napi_env env, napi_callback_info info)
{
    // 创建参数列表
    ParamList params = OH_HiAppEvent_CreateParamList();
    if (params == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "CreateParamList failed");
        return {};
    }
    
    // 添加参数：点击时间戳
    params = OH_HiAppEvent_AddInt64Param(params, "clickTime", time(nullptr));
    
    // 事件打点：记录按钮点击行为事件
    int result = OH_HiAppEvent_Write("button", "click", EventType::BEHAVIOR, params);
    
    // 销毁参数列表
    OH_HiAppEvent_DestroyParamList(params);
    
    if (result < 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Write event failed, result=%{public}d", result);
        // result = -1: 非法事件名称
        // result = -4: 非法事件领域名称
        // result = -99: 打点功能被关闭
    } else if (result > 0) {
        OH_LOG_WARN(LogType::LOG_APP, "Write event success but discard invalid params, result=%{public}d", result);
        // result = 1: 非法参数名称
        // result = 4: 非法参数字符串长度
        // result = 5: 非法参数数量
        // result = 6: 非法参数数组长度
        // result = 8: 重复参数名称
    } else {
        OH_LOG_INFO(LogType::LOG_APP, "Write event success, result=0");
    }
    
    return {};
}
```

### 步骤5：移除和销毁观察者

**示例代码**：
```cpp
// 移除观察者（停止监听）
static napi_value RemoveAllWatchers(napi_env env, napi_callback_info info)
{
    if (crashWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(crashWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher crashWatcher failed, result=%{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher crashWatcher success");
        }
    }
    
    if (clickWatcher != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(clickWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher clickWatcher failed, result=%{public}d", result);
        } else {
            OH_LOG_INFO(LogType::LOG_APP, "RemoveWatcher clickWatcher success");
        }
    }
    
    return {};
}

// 销毁观察者（释放内存）
static napi_value DestroyAllWatchers(napi_env env, napi_callback_info info)
{
    if (crashWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(crashWatcher);
        crashWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher crashWatcher success");
    }
    
    if (clickWatcher != nullptr) {
        OH_HiAppEvent_DestroyWatcher(clickWatcher);
        clickWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "DestroyWatcher clickWatcher success");
    }
    
    return {};
}
```

### 步骤6：注册ArkTS接口

**示例代码**：
```cpp
// 注册NAPI接口
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerCrashWatcher", nullptr, RegisterCrashWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerClickWatcher", nullptr, RegisterClickWatcher, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "writeButtonClickEvent", nullptr, WriteButtonClickEvent, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "removeAllWatchers", nullptr, RemoveAllWatchers, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "destroyAllWatchers", nullptr, DestroyAllWatchers, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

// 模块导出
EXTERN_C_START
static napi_value NapiExport(napi_env env, napi_value exports)
{
    return Init(env, exports);
}
EXTERN_C_END

static napi_module module = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = NapiExport,
    .nm_modname = "entry",
    .nm_priv = nullptr,
    .reserved = { 0 },
};

extern "C" __attribute__((constructor)) void RegisterModule(void)
{
    napi_module_register(&module);
}
```

### 步骤7：ArkTS接口定义和调用

**接口定义（index.d.ts）**：
```typescript
export const registerCrashWatcher: () => void;
export const registerClickWatcher: () => void;
export const writeButtonClickEvent: () => void;
export const removeAllWatchers: () => void;
export const destroyAllWatchers: () => void;
```

**应用启动时注册观察者（EntryAbility.ets）**：
```typescript
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 启动时注册崩溃事件观察者
        testNapi.registerCrashWatcher();
        
        // 启动时注册按钮点击事件观察者
        testNapi.registerClickWatcher();
    }
}
```

**触发事件（Index.ets）**：
```typescript
import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
    build() {
        Column() {
            // 触发崩溃事件按钮（仅测试，实际应用中不应主动触发崩溃）
            Button('触发崩溃事件')
                .onClick(() => {
                    // 构造崩溃场景（JSON.parse解析空字符串会抛异常）
                    let result: object = JSON.parse('');
                })
            
            // 触发按钮点击事件按钮
            Button('触发按钮点击事件')
                .onClick(() => {
                    testNapi.writeButtonClickEvent();
                })
            
            // 移除观察者按钮
            Button('移除观察者')
                .onClick(() => {
                    testNapi.removeAllWatchers();
                })
            
            // 销毁观察者按钮
            Button('销毁观察者')
                .onClick(() => {
                    testNapi.destroyAllWatchers();
                })
        }
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| **0** | 操作成功 | 无需处理 |
| **-1** | 非法的事件名称 | 检查事件名称格式：首字符字母或$，中间字符数字字母下划线，结尾数字字母，不超过48字符 |
| **-4** | 非法的事件领域名称 | 检查领域名称格式：字母开头，不含下划线结尾，不超过32字符 |
| **-5** | watcher入参空指针 | 检查观察者指针是否为nullptr，确保创建观察者成功 |
| **-6** | 未调用OH_HiAppEvent_AddWatcher | 先调用OH_HiAppEvent_AddWatcher添加观察者，再调用OH_HiAppEvent_TakeWatcherData |
| **-7** | 事件处理者为空 | 检查Processor指针是否为nullptr（API 18新增） |
| **-8** | 事件处理者不存在 | 检查Processor是否已创建并添加（API 18新增） |
| **-9** | 参数值无效 | 检查参数值是否符合规范（API 15新增） |
| **-10** | 事件配置为空 | 检查Config指针是否为nullptr（API 15新增） |
| **-99** | 打点功能被关闭 | 检查是否调用OH_HiAppEvent_Configure关闭了打点功能，或系统禁用了打点 |
| **-100** | 操作失败 | 检查系统状态和参数有效性（API 18新增） |
| **-200** | 无效的用户标识 | 检查UID是否有效（API 18新增） |
| **1** | 非法的事件参数名称 | 检查参数名称格式：首字符字母或$，中间字符数字字母下划线，结尾数字字母，不超过32字符 |
| **4** | 非法的事件参数字符串长度 | 字符串参数长度需在8KB（8192字符）以内，超出会丢弃 |
| **5** | 非法的事件参数数量 | 参数个数需在32个以内，超出会丢弃 |
| **6** | 非法的事件参数数组长度 | 数组元素个数需在100个以内，超出会丢弃 |
| **8** | 重复的事件参数名称 | 检查参数列表中是否有重复的参数名称 |
| **HIAPPEVENT_INVALID_PARAM_VALUE_LENGTH = 4** | 参数值长度无效（API 18新增） | 检查参数值字符串长度 |
| **HIAPPEVENT_PROCESSOR_IS_NULL = -7** | 事件处理者为空（API 18新增） | 检查Processor指针 |
| **HIAPPEVENT_PROCESSOR_NOT_FOUND = -8** | 事件处理者不存在（API 18新增） | 检查Processor是否已添加 |
| **HIAPPEVENT_INVALID_PARAM_VALUE = -9** | 参数值无效（API 15新增） | 检查参数值类型和范围 |
| **HIAPPEVENT_EVENT_CONFIG_IS_NULL = -10** | 事件配置为空（API 15新增） | 检查Config指针 |
| **HIAPPEVENT_OPERATE_FAILED = -100** | 操作失败（API 18新增） | 检查系统状态 |
| **HIAPPEVENT_INVALID_UID = -200** | 无效的用户标识（API 18新增） | 检查UID |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@ohos/hypium": "1.0.6"
  },
  "devDependencies": {
    "@ohos/hvigor-ohos-arkui-x": "4.0.2"
  }
}
```

### 环境要求
- **HarmonyOS SDK**：API 8及以上（打点接口），API 12及以上（订阅接口）
- **开发工具**：DevEco Studio 3.1及以上
- **编译工具**：CMake 3.4.1及以上
- **Native环境**：支持C++11及以上标准
- **三方库**：jsoncpp 1.9.6（推荐）或更高版本

### 常见编译问题

**问题1：找不到hiappevent.h头文件**
```
fatal error: hiappevent/hiappevent.h: No such file or directory
```
**解决方法**：
- 检查HarmonyOS SDK是否正确安装
- 检查是否包含Native SDK路径
- 确保CMakeLists.txt中添加了正确的include路径

**问题2：链接libhiappevent_ndk.z.so失败**
```
undefined reference to `OH_HiAppEvent_CreateWatcher'
```
**解决方法**：
- 在CMakeLists.txt中添加依赖库：
  `target_link_libraries(entry PUBLIC libhiappevent_ndk.z.so)`
- 检查SDK路径配置是否正确

**问题3：jsoncpp库找不到**
```
fatal error: json/json.h: No such file or directory
```
**解决方法**：
- 下载jsoncpp源码或预编译库
- 将库文件放置在thirdparty目录下
- 在CMakeLists.txt中配置include路径和链接库
- 参考[jsoncpp开源库](https://github.com/open-source-parsers/jsoncpp)

**问题4：JSON解析失败**
```
JSON parsing failed: syntax error
```
**解决方法**：
- 使用Json::Features::strictMode()严格模式解析
- 检查事件数据是否为有效JSON格式
- 检查回调函数中的params字段是否为字符串类型

**问题5：观察者指针为nullptr**
```
CreateWatcher returned nullptr
```
**解决方法**：
- 检查观察者名称是否合法（不能为空，不能过长）
- 检查观察者名称是否重复（相同名称会覆盖前一次创建）

**问题6：内存泄漏**
```
Memory leak detected: HiAppEvent_Watcher not destroyed
```
**解决方法**：
- 在应用退出或不需要观察者时，调用OH_HiAppEvent_DestroyWatcher销毁
- 销毁后将指针置为nullptr
- 调用OH_HiAppEvent_DestroyParamList销毁参数列表

## 常见问题与解决方法

### Q1：如何区分OnReceive和OnTrigger两种订阅模式？
**原因**：两种回调机制适用场景不同
**解决方法**：
- **OnReceive模式**：观察者接收到事件后立即触发回调，适用于需要实时处理事件的场景（如崩溃事件监控）
- **OnTrigger模式**：观察者接收事件后先保存，满足触发条件后才触发回调，适用于批量处理或条件触发场景（如用户行为统计）
- 设置回调：使用OH_HiAppEvent_SetWatcherOnReceive设置OnReceive回调，使用OH_HiAppEvent_SetWatcherOnTrigger设置OnTrigger回调
- OnTrigger模式还需要调用OH_HiAppEvent_SetTriggerCondition设置触发条件

### Q2：如何获取订阅到的崩溃事件数据？
**原因**：崩溃事件包含重要调试信息
**解决方法**：
- 在OnReceive回调函数中解析事件数据
- 使用jsoncpp库解析params字段（JSON字符串）
- 获取关键字段：
  - `time`：崩溃时间戳（int64）
  - `bundle_name`：崩溃应用包名（string）
  - `external_log`：故障日志文件路径（string数组）
- 注意：回调函数中的指针生命周期仅限函数内，需要深拷贝数据

### Q3：订阅接口在主线程调用是否会影响性能？
**原因**：OH_HiAppEvent_AddWatcher涉及I/O操作
**解决方法**：
- 根据实际业务场景选择调用线程
- 性能敏感场景：在子线程调用OH_HiAppEvent_AddWatcher
- 一般场景：可在主线程调用，但避免高频调用
- 推荐在应用启动时一次性调用订阅接口

### Q4：如何避免观察者名称冲突？
**原因**：相同名称的观察者会覆盖前一次订阅
**解决方法**：
- 使用唯一标识符作为观察者名称（如"CrashWatcher001"、"ButtonClickWatcher_userA"）
- 避免使用通用的名称（如"Watcher"、"Observer"）
- 在移除观察者前不要创建同名观察者
- 记录已创建的观察者名称，避免重复

### Q5：事件打点失败返回负值怎么办？
**原因**：事件参数校验失败
**解决方法**：
- 检查返回值并分析错误类型：
  - `-1`：事件名称非法，检查名称格式
  - `-4`：事件领域非法，检查领域格式
  - `-99`：打点功能被关闭，检查配置
- 检查参数列表：
  - 参数名称格式：字母开头或$开头，不含下划线结尾，不超过32字符
  - 参数字符串长度：8KB以内
  - 参数数量：32个以内
  - 数组元素数量：100个以内

### Q6：回调函数中的指针能否直接缓存？
**原因**：回调指针生命周期仅限函数内
**解决方法**：
- **禁止**：直接缓存回调函数中的指针（如appEventGroups、events）
- **正确做法**：深拷贝指针指向的数据
  - 使用Json::Value缓存解析后的数据
  - 使用std::string缓存字符串数据
  - 使用std::vector缓存数组数据
- 深拷贝示例：
  ```cpp
  std::string domainStr = appEventGroups[i].appEventInfos[j].domain; // 深拷贝
  Json::Value paramsCopy; // 深拷贝JSON数据
  if (reader.parse(appEventGroups[i].appEventInfos[j].params, paramsCopy)) {
      // paramsCopy可以缓存
  }
  ```

### Q7：如何设置多个事件过滤规则？
**原因**：需要订阅多种类型的事件
**解决方法**：
- OH_HiAppEvent_SetAppEventFilter可以多次调用，添加多个过滤规则
- 观察者将收到满足任一过滤规则的事件
- 示例：
  ```cpp
  // 订阅崩溃事件
  const char *crashNames[] = {EVENT_APP_CRASH};
  OH_HiAppEvent_SetAppEventFilter(watcher, DOMAIN_OS, 0, crashNames, 1);
  
  // 订阅按钮点击事件
  const char *clickNames[] = {"click"};
  OH_HiAppEvent_SetAppEventFilter(watcher, "button", 0, clickNames, 1);
  ```

### Q8：OnTrigger回调触发条件如何设置？
**原因**：需要灵活控制回调时机
**解决方法**：
- OH_HiAppEvent_SetTriggerCondition参数说明：
  - `row`：新接收事件数量阈值（大于0生效，如设置1则每接收1个事件触发）
  - `size`：新接收事件大小阈值（字节，大于0生效）
  - `timeOut`：超时时间（秒，大于0生效，定期检查是否有新事件）
- 至少设置一个条件（row、size、timeOut至少一个大于0）
- 示例：
  ```cpp
  // 每接收1个事件触发
  OH_HiAppEvent_SetTriggerCondition(watcher, 1, 0, 0);
  
  // 每10秒检查一次
  OH_HiAppEvent_SetTriggerCondition(watcher, 0, 0, 10);
  
  // 累积事件大小达到1KB触发
  OH_HiAppEvent_SetTriggerCondition(watcher, 0, 1024, 0);
  ```

### Q9：如何获取已保存的事件数据？
**原因**：OnTrigger模式需要主动获取事件
**解决方法**：
- 在OnTrigger回调中调用OH_HiAppEvent_TakeWatcherData
- eventNum参数：
  - 小于等于0：获取全部已保存事件
  - 大于0：按时间倒序获取指定数量的事件
- 通过OnTake回调函数接收事件数据
- 示例：
  ```cpp
  static void OnTrigger(int row, int size) {
      // 获取row个最新事件
      OH_HiAppEvent_TakeWatcherData(watcher, row, OnTake);
  }
  ```

### Q10：如何正确销毁观察者避免内存泄漏？
**原因**：观察者未销毁会常驻内存
**解决方法**：
- 销毁流程：
  1. 调用OH_HiAppEvent_RemoveWatcher停止监听（可选，销毁前自动移除）
  2. 调用OH_HiAppEvent_DestroyWatcher销毁观察者释放内存
  3. 将观察者指针置为nullptr
- 在应用退出或不需要订阅时销毁
- 示例：
  ```cpp
  if (watcher != nullptr) {
      OH_HiAppEvent_RemoveWatcher(watcher); // 停止监听
      OH_HiAppEvent_DestroyWatcher(watcher); // 销毁释放内存
      watcher = nullptr; // 置空指针
  }
  ```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watchers": [
    {
      "name": "CrashWatcher001",
      "type": "OnReceive",
      "domain": "DOMAIN_OS",
      "events": ["EVENT_APP_CRASH"],
      "status": "registered"
    },
    {
      "name": "ButtonClickWatcher001",
      "type": "OnTrigger",
      "domain": "button",
      "events": ["click"],
      "triggerCondition": "row=1",
      "status": "registered"
    }
  ],
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_SetWatcherOnTrigger",
    "OH_HiAppEvent_SetTriggerCondition",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_Write",
    "OH_HiAppEvent_CreateParamList",
    "OH_HiAppEvent_AddInt64Param",
    "OH_HiAppEvent_DestroyParamList",
    "OH_HiAppEvent_TakeWatcherData",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ],
  "dependencies": [
    "libhiappevent_ndk.z.so",
    "libhilog_ndk.z.so",
    "libjsoncpp.so"
  ],
  "eventsRecorded": {
    "systemEvents": 0,
    "appEvents": 0
  },
  "errors": []
}
```

## 参考文档

- [事件订阅开发指南](references/hiappevent-watcher-app-events-ndk.md)
- [HiAppEvent API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [HiAppEvent模块说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent)
- [HiAppEvent_Watcher结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-watcher)
- [HiAppEvent_AppEventGroup结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-appeventgroup)
- [HiAppEvent_AppEventInfo结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-appeventinfo)
- [ParamListNode结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-paramlistnode8h)
- [HiAppEvent错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h#hiappevent_errorcode)
- [EventType枚举](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h#eventtype)
- [jsoncpp开源库](https://github.com/open-source-parsers/jsoncpp)
- [HiAppEvent示例工程](https://gitcode.com/openharmony/applications_app_samples/tree/master/code/DocsSample/PerformanceAnalysisKit/HiAppEvent/EventSub)

## 完整示例代码

- [完整C++示例代码](assets/hiappevent_watcher_example.cpp)
- [完整ArkTS示例代码](assets/hiappevent_watcher_example.ets)
- [CMakeLists.txt配置](assets/CMakeLists.txt)
- [index.d.ts接口定义](assets/index.d.ts)
- [EntryAbility.ets启动注册](assets/EntryAbility.ets)
- [Index.ets页面示例](assets/Index.ets)

## 测试用例

### 正向测试用例
- [订阅系统崩溃事件成功](tests/test_positive.cpp)：创建崩溃事件观察者，触发崩溃，验证回调接收到崩溃事件数据
- [订阅应用按钮点击事件成功](tests/test_positive.cpp)：创建按钮点击观察者，触发按钮点击，验证回调接收到点击事件数据
- [事件打点成功](tests/test_positive.cpp)：创建参数列表，添加参数，调用打点接口，验证返回值0
- [多观察者订阅成功](tests/test_positive.cpp)：创建多个观察者订阅不同事件，验证各自回调正常触发
- [移除和销毁观察者成功](tests/test_positive.cpp)：移除观察者停止监听，销毁观察者释放内存，验证指针置空

### 边界测试用例
- [观察者名称长度边界](tests/test_boundary.cpp)：测试观察者名称长度达到最大限制，验证创建成功
- [事件参数数量边界](tests/test_boundary.cpp)：测试参数数量达到32个，验证打点成功
- [事件参数字符串长度边界](tests/test_boundary.cpp)：测试字符串参数长度达到8KB，验证打点成功
- [事件参数数组元素边界](tests/test_boundary.cpp)：测试数组元素数量达到100个，验证打点成功
- [触发条件边界](tests/test_boundary.cpp)：测试触发条件row=1最小值，验证OnTrigger回调触发

### 异常测试用例
- [观察者名称非法](tests/test_exception.cpp)：测试观察者名称为空或非法字符，验证创建失败返回nullptr
- [事件名称非法](tests/test_exception.cpp)：测试事件名称格式非法，验证打点失败返回-1
- [事件领域非法](tests/test_exception.cpp)：测试事件领域格式非法，验证打点失败返回-4
- [参数名称非法](tests/test_exception.cpp)：测试参数名称格式非法，验证打点成功但返回1（丢弃非法参数）
- [参数字符串超长](tests/test_exception.cpp)：测试字符串参数超过8KB，验证打点成功但返回4（丢弃超长参数）
- [参数数量超限](tests/test_exception.cpp)：测试参数数量超过32个，验证打点成功但返回5（丢弃超限参数）
- [数组元素超限](tests/test_exception.cpp)：测试数组元素超过100个，验证打点成功但返回6（丢弃超限元素）
- [观察者空指针](tests/test_exception.cpp)：测试传入nullptr观察者指针，验证接口返回-5
- [未添加观察者调用TakeWatcherData](tests/test_exception.cpp)：测试未调用AddWatcher前调用TakeWatcherData，验证返回-6
- [JSON解析失败](tests/test_exception.cpp)：测试回调中JSON解析非法字符串，验证解析失败但不崩溃
- [内存泄漏检测](tests/test_exception.cpp)：测试未销毁观察者，验证内存泄漏警告