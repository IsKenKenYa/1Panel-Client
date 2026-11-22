---
name: hmos-network-kit-net-connection-manager
description: 管理网络连接状态、查询网络信息、监听网络变化，支持WiFi/蜂窝/Ethernet多网络管理，需要GET_NETWORK_INFO权限，适用于网络状态监控、网络切换、DNS解析场景
---

# 管理网络连接技能

## 功能描述

网络连接管理提供管理网络的基础能力，包括WiFi/蜂窝/Ethernet等多网络连接优先级管理、网络质量评估、订阅默认/指定网络连接状态变化、查询网络连接信息、DNS解析等功能。

本技能覆盖以下典型场景：
- 接收指定网络的状态变化通知
- 监控默认网络变化并主动重建网络连接
- 获取所有注册的网络
- 查询默认网络或指定网络的连接信息
- 判断默认网络是否可以访问互联网
- 使用默认网络解析域名，获取所有IP

## 使用场景

### 触发词
- "监听网络状态"
- "获取网络连接信息"
- "查询默认网络"
- "网络切换"
- "网络变化通知"
- "DNS解析"
- "判断网络是否可用"
- "获取所有网络"

### 能做
- 创建NetConnection对象监听指定网络或默认网络状态
- 注册网络状态变化通知（netAvailable、netLost、netCapabilitiesChange等）
- 获取默认网络的NetHandle对象
- 获取所有处于连接状态的网络列表
- 查询网络能力信息（bearerTypes、networkCap）
- 查询网络连接属性（linkAddresses、dnsAddresses等）
- 判断网络是否可以访问互联网（NET_CAPABILITY_VALIDATED）
- 使用默认网络解析域名获取所有IP地址
- 监控默认网络变化并自动重建Socket连接

### 绝不做
- 不处理网络连接建立的具体过程（需使用Socket/HttpRequest等其他模块）
- 不处理VPN网络配置（仅查询VPN状态）
- 不修改系统网络设置
- 不处理网络认证流程（portal网络认证）
- 不进行网络流量统计

### 补充
- 需要申请ohos.permission.GET_NETWORK_INFO权限（normal级别）
- 大部分API为异步调用，提供callback和Promise两种方式
- 网络优先级：以太网(PC)|蓝牙(手表) > WIFI > 蜂窝
- NetHandle的netId为0表示无可用网络
- 支持同步和异步两种调用模式（API 10+提供同步接口）

## 调用规范和规则

### 输入约束
- netSpecifier参数：可选，包含netCapabilities和bearerTypes
- timeout参数：可选，uint32_t范围内的整数，默认0（毫秒）
- NetHandle对象：必须通过getDefaultNet或getAllNets获取
- host参数（DNS解析）：有效的域名字符串

### 执行约束
- 最大耗时：异步API无固定限制，同步API即时返回
- register()调用必须先创建NetConnection对象
- unregister()调用前必须已register
- 监听事件必须先register后才能接收回调

### 内容约束
- 禁止直接修改NetHandle的netId（除解除绑定场景）
- 禁止使用已unregister的NetConnection对象
- 禁止在未申请权限情况下调用需要权限的API
- 禁止并发调用默认不支持并发的接口

### 降级约束
- 无可用网络：NetHandle.netId为0，需提示用户检查网络设置
- 网络探测失败：NET_CAPABILITY_CHECKING_CONNECTIVITY状态，需等待后重试
- 权限不足：提示用户申请ohos.permission.GET_NETWORK_INFO权限
- 服务连接失败（2100002）：延迟重试或提示系统服务异常

## 调用流程和步骤

### 场景1：接收指定网络的状态变化通知

#### 步骤1：申请权限

在module.json5中声明权限：
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

#### 步骤2：导入模块

```typescript
import { connection } from '@kit.NetworkKit';
import { BusinessError } from '@kit.BasicServicesKit';
import { hilog } from '@kit.PerformanceAnalysisKit';
```

#### 步骤3：创建NetConnection对象

```typescript
let netSpecifier: connection.NetSpecifier = {
  netCapabilities: {
    bearerTypes: [connection.NetBearType.BEARER_WIFI],
    networkCap: [connection.NetCap.NET_CAPABILITY_INTERNET],
  }
};
let TIMEOUT = 10 * 1000;
let conn = connection.createNetConnection(netSpecifier, TIMEOUT);
```

#### 步骤4：订阅网络事件

```typescript
conn.on('netAvailable', (data: connection.NetHandle) => {
  hilog.info(0x0000, 'testTag', 'Network available, NetId is ' + data.netId);
});

conn.on('netUnavailable', (data: void) => {
  hilog.info(0x0000, 'testTag', 'Network unavailable');
});

conn.on('netLost', (data: connection.NetHandle) => {
  hilog.info(0x0000, 'testTag', 'Network lost, NetId: ' + data.netId);
});

conn.on('netCapabilitiesChange', (data: connection.NetCapabilityInfo) => {
  hilog.info(0x0000, 'testTag', 'Capabilities changed: ' + JSON.stringify(data));
});

conn.on('netConnectionPropertiesChange', (data: connection.NetConnectionPropertyInfo) => {
  hilog.info(0x0000, 'testTag', 'Properties changed: ' + JSON.stringify(data));
});
```

#### 步骤5：注册网络监听

```typescript
conn.register((err: BusinessError, data: void) => {
  if (err) {
    hilog.error(0x0000, 'testTag', 'Register failed: ' + JSON.stringify(err));
    return;
  }
  hilog.info(0x0000, 'testTag', 'Register success');
});
```

#### 步骤6：取消监听

```typescript
conn.unregister((err: BusinessError, data: void) => {
  if (err) {
    hilog.error(0x0000, 'testTag', 'Unregister failed: ' + JSON.stringify(err));
  } else {
    hilog.info(0x0000, 'testTag', 'Unregister success');
  }
});
```

### 场景2：查询默认网络连接信息

#### 步骤1：获取默认网络

```typescript
connection.getDefaultNet().then((data: connection.NetHandle) => {
  if (data.netId == 0) {
    hilog.info(0x0000, 'testTag', 'No default network available');
    return;
  }
  hilog.info(0x0000, 'testTag', 'Default network: ' + JSON.stringify(data));
  
  queryNetworkInfo(data);
}).catch((error: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'Get default net failed: ' + JSON.stringify(error));
});
```

#### 步骤2：查询网络能力

```typescript
function queryNetworkInfo(netHandle: connection.NetHandle) {
  connection.getNetCapabilities(netHandle).then((data: connection.NetCapabilities) => {
    hilog.info(0x0000, 'testTag', 'Network capabilities: ' + JSON.stringify(data));
    
    for (let bearerType of data.bearerTypes) {
      if (bearerType == connection.NetBearType.BEARER_CELLULAR) {
        hilog.info(0x0000, 'testTag', 'Network type: Cellular');
      } else if (bearerType == connection.NetBearType.BEARER_WIFI) {
        hilog.info(0x0000, 'testTag', 'Network type: WiFi');
      } else if (bearerType == connection.NetBearType.BEARER_ETHERNET) {
        hilog.info(0x0000, 'testTag', 'Network type: Ethernet');
      }
    }
    
    for (let cap of data.networkCap) {
      if (cap == connection.NetCap.NET_CAPABILITY_INTERNET) {
        hilog.info(0x0000, 'testTag', 'Capability: Internet');
      } else if (cap == connection.NetCap.NET_CAPABILITY_VALIDATED) {
        hilog.info(0x0000, 'testTag', 'Capability: Validated');
      }
    }
  });
}
```

#### 步骤3：查询网络连接属性

```typescript
connection.getConnectionProperties(netHandle).then((data: connection.ConnectionProperties) => {
  hilog.info(0x0000, 'testTag', 'Connection properties: ' + JSON.stringify(data));
});
```

### 场景3：判断网络是否可访问互联网

#### 步骤1：获取默认网络（同步方式）

```typescript
let netHandle = connection.getDefaultNetSync();
if (!netHandle || netHandle.netId === 0) {
  hilog.error(0x0000, 'testTag', 'No default network');
  return;
}
```

#### 步骤2：查询网络能力（同步方式）

```typescript
let netCapabilities = connection.getNetCapabilitiesSync(netHandle);
let cap = netCapabilities.networkCap;
```

#### 步骤3：判断网络连通性

```typescript
if (cap?.includes(connection.NetCap.NET_CAPABILITY_CHECKING_CONNECTIVITY)) {
  hilog.info(0x0000, 'testTag', 'Network is checking connectivity, please retry later');
} else {
  if (cap?.includes(connection.NetCap.NET_CAPABILITY_VALIDATED)) {
    hilog.info(0x0000, 'testTag', 'Network is validated, can access internet');
  } else {
    hilog.info(0x0000, 'testTag', 'Network is not validated, cannot access internet');
  }
}
```

### 场景4：获取所有网络列表

#### 步骤1：获取所有激活网络

```typescript
connection.getAllNets().then((data: connection.NetHandle[]) => {
  hilog.info(0x0000, 'testTag', 'All nets: ' + JSON.stringify(data));
  
  if (data && data.length > 0) {
    for (let netHandle of data) {
      queryNetworkInfo(netHandle);
    }
  }
}).catch((error: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'Get all nets failed: ' + JSON.stringify(error));
});
```

### 场景5：DNS解析

#### 步骤1：使用默认网络解析域名

```typescript
connection.getAddressesByName('www.example.com').then((data: connection.NetAddress[]) => {
  hilog.info(0x0000, 'testTag', 'Resolved addresses: ' + JSON.stringify(data));
}).catch((error: BusinessError) => {
  hilog.error(0x0000, 'testTag', 'DNS resolve failed: ' + JSON.stringify(error));
});
```

### 场景6：监控默认网络变化并重建连接

#### 步骤1：创建NetConnection监听默认网络

```typescript
import { connection, socket } from '@kit.NetworkKit';

const netConnection = connection.createNetConnection();
```

#### 步骤2：监听网络变化事件

```typescript
let sock: socket.TCPSocket | null = null;

netConnection.on('netAvailable', (netHandle: connection.NetHandle) => {
  hilog.info(0x0000, 'testTag', 'Default network changed: ' + JSON.stringify(netHandle));
  
  if (sock) {
    sock.close();
  }
  sock = socket.constructTCPSocketInstance();
  reconnectSocket();
});
```

#### 步骤3：注册监听

```typescript
netConnection.register((error: BusinessError) => {
  if (error) {
    hilog.error(0x0000, 'testTag', 'Register failed: ' + JSON.stringify(error));
  } else {
    hilog.info(0x0000, 'testTag', 'Register success');
  }
});
```

#### 步骤4：重建Socket连接

```typescript
function reconnectSocket() {
  if (!sock) return;
  
  let netAddress: socket.NetAddress = {
    address: '192.168.1.100',
    port: 8080
  };
  
  let tcpConnectOptions: socket.TCPConnectOptions = {
    address: netAddress,
    timeout: 6000
  };
  
  sock.connect(tcpConnectOptions, (err: BusinessError) => {
    if (err) {
      hilog.error(0x0000, 'testTag', 'Socket connect failed: ' + JSON.stringify(err));
      return;
    }
    hilog.info(0x0000, 'testTag', 'Socket connected');
  });
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请ohos.permission.GET_NETWORK_INFO权限 |
| 401 | Parameter error | 检查参数类型和取值范围 |
| 2100001 | Invalid parameter value | 检查NetHandle、timeout等参数是否合法 |
| 2100002 | Failed to connect to the service | 系统服务异常，延迟重试 |
| 2100003 | System internal error | 系统内部错误，重启应用或设备 |

**NetHandle异常处理**：
- netId为0：当前无可用网络，需提示用户检查网络连接
- 获取失败：检查权限配置和网络状态

**网络能力判断**：
- NET_CAPABILITY_CHECKING_CONNECTIVITY：正在验证连通性，需等待后重试
- 缺少NET_CAPABILITY_VALIDATED：网络未验证，可能无法访问互联网

## 编译和修复问题

### 依赖声明

在oh-package.json5中添加依赖：
```json
{
  "dependencies": {
    "@kit.NetworkKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0",
    "@kit.PerformanceAnalysisKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version 8+（基础接口）
- HarmonyOS API version 9+（getAppNet、setAppNet等）
- HarmonyOS API version 10+（同步接口：getDefaultNetSync、getAllNetsSync等）
- HarmonyOS API version 11+（元服务支持）

### 常见编译问题

**问题1：权限未声明**
```
Error: Permission denied
```
**解决方法**：在module.json5的requestPermissions中添加ohos.permission.GET_NETWORK_INFO

**问题2：API不存在**
```
Error: Property 'getDefaultNetSync' does not exist
```
**解决方法**：检查API version，同步接口需要API 10+

**问题3：导入模块失败**
```
Error: Cannot find module '@kit.NetworkKit'
```
**解决方法**：检查SDK版本和oh-package.json5配置

**问题4：类型错误**
```
Error: Type 'NetHandle' is not assignable to type 'number'
```
**解决方法**：检查变量类型定义，NetHandle是对象类型

## 常见问题与解决方法

### Q1：如何区分WiFi和蜂窝网络？
**原因**：需要通过bearerTypes判断网络类型
**解决方法**：
- 使用connection.getNetCapabilities获取NetCapabilities
- 检查bearerTypes数组：BEARER_CELLULAR(0)、BEARER_WIFI(1)、BEARER_ETHERNET(3)

### Q2：网络变化监听不触发回调？
**原因**：未调用register()注册监听
**解决方法**：
- 创建NetConnection后必须调用register()
- 确保订阅事件在register之前或之后立即设置
- 检查是否有网络状态变化

### Q3：获取的网络列表为空？
**原因**：WiFi和蜂窝开关开启但无应用使用蜂窝
**解决方法**：
- 在WiFi和蜂窝均开启时，默认只激活WiFi
- 需有特定应用启动蜂窝才能同时获取两种网络
- 检查设备网络设置

### Q4：NetHandle.netId为0？
**原因**：当前无可用网络连接
**解决方法**：
- 提示用户检查网络设置
- 检查WiFi/蜂窝是否开启
- 检查网络是否连接成功
- 建议使用hasDefaultNet先判断是否有网络

### Q5：如何判断网络是否可访问互联网？
**原因**：网络连接不一定表示可访问互联网
**解决方法**：
- 使用getNetCapabilitiesSync获取networkCap数组
- 检查是否包含NET_CAPABILITY_VALIDATED
- 注意NET_CAPABILITY_CHECKING_CONNECTIVITY表示正在验证

### Q6：同步接口和异步接口如何选择？
**原因**：性能和场景需求不同
**解决方法**：
- 同步接口：快速查询，适合UI线程外的调用
- 异步接口：不阻塞线程，适合大部分场景
- API 10+提供同步接口：getDefaultNetSync、getAllNetsSync等

## 输出结果报告

执行网络管理操作后输出以下信息：

```json
{
  "status": "success",
  "networkInfo": {
    "netId": 100,
    "bearerType": "WiFi",
    "capabilities": ["INTERNET", "VALIDATED"],
    "isMetered": false
  },
  "connectionProperties": {
    "interfaceName": "wlan0",
    "linkAddresses": ["192.168.1.100/24"],
    "dnsAddresses": ["8.8.8.8", "8.8.4.4"]
  },
  "apiUsed": [
    "connection.getDefaultNet",
    "connection.getNetCapabilities",
    "connection.getConnectionProperties"
  ]
}
```

## 参考文档

- [API开发指南](references/api-guide.md) - 管理网络连接开发指南
- [API参考说明](references/api-reference.md) - @ohos.net.connection API文档
- [权限使用基本原则](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/app-permission-mgmt-overview) - 应用权限管控概述
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions) - 如何声明权限

## 完整示例代码

- [监听网络状态示例](assets/net_connection_monitor.ets) - 接收网络状态变化通知
- [查询网络信息示例](assets/query_network_info.ets) - 查询默认网络和所有网络信息
- [判断网络可用示例](assets/check_network_availability.ets) - 判断网络是否可访问互联网
- [DNS解析示例](assets/dns_resolve.ets) - 使用默认网络解析域名

## 测试用例

### 正向测试用例
- [监听默认网络变化](tests/test_positive.py) - 测试成功监听默认网络状态变化
- [查询WiFi网络信息](tests/test_positive.py) - 测试成功获取WiFi网络的能力和属性
- [DNS解析成功](tests/test_positive.py) - 测试成功解析域名获取IP地址

### 边界测试用例
- [无可用网络](tests/test_boundary.py) - 测试netId为0的场景处理
- [网络探测中](tests/test_boundary.py) - 测试NET_CAPABILITY_CHECKING_CONNECTIVITY状态
- [多网络共存](tests/test_boundary.py) - 测试WiFi和蜂窝同时存在的场景

### 异常测试用例
- [权限未申请](tests/test_exception.py) - 测试缺少GET_NETWORK_INFO权限的错误处理
- [参数错误](tests/test_exception.py) - 测试传入无效NetHandle的错误处理
- [服务连接失败](tests/test_exception.py) - 测试2100002错误码的处理