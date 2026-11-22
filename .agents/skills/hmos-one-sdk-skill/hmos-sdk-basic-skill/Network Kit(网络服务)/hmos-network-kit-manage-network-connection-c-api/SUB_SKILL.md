---
name: hmos-network-kit-manage-network-connection-c-api
description: 管理网络连接状态查询,支持获取默认网络、查询网络能力集、获取连接信息等,C API实现,适用于Native层网络管理场景
---

# 管理网络连接(C/C++)技能

## 功能描述

本技能实现HarmonyOS网络连接管理功能,通过NetConnection模块的C API提供常用网络信息查询能力。包括查询默认激活网络、获取网络连接属性、查询网络能力集、获取HTTP代理配置、DNS解析等功能。需要创建Native C++工程,通过NAPI封装后供ArkTS层调用,适用于需要精确控制网络状态的Native应用场景。

## 使用场景

### 触发词
- "管理网络连接"
- "查询网络状态"
- "获取默认网络"
- "Native网络管理"
- "C API网络查询"
- "获取网络能力"
- "查询网络连接属性"

### 能做
- 查询设备是否有默认激活网络
- 获取默认激活的数据网络ID
- 查询网络连接属性(链路信息)
- 查询网络能力集
- 获取默认HTTP代理配置
- 通过netId进行DNS解析
- 查询所有激活的数据网络列表
- 注册/注销自定义DNS解析器
- 设置/获取PAC脚本地址
- 查询网络探测结果和跟踪路由

### 绝不做
- 不执行网络连接建立操作
- 不修改网络配置(除代理配置外)
- 不处理非Native层的网络管理
- 不执行网络数据传输操作
- 不替代ArkTS层的网络管理接口

### 补充
- 需要申请ohos.permission.GET_NETWORK_INFO权限(查询网络信息)
- 部分接口需要ohos.permission.INTERNET权限(DNS相关)
- 需要通过NAPI封装才能在ArkTS层调用
- 仅适用于API version 11及以上
- 探测和跟踪路由接口(API 20)需要额外权限

## 调用规范和规则

### 输入约束
- API调用前必须初始化NetConn_NetHandle结构体
- DNS查询host参数必须是有效的域名或IP地址
- 网络探测destination必须是有效的域名或IP
- 探测持续时间duration最大不超过系统限制
- 所有指针参数必须有效且非NULL(除非明确允许)
- 字符长度:host名不超过255字符,serv不超过32字符

### 执行约束
- 单次API调用最大耗时:5秒(网络探测除外)
- 最大迭代次数:1次(不重试,直接返回结果)
- DNS解析结果必须手动释放(调用OH_NetConn_FreeDnsResult)
- 回调注册上限:系统默认限制(参考错误码2101022)
- 网络探测避免在主流程调用,防止UI卡顿
- API调用频次:无限制,但需遵循系统调度规则

### 内容约束
- 禁止生成:网络连接建立、数据传输相关代码
- 禁止使用高危函数:eval、exec、system等
- 禁止操作:修改系统网络配置(除允许的代理配置)
- 必须包含权限检查代码
- 必须包含参数有效性校验
- 必须包含错误码处理逻辑

### 降级约束
- 网络服务不可达(2100002):提示用户检查网络状态并稍后重试
- 缺少权限(201):提示用户申请相应权限并检查权限配置
- 参数错误(401):提示用户检查参数有效性并修正
- 内部错误(2100003):记录日志并提示用户联系技术支持
- DNS解析失败:尝试使用备用DNS或提示用户检查网络连接
- 网络探测超时:减少探测次数或延长超时时间

## 调用流程和步骤

### 步骤1:准备阶段

**前置校验**:
1. 检查是否有默认激活网络(调用OH_NetConn_HasDefaultNet)
2. 验证权限配置(ohos.permission.GET_NETWORK_INFO)
3. 初始化必要的结构体(NetConn_NetHandle等)
4. 准备错误码处理变量

**参数准备**:
```c
// C示例
#include "network/netmanager/net_connection.h"
#include "network/netmanager/net_connection_type.h"
#include "napi/native_api.h"

// 初始化网络句柄
NetConn_NetHandle netHandle;
int32_t result = 0;
int32_t hasDefaultNet = 0;

// 检查默认网络
result = OH_NetConn_HasDefaultNet(&hasDefaultNet);
if (result != NETMANAGER_SUCCESS) {
    // 处理错误
    return result;
}

if (hasDefaultNet == 0) {
    // 无默认网络,处理降级场景
    return NETMANAGER_ERR_NO_DEFAULT_NET;
}
```

### 步骤2:调用API

**示例代码-获取默认网络**:
```c
// 获取默认网络的函数(NAPI封装)
static napi_value GetDefaultNet(napi_env env, napi_callback_info info)
{
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
    
    napi_value returnValue;
    napi_create_int32(env, result, &returnValue);
    return returnValue;
}

// 获取默认网络ID
static napi_value NetId(napi_env env, napi_callback_info info)
{
    int32_t defaultNetId;
    NetConn_NetHandle netHandle;
    
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    if (result != NETMANAGER_SUCCESS) {
        // 返回错误码
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    defaultNetId = netHandle.netId;
    
    napi_value netIdValue;
    napi_create_int32(env, defaultNetId, &netIdValue);
    return netIdValue;
}
```

**示例代码-查询网络能力**:
```c
// 查询网络能力集
static napi_value GetNetCapabilities(napi_env env, napi_callback_info info)
{
    NetConn_NetHandle netHandle;
    NetConn_NetCapabilities netCapabilities;
    
    // 获取默认网络
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    if (result != NETMANAGER_SUCCESS) {
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    // 查询网络能力
    result = OH_NetConn_GetNetCapabilities(&netHandle, &netCapabilities);
    if (result != NETMANAGER_SUCCESS) {
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    // 返回能力信息(需要转换为napi_value)
    napi_value capabilitiesObj;
    napi_create_object(env, &capabilitiesObj);
    
    // 设置属性...
    // (具体属性根据NetConn_NetCapabilities结构体定义)
    
    return capabilitiesObj;
}
```

**示例代码-查询连接属性**:
```c
// 查询网络连接属性
static napi_value GetConnectionProperties(napi_env env, napi_callback_info info)
{
    NetConn_NetHandle netHandle;
    NetConn_ConnectionProperties prop;
    
    int32_t result = OH_NetConn_GetDefaultNet(&netHandle);
    if (result != NETMANAGER_SUCCESS) {
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    result = OH_NetConn_GetConnectionProperties(&netHandle, &prop);
    if (result != NETMANAGER_SUCCESS) {
        napi_value errorValue;
        napi_create_int32(env, result, &errorValue);
        return errorValue;
    }
    
    // 返回连接属性
    napi_value propertiesObj;
    napi_create_object(env, &propertiesObj);
    
    // 设置属性...
    // (包含linkAddresses, linkRoutes, dnsAddresses等)
    
    return propertiesObj;
}
```

### 步骤3:错误处理

```c
// 错误处理代码(通用)
int32_t handleNetworkError(int32_t errorCode) {
    switch (errorCode) {
        case NETMANAGER_SUCCESS:
            printf("操作成功\n");
            break;
        case NETMANAGER_ERR_PERMISSION_DENIED:
            printf("缺少权限:需要ohos.permission.GET_NETWORK_INFO\n");
            break;
        case NETMANAGER_ERR_PARAMETER_ERROR:
            printf("参数错误:检查参数有效性\n");
            break;
        case NETMANAGER_ERR_OPERATION_FAILED:
            printf("无法连接到网络服务\n");
            break;
        case NETMANAGER_ERR_INTERNAL_ERROR:
            printf("内部系统错误\n");
            break;
        default:
            printf("未知错误:%d\n", errorCode);
            break;
    }
    return errorCode;
}

// ArkTS层错误处理示例
enum ReturnCode {
    SUCCESS = 0,
    MISSING_PERMISSION = 201,
    PARAMETER_ERROR = 401,
    OPERATION_FAILED = 2100002,
    INTERNAL_ERROR = 2100003
}

// 在ArkTS中处理返回码
function handleResult(codeNumber: number): void {
    switch (codeNumber) {
        case ReturnCode.SUCCESS:
            hilog.info(0x0000, 'testTag', '操作成功');
            break;
        case ReturnCode.MISSING_PERMISSION:
            hilog.info(0x0000, 'testTag', '缺少权限,请检查权限配置');
            break;
        case ReturnCode.PARAMETER_ERROR:
            hilog.info(0x0000, 'testTag', '参数错误,请检查参数有效性');
            break;
        case ReturnCode.OPERATION_FAILED:
            hilog.info(0x0000, 'testTag', '无法连接服务,请检查网络');
            break;
        case ReturnCode.INTERNAL_ERROR:
            hilog.info(0x0000, 'testTag', '内部错误,请联系技术支持');
            break;
        default:
            hilog.info(0x0000, 'testTag', '未知错误:' + codeNumber);
            break;
    }
}
```

### 步骤4:降级处理

```c
// 降级处理代码
async function fallbackNetworkQuery(): Promise<void> {
    try {
        // 主方案:查询网络信息
        const netId = testNetManager.NetId();
        if (netId <= 0) {
            // 降级方案1:提示用户检查网络连接
            hilog.warn(0x0000, 'testTag', '无法获取网络ID,请检查网络连接');
            return;
        }
        
        // 成功获取网络ID,继续处理
        hilog.info(0x0000, 'testTag', '成功获取网络ID:' + netId);
        
    } catch (error) {
        // 降级方案2:记录错误并提示用户
        hilog.error(0x0000, 'testTag', '网络查询失败:' + error.message);
        
        // 最终降级方案:提示用户稍后重试
        hilog.warn(0x0000, 'testTag', '请稍后重试或联系技术支持');
    }
}

// 网络服务不可达降级处理
function handleServiceUnreachable(): void {
    hilog.warn(0x0000, 'testTag', '网络服务不可达');
    
    // 建议:
    // 1. 检查网络连接状态
    // 2. 等待5-10秒后重试
    // 3. 如果持续失败,重启应用或设备
}

// DNS解析失败降级处理
function handleDnsFailure(): void {
    hilog.warn(0x0000, 'testTag', 'DNS解析失败');
    
    // 降级方案:
    // 1. 使用备用DNS服务器(如8.8.8.8)
    // 2. 直接使用IP地址访问
    // 3. 提示用户检查网络配置
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 0 | 成功 | 正常处理返回结果 |
| 201 | 缺少权限 | 在module.json5中添加ohos.permission.GET_NETWORK_INFO或ohos.permission.INTERNET权限 |
| 401 | 参数错误 | 检查参数有效性,确保指针非NULL,参数类型正确 |
| 2100002 | 无法连接到服务 | 检查网络状态,稍后重试,或重启网络服务 |
| 2100003 | 内部错误 | 记录日志,联系技术支持,检查系统状态 |
| 2101008 | 回调已注册 | 注销旧回调后重新注册,或使用不同的回调ID |
| 2101022 | 请求数超出最大值 | 减少并发请求数量,注销不必要的回调 |
| 2101007 | 回调不存在 | 检查callbackId是否正确,确保回调已注册 |

## 编译和修复问题

### 依赖声明

**动态链接库**(CMakeLists.txt):
```cmake
target_link_libraries(entry PUBLIC
    libace_napi.z.so
    libnet_connection.so
)
```

**头文件**:
```c
#include "napi/native_api.h"
#include "network/netmanager/net_connection.h"
#include "network/netmanager/net_connection_type.h"
```

**权限配置**(module.json5):
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.GET_NETWORK_INFO",
        "reason": "用于查询网络连接状态和信息"
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "用于DNS解析和网络探测"
      }
    ]
  }
}
```

### 环境要求
- HarmonyOS SDK: API version 11及以上(基础功能)
- HarmonyOS SDK: API version 12及以上(代理回调功能)
- HarmonyOS SDK: API version 15及以上(PAC脚本功能)
- HarmonyOS SDK: API version 20及以上(探测和跟踪路由)
- DevEco Studio: 3.1及以上
- NDK: r12及以上

### 常见编译问题

**问题1:找不到net_connection.h头文件**
```
fatal error: network/netmanager/net_connection.h: No such file or directory
```
**解决方法**:确保NDK版本正确(r12+),检查HarmonyOS SDK是否包含Network Kit

**问题2:链接libnet_connection.so失败**
```
undefined reference to 'OH_NetConn_GetDefaultNet'
```
**解决方法**:在CMakeLists.txt中添加libnet_connection.so依赖,确保target_link_libraries中包含该库

**问题3:权限缺失导致运行时错误**
```
返回码201:缺少权限
```
**解决方法**:在module.json5中添加ohos.permission.GET_NETWORK_INFO权限配置

**问题4:NAPI封装错误**
```
TypeError: Cannot read property 'NetId' of undefined
```
**解决方法**:确保NAPI模块正确注册(nm_modname与CMakeLists.txt一致),检查Init函数是否正确导出

**问题5:网络服务不可达**
```
返回码2100002:无法连接到服务
```
**解决方法**:检查设备网络连接状态,确保网络服务正常运行,可能需要重启设备

## 常见问题与解决方法

### Q1:如何判断设备是否有网络连接?
**原因**:需要先查询默认网络是否存在
**解决方法**:
- 调用OH_NetConn_HasDefaultNet检查是否有默认激活网络
- 如果返回值为0且hasDefaultNet为1,则设备有网络连接
- 如果hasDefaultNet为0,则设备无网络连接,需提示用户检查网络

### Q2:获取到的netId为负数或0,是否正常?
**原因**:netId为网络标识符,有效值应为正整数
**解决方法**:
- netId <= 0 表示获取失败或无默认网络
- 先调用OH_NetConn_HasDefaultNet检查网络状态
- 检查权限配置是否正确
- 检查返回码是否为NETMANAGER_SUCCESS(0)

### Q3:如何查询网络类型(WiFi/蜂窝)?
**原因**:需要通过网络能力集判断网络类型
**解决方法**:
- 调用OH_NetConn_GetNetCapabilities获取能力集
- 检查NetConn_NetCapabilities结构体中的网络类型标志
- 参考NetConn_NetCapType定义判断网络类型

### Q4:DNS解析结果如何释放?
**原因**:DNS解析结果由系统分配内存,需手动释放
**解决方法**:
- 调用OH_NetConn_FreeDnsResult释放DNS结果
- 传入addrinfo链表头指针
- 在使用完DNS结果后立即释放,避免内存泄漏

### Q5:如何处理网络探测导致的UI卡顿?
**原因**:网络探测涉及网络IO操作,耗时较长
**解决方法**:
- 避免在主线程/UI线程调用探测接口
- 使用异步线程或Worker线程进行探测
- 设置合理的探测时长duration(建议5-10秒)
- 探测完成后通过回调通知UI更新

### Q6:部分API已废弃,应该使用哪个?
**原因**:API版本更新,旧接口被废弃
**解决方法**:
- OHOS_NetConn_RegisterDnsResolver(废弃)->使用OH_NetConn_RegisterDnsResolver
- OHOS_NetConn_UnregisterDnsResolver(废弃)->使用OH_NetConn_UnregisterDnsResolver
- 查看API文档中的废弃版本和替代接口说明
- 使用最新版本的API,确保兼容性

### Q7:如何正确申请权限?
**原因**:不同接口需要不同权限
**解决方法**:
- 查询网络信息:ohos.permission.GET_NETWORK_INFO
- DNS解析和网络探测:ohos.permission.INTERNET
- PAC脚本设置:ohos.permission.SET_PAC_URL
- 跟踪路由:ohos.permission.LOCATION + ohos.permission.ACCESS_NET_TRACE_INFO
- 在module.json5中添加相应权限配置
- 部分权限需要用户授权(动态权限)

### Q8:NAPI模块注册失败怎么办?
**原因**:模块名称不一致或注册函数错误
**解决方法**:
- 确保demoModule.nm_modname与CMakeLists.txt中的库名一致
- 检查RegisterEntryModule是否正确调用napi_module_register
- 确保Init函数正确导出napi_property_descriptor
- 检查extern "C"声明是否正确(C++工程)

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "networkInfo": {
    "hasDefaultNet": true,
    "defaultNetId": 123,
    "connectionProperties": {
      "linkAddresses": ["192.168.1.100"],
      "dnsAddresses": ["8.8.8.8"],
      "linkRoutes": ["192.168.1.0/24"]
    },
    "netCapabilities": {
      "bearerTypes": ["WiFi"],
      "networkCap": ["INTERNET"]
    }
  },
  "apiUsed": [
    "OH_NetConn_HasDefaultNet",
    "OH_NetConn_GetDefaultNet",
    "OH_NetConn_GetConnectionProperties",
    "OH_NetConn_GetNetCapabilities"
  ],
  "permissions": [
    "ohos.permission.GET_NETWORK_INFO"
  ],
  "executionTime": "0.5s",
  "deviceInfo": {
    "apiVersion": 11,
    "networkStatus": "connected"
  }
}
```

## 参考文档

- [API开发指南](references/native-netmanager-guidelines.md)
- [API参考说明](references/capi-net-connection-h.md)

## 完整示例代码

- [C++示例(NAPI封装)](assets/native_netmanager_example.cpp)
- [ArkTS调用示例](assets/arkts_netmanager_example.ets)
- [CMakeLists.txt配置](assets/cmakelists_template.txt)
- [权限配置示例](assets/module_json5_template.json)

## 测试用例

### 正向测试用例
- [查询默认网络ID](tests/test_get_default_net.py):验证在有网络环境下成功获取默认网络ID
- [查询网络能力](tests/test_get_net_capabilities.py):验证成功获取网络能力集信息
- [查询连接属性](tests/test_get_connection_properties.py):验证成功获取网络连接属性

### 边界测试用例
- [无网络环境测试](tests/test_no_network.py):验证在无网络环境下的错误处理和降级方案
- [权限缺失测试](tests/test_missing_permission.py):验证缺少权限时的错误码和提示信息
- [参数NULL测试](tests/test_null_parameter.py):验证传入NULL参数时的错误处理

### 异常测试用例
- [网络服务不可达](tests/test_service_unreachable.py):验证网络服务异常时的降级处理
- [DNS解析失败](tests/test_dns_failure.py):验证DNS解析失败时的降级方案
- [并发调用测试](tests/test_concurrent_calls.py):验证多个并发网络查询的处理能力