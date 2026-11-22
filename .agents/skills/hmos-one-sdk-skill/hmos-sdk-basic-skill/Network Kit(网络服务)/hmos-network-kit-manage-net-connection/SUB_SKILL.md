---
name: hmos-network-kit-manage-net-connection
description: 查询网络连接状态、获取默认网络、检查网络能力，支持C/C++ Native开发，适用于网络状态监控、网络切换检测场景
---

# 管理网络连接(C/C++)技能

## 功能描述

本技能提供HarmonyOS网络连接管理能力，支持查询默认网络、检查网络连接状态、获取网络能力集、查询网络代理配置等功能。通过NetConnection模块的C API接口，实现在Native层对网络连接信息的管理和监控。

**核心功能**：
- 检查默认数据网络是否激活
- 获取默认激活的数据网络句柄
- 查询网络是否按流量计费
- 获取网络连接属性和能力集
- 查询默认HTTP代理配置
- 获取DNS解析结果
- 查询所有激活的网络列表
- 注册/注销自定义DNS解析器
- 设置/获取PAC代理脚本地址
- 查询网络探测结果和跟踪路由

## 使用场景

### 触发词
- "检查网络连接状态"
- "获取默认网络"
- "查询网络能力"
- "网络连接管理"
- "获取网络代理"
- "DNS解析"
- "网络计费查询"

### 能做
- 查询设备是否有网络连接
- 获取当前激活的默认网络信息
- 检查网络是否按流量计费
- 查询网络的连接属性（如链路信息）
- 获取网络的能力集（如是否支持某些网络特性）
- 查询系统默认的HTTP代理配置
- 通过指定网络ID进行DNS解析
- 获取所有处于连接状态的网络列表
- 注册自定义DNS解析器
- 设置和获取PAC代理脚本地址
- 查询网络探测结果（丢包率、RTT等）
- 查询网络跟踪路由信息

### 绝不做
- 不处理网络请求的发送和接收（应使用HTTP客户端或Socket API）
- 不进行网络认证和加密操作
- 不处理应用层协议（HTTP/HTTPS/FTP等）
- 不管理WiFi或移动数据的开关
- 不处理网络连接的建立和断开事件（应使用回调注册接口）

### 补充
- 本技能仅适用于Native C/C++开发场景
- 需要申请相应权限：ohos.permission.GET_NETWORK_INFO、ohos.permission.INTERNET等
- 部分API从特定版本开始支持，需注意版本兼容性
- 避免在主线程调用网络探测等耗时操作

## 调用规范和规则

### 输入约束
- 参数有效性：所有指针参数必须非NULL（除非API明确说明可以传NULL）
- 内存管理：传入的结构体需要预先分配内存
- 字符串长度：URL、主机名等字符串参数不超过1024字节
- 网络ID：有效的网络ID（通过GetDefaultNet或GetAllNets获取）

### 执行约束
- 最大耗时：单个API调用不超过5秒
- 调用频率：避免短时间内频繁调用（建议间隔>100ms）
- 线程安全：可以在多线程环境中调用，但需注意回调函数的线程安全
- 资源释放：使用完DNS结果后必须调用OH_NetConn_FreeDnsResult释放内存

### 内容约束
- 禁止生成：网络数据收发代码、应用层协议处理代码
- 禁止使用高危函数：避免使用已废弃的API（如OHOS_NetConn_RegisterDnsResolver）
- 禁止操作：不要在未申请权限的情况下调用需要权限的API

### 降级约束
- 网络服务未启动：返回错误码2100002，提示用户检查网络服务状态
- 权限不足：返回错误码201，提示用户申请相应权限
- 参数错误：返回错误码401，检查参数有效性
- 内部错误：返回错误码2100003，记录日志并提示用户重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 确认已创建Native C++工程
2. 确认已在CMakeLists.txt中添加依赖库：libnet_connection.so
3. 确认已添加必要的头文件引用
4. 确认已申请必要的权限（ohos.permission.GET_NETWORK_INFO等）

**权限配置**：
在module.json5中添加权限声明：
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

**头文件引入**：
```c
#include "network/netmanager/net_connection.h"
#include "network/netmanager/net_connection_type.h"
#include "napi/native_api.h"
```

### 步骤2：检查网络连接状态

**示例代码**：
```c
#include "network/netmanager/net_connection.h"
#include <stdio.h>

int32_t CheckNetworkConnection() {
    int32_t hasDefaultNet = 0;
    int32_t result = OH_NetConn_HasDefaultNet(&hasDefaultNet);
    
    if (result != 0) {
        printf("Error: Failed to check default network, error code: %d\n", result);
        return result;
    }
    
    if (hasDefaultNet) {
        printf("Network is connected\n");
    } else {
        printf("Network is not connected\n");
    }
    
    return result;
}
```

### 步骤3：获取默认网络信息

**示例代码**：
```c
#include "network/netmanager/net_connection.h"
#include <stdio.h>

int32_t GetDefaultNetworkInfo(int32_t *netId) {
    NetConn_NetHandle netHandle;
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    
    if (result != 0) {
        printf("Error: Failed to get default network, error code: %d\n", result);
        return result;
    }
    
    *netId = netHandle.netId;
    printf("Default network ID: %d\n", *netId);
    
    return result;
}
```

### 步骤4：查询网络能力集

**示例代码**：
```c
#include "network/netmanager/net_connection.h"
#include <stdio.h>

int32_t GetNetworkCapabilities(NetConn_NetHandle *netHandle) {
    NetConn_NetCapabilities netCapabilities;
    int32_t result = OH_NetConn_GetNetCapabilities(netHandle, &netCapabilities);
    
    if (result != 0) {
        printf("Error: Failed to get network capabilities, error code: %d\n", result);
        return result;
    }
    
    printf("Network capabilities: %u\n", netCapabilities.linkUpBandwidthKbps);
    printf("Link down bandwidth: %u Kbps\n", netCapabilities.linkDownBandwidthKbps);
    
    return result;
}
```

### 步骤5：查询网络代理配置

**示例代码**：
```c
#include "network/netmanager/net_connection.h"
#include <stdio.h>

int32_t GetDefaultHttpProxy() {
    NetConn_HttpProxy httpProxy;
    int32_t result = OH_NetConn_GetDefaultHttpProxy(&httpProxy);
    
    if (result != 0) {
        printf("Error: Failed to get default HTTP proxy, error code: %d\n", result);
        return result;
    }
    
    if (httpProxy.host != NULL) {
        printf("Proxy host: %s\n", httpProxy.host);
        printf("Proxy port: %d\n", httpProxy.port);
    } else {
        printf("No proxy configured\n");
    }
    
    return result;
}
```

### 步骤6：错误处理

**错误处理代码**：
```c
#include "network/netmanager/net_connection.h"
#include <stdio.h>

const char* GetErrorMessage(int32_t errorCode) {
    switch (errorCode) {
        case 0:
            return "Success";
        case 201:
            return "Permission denied: Missing required permission";
        case 401:
            return "Parameter error: Invalid parameter";
        case 2100002:
            return "Operation failed: Cannot connect to service";
        case 2100003:
            return "Internal error: System internal error";
        default:
            return "Unknown error";
    }
}

int32_t HandleNetworkOperation(int32_t result) {
    if (result != 0) {
        printf("Network operation failed: %s (code: %d)\n", 
               GetErrorMessage(result), result);
        
        switch (result) {
            case 201:
                printf("Please add required permissions to module.json5\n");
                break;
            case 401:
                printf("Please check parameter validity\n");
                break;
            case 2100002:
                printf("Please check if network service is running\n");
                break;
            case 2100003:
                printf("Please retry or check system logs\n");
                break;
        }
    }
    return result;
}
```

### 步骤7：NAPI封装（用于ArkTS调用）

**封装示例**：
```c
#include "napi/native_api.h"
#include "network/netmanager/net_connection.h"

static napi_value GetDefaultNet(napi_env env, napi_callback_info info) {
    size_t argc = 1;
    napi_value args[1] = {nullptr};
    napi_get_cb_info(env, info, &argc, args, nullptr, nullptr);
    
    int32_t param;
    napi_get_value_int32(env, args[0], &param);
    
    NetConn_NetHandle netHandle;
    int32_t result;
    
    if (param == 0) {
        result = OH_NetConn_GetDefaultNet(NULL);
    } else {
        result = OH_NetConn_GetDefaultNet(&netHandle);
    }
    
    napi_value return_value;
    napi_create_int32(env, result, &return_value);
    return return_value;
}

static napi_value GetNetId(napi_env env, napi_callback_info info) {
    NetConn_NetHandle netHandle;
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    
    napi_value return_value;
    if (result == 0) {
        napi_create_int32(env, netHandle.netId, &return_value);
    } else {
        napi_create_int32(env, -1, &return_value);
    }
    return return_value;
}

EXTERN_C_START
static napi_value Init(napi_env env, napi_value exports) {
    napi_property_descriptor desc[] = {
        {"GetDefaultNet", nullptr, GetDefaultNet, nullptr, nullptr, nullptr, napi_default, nullptr},
        {"GetNetId", nullptr, GetNetId, nullptr, nullptr, nullptr, napi_default, nullptr},
    };
    napi_define_properties(env, exports, sizeof(desc) / sizeof(desc[0]), desc);
    return exports;
}
EXTERN_C_END

static napi_module demoModule = {
    .nm_version = 1,
    .nm_flags = 0,
    .nm_filename = nullptr,
    .nm_register_func = Init,
    .nm_modname = "entry",
    .nm_priv = ((void *)0),
    .reserved = {0},
};

extern "C" __attribute__((constructor)) void RegisterEntryModule(void) { 
    napi_module_register(&demoModule); 
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 操作成功 | 无需处理 |
| 201 | 缺少权限 | 在module.json5中添加相应权限声明 |
| 401 | 参数错误 | 检查参数是否为NULL，参数类型是否正确 |
| 2100002 | 无法连接到服务 | 检查网络管理服务是否正常运行 |
| 2100003 | 内部错误 | 记录日志并重试，或联系系统开发者 |
| 2101007 | 回调不存在 | 注销回调前确认回调ID有效 |
| 2101008 | 回调已注册 | 避免重复注册同一回调 |
| 2101022 | 请求数超出最大值 | 减少并发请求数量 |

## 编译和修复问题

### 依赖声明

**CMakeLists.txt配置**：
```cmake
cmake_minimum_required(VERSION 3.4.1)
project(netmanager_demo)

find_package(
    OHOS::Native
    REQUIRED
)

add_library(entry SHARED
    hello.cpp
)

target_link_libraries(entry
    PUBLIC
        libace_napi.z.so
        libnet_connection.so
)

target_include_directories(entry PUBLIC
    ${CMAKE_CURRENT_SOURCE_DIR}
)
```

### 环境要求
- HarmonyOS SDK版本：API 11及以上
- 开发环境：DevEco Studio 3.1及以上
- NDK版本：r12及以上
- 目标设备：支持HarmonyOS API 11+的设备

### 常见编译问题

**问题1：找不到头文件**
```
fatal error: network/netmanager/net_connection.h: No such file or directory
```
**解决方法**：确保在CMakeLists.txt中正确配置了包含路径，并检查HarmonyOS SDK是否正确安装。

**问题2：链接错误**
```
undefined reference to `OH_NetConn_GetDefaultNet'
```
**解决方法**：在CMakeLists.txt的target_link_libraries中添加libnet_connection.so依赖。

**问题3：权限错误**
```
Error: 201 - Permission denied
```
**解决方法**：在module.json5中添加相应权限：
```json
{
  "name": "ohos.permission.GET_NETWORK_INFO"
}
```

**问题4：运行时崩溃**
```
SIGSEGV: segmentation fault
```
**解决方法**：检查传入的指针参数是否有效，避免传入NULL指针（除非API明确支持）。

## 常见问题与解决方法

### Q1：调用API返回201错误
**原因**：缺少必要的权限声明
**解决方法**：
- 在module.json5中添加ohos.permission.GET_NETWORK_INFO权限
- 对于DNS相关API，添加ohos.permission.INTERNET权限
- 对于PAC脚本设置，添加ohos.permission.SET_PAC_URL权限

### Q2：获取网络信息返回401错误
**原因**：参数错误，通常是指针参数为NULL或无效
**解决方法**：
- 确保所有输出参数的指针非NULL
- 确保传入的结构体已正确初始化
- 检查参数类型是否匹配API要求

### Q3：无法获取默认网络
**原因**：设备未连接网络或网络服务未启动
**解决方法**：
- 先调用OH_NetConn_HasDefaultNet检查是否有默认网络
- 检查设备的网络连接状态
- 确认网络管理服务正常运行

### Q4：DNS解析失败
**原因**：网络未连接或DNS服务器不可达
**解决方法**：
- 检查网络连接状态
- 确认DNS服务器配置正确
- 使用OH_NetConn_GetAddrInfo时确保netId参数有效（传0使用默认网络）

### Q5：内存泄漏问题
**原因**：未正确释放DNS结果内存
**解决方法**：
- 使用OH_NetConn_GetAddrInfo后，必须调用OH_NetConn_FreeDnsResult释放内存
- 避免重复释放同一块内存

### Q6：多线程访问冲突
**原因**：多个线程同时访问网络管理API
**解决方法**：
- 为网络管理操作添加互斥锁保护
- 确保回调函数的线程安全性
- 避免在回调函数中执行耗时操作

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "networkAvailable": true,
  "defaultNetId": 123,
  "networkCapabilities": {
    "linkUpBandwidthKbps": 10000,
    "linkDownBandwidthKbps": 50000
  },
  "proxyConfigured": false,
  "apiUsed": [
    "OH_NetConn_HasDefaultNet",
    "OH_NetConn_GetDefaultNet",
    "OH_NetConn_GetNetCapabilities",
    "OH_NetConn_GetDefaultHttpProxy"
  ]
}
```

## 参考文档

- [API开发指南](references/native-netmanager-guidelines.md)
- [API参考说明](references/capi-net-connection-h.md)
- [错误码参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/errorcode-net-connection)
- [NetConnection模块说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/capi-netconnection)

## 完整示例代码

- [C++示例：网络连接查询](assets/example_net_connection.cpp)
- [C++示例：网络能力查询](assets/example_network_capabilities.cpp)
- [NAPI封装示例](assets/example_napi_wrapper.cpp)
- [CMakeLists.txt配置示例](assets/CMakeLists.txt)

## 测试用例

### 正向测试用例
- [测试：检查网络连接状态](tests/test_has_default_net.cpp)：验证OH_NetConn_HasDefaultNet正确返回网络状态
- [测试：获取默认网络](tests/test_get_default_net.cpp)：验证OH_NetConn_GetDefaultNet成功获取网络ID
- [测试：查询网络能力](tests/test_get_capabilities.cpp)：验证OH_NetConn_GetNetCapabilities返回有效能力集
- [测试：获取代理配置](tests/test_get_http_proxy.cpp)：验证OH_NetConn_GetDefaultHttpProxy返回代理信息

### 边界测试用例
- [测试：无网络连接时调用API](tests/test_no_network.cpp)：验证无网络时的错误处理
- [测试：DNS解析大量域名](tests/test_dns_resolve_batch.cpp)：验证批量DNS解析的性能
- [测试：网络切换场景](tests/test_network_switch.cpp)：验证网络切换时的状态更新

### 异常测试用例
- [测试：NULL参数](tests/test_null_parameter.cpp)：验证传入NULL参数的错误处理
- [测试：权限不足](tests/test_no_permission.cpp)：验证缺少权限时的错误码
- [测试：网络服务未启动](tests/test_service_unavailable.cpp)：验证服务不可用时的降级处理
- [测试：重复注册回调](tests/test_duplicate_callback.cpp)：验证重复注册回调的错误处理