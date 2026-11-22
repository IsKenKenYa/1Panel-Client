---
name: hmos-performance-analysis-kit-subscribe-hicollie-event
description: 订阅任务执行超时事件，支持C/C++语言，通过HiAppEvent观察者订阅APP_HICOLLIE系统事件，结合HiCollie定时器检测任务超时，适用于应用性能监控、任务执行超时检测场景
---

# 订阅任务执行超时事件技能

## 功能描述

本技能提供订阅任务执行超时事件的能力，通过HiAppEvent事件观察者机制订阅系统生成的APP_HICOLLIE事件。支持两种观察者模式：onReceive实时接收模式和onTrigger触发条件模式。结合HiCollie定时器检测函数或代码块执行是否超时，生成任务执行超时事件并自动上报。

**核心功能**：
- 创建HiAppEvent观察者订阅系统事件
- 设置事件过滤器监听指定领域和事件名称
- 实现onReceive或onTrigger回调处理事件数据
- 配置HiCollie定时器检测任务执行超时
- 解析事件参数获取超时详细信息（时间、进程、线程、日志等）

**适用场景**：
- 应用性能监控：监控关键任务执行时间，检测卡顿和超时
- 故障诊断：捕获任务超时事件，分析异常原因
- 性能优化：识别耗时操作，优化应用响应速度
- 线程健康检查：监控业务线程执行状态

## 使用场景

### 触发词
- "订阅任务超时事件" - 创建观察者订阅APP_HICOLLIE事件
- "检测任务执行超时" - 使用HiCollie定时器检测超时
- "监控线程卡顿" - 监控业务线程执行状态
- "捕获HiCollie事件" - 接收并处理系统生成的超时事件
- "分析任务超时日志" - 解析事件参数获取日志信息

### 能做
- 创建并配置HiAppEvent观察者订阅系统事件
- 设置事件过滤器监听DOMAIN_OS领域的APP_HICOLLIE事件
- 实现onReceive回调实时接收并处理事件数据
- 实现onTrigger回调按条件触发处理事件数据
- 配置HiCollie定时器检测任务执行是否超时
- 解析事件JSON参数获取超时详细信息（时间、进程、日志等）
- 移除并销毁观察者释放资源

### 绝不做
- 不处理非DOMAIN_OS领域的事件
- 不处理非APP_HICOLLIE名称的事件
- 不在回调函数外直接使用事件指针（需深拷贝）
- 不在appspawn或nativespawn进程中调用HiCollie接口
- 不使用相同名称创建多个观察者（会覆盖）
- 不忘记销毁观察者导致内存泄漏

### 补充
- onReceive模式：观察者接收事件后立即触发回调，适合实时处理
- onTrigger模式：观察者保存事件，满足条件后触发回调，适合批量处理
- HiCollie定时器：设置超时时间阈值，超时后执行回调并生成日志
- 事件参数为JSON字符串，需使用jsoncpp等库解析
- 回调函数中的指针生命周期仅限于回调内，需深拷贝数据
- OH_HiAppEvent_AddWatcher涉及I/O操作，性能敏感场景需考虑线程选择

## 调用规范和规则

### 输入约束
- 观察者名称：非空字符串，不能为NULL
- 事件领域：DOMAIN_OS（系统事件领域）
- 事件名称：EVENT_APP_HICOLLIE（任务执行超时事件）
- 定时器名称：非空字符串，不能为NULL或空字符串
- 超时时间：大于0的整数，单位秒
- 触发条件参数：row、size、timeOut至少设置一个大于0

### 执行约束
- 最大回调处理耗时：建议小于100ms避免阻塞
- 事件数据深拷贝：必须在回调内完成，指针生命周期仅限回调内
- 定时器ID管理：保存ID用于后续取消定时器
- 观察者生命周期：先创建->配置->添加->移除->销毁，顺序不可乱
- 资源释放：观察者和定时器不再使用后必须销毁/取消
- 最大迭代次数：事件处理循环建议不超过1000次

### 内容约束
- 禁止生成：非DOMAIN_OS领域的订阅代码
- 禁止使用高危函数：不使用eval、exec、system等
- 禁止操作：不在回调外直接使用事件指针、不重复创建同名观察者
- 禁止遗漏：必须包含错误码处理、资源释放、参数校验
- JSON解析：必须使用安全的JSON解析库（如jsoncpp）
- 参数校验：校验观察者名称、定时器参数、回调函数指针

### 降级约束
- 观察者创建失败：返回错误提示，建议检查参数
- 定时器设置失败：返回错误提示，建议检查进程上下文
- 事件接收失败：检查观察者是否已添加、过滤器是否正确
- JSON解析失败：记录错误日志，跳过当前事件继续处理
- 回调执行异常：捕获异常，记录日志，不影响其他事件处理
- 内存不足：优先释放已保存事件，降低保存数量

## 调用流程和步骤

### 步骤1：准备阶段 - 导入依赖和配置工程

**前置校验**：
1. 确认工程为Native C++工程
2. 确认已导入jsoncpp库文件（libs和thirdparty目录）
3. 确认已配置CMakeLists.txt添加动态库依赖
4. 确认开发环境支持HarmonyOS NDK

**参数准备**：
```cmake
# CMakeLists.txt配置
add_library(entry SHARED napi_init.cpp)
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libohhicollie.so 
    libhiappevent_ndk.z.so)
target_link_libraries(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so)
target_include_directories(entry PRIVATE 
    ${DEST_DIR}/jsoncpp-1.9.6/include/json)
```

```cpp
// napi_init.cpp导入头文件
#include "napi/native_api.h"
#include "../../../build/jsoncpp-1.9.6/include/json/json.h"
#include "hiappevent/hiappevent.h"
#include "hicollie/hicollie.h"
#include "hilog/log.h"
#undef LOG_TAG
#define LOG_TAG "HiCollieEventWatcher"
```

### 步骤2：创建观察者并配置过滤器

**示例代码 - onReceive模式**：
```cpp
// 定义观察者指针变量（全局或静态）
static HiAppEvent_Watcher *appHicollieWatcherR = nullptr;

// 创建观察者
appHicollieWatcherR = OH_HiAppEvent_CreateWatcher("appHicollieWatcherR");
if (appHicollieWatcherR == nullptr) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
    return;
}

// 设置事件过滤器：监听DOMAIN_OS领域的APP_HICOLLIE事件
const char *names[] = {EVENT_APP_HICOLLIE};  // 事件名称数组
int result = OH_HiAppEvent_SetAppEventFilter(
    appHicollieWatcherR, 
    DOMAIN_OS,        // 事件领域
    0,                // eventTypes: 0表示支持所有类型
    names, 
    1                 // names数组长度
);

if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "SetAppEventFilter failed: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
    appHicollieWatcherR = nullptr;
    return;
}
```

**示例代码 - onTrigger模式**：
```cpp
static HiAppEvent_Watcher *appHicollieWatcherT = nullptr;

appHicollieWatcherT = OH_HiAppEvent_CreateWatcher("appHicollieWatcherT");
if (appHicollieWatcherT == nullptr) {
    OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
    return;
}

const char *names[] = {EVENT_APP_HICOLLIE};
int result = OH_HiAppEvent_SetAppEventFilter(
    appHicollieWatcherT, 
    DOMAIN_OS, 
    0, 
    names, 
    1
);

// 设置触发条件：新增事件数量为1时触发回调
result = OH_HiAppEvent_SetTriggerCondition(appHicollieWatcherT, 1, 0, 0);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "SetTriggerCondition failed: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
    appHicollieWatcherT = nullptr;
    return;
}
```

### 步骤3：实现回调函数处理事件数据

**onReceive回调实现**：
```cpp
static void OnReceiveAppHicollie(const struct HiAppEvent_AppEventGroup *appEventGroups, int i, int j)
{
    // 校验事件领域和名称
    if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 ||
        strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_APP_HICOLLIE) != 0) {
        return;
    }

    // 解析事件参数（JSON字符串）
    Json::Value params;
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    if (!reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
        OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed");
        return;
    }

    // 提取事件参数（必须在回调内完成深拷贝）
    auto time = params["time"].asInt64();
    auto foreground = params["foreground"].asBool();
    auto bundleVersion = params["bundle_version"].asString();
    auto processName = params["process_name"].asString();
    auto pid = params["pid"].asInt();
    auto uid = params["uid"].asInt();
    auto uuid = params["uuid"].asString();
    auto exception = writer.write(params["exception"]);
    auto hilogSize = params["hilog"].size();
    auto peerBindSize = params["peer_binder"].size();
    auto memory = writer.write(params["memory"]);
    auto externalLog = writer.write(params["external_log"]);
    auto logOverLimit = params["log_over_limit"].asBool();
    auto externalCallbackLog = params["external_callback_log"].asString();

    // 记录事件信息（深拷贝后的数据可在回调外使用）
    OH_LOG_INFO(LogType::LOG_APP, "Event received: domain=%{public}s, name=%{public}s",
        appEventGroups[i].appEventInfos[j].domain,
        appEventGroups[i].appEventInfos[j].name);
    OH_LOG_INFO(LogType::LOG_APP, "time=%{public}lld, foreground=%{public}d, pid=%{public}d",
        time, foreground, pid);
}

static void AppHicollieOnReceive(const char *domain, 
    const struct HiAppEvent_AppEventGroup *appEventGroups,
    uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OnReceiveAppHicollie(appEventGroups, i, j);
        }
    }
}
```

**onTrigger回调实现**：
```cpp
static void AppHicollieOnTake(const char* const *events, uint32_t eventLen)
{
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (!reader.parse(events[i], eventInfo)) {
            OH_LOG_ERROR(LogType::LOG_APP, "JSON parse failed");
            continue;
        }

        auto domain = eventInfo["domain_"].asString();
        auto name = eventInfo["name_"].asString();
        
        if (domain == DOMAIN_OS && name == EVENT_APP_HICOLLIE) {
            auto time = eventInfo["time"].asInt64();
            auto foreground = eventInfo["foreground"].asBool();
            auto pid = eventInfo["pid"].asInt();
            // ... 其他参数处理
            OH_LOG_INFO(LogType::LOG_APP, "Event taken: time=%{public}lld, pid=%{public}d",
                time, pid);
        }
    }
}

static void AppHicollieOnTrigger(int row, int size)
{
    // 获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(appHicollieWatcherT, row, AppHicollieOnTake);
}
```

### 步骤4：添加观察者开始监听

**示例代码**：
```cpp
// onReceive模式：设置回调并添加观察者
int result = OH_HiAppEvent_SetWatcherOnReceive(appHicollieWatcherR, AppHicollieOnReceive);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnReceive failed: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
    appHicollieWatcherR = nullptr;
    return;
}

result = OH_HiAppEvent_AddWatcher(appHicollieWatcherR);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
    appHicollieWatcherR = nullptr;
    return;
}

OH_LOG_INFO(LogType::LOG_APP, "Watcher added successfully");
```

```cpp
// onTrigger模式：设置回调并添加观察者
int result = OH_HiAppEvent_SetWatcherOnTrigger(appHicollieWatcherT, AppHicollieOnTrigger);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "SetWatcherOnTrigger failed: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
    appHicollieWatcherT = nullptr;
    return;
}

result = OH_HiAppEvent_AddWatcher(appHicollieWatcherT);
if (result != 0) {
    OH_LOG_ERROR(LogType::LOG_APP, "AddWatcher failed: %{public}d", result);
    OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
    appHicollieWatcherT = nullptr;
    return;
}
```

### 步骤5：配置HiCollie定时器触发超时事件

**示例代码**：
```cpp
#include <unistd.h>

// 定义超时回调函数
void HiCollieTimerCallback(void* arg)
{
    OH_LOG_INFO(LogType::LOG_APP, "HiCollie timer timeout callback executed");
}

// 注册HiCollie定时器检测任务超时
static napi_value TestHiCollieTimerNdk(napi_env env, napi_callback_info info)
{
    int timerId = 0;
    
    // 设置定时器参数
    HiCollie_SetTimerParam param = {
        "testTimer",                    // timer任务名称
        1,                              // 超时时间：1秒
        HiCollieTimerCallback,          // 超时回调函数
        nullptr,                        // 回调函数参数
        HiCollie_Flag::HICOLLIE_FLAG_LOG // 超时动作：生成日志
    };
    
    HiCollie_ErrorCode errorCode = OH_HiCollie_SetTimer(param, &timerId);
    
    if (errorCode == HICOLLIE_SUCCESS) {
        OH_LOG_INFO(LogType::LOG_APP, "Timer set successfully, id=%{public}d", timerId);
        
        // 模拟耗时任务（阻塞2秒超过1秒超时阈值）
        sleep(2);
        
        // 取消定时器（如果任务按时完成）
        OH_HiCollie_CancelTimer(timerId);
        OH_LOG_INFO(LogType::LOG_APP, "Timer canceled");
    } else {
        OH_LOG_ERROR(LogType::LOG_APP, "SetTimer failed: %{public}d", errorCode);
        // 错误处理：
        // HICOLLIE_INVALID_TIMER_NAME (29800003): 检查名称是否为空
        // HICOLLIE_INVALID_TIMEOUT_VALUE (29800004): 检查超时值是否有效
        // HICOLLIE_WRONG_PROCESS_CONTEXT (29800005): 检查是否在appspawn/nativespawn进程
        // HICOLLIE_WRONG_TIMER_ID_OUTPUT_PARAM (29800006): 检查id指针是否为NULL
    }
    
    return nullptr;
}
```

### 步骤6：移除并销毁观察者释放资源

**示例代码**：
```cpp
// 移除观察者（停止监听）
static napi_value RemoveWatcher(napi_env env, napi_callback_info info)
{
    if (appHicollieWatcherR != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(appHicollieWatcherR);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher failed: %{public}d", result);
        }
    }
    
    if (appHicollieWatcherT != nullptr) {
        int result = OH_HiAppEvent_RemoveWatcher(appHicollieWatcherT);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "RemoveWatcher failed: %{public}d", result);
        }
    }
    
    return {};
}

// 销毁观察者（释放内存）
static napi_value DestroyWatcher(napi_env env, napi_callback_info info)
{
    if (appHicollieWatcherR != nullptr) {
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherR);
        appHicollieWatcherR = nullptr;  // 置空防止误用
    }
    
    if (appHicollieWatcherT != nullptr) {
        OH_HiAppEvent_DestroyWatcher(appHicollieWatcherT);
        appHicollieWatcherT = nullptr;
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watchers destroyed");
    return {};
}
```

### 步骤7：注册ArkTS接口

**示例代码**：
```cpp
// napi_init.cpp Init函数
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "RegisterAppHicollieWatcherR", nullptr, RegisterAppHicollieWatcherR, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "RegisterAppHicollieWatcherT", nullptr, RegisterAppHicollieWatcherT, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "TestHiCollieTimerNdk", nullptr, TestHiCollieTimerNdk, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "RemoveWatcher", nullptr, RemoveWatcher, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
        { "DestroyWatcher", nullptr, DestroyWatcher, 
          nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}

// index.d.ts定义接口
export const RegisterAppHicollieWatcherR: () => void;
export const RegisterAppHicollieWatcherT: () => void;
export const TestHiCollieTimerNdk: () => void;
export const RemoveWatcher: () => void;
export const DestroyWatcher: () => void;
```

### 步骤8：在ArkTS中调用接口

**示例代码**：
```typescript
// EntryAbility.ets
import testNapi from 'libentry.so';

export default class EntryAbility {
    onCreate(want, launchParam) {
        // 启动时注册观察者
        testNapi.RegisterAppHicollieWatcherR();  // 注册onReceive观察者
        testNapi.RegisterAppHicollieWatcherT();  // 注册onTrigger观察者
    }
    
    onDestroy() {
        // 销毁时移除和销毁观察者
        testNapi.RemoveWatcher();
        testNapi.DestroyWatcher();
    }
}

// Index.ets
import testNapi from 'libentry.so';

@Entry
@Component
struct Index {
    build() {
        Column() {
            Button('触发任务超时事件')
                .onClick(() => {
                    testNapi.TestHiCollieTimerNdk();
                })
        }
    }
}
```

## 错误码说明

### HiAppEvent错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 接口调用成功 | 无需处理 |
| -1 | 非法的事件名称 | 检查事件名称格式：首字符字母/$，中间数字/字母/下划线，结尾数字/字母，长度≤48 |
| -4 | 非法的domain参数 | 检查domain格式：数字/字母/下划线，字母开头，不下划线结尾，长度≤32 |
| -5 | watcher入参空指针 | 检查watcher指针是否为nullptr，确保CreateWatcher成功 |
| -6 | 未调用AddWatcher，操作顺序有误 | 确保在TakeWatcherData前调用AddWatcher |
| 1 | 非法的事件参数名称 | 检查参数名格式：首字符字母/$，中间数字/字母/下划线，结尾数字/字母，长度≤32 |
| 4 | 非法的事件参数字符串长度 | 检查字符串参数长度≤8*1024字符 |
| 5 | 非法的事件参数数量 | 检查参数数量≤32个 |
| 6 | 非法的事件参数数组长度 | 检查数组元素数量≤100个 |
| 8 | 重复的事件参数名称 | 检查是否有重复参数名 |

### HiCollie错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| HICOLLIE_SUCCESS (0) | 成功 | 无需处理 |
| HICOLLIE_INVALID_ARGUMENT (401) | 无效参数 | 检查beginFunc和endFunc是否都为空或都有值 |
| HICOLLIE_WRONG_THREAD_CONTEXT (29800001) | 调用线程错误 | 在非主线程中调用该函数 |
| HICOLLIE_REMOTE_FAILED (29800002) | 远程调用错误 | 检查IPC远程服务是否可用 |
| HICOLLIE_INVALID_TIMER_NAME (29800003) | 无效的计时器名称 | 检查timer名称不为NULL或空字符串 |
| HICOLLIE_INVALID_TIMEOUT_VALUE (29800004) | 无效的超时值 | 检查超时值>0且在合理范围 |
| HICOLLIE_WRONG_PROCESS_CONTEXT (29800005) | 进程上下文错误 | 不在appspawn或nativespawn进程中调用 |
| HICOLLIE_WRONG_TIMER_ID_OUTPUT_PARAM (29800006) | id指针为NULL | 确保id指针参数不为NULL |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

# 设置OHOS架构
set(OHOS_ARCH arm64-v8a)

# 添加动态库
add_library(entry SHARED napi_init.cpp)

# 链接系统库
target_link_libraries(entry PUBLIC 
    libace_napi.z.so          # NAPI接口
    libhilog_ndk.z.so         # 日志输出
    libohhicollie.so          # HiCollie检测
    libhiappevent_ndk.z.so    # HiAppEvent事件订阅
)

# 配置jsoncpp库
set(GZ_FILE "${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/src/jsoncpp-1.9.6.tar.gz")
set(DEST_DIR "${CMAKE_CURRENT_SOURCE_DIR}/../../../build")
execute_process(COMMAND ${CMAKE_COMMAND} -E make_directory ${DEST_DIR})
execute_process(COMMAND tar -xzf ${GZ_FILE} -C ${DEST_DIR} WORKING_DIRECTORY ${DEST_DIR})

# 链接jsoncpp库
target_link_libraries(entry PRIVATE 
    ${CMAKE_CURRENT_SOURCE_DIR}/thirdparty/jsoncpp/${OHOS_ARCH}/lib/libjsoncpp.so
)
target_include_directories(entry PRIVATE 
    ${DEST_DIR}/jsoncpp-1.9.6/include/json
)
```

### 环境要求

- HarmonyOS SDK: API 12及以上
- 开发工具: DevEco Studio 3.1及以上
- NDK版本: HarmonyOS Native SDK
- jsoncpp库: 1.9.6版本
- 编译工具: CMake 3.4.1及以上

### 常见编译问题

**问题1：找不到hiappevent.h头文件**
```
fatal error: hiappevent/hiappevent.h: No such file or directory
```
**解决方法**：
- 确认已安装HarmonyOS NDK
- 确认CMakeLists.txt正确配置了include路径
- 检查头文件路径：`#include "hiappevent/hiappevent.h"`

**问题2：找不到jsoncpp库**
```
undefined reference to `Json::Reader::Reader(Json::Features)'
```
**解决方法**：
- 确认jsoncpp库文件存在于thirdparty目录
- 确认CMakeLists.txt正确链接libjsoncpp.so
- 确认jsoncpp头文件路径正确

**问题3：动态库链接失败**
```
cannot find -lhiappevent_ndk.z.so
```
**解决方法**：
- 确认HarmonyOS SDK已正确安装
- 确认库文件路径在系统库目录
- 检查库文件名称是否正确

**问题4：运行时崩溃**
```
HiCollieTimerNdk crash: THREAD_BLOCK_3S
```
**解决方法**：
- 这是正常的超时检测结果
- 检查任务是否真的超时（sleep超过阈值）
- 调整超时时间或优化任务执行速度

## 常见问题与解决方法

### Q1：观察者未接收到事件
**原因**：
- 观察者未添加或添加失败
- 事件过滤器配置错误
- 事件领域或名称不匹配

**解决方法**：
- 检查OH_HiAppEvent_AddWatcher返回值是否为0
- 确认SetAppEventFilter设置了正确的DOMAIN_OS和EVENT_APP_HICOLLIE
- 检查事件是否真的生成（通过日志确认）

### Q2：定时器设置失败
**原因**：
- 在appspawn或nativespawn进程中调用
- timer名称为空或NULL
- id指针为NULL

**解决方法**：
- 确认在应用进程中调用（不在系统spawn进程）
- 确保timer名称为非空字符串
- 确保id指针参数不为NULL

### Q3：JSON解析失败
**原因**：
- jsoncpp库未正确导入
- JSON字符串格式错误
- 事件参数结构不匹配

**解决方法**：
- 确认jsoncpp库正确链接和导入
- 使用strictMode解析器提高容错性
- 添加解析失败的错误处理和日志

### Q4：回调函数中数据丢失
**原因**：
- 回调函数外直接使用事件指针
- 未在回调内进行深拷贝

**解决方法**：
- 所有数据提取必须在回调函数内完成
- 使用JSON解析将字符串转换为可保存的数据类型
- 回调外使用深拷贝后的数据，不直接使用指针

### Q5：内存泄漏
**原因**：
- 观察者未销毁
- 定时器未取消

**解决方法**：
- 应用退出时调用RemoveWatcher和DestroyWatcher
- 任务完成后调用OH_HiCollie_CancelTimer
- 将观察者指针置nullptr防止误用

### Q6：观察者名称冲突
**原因**：
- 使用相同名称创建多个观察者
- 后一次订阅覆盖前一次

**解决方法**：
- 每个观察者使用唯一名称
- 如需替换观察者，先销毁旧观察者再创建新观察者

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherCreated": ["appHicollieWatcherR", "appHicollieWatcherT"],
  "eventsReceived": {
    "domain": "OS",
    "name": "APP_HICOLLIE",
    "count": 1,
    "lastEventTime": "1740993639620"
  },
  "eventParams": {
    "time": 1740993639620,
    "foreground": true,
    "bundle_version": "1.0.0",
    "process_name": "com.example.myapplication",
    "pid": 26251,
    "uid": 20020172,
    "uuid": "4e5d7d0e18f5d6d84cf4f0c9e80d66d0b646c1cc2343d3595f07abb0d3547feb",
    "hilogSize": 77,
    "peerBindSize": 18,
    "log_over_limit": false,
    "external_log": ["APP_HICOLLIE_1740993644458_26215.log"]
  },
  "timerSet": {
    "id": 1,
    "name": "testTimer",
    "timeout": 1,
    "timeoutTriggered": true
  },
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_SetWatcherOnTrigger",
    "OH_HiAppEvent_SetTriggerCondition",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiCollie_SetTimer",
    "OH_HiCollie_CancelTimer",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ]
}
```

## 参考文档

- [订阅任务执行超时事件开发指南](references/hiappevent-watcher-apphicollie-events-ndk.md)
- [HiAppEvent C API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [HiCollie C API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie-h)
- [HiAppEvent_Watcher结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-watcher)
- [HiCollie_SetTimerParam结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hicollie-hicollie-settimerparam)

## 完整示例代码

- [C++完整示例：订阅HiCollie事件](assets/example_subscribe_hicollie.cpp)
- [CMakeLists.txt配置示例](assets/example_cmake.txt)
- [ArkTS接口调用示例](assets/example_arkts.ets)
- [jsoncpp库配置说明](assets/jsoncpp_setup.md)

## 测试用例

### 正向测试用例
- [创建观察者并成功订阅事件](tests/test_positive.cpp)：验证观察者创建、配置、添加流程
- [设置定时器并成功触发超时](tests/test_timer_positive.cpp)：验证定时器设置、超时检测、回调执行
- [接收事件并成功解析参数](tests/test_parse_event.cpp)：验证事件接收、JSON解析、参数提取

### 边界测试用例
- [最小超时时间测试](tests/test_boundary_timeout.cpp)：测试超时时间=1秒的边界值
- [最大事件参数数量测试](tests/test_boundary_params.cpp)：测试事件参数数量=32的边界值
- [观察者名称长度测试](tests/test_boundary_name.cpp)：测试观察者名称长度边界值

### 异常测试用例
- [观察者创建失败处理](tests/test_exception_watcher.cpp)：测试名称为NULL的异常情况
- [定时器设置失败处理](tests/test_exception_timer.cpp)：测试timer名称为空的异常情况
- [JSON解析失败处理](tests/test_exception_parse.cpp)：测试JSON格式错误的异常情况
- [回调函数异常处理](tests/test_exception_callback.cpp)：测试回调执行异常的错误处理