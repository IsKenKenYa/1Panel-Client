---
name: hmos-networkboost-kit-scenecallback
description: 注册和监听网络场景状态变化，接收网络场景实时信息回调，包括链路类型、网络场景类型、数传策略建议、弱信号预测等，适用于实时语音视频、游戏、直播等需要网络自适应的场景
---

# 网络场景识别技能 (C/C++)

## 功能描述

本技能提供Network Boost Kit的网络场景识别能力，通过注册回调函数监听网络场景状态变化。系统在网络场景实时信息或预测信息发生变化后回调给应用，回调的网络场景信息包括：
- 数据传输的链路类型（蜂窝主卡/副卡、Wi-Fi主/辅）
- 网络场景类型（正常、拥塞、信号快切、弱信号）
- 数传策略建议（缓存、暂停、降速、提速、保持）
- 弱信号预测信息（进入时间、停留时长）

应用可以根据回调信息实现网络自适应，调整缓存、码率、帧率、分辨率等策略。

## 使用场景

### 触发词
- "网络场景识别"
- "监听网络场景"
- "注册网络场景回调"
- "网络自适应"
- "弱信号预测"
- "Network Boost场景回调"

### 能做
- 注册网络场景变化回调函数
- 监听网络场景状态实时变化
- 获取网络场景类型（正常、拥塞、信号快切、弱信号）
- 获取数据传输链路类型（蜂窝主卡/副卡、Wi-Fi主/辅）
- 获取数传策略建议（缓存、暂停、降速、提速、保持）
- 获取弱信号预测信息（进入时间、停留时长）
- 取消注册网络场景回调函数

### 绝不做
- 不主动发起网络质量探测
- 不修改网络配置或切换网络
- 不处理连接迁移相关功能（需使用连接迁移技能）
- 不处理多网并发相关功能（需使用多网并发技能）
- 不处理网络质量评估相关功能（需使用网络质量技能）

### 补充
- 仅支持C/C++语言开发
- 需要申请ohos.permission.GET_NETWORK_INFO权限
- API起始版本：5.1.0(18)
- 回调函数在线程中执行，需要注意线程安全
- 最大注册回调数量有限制（错误码62100003）

## 调用规范和规则

### 输入约束
- 回调函数指针必须有效且不为空
- callbackId指针必须有效且不为空
- 回调函数实现必须符合HMS_NetworkBoost_NetSceneChange类型定义
- 回调函数参数NetworkBoost_NetworkScene指针由系统管理，应用不应释放

### 执行约束
- 注册回调耗时：通常小于10ms
- 回调触发频率：系统在网络场景变化时触发，频率取决于网络环境变化
- 最大注册回调数量：受系统限制（达到上限返回错误码62100003）
- 回调执行在独立线程，需注意线程安全

### 内容约束
- 禁止在回调函数中执行耗时操作（建议小于100ms）
- 禁止在回调函数中阻塞或等待
- 禁止在回调函数中释放参数指针
- 禁止在回调函数中调用其他Network Boost注册/取消注册API（可能死锁）
- 禁止使用空指针作为回调函数参数

### 降级约束
- 注册失败：检查权限配置，提示用户授予网络信息权限
- 回调触发异常：记录日志，使用默认网络策略
- 参数为空：立即返回错误，不执行注册操作
- 回调函数执行异常：捕获异常，不影响其他回调触发

## 调用流程和步骤

### 步骤1：开发准备和权限配置

**前置校验**：
1. 确认HarmonyOS SDK版本 >= 5.1.0(18)
2. 确认已申请ohos.permission.GET_NETWORK_INFO权限
3. 确认CMakeLists.txt已配置libnetwork_boost.so链接

**权限配置**（module.json5）：
```typescript
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      },
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

**CMakeLists.txt配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 步骤2：导入头文件和定义回调函数

**导入头文件**：
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstring>
```

**定义回调函数**：
```cpp
uint32_t callbackId = 0;

void onNetworkSceneChanged(NetworkBoost_NetworkScene* ns) {
    if (ns == nullptr) {
        printf("错误：回调参数为空指针\n");
        return;
    }
    
    printf("数据路径类型: %d\n", ns->pathType);
    printf("网络场景: %d\n", ns->scene);
    
    switch (ns->scene) {
        case NB_SCENE_NORMAL:
            printf("正常场景 - 保持当前策略\n");
            break;
        case NB_SCENE_CONGESTION:
            printf("拥塞场景 - 建议降低码率和帧率\n");
            break;
        case NB_SCENE_FREQUENT_HANDOVER:
            printf("信号快切场景 - 建议增加缓存和容错\n");
            break;
        case NB_SCENE_WEAK_SIGNAL:
            printf("弱信号场景 - 建议暂停或大幅降低数据量\n");
            break;
        default:
            printf("未知场景类型\n");
            break;
    }
    
    printf("应用数传策略建议: %d\n", ns->recommendedAction);
    
    switch (ns->recommendedAction) {
        case NB_ACTION_DO_CACHING:
            printf("建议做缓存\n");
            break;
        case NB_ACTION_SUSPEND_DATA:
            printf("建议暂停发包\n");
            break;
        case NB_ACTION_DECREASE_DATA:
            printf("建议降低发包速率\n");
            break;
        case NB_ACTION_INCREASE_DATA:
            printf("建议增加发包速率\n");
            break;
        case NB_ACTION_KEEP_DATA:
            printf("建议保持当前发包速率\n");
            break;
        default:
            printf("未知策略建议\n");
            break;
    }
    
    if (ns->weakSignalPrediction.isLastPredictionValid) {
        printf("弱信号预测有效\n");
        printf("预计%d秒后进入弱信号区域\n", ns->weakSignalPrediction.startTime);
        printf("预计在弱信号区域停留%d秒\n", ns->weakSignalPrediction.duration);
        
        if (ns->weakSignalPrediction.duration > 0) {
            printf("应用应提前调整策略，准备进入弱信号环境\n");
        }
    } else {
        printf("弱信号预测失效或无预测\n");
    }
}
```

### 步骤3：注册网络场景回调

**注册回调函数**：
```cpp
int32_t RegisterNetSceneCallback() {
    if (callbackId != 0) {
        printf("警告：已存在注册的回调，Id：%d，建议先取消注册\n", callbackId);
        return -1;
    }
    
    HMS_NetworkBoost_NetSceneChange callback;
    callback = onNetworkSceneChanged;
    
    int32_t ret = HMS_NetworkBoost_RegisterNetSceneCallback(callback, &callbackId);
    
    if (ret == 0) {
        printf("注册网络场景回调成功，回调Id：%d\n", callbackId);
    } else {
        printf("注册网络场景回调失败，错误码：%d\n", ret);
        callbackId = 0;
        
        switch (ret) {
            case 201:
                printf("权限不足，请检查是否已申请ohos.permission.GET_NETWORK_INFO权限\n");
                break;
            case 401:
                printf("参数错误，请检查回调函数指针和callbackId指针是否有效\n");
                break;
            case 801:
                printf("系统能力不支持，请确认设备支持Network Boost能力\n");
                break;
            case 62100001:
                printf("内部错误，请稍后重试\n");
                break;
            case 62100002:
                printf("系统服务操作失败，网络管理服务可能异常\n");
                break;
            case 62100003:
                printf("注册请求达到上限，已注册回调数量过多\n");
                break;
            default:
                printf("未知错误\n");
                break;
        }
    }
    
    return ret;
}
```

### 步骤4：使用回调信息调整网络策略

**示例：根据场景调整视频播放策略**：
```cpp
void adjustVideoStrategyBasedOnScene(NetworkBoost_Scene scene, 
                                      NetworkBoost_RecommendedAction action) {
    switch (scene) {
        case NB_SCENE_NORMAL:
            setVideoBitrate(2000);
            setVideoFrameRate(30);
            setBufferDuration(2);
            break;
        case NB_SCENE_CONGESTION:
            setVideoBitrate(800);
            setVideoFrameRate(15);
            setBufferDuration(5);
            break;
        case NB_SCENE_FREQUENT_HANDOVER:
            setVideoBitrate(1200);
            setVideoFrameRate(20);
            setBufferDuration(8);
            enableErrorResilience(true);
            break;
        case NB_SCENE_WEAK_SIGNAL:
            if (action == NB_ACTION_SUSPEND_DATA) {
                pauseVideo();
                showNetworkWarning();
            } else {
                setVideoBitrate(400);
                setVideoFrameRate(10);
                setBufferDuration(10);
            }
            break;
    }
}

void onNetworkSceneChanged(NetworkBoost_NetworkScene* ns) {
    if (ns == nullptr) return;
    adjustVideoStrategyBasedOnScene(ns->scene, ns->recommendedAction);
}
```

### 步骤5：取消注册回调

**取消注册回调函数**：
```cpp
int32_t UnregisterNetSceneCallback() {
    if (callbackId == 0) {
        printf("警告：没有已注册的回调，无需取消注册\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterNetSceneCallback(callbackId);
    
    if (ret == 0) {
        printf("取消注册网络场景回调成功\n");
        callbackId = 0;
    } else {
        printf("取消注册网络场景回调失败，错误码：%d\n", ret);
        
        switch (ret) {
            case 201:
                printf("权限不足\n");
                break;
            case 401:
                printf("参数错误，callbackId无效\n");
                break;
            case 801:
                printf("系统能力不支持\n");
                break;
            case 62100001:
                printf("内部错误\n");
                break;
            case 62100002:
                printf("系统服务操作失败\n");
                break;
            default:
                printf("未知错误\n");
                break;
        }
    }
    
    return ret;
}
```

### 步骤6：完整生命周期管理

**示例：应用生命周期中的回调管理**：
```cpp
class NetworkSceneManager {
private:
    uint32_t callbackId = 0;
    bool isRegistered = false;
    
public:
    int32_t initialize() {
        if (isRegistered) {
            printf("已初始化，无需重复注册\n");
            return 0;
        }
        
        HMS_NetworkBoost_NetSceneChange callback = onNetworkSceneChanged;
        int32_t ret = HMS_NetworkBoost_RegisterNetSceneCallback(callback, &callbackId);
        
        if (ret == 0) {
            isRegistered = true;
            printf("初始化成功，回调Id：%d\n", callbackId);
        } else {
            printf("初始化失败，错误码：%d\n", ret);
        }
        
        return ret;
    }
    
    int32_t cleanup() {
        if (!isRegistered || callbackId == 0) {
            printf("未注册或已清理，无需操作\n");
            return 0;
        }
        
        int32_t ret = HMS_NetworkBoost_UnregisterNetSceneCallback(callbackId);
        
        if (ret == 0) {
            isRegistered = false;
            callbackId = 0;
            printf("清理成功\n");
        } else {
            printf("清理失败，错误码：%d\n", ret);
        }
        
        return ret;
    }
    
    bool isMonitoring() const {
        return isRegistered && callbackId != 0;
    }
};

NetworkSceneManager manager;

int32_t main() {
    int32_t ret = manager.initialize();
    if (ret != 0) {
        printf("初始化失败，应用可能无法正常监听网络场景\n");
        return ret;
    }
    
    printf("应用运行中，监听网络场景变化...\n");
    
    manager.cleanup();
    return 0;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 正常返回，无需处理 |
| 201 | 权限不足 | 检查module.json5是否配置ohos.permission.GET_NETWORK_INFO权限，重新编译安装应用 |
| 401 | 参数错误 | 检查回调函数指针和callbackId指针是否有效且不为空 |
| 801 | 系统能力不支持 | 确认设备支持SystemCapability.Communication.NetworkBoost.Core能力，可能在部分设备上不支持 |
| 62100001 | 内部错误 | 系统内部处理异常，记录日志，稍后重试，如持续失败联系技术支持 |
| 62100002 | 系统服务操作失败 | 网络管理服务异常，检查系统网络服务状态，重启设备后重试 |
| 62100003 | 注册请求达到上限 | 已注册回调数量达到系统限制，先取消其他注册回调后再尝试注册 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(NetworkSceneDemo)

set(HMOS_SDK_NATIVE $ENV{HMOS_SDK_NATIVE})

target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
)
```

### 环境要求
- HarmonyOS SDK版本：>= 5.1.0(18)
- 编译工具：DevEco Studio或CMake >= 3.4.1
- 目标设备：支持SystemCapability.Communication.NetworkBoost.Core系统能力
- 权限：ohos.permission.GET_NETWORK_INFO

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_quality.h: No such file or directory
```
**解决方法**：
- 确认HMOS_SDK_NATIVE环境变量已正确设置
- 确认target_include_directories配置正确
- 检查HarmonyOS Native SDK是否完整安装

**问题2：链接libnetwork_boost.so失败**
```
undefined reference to `HMS_NetworkBoost_RegisterNetSceneCallback'
```
**解决方法**：
- 确认target_link_directories路径正确
- 确认target_link_libraries包含libnetwork_boost.so
- 检查libnetwork_boost.so文件是否存在（${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos/）

**问题3：权限未授予导致运行失败**
```
注册失败，错误码：201
```
**解决方法**：
- 检查module.json5中是否配置ohos.permission.GET_NETWORK_INFO权限
- 重新编译安装应用
- 在设备上确认应用已授予网络信息权限

## 常见问题与解决方法

### Q1：注册回调后长时间没有收到回调触发
**原因**：网络场景稳定，未发生变化，系统不会触发回调
**解决方法**：
- 这是正常情况，系统仅在网络场景变化时触发回调
- 可以通过切换网络（如开关Wi-Fi、移动位置）测试回调触发
- 可以使用网络质量回调（HMS_NetworkBoost_RegisterNetQosCallback）获取更频繁的网络质量信息

### Q2：回调函数中访问参数指针导致崩溃
**原因**：回调参数指针由系统管理，应用不应释放或长时间持有
**解决方法**：
- 在回调函数中立即处理数据，不要保存指针
- 如需保存数据，复制内容而非指针
- 不要在回调中调用free或delete释放参数指针

### Q3：注册回调返回错误码62100003
**原因**：已注册回调数量达到系统上限
**解决方法**：
- 检查是否多次注册未取消
- 先调用HMS_NetworkBoost_UnregisterNetSceneCallback取消其他注册回调
- 确保在应用退出或不再需要时取消注册

### Q4：回调函数执行耗时影响性能
**原因**：回调在线程中执行，耗时操作会影响后续回调触发
**解决方法**：
- 回调函数执行时间建议小于100ms
- 将耗时策略调整操作异步处理（如发送消息到主线程）
- 避免在回调中执行IO操作、网络请求、大量计算

### Q5：弱信号预测信息如何使用
**原因**：不理解弱信号预测的含义和使用场景
**解决方法**：
- weakSignalPrediction.isLastPredictionValid判断预测是否有效
- startTime表示预计多少秒后进入弱信号，应用可提前调整策略
- duration表示预计在弱信号区域停留多久，应用可评估是否需要暂停服务
- 例如：startTime=5秒，duration=30秒，应用应在5秒内提前降低码率或增加缓存

### Q6：网络场景类型和数传策略建议的关系
**原因**：不理解场景和策略的对应关系
**解决方法**：
- 网络场景类型描述当前网络状态（如弱信号）
- 数传策略建议是系统给出的具体行动建议
- 不同场景可能有不同的策略建议，应用应根据recommendedAction调整
- 例如：弱信号场景可能建议NB_ACTION_SUSPEND_DATA（暂停）或NB_ACTION_DECREASE_DATA（降速）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "callbackId": "系统分配的回调ID",
  "isRegistered": true,
  "apiUsed": [
    "HMS_NetworkBoost_RegisterNetSceneCallback",
    "HMS_NetworkBoost_UnregisterNetSceneCallback"
  ],
  "permissionsRequired": [
    "ohos.permission.GET_NETWORK_INFO"
  ],
  "supportedScenes": [
    "NB_SCENE_NORMAL",
    "NB_SCENE_CONGESTION",
    "NB_SCENE_FREQUENT_HANDOVER",
    "NB_SCENE_WEAK_SIGNAL"
  ],
  "supportedActions": [
    "NB_ACTION_DO_CACHING",
    "NB_ACTION_SUSPEND_DATA",
    "NB_ACTION_DECREASE_DATA",
    "NB_ACTION_INCREASE_DATA",
    "NB_ACTION_KEEP_DATA"
  ]
}
```

## 参考文档

**本地参考文档（skill内部）**：
- [API开发指南](references/networkboost-scenecallback-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [NetworkBoost_NetworkScene结构体](references/network-boost-c-struct-network_scene.md)
- [NetworkBoost_WeakSignalPrediction结构体](references/network-boost-c-struct-weak_signal_prediction.md)
- [开发准备](references/networkboost-preparations.md)

**华为开发者网站参考文档**：
- [API开发指南 - 网络场景识别 (C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-scenecallback-c)
- [API参考说明 - NetworkBoost](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [NetworkBoost_NetworkScene结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-network_scene)
- [NetworkBoost_WeakSignalPrediction结构体](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-weak_signal_prediction)
- [开发准备 - Network Boost Kit](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)

## 完整示例代码

- [C++示例代码](assets/network_scene_callback_demo.cpp)
- [CMakeLists.txt示例](assets/CMakeLists.txt)
- [module.json5权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常注册和取消注册回调](tests/test_register_unregister.cpp)：测试注册和取消注册回调的基本流程
- [回调触发和数据解析](tests/test_callback_trigger.cpp)：测试回调触发后正确解析网络场景信息
- [弱信号预测信息解析](tests/test_weak_signal_prediction.cpp)：测试正确解析弱信号预测信息

### 边界测试用例
- [多次注册测试](tests/test_multiple_register.cpp)：测试重复注册和达到注册上限的场景
- [参数边界测试](tests/test_parameter_boundary.cpp)：测试回调函数指针为空、callbackId为空等边界情况

### 异常测试用例
- [权限不足测试](tests/test_permission_denied.cpp)：测试未申请权限时的错误处理
- [系统服务异常测试](tests/test_service_error.cpp)：测试系统服务异常时的错误处理
- [回调函数异常测试](tests/test_callback_exception.cpp)：测试回调函数执行异常时的处理