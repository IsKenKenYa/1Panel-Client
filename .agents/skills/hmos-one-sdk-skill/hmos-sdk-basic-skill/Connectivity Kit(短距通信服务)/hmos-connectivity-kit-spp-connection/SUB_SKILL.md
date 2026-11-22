---
name: hmos-connectivity-kit-spp-connection
description: 实现基于串口通信协议(SPP)的蓝牙设备间连接和数据传输，支持客户端与服务端双向通信，适用于传统蓝牙(BR/EDR)设备的数据交互场景
---

# 蓝牙SPP连接和传输数据技能

## 功能描述

本技能提供基于串口通信协议（Serial Port Profile，SPP）实现蓝牙设备间连接和传输数据的完整开发方案。支持客户端与服务端两种角色的实现，包括：
- 服务端创建监听套接字、接受客户端连接请求、数据发送与接收、断开连接及删除套接字
- 客户端发起连接请求、数据发送与接收、断开连接
- 支持RFCOMM和L2CAP两种链路类型
- 提供同步和异步数据传输接口（API 18+）

适用于传统蓝牙（BR/EDR）设备的点对点数据通信场景，如串口通信模拟、设备间数据同步、实时数据传输等应用。

## 使用场景

### 触发词
- "蓝牙SPP连接"
- "蓝牙串口通信"
- "蓝牙数据传输"
- "蓝牙socket连接"
- "SPP客户端"
- "SPP服务端"

### 能做
- 创建蓝牙SPP服务端监听套接字并注册UUID服务
- 客户端向服务端发起SPP连接请求
- 客户端和服务端之间双向发送和接收数据
- 监听和处理连接状态变化
- 主动断开连接并释放套接字资源
- 支持RFCOMM和L2CAP链路类型的配置

### 绝不做
- 不处理低功耗蓝牙（BLE）设备的连接（需使用L2CAP_BLE链路类型）
- 不替代查找设备流程（需先通过查找设备获取目标设备地址）
- 不处理超出数据传输限制的大数据场景
- 不提供跨设备类型（BLE和BR/EDR混连）的解决方案

### 补充
- 需要先申请ohos.permission.ACCESS_BLUETOOTH权限
- 客户端连接前需确保服务端已注册相应UUID服务
- 建议使用自定义UUID而非标准协议UUID以避免冲突
- 数据通道空闲5-7秒后会进入休眠模式，首次发送需约500ms唤醒
- 建议每3秒发送心跳数据以保持连接活跃（会增加功耗）

## 调用规范和规则

### 输入约束
- **设备地址格式**：必须为标准蓝牙MAC地址格式（"XX:XX:XX:XX:XX:XX"）
- **UUID格式**：必须为标准UUID格式（如"00009999-0000-1000-8000-00805F9B34FB")
- **服务名称长度**：字符个数范围为[0, 256]
- **数据大小限制**：
  - SPP_RFCOMM链路：单次接收超过1024字节会自动分多次接收
  - SPP_L2CAP链路：客户端单次发送[1, 8085]字节，服务端单次发送[1, 4091]字节
  - SPP_L2CAP_BLE链路：单次发送和接收[1, 65535]字节

### 执行约束
- **连接建立耗时**：取决于设备距离和蓝牙状态，建议超时设置为10秒
- **数据发送频率**：建议每3秒发送心跳数据以保持连接活跃
- **最大并发连接数**：受限于系统资源，建议不超过5个并发连接
- **异步调用顺序**：sppReadAsync需等待异步回调返回后再进行下一次调用

### 内容约束
- 禁止使用eval、exec等高危函数
- 禁止在回调函数中执行耗时超过100ms的阻塞操作
- 禁止在连接未建立状态下调用数据传输接口
- 禁止混用socket.on('sppRead')和socket.sppReadAsync接口

### 降级约束
- **网络失败**：捕获错误码2900003（Bluetooth disabled），提示用户开启蓝牙
- **连接失败**：捕获错误码2900099（Operation failed），建议重新发起连接或检查设备状态
- **权限不足**：捕获错误码201（Permission denied），引导用户申请权限
- **服务不支持**：捕获错误码2900004（Profile not supported），建议检查设备是否支持SPP功能
- **数据传输错误**：捕获错误码2901054（IO error），建议检查连接状态并重试

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 检查蓝牙权限是否已申请（ohos.permission.ACCESS_BLUETOOTH）
2. 检查蓝牙是否已启用（避免错误码2900003）
3. 准备目标设备地址（通过查找设备流程获取，参考[查找设备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-discovery-development-guide)）

**参数准备**：
```typescript
import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 配置SPP连接参数
let sppOption: socket.SppOptions = {
  uuid: '00009999-0000-1000-8000-00805F9B34FB', // 自定义UUID或标准UUID
  secure: false, // 是否使用安全通道
  type: socket.SppType.SPP_RFCOMM // 链路类型
};
```

### 步骤2：服务端实现

**创建服务端监听套接字**：
```typescript
let serverNumber = -1;

socket.sppListen('demonstration', sppOption, (err: BusinessError, num: number) => {
  if (err) {
    console.error('sppListen errCode: ' + err.code + ', errMessage: ' + err.message);
    return;
  }
  serverNumber = num;
  console.info('sppListen success, serverNumber: ' + serverNumber);
});
```

**监听客户端连接**：
```typescript
let clientNumber = -1;

socket.sppAccept(serverNumber, (err: BusinessError, num: number) => {
  if (err) {
    console.error('sppAccept errCode: ' + err.code + ', errMessage: ' + err.message);
    return;
  }
  clientNumber = num;
  console.info('sppAccept success, clientNumber: ' + clientNumber);
});
```

**发送数据**：
```typescript
let arrayBuffer = new ArrayBuffer(2);
let data = new Uint8Array(arrayBuffer);
data[0] = 9;
data[1] = 8;

try {
  socket.sppWrite(clientNumber, arrayBuffer);
} catch (err) {
  let error = err as BusinessError;
  console.error('sppWrite errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

**接收数据**：
```typescript
function readData(dataBuffer: ArrayBuffer) {
  let data = new Uint8Array(dataBuffer);
  console.info('received data: ' + JSON.stringify(data));
}

try {
  socket.on('sppRead', clientNumber, readData);
} catch (err) {
  let error = err as BusinessError;
  console.error('readData errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

**断开连接并删除套接字**：
```typescript
try {
  socket.off('sppRead', clientNumber, readData);
} catch (err) {
  let error = err as BusinessError;
  console.error('off sppRead errCode: ' + error.code + ', errMessage: ' + error.message);
}

try {
  socket.sppCloseClientSocket(clientNumber);
} catch (err) {
  let error = err as BusinessError;
  console.error('sppCloseClientSocket errCode: ' + error.code + ', errMessage: ' + error.message);
}

try {
  socket.sppCloseServerSocket(serverNumber);
} catch (err) {
  let error = err as BusinessError;
  console.error('sppCloseServerSocket errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

### 步骤3：客户端实现

**发起连接**：
```typescript
let peerDevice = 'XX:XX:XX:XX:XX:XX'; // 从查找设备流程获取
let clientNumber = -1;

socket.sppConnect(peerDevice, sppOption, (err: BusinessError, num: number) => {
  if (err) {
    console.error('sppConnect errCode: ' + err.code + ', errMessage: ' + err.message);
    return;
  }
  clientNumber = num;
  console.info('sppConnect success, clientNumber: ' + clientNumber);
});
```

**发送数据**：
```typescript
let arrayBuffer = new ArrayBuffer(2);
let data = new Uint8Array(arrayBuffer);
data[0] = 3;
data[1] = 4;

try {
  socket.sppWrite(clientNumber, arrayBuffer);
} catch (err) {
  let error = err as BusinessError;
  console.error('sppWrite errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

**接收数据**：
```typescript
function readData(dataBuffer: ArrayBuffer) {
  let data = new Uint8Array(dataBuffer);
  console.info('received data: ' + JSON.stringify(data));
}

try {
  socket.on('sppRead', clientNumber, readData);
} catch (err) {
  let error = err as BusinessError;
  console.error('readData errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

**断开连接**：
```typescript
try {
  socket.off('sppRead', clientNumber, readData);
} catch (err) {
  let error = err as BusinessError;
  console.error('off sppRead errCode: ' + error.code + ', errMessage: ' + error.message);
}

try {
  socket.sppCloseClientSocket(clientNumber);
} catch (err) {
  let error = err as BusinessError;
  console.error('sppCloseClientSocket errCode: ' + error.code + ', errMessage: ' + error.message);
}
```

### 步骤4：错误处理

```typescript
// 通用错误处理函数
function handleSppError(error: BusinessError) {
  switch (error.code) {
    case 201:
      console.error('权限不足，请申请ohos.permission.ACCESS_BLUETOOTH权限');
      break;
    case 401:
      console.error('参数错误：' + error.message);
      break;
    case 801:
      console.error('设备不支持此功能');
      break;
    case 2900001:
      console.error('服务已停止，请检查蓝牙状态');
      break;
    case 2900003:
      console.error('蓝牙已关闭，请开启蓝牙');
      break;
    case 2900004:
      console.error('设备不支持SPP功能');
      break;
    case 2900099:
      console.error('操作失败：' + error.message);
      break;
    case 2901054:
      console.error('IO错误，请检查连接状态');
      break;
    default:
      console.error('未知错误：' + error.message);
  }
}

// 使用示例
try {
  socket.sppConnect(peerDevice, sppOption, (err, num) => {
    if (err) {
      handleSppError(err as BusinessError);
    }
  });
} catch (err) {
  handleSppError(err as BusinessError);
}
```

### 步骤5：降级处理

```typescript
// 连接失败降级处理
async function connectWithFallback(peerDevice: string, sppOption: socket.SppOptions): Promise<number> {
  let retryCount = 0;
  const maxRetry = 3;
  
  while (retryCount < maxRetry) {
    try {
      return await new Promise<number>((resolve, reject) => {
        socket.sppConnect(peerDevice, sppOption, (err, num) => {
          if (err) {
            reject(err);
          } else {
            resolve(num);
          }
        });
      });
    } catch (err) {
      let error = err as BusinessError;
      retryCount++;
      
      if (error.code === 2900003) {
        console.warn('蓝牙已关闭，请手动开启蓝牙');
        break;
      }
      
      if (error.code === 2900099 && retryCount < maxRetry) {
        console.warn('连接失败，正在重试（' + retryCount + '/' + maxRetry + '）');
        await new Promise(resolve => setTimeout(resolve, 1000)); // 等待1秒后重试
        continue;
      }
      
      console.error('连接失败，无法建立连接');
      throw error;
    }
  }
  
  throw new Error('连接重试次数已达上限');
}

// 数据发送失败降级处理
function sendDataWithFallback(clientNumber: number, data: ArrayBuffer): boolean {
  try {
    socket.sppWrite(clientNumber, data);
    return true;
  } catch (err) {
    let error = err as BusinessError;
    if (error.code === 2901054) {
      console.warn('IO错误，建议检查连接状态');
    }
    console.error('数据发送失败：' + error.message);
    return false;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限不足（Permission denied） | 申请ohos.permission.ACCESS_BLUETOOTH权限，参考[声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)和[向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization) |
| 401 | 参数错误（Invalid parameter） | 检查参数类型和取值范围，确保必填参数已指定 |
| 801 | 功能不支持（Capability not supported） | 检查设备是否支持蓝牙SPP功能 |
| 2900001 | 服务已停止（Service stopped） | 检查蓝牙服务状态，尝试重启蓝牙 |
| 2900003 | 蓝牙已关闭（Bluetooth disabled） | 提示用户开启蓝牙开关 |
| 2900004 | Profile不支持（Profile not supported） | 检查目标设备是否支持SPP功能 |
| 2900099 | 操作失败（Operation failed） | 检查设备状态和连接条件，必要时重试 |
| 2901054 | IO错误（IO error） | 检查连接状态，确认套接字是否有效 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version 10+（基础接口）
- HarmonyOS API version 18+（异步接口sppWriteAsync、sppReadAsync）
- HarmonyOS API version 20+（L2CAP相关接口getL2capPsm、psm参数）
- HarmonyOS API version 22+（getMaxReceiveDataSize、getMaxTransmitDataSize、isConnected）
- Device Type：支持传统蓝牙（BR/EDR）的设备

### 常见编译问题

**问题1：导入模块错误**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：确保项目已配置正确的依赖，检查package.json中是否包含@kit.ConnectivityKit

**问题2：权限配置缺失**
```
Error: Permission denied (code: 201)
```
**解决方法**：在module.json5中添加权限声明：
```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BLUETOOTH"
      }
    ]
  }
}
```

**问题3：API版本不兼容**
```
Error: Capability not supported (code: 801)
```
**解决方法**：检查设备API版本，确保使用兼容的API接口

**问题4：类型定义错误**
```
Error: Property 'sppConnect' does not exist on type 'socket'
```
**解决方法**：确保导入正确的socket模块，使用`import { socket } from '@kit.ConnectivityKit'`

## 常见问题与解决方法

### Q1：连接失败提示"Profile not supported"
**原因**：目标设备不支持客户端请求的UUID服务
**解决方法**：
- 确认服务端已通过sppListen注册相应的UUID服务
- 检查客户端和服务端的UUID是否一致
- 确认目标设备支持传统蓝牙（BR/EDR）功能

### Q2：数据传输延迟较高
**原因**：蓝牙数据通道空闲进入休眠模式
**解决方法**：
- 建议每3秒发送一次心跳数据以保持连接活跃
- 首次发送数据前预留约500ms唤醒时间
- 注意心跳数据会增加设备功耗

### Q3：接收数据丢失
**原因**：未及时调用接收接口或订阅回调处理不及时
**解决方法**：
- 使用socket.on('sppRead')订阅接收事件并及时处理回调
- 使用socket.sppReadAsync循环读取数据（API 18+）
- 避免在回调函数中执行耗时超过100ms的阻塞操作

### Q4：连接意外断开
**原因**：设备距离过远、蓝牙干扰或电量不足
**解决方法**：
- 检查设备距离保持在蓝牙有效范围内（建议<10米）
- 避免在有强电磁干扰的环境使用
- 监控设备电量状态，电量过低时提醒用户
- 实现连接状态监听和自动重连机制

### Q5：多个客户端连接同一服务端
**原因**：服务端需要多次调用sppAccept接受不同客户端
**解决方法**：
- 每次调用sppAccept会返回一个新的客户端套接字ID
- 建议维护客户端套接字ID列表进行管理
- 单个服务端建议不超过5个并发连接

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "role": "client|server",
  "socketId": "客户端或服务端套接字ID",
  "peerDevice": "对端设备地址",
  "connected": true,
  "dataTransmitted": {
    "sent": "发送数据大小（字节）",
    "received": "接收数据大小（字节）"
  },
  "apiUsed": [
    "socket.sppConnect",
    "socket.sppWrite",
    "socket.on('sppRead')",
    "socket.off('sppRead')",
    "socket.sppCloseClientSocket"
  ]
}
```

## 参考文档

- [API开发指南 - 连接和传输数据](references/spp-development-guide.md)
- [API参考说明 - @ohos.bluetooth.socket](references/js-apis-bluetooth-socket.md)
- [查找设备流程](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-discovery-development-guide)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)

## 完整示例代码

- [服务端完整示例](assets/spp_server_example.ets)
- [客户端完整示例](assets/spp_client_example.ets)
- [异步数据传输示例（API 18+）](assets/spp_async_example.ets)

## 测试用例

### 正向测试用例
- [服务端监听和接受连接测试](tests/test_server_listen_accept.py)：验证服务端创建套接字并成功接受客户端连接
- [客户端连接和数据传输测试](tests/test_client_connect_transmit.py)：验证客户端成功连接并发送接收数据
- [双向数据通信测试](tests/test_bidirectional_communication.py)：验证客户端和服务端双向数据传输

### 边界测试用例
- [大数据传输测试](tests/test_large_data_transfer.py)：验证单次传输数据大小限制
- [并发连接测试](tests/test_concurrent_connections.py)：验证多个客户端同时连接服务端
- [长时间连接保活测试](tests/test_connection_keepalive.py)：验证心跳数据保持连接活跃

### 异常测试用例
- [权限缺失测试](tests/test_permission_denied.py)：验证未申请权限时的错误处理
- [蓝牙关闭状态测试](tests/test_bluetooth_disabled.py)：验证蓝牙关闭时的错误处理
- [连接失败重试测试](tests/test_connection_failure_retry.py)：验证连接失败时的降级重试机制
- [数据传输错误测试](tests/test_io_error_handling.py)：验证IO错误时的处理机制