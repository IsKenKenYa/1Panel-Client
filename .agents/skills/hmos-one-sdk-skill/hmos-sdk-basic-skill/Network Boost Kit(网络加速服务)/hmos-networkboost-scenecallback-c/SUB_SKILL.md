---
name: hmos-networkboost-scenecallback-c
description: 注册监听网络场景变化回调(C/C++),支持识别拥塞/弱信号/快切等场景,获取链路类型和数传策略建议,适用于视频通话/游戏等实时业务场景,起始版本5.1.0(18)
---

# 网络场景识别(C/C++)技能

## 功能描述

本技能提供Network Boost Kit的网络场景识别能力,通过注册回调监听网络场景实时变化信息。系统在网络场景发生变化时主动回调通知应用,包括数据传输链路类型、网络场景类型、数传策略建议、弱信号预测信息等。应用可根据场景类型自适应调整缓存、码率、帧率、分辨率等策略,实现网络自适应优化。

**核心能力**:
- 注册/取消注册网络场景变化回调
- 获取网络场景类型(正常/拥塞/弱信号/小区频繁切换)
- 获取数据链路类型(蜂窝主卡/副卡/Wi-Fi主/辅)
- 获取数传策略建议(缓存/暂停/降速/加速/保持)
- 获取弱信号预测信息(预计进入时间/持续时长)

**适用场景**: 实时视频通话、在线游戏、直播、短视频、音乐播放等需要网络自适应的场景。

**技术限制**: 仅支持C/C++ API,需要GET_NETWORK_INFO权限,起始版本5.1.0(18)。

## 使用场景

### 触发词
- "网络场景识别"
- "监听网络场景变化"
- "网络场景回调"
- "弱信号检测"
- "网络拥塞识别"
- "网络自适应"
- "实时业务网络优化"
- "Network Boost场景识别"

### 能做
- 注册网络场景变化回调监听器
- 获取网络场景实时状态(正常、拥塞、弱信号、小区频繁切换)
- 获取数据传输链路类型信息
- 获取系统推荐的数传策略建议
- 获取弱信号预测信息(进入时间、持续时长)
- 取消注册网络场景回调
- 根据场景类型实现网络自适应策略调整

### 绝不做
- 不提供网络质量评估能力(需使用网络质量回调API)
- 不处理连接迁移事件(需使用连接迁移回调API)
- 不支持多网并发请求(需使用多网并发API)
- 不支持ArkTS项目(仅支持C/C++ API)
- 不处理超出Network Boost Kit范围的请求
- 不替代应用的业务逻辑实现

### 补充
- 回调函数由系统在网络场景变化时主动调用,应用需实现回调处理逻辑
- 同一应用可注册多个回调,系统分配唯一callbackId用于管理
- 网络场景类型包括:正常(0)、拥塞(1)、小区频繁切换(2)、弱信号(3)
- 数传策略建议包括:缓存(0)、暂停发包(1)、降低速率(2)、增加速率(3)、保持当前(4)
- 弱信号预测仅提供参考信息,应用需根据业务场景决定是否采纳
- 注册回调前需确保已配置GET_NETWORK_INFO权限
- 业务结束时必须取消注册回调,避免资源泄露
- CMakeLists.txt需链接libnetwork_boost.so库

## 调用规范和规则

### 输入约束
- 回调函数指针必须有效且不为NULL
- callbackId指针必须有效且不为NULL,用于接收系统分配的ID
- 取消注册时必须使用注册时系统分配的有效callbackId
- 回调函数签名必须符合HMS_NetworkBoost_NetSceneChange类型定义
- 回调函数内不应执行耗时操作,避免阻塞系统回调线程

### 执行约束
- 最大注册回调数量:受系统限制,达到上限返回错误码62100003
- 回调调用频次:由系统决定,场景变化时主动回调
- 回调处理耗时:建议<100ms,避免阻塞
- 注册操作耗时:同步调用,立即返回结果
- 取消注册操作耗时:同步调用,立即返回结果

### 内容约束
- 禁止在回调函数中执行阻塞操作(如sleep、长时间IO)
- 禁止在回调函数中调用系统API修改网络配置
- 禁止在回调函数中访问已释放的资源
- 禁止注册重复的回调函数指针(建议先取消再重新注册)
- 禁止在应用退出后不取消注册回调(导致资源泄露)
- 回调函数参数NetworkBoost_NetworkScene指针由系统管理,应用不应释放

### 降级约束
- 注册失败(权限不足):提示用户检查权限配置,降级为不监听场景
- 注册失败(达到上限):取消无用回调后重试,或降级为不监听
- 回调未触发:应用可结合网络质量回调API补充判断
- 弱信号预测失效(duration=0):忽略预测信息,仅处理当前场景
- 系统服务异常(错误码62100002):提示系统服务异常,稍后重试
- 内部错误(错误码62100001):记录日志,降级为不监听场景

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查module.json5是否已配置GET_NETWORK_INFO权限
2. 检查CMakeLists.txt是否已链接libnetwork_boost.so
3. 检查头文件是否已正确导入
4. 检查SDK版本是否>=5.1.0(18)
5. 检查回调函数签名是否正确

**权限配置(module.json5)**:
```json
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

**CMakeLists.txt配置**:
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**参数准备**:
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstdint>

uint32_t callbackId = 0;
```

### 步骤2:实现回调函数

**回调函数实现**:
```cpp
void onNetworkSceneChanged(NetworkBoost_NetworkScene* ns)
{
    if (ns == nullptr) {
        printf("错误:回调参数为空\n");
        return;
    }

    printf("数据路径类型: %d\n", ns->pathType);
    printf("网络场景: %d\n", ns->scene);

    switch (ns->scene) {
        case NB_SCENE_NORMAL:
            printf("场景类型:正常场景\n");
            break;
        case NB_SCENE_CONGESTION:
            printf("场景类型:拥塞场景\n");
            break;
        case NB_SCENE_FREQUENT_HANDOVER:
            printf("场景类型:小区频繁切换场景\n");
            break;
        case NB_SCENE_WEAK_SIGNAL:
            printf("场景类型:弱信号场景\n");
            break;
        default:
            printf("场景类型:未知\n");
            break;
    }

    printf("应用数传策略建议: %d\n", ns->recommendedAction);

    switch (ns->recommendedAction) {
        case NB_ACTION_DO_CACHING:
            printf("策略建议:执行缓存动作\n");
            break;
        case NB_ACTION_SUSPEND_DATA:
            printf("策略建议:停止发包\n");
            break;
        case NB_ACTION_DECREASE_DATA:
            printf("策略建议:降低发包速率\n");
            break;
        case NB_ACTION_INCREASE_DATA:
            printf("策略建议:增加发包速率\n");
            break;
        case NB_ACTION_KEEP_DATA:
            printf("策略建议:保持当前发包速率\n");
            break;
        default:
            printf("策略建议:未知\n");
            break;
    }

    if (ns->weakSignalPrediction.isLastPredictionValid) {
        printf("弱信号预测有效\n");
        printf("预计进入弱信号时间: %u秒\n", ns->weakSignalPrediction.startTime);
        printf("预计弱信号持续时长: %u秒\n", ns->weakSignalPrediction.duration);

        if (ns->weakSignalPrediction.duration > 0) {
            printf("建议提前调整策略应对弱信号\n");
        }
    } else {
        printf("弱信号预测无效或已失效\n");
    }
}
```

### 步骤3:注册回调

**示例代码**:
```cpp
int32_t RegisterNetSceneCallback()
{
    HMS_NetworkBoost_NetSceneChange callback;
    callback = onNetworkSceneChanged;

    int32_t ret = HMS_NetworkBoost_RegisterNetSceneCallback(callback, &callbackId);

    if (ret == 0) {
        printf("注册网络场景回调成功,回调ID:%u\n", callbackId);
        return 0;
    }

    switch (ret) {
        case 201:
            printf("错误:权限不足,请检查GET_NETWORK_INFO权限配置\n");
            break;
        case 401:
            printf("错误:参数错误,请检查回调函数和callbackId指针\n");
            break;
        case 801:
            printf("错误:系统能力不支持,请检查SDK版本>=5.1.0(18)\n");
            break;
        case 62100001:
            printf("错误:内部错误,请稍后重试\n");
            break;
        case 62100002:
            printf("错误:系统服务操作失败,请检查系统服务状态\n");
            break;
        case 62100003:
            printf("错误:注册请求达到上限,请先取消无用回调\n");
            break;
        default:
            printf("错误:未知错误码%d\n", ret);
            break;
    }

    return ret;
}
```

### 步骤4:取消注册回调

**示例代码**:
```cpp
int32_t UnregisterNetSceneCallback()
{
    if (callbackId == 0) {
        printf("警告:回调ID为0,可能未注册或已取消\n");
        return -1;
    }

    int32_t ret = HMS_NetworkBoost_UnregisterNetSceneCallback(callbackId);

    if (ret == 0) {
        printf("取消注册网络场景回调成功\n");
        callbackId = 0;
        return 0;
    }

    switch (ret) {
        case 201:
            printf("错误:权限不足\n");
            break;
        case 401:
            printf("错误:参数错误,回调ID无效\n");
            break;
        case 801:
            printf("错误:系统能力不支持\n");
            break;
        case 62100001:
            printf("错误:内部错误\n");
            break;
        case 62100002:
            printf("错误:系统服务操作失败\n");
            break;
        default:
            printf("错误:未知错误码%d\n", ret);
            break;
    }

    return ret;
}
```

### 步骤5:完整流程示例

**完整示例代码**:
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstdint>

static uint32_t g_callbackId = 0;

void onNetworkSceneChanged(NetworkBoost_NetworkScene* ns)
{
    if (ns == nullptr) {
        return;
    }

    switch (ns->scene) {
        case NB_SCENE_WEAK_SIGNAL:
            printf("检测到弱信号场景\n");
            if (ns->recommendedAction == NB_ACTION_DO_CACHING) {
                printf("建议执行缓存策略\n");
            }
            break;
        case NB_SCENE_CONGESTION:
            printf("检测到拥塞场景\n");
            if (ns->recommendedAction == NB_ACTION_DECREASE_DATA) {
                printf("建议降低发包速率\n");
            }
            break;
        case NB_SCENE_NORMAL:
            printf("网络场景恢复正常\n");
            if (ns->recommendedAction == NB_ACTION_INCREASE_DATA) {
                printf("建议恢复正常发包速率\n");
            }
            break;
        case NB_SCENE_FREQUENT_HANDOVER:
            printf("检测到小区频繁切换\n");
            break;
    }
}

int main()
{
    int32_t ret = HMS_NetworkBoost_RegisterNetSceneCallback(onNetworkSceneChanged, &g_callbackId);
    if (ret != 0) {
        printf("注册回调失败:%d\n", ret);
        return ret;
    }

    printf("注册成功,等待回调...\n");

    while (true) {
        break;
    }

    ret = HMS_NetworkBoost_UnregisterNetSceneCallback(g_callbackId);
    if (ret != 0) {
        printf("取消注册失败:%d\n", ret);
    }

    return 0;
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 检查module.json5是否配置GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查回调函数指针和callbackId指针是否有效 |
| 801 | 系统能力不支持 | 检查SDK版本是否>=5.1.0(18) |
| 62100001 | 内部错误 | 记录日志,稍后重试或降级处理 |
| 62100002 | 系统服务操作失败 | 检查系统服务状态,重启应用或设备 |
| 62100003 | 注册请求达到上限 | 取消无用回调后重试 |

**错误处理建议**:
- 权限不足(201):必须在module.json5配置GET_NETWORK_INFO权限
- 参数错误(401):确保回调函数和callbackId指针不为NULL
- 系统能力不支持(801):检查设备SDK版本,低于5.1.0不支持
- 注册达到上限(62100003):先取消无用回调释放资源,再重新注册

## 编译和修复问题

### 依赖声明

**CMakeLists.txt**:
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(NetworkBoostDemo)

set(CMAKE_CXX_STANDARD 17)

target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
    libc.so
)
```

**头文件导入**:
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstdint>
```

### 环境要求
- HarmonyOS SDK: >=5.1.0(18)
- 编译工具: DevEco Studio 5.1.0+
- 目标架构: aarch64-linux-ohos
- C++标准: >=C++17

### 常见编译问题

**问题1:头文件找不到**
```
fatal error: NetworkBoostKit/network_boost_quality.h: No such file or directory
```
**解决方法**:检查target_include_directories是否正确设置${HMOS_SDK_NATIVE}/sysroot/usr/include

**问题2:链接库失败**
```
undefined reference to `HMS_NetworkBoost_RegisterNetSceneCallback'
```
**解决方法**:检查target_link_libraries是否包含libnetwork_boost.so,检查target_link_directories路径是否正确

**问题3:权限未配置导致运行时失败**
```
注册回调返回错误码201
```
**解决方法**:在entry/src/main/module.json5中添加GET_NETWORK_INFO权限配置

**问题4:SDK版本不支持**
```
注册回调返回错误码801
```
**解决方法**:检查设备SDK版本,升级到5.1.0(18)或更高版本

**问题5:结构体成员访问错误**
```
error: 'NetworkBoost_NetworkScene' has no member named 'xxx'
```
**解决方法**:检查SDK版本,确保>=5.1.0(18),某些成员可能在更高版本引入

## 常见问题与解决方法

### Q1:注册回调成功但从未触发回调
**原因**:
- 网络场景未发生变化
- 回调函数实现有问题
- 系统服务异常

**解决方法**:
- 检查设备网络状态,切换网络触发场景变化
- 检查回调函数是否正确实现,添加日志验证
- 检查系统服务状态,重启应用或设备
- 结合网络质量回调API补充判断

### Q2:取消注册回调返回错误码401
**原因**:使用无效的callbackId取消注册

**解决方法**:
- 确保使用注册时系统分配的有效callbackId
- 不要重复取消注册同一个callbackId
- 取消注册后将callbackId置为0避免重复使用

### Q3:回调函数内访问空指针导致崩溃
**原因**:未检查回调参数是否为空

**解决方法**:
- 在回调函数开头添加空指针检查
- 使用if (ns == nullptr)保护后续代码
- 空指针情况下直接返回,不处理

### Q4:弱信号预测信息duration为0
**原因**:预测结果无效,系统无法提供有效预测

**解决方法**:
- 检查isLastPredictionValid字段判断有效性
- duration为0时忽略预测信息
- 仅处理当前网络场景,不依赖预测

### Q5:回调函数阻塞导致性能问题
**原因**:回调函数内执行耗时操作

**解决方法**:
- 回调函数仅做简单判断和状态记录
- 将耗时操作移到应用主线程处理
- 避免在回调中执行sleep、IO等阻塞操作
- 回调处理耗时建议<100ms

### Q6:多进程场景下回调管理混乱
**原因**:不同进程注册回调,callbackId管理不当

**解决方法**:
- 每个进程独立管理callbackId
- 使用全局变量或类成员存储callbackId
- 进程退出前必须取消注册所有回调
- 不同进程可注册不同的回调函数

### Q7:应用退出后未取消注册回调
**原因**:应用退出流程未调用取消注册API

**解决方法**:
- 在应用退出流程中调用UnregisterNetSceneCallback
- 确保所有注册的回调都取消注册
- 使用RAII模式自动管理回调生命周期
- 添加异常处理确保取消注册一定执行

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "网络场景识别回调管理",
  "callbackId": "uint32数值",
  "registered": "true/false",
  "apiUsed": [
    "HMS_NetworkBoost_RegisterNetSceneCallback",
    "HMS_NetworkBoost_UnregisterNetSceneCallback"
  ],
  "sceneTypes": [
    "NB_SCENE_NORMAL",
    "NB_SCENE_CONGESTION",
    "NB_SCENE_FREQUENT_HANDOVER",
    "NB_SCENE_WEAK_SIGNAL"
  ],
  "pathTypes": [
    "NB_PATH_CELLULAR_PRIMARY",
    "NB_PATH_CELLULAR_SECONDARY",
    "NB_PATH_WIFI_PRIMARY",
    "NB_PATH_WIFI_SECONDARY"
  ],
  "recommendedActions": [
    "NB_ACTION_DO_CACHING",
    "NB_ACTION_SUSPEND_DATA",
    "NB_ACTION_DECREASE_DATA",
    "NB_ACTION_INCREASE_DATA",
    "NB_ACTION_KEEP_DATA"
  ]
}
```

**成功标准**:
- 注册回调返回0(成功)
- callbackId为有效值(>0)
- 回调函数在网络场景变化时被系统调用
- 取消注册返回0(成功)
- 无内存泄露和资源泄露

## 参考文档

- [API开发指南](references/networkboost-scenecallback-c.md)
- [API参考说明](references/network-boost-c-overview.md)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)
- [NetworkBoost模块概述](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)

## 完整示例代码

- [C++完整示例](assets/example_network_scene.cpp)
- [CMakeLists配置](assets/CMakeLists.txt)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常注册和取消注册](tests/test_positive.cpp):验证注册成功、回调触发、取消注册成功
- [场景识别验证](tests/test_positive.cpp):验证不同网络场景的识别和回调
- [策略建议验证](tests/test_positive.cpp):验证数传策略建议的正确性

### 边界测试用例
- [多次注册取消](tests/test_boundary.cpp):验证注册-取消-注册的循环操作
- [回调ID管理](tests/test_boundary.cpp):验证callbackId的唯一性和有效性
- [预测信息处理](tests/test_boundary.cpp):验证弱信号预测的边界情况(duration=0)

### 异常测试用例
- [权限不足](tests/test_exception.cpp):验证未配置权限时的错误处理
- [参数错误](tests/test_exception.cpp):验证NULL参数的错误处理
- [注册达到上限](tests/test_exception.cpp):验证注册数量达到上限时的处理
- [系统服务异常](tests/test_exception.cpp):验证系统服务异常时的降级处理