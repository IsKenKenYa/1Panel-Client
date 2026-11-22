---
name: hmos-networkboost-kit-multipath-statechangecallback-c
description: 监听多网状态变化事件，获取多网建立、释放、挂起等状态信息及变化原因，支持注册/注销回调函数，适用于多网并发场景下感知网络状态变化并调整数据传输策略
---

# 多网状态监听技能(C/C++)

## 功能描述

本技能用于监听HarmonyOS多网状态变化事件。通过注册回调函数，应用可以感知多网建立、释放、挂起等状态变化，获取变化原因、链路类型、链路状态等详细信息，从而在多网并发场景下智能调整数据传输策略，提升用户体验。

核心能力包括：
- 注册多网状态变化回调函数
- 接收多网状态变化事件通知
- 获取多网状态详细信息（状态、原因、链路类型、链路状态等）
- 注销多网状态监听

API版本要求：6.0.2(22)及以上

## 使用场景

### 触发词
- "监听多网状态"
- "多网状态变化"
- "注册多网状态回调"
- "多网并发监听"
- "多网状态通知"
- "NetworkBoost多网状态"

### 能做
- 注册多网状态变化回调函数，获取系统分配的callbackId
- 通过回调函数接收多网状态变化事件通知
- 获取多网状态详细信息：多网状态（空闲态/建立中/已建立/释放中）、变化原因（正常请求/正常释放/网络原因/配额耗尽/功耗限制等）、链路类型（蜂窝主卡/副卡/Wi-Fi主/辅）、链路状态（空闲/连接/挂起）
- 在业务流程结束时注销多网状态监听，释放系统资源
- 根据多网状态变化调整应用数据传输策略（如在多网已建立时启用并发传输，在多网释放时切换回单网）

### 绝不做
- 不用于监听单网状态变化（应使用网络质量或网络场景回调）
- 不用于发起或释放多网请求（应使用RequestMultiPath/ReleaseMultiPath接口）
- 不用于获取多网配额信息（应使用GetMultiPathQuotaStats接口）
- 不用于接收多网推荐信息（应使用RegisterMultiPathRecommendationCallback接口）
- 不在未注册callbackId的情况下尝试注销回调
- 不重复注册相同回调函数（会导致注册失败）

### 补充
- 需要申请ohos.permission.GET_NETWORK_INFO权限
- 回调函数不能为空指针
- callbackId由系统分配，用于注销时识别回调
- 多网状态变化原因包含多种类型，需根据具体原因进行相应处理
- 建议在应用进入前台时注册监听，进入后台或业务结束时注销监听

## 调用规范和规则

### 输入约束
- 回调函数参数不能为空指针
- callbackId参数必须为有效的uint32_t指针，用于接收系统分配的ID
- 注销时传入的callbackId必须为注册时系统分配的ID

### 执行约束
- 注册回调后，回调函数会持续接收多网状态变化事件，直到注销
- 回调函数中不应执行耗时操作，避免阻塞系统回调处理线程
- 回调函数中不应进行多网请求/释放操作，避免递归调用
- 注销操作应在应用退出或业务流程结束时执行

### 内容约束
- 回调函数实现必须包含对NetworkBoost_MultiPathStateChange结构体的完整处理
- 回调函数中应对多网状态、变化原因、链路类型、链路状态进行判断和处理
- 禁止在回调函数中修改传入的结构体指针内容
- 禁止在回调函数中使用阻塞IO操作或长耗时计算

### 降级约束
- 注册失败时（权限不足、参数错误、注册达到上限），应记录错误日志并提示用户检查权限或稍后重试
- 回调函数中遇到异常状态时，应记录状态信息但不中断应用主流程
- 注销失败时（callbackId无效），应忽略错误或记录日志，不影响应用退出流程
- 多网功能不可用时（API版本低于6.0.2(22)或系统不支持），应降级为单网传输策略

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查API版本是否>=6.0.2(22)
2. 检查是否已申请ohos.permission.GET_NETWORK_INFO权限
3. 检查回调函数是否已实现且不为空

**参数准备**：
```cpp
// 定义回调函数
void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* result);

// 定义callbackId变量
uint32_t callbackId = 0;
```

### 步骤2：导入头文件和链接库

**导入必要模块**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>
```

**CMakeLists.txt配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC libnetwork_boost.so)
```

### 步骤3：注册多网状态监听回调

**示例代码**：
```cpp
void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* result) {
    if (result == nullptr) {
        printf("多网状态变化回调: 参数为空\n");
        return;
    }
    
    printf("多网状态变化回调:\n");
    printf("  多网状态: %d\n", result->multiPathState);
    printf("  变化原因: %d\n", result->changeCause);
    printf("  链路类型: %d\n", result->pathType);
    printf("  链路状态: %d\n", result->pathState);
    
    switch (result->multiPathState) {
        case NB_MULTIPATH_IDLE:
            printf("  多网处于空闲状态\n");
            break;
        case NB_MULTIPATH_CREATEING:
            printf("  多网正在建立中\n");
            break;
        case NB_MULTIPATH_CREATED:
            printf("  多网已建立，可启用并发传输\n");
            break;
        case NB_MULTIPATH_RELEASING:
            printf("  多网正在释放中\n");
            break;
        default:
            printf("  未知多网状态\n");
            break;
    }
    
    switch (result->changeCause) {
        case NB_MULTIPATH_CAUSE_REQUEST_NORMAL:
            printf("  变化原因: 正常发起多网请求\n");
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_NORMAL:
            printf("  变化原因: 正常释放多网请求\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_RELEASE_NETWORK:
            printf("  变化原因: 网络原因释放多网\n");
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_NO_QUOTA:
            printf("  变化原因: 配额耗尽释放多网\n");
            break;
        case NB_MULTIPATH_CAUSE_RELEASE_POWER_CONSUMPTION:
            printf("  变化原因: 功耗原因释放多网\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_ENTER:
            printf("  变化原因: 多网进入挂起状态\n");
            break;
        case NB_MULTIPATH_CHANGE_CAUSE_SUSPEND_LEAVE:
            printf("  变化原因: 多网退出挂起状态\n");
            break;
        default:
            printf("  变化原因: %d\n", result->changeCause);
            break;
    }
}

int32_t RegisterMultiPathStateChange() {
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathStateChangeCallback(
        onMultiPathStateChangeCallback, 
        &callbackId
    );
    
    if (ret == 0) {
        printf("注册多网状态监听回调成功, callbackId: %u\n", callbackId);
    } else {
        printf("注册多网状态监听回调失败, 错误码: %d\n", ret);
        switch (ret) {
            case 201:
                printf("  权限不足, 需申请ohos.permission.GET_NETWORK_INFO权限\n");
                break;
            case 401:
                printf("  参数错误, 回调函数或callbackId指针为空\n");
                break;
            case 801:
                printf("  系统能力不支持\n");
                break;
            case 1013600001:
                printf("  内部处理异常\n");
                break;
            case 1013600002:
                printf("  系统服务操作失败\n");
                break;
            case 62100003:
                printf("  注册请求达到上限\n");
                break;
            default:
                printf("  其他错误\n");
                break;
        }
    }
    
    return ret;
}
```

### 步骤4：注销多网状态监听

**示例代码**：
```cpp
int32_t UnregisterMultiPathStateChange() {
    if (callbackId == 0) {
        printf("未注册多网状态监听, 无需注销\n");
        return 0;
    }
    
    int32_t ret = HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback(callbackId);
    
    if (ret == 0) {
        printf("注销多网状态监听成功\n");
        callbackId = 0;
    } else {
        printf("注销多网状态监听失败, 错误码: %d\n", ret);
        switch (ret) {
            case 201:
                printf("  权限不足\n");
                break;
            case 401:
                printf("  callbackId无效\n");
                break;
            case 801:
                printf("  系统能力不支持\n");
                break;
            case 1013600001:
                printf("  内部处理异常\n");
                break;
            case 1013600002:
                printf("  系统服务操作失败\n");
                break;
            default:
                printf("  其他错误\n");
                break;
        }
    }
    
    return ret;
}
```

### 步骤5：完整示例流程

**示例代码**：
```cpp
#include "NetworkBoostKit/network_boost_handover.h"
#include <cstdio>

uint32_t callbackId = 0;
bool isRegistered = false;

void onMultiPathStateChangeCallback(NetworkBoost_MultiPathStateChange* result) {
    if (result == nullptr) {
        return;
    }
    
    printf("多网状态变化: state=%d, cause=%d, pathType=%d, pathState=%d\n",
        result->multiPathState, result->changeCause, 
        result->pathType, result->pathState);
    
    if (result->multiPathState == NB_MULTIPATH_CREATED) {
        printf("多网已建立, 启用并发传输策略\n");
    } else if (result->multiPathState == NB_MULTIPATH_IDLE) {
        printf("多网已释放, 切换回单网传输策略\n");
    }
}

int main() {
    printf("=== 多网状态监听示例 ===\n");
    
    int32_t ret = HMS_NetworkBoost_RegisterMultiPathStateChangeCallback(
        onMultiPathStateChangeCallback, 
        &callbackId
    );
    
    if (ret == 0) {
        isRegistered = true;
        printf("注册成功, callbackId=%u\n", callbackId);
        
        printf("应用运行中, 等待多网状态变化事件...\n");
        
        printf("业务流程结束, 注销监听\n");
        ret = HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback(callbackId);
        if (ret == 0) {
            printf("注销成功\n");
            isRegistered = false;
            callbackId = 0;
        } else {
            printf("注销失败, 错误码=%d\n", ret);
        }
    } else {
        printf("注册失败, 错误码=%d\n", ret);
    }
    
    return 0;
}
```

## 错误码说明

### 注册回调错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 申请ohos.permission.GET_NETWORK_INFO权限 |
| 401 | 参数错误 | 确保回调函数和callbackId指针不为空 |
| 801 | 系统能力不支持 | 检查设备是否支持多网功能 |
| 1013600001 | 内部处理异常 | 记录日志，稍后重试 |
| 1013600002 | 系统服务操作失败 | 检查网络服务状态，重启应用 |
| 62100003 | 注册请求达到上限 | 注销已有回调后再注册新回调 |

### 注销回调错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 无需处理 |
| 201 | 权限不足 | 检查权限配置 |
| 401 | callbackId无效 | 使用注册时系统分配的callbackId |
| 801 | 系统能力不支持 | 检查设备是否支持多网功能 |
| 1013600001 | 内部处理异常 | 记录日志，不影响应用退出 |
| 1013600002 | 系统服务操作失败 | 记录日志，不影响应用退出 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(NetworkBoostDemo)

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

**module.json5权限配置**：
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

### 环境要求
- HarmonyOS SDK: 6.0.2(22)及以上
- 系统能力: SystemCapability.Communication.NetworkBoost.Core
- 开发环境: DevEco Studio 5.0及以上

### 常见编译问题

**问题1：找不到头文件NetworkBoostKit/network_boost_handover.h**
```
fatal error: NetworkBoostKit/network_boost_handover.h: No such file or directory
```
**解决方法**：
- 确保已配置正确的SDK路径`${HMOS_SDK_NATIVE}/sysroot/usr/include`
- 确保HarmonyOS SDK版本>=6.0.2(22)
- 在CMakeLists.txt中添加target_include_directories配置

**问题2：链接libnetwork_boost.so失败**
```
undefined reference to `HMS_NetworkBoost_RegisterMultiPathStateChangeCallback'
```
**解决方法**：
- 在CMakeLists.txt中添加target_link_directories配置
- 在target_link_libraries中添加libnetwork_boost.so
- 确保链接路径正确：`${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos`

**问题3：权限不足导致注册失败**
```
注册回调返回错误码201
```
**解决方法**：
- 在module.json5中添加ohos.permission.GET_NETWORK_INFO权限声明
- 检查应用签名配置是否正确
- 参考开发准备文档完成权限申请和配置签名

## 常见问题与解决方法

### Q1：注册回调时返回错误码62100003（注册达到上限）
**原因**：系统对多网状态回调注册数量有限制，已达到上限
**解决方法**：
- 注销已有的多网状态回调后再注册新回调
- 避免重复注册相同回调函数
- 使用全局callbackId变量管理回调生命周期

### Q2：回调函数中无法获取多网状态信息
**原因**：回调函数实现不完整或未正确处理结构体
**解决方法**：
- 确保回调函数中正确解析NetworkBoost_MultiPathStateChange结构体
- 检查回调函数参数是否为空指针
- 根据多网状态枚举值进行switch判断处理

### Q3：注销回调时返回错误码401（参数错误）
**原因**：传入的callbackId无效或未正确保存注册时分配的ID
**解决方法**：
- 使用全局变量保存注册时系统分配的callbackId
- 注销前检查callbackId是否为0（未注册状态）
- 确保注销时传入的是注册时分配的callbackId

### Q4：多网状态回调未触发或触发频率异常
**原因**：多网功能未启用或系统多网状态未变化
**解决方法**：
- 确保已使用RequestMultiPath接口发起多网请求
- 检查系统是否支持多网并发能力
- 多网状态仅在系统多网状态变化时触发回调，无变化时不触发

### Q5：回调函数中如何区分不同的多网状态变化原因
**原因**：多网变化原因枚举值较多，需要根据具体原因进行不同处理
**解决方法**：
- 使用switch语句对changeCause字段进行判断
- 参考NetworkBoost_MultiPathChangeCause枚举定义
- 根据变化原因调整应用策略（如配额耗尽时提示用户，网络原因时降级处理）

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "callbackId": 12345,
  "multiPathState": 2,
  "changeCause": 0,
  "pathType": 0,
  "pathState": 1,
  "apiUsed": [
    "HMS_NetworkBoost_RegisterMultiPathStateChangeCallback",
    "HMS_NetworkBoost_UnregisterMultiPathStateChangeCallback"
  ],
  "message": "多网状态监听已注册，等待状态变化事件"
}
```

## 参考文档

- [多网状态监听开发指南(C/C++)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-netmultipath-statechangecallback-c)
- [NetworkBoost API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-overview)
- [network_boost_handover.h头文件说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-files-handover)
- [NetworkBoost_MultiPathStateChange结构体说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/network-boost-c-struct-multipath_statechange)
- [开发准备-权限配置](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/networkboost-preparations)

## 完整示例代码

- [C++完整示例代码](assets/example_multipath_statechangecallback.cpp)

## 测试用例

### 正向测试用例
- [注册多网状态回调成功](tests/test_positive.cpp)：验证注册回调返回成功并获取有效callbackId
- [接收多网状态变化事件](tests/test_positive.cpp)：验证回调函数正确接收并处理状态变化事件
- [注销多网状态回调成功](tests/test_positive.cpp)：验证注销回调返回成功

### 边界测试用例
- [注册达到上限时注册失败](tests/test_boundary.cpp)：验证注册数量达到上限时返回错误码62100003
- [未注册时注销失败](tests/test_boundary.cpp)：验证未注册状态时注销返回错误码401
- [API版本不支持时注册失败](tests/test_boundary.cpp)：验证API版本低于6.0.2(22)时返回错误码801

### 异常测试用例
- [回调函数为空指针](tests/test_exception.cpp)：验证传入空回调函数返回错误码401
- [callbackId指针为空](tests/test_exception.cpp)：验证传入空callbackId指针返回错误码401
- [权限不足时注册失败](tests/test_exception.cpp)：验证未申请权限时返回错误码201
- [注销时传入无效callbackId](tests/test_exception.cpp)：验证传入无效callbackId返回错误码401