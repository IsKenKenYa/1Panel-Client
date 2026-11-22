---
name: hmos-wear-engine-kit-device-sensor
description: 获取穿戴设备传感器数据+支持ACC/GYRO/MAG/HR/PPG/ECG传感器+需申请HEALTH_SENSOR或MOTION_SENSOR权限+适用于健康监测、运动追踪场景
---

# 穿戴设备传感器获取技能

## 功能描述

手机侧应用通过Wear Engine获取穿戴设备上的传感器信息，支持获取传感器列表、订阅传感器数据上报、取消订阅等操作。支持加速度(ACC)、陀螺仪(GYRO)、磁力(MAG)、心率(HR)、光电容积脉搏波(PPG)、心电图(ECG)等多种传感器类型。

**支持的传感器类型**：
- **运动传感器**（需申请MOTION_SENSOR权限）：加速度传感器(ACC)、陀螺仪传感器(GYRO)、磁力传感器(MAG)
- **人体传感器**（需申请HEALTH_SENSOR权限，受限开放）：心率传感器(HR)、光电容积脉搏波传感器(PPG)、心电图传感器(ECG)

**关键特性**：
- 传感器数据实时上报，支持多通道传感器（PPG、ECG）
- 数据包含时间戳，建议根据时间戳进行数据对齐
- 设备断开连接时自动停止传感器数据上报

## 使用场景

### 触发词
- "获取穿戴设备传感器" - 获取传感器列表
- "订阅传感器数据" - 订阅指定传感器数据上报
- "取消传感器订阅" - 取消传感器数据上报
- "ACC数据" - 加速度传感器数据
- "GYRO数据" - 陀螺仪传感器数据
- "MAG数据" - 磁力传感器数据
- "心率数据" - 心率传感器数据
- "PPG数据" - 光电容积脉搏波数据
- "ECG数据" - 心电图数据
- "传感器列表" - 查询可用传感器

### 能做
- 获取穿戴设备上可用的传感器列表（名称、ID、上报周期等参数）
- 订阅指定传感器的数据上报，实时接收传感器数据
- 取消订阅传感器数据上报
- 处理多通道传感器数据（通过channel字段区分）
- 根据时间戳进行数据对齐和同步

### 绝不做
- 不支持获取未授权的传感器数据（必须先申请相应权限并获得用户授权）
- 不支持非穿戴设备（仅支持已连接的手表、手环等穿戴设备）
- 不支持未连接设备的传感器访问（设备必须在线且已连接）
- 不支持人体传感器用于非专业研究机构（人体传感器功能仅限专业研究机构使用）

### 补充
- **权限要求**：使用传感器相关接口前，必须向用户申请获取对应权限的授权
  - ECG、PPG、HR传感器需要申请HEALTH_SENSOR权限（受限开放，需在开发者联盟申请）
  - ACC、GYRO、MAG传感器需要申请MOTION_SENSOR权限
- **设备连接要求**：穿戴设备和华为运动健康App必须处于连接状态
- **人体传感器限制**：人体传感器功能仅限专业研究机构使用
- **数据格式**：不同传感器上报的数据格式不同，详见[穿戴设备传感器数据格式及样例](#穿戴设备传感器数据格式及样例)
- **断线处理**：设备连接状态断开时自动停止传感器数据上报，需主动订阅设备连接状态，设备重新连接后需重新调用订阅方法

## 调用规范和规则

### 输入约束
- **设备要求**：必须提供有效的设备随机标识符(deviceRandomId)
- **传感器类型**：必须指定有效的传感器类型(SensorType枚举值)
- **回调函数**：订阅和取消订阅时必须使用同一个回调函数对象
- **权限申请**：必须先申请相应权限(HEALTH_SENSOR或MOTION_SENSOR)并获得用户授权

### 执行约束
- **最大订阅数量**：同一类型传感器的回调函数数量有限制，避免过多回调
- **数据上报周期**：传感器根据各自的采集周期和上报周期自动上报数据
- **网络要求**：需要网络连接正常，设备在线且已连接
- **异步调用**：所有API使用Promise异步回调，需正确处理异步结果

### 内容约束
- **禁止未授权访问**：禁止尝试获取未授权的传感器数据
- **禁止伪造设备ID**：禁止使用无效或伪造的设备随机标识符
- **禁止忽略错误处理**：必须捕获并处理所有可能的错误码
- **禁止内存泄漏**：取消订阅时必须传入与订阅时相同的回调函数对象，避免回调函数无法释放

### 降级约束
- **网络失败**：提示用户检查网络连接和设备在线状态，建议调用getConnectedDevices验证设备连接
- **设备断开**：订阅设备连接状态变化事件，设备重新连接后主动重新订阅传感器
- **权限不足**：提示用户申请相应权限授权，引导用户进入权限设置页面
- **传感器不支持**：查询传感器列表确认设备是否支持目标传感器，不支持时提示用户更换设备或传感器类型

## 调用流程和步骤

### 步骤1：准备阶段 - 查询已连接设备和申请权限

**前置校验**：
1. 检查设备是否支持WearEngine系统能力：使用canIUse接口判断
2. 获取已连接的穿戴设备列表：调用getConnectedDevices方法
3. 从设备列表中选定目标设备：获取设备的randomId
4. 申请传感器权限：调用requestAuthorization申请HEALTH_SENSOR或MOTION_SENSOR权限

**示例代码**：
```typescript
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';

// 检查系统能力是否支持
if (!canIUse('SystemCapability.Health.WearEngine')) {
  console.error('当前设备不支持WearEngine能力');
  return;
}

// 获取设备客户端
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(this.getUIContext().getHostContext());

// 获取已连接设备列表
let devices: wearEngine.Device[] = await deviceClient.getConnectedDevices();
if (devices.length === 0) {
  console.error('没有已连接的穿戴设备');
  return;
}

// 从设备列表中选取目标设备（示例取第一个设备）
let targetDevice: wearEngine.Device = devices[0];

// 申请传感器权限
let authClient: wearEngine.AuthClient = wearEngine.getAuthClient(this.getUIContext().getHostContext());
let request: wearEngine.AuthorizationRequest = {
  permissions: [wearEngine.Permission.MOTION_SENSOR]  // 或 HEALTH_SENSOR
};

try {
  let authResponse: wearEngine.AuthorizationResponse = await authClient.requestAuthorization(request);
  if (!authResponse.permissions.includes(wearEngine.Permission.MOTION_SENSOR)) {
    console.error('用户未授权传感器权限');
    return;
  }
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`申请权限失败. Code: ${err.code}, Message: ${err.message}`);
  return;
}
```

### 步骤2：获取SensorClient客户端和传感器列表

**示例代码**：
```typescript
// 获取SensorClient客户端
let sensorClient: wearEngine.SensorClient = wearEngine.getSensorClient(this.getUIContext().getHostContext());

// 获取指定设备的传感器列表
try {
  let sensorList: wearEngine.Sensor[] = await sensorClient.getSensorList(targetDevice.randomId);
  console.info(`成功获取传感器列表，共${sensorList.length}个传感器`);
  
  // 打印传感器信息
  sensorList.forEach((sensor, idx, arr) => {
    console.info(`传感器${idx}: 名称=${sensor.name}, ID=${sensor.id}, 类型=${sensor.type}, 采样周期=${sensor.accuracy}ms`);
  });
  
  return sensorList;
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`获取传感器列表失败. Code: ${err.code}, Message: ${err.message}`);
  return [];
}
```

### 步骤3：订阅传感器数据上报

**示例代码**：
```typescript
// 查找目标传感器（示例：加速度传感器）
let targetSensorType: wearEngine.SensorType = wearEngine.SensorType.ACCELEROMETER;
let hasTargetSensor: boolean = false;

sensorList.forEach((sensor, idx, arr) => {
  if (sensor.type === targetSensorType) {
    hasTargetSensor = true;
  }
});

if (!hasTargetSensor) {
  console.error(`设备不支持${targetSensorType}传感器`);
  return;
}

// 定义回调函数（注意：必须在订阅和取消订阅时使用同一个函数对象）
let sensorCallback = (sensorResult: wearEngine.SensorResult) => {
  if (sensorResult.errorCode) {
    console.error(`传感器错误码: ${sensorResult.errorCode}`);
    return;
  }
  
  if (sensorResult.data && sensorResult.data.length > 0) {
    sensorResult.data.forEach((sensorData, idx, arr) => {
      console.info(`传感器类型: ${sensorData.sensorType}, 时间戳: ${sensorData.timestamp}, 数据: ${sensorData.data}`);
      
      // 处理多通道传感器数据
      if (sensorData.channel) {
        console.info(`通道ID: ${sensorData.channel}`);
      }
    });
  }
};

// 订阅传感器数据上报
try {
  await sensorClient.subscribeSensor(targetDevice.randomId, targetSensorType, sensorCallback);
  console.info(`成功订阅${targetSensorType}传感器数据`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`订阅传感器失败. Code: ${err.code}, Message: ${err.message}`);
}
```

### 步骤4：取消订阅传感器数据上报

**示例代码**：
```typescript
// 取消订阅（必须传入与订阅时相同的回调函数对象）
try {
  await sensorClient.unsubscribeSensor(targetDevice.randomId, targetSensorType, sensorCallback);
  console.info(`成功取消订阅${targetSensorType}传感器数据`);
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`取消订阅失败. Code: ${err.code}, Message: ${err.message}`);
}
```

### 步骤5：错误处理

**完整的错误处理示例**：
```typescript
try {
  // 执行传感器操作
  let sensorList: wearEngine.Sensor[] = await sensorClient.getSensorList(targetDevice.randomId);
  
  // 订阅传感器
  await sensorClient.subscribeSensor(targetDevice.randomId, wearEngine.SensorType.ACCELEROMETER, sensorCallback);
  
} catch (error) {
  const err: BusinessError = error as BusinessError;
  
  switch (err.code) {
    case 401:
      console.error('参数错误：必填参数未指定或参数类型错误');
      break;
    case 801:
      console.error('系统能力不支持：当前设备不支持WearEngine能力');
      break;
    case 1008500001:
      console.error('网络错误：网络不可用，请检查网络连接');
      break;
    case 1008500002:
      console.error('未绑定设备：没有绑定的穿戴设备');
      break;
    case 1008500003:
      console.error('设备断开：设备已断开连接，请重新连接设备');
      break;
    case 1008500004:
      console.error('未申请服务：应用未在开发者联盟申请Wear Engine服务');
      break;
    case 1008500005:
      console.error('华为账号未授权：华为账号未授权');
      break;
    case 1008500006:
      console.error('用户隐私未同意：用户隐私协议未同意');
      break;
    case 1008500007:
      console.error('设备能力不支持：设备不支持该传感器能力');
      break;
    case 1008500008:
      console.error('账号错误：用户未登录华为账号');
      break;
    case 1008500009:
      console.error('账号错误：获取华为账号信息失败');
      break;
    case 1008500010:
      console.error('设备ID无效：设备随机标识符无效');
      break;
    case 1008500012:
      console.error('回调函数过多：同一类型传感器的回调函数数量超限');
      break;
    case 1008509999:
      console.error('内部错误：Wear Engine内部错误，请联系华为支持');
      break;
    default:
      console.error(`未知错误. Code: ${err.code}, Message: ${err.message}`);
  }
}
```

### 步骤6：降级处理 - 设备断线重连处理

**示例代码**：
```typescript
// 订阅设备连接状态变化事件
let monitorClient: wearEngine.MonitorClient = wearEngine.getMonitorClient(this.getUIContext().getHostContext());

let connectionCallback = (monitorEventData: wearEngine.MonitorEventData) => {
  if (monitorEventData.event === wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED) {
    let connectionStatus = monitorEventData.data.code;
    
    if (connectionStatus === 2) {  // 连接成功
      console.info('设备重新连接成功，重新订阅传感器');
      // 重新订阅传感器
      sensorClient.subscribeSensor(targetDevice.randomId, targetSensorType, sensorCallback).then(() => {
        console.info('重新订阅传感器成功');
      }).catch((error: BusinessError) => {
        console.error(`重新订阅失败. Code: ${error.code}, Message: ${error.message}`);
      });
    } else if (connectionStatus === 3) {  // 连接断开
      console.warn('设备连接断开，传感器数据上报已停止');
    } else if (connectionStatus === 5) {  // 设备解绑
      console.warn('设备已解绑');
    }
  }
};

// 订阅设备连接状态变化
try {
  await monitorClient.subscribeEvent(targetDevice.randomId, wearEngine.MonitorEvent.EVENT_CONNECTION_STATUS_CHANGED, connectionCallback);
  console.info('成功订阅设备连接状态变化事件');
} catch (error) {
  const err: BusinessError = error as BusinessError;
  console.error(`订阅连接状态失败. Code: ${err.code}, Message: ${err.message}`);
}
```

## 穿戴设备传感器数据格式及样例

数据上报数量非固定，示例中给出的是通常上报结果，实际有可能根据设备原因增加或者减少数据。

| 传感器 | 支持多通道 | 采集周期（ms） | 上报周期（ms） | 数据格式 | 数据样例 |
| --- | --- | --- | --- | --- | --- |
| ACC | No | 10 | 100 | 1次上报10组，每组3个数据，分别代表x轴、y轴、z轴加速度，共30个数据。单位：m/s^2，4096为1个重力加速度g | [34303.0, 10753.0, 54799.0, 33023.0, 15617.0, 2576.0, 33535.0, 9729.0, 5136.0, 24063.0, 6145.0, 62479.0, 23295.0, 6145.0, 58895.0, 35071.0, 9729.0, 57359.0, 46335.0, 10497.0, 53263.0, 55039.0, 4609.0, 57359.0, 42495.0, 2305.0, 60943.0, 41471.0, 64768.0, 57359.0] **说明：**ACC、GYRO原始数据值范围为有符号Short，目前上报后的数据值范围为无符号Short，需要开发者自行进行转换。 |
| GYRO | No | 10 | 100 | 1次上报10组，每组3个数据，分别代表x轴、y轴、z轴角速度，共30个数据。单位：70mdps/LSB | [34303.0, 10753.0, 54799.0, 33023.0, 15617.0, 2576.0, 33535.0, 9729.0, 5136.0, 24063.0, 6145.0, 62479.0, 23295.0, 6145.0, 58895.0, 35071.0, 9729.0, 57359.0, 46335.0, 10497.0, 53263.0, 55039.0, 4609.0, 57359.0, 42495.0, 2305.0, 60943.0, 41471.0, 64768.0, 57359.0] |
| HR | No | 1000 | 1000 | 1次1个数据，代表每分钟心跳次数。单位：次/分钟 | [80.0] |
| MAG | No | 100 | 100 | 1次上报1组，每组4个数据，分别代表x轴、y轴、z轴磁场强度，最后一个数据无实际意义，无需关注。单位：μT | [3.9310358, 21.161278, -34.467373, 0.0] |
| PPG | Yes | 10 | 100 | 三路数据（GREEN/RED/IR） 100ms上报10包数据，每包数据4个字节。 | [758457.0, 2273675.0, 2276247.0, 2278939.0, 2281102.0, 2283411.0, 2285717.0, 2288307.0, 2290863.0, 2293297.0]（一路数据） |
| ECG | Yes | 2 | 100 | 一路数据100ms上报50包数据。不区分左右手。单位：nV | [-5020837.0, -4742510.0, -4896082.0, -4938397.0, -4796497.0, -4886598.0, -4871642.0, -4943139.0, -5209429.0, -5294787.0, -5161278.0, -5174045.0, -5588071.0, -5323970.0, -5342938.0, -5028133.0, -5094523.0, -5240070.0, -5394008.0, -5540285.0, -5655190.0, -5589895.0, -5539920.0, -5559618.0, -5623090.0, -5501618.0, -5747845.0, -5871870.0, -5814964.0, -5885002.0, -6069946.0, -5678536.0, -5839040.0, -5903971.0, -5959417.0, -6172084.0, -6263279.0, -6029455.0, -6097669.0, -6165518.0, -6174638.0, -6284072.0, -6347544.0, -6319091.0, -6085631.0, -6143631.0, -6382198.0, -6250512.0, -6396059.0, -6424512.0] |

**传感器错误码说明**：

| 错误码 | 说明 |
| --- | --- |
| 300 | DEVICE_NOT_BEING_WORN - 设备未佩戴 |
| 301 | DEVICE_LEAD_OFF - 设备引线脱落 |
| 302 | SENSOR_TURNED_OFF_MANUALLY - 传感器被手动关闭 |
| 303 | SENSOR_OCCUPIED - 传感器被占用 |
| 304 | SENSOR_NOT_SUPPORTED - 传感器不支持 |

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误：必填参数未指定、参数类型错误或参数验证失败 | 检查参数是否正确，确保deviceRandomId有效、SensorType正确、回调函数有效 |
| 801 | 系统能力不支持：当前设备不支持WearEngine能力 | 使用canIUse接口检查系统能力支持情况 |
| 1008500001 | 网络错误：网络不可用 | 检查网络连接，提示用户检查网络设置 |
| 1008500002 | 未绑定设备：没有绑定的穿戴设备 | 提示用户先绑定穿戴设备 |
| 1008500003 | 设备断开：设备已断开连接 | 提示用户重新连接设备，订阅设备连接状态变化事件 |
| 1008500004 | 未申请服务：应用未在开发者联盟申请Wear Engine服务 | 在开发者联盟申请Wear Engine服务接入 |
| 1008500005 | 华为账号未授权：华为账号未授权 | 提示用户授权华为账号 |
| 1008500006 | 用户隐私未同意：用户隐私协议未同意 | 提示用户同意隐私协议 |
| 1008500007 | 设备能力不支持：设备不支持该传感器能力 | 查询设备能力，更换支持该传感器的设备 |
| 1008500008 | 账号错误：用户未登录华为账号 | 提示用户登录华为账号 |
| 1008500009 | 账号错误：获取华为账号信息失败 | 提示用户重新登录华为账号 |
| 1008500010 | 设备ID无效：设备随机标识符无效 | 使用getConnectedDevices获取有效的设备ID |
| 1008500012 | 回调函数过多：同一类型传感器的回调函数数量超限 | 减少回调函数数量，先取消之前的订阅再重新订阅 |
| 1008509999 | 内部错误：Wear Engine内部错误 | 通过在线提单提交问题，联系华为支持人员 |
| 300 | 设备未佩戴：传感器需要佩戴才能工作 | 提示用户佩戴穿戴设备 |
| 301 | 设备引线脱落：ECG传感器引线脱落 | 提示用户检查ECG传感器引线连接 |
| 302 | 传感器被手动关闭：传感器被用户手动关闭 | 提示用户在设备上打开传感器 |
| 303 | 传感器被占用：传感器正在被其他应用使用 | 等待其他应用释放传感器，或提示用户关闭其他应用 |
| 304 | 传感器不支持：设备不支持该传感器类型 | 查询传感器列表，选择设备支持的传感器类型 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "5.0.0(12)"
  }
}
```

### 环境要求
- **HarmonyOS版本**：5.0.0(12)及以上
- **设备类型**：Phone、Tablet（支持WearEngine能力）
- **系统能力**：SystemCapability.Health.WearEngine
- **模型约束**：仅支持Stage模型

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：确保项目配置正确，SDK版本支持WearEngine Kit，检查build-profile.json5中的SDK配置。

**问题2：系统能力不支持**
```
Error: 801 - Capability not supported
```
**解决方法**：使用canIUse接口检查当前设备是否支持SystemCapability.Health.WearEngine能力，在不支持的设备上避免调用相关接口。

**问题3：权限未申请**
```
Error: 1008500006 - User privacy is not agreed
```
**解决方法**：调用requestAuthorization接口申请相应权限（HEALTH_SENSOR或MOTION_SENSOR），并获得用户授权。

**问题4：回调函数未释放**
```
内存泄漏警告：订阅的回调函数未取消
```
**解决方法**：在组件销毁或页面退出时，调用unsubscribeSensor取消订阅，传入与订阅时相同的回调函数对象。

## 常见问题与解决方法

### Q1：获取传感器列表返回空列表
**原因**：
- 设备不支持传感器能力
- 设备断开连接
- 权限未授权

**解决方法**：
- 使用device.isWearEngineCapabilitySupported(wearEngine.WearEngineCapability.SENSOR)检查设备是否支持传感器能力
- 调用getConnectedDevices确认设备连接状态
- 调用requestAuthorization申请传感器权限并获得用户授权

### Q2：订阅传感器后没有数据上报
**原因**：
- 设备未佩戴（针对人体传感器）
- 传感器被手动关闭
- 传感器被占用
- 设备断开连接

**解决方法**：
- 检查sensorResult.errorCode，根据错误码处理：
  - 300：提示用户佩戴设备
  - 302：提示用户打开传感器
  - 303：等待其他应用释放传感器
- 订阅设备连接状态变化事件，设备断开时停止订阅，设备重连后重新订阅

### Q3：取消订阅失败
**原因**：
- 传入的回调函数与订阅时不是同一个对象
- 设备已断开连接

**解决方法**：
- 确保取消订阅时传入的回调函数对象与订阅时完全相同（同一个对象引用）
- 在订阅时保存回调函数对象，取消订阅时使用保存的对象

### Q4：多通道传感器数据如何区分
**原因**：PPG、ECG等传感器支持多通道，数据上报时需要区分通道

**解决方法**：
- 通过SensorData的channel字段区分通道（大于0的整数）
- 不同通道的数据可能有不同的含义或用途，根据业务需求处理不同通道的数据

### Q5：设备断线后如何恢复传感器订阅
**原因**：设备连接状态断开时，传感器数据上报会自动停止

**解决方法**：
- 订阅设备连接状态变化事件(EVENT_CONNECTION_STATUS_CHANGED)
- 在回调函数中判断连接状态：
  - 连接成功(状态码2)：重新调用subscribeSensor订阅传感器
  - 连接断开(状态码3)：提示用户设备已断开
  - 设备解绑(状态码5)：提示用户设备已解绑，需要重新绑定

### Q6：ACC/GYRO数据值范围转换问题
**原因**：ACC、GYRO原始数据值范围为有符号Short，上报后的数据值范围为无符号Short

**解决方法**：
- 开发者自行进行数据转换，将有符号Short转换为实际物理量
- 参考数据格式说明中的单位和转换规则：
  - ACC：4096为1个重力加速度g
  - GYRO：单位为70mdps/LSB

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "deviceInfo": {
    "randomId": "设备随机标识符",
    "name": "设备名称",
    "model": "设备型号"
  },
  "sensorList": [
    {
      "name": "传感器名称",
      "id": "传感器ID",
      "type": "传感器类型",
      "accuracy": "采样周期(ms)",
      "isUtcTimestampSupported": "是否支持UTC时间戳"
    }
  ],
  "subscriptionStatus": {
    "sensorType": "订阅的传感器类型",
    "isSubscribed": true,
    "startTime": "订阅开始时间"
  },
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "wearEngine.getAuthClient",
    "wearEngine.getSensorClient",
    "deviceClient.getConnectedDevices",
    "authClient.requestAuthorization",
    "sensorClient.getSensorList",
    "sensorClient.subscribeSensor",
    "sensorClient.unsubscribeSensor",
    "monitorClient.subscribeEvent"
  ]
}
```

## 参考文档

- [穿戴设备传感器获取开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/device_sensor)
- [wearEngine API参考说明](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)
- [请求用户授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization)
- [已连接穿戴设备查询](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices)
- [目标设备选择](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection)
- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [Wear Engine ArkTS API错误码](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code)

## 完整示例代码

- [ArkTS示例代码](assets/device_sensor_example.ets) - 完整的传感器获取、订阅、取消订阅示例
- [错误处理示例](assets/error_handling_example.ets) - 完整的错误处理和降级方案
- [设备断线重连示例](assets/reconnect_example.ets) - 设备断线后自动重连并重新订阅传感器

## 测试用例

### 正向测试用例
- [获取传感器列表成功](tests/test_get_sensor_list_positive.ets)：已授权且有已连接设备时获取传感器列表
- [订阅ACC传感器成功](tests/test_subscribe_acc_positive.ets)：订阅加速度传感器并接收数据
- [取消订阅成功](tests/test_unsubscribe_positive.ets)：正确取消传感器订阅
- [多通道数据处理](tests/test_multi_channel_positive.ets)：正确处理PPG/ECG多通道数据

### 边界测试用例
- [无已连接设备](tests/test_no_device_boundary.ets)：没有已连接设备时的处理
- [设备不支持传感器](tests/test_sensor_not_supported_boundary.ets)：设备不支持目标传感器时的处理
- [最大回调函数数量](tests/test_max_callbacks_boundary.ets)：测试回调函数数量限制

### 异常测试用例
- [未授权权限](tests/test_no_permission_exception.ets)：未授权传感器权限时的错误处理
- [设备断开连接](tests/test_device_disconnect_exception.ets)：设备断开连接时的错误处理和重连
- [无效设备ID](tests/test_invalid_device_id_exception.ets)：使用无效设备ID时的错误处理
- [网络错误](tests/test_network_error_exception.ets)：网络不可用时的错误处理和降级