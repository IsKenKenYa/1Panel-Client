---
name: hmos-remote-communication-kit-close-session
description: 关闭HTTP会话并释放相关资源+支持C++语言+需要在请求完成后调用+适用于网络通信清理场景
---

# 关闭会话（C++）技能

## 功能描述

关闭远场通信HTTP会话，释放会话占用的系统资源（内存、网络带宽、处理器时间等），清理内部状态信息（缓存、连接状态标志等），确保系统资源有效回收，提高系统稳定性和性能。

**核心能力**：
- 关闭HTTP会话
- 释放系统资源
- 清理内部状态
- 防止资源泄漏

**起始版本**：5.0.0(12)

## 使用场景

### 触发词
- "关闭会话"
- "关闭HTTP会话"
- "释放会话资源"
- "清理session"
- "关闭远场通信会话"

### 能做
- 关闭已完成的HTTP会话
- 释放会话占用的系统资源
- 清理会话相关的内部状态
- 在请求成功或失败后清理资源
- 防止资源泄漏和状态冲突

### 绝不做
- 不创建新的会话（应使用HMS_Rcp_CreateSession）
- 不发起HTTP请求（应使用HMS_Rcp_Fetch或HMS_Rcp_FetchSync）
- 不处理请求响应数据
- 不替代取消会话操作（HMS_Rcp_CancelSession用于取消进行中的请求）

### 补充
- 关闭会话前建议先调用HMS_Rcp_CancelSession取消可能还在执行的请求
- 关闭会话后session指针会被置空
- 关闭会话是资源管理的必要步骤，必须在会话使用完成后调用
- 一个应用最多能创建16个session实例，及时关闭会话可以释放实例占用

## 调用规范和规则

### 输入约束
- session参数必须是通过HMS_Rcp_CreateSession创建的有效会话指针
- session指针不能为NULL
- 传入参数必须是Rcp_Session**类型（指针的指针）

### 执行约束
- 必须在请求完成后（成功或失败）调用
- 建议在关闭前先调用HMS_Rcp_CancelSession
- 最大耗时：预计小于10ms
- 单次调用：每个会话只能关闭一次

### 内容约束
- 禁止在会话关闭后继续使用该session指针
- 禁止跳过关闭步骤直接销毁request
- 禁止重复关闭已关闭的会话

### 降级约束
- 如果关闭失败（errCode != 0），记录错误日志并尝试再次关闭
- 如果session指针已为NULL，跳过关闭操作并记录警告
- 如果系统资源紧张，优先关闭不再使用的会话

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查session指针是否有效（不为NULL）
2. 确认所有请求已完成或已取消
3. 检查是否需要先调用HMS_Rcp_CancelSession

**参数准备**：
```cpp
// C++示例
Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
// ... 使用session发起请求 ...

// 准备关闭会话
// 检查session是否有效
if (session == NULL) {
    printf("Session is NULL, skip close operation\n");
    return;
}
```

### 步骤2：取消进行中的请求

**示例代码**：
```cpp
// 在退出前取消可能还在执行的requests
uint32_t errCode = HMS_Rcp_CancelSession(session);
if (errCode != 0) {
    printf("Cancel session failed, errCode: %u\n", errCode);
    // 继续尝试关闭会话
}
```

### 步骤3：关闭会话

**示例代码**：
```cpp
#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>

// 关闭session
errCode = HMS_Rcp_CloseSession(&session);
if (errCode != 0) {
    printf("Close session failed, errCode: %u\n", errCode);
    // 根据错误码进行错误处理
} else {
    printf("Session closed successfully\n");
    // session指针已被置空
    if (session == NULL) {
        printf("Session pointer is NULL now\n");
    }
}
```

### 步骤4：清理request

**示例代码**：
```cpp
// 清理request
HMS_Rcp_DestroyRequest(request);
request = NULL;
```

### 步骤5：错误处理

**完整错误处理代码**：
```cpp
void closeSessionWithErrorHandling(Rcp_Session **session, Rcp_Request *request) {
    if (session == NULL || *session == NULL) {
        printf("Session pointer is NULL, skip close operation\n");
        return;
    }
    
    // 取消可能还在执行的请求
    uint32_t errCode = HMS_Rcp_CancelSession(*session);
    if (errCode != 0) {
        printf("Cancel session failed, errCode: %u, continue to close\n", errCode);
    }
    
    // 关闭会话
    errCode = HMS_Rcp_CloseSession(session);
    if (errCode != 0) {
        printf("Close session failed, errCode: %u\n", errCode);
        // 根据错误码进行处理
        // 错误码说明见错误码表
    } else {
        printf("Session closed successfully\n");
    }
    
    // 清理request
    if (request != NULL) {
        HMS_Rcp_DestroyRequest(request);
        request = NULL;
    }
}
```

### 步骤6：降级处理

**降级处理代码**：
```cpp
void safeCloseSession(Rcp_Session **session) {
    // 降级方案1：检查指针有效性
    if (session == NULL || *session == NULL) {
        printf("Warning: Session pointer is NULL\n");
        return;
    }
    
    // 降级方案2：多次尝试关闭
    uint32_t errCode = 0;
    int retryCount = 0;
    const int MAX_RETRY = 3;
    
    do {
        errCode = HMS_Rcp_CloseSession(session);
        if (errCode != 0) {
            retryCount++;
            printf("Close failed (attempt %d), errCode: %u\n", retryCount, errCode);
            if (retryCount < MAX_RETRY) {
                usleep(1000); // 等待1ms后重试
            }
        } else {
            printf("Session closed successfully\n");
            break;
        }
    } while (retryCount < MAX_RETRY && errCode != 0);
    
    // 降级方案3：最终失败处理
    if (errCode != 0) {
        printf("Error: Failed to close session after %d attempts\n", MAX_RETRY);
        // 记录错误日志，应用可以继续运行但可能存在资源泄漏
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| 1007900001 | Session内部错误 | 检查session状态，可能已损坏 |
| 1007900002 | Session未找到 | 确认session是否已关闭或无效 |
| 1007900003 | Session已关闭 | 避免重复关闭操作 |
| 1007900004 | 参数错误 | 检查session指针是否为有效指针的指针 |
| 1007900005 | 内存分配失败 | 检查系统内存状态 |
| 1007900201 | HTTP明文传输被拦截 | 检查network_config.json配置 |

**错误码验证方法**：
```cpp
uint32_t errCode = HMS_Rcp_CloseSession(&session);
switch (errCode) {
    case 0:
        printf("Success: Session closed\n");
        break;
    case 1007900001:
        printf("Error: Session internal error\n");
        break;
    case 1007900002:
        printf("Error: Session not found\n");
        break;
    case 1007900003:
        printf("Error: Session already closed\n");
        break;
    case 1007900004:
        printf("Error: Invalid parameter\n");
        break;
    default:
        printf("Error: Unknown error code %u\n", errCode);
        break;
}
```

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 设置动态库路径及头文件路径
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)

# 链接librcp_c.so
target_link_libraries(entry PUBLIC librcp_c.so)
```

**权限配置（module.json5）**：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      },
      {
        "name": "ohos.permission.GET_NETWORK_INFO"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)及以上
- 设备类型：Phone、2in1、Tablet、Wearable（5.0+）
- TV设备：5.1.1(19)及以上
- Car设备：6.1.0(23)及以上

### 常见编译问题

**问题1：找不到头文件**
```
error: 'RemoteCommunicationKit/rcp.h' file not found
```
**解决方法**：
- 确认HMOS_SDK_NATIVE环境变量已设置
- 检查target_include_directories配置是否正确
- 确认SDK路径中存在sysroot/usr/include目录

**问题2：链接librcp_c.so失败**
```
error: cannot find -llibrcp_c.so
```
**解决方法**：
- 检查target_link_directories路径是否正确
- 确认librcp_c.so文件存在于指定路径
- 确认架构匹配（aarch64-linux-ohos）

**问题3：权限未配置**
```
运行时错误：Permission denied
```
**解决方法**：
- 在module.json5中添加ohos.permission.INTERNET权限
- 注意：关闭会话不需要权限，但创建会话和发起请求需要权限

## 常见问题与解决方法

### Q1：关闭会话后session指针是否为NULL？
**原因**：HMS_Rcp_CloseSession会将session指针置空
**解决方法**：
- 关闭后不需要手动设置session = NULL
- 可以通过检查session == NULL确认关闭成功

### Q2：是否需要在关闭前调用HMS_Rcp_CancelSession？
**原因**：如果有请求还在执行，直接关闭可能导致资源未完全释放
**解决方法**：
- 建议在关闭前先调用HMS_Rcp_CancelSession
- 特别是异步请求（HMS_Rcp_Fetch）可能还在执行

### Q3：关闭会话失败如何处理？
**原因**：可能是session状态异常或系统资源紧张
**解决方法**：
- 检查错误码并根据错误类型处理
- 可以尝试多次关闭（最多3次）
- 记录错误日志，应用可继续运行

### Q4：如何确认会话已成功关闭？
**原因**：需要验证资源是否完全释放
**解决方法**：
- 检查返回的errCode是否为0
- 验证session指针是否为NULL
- 监控系统资源使用情况

### Q5：一个应用最多能创建多少个session？
**原因**：系统限制最多16个session实例
**解决方法**：
- 及时关闭不再使用的会话
- 合理管理会话生命周期
- 避免创建过多不必要的会话

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "sessionClosed": true,
  "sessionPointer": "NULL",
  "errorCode": 0,
  "apiUsed": [
    "HMS_Rcp_CancelSession",
    "HMS_Rcp_CloseSession",
    "HMS_Rcp_DestroyRequest"
  ],
  "message": "Session closed successfully, resources released"
}
```

**输出验证**：
- errCode == 0表示成功
- session指针为NULL确认关闭完成
- 资已释放request避免内存泄漏

## 参考文档

- [关闭会话开发指南](references/remote-communication-netclose-c.md)
- [Remote Communication Kit C API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-preparations)

## 完整示例代码

- [C++完整示例](assets/example_close_session.cpp)

## 测试用例

### 正向测试用例
- [正常关闭会话](tests/test_positive.cpp)：创建会话、发起请求、关闭会话
- [异步请求后关闭](tests/test_positive.cpp)：异步请求完成后关闭会话

### 边界测试用例
- [立即关闭会话](tests/test_boundary.cpp)：创建会话后立即关闭
- [多次尝试关闭](tests/test_boundary.cpp)：关闭失败后重试

### 异常测试用例
- [NULL指针关闭](tests/test_exception.cpp)：传入NULL指针
- [重复关闭会话](tests/test_exception.cpp)：关闭已关闭的会话
- [未创建会话关闭](tests/test_exception.cpp)：关闭未创建的会话