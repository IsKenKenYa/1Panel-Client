# API参考链接汇总

本文档汇总穿戴设备传感器获取技能涉及的所有关键API参考链接。

## 核心API接口

### 1. wearEngine模块导入

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**导入方式**:
```typescript
import { wearEngine } from '@kit.WearEngine';
```

### 2. 获取SensorClient客户端

**API**: `wearEngine.getSensorClient(context: common.Context): SensorClient`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 用于获取Sensor模块的客户端,返回SensorClient对象。

**起始版本**: 5.0.0(12)

**参数**:
- `context`: Context上下文,仅支持包含connectServiceExtensionAbility方法的Context(如UIAbilityContext)

**返回值**: SensorClient - Sensor客户端,存储了Sensor模块的相关方法

### 3. 获取传感器列表

**API**: `sensorClient.getSensorList(deviceRandomId: string): Promise<Sensor[]>`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 获取设备侧可用的传感器列表,返回对应的传感器列表。

**参数**:
- `deviceRandomId`: Device的随机标识符,用于指定设备

**返回值**: Promise<Sensor[]> - 返回设备侧可用的传感器列表

### 4. 订阅传感器数据

**API**: `sensorClient.subscribeSensor(deviceRandomId: string, type: SensorType, callback: Callback<SensorResult>): Promise<void>`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 订阅指定的传感器数据上报,返回是否订阅成功。

**参数**:
- `deviceRandomId`: Device的随机标识符
- `type`: 传感器类别(SensorType枚举)
- `callback`: 回调函数,用于处理传感器上报的数据

**返回值**: Promise<void> - 无结果返回的Promise对象

### 5. 取消订阅传感器数据

**API**: `sensorClient.unsubscribeSensor(deviceRandomId: string, type: SensorType, callback: Callback<SensorResult>): Promise<void>`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 取消订阅指定的传感器数据上报,返回是否取消成功。

**参数**:
- `deviceRandomId`: Device的随机标识符
- `type`: 传感器类别
- `callback`: 回调函数,需要同订阅监听时的回调函数为同一个对象

**返回值**: Promise<void> - 无结果返回的Promise对象

## 辅助API接口

### 6. 获取DeviceClient客户端

**API**: `wearEngine.getDeviceClient(context: common.Context): DeviceClient`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 用于获取Device模块的客户端。

### 7. 获取已连接设备列表

**API**: `deviceClient.getConnectedDevices(): Promise<Device[]>`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 获取当前已连接且支持wearEngine能力集的设备。

### 8. 获取AuthClient客户端

**API**: `wearEngine.getAuthClient(context: common.Context): AuthClient`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 用于获取权限管理的客户端。

### 9. 申请用户授权

**API**: `authClient.requestAuthorization(request: AuthorizationRequest): Promise<AuthorizationResponse>`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 向手机用户申请需要授权的权限。

### 10. 查询设备能力支持

**API**: `device.isWearEngineCapabilitySupported(capability: WearEngineCapability): Promise<boolean>`

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**功能**: 查询设备是否支持指定的WearEngine能力。

## 数据类型定义

### SensorType枚举

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**枚举值**:
- ELECTROCARDIOGRAPHY (0): ECG传感器
- PHOTOPLETHYSMOGRAPHY (1): PPG传感器
- ACCELEROMETER (2): 加速度传感器
- GYROSCOPE (3): 陀螺仪传感器
- MAGNETIC_FIELD (4): 磁力传感器
- HEART_RATE (6): 心率传感器

### Sensor信息类

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**属性**:
- name: string - 传感器名称
- id: number - 传感器ID
- type: SensorType - 传感器类型
- accuracy: number - 传感器采样周期(毫秒)
- resolution: number - 传感器分辨率
- isUtcTimestampSupported: boolean - 是否支持UTC时间戳

### SensorData数据类

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**属性**:
- sensorType: SensorType - 传感器类型
- data: number[] - 数据内容
- channel: number - 传感器通道ID
- timestamp: number - 计时时间戳
- utcTimestamp: number - UTC时间戳

### SensorResult结果类

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**属性**:
- data: SensorData[] - 传感器正常上报的数据内容
- errorCode: number - 错误码(SensorErrorCode)

### Permission权限枚举

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**枚举值**:
- USER_STATUS (2): 获取用户状态权限
- MOTION_SENSOR (3): 运动传感器数据权限
- HEALTH_SENSOR (4): 人体传感器数据权限
- DEVICE_IDENTIFIER (6): 设备序列号权限

## 错误码文档

### Wear Engine错误码

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api_error_code

**常见错误码**:
- 401: 参数错误
- 801: 能力不支持
- 1008500001: 网络错误
- 1008500003: 设备断开连接
- 1008500006: 用户隐私未同意
- 1008500010: 设备ID无效

### SensorErrorCode传感器错误码

**文档链接**: https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api

**错误码**:
- 300: DEVICE_NOT_BEING_WORN - 设备未佩戴
- 301: DEVICE_LEAD_OFF - 设备引线脱落
- 302: SENSOR_TURNED_OFF_MANUALLY - 传感器被手动关闭
- 303: SENSOR_OCCUPIED - 传感器被占用
- 304: SENSOR_NOT_SUPPORTED - 传感器不支持

## 开发指南文档链接

以下开发指南文档提供详细的功能实现步骤和最佳实践:

- **穿戴设备传感器获取(主文档)**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/device_sensor
- **请求用户授权**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request_user_authorization
- **已连接穿戴设备查询**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/query_connected_devices
- **目标设备选择**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/we-device-selection
- **申请接入Wear Engine服务**: https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply

## 注意事项

1. 所有API链接均指向华为开发者官网最新版本文档
2. 如果链接无法访问,请访问 https://developer.huawei.com/consumer/cn/ 搜索相关文档
3. API版本要求: HarmonyOS SDK 5.0.0(12)及以上
4. 系统能力: SystemCapability.Health.WearEngine
5. 模型约束: 仅支持Stage模型,不支持FA模型