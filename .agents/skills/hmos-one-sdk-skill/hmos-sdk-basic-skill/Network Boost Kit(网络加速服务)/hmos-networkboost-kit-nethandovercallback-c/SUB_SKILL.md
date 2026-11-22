---
name: hmos-networkboost-kit-nethandovercallback-c
description: 提供连接迁移通知能力，通过注册回调监听网络连接迁移开始和完成事件，应用根据迁移建议进行重建和恢复，适用于弱网环境下多网切换场景（WiFi-蜂窝、主卡-副卡），最大支持单个应用注册上限，需要GET_NETWORK_INFO权限，适用于实时通信、视频会议、游戏等对网络切换敏感的业务场景
---

# 连接迁移通知技能 (C/C++)

## 功能描述

本技能提供Network Boost Kit的连接迁移通知能力，通过注册回调函数监听系统发起的网络连接迁移事件。在弱网环境下，系统会发起多网迁移（WiFi <-> 蜂窝，主卡 <-> 副卡等），本技能帮助应用接收迁移开始和完成的通知，并根据系统建议调整数传策略和重建链路，快速恢复业务，实现平滑、高速、低时延的上网体验。

**核心能力**：
- 注册连接迁移回调，监听迁移开始和完成事件
- 接收系统提供的迁移建议（数传策略调整、链路重建方式）
- 取消注册回调，释放监听资源
- 支持委托模式和自主模式切换

**适用范围**：
- HarmonyOS 5.1.0(18)及以上版本
- C/C++ Native开发环境
- 需要申请ohos.permission.GET_NETWORK_INFO权限

**典型场景**：
- 实时音视频通话（VoIP、视频会议）
- 在线游戏（实时对战、多人游戏）
- 直播场景（主播推流、观众观看）
- 金融交易（支付、扫码）
- 导航定位服务

## 使用场景

### 触发词
- "连接迁移通知" - 注册监听网络切换事件
- "网络切换回调" - 获取多网迁移信息
- "WiFi蜂窝切换" - 监听WiFi和蜂窝网络迁移
- "多网迁移监听" - 接收网络连接迁移通知
- "弱网重建" - 根据迁移建议重建网络连接
- "NetworkBoost连接迁移" - Network Boost Kit的连接迁移功能

### 能做
- 注册连接迁移开始和完成事件的回调监听
- 接收迁移开始通知，包含数传策略建议（暂停、降速、加速、保持）
- 接收迁移完成通知，包含链路重建建议（查询DNS、更换远端IP、更换IP版本）
- 根据系统建议快速调整应用数传策略
- 根据重建建议快速恢复业务连接
- 取消注册回调，停止监听连接迁移事件
- 设置连接迁移模式（委托模式/自主模式）

### 绝不做
- 不直接发起网络切换（由系统触发）
- 不替代应用的具体业务逻辑（仅提供建议）
- 不处理超出连接迁移范围的其他网络事件
- 不在无权限情况下强制注册回调
- 不处理多网并发请求（需要使用其他技能）

### 补充
- 回调函数必须同时实现onNetworkHandoverStart和onNetworkHandoverComplete
- 注册回调数量有上限限制，超过会返回错误码62100003
- 迁移建议需要应用自行实现具体调整逻辑
- 委托模式下由系统自动发起迁移，自主模式下应用可禁止系统迁移

## 调用规范和规则

### 输入约束
- 回调函数结构体必须完整，不能为空指针
- callback和callbackId参数必须为有效指针
- callbackId用于后续取消注册，需要保存
- 回调函数中不能执行耗时超过100ms的操作

### 执行约束
- 最大注册次数：单个应用有注册上限（具体数值由系统配置）
- 回调函数执行时间：建议不超过100ms，避免阻塞系统
- API调用频次：注册和取消注册不建议频繁调用
- 最大耗时：API调用本身耗时不超过50ms

### 内容约束
- 禁止在回调函数中执行阻塞操作（如文件I/O、网络请求）
- 禁止在回调函数中调用其他Network Boost API（避免递归调用）
- 禁止使用高危函数（如eval、exec、system等）
- 禁止在回调中修改全局状态或执行内存分配

### 降级约束
- 注册失败：提示权限不足或注册上限，建议使用其他网络监听方式
- 回调未触发：可能未发生迁移事件，保持当前网络连接
- 迁移建议无法执行：保持当前策略，等待下一次迁移通知
- 权限不足：提示用户申请GET_NETWORK_INFO权限

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查HarmonyOS版本是否≥5.1.0(18)
2. 检查是否已申请ohos.permission.GET_NETWORK_INFO权限
3. 检查CMakeLists.txt是否已添加libnetwork_boost.so依赖
4. 检查回调函数是否已正确实现

**参数准备**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

uint32_t callbackId = 0;  // 用于保存回调ID
```

**权限配置**：
在module.json5中添加权限声明：
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

### 步骤2：实现回调函数

**回调函数定义**：
```cpp
void onNetworkHandoverStart(NetworkBoost_HandoverStart* handoverStart) {
    if (handoverStart == nullptr) {
        printf("HandoverStart参数为空\n");
        return;
    }
    
    printf("连接迁移开始通知\n");
    printf("建议动作：%d\n", handoverStart->recommendedAction);
    
    switch (handoverStart->recommendedAction) {
        case NB_ACTION_DO_CACHING:
            printf("建议：执行缓存动作\n");
            break;
        case NB_ACTION_SUSPEND_DATA:
            printf("建议：暂停发包\n");
            break;
        case NB_ACTION_DECREASE_DATA:
            printf("建议：降低发包速率\n");
            break;
        case NB_ACTION_INCREASE_DATA:
            printf("建议：增加发包速率\n");
            break;
        case NB_ACTION_KEEP_DATA:
            printf("建议：保持当前速率\n");
            break;
        default:
            printf("未知的建议动作：%d\n", handoverStart->recommendedAction);
            break;
    }
}

void onNetworkHandoverComplete(NetworkBoost_HandoverComplete* handoverComplete) {
    if (handoverComplete == nullptr) {
        printf("HandoverComplete参数为空\n");
        return;
    }
    
    printf("连接迁移完成通知\n");
    printf("迁移结果：%d\n", handoverComplete->errorResult);
    printf("重建建议：%d\n", handoverComplete->reEstAction);
    
    if (handoverComplete->errorResult == NB_ERROR_NONE) {
        printf("迁移成功\n");
        
        switch (handoverComplete->reEstAction) {
            case NB_REEST_DEFAULT:
                printf("建议：使用相同远端IP重建链路\n");
                break;
            case NB_REEST_QUERY_DNS:
                printf("建议：重新查询DNS（链路类型变化）\n");
                break;
            case NB_REEST_CHANGE_REMOTE_IP:
                printf("建议：更换远端IP重建链路\n");
                break;
            case NB_REEST_CHANGE_IP_VERSION:
                printf("建议：修改IP版本重建（IPv4 <-> IPv6）\n");
                break;
            case NB_NO_EST:
                printf("建议：在老链路立即重试，无需重建\n");
                break;
            default:
                printf("未知的重建建议：%d\n", handoverComplete->reEstAction);
                break;
        }
    } else {
        printf("迁移失败，错误码：%d\n", handoverComplete->errorResult);
        handleHandoverError(handoverComplete->errorResult);
    }
}
```

### 步骤3：注册回调

**注册函数实现**：
```cpp
int32_t RegisterNetworkHandoverCallback() {
    HMS_NetworkBoost_HandoverCallback callback;
    callback.onNetworkHandoverStart = onNetworkHandoverStart;
    callback.onNetworkHandoverComplete = onNetworkHandoverComplete;
    
    int32_t ret = HMS_NetworkBoost_RegisterHandoverChangeCallback(&callback, &callbackId);
    
    if (ret == 0) {
        printf("注册连接迁移回调成功，ID：%u\n", callbackId);
        return 0;
    } else {
        printf("注册失败，错误码：%d\n", ret);
        return ret;
    }
}
```

### 步骤4：错误处理

**错误处理函数**：
```cpp
void handleHandoverError(NetworkBoost_ErrorResult error) {
    switch (error) {
        case NB_ERROR_HANDOVER_TIMEOUT:
            printf("错误：连接迁移超时，建议等待系统重试\n");
            break;
        case NB_ERROR_NEW_PATH_ACTIVATION_FAILED:
            printf("错误：新链路激活失败，建议回退到原链路\n");
            break;
        case NB_ERROR_ABORT:
            printf("错误：迁移被取消，建议保持当前连接\n");
            break;
        default:
            printf("错误：未知错误，错误码：%d\n", error);
            break;
    }
}

void handleRegisterError(int32_t errorCode) {
    switch (errorCode) {
        case 201:
            printf("权限不足，请申请ohos.permission.GET_NETWORK_INFO权限\n");
            break;
        case 401:
            printf("参数错误，请检查回调函数是否正确实现\n");
            break;
        case 801:
            printf("系统能力不支持，请检查HarmonyOS版本\n");
            break;
        case 62100001:
            printf("内部错误，请稍后重试\n");
            break;
        case 62100002:
            printf("系统服务操作失败，请检查网络服务状态\n");
            break;
        case 62100003:
            printf("注册请求达到上限，请取消其他回调后再注册\n");
            break;
        default:
            printf("未知错误，错误码：%d\n", errorCode);
            break;
    }
}
```

### 步骤5：取消注册

**取消注册函数**：
```cpp
int32_t UnregisterNetworkHandoverCallback() {
    if (callbackId == 0) {
        printf("回调未注册或已取消\n");
        return -1;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterHandoverChangeCallback(callbackId);
    
    if (ret == 0) {
        printf("取消注册成功\n");
        callbackId = 0;
        return 0;
    } else {
        printf("取消注册失败，错误码：%d\n", ret);
        return ret;
    }
}
```

### 步骤6：降级处理

**降级方案**：
```cpp
void fallbackStrategy() {
    printf("无法注册连接迁移回调，使用降级方案\n");
    printf("建议：使用网络质量回调监听网络状态变化\n");
    printf("建议：使用定时器定期检查网络连接状态\n");
}
```

## 错误码说明

### 注册/取消注册错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 申请ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 检查回调函数指针是否有效 |
| 801 | 系统能力不支持 | 检查HarmonyOS版本是否≥5.1.0(18) |
| 62100001 | 内部错误 | 稍后重试或重启应用 |
| 62100002 | 系统服务操作失败 | 检查网络服务状态，重启设备 |
| 62100003 | 注册请求达到上限 | 取消其他回调或减少注册数量 |

### 迁移结果错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| NB_ERROR_NONE (0) | 迁移成功 | 根据重建建议恢复业务 |
| NB_ERROR_HANDOVER_TIMEOUT (1) | 迁移超时 | 等待系统重试或保持原连接 |
| NB_ERROR_NEW_PATH_ACTIVATION_FAILED (2) | 新链路激活失败 | 回退到原链路或重试迁移 |
| NB_ERROR_ABORT (3) | 迁移被取消 | 保持当前连接，等待下次迁移 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(networkboost_handover_demo)

set(CMAKE_CXX_STANDARD 17)

add_executable(networkboost_handover_demo
    src/main.cpp
)

target_link_libraries(networkboost_handover_demo
    libnetwork_boost.so
)

target_include_directories(networkboost_handover_demo
    PRIVATE
    ${CMAKE_CURRENT_SOURCE_DIR}/include
)
```

### 环境要求
- HarmonyOS SDK：5.1.0(18)及以上
- Native开发环境：支持C++17标准
- 编译工具：DevEco Studio或cmake 3.4.1+
- 运行设备：支持Network Boost Kit的HarmonyOS设备

### 常见编译问题

**问题1：找不到NetworkBoostKit头文件**
```
error: 'NetworkBoostKit/network_boost_handover.h' file not found
```
**解决方法**：
- 检查HarmonyOS SDK是否正确安装
- 检查头文件路径是否在include_directories中配置
- 确认SDK版本是否≥5.1.0(18)

**问题2：链接libnetwork_boost.so失败**
```
error: cannot find -lnetwork_boost
```
**解决方法**：
- 检查CMakeLists.txt中是否正确添加target_link_libraries
- 确认libnetwork_boost.so库文件存在于SDK目录
- 检查库文件路径是否正确配置

**问题3：权限未配置导致运行时错误**
```
错误码：201（权限不足）
```
**解决方法**：
- 在module.json5中添加ohos.permission.GET_NETWORK_INFO权限
- 检查权限是否正确签名和授权

## 常见问题与解决方法

### Q1：注册回调失败，错误码62100003
**原因**：应用注册的回调数量已达到系统上限
**解决方法**：
- 取消不再需要的其他回调注册
- 使用callbackId管理回调，避免重复注册
- 检查是否有多次注册同一回调

### Q2：回调函数未触发
**原因**：
1. 未发生网络迁移事件（WiFi <-> 蜂窝、主卡 <-> 副卡）
2. 系统处于非弱网环境，未触发迁移
3. 回调函数指针无效或未正确设置
**解决方法**：
- 检查网络环境是否确实发生了迁移
- 确认回调函数指针是否正确赋值
- 查看系统日志确认是否有迁移事件

### Q3：迁移建议无法执行
**原因**：
1. 应用未实现相应的数传策略调整逻辑
2. 重建建议需要特定的业务逻辑支持
3. 迁移失败导致建议无效
**解决方法**：
- 根据建议类型实现对应的策略调整
- 在迁移成功时才执行重建建议
- 失败时保持原连接，等待下次迁移

### Q4：迁移过程中业务中断
**原因**：应用未及时响应迁移通知
**解决方法**：
- 在回调中快速执行策略调整（建议<100ms）
- 避免在回调中执行耗时操作
- 迁移完成后立即按建议重建连接

### Q5：如何区分委托模式和自主模式
**原因**：不理解两种迁移模式的区别
**解决方法**：
- 委托模式（默认）：系统自动判断并发起迁移
- 自主模式：应用可禁止系统迁移，自行决定
- 使用HMS_NetworkBoost_SetHandoverMode设置模式

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "callbackId": "uint32数值",
  "registeredCallbacks": ["onNetworkHandoverStart", "onNetworkHandoverComplete"],
  "apiUsed": [
    "HMS_NetworkBoost_RegisterHandoverChangeCallback",
    "HMS_NetworkBoost_UnregisterHandoverChangeCallback"
  ],
  "permissions": ["ohos.permission.GET_NETWORK_INFO"],
  "sdkVersion": "5.1.0(18)"
}
```

## 参考文档

- [API开发指南](references/api-guide.md)
- [API参考说明](references/api-reference.md)

## 完整示例代码

- [C++完整示例](assets/example_networkboost_handover.cpp)
- [CMake配置示例](assets/CMakeLists.txt.example)

## 测试用例

### 正向测试用例
- [成功注册回调](tests/test_register_success.cpp)：验证正常注册流程
- [成功接收迁移通知](tests/test_receive_notification.cpp)：验证回调触发
- [成功取消注册](tests/test_unregister_success.cpp)：验证取消注册流程

### 边界测试用例
- [达到注册上限](tests/test_register_limit.cpp)：测试注册数量上限
- [回调函数空指针](tests/test_null_callback.cpp)：测试空指针参数
- [多次注册取消](tests/test_multiple_register.cpp)：测试重复操作

### 异常测试用例
- [权限不足](tests/test_permission_denied.cpp)：测试无权限场景
- [系统服务异常](tests/test_service_error.cpp)：测试服务失败场景
- [参数错误](tests/test_invalid_param.cpp)：测试无效参数场景