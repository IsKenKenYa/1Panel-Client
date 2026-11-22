---
name: hmos-connectivity-kit-ble-device-find
description: 实现BLE设备扫描和广播功能，支持多路扫描和广播，需蓝牙权限，适用于查找周边BLE设备和被其他设备发现的场景
---

# BLE设备查找技能

## 功能描述

本技能提供了基于低功耗蓝牙(BLE)技术的设备扫描和广播功能实现。通过本技能可以：

1. **BLE扫描**：扫描周边BLE设备，发现目标设备
2. **BLE广播**：发送BLE广播报文，让其他设备发现本机设备

支持API version 15开始的多路扫描和API version 11+的多路广播，提供完整的扫描结果解析和广播数据构造能力。

## 使用场景

### 触发词
- "BLE扫描"
- "BLE广播"
- "查找BLE设备"
- "扫描周边蓝牙设备"
- "发送BLE广播"
- "被其他设备发现"

### 能做
- 扫描周边BLE设备并解析广播报文
- 发送BLE广播报文让其他设备发现本机
- 支持多路扫描和广播管理
- 解析BLE广播报文的各种数据类型(UUID、制造商数据、服务数据等)
- 构造自定义的BLE广播数据

### 绝不做
- 不处理BLE设备连接和数据传输（参考GATT连接技能）
- 不处理经典蓝牙扫描和广播
- 不处理蓝牙配对和认证
- 不处理超出31字节的广播数据（会导致启动失败）

### 补充
- 必须申请ohos.permission.ACCESS_BLUETOOTH权限
- 推荐使用API version 15的多路扫描方式
- 广播数据长度不能超过31字节
- 扫描会消耗硬件资源和影响功耗，需主动停止

## 调用规范和规则

### 输入约束
- 扫描过滤器数量：建议不超过3个（避免资源耗尽）
- 广播数据长度：不超过31字节
- 扫描间隔：最小0ms，推荐值根据功耗要求调整
- 广播间隔：最小20ms，推荐160ms（平衡功耗和发现率）

### 执行约束
- 最大扫描持续时间：建议不超过60秒（避免高功耗）
- 最大广播持续时间：根据业务需求，建议设置duration参数
- API调用频次：避免频繁启动/停止扫描或广播
- 扫描结果上报频次：根据matchMode调整上报频率

### 内容约束
- 禁止生成超过31字节的广播数据
- 禁止使用无效的UUID格式
- 禁止扫描时使用null过滤器（可能扫描到非预期设备）
- 禁止混用不同API version的接口（如API v10的startAdvertising和API v11的stopAdvertising）

### 降级约束
- 权限不足：提示用户申请权限，参考权限申请文档
- 硬件资源耗尽：减少过滤器数量或停止其他扫描流程
- 广播数据过长：压缩数据或移除includeDeviceName
- 蓝牙服务停止：提示用户检查蓝牙开关状态

## 调用流程和步骤

### 步骤1：申请蓝牙权限

**前置校验**：
1. 检查是否已声明ohos.permission.ACCESS_BLUETOOTH权限
2. 检查是否已向用户申请授权
3. 验证权限申请流程是否完成

**权限申请示例**：
```typescript
// 在module.json5中声明权限
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BLUETOOTH",
        "reason": "$string:ble_permission_reason"
      }
    ]
  }
}
```

参考文档：
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)

### 步骤2：导入API模块

```typescript
import { ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤3：BLE扫描流程（推荐API version 15）

#### 3.1 创建扫描实例

```typescript
let bleScanner: ble.BleScanner = ble.createBleScanner();
console.info('create bleScanner success');
```

#### 3.2 订阅扫描结果上报事件

```typescript
function onReceiveEvent(scanReport: ble.ScanReport) {
  console.info('BLE scan device find result: ' + JSON.stringify(scanReport));
  if (scanReport.scanResult.length > 0) {
    console.info('BLE scan result deviceId: ' + scanReport.scanResult[0].deviceId);
    // 解析广播报文数据
    parseScanResult(scanReport.scanResult[0].data);
  }
}

try {
  bleScanner.on('BLEDeviceFind', onReceiveEvent);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 3.3 构造扫描过滤器

```typescript
let manufactureId = 4567;
let manufactureData: Uint8Array = new Uint8Array([1, 2, 3, 4]);
let manufactureDataMask: Uint8Array = new Uint8Array([0xFF, 0xFF, 0xFF, 0xFF]);

let scanFilter: ble.ScanFilter = {
  manufactureId: manufactureId,
  manufactureData: manufactureData.buffer,
  manufactureDataMask: manufactureDataMask.buffer,
  // 可选参数
  deviceId: "XX:XX:XX:XX:XX:XX",  // 设备地址
  name: "test",                   // 设备名称
  serviceUuid: "00001888-0000-1000-8000-00805f9b34fb"  // 服务UUID
};
```

#### 3.4 构造扫描配置参数

```typescript
let scanOptions: ble.ScanOptions = {
  interval: 0,  // 扫描间隔，0表示连续扫描
  dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,  // 低功耗模式
  matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE  // 宽松匹配模式
};
```

#### 3.5 发起扫描

```typescript
try {
  await bleScanner.startScan([scanFilter], scanOptions);
  console.info('startBleScan success');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 3.6 停止扫描

```typescript
try {
  bleScanner.off('BLEDeviceFind', onReceiveEvent);
  await bleScanner.stopScan();
  console.info('stopBleScan success');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤4：BLE广播流程（推荐API version 11+）

#### 4.1 订阅广播状态上报事件

```typescript
function onReceiveEvent(data: ble.AdvertisingStateChangeInfo) {
  console.info('bluetooth advertising state = ' + JSON.stringify(data));
  // 更新广播状态
  AppStorage.setOrCreate('advertiserState', data.state);
}

try {
  ble.on('advertisingStateChange', onReceiveEvent);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 4.2 设置广播参数

```typescript
let setting: ble.AdvertiseSetting = {
  interval: 160,        // 广播间隔160ms
  txPower: 0,           // 发射功率
  connectable: true     // 可连接广播
};
```

#### 4.3 构造广播数据

```typescript
// 制造商数据
let manufactureValueBuffer = new Uint8Array(4);
manufactureValueBuffer[0] = 1;
manufactureValueBuffer[1] = 2;
manufactureValueBuffer[2] = 3;
manufactureValueBuffer[3] = 4;

let manufactureDataUnit: ble.ManufactureData = {
  manufactureId: 4567,
  manufactureValue: manufactureValueBuffer.buffer
};

// 服务数据
let serviceValueBuffer = new Uint8Array(4);
serviceValueBuffer[0] = 5;
serviceValueBuffer[1] = 6;
serviceValueBuffer[2] = 7;
serviceValueBuffer[3] = 8;

let serviceDataUnit: ble.ServiceData = {
  serviceUuid: "00001999-0000-1000-8000-00805f9b34fb",
  serviceValue: serviceValueBuffer.buffer
};

// 广播数据（不超过31字节）
let advData: ble.AdvertiseData = {
  serviceUuids: ["00001888-0000-1000-8000-00805f9b34fb"],
  manufactureData: [manufactureDataUnit],
  serviceData: [],
  includeDeviceName: false  // 不携带设备名（避免超长）
};

// 扫描回复数据（不超过31字节）
let advResponse: ble.AdvertiseData = {
  serviceUuids: [],
  manufactureData: [],
  serviceData: [serviceDataUnit]
};
```

#### 4.4 首次启动广播

```typescript
let advertisingParams: ble.AdvertisingParams = {
  advertisingSettings: setting,
  advertisingData: advData,
  advertisingResponse: advResponse,
  duration: 0  // 持续发送，不自动停止
};

try {
  let advHandle = await ble.startAdvertising(advertisingParams);
  console.info("advHandle: " + advHandle);
  // 保存广播标识用于后续管理
  this.advHandle = advHandle;
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 4.5 停止指定广播（保留资源）

```typescript
let advertisingDisableParams: ble.AdvertisingDisableParams = {
  advertisingId: this.advHandle
};

try {
  await ble.disableAdvertising(advertisingDisableParams);
  console.info("disable advertising success");
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 4.6 重新启动广播

```typescript
let advertisingEnableParams: ble.AdvertisingEnableParams = {
  advertisingId: this.advHandle,
  duration: 300  // 发送300秒后自动停止
};

try {
  await ble.enableAdvertising(advertisingEnableParams);
  console.info("enable advertising success");
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

#### 4.7 完全停止广播（释放资源）

```typescript
try {
  await ble.stopAdvertising(this.advHandle);
  ble.off('advertisingStateChange', onReceiveEvent);
  console.info("stop advertising success");
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤5：错误处理和降级方案

#### 5.1 权限错误处理

```typescript
try {
  await bleScanner.startScan([scanFilter], scanOptions);
} catch (err) {
  let businessError = err as BusinessError;
  if (businessError.code === 201) {
    console.error('Permission denied. Please apply for ohos.permission.ACCESS_BLUETOOTH');
    // 降级方案：提示用户申请权限
  }
}
```

#### 5.2 资源耗尽处理

```typescript
try {
  await bleScanner.startScan([scanFilter1, scanFilter2, scanFilter3], scanOptions);
} catch (err) {
  let businessError = err as BusinessError;
  if (businessError.code === 2900009) {
    console.error('Hardware resources exhausted. Reducing filters.');
    // 降级方案：减少过滤器数量
    await bleScanner.startScan([scanFilter1], scanOptions);
  }
}
```

#### 5.3 广播数据过长处理

```typescript
try {
  await ble.startAdvertising(advertisingParams);
} catch (err) {
  let businessError = err as BusinessError;
  if (businessError.code === 2902054) {
    console.error('Advertising data too long. Max 31 bytes.');
    // 降级方案：移除设备名或压缩数据
    advData.includeDeviceName = false;
    await ble.startAdvertising(advertisingParams);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请ohos.permission.ACCESS_BLUETOOTH权限 |
| 401 | Invalid parameter | 检查参数类型和取值范围，确保UUID格式正确 |
| 801 | Capability not supported | 检查设备是否支持BLE功能 |
| 2900001 | Service stopped | 检查蓝牙服务是否运行，尝试重新启动 |
| 2900003 | Bluetooth disabled | 提示用户打开蓝牙开关 |
| 2900009 | Operation failed / Hardware resources exhausted | 减少过滤器数量或停止其他扫描流程 |
| 2900010 | The number of advertising resources reaches the upper limit | 停止其他广播流程 |
| 2902050 | Ble scan is already started by the app | 先停止当前扫描再重新启动 |
| 2902054 | The length of advertising data exceeds the upper limit | 压缩广播数据，确保不超过31字节 |
| 2902055 | Invalid advertising id | 使用正确的广播标识 |
| 2900099 | Operation failed | 检查操作条件和参数 |

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
- HarmonyOS API version 10+（基础BLE功能）
- HarmonyOS API version 11+（推荐多路广播）
- HarmonyOS API version 15+（推荐多路扫描）
- DevEco Studio 3.1+

### 常见编译问题

**问题1：找不到ble模块**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：确保项目使用HarmonyOS SDK，并在oh-package.json5中添加依赖声明。

**问题2：类型定义错误**
```
Error: Property 'createBleScanner' does not exist on type 'ble'
```
**解决方法**：检查API version是否支持（createBleScanner需要API version 15+）。

**问题3：权限声明缺失**
```
Error: Permission denied
```
**解决方法**：在module.json5中声明ohos.permission.ACCESS_BLUETOOTH权限。

## 常见问题与解决方法

### Q1：扫描不到BLE设备
**原因**：
- 权限未申请或授权
- 蓝牙未开启
- 过滤器设置过于严格
- 目标设备未发送广播

**解决方法**：
- 检查权限申请流程是否完成
- 确认蓝牙开关已打开
- 调整过滤器参数，尝试放宽条件
- 确认目标设备正在发送BLE广播

### Q2：广播启动失败
**原因**：
- 广播数据超过31字节
- 广播资源已达上限
- 蓝牙服务异常

**解决方法**：
- 设置includeDeviceName为false
- 减少广播数据字段
- 先停止其他广播流程
- 检查蓝牙服务状态

### Q3：扫描功耗过高
**原因**：
- 扫描间隔设置为0（连续扫描）
- dutyMode设置为高功耗模式
- 扫描持续时间过长

**解决方法**：
- 设置interval参数为500ms或更大
- 使用SCAN_MODE_LOW_POWER模式
- 设置扫描超时时间，及时停止扫描

### Q4：无法同时启动多路扫描
**原因**：
- API version低于15
- 使用了旧版ble.startBLEScan接口

**解决方法**：
- 使用API version 15+的createBleScanner接口
- 每个BleScanner实例可独立管理扫描流程

### Q5：广播标识无效
**原因**：
- 广播已完全停止（资源已释放）
- 广播标识不匹配

**解决方法**：
- 确认广播流程未调用stopAdvertising完全停止
- 使用首次启动广播时获取的正确标识

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operationType": "BLE_SCAN | BLE_ADVERTISING",
  "deviceCount": 5,
  "advHandle": 123,
  "apiUsed": [
    "ble.createBleScanner",
    "bleScanner.startScan",
    "bleScanner.stopScan",
    "bleScanner.on",
    "bleScanner.off",
    "ble.startAdvertising",
    "ble.stopAdvertising",
    "ble.enableAdvertising",
    "ble.disableAdvertising"
  ],
  "executionTime": "10s",
  "powerConsumption": "low"
}
```

## 参考文档

- [BLE开发指南](references/ble-development-guide.md)
- [BLE API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-ble)

## 完整示例代码

- [BLE扫描完整示例](assets/ble_scan_example.ets)
- [BLE广播完整示例](assets/ble_advertising_example.ets)

## 测试用例

### 正向测试用例
- [BLE扫描测试](tests/test_ble_scan_positive.ets)：测试正常扫描流程
- [BLE广播测试](tests/test_ble_advertising_positive.ets)：测试正常广播流程

### 边界测试用例
- [最大过滤器数量测试](tests/test_ble_scan_max_filters.ets)：测试3个过滤器场景
- [最大广播数据长度测试](tests/test_ble_advertising_max_length.ets)：测试31字节广播数据

### 异常测试用例
- [权限缺失测试](tests/test_ble_permission_denied.ets)：测试未申请权限场景
- [蓝牙服务异常测试](tests/test_ble_service_stopped.ets)：测试蓝牙服务停止场景
- [广播数据超长测试](tests/test_ble_advertising_data_long.ets)：测试超过31字节场景