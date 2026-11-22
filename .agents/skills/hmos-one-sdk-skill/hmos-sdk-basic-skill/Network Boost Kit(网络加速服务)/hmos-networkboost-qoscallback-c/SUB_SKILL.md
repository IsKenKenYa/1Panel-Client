---
name: hmos-networkboost-qoscallback-c
description: 注册和监听网络质量QoS评估回调信息，获取链路类型、带宽、速率、RTT时延等网络质量数据，支持C/C++语言，适用于实时音视频、直播、游戏等需要网络自适应场景
---

# 网络质量评估回调技能 (C/C++)

## 功能描述

本技能提供Network Boost Kit的网络质量评估回调功能，允许应用订阅网络质量QoS评估信息，系统会按照一定周期或QoS变化时主动回调给应用。回调的QoS信息包括：

- 数据传输链路类型（蜂窝主卡、蜂窝副卡、主Wi-Fi、辅Wi-Fi）
- 上下行空口实时带宽（单位bps）
- 上下行空口实时速率（单位bps）
- RTT时延（单位ms）
- 上行发送空口缓冲时延（单位ms）
- 上行发送空口缓冲时延占总缓冲时间的比例（范围[0, 100]）

应用可根据这些信息实现网络自适应策略，调整缓存、码率、帧率、分辨率等参数，提升弱网环境下的用户体验。

**起始版本：** API 5.1.0(18)

## 使用场景

### 触发词
- "网络质量评估"
- "网络QoS回调"
- "监听网络质量"
- "获取网络带宽速率"
- "网络质量评估 C/C++"
- "NetworkBoost QoS"

### 能做
- 注册网络质量变化回调，监听网络质量评估信息
- 获取多条路径的网络质量数据（支持最多4条路径）
- 解析回调数据，提取链路类型、带宽、速率、时延等信息
- 实现网络自适应策略（调整缓存、码率、帧率等）
- 取消注册回调，停止监听网络质量信息

### 绝不做
- 不用于网络连接迁移场景（应使用连接迁移技能）
- 不用于多网并发场景（应使用多网并发技能）
- 不用于应用传输体验反馈（应使用ReportQoe接口）
- 不用于网络场景识别（应使用网络场景变化回调）
- 不支持ArkTS语言（仅支持C/C++）

### 补充
- 需要申请ohos.permission.GET_NETWORK_INFO权限
- 需要在CMakeLists.txt中链接libnetwork_boost.so库
- 回调数据单位为bps，转换为B/s需除以8
- 最多支持监听4条路径的网络质量信息
- 注册回调数量有上限限制，超过上限返回62100003错误码

## 调用规范和规则

### 输入约束
- 回调函数指针必须有效，不能为NULL
- callbackId指针必须有效，用于接收系统分配的ID
- 取消注册时，callbackId必须为注册时获取的有效ID
- 回调函数类型必须为HMS_NetworkBoost_NetQosChange

### 执行约束
- 注册回调后，系统会周期性或QoS变化时触发回调
- 回调频率由系统控制，应用无法自定义
- 最大并发回调数量有限制（系统级限制）
- 取消注册后，回调立即停止触发

### 内容约束
- 禁止在回调函数中执行耗时操作（建议不超过100ms）
- 禁止在回调函数中调用阻塞函数
- 禁止在回调函数中申请大量内存
- 禁止在回调函数中进行网络请求
- 回调数据指针仅在回调期间有效，禁止保存指针

### 降级约束
- 注册失败：检查权限配置，使用错误码定位问题
- 回调数据异常：验证pathNum范围[1, 4]，过滤无效数据
- 取消注册失败：确保callbackId有效，检查系统服务状态
- 权限不足：提示用户配置GET_NETWORK_INFO权限
- 系统服务失败：等待系统恢复或提示用户重启应用

## 调用流程和步骤

### 步骤1：准备阶段（权限配置和依赖链接）

**前置校验**：
1. 确认已在module.json5中配置ohos.permission.GET_NETWORK_INFO权限
2. 确认已在CMakeLists.txt中链接libnetwork_boost.so库
3. 确认已导入必要的头文件

**权限配置示例**：
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

**CMakeLists.txt配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**参数准备**：
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstdint>

uint32_t callbackId = 0;
```

### 步骤2：注册网络质量回调

**示例代码**：
```cpp
void onNetworkQoSChanged(NetworkBoost_NetworkQosArray *msg)
{
    if (msg == nullptr) {
        printf("回调数据为空\n");
        return;
    }
    
    if (msg->pathNum < 1 || msg->pathNum > 4) {
        printf("路径数量异常: %d\n", msg->pathNum);
        return;
    }
    
    for (uint32_t i = 0; i < msg->pathNum; i++) {
        NetworkBoost_NetworkQos &qos = msg->networkQos[i];
        
        printf("路径%d网络质量信息:\n", i);
        printf("  链路类型: %d\n", qos.pathType);
        printf("  上行带宽: %llu bps\n", qos.linkUpBandwidth);
        printf("  下行带宽: %llu bps\n", qos.linkDownBandwidth);
        printf("  上行速率: %llu bps (%llu B/s)\n", 
               qos.linkUpRate, qos.linkUpRate / 8);
        printf("  下行速率: %llu bps (%llu B/s)\n", 
               qos.linkDownRate, qos.linkDownRate / 8);
        printf("  实时速率: %llu B/s\n", 
               (qos.linkUpRate + qos.linkDownRate) / 8);
        printf("  RTT时延: %u ms\n", qos.rttMs);
        printf("  上行缓冲时延: %u ms\n", qos.linkUpBufferDelayMs);
        printf("  缓冲占比: %u%%\n", qos.linkUpBufferCongestionPercent);
    }
}

int32_t RegisterNetQualityCallback()
{
    HMS_NetworkBoost_NetQosChange callback = onNetworkQoSChanged;
    
    int32_t ret = HMS_NetworkBoost_RegisterNetQosCallback(callback, &callbackId);
    
    if (ret == 0) {
        printf("注册成功，回调ID: %u\n", callbackId);
    } else {
        printf("注册失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

### 步骤3：错误处理

```cpp
void HandleRegisterError(int32_t errorCode)
{
    switch (errorCode) {
        case 0:
            printf("注册成功\n");
            break;
        case 201:
            printf("权限不足，请检查GET_NETWORK_INFO权限配置\n");
            break;
        case 401:
            printf("参数错误，请检查回调函数和callbackId指针\n");
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
        case 62100003:
            printf("注册请求达到上限，请先取消其他回调注册\n");
            break;
        default:
            printf("未知错误: %d\n", errorCode);
            break;
    }
}
```

### 步骤4：取消注册回调

```cpp
int32_t UnregisterNetQualityCallback()
{
    if (callbackId == 0) {
        printf("回调ID无效，未注册回调\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterNetQosCallback(callbackId);
    
    if (ret == 0) {
        printf("取消注册成功\n");
        callbackId = 0;
    } else {
        printf("取消注册失败，错误码: %d\n", ret);
    }
    
    return ret;
}
```

### 步骤5：完整业务流程示例

```cpp
class NetworkQualityMonitor {
private:
    uint32_t callbackId = 0;
    bool isRegistered = false;
    
public:
    void onQoSChanged(NetworkBoost_NetworkQosArray *msg)
    {
        if (!msg || msg->pathNum < 1 || msg->pathNum > 4) {
            return;
        }
        
        for (uint32_t i = 0; i < msg->pathNum; i++) {
            NetworkBoost_NetworkQos &qos = msg->networkQos[i];
            
            uint64_t totalRate = (qos.linkUpRate + qos.linkDownRate) / 8;
            
            if (totalRate < 100000) {
                printf("弱网环境，建议降低码率\n");
            } else if (qos.rttMs > 200) {
                printf("高延迟，建议增加缓冲\n");
            } else {
                printf("网络质量良好\n");
            }
        }
    }
    
    int32_t startMonitoring()
    {
        if (isRegistered) {
            printf("已注册回调\n");
            return 0;
        }
        
        HMS_NetworkBoost_NetQosChange callback = 
            [](NetworkBoost_NetworkQosArray *msg) {
                NetworkQualityMonitor *monitor = 
                    reinterpret_cast<NetworkQualityMonitor*>(
                        msg->networkQos[0].linkUpBandwidth);
                monitor->onQoSChanged(msg);
            };
        
        int32_t ret = HMS_NetworkBoost_RegisterNetQosCallback(callback, &callbackId);
        
        if (ret == 0) {
            isRegistered = true;
            printf("开始监听网络质量\n");
        } else {
            HandleRegisterError(ret);
        }
        
        return ret;
    }
    
    int32_t stopMonitoring()
    {
        if (!isRegistered || callbackId == 0) {
            printf("未注册回调\n");
            return 0;
        }
        
        int32_t ret = HMS_NetworkBoost_UnregisterNetQosCallback(callbackId);
        
        if (ret == 0) {
            isRegistered = false;
            callbackId = 0;
            printf("停止监听网络质量\n");
        } else {
            HandleRegisterError(ret);
        }
        
        return ret;
    }
};
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 正常执行，无需处理 |
| 201 | 权限不足 | 在module.json5中配置ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查回调函数指针和callbackId指针是否有效 |
| 801 | 系统能力不支持 | 检查设备是否支持Network Boost Kit，确认系统版本>=5.1.0(18) |
| 62100001 | 内部错误 | 系统内部异常，建议稍后重试或重启应用 |
| 62100002 | 系统服务操作失败 | 系统服务异常，检查网络管理服务状态，重启应用或设备 |
| 62100003 | 注册请求达到上限 | 已达到最大回调注册数量，先取消其他回调注册 |

## 编译和修复问题

### 依赖声明
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(network_quality_demo)

set(CMAKE_CXX_STANDARD 17)

target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    libnetwork_boost.so
    libc++.so
)
```

### 环境要求
- HarmonyOS SDK: >= 5.1.0(18)
- CMake: >= 3.4.1
- C++标准: >= C++17
- 目标架构: aarch64-linux-ohos

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_quality.h: No such file or directory
```
**解决方法**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
```

**问题2：链接库失败**
```
undefined reference to `HMS_NetworkBoost_RegisterNetQosCallback'
```
**解决方法**：
```cmake
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

**问题3：权限配置缺失**
```
运行时错误：权限不足 (错误码 201)
```
**解决方法**：
在module.json5中添加：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

**问题4：回调函数类型错误**
```
编译错误：无法将函数指针转换为HMS_NetworkBoost_NetQosChange类型
```
**解决方法**：
确保回调函数签名正确：
```cpp
void callback(NetworkBoost_NetworkQosArray *msg);
```

## 常见问题与解决方法

### Q1：注册回调后一直没有收到回调
**原因**：
- 网络质量未发生变化
- 系统周期性回调间隔较长
- 回调函数指针无效

**解决方法**：
- 检查网络环境是否稳定
- 等待一段时间观察回调触发
- 验证回调函数指针是否正确传递

### Q2：回调数据中pathNum为0或超过4
**原因**：
- 系统数据异常
- 回调数据指针无效

**解决方法**：
- 在回调函数中添加数据验证：
```cpp
if (msg->pathNum < 1 || msg->pathNum > 4) {
    printf("路径数量异常，忽略本次回调\n");
    return;
}
```

### Q3：取消注册时提示回调ID无效
**原因**：
- 使用了错误的callbackId
- 回调已被其他线程取消注册
- callbackId变量未保存注册时的值

**解决方法**：
- 确保使用注册时返回的callbackId
- 避免多线程并发取消注册
- 使用全局变量保存callbackId

### Q4：回调数据单位转换错误
**原因**：
- linkUpRate/linkDownRate单位为bps，误以为B/s
- 未除以8进行单位转换

**解决方法**：
```cpp
uint64_t rateInBytes = qos.linkUpRate / 8;
```

### Q5：注册回调时提示已达上限
**原因**：
- 已注册的回调数量超过系统限制
- 未及时取消注册旧的回调

**解决方法**：
- 先取消注册其他回调：
```cpp
HMS_NetworkBoost_UnregisterNetQosCallback(oldCallbackId);
```
- 然后再注册新的回调

### Q6：回调函数执行耗时导致卡顿
**原因**：
- 在回调函数中执行了耗时操作
- 回调函数处理逻辑过于复杂

**解决方法**：
- 仅在回调中保存数据指针，异步处理：
```cpp
void onQoSChanged(NetworkBoost_NetworkQosArray *msg) {
    std::lock_guard<std::mutex> lock(dataMutex);
    latestQosData = *msg;
}
```
- 在主线程或其他线程中处理数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "register_qos_callback",
  "callbackId": 12345,
  "apiUsed": [
    "HMS_NetworkBoost_RegisterNetQosCallback",
    "HMS_NetworkBoost_UnregisterNetQosCallback"
  ],
  "networkQuality": {
    "pathNum": 2,
    "paths": [
      {
        "pathType": 0,
        "linkUpBandwidth": 1000000,
        "linkDownBandwidth": 10000000,
        "linkUpRate": 500000,
        "linkDownRate": 5000000,
        "rttMs": 50,
        "linkUpBufferDelayMs": 10,
        "linkUpBufferCongestionPercent": 20
      },
      {
        "pathType": 2,
        "linkUpBandwidth": 5000000,
        "linkDownBandwidth": 20000000,
        "linkUpRate": 2000000,
        "linkDownRate": 10000000,
        "rttMs": 30,
        "linkUpBufferDelayMs": 5,
        "linkUpBufferCongestionPercent": 10
      }
    ]
  }
}
```

## 参考文档

- [网络质量评估开发指南](references/networkboost-qoscallback-c-guide.md)
- [NetworkBoost模块API参考](references/network-boost-c-overview-ref.md)
- [NetworkBoost_NetworkQos结构体参考](references/network-boost-c-struct-network_qos-ref.md)
- [NetworkBoost_NetworkQosArray结构体参考](references/network-boost-c-struct-network_qos_array-ref.md)

## 完整示例代码

- [C++完整示例](assets/network_qos_monitor.cpp)
- [CMakeLists.txt配置示例](assets/CMakeLists.txt)
- [权限配置示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [正常注册和取消注册回调](tests/test_positive.cpp)：验证注册和取消注册流程正常工作
- [接收多路径网络质量数据](tests/test_multi_path.cpp)：验证回调数据包含多条路径信息
- [单位转换测试](tests/test_unit_conversion.cpp)：验证bps到B/s的单位转换正确

### 边界测试用例
- [路径数量边界测试](tests/test_boundary.cpp)：验证pathNum为1和4时的处理
- [带宽速率边界测试](tests/test_rate_boundary.cpp)：验证带宽和速率为0和最大值时的处理
- [时延边界测试](tests/test_rtt_boundary.cpp)：验证RTT时延为0和最大值时的处理

### 异常测试用例
- [权限不足测试](tests/test_permission_denied.cpp)：验证未配置权限时的错误处理
- [参数错误测试](tests/test_invalid_params.cpp)：验证回调函数指针为NULL时的错误处理
- [注册上限测试](tests/test_register_limit.cpp)：验证注册数量达到上限时的错误处理
- [取消注册无效ID测试](tests/test_unregister_invalid_id.cpp)：验证取消注册无效callbackId时的错误处理