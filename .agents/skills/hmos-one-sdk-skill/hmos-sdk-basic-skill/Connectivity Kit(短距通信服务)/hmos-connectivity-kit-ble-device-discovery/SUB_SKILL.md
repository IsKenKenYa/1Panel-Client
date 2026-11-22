---
name: hmos-connectivity-kit-ble-device-discovery
description: 扫描周边BLE设备和发送BLE广播报文实现设备发现,支持多路扫描和广播管理,需申请蓝牙权限,适用于智能硬件配对、位置服务等场景
---

# BLE设备发现技能

## 功能描述

本技能提供低功耗蓝牙(BLE)设备发现能力,包括BLE扫描和BLE广播两部分功能:

**BLE扫描**:扫描周边其他设备发出的BLE广播报文,发现或查找目标设备。支持API version 15开始的多路扫描方式,可同时管理多个扫描流程。

**BLE广播**:本机设备发送BLE广播报文,实现被其他设备发现的功能。支持API version 11及以后的多路广播方式,可在不释放资源的情况下多次启动停止广播。

## 使用场景

### 触发词
- "BLE扫描" - 扫描周边BLE设备
- "BLE广播" - 发送BLE广播报文
- "查找设备" - 发现周边BLE设备
- "设备发现" - 实现设备互相发现
- "蓝牙扫描" - 扫描蓝牙设备
- "蓝牙广播" - 发送蓝牙广播

### 能做
- 扫描周边BLE设备并获取设备信息(设备地址、广播数据等)
- 发送BLE广播报文让其他设备发现本机
- 管理多路BLE扫描流程(API version 15+)
- 管理多路BLE广播流程(API version 11+)
- 解析扫描到的BLE广播报文数据
- 设置扫描过滤条件和扫描参数
- 设置广播数据和广播参数

### 绝不做
- 不直接建立GATT连接(需参考连接和传输数据技能)
- 不处理非BLE类型的蓝牙设备
- 不处理超出广播报文长度限制(31字节)的情况
- 不替代权限申请流程(需用户自行申请ohos.permission.ACCESS_BLUETOOTH权限)

### 补充
- API version 15+推荐使用多路扫描方式(ble.createBleScanner())
- API version 11+推荐使用多路广播方式(ble.startAdvertising(advertisingParams))
- 广播报文长度不能超过31字节,超出会导致广播启动失败
- 扫描和广播会消耗蓝牙硬件资源和影响设备功耗,需及时停止

## 调用规范和规则

### 输入约束
- 权限要求:必须申请ohos.permission.ACCESS_BLUETOOTH权限
- API版本:BLE扫描推荐API version 15+,BLE广播推荐API version 11+
- 广播数据长度:广播报文(advertisingData)和扫描响应报文(advertisingResponse)长度均不能超过31字节
- 扫描过滤器数量:建议单个应用使用过滤器数量不超过3个
- 设备地址格式:XX:XX:XX:XX:XX:XX(例如:"11:22:33:44:55:66")
- UUID格式:标准UUID格式(例如:"00001888-0000-1000-8000-00805f9b34fb")

### 执行约束
- 扫描持续时间:建议设置扫描持续时间,避免无限扫描消耗资源
- 广播持续时间:可选参数duration,若大于0则广播发送一段时间后自动停止
- 扫描模式:dutyMode可选择SCAN_MODE_LOW_POWER(低功耗)或SCAN_MODE_BALANCED(平衡)
- 匹配模式:matchMode可选择MATCH_MODE_AGGRESSIVE(激进)或MATCH_MODE_STICKY(粘性)
- 最大扫描路数:支持多路扫描,但建议不超过系统限制
- 最大广播路数:从API version 15开始支持多路广播

### 内容约束
- 禁止生成超出31字节长度的广播报文
- 禁止使用无效的广播标识ID(advertisingId)
- 禁止携带设备名时导致广播报文超出31字节(includeDeviceName需谨慎设置)
- 禁止在未停止扫描的情况下再次发起扫描(API version 14及以前)
- 禁止混用不同API版本的扫描/广播接口

### 降级约束
- 扫描失败:提示用户检查蓝牙是否开启、权限是否已申请
- 广播失败:提示用户检查广播报文长度是否超过31字节、广播资源是否已达上限
- 设备未找到:提示用户检查扫描过滤条件、延长扫描时间
- 权限不足:引导用户申请ohos.permission.ACCESS_BLUETOOTH权限

## 调用流程和步骤

### 步骤1:申请蓝牙权限

**前置校验**:
1. 检查是否已申请ohos.permission.ACCESS_BLUETOOTH权限
2. 检查蓝牙是否已开启
3. 检查API版本是否符合要求

**权限申请示例**:
```typescript
// 在module.json5中声明权限
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

### 步骤2:BLE扫描流程(API version 15+)

**2.1 创建扫描实例**:
```typescript
import { ble } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 创建ble扫描实例,可以管理该实例下创建的扫描流程
let bleScanner: ble.BleScanner = ble.createBleScanner();
console.info('create bleScanner success');
```

**2.2 订阅扫描结果上报事件**:
```typescript
// 定义扫描结果上报回调函数
function onReceiveEvent(scanReport: ble.ScanReport) {
  console.info('BLE scan device find result: '+ JSON.stringify(scanReport));
  if (scanReport.scanResult.length > 0) {
    console.info('BLE scan result: ' + scanReport.scanResult[0].deviceId);
    // 可在此处解析广播数据
  }
}

try {
  // 发起订阅
  bleScanner.on('BLEDeviceFind', onReceiveEvent);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**2.3 构造扫描过滤条件和参数**:
```typescript
// 构造扫描BLE广播的过滤条件
let manufactureId = 4567;
let manufactureData: Uint8Array = new Uint8Array([1, 2, 3, 4]);
let manufactureDataMask: Uint8Array = new Uint8Array([0xFF, 0xFF, 0xFF, 0xFF]);

let scanFilter: ble.ScanFilter = {
  manufactureId: manufactureId,
  manufactureData: manufactureData.buffer,
  manufactureDataMask: manufactureDataMask.buffer
};

// 构造扫描配置参数
let scanOptions: ble.ScanOptions = {
  interval: 0,
  dutyMode: ble.ScanDuty.SCAN_MODE_LOW_POWER,
  matchMode: ble.MatchMode.MATCH_MODE_AGGRESSIVE
};
```

**2.4 发起扫描**:
```typescript
try {
  bleScanner.startScan([scanFilter], scanOptions);
  console.info('startBleScan success');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**2.5 停止扫描**:
```typescript
try {
  bleScanner.off('BLEDeviceFind', onReceiveEvent);
  bleScanner.stopScan();
  console.info('stopBleScan success');
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤3:BLE广播流程(API version 11+)

**3.1 订阅广播状态上报事件**:
```typescript
function onReceiveEvent(data: ble.AdvertisingStateChangeInfo) {
  console.info('bluetooth advertising state = ' + JSON.stringify(data));
}

try {
  ble.on('advertisingStateChange', onReceiveEvent);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**3.2 构造广播参数和数据**:
```typescript
// 设置广播发送的参数
let setting: ble.AdvertiseSetting = {
  interval: 160,
  txPower: 0,
  connectable: true // 发送支持连接的广播
};

// 构造广播数据
let manufactureValueBuffer = new Uint8Array(4);
manufactureValueBuffer[0] = 1;
manufactureValueBuffer[1] = 2;
manufactureValueBuffer[2] = 3;
manufactureValueBuffer[3] = 4;

let manufactureDataUnit: ble.ManufactureData = {
  manufactureId: 4567,
  manufactureValue: manufactureValueBuffer.buffer
};

let advData: ble.AdvertiseData = {
  serviceUuids: ["00001888-0000-1000-8000-00805f9b34fb"],
  manufactureData: [manufactureDataUnit],
  serviceData: [],
  includeDeviceName: false // 注意:带上设备名时容易导致广播报文长度超出31字节
};

let advResponse: ble.AdvertiseData = {
  serviceUuids: [],
  manufactureData: [],
  serviceData: []
};

// 构造广播启动完整参数AdvertisingParams
let advertisingParams: ble.AdvertisingParams = {
  advertisingSettings: setting,
  advertisingData: advData, // 注意:广播报文长度不能超过31个字节
  advertisingResponse: advResponse, // 注意:广播报文长度不能超过31个字节
  duration: 0 // 可选参数,若大于0则广播发送一段时间后会自动停止
};
```

**3.3 首次启动广播**:
```typescript
let advHandle = 0xFF; // 定义广播标识

try {
  ble.startAdvertising(advertisingParams, (err, outAdvHandle) => {
    if (err) {
      console.error('startAdvertising failed: ' + err.code);
      return;
    } else {
      advHandle = outAdvHandle;
      console.info("advHandle: " + advHandle);
    }
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**3.4 停止指定标识的广播**:
```typescript
let advertisingDisableParams: ble.AdvertisingDisableParams = {
  advertisingId: advHandle // 使用首次启动广播时获取到的广播标识ID
};

try {
  ble.disableAdvertising(advertisingDisableParams, (err) => {
    if (err) {
      console.error('disableAdvertising failed: ' + err.code);
      return;
    }
    console.info('disableAdvertising success');
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**3.5 重新启动指定标识的广播**:
```typescript
let advertisingEnableParams: ble.AdvertisingEnableParams = {
  advertisingId: advHandle, // 使用首次启动广播时获取到的广播标识ID
  duration: 300
};

try {
  ble.enableAdvertising(advertisingEnableParams, (err) => {
    if (err) {
      console.error('enableAdvertising failed: ' + err.code);
      return;
    }
    console.info('enableAdvertising success');
  });
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**3.6 完全停止广播并释放资源**:
```typescript
try {
  ble.stopAdvertising(advHandle, (err) => {
    if (err) {
      console.error('stopAdvertising failed: ' + err.code);
      return;
    }
    console.info('stopAdvertising success');
  });
  ble.off('advertisingStateChange', onReceiveEvent);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤4:错误处理

**通用错误处理模式**:
```typescript
try {
  // BLE操作代码
} catch (err) {
  let error = err as BusinessError;
  console.error('errCode: ' + error.code + ', errMessage: ' + error.message);
  
  // 根据错误码进行特定处理
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please apply for ohos.permission.ACCESS_BLUETOOTH permission');
      break;
    case 2900003:
      console.error('Bluetooth disabled. Please enable Bluetooth');
      break;
    case 2900010:
      console.error('The number of advertising resources reaches the upper limit');
      break;
    case 2902054:
      console.error('The length of the advertising data exceeds the upper limit (31 bytes)');
      break;
    default:
      console.error('Operation failed: ' + error.message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请ohos.permission.ACCESS_BLUETOOTH权限 |
| 401 | Invalid parameter | 检查参数类型和格式是否正确 |
| 801 | Capability not supported | 检查设备是否支持该API版本 |
| 2900001 | Service stopped | 等待蓝牙服务恢复或重启蓝牙 |
| 2900003 | Bluetooth disabled | 开启蓝牙开关 |
| 2900009 | Operation failed | 检查操作流程和参数是否正确 |
| 2900010 | The number of advertising resources reaches the upper limit | 停止不必要的广播释放资源 |
| 2902054 | The length of the advertising data exceeds the upper limit | 减少广播报文数据,确保不超过31字节 |
| 2902055 | Invalid advertising id | 使用首次启动广播时获取的正确广播标识ID |

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
- HarmonyOS API version: 10+ (基础功能), 11+ (推荐广播方式), 15+ (推荐扫描方式)
- DevEco Studio: 3.1+
- ArkTS: 最新版本

### 常见编译问题

**问题1:导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**:确保HarmonyOS SDK版本支持ConnectivityKit,并正确配置依赖

**问题2:权限编译错误**
```
Error: Permission ohos.permission.ACCESS_BLUETOOTH not declared
```
**解决方法**:在module.json5中声明权限

**问题3:API版本不匹配**
```
Error: Property 'createBleScanner' does not exist on type 'ble'
```
**解决方法**:检查API版本,createBleScanner需要API version 15+

## 常见问题与解决方法

### Q1:扫描不到BLE设备
**原因**:
- 蓝牙未开启
- 权限未申请
- 扫描过滤条件设置过于严格
- 目标设备未发送广播

**解决方法**:
- 检查并开启蓝牙开关
- 申请ohos.permission.ACCESS_BLUETOOTH权限
- 调整扫描过滤条件或使用空过滤器(不建议)
- 确认目标设备正在发送BLE广播

### Q2:广播启动失败
**原因**:
- 广播报文长度超过31字节
- 广播资源已达上限
- 权限未申请
- includeDeviceName设置导致超长

**解决方法**:
- 减少广播报文数据量,确保不超过31字节
- 停止不必要的广播释放资源
- 申请ohos.permission.ACCESS_BLUETOOTH权限
- 将includeDeviceName设置为false

### Q3:无法解析广播数据
**原因**:
- 广播数据格式不符合蓝牙标准协议
- 解析逻辑错误

**解决方法**:
- 参考蓝牙标准协议Core Assigned Numbers规范
- 使用完整示例中的parseScanResult方法解析

### Q4:多路扫描/广播管理混乱
**原因**:
- 不同API版本的接口混用
- 广播标识ID管理错误

**解决方法**:
- 使用推荐的API version 15+扫描方式和API version 11+广播方式
- 正确保存和管理首次启动广播时获取的广播标识ID
- 不要混用不同API版本的接口

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "BLE扫描/广播",
  "deviceId": "扫描到的设备地址或本机设备地址",
  "advHandle": "广播标识ID(仅广播操作)",
  "scanResult": {
    "deviceId": "设备地址",
    "data": "广播数据",
    "rssi": "信号强度"
  },
  "apiUsed": [
    "ble.createBleScanner",
    "bleScanner.startScan",
    "bleScanner.stopScan",
    "bleScanner.on('BLEDeviceFind')",
    "ble.startAdvertising",
    "ble.enableAdvertising",
    "ble.disableAdvertising",
    "ble.stopAdvertising",
    "ble.on('advertisingStateChange')"
  ]
}
```

## 参考文档

- [BLE设备查找开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide)
- [蓝牙BLE API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-ble)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
- [连接和传输数据](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/gatt-development-guide)

## 完整示例代码

- [ArkTS BLE扫描示例](assets/BleScanManager.ets) - 包含完整的BLE扫描流程和广播数据解析
- [ArkTS BLE广播示例](assets/BleAdvertisingManager.ets) - 包含完整的BLE广播流程管理
- [配置文件示例](assets/module.json5) - 包含权限声明配置

## 测试用例

### 正向测试用例
- [测试BLE扫描功能](tests/test_ble_scan_positive.ets) - 测试正常扫描流程
- [测试BLE广播功能](tests/test_ble_advertising_positive.ets) - 测试正常广播流程

### 边界测试用例
- [测试广播报文长度边界](tests/test_advertising_length_boundary.ets) - 测试31字节长度限制
- [测试多路扫描/广播](tests/test_multi_scan_advertising.ets) - 测试多路管理能力

### 异常测试用例
- [测试权限缺失场景](tests/test_permission_denied.ets) - 测试权限未申请时的错误处理
- [测试蓝牙未开启场景](tests/test_bluetooth_disabled.ets) - 测试蓝牙关闭时的错误处理
- [测试参数错误场景](tests/test_invalid_parameters.ets) - 测试参数错误时的错误处理