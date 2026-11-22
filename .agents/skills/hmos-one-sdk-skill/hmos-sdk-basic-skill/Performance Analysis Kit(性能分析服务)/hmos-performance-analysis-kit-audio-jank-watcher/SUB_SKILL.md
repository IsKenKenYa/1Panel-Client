---
name: hmos-performance-analysis-kit-audio-jank-watcher
description: 订阅音频卡顿系统事件AUDIO_JANK_FRAME,实时监听音频卡顿故障,获取卡顿参数信息,适用于音频播放性能监控场景
---

# 订阅音频卡顿事件(C/C++)技能

## 功能描述

本技能用于使用HiAppEvent提供的C/C++接口订阅音频卡顿系统事件(AUDIO_JANK_FRAME)。音频卡顿事件是在音频播放过程中,由于音频数据写入回调返回INVALID导致音频播放中断时触发的系统故障事件。通过订阅该事件,开发者可以实时获取音频卡顿的详细信息,包括卡顿时间、应用包名、故障类型、发生时间、最大帧时长等参数,用于音频播放性能监控和问题定位。

### 核心能力

- 创建HiAppEvent监听器观察音频卡顿事件
- 支持onReceive类型观察者实时接收事件
- 支持onTrigger类型观察者条件触发接收事件
- 解析音频卡顿事件参数信息
- 提供两种观察者模式的完整实现流程

### 适用范围

- 音频播放应用性能监控
- 音频卡顿故障诊断和定位
- 音频播放质量分析
- Native C++工程开发

### 限制条件

- 需要API版本21及以上(音频卡顿事件起始版本)
- 需要Native C++工程支持
- 需要依赖jsoncpp库解析JSON参数
- 需要libhiappevent_ndk.z.so和libhilog_ndk.z.so库
- 监听器名称必须唯一

### 典型场景

- 音乐播放器应用监控音频卡顿
- 实时音频通话应用质量监控
- 音频编辑应用性能分析
- 游戏音频播放故障诊断

## 使用场景

### 触发词

- "订阅音频卡顿事件"
- "监听音频卡顿"
- "音频卡顿监控"
- "AUDIO_JANK_FRAME事件订阅"
- "HiAppEvent音频卡顿"
- "音频播放性能监控"

### 能做

- 创建HiAppEvent监听器订阅音频卡顿系统事件
- 实现onReceive回调实时接收音频卡顿事件
- 实现onTrigger回调条件触发接收事件
- 解析音频卡顿事件参数(time, bundle_version, bundle_name, fault_type, happen_time, max_frame_time)
- 将监听器注册为ArkTS接口供应用层调用
- 提供两种观察者模式的完整实现方案

### 绝不做

- 不订阅其他系统事件(仅订阅AUDIO_JANK_FRAME)
- 不处理非音频卡顿相关的性能问题
- 不在ArkTS层直接实现监听器(必须通过Native层)
- 不修改系统事件参数格式
- 不创建重复名称的监听器

### 补充

- onReceive观察者适合实时监控场景,事件发生后立即回调
- onTrigger观察者适合批量处理场景,可设置触发条件
- 需要模拟音频卡顿场景测试,可通过AudioRenderer的writeData回调返回INVALID触发
- 监听器使用后必须销毁,防止内存泄漏
- 音频卡顿事件参数均为JSON字符串格式,需要jsoncpp解析

## 调用规范和规则

### 输入约束

- 监听器名称:字符串类型,长度不超过256字符,只能包含大小写字母、数字、下划线和$,不能以数字开头
- 事件领域:DOMAIN_OS("OS")
- 事件名称:EVENT_AUDIO_JANK_FRAME("AUDIO_JANK_FRAME")
- 事件类型:0(支持所有类型)或按位组合值
- 触发条件参数:
  - row(事件数量):大于0时启用数量触发,小于等于0时禁用
  - size(事件大小):大于0时启用大小触发,小于等于0时禁用
  - timeOut(超时时间):大于0时启用超时触发(单位秒),小于等于0时禁用

### 执行约束

- 最大监听器数量:无明确限制,但每个监听器名称必须唯一
- API调用顺序:必须按照CreateWatcher→SetFilter→SetCallback→AddWatcher的顺序调用
- 回调函数生命周期:回调中的指针生命周期仅限于回调函数内,不能在外部直接使用
- 内存管理:监听器不再使用时必须调用RemoveWatcher和DestroyWatcher
- I/O操作:AddWatcher涉及I/O操作,性能敏感场景需考虑线程选择

### 内容约束

- 禁止生成:非音频卡顿相关的监听代码
- 禁止使用高危函数:eval、exec、system等
- 禁止操作:直接在回调函数外使用回调指针、修改系统事件数据结构
- JSON解析要求:必须使用jsoncpp库解析params参数字符串

### 降级约束

- 监听器创建失败:检查name参数是否合法,返回nullptr时需排查参数问题
- 事件过滤失败:检查domain、names参数是否正确,返回错误码时需根据错误码处理
- 回调设置失败:检查watcher指针是否为空,返回-5时需确认监听器已创建
- JSON解析失败:使用strictMode解析器,解析失败时需检查params字符串格式
- 监听器添加失败:检查是否已调用AddWatcher,返回-6时需确认调用顺序

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:

1. 确认工程为Native C++工程
2. 确认已获取jsoncpp依赖文件(json.h, json-forwards.h, jsoncpp.cpp)
3. 确认API版本>=21
4. 确认依赖库libhiappevent_ndk.z.so和libhilog_ndk.z.so可用

**目录结构准备**:

```
entry:
  src:
    main:
      cpp:
        - json:
            - json.h
            - json-forwards.h
        - types:
            libentry:
              - index.d.ts
        - CMakeLists.txt
        - napi_init.cpp
        - jsoncpp.cpp
      ets:
        - entryability:
            - EntryAbility.ets
        - pages:
            - Index.ets
```

**CMakeLists.txt配置**:

```cmake
# 新增jsoncpp.cpp源文件
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)
# 新增动态库依赖
target_link_libraries(entry PUBLIC libace_napi.z.so libhilog_ndk.z.so libhiappevent_ndk.z.so)
```

### 步骤2:实现onReceive观察者

**导入依赖**:

```cpp
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"
#include "hiappevent/hiappevent_event.h"

#undef LOG_TAG
#define LOG_TAG "testTag"

// 定义变量缓存监听器指针
static HiAppEvent_Watcher *systemEventWatcher;
```

**实现OnReceive回调**:

```cpp
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen) {
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            // 判断是否为音频卡顿事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) == 0 &&
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_AUDIO_JANK_FRAME) == 0) {
                Json::Value params;
                Json::Reader reader(Json::Features::strictMode());
                Json::FastWriter writer;
                
                // 解析JSON参数字符串
                if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                    auto time = params["time"].asInt64();
                    auto bundleVersion = params["bundle_version"].asString();
                    auto bundleName = params["bundle_name"].asString();
                    auto faultType = params["fault_type"].asString();
                    auto happenTime = params["happen_time"].asInt64();
                    auto maxFrameTime = params["max_frame_time"].asInt64();
                    
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}ld", time);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", bundleVersion.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.fault_type=%{public}s", faultType.c_str());
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.happen_time=%{public}ld", happenTime);
                    OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_frame_time=%{public}ld", maxFrameTime);
                }
            }
        }
    }
}
```

**注册监听器**:

```cpp
static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 创建监听器
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onReceiverWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置事件过滤器(订阅AUDIO_JANK_FRAME事件)
    const char *names[] = {EVENT_AUDIO_JANK_FRAME};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    // 设置OnReceive回调
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcher, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    // 启动监听器
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}
```

### 步骤3:实现onTrigger观察者

**实现OnTake回调**:

```cpp
static void OnTake(const char *const *events, uint32_t eventLen) {
    Json::Reader reader(Json::Features::strictMode());
    Json::FastWriter writer;
    
    for (int i = 0; i < eventLen; ++i) {
        Json::Value eventInfo;
        if (reader.parse(events[i], eventInfo)) {
            auto domain = eventInfo["domain_"].asString();
            auto name = eventInfo["name_"].asString();
            auto type = eventInfo["type_"].asInt();
            
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", domain.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", name.c_str());
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", type);
            
            // 判断是否为音频卡顿事件
            if (domain == DOMAIN_OS && name == EVENT_AUDIO_JANK_FRAME) {
                auto time = eventInfo["time"].asInt64();
                auto bundleVersion = eventInfo["bundle_version"].asString();
                auto bundleName = eventInfo["bundle_name"].asString();
                auto faultType = eventInfo["fault_type"].asString();
                auto happenTime = eventInfo["happen_time"].asInt64();
                auto maxFrameTime = eventInfo["max_frame_time"].asInt64();
                
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}ld", time);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_version=%{public}s", bundleVersion.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", bundleName.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.fault_type=%{public}s", faultType.c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.happen_time=%{public}ld", happenTime);
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_frame_time=%{public}ld", maxFrameTime);
            }
        }
    }
}
```

**实现OnTrigger回调**:

```cpp
static void OnTrigger(int row, int size) {
    // 获取已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcher, row, OnTake);
}

static napi_value RegisterWatcher(napi_env env, napi_callback_info info) {
    // 创建监听器
    systemEventWatcher = OH_HiAppEvent_CreateWatcher("onTriggerWatcher");
    if (systemEventWatcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置事件过滤器
    const char *names[] = {EVENT_AUDIO_JANK_FRAME};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcher, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    // 设置OnTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcher, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    // 设置触发条件:新增1个事件时触发回调
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcher, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    // 启动监听器
    result = OH_HiAppEvent_AddWatcher(systemEventWatcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error code: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "Watcher registered successfully");
    return {};
}
```

### 步骤4:注册ArkTS接口

**napi_init.cpp注册接口**:

```cpp
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        { "registerWatcher", nullptr, RegisterWatcher, nullptr, nullptr, nullptr, napi_default, nullptr }
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**index.d.ts定义接口**:

```typescript
export const registerWatcher: () => void;
```

**EntryAbility.ets调用接口**:

```typescript
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 启动时注册监听器
        testNapi.registerWatcher();
    }
}
```

### 步骤5:触发音频卡顿测试

**Index.ets模拟卡顿**:

```typescript
import audio from '@ohos.multimedia.audio';
import testNapi from 'libentry.so';

let g_invalidCount = 0;

function normalCallback(buffer: ArrayBuffer): audio.AudioDataCallbackResult {
    if (g_invalidCount > 0) {
        g_invalidCount--;
        return audio.AudioDataCallbackResult.INVALID; // 模拟卡顿
    }
    // 正常写数据逻辑
    return audio.AudioDataCallbackResult.VALID;
}

@Entry
@Component
struct Index {
    private renderModel: audio.AudioRenderer | undefined = undefined;
    
    build() {
        Row() {
            Button("卡顿").onClick(async () => {
                g_invalidCount = 30; // 设置卡顿次数
            })
        }
    }
    
    async createAudioRenderer() {
        let audioRendererOptions: audio.AudioRendererOptions = {
            // 配置音频渲染器参数
        };
        
        audio.createAudioRenderer(audioRendererOptions, (err, renderer) => {
            if (!err && renderer) {
                this.renderModel = renderer;
                this.renderModel.on('writeData', normalCallback);
            }
        });
    }
}
```

### 步骤6:错误处理和清理

**清理监听器**:

```cpp
static napi_value UnregisterWatcher(napi_env env, napi_callback_info info) {
    if (systemEventWatcher != nullptr) {
        // 移除监听器(停止监听)
        int result = OH_HiAppEvent_RemoveWatcher(systemEventWatcher);
        if (result != 0) {
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to remove watcher, error code: %{public}d", result);
        }
        
        // 销毁监听器(释放内存)
        OH_HiAppEvent_DestroyWatcher(systemEventWatcher);
        systemEventWatcher = nullptr;
        OH_LOG_INFO(LogType::LOG_APP, "Watcher unregistered successfully");
    }
    return {};
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 接口调用成功 | 正常执行 |
| -1 | names参数异常 | 检查事件名称数组是否正确,EVENT_AUDIO_JANK_FRAME是否定义 |
| -4 | domain参数异常 | 检查DOMAIN_OS是否正确导入和定义 |
| -5 | watcher入参空指针 | 检查监听器是否成功创建,CreateWatcher是否返回nullptr |
| -6 | 还未调用AddWatcher | 检查调用顺序,必须先AddWatcher才能RemoveWatcher或TakeWatcherData |
| -7 | 事件处理者为空(Processor) | 不适用于Watcher场景 |
| -8 | 事件处理者不存在(Processor) | 不适用于Watcher场景 |
| -9 | 参数值无效 | 检查传入参数格式和取值范围 |
| -10 | 事件配置为空 | 不适用于Watcher场景 |
| -100 | 操作失败 | 检查整体调用流程和参数配置 |
| -200 | 无效的用户标识 | 检查应用权限和UID配置 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt**:

```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

### 环境要求

- HarmonyOS SDK版本:API 21及以上
- 开发环境:DevEco Studio
- Native开发支持:C++17标准
- jsoncpp库:从GitHub获取Amalgamated版本

### 常见编译问题

**问题1:找不到hiappevent.h头文件**

```
fatal error: hiappevent/hiappevent.h: No such file or directory
```

**解决方法**:在CMakeLists.txt中添加头文件搜索路径:

```cmake
include_directories(${OHOS_SDK_PATH}/native/sysroot/usr/include/hiappevent)
```

**问题2:jsoncpp链接失败**

```
undefined reference to `Json::Reader::parse`
```

**解决方法**:确保jsoncpp.cpp已添加到add_library源文件列表,并且链接顺序正确。

**问题3:libhiappevent_ndk.z.so未找到**

```
cannot find -lhiappevent_ndk.z
```

**解决方法**:确认HarmonyOS SDK已正确安装,库文件路径配置正确。

## 常见问题与解决方法

### Q1:监听器创建返回nullptr

**原因**:name参数不符合规范或内存不足

**解决方法**:

- 检查监听器名称是否符合规范(字母开头,不含数字开头,长度<256)
- 检查是否已创建同名监听器(名称必须唯一)
- 检查系统内存是否充足

### Q2:事件过滤失败返回-1或-4

**原因**:names或domain参数错误

**解决方法**:

- 确认已正确导入hiappevent_event.h头文件
- 确认EVENT_AUDIO_JANK_FRAME宏定义可用
- 确认DOMAIN_OS宏定义可用
- 检查names数组长度与namesLen参数一致

### Q3:回调函数未触发

**原因**:音频卡顿事件未实际发生或监听器未添加

**解决方法**:

- 确认已调用OH_HiAppEvent_AddWatcher启动监听器
- 确认AudioRenderer的writeData回调已正确设置
- 确认模拟卡顿场景(g_invalidCount > 0)已触发
- 确认AudioRenderer正在播放状态

### Q4:JSON解析失败

**原因**:params字符串格式错误或解析器配置不当

**解决方法**:

- 使用Json::Features::strictMode()严格模式解析
- 检查params字符串是否为有效JSON格式
- 确认jsoncpp库版本兼容
- 添加解析失败的日志输出排查问题

### Q5:内存泄漏

**原因**:监听器未正确销毁

**解决方法**:

- 在应用退出或监听结束时调用RemoveWatcher和DestroyWatcher
- 确保DestroyWatcher后将指针置空
- 避免重复创建监听器而不销毁

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "watcher_name": "onReceiverWatcher/onTriggerWatcher",
  "event_domain": "OS",
  "event_name": "AUDIO_JANK_FRAME",
  "event_params": {
    "time": 1762739184665,
    "bundle_version": "1.0.0",
    "bundle_name": "com.samples.audio",
    "fault_type": "application",
    "happen_time": 176273918,
    "max_frame_time": 220
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

- [API开发指南:订阅音频卡顿事件(C/C++)](references/hiappevent-watcher-audio-jank-event-c.md)
- [API参考说明:HiAppEvent C API](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [API参考说明:hiappevent_event.h](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-event-h)

## 完整示例代码

- [onReceive观察者完整示例](assets/audio_jank_watcher_onreceive.cpp)
- [onTrigger观察者完整示例](assets/audio_jank_watcher_ontrigger.cpp)
- [CMakeLists.txt配置示例](assets/cmakelists-example.txt)
- [index.d.ts接口定义示例](assets/index-d-ts-example.ts)
- [EntryAbility调用示例](assets/entryability-example.ets)

## 测试用例

### 正向测试用例

- [正常订阅音频卡顿事件](tests/test_positive.cpp):验证监听器创建、过滤设置、回调设置、监听器添加流程正确执行
- [实时接收音频卡顿事件](tests/test_onreceive.cpp):验证onReceive回调正确触发,事件参数正确解析
- [条件触发接收事件](tests/test_ontrigger.cpp):验证onTrigger回调在满足条件时正确触发,事件数据正确获取

### 边界测试用例

- [监听器名称边界值测试](tests/test_boundary_watcher_name.cpp):测试名称长度256字符、特殊字符等边界情况
- [触发条件边界值测试](tests/test_boundary_trigger_condition.cpp):测试row=0,size=0,timeOut=0等边界值
- [事件数量边界测试](tests/test_boundary_event_count.cpp):测试大量事件触发时的性能和稳定性

### 异常测试用例

- [监听器创建失败测试](tests/test_exception_create_watcher.cpp):测试非法name参数、空指针等情况
- [事件过滤失败测试](tests/test_exception_set_filter.cpp):测试非法domain、names参数等情况
- [回调设置失败测试](tests/test_exception_set_callback.cpp):测试空watcher指针、非法回调函数等情况
- [JSON解析失败测试](tests/test_exception_json_parse.cpp):测试params字符串格式错误、解析器异常等情况