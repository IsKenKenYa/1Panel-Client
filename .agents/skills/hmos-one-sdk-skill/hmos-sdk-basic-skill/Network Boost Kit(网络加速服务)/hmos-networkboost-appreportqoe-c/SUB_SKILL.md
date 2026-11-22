---
name: hmos-networkboost-appreportqoe-c
description: 反馈应用传输体验质量信息，支持短视频、长视频、实时游戏等多种业务类型，触发系统网络加速，适用于视频卡顿、游戏延迟等弱网场景，需GET_NETWORK_INFO权限
---

# 应用传输体验反馈技能 (C/C++)

## 功能描述

应用传输体验反馈功能允许应用将当前的传输体验状态和业务类型信息实时反馈给系统网络业务模块。系统会根据反馈信息进行精细化调度，启用网络加速能力，提升用户体验。例如：视频类App播放过程中卡顿，将卡顿信息上报后，Network Boost Kit将信息反馈给系统网络加速模块，该模块会记录播放卡顿信息，并根据当前网络情况，启用网络加速能力。

**核心能力**：
- 实时反馈传输体验状态（良好/卡顿/丢包/高延迟等）
- 指定业务类型（短视频、长视频、实时游戏、直播等）
- 触发系统网络加速调度
- 改善弱网环境用户体验

**适用场景**：
- 视频播放卡顿上报
- 实时游戏延迟反馈
- 直播质量状态报告
- 文件下载上传异常上报

## 使用场景

### 触发词
- "报告体验质量"
- "反馈卡顿"
- "上报延迟"
- "网络体验差"
- "传输质量反馈"
- "ReportQoe"
- "应用传输体验反馈"

### 能做
- 反馈应用当前的传输体验状态（NB_QOE_GOOD/NB_QOE_BAD_*）
- 指定业务类型触发针对性加速策略
- 触发系统网络加速模块进行精细化调度
- 在弱网、拥塞、高延迟场景下改善用户体验
- 支持短视频、长视频、实时游戏、直播、下载等多种业务类型

### 绝不做
- 不用于获取网络质量信息（应使用RegisterNetQosCallback）
- 不用于监听网络场景变化（应使用RegisterNetSceneCallback）
- 不用于网络连接迁移（应使用Handover相关接口）
- 不用于多网并发请求（应使用RequestMultiPath）
- 不处理超出Network Boost Kit范围的请求

### 补充
- 必须申请ohos.permission.GET_NETWORK_INFO权限
- API起始版本：5.1.0(18)
- 系统能力：SystemCapability.Communication.NetworkBoost.Core
- 需链接libnetwork_boost.so库
- 需包含头文件NetworkBoostKit/network_boost_quality.h

## 调用规范和规则

### 输入约束
- serviceType参数：必须使用NetworkBoost_ServiceType枚举值（0-23）
- qoeType参数：必须使用NetworkBoost_QoeType枚举值（0-7）
- 参数有效性校验：serviceType和qoeType必须在枚举范围内
- 业务类型匹配：serviceType应与应用实际业务匹配

### 执行约束
- 最大调用频次：建议每秒不超过10次
- 调用时机：在检测到传输体验变化时立即调用
- 调用场景：应在用户体验发生变化时触发（如卡顿、延迟增大）
- 线程安全：可在任意线程调用

### 内容约束
- 禁止虚假上报：不得上报与实际情况不符的体验状态
- 禁止过度上报：避免频繁上报相同状态
- 禁止使用无效枚举值：不得使用超出枚举范围的值
- 禁止遗漏权限：必须确保已申请GET_NETWORK_INFO权限

### 降级约束
- 权限不足：提示用户申请GET_NETWORK_INFO权限，降级为不上报
- 参数错误：校验参数范围，提示开发者修正枚举值
- 系统服务失败：记录错误日志，跳过本次上报，等待下次体验变化时再上报
- 系统能力不支持：检测API版本，提示用户升级系统

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查是否已申请ohos.permission.GET_NETWORK_INFO权限
2. 检查系统API版本是否>=5.1.0(18)
3. 检查libnetwork_boost.so库是否正确链接
4. 检查头文件路径是否正确配置

**权限配置**：
```json
// module.json5
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

**CMake配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 步骤2：调用API

**头文件导入**：
```cpp
#include "NetworkBoostKit/network_boost_quality.h"
#include <cstdio>
#include <cstring>
```

**API调用示例**：
```cpp
int32_t ReportQoe(NetworkBoost_ServiceType serviceType, NetworkBoost_QoeType qoeType)
{
    // 参数校验
    if (serviceType < NB_SERVICE_DEFAULT || serviceType > NB_SERVICE_SHOPPING) {
        printf("错误：serviceType参数超出范围[%d]\n", serviceType);
        return 401;
    }
    
    if (qoeType < NB_QOE_GOOD || qoeType > NB_QOE_BAD_HIGH_LATENCY) {
        printf("错误：qoeType参数超出范围[%d]\n", qoeType);
        return 401;
    }
    
    // 调用API
    int32_t ret = HMS_NetworkBoost_ReportQoe(serviceType, qoeType);
    
    // 处理返回结果
    switch (ret) {
        case 0:
            printf("传输体验反馈成功：serviceType=%d, qoeType=%d\n", serviceType, qoeType);
            break;
        case 201:
            printf("权限不足：请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误：请检查serviceType和qoeType枚举值\n");
            break;
        case 801:
            printf("系统能力不支持：请升级系统至API 5.1.0(18)及以上\n");
            break;
        case 62100001:
            printf("内部错误：系统服务异常\n");
            break;
        case 62100002:
            printf("系统服务操作失败：请稍后重试\n");
            break;
        default:
            printf("未知错误：ret=%d\n", ret);
            break;
    }
    
    return ret;
}
```

### 步骤3：业务场景示例

**短视频卡顿上报**：
```cpp
void OnVideoPlaybackStutter()
{
    // 短视频卡顿，上报服务器异常
    NetworkBoost_ServiceType serviceType = NB_SERVICE_SHORT_VIDEO;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_SERVER_ERROR;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    if (ret != 0) {
        printf("上报失败，系统将无法启用网络加速\n");
    }
}
```

**实时游戏延迟上报**：
```cpp
void OnGameHighLatency()
{
    // 实时游戏高延迟，上报高时延
    NetworkBoost_ServiceType serviceType = NB_SERVICE_REAL_TIME_GAME;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_HIGH_LATENCY;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
    if (ret == 0) {
        printf("系统已收到延迟反馈，将启用网络加速\n");
    }
}
```

**直播丢包上报**：
```cpp
void OnLiveStreamingPacketLost()
{
    // 直播观看丢包，上报丢包
    NetworkBoost_ServiceType serviceType = NB_SERVICE_LIVE_STREAMING_WATCHER;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_PACKET_LOST;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
}
```

**下载异常上报**：
```cpp
void OnDownloadNoData()
{
    // 下载无数据，上报无数据
    NetworkBoost_ServiceType serviceType = NB_SERVICE_DOWNLOAD;
    NetworkBoost_QoeType qoeType = NB_QOE_BAD_NO_DATA;
    
    int32_t ret = ReportQoe(serviceType, qoeType);
}
```

### 步骤4：错误处理

```cpp
void HandleReportQoeError(int32_t errorCode)
{
    switch (errorCode) {
        case 0:
            printf("上报成功\n");
            break;
        case 201:
            printf("权限不足，请检查module.json5权限配置\n");
            break;
        case 401:
            printf("参数错误，请使用有效的枚举值\n");
            break;
        case 801:
            printf("系统能力不支持，请升级系统\n");
            break;
        case 62100001:
            printf("内部错误，请稍后重试\n");
            break;
        case 62100002:
            printf("系统服务操作失败，请检查网络状态\n");
            break;
        default:
            printf("未知错误码：%d\n", errorCode);
            break;
    }
}
```

### 步骤5：降级处理

```cpp
void ReportQoeWithFallback(NetworkBoost_ServiceType serviceType, NetworkBoost_QoeType qoeType)
{
    int32_t ret = ReportQoe(serviceType, qoeType);
    
    if (ret != 0) {
        // 降级处理：不上报，但记录日志
        printf("传输体验反馈失败，跳过本次上报\n");
        
        // 可选降级方案：
        // 1. 调整应用自身的传输策略（如降低码率）
        // 2. 缓存当前体验状态，等待下次成功上报
        // 3. 提示用户检查网络设置
        
        if (ret == 201) {
            printf("建议：请申请GET_NETWORK_INFO权限\n");
        } else if (ret == 801) {
            printf("建议：系统版本过低，无法使用网络加速功能\n");
        }
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 上报成功，系统已收到反馈 |
| 201 | 权限不足 | 在module.json5中添加ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查serviceType和qoeType是否为有效枚举值 |
| 801 | 系统能力不支持 | 升级系统至API 5.1.0(18)及以上版本 |
| 62100001 | 内部错误 | 系统服务异常，稍后重试 |
| 62100002 | 系统服务操作失败 | 检查网络状态，重启应用后重试 |

## 枚举值说明

### NetworkBoost_ServiceType（业务类型）

| 枚举值 | 数值 | 说明 |
|-------|------|------|
| NB_SERVICE_DEFAULT | 0 | 默认服务类型 |
| NB_SERVICE_BACKGROUND | 1 | 后台类型 |
| NB_SERVICE_REAL_TIME_VOICE | 2 | 实时语音类型 |
| NB_SERVICE_REAL_TIME_VIDEO | 3 | 实时视频类型 |
| NB_SERVICE_CALL_SIGNALING | 4 | 语音信令类型 |
| NB_SERVICE_REAL_TIME_GAME | 5 | 实时游戏类型 |
| NB_SERVICE_NORMAL_GAME | 6 | 普通游戏类型 |
| NB_SERVICE_SHORT_VIDEO | 7 | 短视频类型 |
| NB_SERVICE_LONG_VIDEO | 8 | 长视频类型 |
| NB_SERVICE_LIVE_STREAMING_ANCHOR | 9 | 直播主播类型 |
| NB_SERVICE_LIVE_STREAMING_WATCHER | 10 | 直播观看类型 |
| NB_SERVICE_DOWNLOAD | 11 | 下载类型 |
| NB_SERVICE_UPLOAD | 12 | 上传类型 |
| NB_SERVICE_BROWSER | 13 | 浏览页面类型 |
| NB_SERVICE_TRANSACTION | 14 | 交易支付或扫码类型 |
| NB_SERVICE_DETECTION | 15 | 探测类型 |
| NB_SERVICE_CLOUDSERVICE | 16 | 云业务、云游戏类型 |
| NB_SERVICE_VOICE_CONFERENCE | 17 | 语音会议类型 |
| NB_SERVICE_VIDEO_CONFERENCE | 18 | 视频会议类型 |
| NB_SERVICE_NAVIGATION | 19 | 导航定位类型 |
| NB_SERVICE_SECKILL_SERVICE | 20 | 秒杀业务类型 |
| NB_SERVICE_LOGIN | 21 | 登录（含一键登录）类型 |
| NB_SERVICE_AUDIO | 22 | 音乐、音频类型 |
| NB_SERVICE_SHOPPING | 23 | 购物类型 |

### NetworkBoost_QoeType（体验类型）

| 枚举值 | 数值 | 说明 |
|-------|------|------|
| NB_QOE_GOOD | 0 | 体验良好 |
| NB_QOE_BAD_UNKNOWN | 1 | 体验差：未知原因 |
| NB_QOE_BAD_SERVER_ERROR | 2 | 体验差：服务器异常 |
| NB_QOE_BAD_NO_DATA | 3 | 体验差：无数据 |
| NB_QOE_BAD_PACKET_LOST | 4 | 体验差：丢包 |
| NB_QOE_BAD_PACKET_OUT_OF_ORDER | 5 | 体验差：乱序 |
| NB_QOE_BAD_HIGH_JITTER | 6 | 体验差：高抖动 |
| NB_QOE_BAD_HIGH_LATENCY | 7 | 体验差：高时延 |

## 编译和修复问题

### 依赖声明
```cmake
# CMakeLists.txt
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 环境要求
- HarmonyOS API版本：>=5.1.0(18)
- 编译工具：DevEco Studio或CMake
- 目标架构：aarch64-linux-ohos
- SDK路径：HMOS_SDK_NATIVE环境变量

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: NetworkBoostKit/network_boost_quality.h: No such file or directory
```
**解决方法**：
检查target_include_directories配置，确保${HMOS_SDK_NATIVE}/sysroot/usr/include路径正确

**问题2：链接库失败**
```
undefined reference to `HMS_NetworkBoost_ReportQoe'
```
**解决方法**：
检查target_link_libraries配置，确保libnetwork_boost.so已正确链接

**问题3：权限未配置**
```
运行时返回错误码201
```
**解决方法**：
在module.json5中添加ohos.permission.GET_NETWORK_INFO权限配置

**问题4：API版本不匹配**
```
运行时返回错误码801
```
**解决方法**：
升级系统至API 5.1.0(18)及以上版本，或使用版本检查API判断系统能力

## 常见问题与解决方法

### Q1：上报后系统未启用加速，用户体验未改善
**原因**：系统网络加速需要综合判断网络状态、业务类型、用户体验等多方面因素
**解决方法**：
- 确保上报的serviceType与实际业务匹配
- 确保上报的qoeType准确反映实际体验状态
- 配合使用RegisterNetQosCallback监听网络质量变化
- 配合使用RegisterNetSceneCallback监听网络场景变化
- 在多次上报体验差后，系统会综合判断启用加速

### Q2：频繁上报是否会影响性能
**原因**：过度上报可能增加系统负载
**解决方法**：
- 建议在用户体验发生明显变化时上报
- 避免每秒超过10次的频繁调用
- 状态稳定时不必重复上报相同状态
- 使用降级策略避免无效上报

### Q3：多个业务场景如何选择serviceType
**原因**：业务类型不明确或场景复杂
**解决方法**：
- 根据应用主要功能选择最匹配的类型
- 短视频应用选择NB_SERVICE_SHORT_VIDEO
- 实时游戏选择NB_SERVICE_REAL_TIME_GAME
- 直播观看选择NB_SERVICE_LIVE_STREAMING_WATCHER
- 复合场景可选择NB_SERVICE_DEFAULT

### Q4：如何判断应该上报哪种qoeType
**原因**：体验差的类型判断困难
**解决方法**：
- 播放器卡顿：上报NB_QOE_BAD_SERVER_ERROR或NB_QOE_BAD_NO_DATA
- 网络延迟高：上报NB_QOE_BAD_HIGH_LATENCY
- 数据丢包：上报NB_QOE_BAD_PACKET_LOST
- 数据乱序：上报NB_QOE_BAD_PACKET_OUT_OF_ORDER
- 抖动明显：上报NB_QOE_BAD_HIGH_JITTER
- 原因不明：上报NB_QOE_BAD_UNKNOWN

### Q5：权限申请流程复杂，如何简化
**原因**：GET_NETWORK_INFO为普通权限，配置相对简单
**解决方法**：
- 在module.json5中添加权限声明即可
- 无需用户手动授权（非敏感权限）
- 编译时DevEco Studio会自动处理
- 运行时系统自动授予权限

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "serviceType": "NB_SERVICE_SHORT_VIDEO",
  "qoeType": "NB_QOE_BAD_SERVER_ERROR",
  "errorCode": 0,
  "message": "传输体验反馈成功",
  "apiUsed": [
    "HMS_NetworkBoost_ReportQoe"
  ],
  "timestamp": "2026-07-03T22:54:00Z"
}
```

**成功示例**：
- serviceType：上报的业务类型
- qoeType：上报的体验状态
- errorCode：0表示成功
- message：反馈结果说明

**失败示例**：
```json
{
  "status": "failed",
  "errorCode": 201,
  "message": "权限不足",
  "suggestion": "请在module.json5中添加ohos.permission.GET_NETWORK_INFO权限"
}
```

## 参考文档

- [应用传输体验反馈开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-appreportqoe-c)
- [NetworkBoost C API接口文档](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [NetworkBoost头文件说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-quality)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)

## 完整示例代码

- [C++完整示例](assets/example_reportqoe.cpp)
- [CMake配置示例](assets/example_cmake.txt)
- [权限配置示例](assets/example_permissions.json)

## 测试用例

### 正向测试用例
- [短视频卡顿上报](tests/test_positive.cpp)：测试NB_SERVICE_SHORT_VIDEO + NB_QOE_BAD_SERVER_ERROR
- [实时游戏延迟上报](tests/test_positive.cpp)：测试NB_SERVICE_REAL_TIME_GAME + NB_QOE_BAD_HIGH_LATENCY
- [直播丢包上报](tests/test_positive.cpp)：测试NB_SERVICE_LIVE_STREAMING_WATCHER + NB_QOE_BAD_PACKET_LOST

### 边界测试用例
- [最小业务类型](tests/test_boundary.cpp)：测试NB_SERVICE_DEFAULT
- [最大业务类型](tests/test_boundary.cpp)：测试NB_SERVICE_SHOPPING
- [体验良好状态](tests/test_boundary.cpp)：测试NB_QOE_GOOD

### 异常测试用例
- [权限不足](tests/test_exception.cpp)：测试未配置权限时返回201
- [参数超出范围](tests/test_exception.cpp)：测试无效枚举值返回401
- [系统服务失败](tests/test_exception.cpp)：测试系统异常返回62100001/62100002