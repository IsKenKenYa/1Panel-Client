---
name: hmos-performance-analysis-kit-appfreeze-warning-subscription
description: 订阅应用冻屏告警事件，支持onReceive和onTrigger两种观察者模式，适用于应用性能监控和故障诊断场景
---

# 订阅应用冻屏告警事件技能

## 功能描述

使用HiAppEvent提供的C/C++接口订阅应用冻屏告警事件。应用冻屏告警事件（APPFREEZE_WARNING）是系统事件，当应用主线程阻塞超过5秒时会触发该事件。开发者可以通过订阅该事件实现应用性能监控和故障诊断。

主要功能：
- 创建事件观察者监听应用冻屏告警事件
- 支持onReceive实时接收模式和onTrigger批量触发模式
- 获取冻屏事件的详细信息（时间、进程、线程、内存等）
- 提供移除和销毁观察者的完整生命周期管理

## 使用场景

### 触发词
- "订阅应用冻屏告警事件"
- "监听应用冻屏"
- "应用冻屏事件订阅"
- "APPFREEZE_WARNING事件"
- "应用性能监控"
- "应用故障诊断"

### 能做
- 订阅系统应用冻屏告警事件（APPFREEZE_WARNING）
- 实时接收冻屏事件信息
- 批量处理冻屏事件数据
- 获取冻屏事件的详细参数（时间、进程名、线程信息、内存数据等）
- 管理观察者的生命周期（添加、移除、销毁）

### 绝不做
- 不订阅非系统领域（DOMAIN_OS）的事件
- 不订阅除APPFREEZE_WARNING外的其他事件
- 不在回调函数外直接使用回调中的指针（需深拷贝）
- 不在未调用OH_HiAppEvent_AddWatcher前调用OH_HiAppEvent_TakeWatcherData

### 补充
- 回调中的指针生命周期仅限于回调函数内
- OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景需考虑线程选择
- 相同name的订阅会覆盖之前的订阅
- 需要导入jsoncpp库解析事件参数

## 调用规范和规则

### 输入约束
- 观察者名称：字符串，系统根据名称识别不同观察者
- 事件名称：固定为OH_EVENT_APP_FREEZE_WARNING
- 事件领域：固定为DOMAIN_OS
- 事件类型：0（监听所有类型）或指定类型掩码
- 触发条件参数：
  - row：新接收事件数量阈值，大于0生效
  - size：新接收事件大小阈值（字节），大于0生效
  - timeOut：超时时间（秒），大于0生效

### 执行约束
- 最大耗时：OH_HiAppEvent_AddWatcher涉及I/O，建议在子线程调用（性能敏感场景）
- 最大迭代次数：观察者回调内避免复杂操作
- API调用频次：无限制，但相同name会覆盖
- 内存管理：必须销毁创建的观察者防止内存泄漏

### 内容约束
- 禁止生成：非系统事件的订阅代码
- 禁止使用高危函数：回调内避免阻塞操作
- 禁止操作：回调外直接使用回调指针（需深拷贝）

### 降级约束
- 回调失败：记录日志，不影响后续事件接收
- 解析失败：使用Json::Reader strict模式，失败时记录错误
- 内存不足：及时销毁观察者释放资源

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证是否为Native C++工程
2. 验证是否导入jsoncpp库（json.h, json-forwards.h, jsoncpp.cpp）
3. 验证是否导入hiappevent头文件（hiappevent/hiappevent.h）
4. 验证是否导入hilog头文件（hilog/log.h）

**参数准备**：
```cpp
// 导入必要头文件
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

// 定义日志标签
#undef LOG_TAG
#define LOG_TAG "testTag"

// 定义观察者指针
static HiAppEvent_Watcher *systemEventWatcher;
```

**工程结构准备**：
```
entry:
  src:
    main:
      cpp:
        json:
          - json.h
          - json-forwards.h
        types:
          libentry:
            - index.d.ts
        - CMakeLists.txt
        - jsoncpp.cpp
        - napi_init.cpp
      ets:
        entryability:
          - EntryAbility.ets
        pages:
          - Index.ets
```

### 步骤2：创建观察者并设置过滤器

**onReceive模式示例代码**：
```cpp
// 定义onReceive回调函数
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            // 判断是否为应用冻屏告警事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, OH_EVENT_APP_FREEZE_WARNING) == 0) {
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                // 解析事件参数
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    auto time = params["time"].asInt64();
                    auto foreground = params["foreground"].asBool();
                    auto bundleName = params["bundle_name"].asString();
                    auto processName = params["process_name"].asString();
                    auto pid = params["pid"].asInt();
                    auto uid = params["uid"].asInt();
                    
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.foreground=%{public}d", foreground);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.process_name=%{public}s", processName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.pid=%{public}d", pid);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.uid=%{public}d", uid);
                }
            }
        }
    }
}

// 创建观察者并订阅事件
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 创建观察者，自定义观察者名称
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onReceiverWatcher");
    
    // 设置订阅的事件为OH_EVENT_APP_FREEZE_WARNING
    const char *names[] = {OH_EVENT_APP_FREEZE_WARNING};
    
    // 设置事件过滤器：领域为DOMAIN_OS，事件类型为0（所有类型），事件名称数组
    OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    
    // 设置onReceive回调函数
    OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    
    // 添加观察者，开始监听
    OH_HiAppEvent_AddWatcher(systemEventWatcher);
    
    return {};
}
```

**onTrigger模式示例代码**：
```cpp
// 定义OnTake回调函数，用于处理获取的事件数据
static void OnTake(const char* const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            
            // 判断是否为应用冻屏告警事件
            if (domain == DOMAIN_OS && name == OH_EVENT_APP_FREEZE_WARNING) {
                auto time = eventInfo["time"].asInt64();
                auto foreground = eventInfo["foreground"].asBool();
                auto bundleName = eventInfo["bundle_name"].asString();
                auto processName = eventInfo["process_name"].asString();
                auto pid = eventInfo["pid"].asInt();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent params.time=%{public}lld", time);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent params.foreground=%{public}d", foreground);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent params.bundle_name=%{public}s", bundleName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent params.process_name=%{public}s", processName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent params.pid=%{public}d", pid);
            }
        }
    }
}

// 定义OnTrigger回调函数
static void OnTrigger(int row, int size) {
    // 获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcher, row, OnTake);
}

// 创建观察者并订阅事件
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 创建观察者
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onTriggerWatcher");
    
    // 设置事件过滤器
    const char *names[] = {OH_EVENT_APP_FREEZE_WARNING};
    OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    
    // 设置onTrigger回调
    OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcher, OnTrigger);
    
    // 设置触发条件：新增1个事件时触发
    OH_HiAppEvent_SetTriggerCondition(systemEventWatcher, 1, 0, 0);
    
    // 添加观察者
    OH_HiAppEvent_AddWatcher(systemEventWatcher);
    
    return {};
}
```

### 步骤3：注册ArkTS接口

**示例代码**：
```cpp
// 将RegisterWatcher注册为ArkTS接口
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**index.d.ts文件**：
```typescript
export const registerWatcher: () => void;
```

### 步骤4：在应用入口调用

**EntryAbility.ets示例代码**：
```typescript
// 导入依赖模块
import testNapi from 'libentry.so'

// 在onCreate()函数中调用
export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 启动时注册系统事件观察者
        testNapi.registerWatcher();
    }
}
```

### 步骤5：移除和销毁观察者

**示例代码**：
```cpp
// 移除观察者
static napi_value RemoveWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        // 使观察者停止监听事件
        OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
    }
    return {};
}

// 销毁观察者
static napi_value DestroyWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        // 销毁创建的观察者
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
    }
    return {};
}
```

### 步骤6：配置CMakeLists.txt

**CMakeLists.txt示例**：
```cmake
# 新增jsoncpp.cpp源文件（用于解析订阅事件中的json字符串）
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 新增动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

### 步骤7：错误处理

```cpp
// 创建观察者时的错误处理
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("freezeWatcher");
    
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    const char *names[] = {OH_EVENT_APP_FREEZE_WARNING};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        return {};
    }
    
    return {};
}

// JSON解析错误处理
if (!reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to parse event params");
    continue;
}
```

### 步骤8：降级处理

```cpp
// 降级处理：内存不足时及时销毁观察者
static napi_value CleanupWatcher(napi_env env, napi_callback_info info) {
    try {
        if (systemEventWatcher != nullptr) {
            OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
            OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
            systemEventWatcher = nullptr;
        }
    } catch (...) {
        OH_LOG_WARN(LogType::LOG_APP, "Exception during watcher cleanup");
        systemEventWatcher = nullptr;
    }
    return {};
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 接口调用成功 | 正常流程继续 |
| -1 | names参数异常 | 检查事件名称数组是否正确 |
| -4 | domain参数异常 | 确认domain为DOMAIN_OS |
| -5 | watcher入参空指针 | 检查观察者是否成功创建 |
| -6 | 未调用AddWatcher就调用TakeWatcherData | 先调用OH_HiAppEvent_AddWatcher |
| HIAPPEVENT_SUCCESS | 操作成功（值=0） | 正常处理 |
| HIAPPEVENT_INVALID_PARAM_VALUE | 参数值无效（值=-9） | 检查参数类型和范围 |
| HIAPPEVENT_EVENT_CONFIG_IS_NULL | 事件配置为空（值=-10） | 检查配置对象 |
| HIAPPEVENT_OPERATE_FAILED | 操作失败（值=-100） | 检查系统状态和权限 |
| HIAPPEVENT_INVALID_UID | 无效的用户标识（值=-200） | 检查应用权限配置 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt依赖**：
```cmake
# 必需的库
libhiappevent_ndk.z.so  # HiAppEvent NDK库
libhilog_ndk.z.so       # 日志库
libace_napi.z.so        # NAPI库

# 第三方库
jsoncpp                 # JSON解析库
```

**jsoncpp导入**：
从 https://github.com/open-source-parsers/jsoncpp 下载源码，按照README的 Amalgamated 步骤生成：
- jsoncpp.cpp
- json.h
- json-forwards.h

### 环境要求
- HarmonyOS API版本：12+
- 开发环境：DevEco Studio
- Native C++工程模板
- 系统能力：SystemCapability.HiviewDFX.HiAppEvent

### 常见编译问题

**问题1：找不到hiappevent.h头文件**
```
fatal error: hiappevent/hiappevent.h: No such file or directory
```
**解决方法**：确认使用Native C++工程模板，系统头文件会自动包含

**问题2：jsoncpp链接失败**
```
undefined reference to `Json::Reader::parse'
```
**解决方法**：
1. 在CMakeLists.txt中添加jsoncpp.cpp源文件
2. 将json.h和json-forwards.h放在cpp/json目录

**问题3：动态库链接失败**
```
cannot find -lhiappevent_ndk.z
```
**解决方法**：确认target_link_libraries中添加了libhiappevent_ndk.z.so

**问题4：回调函数编译错误**
```
error: invalid conversion from 'void (*)(const char*, ...)' to 'OH_HiAppEvent_OnReceive'
```
**解决方法**：确认回调函数签名与API定义完全匹配

## 常见问题与解决方法

### Q1：观察者未接收到事件
**原因**：
1. 观察者未成功添加
2. 事件过滤器设置错误
3. 未触发冻屏场景（主线程阻塞超过5秒）

**解决方法**：
1. 检查OH_HiAppEvent_AddWatcher返回值是否为0
2. 确认domain为DOMAIN_OS，事件名称为OH_EVENT_APP_FREEZE_WARNING
3. 在应用中创建冻屏场景（主线程阻塞6.5秒以上）

### Q2：回调函数中解析JSON失败
**原因**：
1. jsoncpp库未正确导入
2. JSON格式不符合预期
3. 使用了错误的解析模式

**解决方法**：
1. 确认jsoncpp.cpp已添加到CMakeLists.txt
2. 使用Json::Reader的strict模式解析
3. 添加错误日志输出，查看原始JSON字符串

### Q3：观察者重复订阅
**原因**：相同的观察者名称会覆盖之前的订阅

**解决方法**：
1. 为不同的观察者使用不同的名称
2. 在重新订阅前先移除旧观察者
3. 避免在应用生命周期内重复调用registerWatcher

### Q4：内存泄漏
**原因**：观察者创建后未销毁

**解决方法**：
1. 在应用退出时调用DestroyWatcher
2. 将观察者指针置为nullptr
3. 在移除观察者后再销毁

### Q5：TakeWatcherData返回错误码-6
**原因**：未调用OH_HiAppEvent_AddWatcher就调用OH_HiAppEvent_TakeWatcherData

**解决方法**：
1. 确保调用顺序正确：CreateWatcher -> SetFilter -> SetOnTrigger -> AddWatcher -> TakeWatcherData
2. 检查AddWatcher是否返回成功

### Q6：回调中的指针在回调外使用导致崩溃
**原因**：回调中的指针生命周期仅限于回调函数内

**解决方法**：
1. 在回调内对需要的数据进行深拷贝
2. 不要将回调中的指针保存到全局变量
3. 使用Json解析后保存解析结果而非原始指针

## 输出结果报告

执行完成后输出以下信息：

**日志输出示例**：
```
HiAppEvent eventInfo.domain=OS
HiAppEvent eventInfo.name=APPFREEZE_WARNING
HiAppEvent eventInfo.eventType=1
HiAppEvent eventInfo.params.time=1776946769389
HiAppEvent eventInfo.params.foreground=1
HiAppEvent eventInfo.params.bundle_name=com.example.myapplication
HiAppEvent eventInfo.params.process_name=com.example.myapplication
HiAppEvent eventInfo.params.pid=1587
HiAppEvent eventInfo.params.uid=20010043
```

**返回值说明**：
```json
{
  "status": "success",
  "watcherName": "onReceiverWatcher/onTriggerWatcher",
  "eventType": "APPFREEZE_WARNING",
  "eventDomain": "DOMAIN_OS",
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_AddWatcher"
  ]
}
```

**事件参数说明**：
- time：冻屏发生时间（毫秒）
- foreground：是否前台运行（true/false）
- app_running_unique_id：应用运行唯一标识
- bundle_version：应用版本号
- bundle_version_code：应用版本代码
- bundle_name：应用包名
- process_name：进程名
- pid：进程ID
- uid：用户ID
- exception：异常信息（JSON字符串）
- hilog：系统日志数组
- event_handler：事件处理器信息
- peer_binder：peer binder信息
- threads：线程信息数组
- memory：内存信息（JSON字符串）
- process_life_time：进程生命周期时长（秒）

## 参考文档

- [API开发指南：订阅应用冻屏告警事件](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/hiappevent-watcher-appfreezewarning-events-ndk)
- [API参考说明：hiappevent.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)

## 完整示例代码

- [C++完整示例：onReceive模式](assets/example_onreceive.cpp)
- [C++完整示例：onTrigger模式](assets/example_ontrigger.cpp)
- [CMakeLists.txt配置示例](assets/CMakeLists.txt)
- [index.d.ts接口定义](assets/index.d.ts)
- [EntryAbility.ets调用示例](assets/EntryAbility.ets)

## 测试用例

### 正向测试用例
- [正常订阅冻屏事件](tests/test_positive.cpp)：创建观察者、设置过滤器、添加观察者、触发冻屏、接收事件
- [onReceive模式测试](tests/test_onreceive.cpp)：验证onReceive回调能正确接收并解析事件
- [onTrigger模式测试](tests/test_ontrigger.cpp)：验证onTrigger回调和TakeWatcherData能正确获取事件

### 边界测试用例
- [最小触发条件测试](tests/test_boundary.cpp)：设置row=1验证最小触发条件
- [多次订阅测试](tests/test_multiple_subscribe.cpp)：验证相同name会覆盖订阅
- [大事件数据测试](tests/test_large_event.cpp)：验证处理包含大量hilog和threads的事件

### 异常测试用例
- [空指针测试](tests/test_null_pointer.cpp)：传入nullptr观察者，验证返回-5错误码
- [错误domain测试](tests/test_wrong_domain.cpp)：设置非DOMAIN_OS领域，验证无法接收事件
- [未AddWatcher测试](tests/test_no_addwatcher.cpp)：未调用AddWatcher直接调用TakeWatcherData，验证返回-6
- [JSON解析失败测试](tests/test_json_parse_fail.cpp)：提供无效JSON字符串，验证错误处理
- [重复销毁测试](tests/test_double_destroy.cpp)：销毁观察者后再次销毁，验证不会崩溃