---
name: hmos-connectivity-kit-gatt-connection
description: 实现BLE设备间的GATT连接和数据传输，支持客户端和服务端两种角色，需申请ACCESS_BLUETOOTH权限，适用于蓝牙设备通信、数据同步场景
---

# BLE GATT连接和数据传输技能

## 功能描述

本技能提供了基于通用属性协议（Generic Attribute Profile，GATT）实现BLE设备间连接和传输数据的完整开发指导。GATT是低功耗蓝牙（BLE）的核心协议，定义了基于服务（Service）、特征值（Characteristic）和描述符（Descriptor）进行蓝牙通信和传输数据的机制。

当两个设备间进行GATT通信交互时，依据设备功能的不同，可区分为GATT客户端和GATT服务端：
- **GATT客户端**：主动发起连接，向服务端发起服务查询、读写特征值和接收通知等操作
- **GATT服务端**：发送BLE广播等待客户端连接，支持客户端需要的服务，接收读写请求和发送通知等操作

## 使用场景

### 触发词
- "BLE连接"
- "GATT连接"
- "蓝牙数据传输"
- "BLE客户端"
- "BLE服务端"
- "蓝牙特征值读写"
- "低功耗蓝牙通信"

### 能做
- 创建GATT客户端实例并主动发起连接
- 创建GATT服务端实例并注册服务
- 进行服务发现获取服务端支持的服务能力
- 读取和写入特征值数据
- 读取和写入描述符数据
- 接收服务端特征值变化通知或指示
- 发送特征值变化通知或指示到客户端
- 监听连接状态变化
- 断开连接并释放资源

### 绝不做
- 不处理BLE扫描流程（请参考查找设备技能）
- 不处理BLE广播流程（请参考查找设备技能）
- 不处理经典蓝牙连接
- 不处理超出BLE协议范围的操作
- 不在未连接状态下进行读写操作
- 不操作未包含在服务能力集合中的特征值或描述符

### 补充
- 需要先申请ohos.permission.ACCESS_BLUETOOTH权限
- 客户端需要通过BLE扫描获取服务端设备地址
- 服务端需要发送BLE广播才能被客户端发现
- 读写操作必须在服务发现完成后进行
- 特征值变化通知需要使能Client Characteristic Configuration描述符

## 调用规范和规则

### 输入约束
- 设备地址格式：必须为"XX:XX:XX:XX:XX:XX"格式
- UUID格式：必须符合标准UUID格式（如"00001810-0000-1000-8000-00805F9B34FB"）
- 特征值数据：ArrayBuffer类型，最大长度512字节
- 描述符数据：ArrayBuffer类型，最大长度512字节
- 服务UUID：必须唯一且符合蓝牙标准或自定义规范

### 执行约束
- 最大连接耗时：30秒（超时需主动断开）
- 服务发现必须在连接成功后进行
- 读写操作必须在服务发现完成后进行
- 特征值变化通知使能前必须先订阅事件
- 断开连接后必须调用close释放资源
- 同时最多支持7个BLE设备连接

### 内容约束
- 禁止在未连接状态下调用读写API
- 禁止操作不存在的特征值或描述符
- 禁止使用未注册的服务UUID
- 禁止硬编码敏感数据（如设备地址、密钥）
- 禁止在回调函数中执行耗时超过100ms的操作
- 必须校验服务发现结果包含所需的服务和特征值

### 降级约束
- 连接失败：提示用户检查设备状态和权限，提供重试机制
- 服务发现失败：断开连接并提示服务端不支持所需服务
- 读写超时：取消操作并提示用户，提供重试选项
- 特征值变化通知使能失败：提示不支持该功能，使用轮询读取替代方案
- 权限未授予：引导用户到设置页面授权，禁止强制操作

## 调用流程和步骤

### 步骤1：申请权限和导入模块

**前置校验**：
1. 检查是否已申请ohos.permission.ACCESS_BLUETOOTH权限
2. 检查蓝牙是否已开启
3. 检查设备是否支持BLE功能

**参数准备**：
```typescript
import { ble, constant } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2：客户端实现流程

#### 2.1 创建客户端实例

**示例代码**：
```typescript
let device = 'XX:XX:XX:XX:XX:XX'; // 服务端设备地址
let gattClient: ble.GattClientDevice | undefined = undefined;

try {
  gattClient = ble.createGattClientDevice(device);
  console.info('GattClient created successfully');
} catch (err) {
  console.error('Create GattClient failed: ' + (err as BusinessError).code + ', ' + (err as BusinessError).message);
  return;
}
```

#### 2.2 订阅连接状态变化事件

**示例代码**：
```typescript
let connectState: constant.ProfileConnectionState = constant.ProfileConnectionState.STATE_DISCONNECTED;

function onConnectionStateChange(state: ble.BLEConnectionChangeState) {
  console.info('Connection state changed: device=' + state.deviceId + ', state=' + state.state);
  if (state.deviceId === device) {
    connectState = state.state;
    if (state.state === constant.ProfileConnectionState.STATE_CONNECTED) {
      console.info('Device connected successfully');
      // 连接成功后进行服务发现
      discoverServices();
    } else if (state.state === constant.ProfileConnectionState.STATE_DISCONNECTED) {
      console.info('Device disconnected');
    }
  }
}

try {
  gattClient.on('BLEConnectionStateChange', onConnectionStateChange);
} catch (err) {
  console.error('Subscribe connection state failed: ' + (err as BusinessError).code);
}
```

#### 2.3 发起连接

**示例代码**：
```typescript
try {
  if (gattClient) {
    gattClient.connect();
    console.info('Connect request sent');
  }
} catch (err) {
  console.error('Connect failed: ' + (err as BusinessError).code);
  // 降级处理：提示用户并清理资源
  cleanupClient();
}
```

#### 2.4 服务发现

**示例代码**：
```typescript
async function discoverServices() {
  if (!gattClient || connectState !== constant.ProfileConnectionState.STATE_CONNECTED) {
    console.error('GattClient not connected');
    return;
  }

  try {
    let services = await gattClient.getServices();
    console.info('Services discovered: ' + services.length);
    
    // 查找所需的服务和特征值
    for (let service of services) {
      console.info('Service UUID: ' + service.serviceUuid);
      for (let characteristic of service.characteristics) {
        console.info('Characteristic UUID: ' + characteristic.characteristicUuid);
        for (let descriptor of characteristic.descriptors) {
          console.info('Descriptor UUID: ' + descriptor.descriptorUuid);
        }
      }
    }
    
    // 校验是否包含所需的服务
    checkRequiredServices(services);
  } catch (err) {
    console.error('Service discovery failed: ' + (err as BusinessError).code);
    // 降级处理：断开连接
    disconnect();
  }
}
```

#### 2.5 读取特征值

**示例代码**：
```typescript
function readCharacteristic(serviceUuid: string, characteristicUuid: string) {
  if (!gattClient || connectState !== constant.ProfileConnectionState.STATE_CONNECTED) {
    console.error('GattClient not connected');
    return;
  }

  let characteristic: ble.BLECharacteristic = {
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    characteristicValue: new ArrayBuffer(0),
    descriptors: []
  };

  try {
    gattClient.readCharacteristicValue(characteristic).then((result: ble.BLECharacteristic) => {
      console.info('Read characteristic success: ' + result.characteristicUuid);
      let value = new Uint8Array(result.characteristicValue);
      console.info('Value: ' + Array.from(value).join(','));
    }).catch((err: BusinessError) => {
      console.error('Read characteristic failed: ' + err.code);
    });
  } catch (err) {
    console.error('Read characteristic exception: ' + (err as BusinessError).code);
  }
}
```

#### 2.6 写入特征值

**示例代码**：
```typescript
function writeCharacteristic(serviceUuid: string, characteristicUuid: string, data: ArrayBuffer) {
  if (!gattClient || connectState !== constant.ProfileConnectionState.STATE_CONNECTED) {
    console.error('GattClient not connected');
    return;
  }

  let characteristic: ble.BLECharacteristic = {
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    characteristicValue: data,
    descriptors: []
  };

  try {
    gattClient.writeCharacteristicValue(characteristic, ble.GattWriteType.WRITE, (err) => {
      if (err) {
        console.error('Write characteristic failed: ' + (err as BusinessError).code);
      } else {
        console.info('Write characteristic success');
      }
    });
  } catch (err) {
    console.error('Write characteristic exception: ' + (err as BusinessError).code);
  }
}
```

#### 2.7 接收特征值变化通知

**示例代码**：
```typescript
function enableNotification(serviceUuid: string, characteristicUuid: string) {
  if (!gattClient || connectState !== constant.ProfileConnectionState.STATE_CONNECTED) {
    console.error('GattClient not connected');
    return;
  }

  // 先订阅特征值变化事件
  function onCharacteristicChange(char: ble.BLECharacteristic) {
    console.info('Characteristic changed: ' + char.characteristicUuid);
    let value = new Uint8Array(char.characteristicValue);
    console.info('New value: ' + Array.from(value).join(','));
  }

  try {
    gattClient.on('BLECharacteristicChange', onCharacteristicChange);

    let characteristic: ble.BLECharacteristic = {
      serviceUuid: serviceUuid,
      characteristicUuid: characteristicUuid,
      characteristicValue: new ArrayBuffer(0),
      descriptors: [{
        serviceUuid: serviceUuid,
        characteristicUuid: characteristicUuid,
        descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB', // Client Characteristic Configuration
        descriptorValue: new ArrayBuffer(2)
      }]
    };

    // 使能通知能力
    gattClient.setCharacteristicChangeNotification(characteristic, true, (err: BusinessError) => {
      if (err) {
        console.error('Enable notification failed: ' + err.code);
        // 降级方案：使用轮询读取
        startPollingRead(serviceUuid, characteristicUuid);
      } else {
        console.info('Notification enabled successfully');
      }
    });
  } catch (err) {
    console.error('Enable notification exception: ' + (err as BusinessError).code);
  }
}
```

#### 2.8 断开连接

**示例代码**：
```typescript
function disconnect() {
  if (!gattClient) {
    console.error('GattClient not exist');
    return;
  }

  try {
    gattClient.disconnect();
    console.info('Disconnect request sent');
    
    // 取消订阅事件
    gattClient.off('BLEConnectionStateChange', onConnectionStateChange);
    gattClient.off('BLECharacteristicChange', onCharacteristicChange);
    
    // 关闭实例
    gattClient.close();
    gattClient = undefined;
    console.info('GattClient closed');
  } catch (err) {
    console.error('Disconnect failed: ' + (err as BusinessError).code);
  }
}
```

### 步骤3：服务端实现流程

#### 3.1 创建服务端实例

**示例代码**：
```typescript
let gattServer: ble.GattServer | undefined = undefined;

try {
  gattServer = ble.createGattServer();
  console.info('GattServer created successfully');
} catch (err) {
  console.error('Create GattServer failed: ' + (err as BusinessError).code);
  return;
}
```

#### 3.2 添加服务

**示例代码**：
```typescript
function addService() {
  let serviceUuid = '00001810-0000-1000-8000-00805F9B34FB';
  let characteristicUuid = '00001820-0000-1000-8000-00805F9B34FB';

  // 创建描述符
  let descriptors: Array<ble.BLEDescriptor> = [];
  let cccDescriptor: ble.BLEDescriptor = {
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    descriptorUuid: '00002902-0000-1000-8000-00805F9B34FB', // Client Characteristic Configuration
    descriptorValue: new ArrayBuffer(2)
  };
  descriptors.push(cccDescriptor);

  // 创建特征值
  let characteristics: Array<ble.BLECharacteristic> = [];
  let characteristic: ble.BLECharacteristic = {
    serviceUuid: serviceUuid,
    characteristicUuid: characteristicUuid,
    characteristicValue: new ArrayBuffer(2),
    descriptors: descriptors
  };
  characteristics.push(characteristic);

  // 创建服务
  let gattService: ble.GattService = {
    serviceUuid: serviceUuid,
    isPrimary: true,
    characteristics: characteristics,
    includeServices: []
  };

  try {
    if (gattServer) {
      gattServer.addService(gattService);
      console.info('Service added successfully: ' + serviceUuid);
    }
  } catch (err) {
    console.error('Add service failed: ' + (err as BusinessError).code);
  }
}
```

#### 3.3 订阅连接状态和读写事件

**示例代码**：
```typescript
let connectedDevice = '';

function onServerConnectionStateChange(state: ble.BLEConnectionChangeState) {
  console.info('Server connection state changed: device=' + state.deviceId + ', state=' + state.state);
  if (state.state === constant.ProfileConnectionState.STATE_CONNECTED) {
    connectedDevice = state.deviceId;
    console.info('Client connected: ' + connectedDevice);
  } else if (state.state === constant.ProfileConnectionState.STATE_DISCONNECTED) {
    console.info('Client disconnected: ' + state.deviceId);
    connectedDevice = '';
  }
}

function onCharacteristicRead(request: ble.CharacteristicReadRequest) {
  console.info('Characteristic read request: uuid=' + request.characteristicUuid);
  
  let response: ble.ServerResponse = {
    deviceId: request.deviceId,
    transId: request.transId,
    status: 0, // 成功
    offset: request.offset,
    value: characteristic.characteristicValue // 返回特征值数据
  };

  try {
    gattServer.sendResponse(response);
    console.info('Response sent successfully');
  } catch (err) {
    console.error('Send response failed: ' + (err as BusinessError).code);
  }
}

function onCharacteristicWrite(request: ble.CharacteristicWriteRequest) {
  console.info('Characteristic write request: uuid=' + request.characteristicUuid + ', needRsp=' + request.needRsp);
  
  // 更新特征值数据
  characteristic.characteristicValue = request.value;
  let value = new Uint8Array(request.value);
  console.info('New value: ' + Array.from(value).join(','));

  // 如果需要回复
  if (request.needRsp) {
    let response: ble.ServerResponse = {
      deviceId: request.deviceId,
      transId: request.transId,
      status: 0,
      offset: request.offset,
      value: new ArrayBuffer(0)
    };

    try {
      gattServer.sendResponse(response);
      console.info('Response sent successfully');
      
      // 特征值变化，发送通知
      sendNotification();
    } catch (err) {
      console.error('Send response failed: ' + (err as BusinessError).code);
    }
  }
}

try {
  if (gattServer) {
    gattServer.on('connectionStateChange', onServerConnectionStateChange);
    gattServer.on('characteristicRead', onCharacteristicRead);
    gattServer.on('characteristicWrite', onCharacteristicWrite);
    console.info('Events subscribed successfully');
  }
} catch (err) {
  console.error('Subscribe events failed: ' + (err as BusinessError).code);
}
```

#### 3.4 发送特征值变化通知

**示例代码**：
```typescript
function sendNotification() {
  if (!gattServer || !connectedDevice) {
    console.error('GattServer not ready or no connected device');
    return;
  }

  let notifyCharacteristic: ble.NotifyCharacteristic = {
    serviceUuid: '00001810-0000-1000-8000-00805F9B34FB',
    characteristicUuid: '00001820-0000-1000-8000-00805F9B34FB',
    characteristicValue: characteristic.characteristicValue,
    confirm: false // 发送通知（不需要确认）
  };

  try {
    gattServer.notifyCharacteristicChanged(connectedDevice, notifyCharacteristic, (err: BusinessError) => {
      if (err) {
        console.error('Send notification failed: ' + err.code);
      } else {
        console.info('Notification sent successfully');
      }
    });
  } catch (err) {
    console.error('Send notification exception: ' + (err as BusinessError).code);
  }
}
```

#### 3.5 关闭服务端

**示例代码**：
```typescript
function closeServer() {
  if (!gattServer) {
    console.error('GattServer not exist');
    return;
  }

  try {
    // 删除服务
    gattServer.removeService('00001810-0000-1000-8000-00805F9B34FB');
    
    // 取消订阅事件
    gattServer.off('connectionStateChange', onServerConnectionStateChange);
    gattServer.off('characteristicRead', onCharacteristicRead);
    gattServer.off('characteristicWrite', onCharacteristicWrite);
    
    // 关闭实例
    gattServer.close();
    gattServer = undefined;
    console.info('GattServer closed');
  } catch (err) {
    console.error('Close server failed: ' + (err as BusinessError).code);
  }
}
```

### 步骤4：错误处理

```typescript
function handleBluetoothError(error: BusinessError) {
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please grant ACCESS_BLUETOOTH permission');
      // 引导用户授权
      requestPermission();
      break;
    case 401:
      console.error('Invalid parameter. Check device address format or UUID format');
      // 校验参数格式
      validateParameters();
      break;
    case 801:
      console.error('Capability not supported. Device does not support BLE');
      // 提示不支持
      showUnsupportedMessage();
      break;
    case 2900001:
      console.error('Service stopped. Bluetooth service unavailable');
      // 尝试重启蓝牙
      restartBluetooth();
      break;
    case 2900003:
      console.error('Bluetooth disabled. Please enable Bluetooth');
      // 引导用户开启蓝牙
      enableBluetooth();
      break;
    case 2900099:
      console.error('Operation failed. Generic error');
      // 提供重试机制
      retryOperation();
      break;
    default:
      console.error('Unknown error: ' + error.code + ', ' + error.message);
      // 记录错误日志
      logError(error);
  }
}
```

### 步骤5：降级处理

```typescript
// 连接失败降级方案
function handleConnectFailure() {
  console.warn('Connect failed, try fallback solution');
  
  // 方案1：检查设备状态
  checkDeviceStatus();
  
  // 方案2：提示用户重试
  showRetryDialog();
  
  // 方案3：使用其他通信方式
  if (isAlternativeAvailable()) {
    switchToAlternative();
  }
}

// 服务发现失败降级方案
function handleServiceDiscoveryFailure() {
  console.warn('Service discovery failed, disconnecting');
  disconnect();
  showServiceNotFoundMessage();
}

// 特征值变化通知使能失败降级方案
function handleNotificationEnableFailure(serviceUuid: string, characteristicUuid: string) {
  console.warn('Notification enable failed, use polling read instead');
  
  // 使用轮询读取替代
  let pollingInterval = setInterval(() => {
    readCharacteristic(serviceUuid, characteristicUuid);
  }, 1000); // 每秒读取一次
  
  // 存储轮询定时器，以便后续停止
  pollingIntervals.push(pollingInterval);
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请ohos.permission.ACCESS_BLUETOOTH权限 |
| 401 | Invalid parameter | 检查设备地址格式（XX:XX:XX:XX:XX:XX）和UUID格式 |
| 801 | Capability not supported | 检查设备是否支持BLE功能 |
| 2900001 | Service stopped | 尝试重启蓝牙服务 |
| 2900003 | Bluetooth disabled | 引导用户开启蓝牙 |
| 2900099 | Operation failed | 检查操作流程，提供重试机制 |
| 2900100 | Invalid UUID | 检查UUID格式是否符合标准 |
| 2900101 | Invalid adapter state | 睡眠蓝牙适配器状态后再操作 |
| 2900104 | GATT operation not permitted | 检查服务端是否支持该操作 |
| 2900105 | GATT operation not supported | 特征值不支持该操作类型 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "API 10+",
    "@kit.BasicServicesKit": "API 10+"
  }
}
```

### 环境要求
- HarmonyOS API version：10及以上
- 设备支持：支持BLE功能的设备
- 权限要求：ohos.permission.ACCESS_BLUETOOTH
- 蓝牙状态：蓝牙必须开启

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：确保项目配置支持HarmonyOS API 10+，检查build-profile.json5中的compileApiVersion

**问题2：类型定义错误**
```
Error: Property 'createGattClientDevice' does not exist on type 'ble'
```
**解决方法**：确保正确导入模块`import { ble } from '@kit.ConnectivityKit'`

**问题3：权限未配置**
```
Error: Permission denied (201)
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

## 常见问题与解决方法

### Q1：连接失败怎么办？
**原因**：设备地址错误、蓝牙未开启、权限未授予、服务端未发送广播
**解决方法**：
- 校验设备地址格式
- 检查蓝牙开关状态
- 申请必要权限
- 确认服务端已发送BLE广播
- 提供重试机制

### Q2：服务发现失败？
**原因**：连接未建立、服务端未注册服务、服务UUID不存在
**解决方法**：
- 确保连接状态为STATE_CONNECTED
- 等待连接成功后再进行服务发现
- 检查服务端是否已添加所需服务
- 提示用户服务端不支持所需功能

### Q3：读取特征值超时？
**原因**：特征值不存在、服务端未响应、操作超时
**解决方法**：
- 确认特征值包含在服务发现结果中
- 检查服务端是否订阅了读取事件
- 设置合理的超时时间（建议5秒）
- 提供取消操作和重试选项

### Q4：特征值变化通知不生效？
**原因**：未订阅事件、未使能通知能力、特征值不支持通知
**解决方法**：
- 先订阅BLECharacteristicChange事件
- 调用setCharacteristicChangeNotification使能
- 检查特征值包含Client Characteristic Configuration描述符
- 使用轮询读取作为降级方案

### Q5：断开连接后资源未释放？
**原因**：未调用close方法、未取消订阅事件
**解决方法**：
- 断开连接后必须调用close方法
- 取消所有已订阅的事件
- 确保GattClientDevice/GattServer实例设置为undefined
- 检查是否有未清理的定时器或回调

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "deviceAddress": "XX:XX:XX:XX:XX:XX",
  "connectionState": "STATE_CONNECTED",
  "servicesDiscovered": [
    {
      "serviceUuid": "00001810-0000-1000-8000-00805F9B34FB",
      "characteristics": [
        {
          "characteristicUuid": "00001820-0000-1000-8000-00805F9B34FB",
          "properties": ["read", "write", "notify"]
        }
      ]
    }
  ],
  "operationsCompleted": [
    "connect",
    "discoverServices",
    "readCharacteristic",
    "writeCharacteristic",
    "enableNotification"
  ],
  "apiUsed": [
    "ble.createGattClientDevice",
    "gattClient.connect",
    "gattClient.getServices",
    "gattClient.readCharacteristicValue",
    "gattClient.writeCharacteristicValue",
    "gattClient.setCharacteristicChangeNotification",
    "gattClient.disconnect",
    "gattClient.close"
  ]
}
```

## 参考文档

- [API开发指南](references/api-guide.md)
- [蓝牙BLE模块API参考](references/js-apis-bluetooth-ble.md)
- [蓝牙Constant模块API参考](references/js-apis-bluetooth-constant.md)

相关术语请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/terminology
权限申请请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions
用户授权请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization
BLE扫描和广播请参考：https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide

## 完整示例代码

- [客户端完整示例](assets/gatt-client-example.ets)
- [服务端完整示例](assets/gatt-server-example.ets)
- [配置文件示例](assets/module.json5)

## 测试用例

### 正向测试用例
- [客户端连接和数据传输测试](tests/test_gatt_client_positive.ets)：测试正常连接、服务发现、读写操作
- [服务端服务和通知测试](tests/test_gatt_server_positive.ets)：测试正常服务注册、读写响应、通知发送

### 边界测试用例
- [最大连接数测试](tests/test_max_connections.ets)：测试同时7个设备连接
- [数据长度边界测试](tests/test_data_length.ets)：测试512字节特征值读写
- [连接超时测试](tests/test_connection_timeout.ets)：测试30秒连接超时处理

### 异常测试用例
- [权限缺失测试](tests/test_permission_denied.ets)：测试未申请权限时的错误处理
- [设备地址错误测试](tests/test_invalid_device_address.ets)：测试设备地址格式错误的处理
- [服务不存在测试](tests/test_service_not_found.ets)：测试所需服务不存在时的降级处理
- [连接失败测试](tests/test_connection_failure.ets)：测试连接失败时的重试和降级机制
- [蓝牙关闭测试](tests/test_bluetooth_disabled.ets)：测试蓝牙关闭状态下的错误处理