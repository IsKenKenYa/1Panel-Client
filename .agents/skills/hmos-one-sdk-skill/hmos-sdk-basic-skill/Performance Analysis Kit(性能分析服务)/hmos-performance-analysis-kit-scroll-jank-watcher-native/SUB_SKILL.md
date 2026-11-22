---
name: hmos-performance-analysis-kit-scroll-jank-watcher
description: 订阅滑动丢帧系统事件，支持onReceive和onTrigger两种观察者模式，需导入jsoncpp库解析事件数据，适用于列表滑动性能监控、UI流畅度分析场景
---

# 订阅滑动丢帧事件技能

## 功能描述

本技能实现使用HiAppEvent C/C++ API订阅系统滑动丢帧事件(SCROLL_JANK)。支持两种观察者模式：
- **onReceive模式**：实时接收事件，观察者接收到事件后立即触发回调
- **onTrigger模式**：条件触发回调，当满足预设条件(事件数量/大小/超时)后触发

滑动丢帧事件包含以下关键参数：
- 丢帧统计：总帧数、丢帧数、连续丢帧数
- 帧时间：最大帧时间、渲染帧时间
- 时间信息：事件时间、开始时间、持续时长
- 应用信息：包名、版本、进程名、Ability名
- 日志路径：外部日志文件路径

## 使用场景

### 触发词
- "订阅滑动丢帧事件"
- "监控滑动卡顿"
- "监听SCROLL_JANK"
- "列表滑动性能分析"
- "UI流畅度监控"

### 能做
- 创建HiAppEvent观察者订阅滑动丢帧系统事件
- 实现onReceive类型观察者实时接收事件
- 实现onTrigger类型观察者条件触发回调
- 解析事件JSON参数获取丢帧详细数据
- 注册Native C++接口供ArkTS调用
- 在应用启动时自动注册观察者

### 绝不做
- 不订阅其他系统事件(如MAIN_THREAD_JANK)
- 不使用ArkTS API订阅事件(本技能仅支持C/C++)
- 不修改系统事件触发阈值
- 不处理非滑动丢帧的事件数据

### 补充
- 需要从三方开源库jsoncpp代码仓下载源码并导入工程
- 滑动丢帧事件触发条件：每次滑动操作发生超过50ms卡顿场景，间隔5~35秒
- 观察者名称必须唯一，相同名称后一次订阅会覆盖前一次

## 调用规范和规则

### 输入约束
- 观察者名称：字符串长度不超过48字符，首字符必须为字母或$，中间字符为数字/字母/下划线，结尾字符为数字或字母
- 事件名称：EVENT_SCROLL_JANK(固定值)
- 事件领域：DOMAIN_OS(固定值，系统事件领域)
- JSON解析库：必须使用jsoncpp库的strict模式解析
- 触发条件参数：
  - row(事件数量)：整数，>0表示启用数量触发
  - size(事件大小)：整数，>0表示启用大小触发  
  - timeOut(超时时间)：整数秒，>0表示启用超时触发

### 执行约束
- 最大耗时：初始化观察者不超过100ms
- 最大迭代次数：事件回调处理不超过10次/秒
- API调用频次：AddWatcher接口涉及I/O操作，建议在子线程调用
- 内存管理：必须调用OH_HiAppEvent_DestroyWatcher释放观察者，防止内存泄漏

### 内容约束
- 禁止生成：非滑动丢帧相关的订阅代码
- 禁止使用高危函数：不使用eval、exec等动态执行函数
- 禁止操作：不修改系统事件配置文件
- JSON解析：必须使用Json::Reader的strictMode防止解析错误

### 降级约束
- jsoncpp库缺失：提示用户下载jsoncpp源码并导入工程
- 观察者创建失败：返回nullptr，检查name参数是否合法
- 订阅失败：返回-5错误码，检查watcher指针是否为空
- JSON解析失败：跳过该事件，继续处理下一个事件

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查jsoncpp库是否已导入工程目录`entry/src/main/cpp/json/`
2. 验证CMakeLists.txt是否添加了jsoncpp.cpp源文件
3. 确认已链接libhiappevent_ndk.z.so动态库
4. 检查工程是否为Native C++类型

**参数准备**：
```cpp
// C++示例
#include "napi/native_api.h"
#include "json/json.h"
#include "hilog/log.h"
#include "hiappevent/hiappevent.h"

#undef LOG_TAG
#define LOG_TAG "ScrollJankWatcher"

// 定义观察者指针缓存变量
static HiAppEvent_Watcher *systemEventWatcherR = nullptr;
static HiAppEvent_Watcher *systemEventWatcherT = nullptr;
```

### 步骤2：创建观察者

**示例代码 - onReceive类型**：
```cpp
// onReceive类型观察者回调函数
static void OnReceive(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.WatcherType=OnReceive");
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.domain=%{public}s", appEventGroups[i].appEventInfos[j].domain);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.name=%{public}s", appEventGroups[i].appEventInfos[j].name);
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.eventType=%{public}d", appEventGroups[i].appEventInfos[j].type);
            
            // 过滤滑动丢帧事件
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_SCROLL_JANK) != 0) {
                continue;
            }
            
            // 使用jsoncpp解析事件参数
            Json::Value params;
            Json::Reader reader(Json::Features::strictMode());
            Json::FastWriter writer;
            
            if (reader.parse(appEventGroups[i].appEventInfos[j].params, params)) {
                // 解析并打印丢帧关键参数
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", params["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.bundle_name=%{public}s", params["bundle_name"].asString().c_str());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_frames=%{public}d", params["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_missed_frames=%{public}d", params["total_app_missed_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_frametime=%{public}d", params["max_app_frametime"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.max_app_seq_frames=%{public}d", params["max_app_seq_frames"].asInt());
            }
        }
    }
}

// 注册onReceive观察者
static napi_value RegisterWatcherReceive(napi_env env, napi_callback_info info)
{
    // 创建观察者，自定义名称
    systemEventWatcherR = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherR");
    if (systemEventWatcherR == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置订阅的事件名称为EVENT_SCROLL_JANK
    const char *names[] = {EVENT_SCROLL_JANK};
    
    // 设置事件过滤器，订阅系统事件
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherR, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        return {};
    }
    
    // 设置onReceive回调函数
    result = OH_HiAppEvent_SetWatcherOnReceive(systemEventWatcherR, OnReceive);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onReceive, error=%{public}d", result);
        return {};
    }
    
    // 开始监听订阅的事件
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherR);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "ScrollJankWatcherR registered successfully");
    return {};
}
```

**示例代码 - onTrigger类型**：
```cpp
// onTrigger类型观察者的OnTake回调
static void OnTake(const char* const *events, uint32_t eventLen)
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
            
            if (domain == DOMAIN_OS && name == EVENT_SCROLL_JANK) {
                // 解析丢帧参数
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.time=%{public}lld", eventInfo["time"].asInt64());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_frames=%{public}d", eventInfo["total_app_frames"].asInt());
                OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent eventInfo.params.total_app_missed_frames=%{public}d", eventInfo["total_app_missed_frames"].asInt());
            }
        }
    }
}

// onTrigger回调函数
static void OnTrigger(int row, int size)
{
    // 接收回调后，获取指定数量的已接收事件
    OH_HiAppEvent_TakeWatcherData(systemEventWatcherT, row, OnTake);
}

// 注册onTrigger观察者
static napi_value RegisterWatcherTrigger(napi_env env, napi_callback_info info)
{
    // 创建观察者
    systemEventWatcherT = OH_HiAppEvent_CreateWatcher("ScrollJankWatcherT");
    if (systemEventWatcherT == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher");
        return {};
    }
    
    // 设置订阅的事件
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(systemEventWatcherT, DOMAIN_OS, 0, names, 1);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter, error=%{public}d", result);
        return {};
    }
    
    // 设置onTrigger回调
    result = OH_HiAppEvent_SetWatcherOnTrigger(systemEventWatcherT, OnTrigger);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set onTrigger, error=%{public}d", result);
        return {};
    }
    
    // 设置触发条件：新增事件数量为1个时触发回调
    result = OH_HiAppEvent_SetTriggerCondition(systemEventWatcherT, 1, 0, 0);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to set trigger condition, error=%{public}d", result);
        return {};
    }
    
    // 开始监听
    result = OH_HiAppEvent_AddWatcher(systemEventWatcherT);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher, error=%{public}d", result);
        return {};
    }
    
    OH_LOG_INFO(LogType::LOG_APP, "ScrollJankWatcherT registered successfully");
    return {};
}
```

### 步骤3：注册ArkTS接口

**示例代码**：
```cpp
// napi_init.cpp中注册接口
static napi_value Init(napi_env env, napi_value exports)
{
    napi_property_descriptor desc[] = {
        { "registerWatcherReceive", nullptr, RegisterWatcherReceive, nullptr, nullptr, nullptr, napi_default, nullptr },
        { "registerWatcherTrigger", nullptr, RegisterWatcherTrigger, nullptr, nullptr, nullptr, napi_default, nullptr },
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
```

**ArkTS接口定义**：
```typescript
// index.d.ts
export const registerWatcherReceive: () => void;
export const registerWatcherTrigger: () => void;
```

### 步骤4：在应用启动时调用

**示例代码**：
```typescript
// EntryAbility.ets
import testNapi from 'libentry.so';

export default class EntryAbility extends UIAbility {
    onCreate(want: Want, launchParam: AbilityConstant.LaunchParam): void {
        // 启动时注册系统事件观察者
        testNapi.registerWatcherReceive();
        testNapi.registerWatcherTrigger();
    }
}
```

### 步骤5：触发滑动丢帧事件

**示例代码**：
```typescript
// Index.ets
@Entry
struct Index {
  private arr: number[] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12, 13, 14, 15]
  
  build() {
    List({ space: 10 }) {
      ForEach(this.arr, (item: number) => {
        ListItem() {
          Text(`${item}`)
            .width('100%')
            .height(100)
            .fontSize(20)
            .fontColor(Color.White)
            .textAlign(TextAlign.Center)
            .borderRadius(10)
            .backgroundColor(0x007DFF)
        }
      })
    }
    .onScrollIndex((firstIndex: number) => {
      let i = 1;
      while (i < 20000) { // 在列表滑动事件中添加耗时操作触发丢帧
        console.info("do something");
        i++;
      }
    })
  }
}
```

### 步骤6：错误处理

```cpp
// 错误处理代码
static napi_value SafeRegisterWatcher(napi_env env, napi_callback_info info)
{
    HiAppEvent_Watcher* watcher = OH_HiAppEvent_CreateWatcher("TestWatcher");
    
    if (watcher == nullptr) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to create watcher: name parameter invalid");
        return {};
    }
    
    const char *names[] = {EVENT_SCROLL_JANK};
    int result = OH_HiAppEvent_SetAppEventFilter(watcher, DOMAIN_OS, 0, names, 1);
    
    switch (result) {
        case 0:
            OH_LOG_INFO(LogType::LOG_APP, "Filter set successfully");
            break;
        case -1:
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: names parameter abnormal");
            OH_HiAppEvent_DestroyWatcher(watcher);
            return {};
        case -4:
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: domain parameter abnormal");
            OH_HiAppEvent_DestroyWatcher(watcher);
            return {};
        case -5:
            OH_LOG_ERROR(LogType::LOG_APP, "Failed to set filter: watcher is null pointer");
            OH_HiAppEvent_DestroyWatcher(watcher);
            return {};
        default:
            OH_LOG_ERROR(LogType::LOG_APP, "Unknown error: %{public}d", result);
            OH_HiAppEvent_DestroyWatcher(watcher);
            return {};
    }
    
    result = OH_HiAppEvent_AddWatcher(watcher);
    if (result != 0) {
        OH_LOG_ERROR(LogType::LOG_APP, "Failed to add watcher: %{public}d", result);
        OH_HiAppEvent_DestroyWatcher(watcher);
        return {};
    }
    
    return {};
}
```

### 步骤7：降级处理

```cpp
// 降级处理：jsoncpp库缺失时的替代方案
static void OnReceiveFallback(const char *domain, const struct HiAppEvent_AppEventGroup *appEventGroups, uint32_t groupLen)
{
    for (int i = 0; i < groupLen; ++i) {
        for (int j = 0; j < appEventGroups[i].infoLen; ++j) {
            if (strcmp(appEventGroups[i].appEventInfos[j].domain, DOMAIN_OS) != 0 || 
                strcmp(appEventGroups[i].appEventInfos[j].name, EVENT_SCROLL_JANK) != 0) {
                continue;
            }
            
            // 降级方案：直接打印原始JSON字符串，不解析
            OH_LOG_INFO(LogType::LOG_APP, "HiAppEvent SCROLL_JANK params (raw): %{public}s", 
                       appEventGroups[i].appEventInfos[j].params);
            
            // 提示用户导入jsoncpp库以获取详细数据
            OH_LOG_WARN(LogType::LOG_APP, "Please import jsoncpp library to parse event params");
        }
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| -1 | names参数异常 | 检查事件名称数组是否正确 |
| -4 | domain参数异常 | 检查事件领域是否为DOMAIN_OS |
| -5 | watcher入参空指针 | 检查观察者指针是否为nullptr |
| -6 | 操作顺序有误 | 先调用OH_HiAppEvent_AddWatcher再调用TakeWatcherData |
| -99 | 打点功能被关闭 | 调用OH_HiAppEvent_Configure开启打点功能 |
| 1 | 非法的事件参数名称 | 检查参数名称格式 |
| 4 | 非法的事件参数字符串长度 | 参数字符串长度需在8*1024字符以内 |
| 5 | 非法的事件参数数量 | 参数个数需在32个以内 |
| 6 | 非法的事件参数数组长度 | 数组元素个数需在100以内 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 新增jsoncpp.cpp源文件(解析订阅事件中的json字符串)
add_library(entry SHARED napi_init.cpp jsoncpp.cpp)

# 新增动态库依赖
target_link_libraries(entry PUBLIC 
    libace_napi.z.so 
    libhilog_ndk.z.so 
    libhiappevent_ndk.z.so
)
```

**jsoncpp库导入**：
1. 从https://github.com/open-source-parsers/jsoncpp下载源码压缩包
2. 按照README中Amalgamated source步骤生成三个文件：
   - jsoncpp.cpp
   - json/json.h
   - json/json-forwards.h
3. 将文件导入到工程目录`entry/src/main/cpp/`

### 环境要求
- DevEco Studio：3.1或以上版本
- HarmonyOS SDK：API 12或以上版本
- Native C++工程类型
- NAPI接口支持

### 常见编译问题

**问题1：找不到json.h头文件**
```
error: 'json/json.h' file not found
```
**解决方法**：从jsoncpp代码仓下载源码并导入到`entry/src/main/cpp/json/`目录

**问题2：未链接libhiappevent_ndk.z.so**
```
error: undefined reference to 'OH_HiAppEvent_CreateWatcher'
```
**解决方法**：在CMakeLists.txt中添加`target_link_libraries(entry PUBLIC libhiappevent_ndk.z.so)`

**问题3：观察者名称重复**
```
Warning: watcher with same name already exists, will be replaced
```
**解决方法**：使用不同的观察者名称，或先调用OH_HiAppEvent_RemoveWatcher移除旧观察者

**问题4：JSON解析失败**
```
Failed to parse event params: JSON syntax error
```
**解决方法**：使用Json::Reader的strictMode进行严格解析，检查params字符串格式

## 常见问题与解决方法

### Q1：如何获取完整的丢帧数据？
**原因**：需要正确解析JSON格式的params字段
**解决方法**：
- 导入jsoncpp库并使用Json::Reader的strictMode
- 解析params字段获取所有丢帧参数：
  - time, bundle_version, bundle_name, process_name, ability_name
  - begin_time, duration
  - total_app_frames, total_app_missed_frames, max_app_frametime, max_app_seq_frames
  - total_render_frames, total_render_missed_frames, max_render_frametime, max_render_seq_frames
  - external_log, log_over_limit

### Q2：为什么观察者没有接收到事件？
**原因**：滑动丢帧事件触发条件未满足
**解决方法**：
- 确认列表滑动时存在超过50ms的卡顿操作
- 检查是否已正确调用OH_HiAppEvent_AddWatcher
- 验证事件过滤器设置为DOMAIN_OS和EVENT_SCROLL_JANK
- 确认事件触发间隔为5~35秒

### Q3：如何区分onReceive和onTrigger模式？
**原因**：两种观察者模式的触发机制不同
**解决方法**：
- **onReceive模式**：实时接收，适合需要立即处理事件的场景
  - 设置OH_HiAppEvent_SetWatcherOnReceive回调
  - 事件到达时立即触发，无延迟
  
- **onTrigger模式**：条件触发，适合批量处理事件的场景
  - 设置OH_HiAppEvent_SetWatcherOnTrigger回调
  - 设置OH_HiAppEvent_SetTriggerCondition触发条件
  - 在OnTrigger中调用OH_HiAppEvent_TakeWatcherData获取事件

### Q4：如何避免内存泄漏？
**原因**：观察者未正确销毁
**解决方法**：
- 在应用退出或不再需要观察者时调用OH_HiAppEvent_RemoveWatcher停止监听
- 调用OH_HiAppEvent_DestroyWatcher销毁观察者对象
- 将观察者指针置为nullptr防止野指针

### Q5：external_log字段包含什么内容？
**原因**：滑动丢帧事件会生成详细的日志文件
**解决方法**：
- external_log是一个字符串数组，包含日志文件路径
- 文件路径格式：`/data/storage/el2/log/watchdog/SCROLL_JANK_YYYYMMDDHHMMSS_PID.txt`
- log_over_limit字段标识是否超过日志大小限制
- 可以读取日志文件获取更详细的丢帧信息

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "watcherRegistered": ["ScrollJankWatcherR", "ScrollJankWatcherT"],
  "eventReceived": {
    "domain": "OS",
    "name": "SCROLL_JANK",
    "eventType": 1,
    "params": {
      "time": "事件发生时间戳",
      "bundle_name": "应用包名",
      "total_app_frames": "应用总帧数",
      "total_app_missed_frames": "应用丢帧数",
      "max_app_frametime": "最大应用帧时间",
      "max_app_seq_frames": "最大连续丢帧数"
    }
  },
  "apiUsed": [
    "OH_HiAppEvent_CreateWatcher",
    "OH_HiAppEvent_SetAppEventFilter",
    "OH_HiAppEvent_SetWatcherOnReceive",
    "OH_HiAppEvent_SetWatcherOnTrigger",
    "OH_HiAppEvent_SetTriggerCondition",
    "OH_HiAppEvent_AddWatcher",
    "OH_HiAppEvent_TakeWatcherData",
    "OH_HiAppEvent_RemoveWatcher",
    "OH_HiAppEvent_DestroyWatcher"
  ]
}
```

## 参考文档

- [API开发指南](references/hiappevent-watcher-scroll-jank-c.md)
- [HiAppEvent C API文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-h)
- [HiAppEvent结构体文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-hiappevent-hiappevent-watcher)
- [jsoncpp开源库](https://github.com/open-source-parsers/jsoncpp)

## 完整示例代码

- [C++示例代码](assets/example_scroll_jank_watcher.cpp)
- [CMakeLists配置](assets/CMakeLists.txt)
- [ArkTS接口定义](assets/index.d.ts)
- [测试页面代码](assets/Index.ets)

## 测试用例

### 正向测试用例
- [正常订阅滑动丢帧事件](tests/test_positive.cpp)：验证观察者成功注册并接收事件
- [正确解析事件参数](tests/test_parse_params.cpp)：验证JSON解析和参数提取正确

### 边界测试用例
- [最小触发条件](tests/test_boundary_min.cpp)：设置row=1触发条件，验证单事件触发
- [最大参数长度](tests/test_boundary_max.cpp)：验证处理最大长度的事件参数字符串

### 异常测试用例
- [观察者名称非法](tests/test_exception_name.cpp)：测试非法观察者名称的创建失败处理
- [JSON解析失败](tests/test_exception_parse.cpp)：测试JSON格式错误的降级处理
- [内存泄漏检测](tests/test_exception_memory.cpp)：验证未销毁观察者的内存泄漏检测