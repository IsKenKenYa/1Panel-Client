---
name: hmos-remote-communication-kit-cancel-request-c
description: 取消HTTP网络请求，支持取消指定请求和会话全部请求，适用于C++开发场景，最大支持Phone/2in1/Tablet/Wearable/TV/Car设备
---

# 取消网络请求（C++）技能

## 功能描述

本技能提供取消HTTP网络请求的能力，使用Remote Communication Kit的C API。支持两种取消方式：
1. 取消指定的单个网络请求（HMS_Rcp_CancelRequest）
2. 取消会话中的所有网络请求（HMS_Rcp_CancelSession）

灵活管理和控制网络请求的执行，优化网络资源使用，提升应用程序用户体验。

## 使用场景

### 触发词
- "取消网络请求"
- "取消HTTP请求"
- "取消指定请求"
- "取消会话请求"
- "停止网络请求"

### 能做
- 取消正在进行的单个HTTP请求
- 取消会话中的所有正在进行的HTTP请求
- 释放网络资源，优化性能
- 提供请求取消后的错误处理

### 绝不做
- 不创建新的网络请求
- 不处理请求取消后的数据保存
- 不替代正常的请求完成流程
- 不处理非HTTP协议的请求取消

### 补充
- 支持设备：Phone、2in1、Tablet、Wearable（5.1.1(19)起支持TV，6.1.0(23)起支持Car）
- API起始版本：5.0.0(12)
- 取消操作是异步的，可能需要等待回调确认

## 调用规范和规则

### 输入约束
- 会话对象：必须是有效的Rcp_Session指针，不能为NULL
- 请求对象：取消单个请求时，必须是有效的Rcp_Request指针
- URL地址：需要是合法的HTTP/HTTPS URL
- 权限要求：需要网络访问权限

### 执行约束
- 最大耗时：取消操作通常在100ms内完成
- 最大迭代次数：单次调用，无需迭代
- API调用频次：无限制，但建议合理控制
- 并发限制：可以在任何时候调用取消API

### 内容约束
- 禁止生成：不生成新的网络请求代码
- 禁止使用高危函数：不使用系统级网络操作函数
- 禁止操作：不在取消后强制关闭会话（除非明确要求）

### 降级约束
- 会话已关闭：提示用户会话无效，重新创建会话
- 请求不存在：忽略取消操作，记录日志
- 权限不足：提示用户检查权限配置
- 参数错误：提示用户检查参数有效性

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查会话对象是否有效（不为NULL）
2. 检查请求对象是否有效（取消单个请求时）
3. 验证网络权限是否已配置
4. 确认当前设备类型支持该API

**参数准备**：
```cpp
// C++参数准备示例
#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>

const char *kHttpServerAddress = "http://www.example.com/delete";
uint32_t errCode = 0;
```

### 步骤2：创建会话和请求

**示例代码**：
```cpp
// 创建请求对象
Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
request->method = RCP_METHOD_DELETE;

// 创建会话
Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
if (errCode != 0) {
    printf("Failed to create session: errCode = %u\n", errCode);
    return -1;
}

// 配置请求回调
void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode)
{
    (void *)usrCtx;
    if (response != NULL) {
        printf("Response status: %d\n", response->statusCode);
    } else {
        printf("Fetch failed: errCode: %u\n", errCode);
    }
    if (response != NULL) {
        response->destroyResponse(response);
    }
}

Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
```

### 步骤3：发起请求

**示例代码**：
```cpp
// 发起fetch请求
errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
if (errCode != 0) {
    printf("Failed to fetch: errCode = %u\n", errCode);
}
```

### 步骤4：取消请求

**示例代码**：
```cpp
// 取消指定request的请求
errCode = HMS_Rcp_CancelRequest(session, request);
if (errCode == 0) {
    printf("Request canceled successfully\n");
} else {
    printf("Failed to cancel request: errCode = %u\n", errCode);
    // 处理错误码
    switch (errCode) {
        case 201:
            printf("Permission denied\n");
            break;
        case 401:
            printf("Parameter error\n");
            break;
        case 1007900993:
            printf("Session closed or invalid\n");
            break;
        default:
            printf("Unknown error\n");
    }
}

// 取消指定session的全部请求
errCode = HMS_Rcp_CancelSession(session);
if (errCode == 0) {
    printf("Session canceled successfully\n");
} else {
    printf("Failed to cancel session: errCode = %u\n", errCode);
}
```

### 步骤5：清理资源

**示例代码**：
```cpp
// 清理request
HMS_Rcp_DestroyRequest(request);

// 关闭session
errCode = HMS_Rcp_CloseSession(&session);
if (errCode != 0) {
    printf("Failed to close session: errCode = %u\n", errCode);
}
```

### 步骤6：错误处理

**完整错误处理示例**：
```cpp
void HandleCancelError(uint32_t errCode) {
    switch (errCode) {
        case 0:
            printf("Operation successful\n");
            break;
        case 201:
            printf("Error: Permission denied. Check network permissions.\n");
            break;
        case 401:
            printf("Error: Invalid parameters. Check session and request objects.\n");
            break;
        case 1007900993:
            printf("Error: Session is closed or invalid. Recreate the session.\n");
            break;
        default:
            printf("Error: Unknown error code %u\n", errCode);
            break;
    }
}
```

### 步骤7：降级处理

**降级处理示例**：
```cpp
// 降级处理：如果取消失败，等待请求自然完成或超时
void FallbackCancelRequest(Rcp_Session *session, Rcp_Request *request) {
    uint32_t errCode = HMS_Rcp_CancelRequest(session, request);
    if (errCode != 0) {
        printf("Cancel failed, waiting for request to complete naturally\n");
        // 可以设置较短的超时时间，让请求快速结束
        // 或者直接关闭会话（根据业务需求）
        printf("Warning: Request may continue running\n");
    }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| 201 | 权限不足 | 检查应用是否具有网络访问权限，在配置文件中添加ohos.permission.INTERNET权限 |
| 401 | 参数错误 | 检查session和request参数是否为有效指针，是否为NULL |
| 1007900993 | 会话已关闭或无效 | 重新创建会话后再进行操作 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
# 添加Remote Communication Kit库依赖
target_link_libraries(your_target librcp_c.so)

# 如果使用其他依赖库
target_link_libraries(your_target 
    librcp_c.so
    # 其他依赖...
)
```

**模块导入**：
```cpp
#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
```

### 环境要求
- HarmonyOS SDK：最低版本5.0.0(12)
- 开发环境：支持C++的HarmonyOS开发环境
- 设备支持：Phone、2in1、Tablet、Wearable、TV（5.1.1(19)+）、Car（6.1.0(23)+）

### 常见编译问题

**问题1：找不到rcp.h头文件**
```
fatal error: RemoteCommunicationKit/rcp.h: No such file or directory
```
**解决方法**：
- 确保已安装HarmonyOS SDK
- 检查SDK路径配置是否正确
- 在CMakeLists.txt中添加正确的include路径

**问题2：链接librcp_c.so失败**
```
undefined reference to `HMS_Rcp_CancelRequest'
```
**解决方法**：
- 在CMakeLists.txt中添加librcp_c.so链接
- 检查库文件是否存在于SDK目录中

**问题3：权限不足错误**
```
运行时错误码201：Permission denied
```
**解决方法**：
- 在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.INTERNET"
      }
    ]
  }
}
```

## 常见问题与解决方法

### Q1：取消请求后，回调函数还会被调用吗？
**原因**：取消操作是异步的，可能有延迟
**解决方法**：
- 在回调函数中检查错误码，如果是取消导致的失败，忽略响应
- 在回调中添加取消状态的检查逻辑
- 建议在取消后立即清理回调对象

### Q2：取消会话后，能否继续使用该会话？
**原因**：取消会话不会关闭会话，但会清除所有请求
**解决方法**：
- 取消会话后可以继续使用该会话发起新请求
- 如果不再需要，调用HMS_Rcp_CloseSession关闭会话
- 区分CancelSession和CloseSession的不同作用

### Q3：如何判断请求是否真正被取消？
**原因**：取消操作可能未立即生效
**解决方法**：
- 检查回调函数中的错误码
- 监听OnVoidCallback回调（如果配置了EventsHandler）
- 设置合理的超时时间等待取消完成

### Q4：取消请求失败怎么办？
**原因**：会话已关闭、权限不足或参数错误
**解决方法**：
- 检查错误码，根据具体原因处理
- 如果会话无效，重新创建会话
- 如果权限不足，检查权限配置
- 可以等待请求自然完成或超时

### Q5：能否取消已经完成的请求？
**原因**：请求已完成，取消操作无效
**解决方法**：
- 取消已完成请求会返回错误码
- 在取消前检查请求状态（如果有状态跟踪）
- 不影响已完成请求的响应数据

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "cancel_request",
  "errorCode": 0,
  "message": "Request canceled successfully",
  "apiUsed": [
    "HMS_Rcp_CancelRequest",
    "HMS_Rcp_CancelSession"
  ],
  "sessionState": "active",
  "requestState": "canceled"
}
```

## 参考文档

- [API开发指南](references/remote-communication-netcancle-c.md)
- [API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/remote-communication-overview)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-preparations)

## 完整示例代码

- [C++完整示例](assets/example_cancel_request.cpp)
- [CMake配置示例](assets/CMakeLists.txt.example)
- [权限配置示例](assets/module.json5.example)

## 测试用例

### 正向测试用例
- [取消单个请求](tests/test_cancel_single_request.cpp)：测试正常取消单个HTTP请求
- [取消会话全部请求](tests/test_cancel_session.cpp)：测试取消会话中的所有请求
- [多次取消操作](tests/test_multiple_cancel.cpp)：测试多次取消不同请求

### 边界测试用例
- [取消NULL请求](tests/test_cancel_null_request.cpp)：测试取消NULL请求对象
- [取消已完成请求](tests/test_cancel_completed_request.cpp)：测试取消已完成的请求
- [取消不存在请求](tests/test_cancel_nonexistent_request.cpp)：测试取消不存在的请求

### 异常测试用例
- [取消已关闭会话的请求](tests/test_cancel_closed_session.cpp)：测试会话已关闭时的取消操作
- [无权限取消](tests/test_cancel_no_permission.cpp)：测试无网络权限时的取消操作
- [并发取消测试](tests/test_concurrent_cancel.cpp)：测试同时取消多个请求的场景