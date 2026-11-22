---
name: hmos-connectivity-kit-spp-connect-transmit
description: 实现蓝牙SPP连接和数据传输+支持客户端服务端双向通信+需要蓝牙权限和设备配对+适用于传统蓝牙设备间串口通信场景
---

# 蓝牙SPP连接和数据传输技能

## 功能描述

本技能提供基于串口通信协议(Serial Port Profile, SPP)的蓝牙设备间连接和数据传输能力。支持客户端和服务端两种模式,实现蓝牙设备的发现、连接建立、双向数据传输和连接管理。适用于传统蓝牙(BR/EDR)设备间的通信场景,如蓝牙串口通信、设备间数据同步、蓝牙外设控制等。

**核心功能**:
- 客户端模式:发起连接、发送数据、接收数据、断开连接
- 服务端模式:创建socket、监听连接、发送数据、接收数据、删除socket
- 支持RFCOMM链路类型(传统蓝牙标准协议)
- 支持双向数据传输和异步回调

**适用范围**:
- 传统蓝牙(BR/EDR)设备通信
- 需要配对的蓝牙设备间通信
- 短距离串口通信场景
- 蓝牙外设数据交互

**技术限制**:
- 仅支持传统蓝牙(BR/EDR),不支持低功耗蓝牙(BLE)
- 需要申请ohos.permission.ACCESS_BLUETOOTH权限
- 客户端和服务端UUID必须一致
- 数据通道空闲5-7秒后进入休眠模式,首次发送需500ms唤醒
- RFCOMM链路单次接收数据超过1024字节会自动分多次接收

## 使用场景

### 触发词
- "蓝牙SPP连接" - 建立蓝牙串口连接
- "蓝牙数据传输" - 通过蓝牙传输数据
- "蓝牙socket通信" - 使用蓝牙socket进行通信
- "传统蓝牙通信" - 传统蓝牙(BR/EDR)设备间通信
- "蓝牙串口通信" - 蓝牙串口协议通信

### 能做
- 创建客户端socket并向服务端发起SPP连接
- 创建服务端socket并监听客户端连接请求
- 向已连接的蓝牙设备发送数据(ArrayBuffer格式)
- 从已连接的蓝牙设备接收数据(订阅模式)
- 主动断开客户端或服务端连接
- 删除服务端socket并注销UUID服务
- 支持客户端和服务端双向数据传输
- 提供连接状态管理和错误处理

### 绝不做
- 不处理低功耗蓝牙(BLE)设备的连接
- 不提供蓝牙设备扫描和发现功能(需配合查找设备技能)
- 不处理蓝牙配对流程(需提前完成配对)
- 不支持非RFCOMM链路类型的通信
- 不处理超出蓝牙协议限制的数据传输
- 不提供数据加密和压缩功能

### 补充
- 客户端和服务端UUID必须完全一致才能建立连接
- 服务端需先创建socket注册UUID服务,客户端才能发起连接
- 建议使用自定义UUID服务标识,避免与标准协议冲突
- 数据传输建议采用心跳保活机制(每3秒发送心跳数据)
- 连接建立前需确保设备已配对并获取设备地址
- 断开连接时需先取消数据订阅再关闭socket

## 调用规范和规则

### 输入约束
- **设备地址格式**: 必须符合蓝牙地址格式"XX:XX:XX:XX:XX:XX",6组16进制数用冒号分隔
- **UUID格式**: 必须符合UUID标准格式,如"00001101-0000-1000-8000-00805F9B34FB"
- **数据大小**: RFCOMM链路无单次发送限制,但建议不超过1024字节优化性能
- **socket ID**: 必须使用API回调返回的有效socket ID(非负整数)
- **服务名称**: 字符串长度范围[0, 256]字符

### 执行约束
- **权限检查**: 执行前必须验证ohos.permission.ACCESS_BLUETOOTH权限已申请
- **连接状态**: 发送/接收数据前必须确认连接已建立成功
- **UUID一致性**: 客户端连接UUID必须与服务端注册UUID完全一致
- **异步处理**: 所有连接和数据操作均使用异步回调,需正确处理callback
- **订阅管理**: 接收数据需先订阅,断开连接需先取消订阅
- **最大耗时**: 连接建立建议不超过10秒,数据发送建议不超过2秒
- **并发限制**: 同一socket ID不支持并发读写操作

### 内容约束
- **禁止高危操作**: 禁止使用蓝牙socket传输敏感数据(密码、密钥等)
- **禁止超时阻塞**: 禁止在无连接状态下无限等待连接回调
- **禁止异常UUID**: 禁止使用不符合规范的UUID字符串
- **禁止无效socket**: 禁止使用已关闭或无效的socket ID
- **禁止并发订阅**: 同一socket禁止重复订阅sppRead事件

### 降级约束
- **连接失败**: 提示用户检查设备配对状态和蓝牙开关,建议重试或切换设备
- **发送失败**: 检查连接状态和socket有效性,尝试重新建立连接
- **接收失败**: 检查订阅状态和回调函数,尝试重新订阅
- **权限不足**: 提示用户申请蓝牙权限,提供权限申请代码示例
- **UUID不匹配**: 提示用户确保客户端和服务端UUID一致,提供UUID生成方法
- **设备未配对**: 提示用户先完成设备配对,引导使用查找设备技能

## 调用流程和步骤

### 步骤1:权限申请和准备阶段

**前置校验**:
1. 检查蓝牙权限是否已申请
2. 检查蓝牙开关是否开启
3. 检查设备是否已配对
4. 获取目标设备地址(客户端模式)

**参数准备**:
```typescript
import { socket } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 客户端参数配置
let peerDevice: string = 'XX:XX:XX:XX:XX:XX'; // 服务端设备地址
let clientNumber: number = -1; // 客户端socket ID初始化

// 服务端参数配置
let serverNumber: number = -1; // 服务端socket ID初始化
let serviceName: string = 'MySppService'; // 服务名称

// 通用配置参数
let sppOption: socket.SppOptions = {
  uuid: '00009999-0000-1000-8000-00805F9B34FB', // 自定义UUID服务
  secure: false, // 非安全通道
  type: socket.SppType.SPP_RFCOMM // RFCOMM链路类型
};
```

### 步骤2:服务端创建socket并监听连接

**示例代码**:
```typescript
// 创建服务端监听socket
function createServerSocket(): void {
  console.info('[SPP] 创建服务端socket');
  
  socket.sppListen(serviceName, sppOption, (err: BusinessError, num: number) => {
    if (err) {
      console.error('[SPP] 创建失败: code=' + err.code + ', message=' + err.message);
      // 降级处理:提示用户检查蓝牙状态和权限
      handleServerError(err);
      return;
    } else {
      serverNumber = num;
      console.info('[SPP] 创建成功: serverNumber=' + serverNumber);
      // 继续监听客户端连接
      listenClientConnection();
    }
  });
}

// 监听客户端连接请求
function listenClientConnection(): void {
  if (serverNumber === -1) {
    console.error('[SPP] 服务端socket未创建');
    return;
  }
  
  console.info('[SPP] 开始监听客户端连接');
  socket.sppAccept(serverNumber, (err: BusinessError, clientSocketId: number) => {
    if (err) {
      console.error('[SPP] 监听失败: code=' + err.code + ', message=' + err.message);
      return;
    } else {
      console.info('[SPP] 客户端连接成功: clientSocketId=' + clientSocketId);
      // 连接建立成功,开始数据传输
      startDataTransmission(clientSocketId);
    }
  });
}
```

### 步骤3:客户端发起连接

**示例代码**:
```typescript
// 客户端发起连接
function connectToServer(): void {
  if (!peerDevice) {
    console.error('[SPP] 设备地址未设置');
    return;
  }
  
  console.info('[SPP] 开始连接服务端: device=' + peerDevice);
  
  socket.sppConnect(peerDevice, sppOption, (err: BusinessError, num: number) => {
    if (err) {
      console.error('[SPP] 连接失败: code=' + err.code + ', message=' + err.message);
      // 降级处理:检查设备配对和蓝牙状态
      handleConnectionError(err);
      return;
    } else {
      clientNumber = num;
      console.info('[SPP] 连接成功: clientNumber=' + clientNumber);
      // 连接建立成功,开始数据传输
      startDataTransmission(clientNumber);
    }
  });
}
```

### 步骤4:发送数据

**示例代码**:
```typescript
// 发送数据到对端设备
function sendData(socketId: number, dataContent: Uint8Array): void {
  if (socketId === -1) {
    console.error('[SPP] socket ID无效');
    return;
  }
  
  let arrayBuffer = new ArrayBuffer(dataContent.length);
  let dataView = new Uint8Array(arrayBuffer);
  dataView.set(dataContent);
  
  console.info('[SPP] 发送数据: length=' + dataContent.length);
  
  try {
    socket.sppWrite(socketId, arrayBuffer);
    console.info('[SPP] 数据发送成功');
  } catch (err) {
    let error = err as BusinessError;
    console.error('[SPP] 发送失败: code=' + error.code + ', message=' + error.message);
    // 错误处理:检查连接状态和socket有效性
    handleWriteError(error);
  }
}

// 示例:发送测试数据
function sendTestData(socketId: number): void {
  let testData = new Uint8Array([0x01, 0x02, 0x03, 0x04]);
  sendData(socketId, testData);
}
```

### 步骤5:接收数据

**示例代码**:
```typescript
// 订阅接收数据事件
function subscribeDataReceive(socketId: number): void {
  if (socketId === -1) {
    console.error('[SPP] socket ID无效');
    return;
  }
  
  console.info('[SPP] 订阅数据接收: socketId=' + socketId);
  
  // 定义接收数据回调函数
  let dataReceiveCallback = (dataBuffer: ArrayBuffer) => {
    let data = new Uint8Array(dataBuffer);
    console.info('[SPP] 接收数据: length=' + data.byteLength + ', data=' + JSON.stringify(data));
    // 处理接收到的数据
    handleReceivedData(data);
  };
  
  try {
    socket.on('sppRead', socketId, dataReceiveCallback);
    console.info('[SPP] 数据订阅成功');
  } catch (err) {
    let error = err as BusinessError;
    console.error('[SPP] 订阅失败: code=' + error.code + ', message=' + error.message);
  }
}

// 处理接收到的数据
function handleReceivedData(data: Uint8Array): void {
  // 根据业务需求处理数据
  console.info('[SPP] 处理接收数据');
  // 示例:数据解析、业务逻辑处理等
}
```

### 步骤6:断开连接和清理资源

**示例代码**:
```typescript
// 客户端断开连接
function disconnectClient(): void {
  if (clientNumber === -1) {
    console.error('[SPP] 客户端socket未创建');
    return;
  }
  
  console.info('[SPP] 开始断开客户端连接');
  
  try {
    // 先取消数据订阅
    socket.off('sppRead', clientNumber);
    console.info('[SPP] 取消数据订阅成功');
  } catch (err) {
    let error = err as BusinessError;
    console.error('[SPP] 取消订阅失败: code=' + error.code + ', message=' + error.message);
  }
  
  try {
    // 关闭客户端socket
    socket.sppCloseClientSocket(clientNumber);
    console.info('[SPP] 客户端连接已断开');
    clientNumber = -1;
  } catch (err) {
    let error = err as BusinessError;
    console.error('[SPP] 断开连接失败: code=' + error.code + ', message=' + error.message);
  }
}

// 服务端断开连接和删除socket
function disconnectServer(): void {
  console.info('[SPP] 开始断开服务端连接');
  
  // 断开客户端连接(如果有)
  if (clientNumber !== -1) {
    try {
      socket.off('sppRead', clientNumber);
      socket.sppCloseClientSocket(clientNumber);
      console.info('[SPP] 服务端断开客户端连接成功');
      clientNumber = -1;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP] 断开客户端连接失败: code=' + error.code + ', message=' + error.message);
    }
  }
  
  // 删除服务端socket
  if (serverNumber !== -1) {
    try {
      socket.sppCloseServerSocket(serverNumber);
      console.info('[SPP] 服务端socket已删除');
      serverNumber = -1;
    } catch (err) {
      let error = err as BusinessError;
      console.error('[SPP] 删除服务端socket失败: code=' + error.code + ', message=' + error.message);
    }
  }
}
```

### 步骤7:错误处理和降级方案

**错误处理代码**:
```typescript
// 连接错误处理
function handleConnectionError(err: BusinessError): void {
  switch (err.code) {
    case 201:
      console.error('[SPP] 权限不足: 请申请ohos.permission.ACCESS_BLUETOOTH权限');
      // 降级:提供权限申请引导
      guidePermissionRequest();
      break;
    case 2900003:
      console.error('[SPP] 蓝牙未开启: 请打开蓝牙开关');
      // 降级:提示用户开启蓝牙
      guideEnableBluetooth();
      break;
    case 2900004:
      console.error('[SPP] Profile不支持: 设备不支持SPP服务');
      // 降级:提示更换设备或检查设备兼容性
      guideDeviceCompatibility();
      break;
    case 2900099:
      console.error('[SPP] 操作失败: 请检查设备配对状态和UUID配置');
      // 降级:提供详细检查步骤
      guideTroubleshooting();
      break;
    default:
      console.error('[SPP] 未知错误: code=' + err.code);
      // 降级:提供通用错误处理建议
      guideGenericErrorHandling();
  }
}

// 数据发送错误处理
function handleWriteError(err: BusinessError): void {
  switch (err.code) {
    case 2901054:
      console.error('[SPP] IO错误: 连接可能已断开');
      // 降级:尝试重新建立连接
      reconnectSocket();
      break;
    case 2900099:
      console.error('[SPP] 发送失败: socket无效或数据格式错误');
      // 降级:检查socket状态和数据格式
      validateSocketAndData();
      break;
    default:
      console.error('[SPP] 发送未知错误: code=' + err.code);
  }
}

// 降级处理:重新连接
function reconnectSocket(): void {
  console.warn('[SPP] 执行降级方案:尝试重新连接');
  disconnectClient();
  // 等待1秒后重试
  setTimeout(() => {
    connectToServer();
  }, 1000);
}

// 降级处理:权限申请引导
function guidePermissionRequest(): void {
  console.info('[SPP] 降级方案:请在module.json5中配置权限');
  console.info('示例配置:');
  console.info('"requestPermissions": [');
  console.info('  { "name": "ohos.permission.ACCESS_BLUETOOTH" }');
  console.info(']');
}
```

## 错误码说明

| 错误码 | 说明 | 触发场景 | 解决方法 |
|-------|------|---------|---------|
| 201 | 权限不足 | 未申请蓝牙权限 | 在module.json5中配置ohos.permission.ACCESS_BLUETOOTH权限 |
| 401 | 参数错误 | UUID格式错误、设备地址格式错误、socket ID无效 | 检查参数格式和有效性,确保符合规范要求 |
| 801 | 能力不支持 | 设备不支持蓝牙SPP功能 | 检查设备兼容性,更换支持传统蓝牙的设备 |
| 2900001 | 服务停止 | 蓝牙服务异常停止 | 重启蓝牙服务或重启设备 |
| 2900003 | 蓝牙未开启 | 蓝牙开关处于关闭状态 | 打开蓝牙开关,确保蓝牙功能已启用 |
| 2900004 | Profile不支持 | 设备不支持SPP Profile | 检查设备是否支持传统蓝牙(BR/EDR),更换兼容设备 |
| 2900099 | 操作失败 | UUID不匹配、设备未配对、连接超时 | 检查UUID一致性、确认设备已配对、检查网络状态 |
| 2901054 | IO错误 | 连接已断开、socket已关闭、数据传输异常 | 检查连接状态,尝试重新建立连接 |

**错误处理最佳实践**:
- 连接失败优先检查权限和蓝牙状态
- 数据传输失败优先检查连接状态和socket有效性
- 所有异步回调必须处理错误分支
- 使用try-catch包裹同步API调用
- 提供友好的用户提示和降级方案

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
- **HarmonyOS SDK**: API version 10及以上
- **蓝牙支持**: 设备需支持传统蓝牙(BR/EDR)
- **权限配置**: module.json5需配置ohos.permission.ACCESS_BLUETOOTH权限

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**: 
- 检查HarmonyOS SDK版本是否为API 10及以上
- 确保项目配置中已正确引用ConnectivityKit
- 更新SDK到最新版本

**问题2:权限未配置**
```
Error: Permission denied. 201
```
**解决方法**:
- 在module.json5文件中添加权限配置:
```json
"requestPermissions": [
  {
    "name": "ohos.permission.ACCESS_BLUETOOTH",
    "reason": "用于蓝牙设备间通信",
    "usedScene": {
      "abilities": ["EntryAbility"],
      "when": "inuse"
    }
  }
]
```

**问题3:UUID格式错误**
```
Error: Invalid parameter. 401
```
**解决方法**:
- 检查UUID格式是否符合标准:8-4-4-4-12格式
- 使用UUID生成工具生成规范的UUID字符串
- 确保UUID与服务端配置完全一致

**问题4:设备地址格式错误**
```
Error: Invalid parameter. 401
```
**解决方法**:
- 确保设备地址格式为"XX:XX:XX:XX:XX:XX"
- 使用16进制表示,每组两个字符
- 通过查找设备技能获取正确的设备地址

## 常见问题与解决方法

### Q1:客户端连接失败,提示"Profile不支持"
**原因**: 设备不支持传统蓝牙(BR/EDR)或SPP Profile
**解决方法**:
- 检查设备是否支持传统蓝牙(非BLE设备)
- 确认设备已开启蓝牙功能
- 尝试更换支持SPP Profile的蓝牙设备
- 查询设备技术规格确认蓝牙协议支持

### Q2:UUID不匹配导致连接失败
**原因**: 客户端和服务端UUID配置不一致
**解决方法**:
- 确保两端使用完全相同的UUID字符串
- 建议使用自定义UUID而非标准协议UUID
- 使用UUID生成工具生成唯一UUID并同步配置
- 检查UUID格式是否正确(无多余空格或字符)

### Q3:数据接收不完整或丢失
**原因**: 未订阅数据接收事件或订阅回调未正确处理
**解决方法**:
- 确保连接建立成功后再订阅sppRead事件
- 检查回调函数是否正确处理ArrayBuffer数据
- RFCOMM链路超过1024字节会自动分包,需多次接收
- 避免在回调中执行耗时操作,影响数据接收

### Q4:发送数据后响应缓慢(500ms延迟)
**原因**: 蓝牙数据通道空闲5-7秒后进入休眠模式
**解决方法**:
- 实现心跳保活机制,每3秒发送心跳数据
- 在关键数据发送前先发送唤醒数据包
- 降低数据发送间隔,保持通道活跃状态
- 注意:保活机制会增加设备功耗

### Q5:断开连接后socket ID仍有效
**原因**: socket未正确关闭或资源未清理
**解决方法**:
- 断开连接前先取消数据订阅
- 使用正确的socket关闭API(sppCloseClientSocket或sppCloseServerSocket)
- 确保socket ID变量在关闭后重置为-1
- 检查异步回调是否正确执行关闭操作

### Q6:权限申请后仍提示权限不足
**原因**: 权限配置不完整或运行时权限未申请
**解决方法**:
- 确保module.json5中已配置ohos.permission.ACCESS_BLUETOOTH
- 检查是否为用户授权权限(需向用户申请授权)
- 参考声明权限和向用户申请授权文档正确配置
- 重启应用使权限配置生效

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "function": "蓝牙SPP连接和数据传输",
  "mode": "client/server",
  "socketId": {
    "clientSocket": "客户端socket ID(非负整数)",
    "serverSocket": "服务端socket ID(非负整数)"
  },
  "connectionState": "connected/disconnected",
  "dataTransmission": {
    "sendBytes": "已发送数据字节数",
    "receiveBytes": "已接收数据字节数"
  },
  "apiUsed": [
    "socket.sppConnect",
    "socket.sppListen",
    "socket.sppAccept",
    "socket.sppWrite",
    "socket.on('sppRead')",
    "socket.off('sppRead')",
    "socket.sppCloseClientSocket",
    "socket.sppCloseServerSocket"
  ],
  "uuidService": "使用的UUID服务标识",
  "deviceAddress": "对端设备地址",
  "executionTime": "执行耗时(秒)"
}
```

## 参考文档

- [SPP开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/spp-development-guide)
- [蓝牙socket API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-socket)
- [查找设备开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-discovery-development-guide)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)

## 完整示例代码

- [客户端完整示例](assets/spp_client_example.ets)
- [服务端完整示例](assets/spp_server_example.ets)
- [管理类封装示例](assets/spp_manager_example.ets)

## 测试用例

### 正向测试用例
- [客户端连接成功测试](tests/test_client_connect_success.ets):验证客户端成功连接服务端
- [服务端监听成功测试](tests/test_server_listen_success.ets):验证服务端成功创建socket和监听
- [数据发送成功测试](tests/test_data_send_success.ets):验证数据成功发送到对端
- [数据接收成功测试](tests/test_data_receive_success.ets):验证成功订阅并接收数据
- [断开连接成功测试](tests/test_disconnect_success.ets):验证连接正常断开和资源清理

### 边界测试用例
- [UUID边界测试](tests/test_uuid_boundary.ets):测试不同UUID格式和长度
- [数据大小边界测试](tests/test_data_size_boundary.ets):测试不同数据大小传输
- [连接数量边界测试](tests/test_connection_count_boundary.ets):测试多客户端连接场景
- [服务名称长度边界测试](tests/test_service_name_boundary.ets):测试服务名称长度限制

### 异常测试用例
- [权限不足测试](tests/test_permission_denied.ets):验证权限不足时的错误处理
- [蓝牙未开启测试](tests/test_bluetooth_disabled.ets):验证蓝牙关闭状态的处理
- [设备未配对测试](tests/test_device_unpaired.ets):验证设备未配对时的错误处理
- [UUID不匹配测试](tests/test_uuid_mismatch.ets):验证UUID不一致的连接失败
- [无效socket测试](tests/test_invalid_socket.ets):验证无效socket ID的错误处理
- [连接超时测试](tests/test_connection_timeout.ets):验证连接超时的降级处理