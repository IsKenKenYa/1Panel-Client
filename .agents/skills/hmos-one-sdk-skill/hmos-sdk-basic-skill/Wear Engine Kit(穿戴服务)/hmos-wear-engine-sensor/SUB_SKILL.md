---
name: hmos-wear-engine-sensor
description: 获取穿戴设备传感器列表、订阅传感器数据上报、取消订阅传感器数据，支持ACC/GYRO/MAG/HR/PPG/ECG传感器类型，需要申请权限并获得用户授权，设备需处于连接状态，适用于健康监测、运动追踪场景
---

# 穿戴设备传感器获取技能

## 功能描述

本技能提供穿戴设备传感器数据的获取和管理能力。通过Wear Engine Kit实现手机侧应用与穿戴设备传感器交互，包括:

- **获取传感器列表**: 查询穿戴设备上可用的传感器信息(名称、ID、类型、采样周期、分辨率等)
- **订阅传感器数据**: 持续获取指定传感器的实时数据上报(加速度、陀螺仪、磁力、心率、PPG、ECG等)
- **取消订阅传感器**: 停止指定传感器的数据上报

**支持的传感器类型**:
- **运动传感器**: ACC(加速度)、GYRO(陀螺仪)、MAG(磁力)
- **人体传感器**: HR(心率)、PPG(光电容积脉搏波)、ECG(心电图)

**数据上报特点**:
- 不同传感器有不同的采集周期和上报周期
- 数据包含时间戳和UTC时间戳(部分传感器支持)
- 多通道传感器(PPG、ECG)通过channel字段区分通道
- 数据格式各异,需根据传感器类型解析

## 使用场景

### 触发词
- "获取穿戴设备传感器" - 获取传感器列表
- "订阅传感器数据" - 实时获取传感器数据
- "取消订阅传感器" - 停止数据上报
- "加速度传感器" - ACC传感器操作
- "心率传感器" - HR传感器操作
- "陀螺仪传感器" - GYRO传感器操作
- "心电图传感器" - ECG传感器操作
- "穿戴设备传感器获取" - 整体传感器功能

### 能做
- 获取已连接穿戴设备的可用传感器列表及详细信息
- 订阅指定传感器的实时数据上报,接收连续数据流
- 取消订阅传感器数据上报,停止数据接收
- 处理传感器数据上报回调,解析不同传感器的数据格式
- 处理传感器错误状态(未佩戴、引线脱落、手动关闭、占用、不支持等)

### 绝不做
- 不处理未授权的传感器访问(需要先申请权限并获得用户授权)
- 不在设备未连接时执行传感器操作
- 不处理超出Wear Engine Kit范围的传感器请求
- 不修改传感器硬件配置参数
- 不替代穿戴设备侧应用的数据采集逻辑

### 补充
- **权限要求**: 
  - 运动传感器(ACC/GYRO/MAG): 需申请MOTION_SENSOR权限
  - 人体传感器(HR/PPG/ECG): 需申请HEALTH_SENSOR权限(受限开放,需在开发者联盟申请)
- **前置条件**:
  - 穿戴设备和华为运动健康App需处于连接状态
  - 用户已授予对应的传感器权限
  - 开发者已在开发者联盟申请Wear Engine服务并获批相应权限
- **设备连接检查**: 可调用getConnectedDevices方法检查设备是否在线
- **数据时间戳**: 建议根据时间戳进行数据对齐
- **设备断线处理**: 设备连接断开时自动停止数据上报,重连后需主动重新订阅

## 调用规范和规则

### 输入约束
- **设备标识**: deviceRandomId必须为有效的设备随机ID(string类型)
- **传感器类型**: type必须为有效的SensorType枚举值(ACC/GYRO/MAG/HR/PPG/ECG)
- **回调函数**: callback必须为有效的Callback<SensorResult>类型,且生命周期需延长至取消订阅时
- **权限校验**: 必须先申请并获得用户授权对应的传感器权限(HEALTH_SENSOR或MOTION_SENSOR)

### 执行约束
- **设备连接**: 执行前必须确保设备处于连接状态
- **传感器存在**: 订阅前应先查询传感器列表确认目标传感器存在
- **订阅生命周期**: 回调函数对象需保持引用直至取消订阅完成
- **数据上报持续**: 订阅成功后数据会持续上报,需要主动调用取消订阅接口停止

### 内容约束
- **禁止生成**: 不生成传感器硬件配置代码
- **禁止高危操作**: 不直接操作传感器硬件寄存器
- **禁止跨设备操作**: 不在未授权设备上执行传感器操作
- **禁止数据篡改**: 不修改传感器原始数据内容

### 降级约束
- **设备未连接**: 提示用户检查设备连接状态,引导用户打开华为运动健康App重新连接
- **权限未授权**: 提示用户申请权限,调用requestAuthorization接口申请授权
- **传感器不支持**: 查询传感器列表后若不存在目标传感器,提示用户设备不支持该传感器类型
- **网络错误**: 检查网络连接状态,稍后重试或引导用户检查网络设置

## 调用流程和步骤

### 步骤1: 准备阶段 - 权限申请和设备连接检查

**前置校验**:
1. 检查应用是否已在开发者联盟申请Wear Engine服务并获得相应权限
2. 检查是否已申请并获得用户授权(HEALTH_SENSOR或MOTION_SENSOR权限)
3. 检查穿戴设备是否处于连接状态
4. 检查设备是否支持Sensor能力集

**参数准备**:
```typescript
// 导入必要的模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

// 获取Context上下文(在UIAbility中使用)
let context = this.getUIContext().getHostContext();

// 获取DeviceClient和SensorClient
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(context);
let sensorClient: wearEngine.SensorClient = wearEngine.getSensorClient(context);

// 获取已连接设备列表
let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();

// 检查是否有已连接设备
if (devices.length === 0) {
  console.error('No connected device found');
  return;
}

// 选择目标设备(假设选择第一个设备)
let targetDevice: wearEngine.Device = devices[0];
```

### 步骤2: 获取传感器列表

**示例代码**:
```typescript
// 获取指定设备的传感器列表
sensorClient.getSensorList(targetDevice.randomId).then((sensorList) => {
  console.info(`Succeeded in getting sensor list. Total sensors: ${sensorList.length}`);
  
  // 遍历传感器列表,打印传感器信息
  sensorList.forEach((sensor, index) => {
    console.info(`Sensor[${index}]: name=${sensor.name}, id=${sensor.id}, type=${sensor.type}, accuracy=${sensor.accuracy}, resolution=${sensor.resolution}`);
  });
  
  // 检查是否存在目标传感器类型
  let hasAccelerometer = sensorList.some(sensor => sensor.type === wearEngine.SensorType.ACCELEROMETER);
  if (!hasAccelerometer) {
    console.warn('Target sensor type not found in device');
  }
  
}).catch((error: BusinessError) => {
  console.error(`Failed to get sensor list. Code: ${error.code}, Message: ${error.message}`);
  
  // 错误处理
  handleSensorError(error);
});
```

### 步骤3: 订阅传感器数据上报

**示例代码**:
```typescript
// 定义传感器数据回调函数
let sensorDataCallback = (sensorResult: wearEngine.SensorResult) => {
  // 检查是否有错误码
  if (sensorResult.errorCode) {
    console.error(`Sensor error occurred. ErrorCode: ${sensorResult.errorCode}`);
    handleSensorErrorCode(sensorResult.errorCode);
    return;
  }
  
  // 处理正常上报的传感器数据
  if (sensorResult.data && sensorResult.data.length > 0) {
    sensorResult.data.forEach((sensorData, index) => {
      console.info(`SensorData[${index}]: type=${sensorData.sensorType}, timestamp=${sensorData.timestamp}, channel=${sensorData.channel}, data=${sensorData.data}`);
      
      // 根据传感器类型解析数据格式
      parseSensorData(sensorData);
    });
  }
};

// 订阅加速度传感器数据上报
sensorClient.subscribeSensor(targetDevice.randomId, wearEngine.SensorType.ACCELEROMETER, sensorDataCallback).then(() => {
  console.info(`Succeeded in subscribing sensor. Type: ACCELEROMETER`);
  
}).catch((error: BusinessError) => {
  console.error(`Failed to subscribe sensor. Code: ${error.code}, Message: ${error.message}`);
  handleSensorError(error);
});

// 注意: 保持sensorDataCallback的引用,后续取消订阅时需要使用同一个回调对象
```

### 步骤4: 处理传感器数据

**数据解析示例**:
```typescript
// 根据传感器类型解析数据
function parseSensorData(sensorData: wearEngine.SensorData): void {
  switch (sensorData.sensorType) {
    case wearEngine.SensorType.ACCELEROMETER:
      // ACC数据: 1次上报10组,每组3个数据(x,y,z轴加速度),单位m/s^2
      console.info(`Accelerometer data: ${sensorData.data.length} values, unit: m/s^2`);
      if (sensorData.data.length === 30) {
        // 解析10组数据
        for (let i = 0; i < 10; i++) {
          let x = sensorData.data[i * 3];
          let y = sensorData.data[i * 3 + 1];
          let z = sensorData.data[i * 3 + 2];
          console.info(`ACC[${i}]: x=${x}, y=${y}, z=${z}`);
        }
      }
      break;
      
    case wearEngine.SensorType.HEART_RATE:
      // HR数据: 1次上报1个数据(心率值),单位次/分钟
      if (sensorData.data.length > 0) {
        let heartRate = sensorData.data[0];
        console.info(`Heart rate: ${heartRate} bpm`);
      }
      break;
      
    case wearEngine.SensorType.GYROSCOPE:
      // GYRO数据: 1次上报10组,每组3个数据(x,y,z轴角速度),单位70mdps/LSB
      console.info(`Gyroscope data: ${sensorData.data.length} values`);
      break;
      
    case wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY:
      // PPG数据: 多通道传感器,通过channel字段区分
      console.info(`PPG data: channel=${sensorData.channel}, values=${sensorData.data.length}`);
      break;
      
    case wearEngine.SensorType.ELECTROCARDIOGRAPHY:
      // ECG数据: 多通道传感器,100ms上报50包数据,单位nV
      console.info(`ECG data: channel=${sensorData.channel}, values=${sensorData.data.length}`);
      break;
      
    default:
      console.warn(`Unknown sensor type: ${sensorData.sensorType}`);
  }
}
```

### 步骤5: 取消订阅传感器数据上报

**示例代码**:
```typescript
// 取消订阅加速度传感器数据上报
// 注意: 必须使用订阅时的同一个回调函数对象(sensorDataCallback)
sensorClient.unsubscribeSensor(targetDevice.randomId, wearEngine.SensorType.ACCELEROMETER, sensorDataCallback).then(() => {
  console.info(`Succeeded in unsubscribing sensor. Type: ACCELEROMETER`);
  
}).catch((error: BusinessError) => {
  console.error(`Failed to unsubscribe sensor. Code: ${error.code}, Message: ${error.message}`);
  handleSensorError(error);
});
```

### 步骤6: 错误处理和降级处理

**错误处理代码**:
```typescript
// 处理传感器操作错误
function handleSensorError(error: BusinessError): void {
  switch (error.code) {
    case 1008500001:
      console.error('Network error. Please check network connection.');
      // 降级方案: 稍后重试或引导用户检查网络
      break;
      
    case 1008500002:
      console.error('No device is bound. Please bind device first.');
      // 降级方案: 引导用户在华为运动健康App绑定设备
      break;
      
    case 1008500003:
      console.error('Device disconnected. Please reconnect device.');
      // 降级方案: 引导用户重新连接设备
      break;
      
    case 1008500004:
      console.error('App has not applied for Wear Engine service.');
      // 降级方案: 引导开发者申请Wear Engine服务
      break;
      
    case 1008500006:
      console.error('User privacy is not agreed.');
      // 降级方案: 引导用户同意隐私协议
      break;
      
    case 1008500010:
      console.error('Device ID is invalid.');
      // 降级方案: 重新获取设备列表获取正确的deviceRandomId
      break;
      
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}

// 处理传感器特定错误码
function handleSensorErrorCode(errorCode: number): void {
  switch (errorCode) {
    case 300:
      console.error('Device not being worn. Please wear the device.');
      break;
      
    case 301:
      console.error('Device lead off. Please check device connection.');
      break;
      
    case 302:
      console.error('Sensor turned off manually.');
      break;
      
    case 303:
      console.error('Sensor occupied by other app.');
      break;
      
    case 304:
      console.error('Sensor not supported on this device.');
      break;
      
    default:
      console.error(`Unknown sensor error: ${errorCode}`);
  }
}
```

## 错误码说明

### 通用错误码

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因: 1.必填参数未指定 2.参数类型错误 3.参数校验失败 | 检查参数类型和取值范围,确保deviceRandomId、type、callback参数正确 |
| 801 | 能力不支持 | 检查设备是否支持Wear Engine能力集,调用canIUse接口判断 |
| 1008500001 | 网络错误。网络不可用 | 检查网络连接状态,稍后重试或引导用户检查网络设置 |
| 1008500002 | 无设备绑定 | 引导用户在华为运动健康App绑定设备 |
| 1008500003 | 设备断开连接 | 引导用户重新连接设备,可调用getConnectedDevices检查连接状态 |
| 1008500004 | 应用未申请Wear Engine服务 | 引导开发者申请Wear Engine服务 |
| 1008500005 | 华为账号未授权 | 引导用户使用华为账号登录并授权 |
| 1008500006 | 用户隐私未同意 | 引导用户同意隐私协议 |
| 1008500007 | 设备能力不支持 | 检查设备是否支持Sensor能力集,调用isWearEngineCapabilitySupported检查 |
| 1008500008 | 账号错误。用户未使用华为账号登录 | 引导用户使用华为账号登录 |
| 1008500009 | 账号错误。无法获取华为账号信息 | 检查账号状态,重新登录华为账号 |
| 1008500010 | 设备ID无效 | 重新获取设备列表,使用正确的deviceRandomId |
| 1008500012 | 同类型回调函数过多 | 减少订阅数量,先取消已有订阅再重新订阅 |
| 1008509999 | 内部错误 | 重试操作,如持续失败请联系技术支持 |

### 传感器特定错误码(SensorErrorCode)

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 300 | 设备未佩戴 | 提示用户佩戴设备 |
| 301 | 设备引线脱落 | 提示用户检查设备连接状态(ECG传感器特有) |
| 302 | 传感器被手动关闭 | 提示用户开启传感器 |
| 303 | 传感器被占用 | 其他应用正在使用该传感器,等待或引导用户关闭占用应用 |
| 304 | 传感器不支持 | 该设备不支持该传感器类型,提示用户更换设备或选择其他传感器 |

## 编译和修复问题

### 依赖声明

```json
{
  "dependencies": {
    "@kit.WearEngine": "^5.0.0"
  }
}
```

### 环境要求

- **HarmonyOS SDK**: 最低版本5.0.0(12)
- **开发模型**: Stage模型(不支持FA模型)
- **设备类型**: Phone或Tablet(其他设备返回801错误码)
- **系统能力**: SystemCapability.Health.WearEngine

### 常见编译问题

**问题1: 导入wearEngine模块失败**

```
Error: Cannot find module '@kit.WearEngine'
```

**解决方法**:
- 确保HarmonyOS SDK版本不低于5.0.0(12)
- 在module.json5中声明依赖:
```json
{
  "module": {
    "dependencies": {
      "@kit.WearEngine": "^5.0.0"
    }
  }
}
```

**问题2: Context类型不匹配**

```
Error: Parameter error. Incorrect parameter types.
```

**解决方法**:
- 确保传入的context是UIAbilityContext或其他包含connectServiceExtensionAbility方法的Context
- 在UIAbility中使用`this.context`获取Context
- 在UI组件中使用`this.getUIContext().getHostContext()`获取Context

**问题3: 回调函数对象不匹配导致取消订阅失败**

```
Error: Failed to unsubscribe sensor. The callback is not registered.
```

**解决方法**:
- 取消订阅时必须传入订阅时使用的同一个回调函数对象
- 不要在订阅和取消订阅之间重新定义回调函数
- 保持回调函数对象的引用:
```typescript
// 正确做法: 定义回调函数并保持引用
let myCallback = (result: wearEngine.SensorResult) => { ... };

// 订阅时使用myCallback
sensorClient.subscribeSensor(deviceId, type, myCallback);

// 取消订阅时使用同一个myCallback对象
sensorClient.unsubscribeSensor(deviceId, type, myCallback);

// 错误做法: 重新定义回调函数
sensorClient.unsubscribeSensor(deviceId, type, (result) => { ... }); // 这会失败!
```

**问题4: 权限未授予导致接口调用失败**

```
Error: User privacy is not agreed. (1008500006)
```

**解决方法**:
- 调用requestAuthorization接口申请权限
- 在开发者联盟申请HEALTH_SENSOR或MOTION_SENSOR权限
- 确保用户授予了对应的传感器权限

## 常见问题与解决方法

### Q1: 如何申请传感器权限?

**原因**: 人体传感器(HEALTH_SENSOR)权限受限开放,运动传感器(MOTION_SENSOR)需要申请

**解决方法**:
- 步骤1: 在开发者联盟申请接入Wear Engine服务并获得相应权限审批
- 步骤2: 调用AuthClient.requestAuthorization接口向用户申请权限授权:
```typescript
let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(context);
let request: wearEngine.AuthorizationRequest = {
  permissions: [wearEngine.Permission.HEALTH_SENSOR] // 或 MOTION_SENSOR
};
authClient.requestAuthorization(request).then(result => {
  console.info(`Authorized permissions: ${result.permissions}`);
});
```

### Q2: 如何检查设备是否支持特定传感器?

**原因**: 不同穿戴设备支持的传感器类型可能不同

**解决方法**:
- 步骤1: 查询传感器列表确认是否存在目标传感器
- 步骤2: 检查设备是否支持Sensor能力集:
```typescript
device.isWearEngineCapabilitySupported(wearEngine.WearEngineCapability.SENSOR).then(isSupport => {
  if (isSupport) {
    console.info('Device supports sensor capability');
    // 继续传感器操作
  } else {
    console.warn('Device does not support sensor capability');
  }
});
```

### Q3: 设备断线后如何恢复传感器订阅?

**原因**: 设备连接断开时自动停止传感器数据上报

**解决方法**:
- 步骤1: 订阅设备连接状态变化事件:
```typescript
let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(context);
monitorClient.subscribeEvent(deviceId, wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED, (eventData) => {
  if (eventData.data.code === 2) { // 连接成功
    console.info('Device reconnected');
    // 重新订阅传感器
    sensorClient.subscribeSensor(deviceId, sensorType, callback);
  }
});
```
- 步骤2: 设备重连后主动调用subscribeSensor重新订阅

### Q4: 如何解析ACC/GYRO传感器的有符号Short数据?

**原因**: ACC、GYRO原始数据值范围为有符号Short,上报后为无符号Short需转换

**解决方法**:
```typescript
function convertUnsignedToSigned(value: number): number {
  // 无符号Short范围: 0-65535
  // 有符号Short范围: -32768 to 32767
  if (value > 32767) {
    return value - 65536;
  }
  return value;
}

// 使用示例
let accData = sensorData.data;
for (let i = 0; i < accData.length; i++) {
  accData[i] = convertUnsignedToSigned(accData[i]);
}
```

### Q5: 多通道传感器(PPG/ECG)数据如何区分通道?

**原因**: PPG、ECG是多通道传感器,需要通过channel字段区分

**解决方法**:
- 检查SensorData的channel字段,大于0的整数表示通道ID
- 不同通道代表不同的采集源:
  - PPG: GREEN、RED、IR三路数据
  - ECG: 一路数据,不区分左右手
```typescript
sensorResult.data.forEach(sensorData => {
  if (sensorData.sensorType === wearEngine.SensorType.PHOTOPLETHYSMOGRAPHY) {
    console.info(`PPG channel ${sensorData.channel}: ${sensorData.data.length} values`);
  }
});
```

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "deviceRandomId": "string",
  "sensorType": "SensorType",
  "operationType": "getSensorList|subscribeSensor|unsubscribeSensor",
  "sensorCount": "number",
  "sensorList": [
    {
      "name": "string",
      "id": "number",
      "type": "SensorType",
      "accuracy": "number",
      "resolution": "number"
    }
  ],
  "subscriptionStatus": "active|inactive",
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "wearEngine.getSensorClient",
    "sensorClient.getSensorList",
    "sensorClient.subscribeSensor",
    "sensorClient.unsubscribeSensor"
  ],
  "timestamp": "number"
}
```

## 参考文档

- [API开发指南 - 穿戴设备传感器获取](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/device_sensor)
- [API参考说明 - wearEngine(穿戴设备能力开放)](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)

## 完整示例代码

- [ArkTS示例 - 获取传感器列表](assets/get_sensor_list.ets)
- [ArkTS示例 - 订阅传感器数据](assets/subscribe_sensor.ets)
- [ArkTS示例 - 取消订阅传感器](assets/unsubscribe_sensor.ets)
- [ArkTS示例 - 完整传感器管理](assets/sensor_manager_complete.ets)

## 测试用例

### 正向测试用例
- [获取传感器列表成功](tests/test_get_sensor_list_positive.py): 测试正常获取已连接设备的传感器列表
- [订阅ACC传感器成功](tests/test_subscribe_acc_positive.py): 测试正常订阅加速度传感器数据
- [订阅HR传感器成功](tests/test_subscribe_hr_positive.py): 测试正常订阅心率传感器数据
- [取消订阅传感器成功](tests/test_unsubscribe_positive.py): 测试正常取消订阅传感器

### 边界测试用例
- [设备无传感器](tests/test_no_sensor_boundary.py): 测试设备无可用传感器时的处理
- [多通道传感器数据解析](tests/test_multi_channel_boundary.py): 测试PPG/ECG多通道数据解析
- [高频数据上报](tests/test_high_frequency_boundary.py): 测试高频传感器数据上报处理

### 异常测试用例
- [设备未连接](tests/test_device_disconnected_exception.py): 测试设备断开时的错误处理
- [权限未授权](tests/test_permission_denied_exception.py): 测试权限未授予时的错误处理
- [传感器不支持](tests/test_sensor_not_supported_exception.py): 测试设备不支持传感器时的错误处理
- [回调函数对象不匹配](tests/test_callback_mismatch_exception.py): 测试取消订阅时回调函数不匹配的错误处理