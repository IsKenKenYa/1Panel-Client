---
name: hmos-remote-communication-kit-http-request-c
description: 使用C++发送HTTP请求，支持GET/POST/PUT/DELETE/HEAD方法，支持同步和异步请求，最大支持200MB文件上传，适用于网络通信、数据传输、API调用场景
---

# 发送网络请求（C++）技能

## 功能描述

本技能提供使用C++通过Remote Communication Kit发送HTTP请求的能力，支持多种HTTP方法（GET、POST、PUT、DELETE、HEAD等），支持同步和异步两种请求模式，可配置请求头、请求体、超时时间、自动重定向等参数，适用于网络数据获取、文件上传下载、API接口调用等场景。

**核心能力**：
- 发送同步HTTP请求（HMS_Rcp_FetchSync）
- 发送异步HTTP请求（HMS_Rcp_Fetch）
- 支持GET/POST/PUT/DELETE/HEAD等多种HTTP方法
- 支持请求配置（超时、重定向、请求头等）
- 支持请求内容设置（字符串、表单、文件等）
- 提供完整的错误处理和资源清理机制

**起始版本**：5.0.0(12)，从5.1.1(19)开始支持TV设备，从6.1.0(23)开始支持Car设备

## 使用场景

### 触发词
- "发送HTTP请求（C++）" - 使用C++发送HTTP请求
- "C++网络请求" - C++语言的HTTP请求功能
- "RCP C API" - Remote Communication Kit C API
- "fetchsync" - 同步HTTP请求
- "fetch异步" - 异步HTTP请求
- "HTTP GET请求（C++）" - C++ GET请求
- "HTTP POST请求（C++）" - C++ POST请求
- "HTTP PUT请求（C++）" - C++ PUT请求
- "HTTP DELETE请求（C++）" - C++ DELETE请求
- "HTTP HEAD请求（C++）" - C++ HEAD请求

### 能做
- 发送同步HTTP请求并获取响应
- 发送异步HTTP请求并处理回调
- 配置请求参数（URL、方法、请求头、请求体）
- 设置请求超时时间、自动重定向
- 处理响应状态码、响应头、响应内容
- 发送字符串内容、表单数据
- 实现完整的资源管理和错误处理

### 绝不做
- 不发送超过200MB的文件内容
- 不处理WebSocket通信（需要使用其他技能）
- 不实现文件下载到本地（需要使用文件下载技能）
- 不处理FTP协议（仅支持HTTP/HTTPS）
- 不实现HTTP服务器功能（仅作为客户端）
- 不处理跨域CORS问题（服务端问题）

### 补充
- 支持Phone、2in1、Tablet、Wearable设备
- 从5.1.1(19)开始支持TV设备
- 从6.1.0(23)开始支持Car设备
- 需要配置ohos.permission.INTERNET和ohos.permission.GET_NETWORK_INFO权限
- C API需要在CMakeLists.txt中链接librcp_c.so库

## 调用规范和规则

### 输入约束
- URL长度：最大2048字符
- 请求头数量：最多100个
- 请求内容大小：最大200MB
- 单个请求头值长度：最大8192字符
- 请求ID长度：最大32字符（RCP_MAX_REQUEST_ID_LEN）
- 内容类型长度：最大64字符（RCP_MAX_CONTENT_TYPE_LEN）
- 文件名长度：最大128字符（RCP_MAX_FILENAME_LEN）

### 执行约束
- 最大请求耗时：可配置，默认无限制（建议设置timeout）
- 最大并发请求数：建议不超过10个
- API调用频次：无硬性限制，建议合理控制避免服务器拒绝
- 资源清理：必须在请求完成后清理request、response、session

### 内容约束
- 禁止发送违法、违规内容
- 禁止硬编码敏感信息（密码、密钥等）
- 禁止使用eval、exec等高危函数
- 禁止绕过HTTPS安全检查（除非配置明文传输）
- 禁止无限循环请求

### 降级约束
- 网络失败：返回错误码，建议实现重试机制
- 超时失败：返回错误码，建议调整超时时间或优化网络
- 服务器错误：返回状态码，建议根据状态码处理
- 内存不足：释放资源后重试或降级处理
- DNS解析失败：检查域名配置或使用备用地址

## 调用流程和步骤

### 步骤1：开发准备

**前置校验**：
1. 检查是否已配置ohos.permission.INTERNET权限
2. 检查是否已配置ohos.permission.GET_NETWORK_INFO权限
3. 检查CMakeLists.txt是否已配置librcp_c.so链接
4. 检查是否已包含RemoteCommunicationKit/rcp.h头文件

**权限配置**：
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

**CMake配置**：
```cmake
target_include_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/include)
target_link_directories(entry PUBLIC ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos)
target_link_libraries(entry PUBLIC librcp_c.so)
```

### 步骤2：导入头文件

```cpp
#include "RemoteCommunicationKit/rcp.h"
#include <stdio.h>
#include <cstring>
#include <cstdlib>
```

### 步骤3：创建Request对象

**同步请求示例**：
```cpp
const char *kHttpServerAddress = "https://www.example.com";
Rcp_Request *request = HMS_Rcp_CreateRequest(kHttpServerAddress);
if (request == NULL) {
    printf("Failed to create request\n");
    return -1;
}
```

**配置请求参数**：
```cpp
request->method = RCP_METHOD_GET;  // 或 RCP_METHOD_POST/PUT/DELETE/HEAD

// 配置超时和重定向
Rcp_Configuration config;
memset(&config, 0, sizeof(Rcp_Configuration));
config.transferConfiguration.autoRedirect = true;
config.transferConfiguration.timeout.transferMs = 10000;  // 10秒超时
config.transferConfiguration.timeout.connectMs = 10000;   // 10秒连接超时
request->configuration = &config;
```

### 步骤4：创建Session

```cpp
uint32_t errCode = 0;
Rcp_Session *session = HMS_Rcp_CreateSession(NULL, &errCode);
if (session == NULL || errCode != 0) {
    printf("Failed to create session, errCode: %u\n", errCode);
    HMS_Rcp_DestroyRequest(request);
    return -1;
}
```

### 步骤5：发送请求（同步模式）

**使用HMS_Rcp_FetchSync**：
```cpp
Rcp_Response *response = HMS_Rcp_FetchSync(session, request, &errCode);
if (response != NULL) {
    printf("Response status: %d\n", response->statusCode);
    // 处理响应内容
    if (response->content != NULL && response->content->data.contentStr.buffer != NULL) {
        printf("Response content: %s\n", response->content->data.contentStr.buffer);
    }
} else {
    printf("Fetch failed, errCode: %u\n", errCode);
}
```

### 步骤6：发送请求（异步模式）

**定义回调函数**：
```cpp
void ResponseCallback(void *usrCtx, Rcp_Response *response, uint32_t errCode) {
    (void)usrCtx;
    if (response != NULL) {
        printf("Response status: %d\n", response->statusCode);
        if (response->content != NULL && response->content->data.contentStr.buffer != NULL) {
            printf("Response content: %s\n", response->content->data.contentStr.buffer);
        }
        response->destroyResponse(response);
    } else {
        printf("Fetch failed, errCode: %u\n", errCode);
    }
}
```

**发送异步请求**：
```cpp
Rcp_ResponseCallbackObject responseCallback = {ResponseCallback, NULL};
errCode = HMS_Rcp_Fetch(session, request, &responseCallback);
if (errCode != 0) {
    printf("Failed to fetch, errCode: %u\n", errCode);
}
```

### 步骤7：POST请求示例

**设置请求内容**：
```cpp
const char *content = "{\"key\":\"value\"}";
request->method = RCP_METHOD_POST;
request->content = (Rcp_RequestContent *)calloc(1, sizeof(Rcp_RequestContent));
request->content->type = RCP_CONTENT_TYPE_STRING;
request->content->data.contentStr.buffer = content;
request->content->data.contentStr.length = strlen(content);
```

### 步骤8：错误处理

```cpp
if (response == NULL) {
    switch (errCode) {
        case 1007900001:
            printf("Session not found\n");
            break;
        case 1007900002:
            printf("Request not found\n");
            break;
        case 1007900003:
            printf("URL format error\n");
            break;
        case 1007900004:
            printf("Network error\n");
            break;
        default:
            printf("Unknown error: %u\n", errCode);
    }
}
```

### 步骤9：资源清理

**必须按顺序清理资源**：
```cpp
// 1. 清理request content（如果有）
if (request->content != NULL) {
    free(request->content);
}

// 2. 清理request
HMS_Rcp_DestroyRequest(request);

// 3. 清理response（如果有）
if (response != NULL) {
    response->destroyResponse(response);
}

// 4. 取消session中可能还在执行的请求
errCode = HMS_Rcp_CancelSession(session);

// 5. 关闭session
errCode = HMS_Rcp_CloseSession(&session);
if (errCode != 0) {
    printf("Failed to close session, errCode: %u\n", errCode);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 1007900001 | Session未找到或已关闭 | 检查session是否已创建，避免重复关闭 |
| 1007900002 | Request未找到或已销毁 | 检查request是否已创建，避免重复销毁 |
| 1007900003 | URL格式错误 | 检查URL格式，确保包含协议（http://或https://） |
| 1007900004 | 网络错误 | 检查网络连接，检查权限配置 |
| 1007900005 | DNS解析失败 | 检查域名是否正确，检查DNS配置 |
| 1007900006 | 连接超时 | 增加timeout.connectMs配置 |
| 1007900007 | 传输超时 | 增加timeout.transferMs配置 |
| 1007900008 | SSL证书验证失败 | 检查证书配置，或配置跳过验证（不推荐） |
| 1007900009 | 内存分配失败 | 检查内存使用，释放不必要的资源 |
| 1007900010 | 参数错误 | 检查API参数是否正确设置 |
| 1007900011 | HTTP协议错误 | 检查HTTP方法、请求头是否符合规范 |
| 1007900012 | 服务器返回错误状态码 | 检查响应statusCode，根据状态码处理 |
| 1007900201 | HTTP明文传输被拦截 | 配置network_config.json允许明文传输 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(entry)

target_include_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/include
)

target_link_directories(entry PUBLIC 
    ${HMOS_SDK_NATIVE}/sysroot/usr/lib/aarch64-linux-ohos
)

target_link_libraries(entry PUBLIC 
    librcp_c.so
    # 其他依赖库
)
```

### 环境要求
- HarmonyOS SDK：5.0.0(12)及以上
- Native SDK路径：HMOS_SDK_NATIVE环境变量已配置
- 编译工具：CMake 3.4.1及以上
- 目标架构：aarch64-linux-ohos

### 常见编译问题

**问题1：找不到rcp.h头文件**
```
fatal error: RemoteCommunicationKit/rcp.h: No such file or directory
```
**解决方法**：
- 检查HMOS_SDK_NATIVE环境变量是否配置
- 确认target_include_directories路径正确
- 检查SDK版本是否为5.0.0(12)及以上

**问题2：链接librcp_c.so失败**
```
cannot find -lrcp_c
```
**解决方法**：
- 检查target_link_directories路径正确
- 确认librcp_c.so存在于SDK目录
- 检查架构是否匹配（aarch64-linux-ohos）

**问题3：权限未配置导致运行失败**
```
Application requires permission ohos.permission.INTERNET
```
**解决方法**：
- 在module.json5中添加权限声明
- 检查requestPermissions配置格式正确

**问题4：HTTP明文传输被拦截**
```
Error code: 1007900201
```
**解决方法**：
- 配置network_config.json允许HTTP明文
- 或改用HTTPS协议

## 常见问题与解决方法

### Q1：请求超时如何处理？
**原因**：网络延迟或服务器响应慢，timeout配置过小
**解决方法**：
- 增加timeout.transferMs和timeout.connectMs值
- 检查网络连接质量
- 考虑使用异步请求避免阻塞

### Q2：如何处理大文件上传？
**原因**：请求内容超过200MB限制
**解决方法**：
- 分片上传：将文件分割为多个部分分别上传
- 使用表单文件上传方式
- 考虑压缩文件大小

### Q3：异步请求回调未执行？
**原因**：请求已取消或session已关闭，回调时机问题
**解决方法**：
- 检查session是否在回调前关闭
- 使用HMS_Rcp_CancelSession前等待回调完成
- 增加等待时间（如usleep）

### Q4：如何设置请求头？
**原因**：未配置请求头结构
**解决方法**：
```cpp
Rcp_HeaderEntry headerEntry;
headerEntry.key = "Content-Type";
headerEntry.value.type = RCP_HEADER_VALUE_TYPE_STRING;
headerEntry.value.data.valueStr = "application/json";
// 将headerEntry添加到request->headers
```

### Q5：响应内容如何正确读取？
**原因**：未正确处理响应内容结构
**解决方法**：
- 检查response->content不为NULL
- 根据content->type判断内容类型
- 读取content->data.contentStr.buffer和length

### Q6：如何实现请求重试？
**原因**：网络不稳定导致请求失败
**解决方法**：
```cpp
int maxRetry = 3;
for (int i = 0; i < maxRetry; i++) {
    Rcp_Response *response = HMS_Rcp_FetchSync(session, request, &errCode);
    if (response != NULL && response->statusCode == 200) {
        break;  // 成功
    }
    // 清理并重试
    if (response != NULL) {
        response->destroyResponse(response);
    }
    usleep(1000000);  // 等待1秒
}
```

### Q7：如何处理服务器返回的错误状态码？
**原因**：服务器返回400/500等错误状态码
**解决方法**：
```cpp
if (response != NULL) {
    switch (response->statusCode) {
        case 200:
            printf("Success\n");
            break;
        case 400:
            printf("Bad Request: check request parameters\n");
            break;
        case 401:
            printf("Unauthorized: check authentication\n");
            break;
        case 404:
            printf("Not Found: check URL\n");
            break;
        case 500:
            printf("Internal Server Error: server issue\n");
            break;
        default:
            printf("Status code: %d\n", response->statusCode);
    }
}
```

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "statusCode": 200,
  "contentLength": 1234,
  "headers": {
    "Content-Type": "application/json",
    "Server": "ExampleServer"
  },
  "requestTime": 1234,
  "apiUsed": [
    "HMS_Rcp_CreateRequest",
    "HMS_Rcp_CreateSession",
    "HMS_Rcp_FetchSync",
    "HMS_Rcp_DestroyRequest",
    "HMS_Rcp_CloseSession"
  ]
}
```

## 参考文档

- [API开发指南](references/remote-communication-netsend-c.md)
- [API参考说明](references/remote-communication-overview.md)
- [开发准备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/remote-communication-preparations)

## 完整示例代码

- [同步GET请求示例](assets/example_sync_get.cpp)
- [异步GET请求示例](assets/example_async_get.cpp)
- [POST请求示例](assets/example_post.cpp)
- [PUT请求示例](assets/example_put.cpp)
- [完整配置示例](assets/example_full.cpp)

## 测试用例

### 正向测试用例
- [测试同步GET请求](tests/test_sync_get.cpp)：验证同步GET请求成功返回
- [测试异步GET请求](tests/test_async_get.cpp)：验证异步回调正确执行
- [测试POST请求](tests/test_post.cpp)：验证POST请求内容正确发送
- [测试请求配置](tests/test_configuration.cpp)：验证超时、重定向配置生效

### 边界测试用例
- [测试最大URL长度](tests/test_max_url.cpp)：验证URL长度限制
- [测试最大请求内容](tests/test_max_content.cpp)：验证请求内容大小限制
- [测试超时边界](tests/test_timeout.cpp)：验证超时配置边界值

### 异常测试用例
- [测试无效URL](tests/test_invalid_url.cpp)：验证URL格式错误处理
- [测试网络失败](tests/test_network_fail.cpp)：验证网络错误处理
- [测试超时失败](tests/test_timeout_fail.cpp)：验证超时错误处理
- [测试权限缺失](tests/test_no_permission.cpp)：验证权限缺失错误处理
- [测试资源清理](tests/test_resource_cleanup.cpp)：验证资源正确清理