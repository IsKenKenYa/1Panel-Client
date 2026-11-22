---
name: hmos-connectivity-kit-bluetooth-discovery
description: 扫描周边蓝牙设备、设置本机蓝牙扫描模式、查找已配对设备信息，支持设备地址/信号强度/名称/类型信息获取，需要ACCESS_BLUETOOTH权限，适用于蓝牙设备发现和配对场景
---

# 蓝牙设备查找技能

## 功能描述

本技能提供传统蓝牙设备的发现和查找能力，包括扫描周边蓝牙设备、设置本机蓝牙扫描模式、查找已配对设备信息等功能。支持两种扫描结果上报方式（API version 10和API version 18），可获取设备地址、信号强度、设备名称和设备类型等信息。

**核心能力**：
- 扫描周边传统蓝牙和低功耗蓝牙设备
- 设置本机蓝牙扫描模式（可被发现、可被连接）
- 查找已配对设备信息
- 获取设备配对状态

**适用范围**：
- HarmonyOS 4.0及以上版本
- 需要ohos.permission.ACCESS_BLUETOOTH权限
- 支持ArkTS语言开发

**限制条件**：
- 扫描过程持续约12秒
- 扫描期间不可重复调用startBluetoothDiscovery
- 停止扫描后才能开始下一次扫描
- 基于信息安全考虑，获取的设备地址为虚拟MAC地址

**典型场景**：
- 蓝牙设备配对前扫描周边设备
- 查找特定设备是否已配对
- 设置本机设备可被发现模式
- 获取已配对设备列表

## 使用场景

### 触发词
- "扫描蓝牙设备"
- "查找蓝牙设备"
- "发现蓝牙设备"
- "搜索蓝牙设备"
- "获取已配对设备"
- "设置蓝牙扫描模式"
- "蓝牙设备发现"

### 能做
- 扫描周边支持蓝牙能力的设备（传统蓝牙和低功耗蓝牙）
- 获取扫描到的设备信息（地址、信号强度、名称、类型）
- 设置本机蓝牙扫描模式（可被发现、可被连接）
- 查找已配对设备列表
- 查询特定设备的配对状态
- 订阅和取消订阅扫描结果上报事件

### 绝不做
- 不执行蓝牙配对操作（需使用配对技能）
- 不执行蓝牙连接操作（需使用连接技能）
- 不执行数据传输操作（需使用传输技能）
- 不处理低功耗蓝牙专用场景（需使用BLE专用API）
- 不处理超出设备扫描范围的任务

### 补充
- 扫描过程消耗蓝牙硬件资源，扫描到所需设备后应立即停止扫描
- 推荐使用API version 18的discoveryResult上报方式（可获取更多设备信息）
- 获取的设备地址为虚拟MAC地址，已配对地址不会变更，未配对地址可能变更
- 系统应用一般不关注扫描模式设置，由系统设置应用统一管理

## 调用规范和规则

### 输入约束
- 权限要求：必须申请ohos.permission.ACCESS_BLUETOOTH权限
- 设备地址格式："XX:XX:XX:XX:XX:XX"（虚拟MAC地址）
- 扫描模式：仅支持ScanMode枚举值（0-5）
- 扫描持续时间：设置为0表示持续可发现，大于0表示限时可发现

### 执行约束
- 扫描时间：整个扫描过程约持续12秒
- 扫描状态检查：启动扫描前必须检查isBluetoothDiscovering()状态
- 重复调用限制：扫描过程中禁止重复调用startBluetoothDiscovery
- 停止扫描要求：扫描到设备后，发起连接前必须停止扫描
- 最大并发扫描：同一时间只能进行一次扫描流程

### 内容约束
- 禁止生成：不生成配对、连接、传输相关代码
- 禁止高危函数：不使用eval、exec等高危函数
- 禁止操作：不修改系统蓝牙设置、不强制修改设备地址
- 错误处理：所有API调用必须包含try-catch错误处理

### 降级约束
- 权限不足：提示用户申请ACCESS_BLUETOOTH权限
- 蓝牙未开启：提示用户开启蓝牙功能
- 扫描失败：使用getPairedDevices()查询已配对设备作为降级方案
- 设备地址变更：提示用户地址为虚拟MAC，建议使用access.addPersistentDeviceId持久化

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 申请ohos.permission.ACCESS_BLUETOOTH权限（参考声明权限和向用户申请授权文档）
2. 导入必要模块：connection和BusinessError
3. 检查蓝牙是否开启（可选）
4. 检查当前扫描状态

**参数准备**：
```typescript
// 导入必要模块
import { connection } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';

// 定义扫描结果回调函数
function onReceiveEvent(data: Array<connection.DiscoveryResult>) {
  console.info('bluetooth device: ' + JSON.stringify(data));
}
```

### 步骤2：订阅扫描结果上报事件

**推荐方式（API version 18）**：
```typescript
// 订阅discoveryResult事件（推荐）
try {
  connection.on('discoveryResult', onReceiveEvent);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**备用方式（API version 10-17）**：
```typescript
// 定义扫描结果回调函数（仅返回设备地址）
function onReceiveEventLegacy(data: Array<string>) {
  console.info('bluetooth device: ' + JSON.stringify(data));
}

// 订阅bluetoothDeviceFind事件
try {
  connection.on('bluetoothDeviceFind', onReceiveEventLegacy);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

### 步骤3：发起设备扫描

**扫描流程**：
```typescript
try {
  // 判断本机设备是否正在进行扫描
  let scan = connection.isBluetoothDiscovering();
  if (!scan) {
    // 若当前不处于扫描过程，则开始扫描设备
    connection.startBluetoothDiscovery();
    console.info('Bluetooth discovery started');
  } else {
    console.warn('Bluetooth discovery is already running');
  }
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**关键说明**：
- 扫描过程持续约12秒
- 扫描结果通过订阅的回调函数上报
- 扫描过程中禁止重复调用startBluetoothDiscovery

### 步骤4：处理扫描结果

**扫描结果处理**：
```typescript
// 处理扫描到的设备信息
function handleDiscoveryResult(data: Array<connection.DiscoveryResult>) {
  for (let device of data) {
    console.info('Device found:');
    console.info('  Address: ' + device.deviceId);
    console.info('  Name: ' + device.deviceName);
    console.info('  RSSI: ' + device.rssi + ' dBm');
    console.info('  Class: ' + JSON.stringify(device.deviceClass));
    
    // 根据需求筛选设备
    if (device.deviceName === 'TargetDevice') {
      console.info('Target device found: ' + device.deviceId);
      // 可以在此处停止扫描并准备配对/连接
    }
  }
}
```

### 步骤5：停止设备扫描

**停止扫描流程**：
```typescript
try {
  // 判断本机设备是否正在进行扫描
  let scan = connection.isBluetoothDiscovering();
  if (scan) {
    // 若当前处于扫描过程，则停止扫描设备
    connection.stopBluetoothDiscovery();
    console.info('Bluetooth discovery stopped');
  }
  
  // 若不再需要使用扫描，可以取消订阅扫描上报结果
  connection.off('discoveryResult', onReceiveEvent);
  // 或使用旧版API取消订阅
  // connection.off('bluetoothDeviceFind', onReceiveEventLegacy);
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**重要提醒**：
- 扫描消耗蓝牙硬件资源，扫描到所需设备后应立即停止
- 发起连接前必须停止扫描
- 停止扫描后才能开始下一次扫描

### 步骤6：设置本机蓝牙扫描模式（可选）

**扫描模式设置**：
```typescript
try {
  // 获取当前本机的扫描模式
  let scanMode: connection.ScanMode = connection.getBluetoothScanMode();
  console.info('Current scan mode: ' + scanMode);
  
  // 设置为可被发现和可被连接模式
  if (scanMode != connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE) {
    connection.setBluetoothScanMode(
      connection.ScanMode.SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE, 
      0  // 0表示持续可发现
    );
    console.info('Scan mode set to CONNECTABLE_GENERAL_DISCOVERABLE');
  }
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**扫描模式说明**：
- SCAN_MODE_NONE (0): 不可发现、不可连接
- SCAN_MODE_CONNECTABLE (1): 可连接
- SCAN_MODE_GENERAL_DISCOVERABLE (2): 通用可发现
- SCAN_MODE_LIMITED_DISCOVERABLE (3): 有限可发现
- SCAN_MODE_CONNECTABLE_GENERAL_DISCOVERABLE (4): 可连接及通用可发现
- SCAN_MODE_CONNECTABLE_LIMITED_DISCOVERABLE (5): 可连接及有限可发现

### 步骤7：查找已配对设备信息

**获取已配对设备**：
```typescript
try {
  // 获取已配对设备信息
  let devices: Array<string> = connection.getPairedDevices();
  console.info('Paired devices: ' + JSON.stringify(devices));
  
  // 若已知设备地址，可主动查询该设备是否是已配对的
  if (devices.length > 0) {
    let pairState: connection.BondState = connection.getPairState(devices[0]);
    console.info('Device: ' + devices[0] + ' pairState is ' + pairState);
    
    // 配对状态说明
    // BOND_STATE_INVALID (0): 未配对
    // BOND_STATE_BONDING (1): 配对中
    // BOND_STATE_BONDED (2): 已配对
  }
} catch (err) {
  console.error('errCode: ' + (err as BusinessError).code + ', errMessage: ' + (err as BusinessError).message);
}
```

**地址安全说明**：
- 获取的设备地址为虚拟MAC地址（基于信息安全考虑）
- 已配对的设备地址不会变更
- 设备重启蓝牙开关后，虚拟地址会立即变更
- 取消配对后，地址变更时机由系统决策
- 建议使用access.addPersistentDeviceId方法持久化保存地址

### 步骤8：错误处理

**错误处理代码**：
```typescript
try {
  // 调用蓝牙扫描相关API
  connection.startBluetoothDiscovery();
} catch (err) {
  const error = err as BusinessError;
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please apply for ACCESS_BLUETOOTH permission.');
      break;
    case 401:
      console.error('Invalid parameter. Check parameter types and values.');
      break;
    case 801:
      console.error('Capability not supported. Device does not support this feature.');
      break;
    case 2900001:
      console.error('Service stopped. Bluetooth service is not running.');
      break;
    case 2900003:
      console.error('Bluetooth disabled. Please enable Bluetooth.');
      break;
    case 2900099:
      console.error('Operation failed. Unknown error occurred.');
      break;
    default:
      console.error('Unknown error: ' + error.code + ', message: ' + error.message);
  }
}
```

### 步骤9：降级处理

**降级处理代码**：
```typescript
// 扫描失败时的降级方案
async function fallbackToDeviceList(): Promise<void> {
  try {
    // 尝试获取已配对设备作为降级方案
    let devices = connection.getPairedDevices();
    if (devices.length > 0) {
      console.info('Fallback: Found ' + devices.length + ' paired devices');
      // 可以直接对已配对设备发起连接
      return;
    }
    
    // 如果没有已配对设备，提示用户
    console.warn('No paired devices found. Please pair devices manually in system settings.');
  } catch (err) {
    console.error('Fallback failed: ' + (err as BusinessError).message);
    // 最终降级：提示用户手动操作
    console.warn('Please enable Bluetooth and scan devices manually.');
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied. | 申请ohos.permission.ACCESS_BLUETOOTH权限 |
| 401 | Invalid parameter. | 检查参数类型和取值范围，确保参数正确 |
| 801 | Capability not supported. | 设备不支持该功能，检查设备兼容性 |
| 2900001 | Service stopped. | 蓝牙服务停止，重启蓝牙或重启设备 |
| 2900003 | Bluetooth disabled. | 蓝牙未开启，提示用户开启蓝牙 |
| 2900099 | Operation failed. | 操作失败，查看日志分析具体原因 |

**错误处理最佳实践**：
- 所有API调用都应包含try-catch错误处理
- 根据错误码提供用户友好的提示
- 对于权限错误，引导用户申请权限
- 对于蓝牙未开启，引导用户开启蓝牙
- 对于操作失败，提供降级方案

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "最新版本",
    "@kit.BasicServicesKit": "最新版本"
  }
}
```

### 环境要求
- HarmonyOS SDK: 4.0及以上版本
- DevEco Studio: 3.1及以上版本
- API version: 10及以上（基础功能），18及以上（完整功能）

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：
- 确保项目已配置HarmonyOS SDK
- 在module.json5中添加依赖声明
- 检查SDK版本是否支持该Kit

**问题2：权限未声明**
```
Error: Permission denied (201)
```
**解决方法**：
- 在module.json5的requestPermissions中添加ohos.permission.ACCESS_BLUETOOTH
- 参考声明权限文档正确配置权限
- 如需用户授权，参考向用户申请授权文档

**问题3：API不存在**
```
Error: Property 'discoveryResult' does not exist
```
**解决方法**：
- discoveryResult从API version 18开始支持
- 检查项目的compileSdkVersion是否>=18
- 如使用API version 10-17，改用bluetoothDeviceFind

**问题4：设备地址变更**
```
Warning: Device address changed unexpectedly
```
**解决方法**：
- 获取的地址为虚拟MAC地址，可能变更
- 已配对设备的地址不会变更
- 建议使用access.addPersistentDeviceId持久化地址
- 参考js-apis-bluetooth-access文档

## 常见问题与解决方法

### Q1：扫描不到任何设备
**原因**：
- 本机蓝牙未开启
- 周边设备未设置为可被发现状态
- 权限未申请或未授权
- 蓝牙硬件故障

**解决方法**：
- 检查并开启本机蓝牙
- 确认周边设备蓝牙已开启且处于可被发现状态
- 申请ohos.permission.ACCESS_BLUETOOTH权限
- 重启蓝牙或重启设备
- 检查蓝牙硬件是否正常

### Q2：扫描到的设备地址与实际地址不符
**原因**：
- 系统出于信息安全考虑返回虚拟MAC地址
- 未配对设备的虚拟地址可能变更

**解决方法**：
- 理解虚拟地址机制（已配对地址不会变更）
- 如需持久化地址，使用access.addPersistentDeviceId方法
- 对于已配对设备，地址稳定可放心使用
- 参考js-apis-bluetooth-access文档了解地址持久化

### Q3：扫描过程持续太久无法停止
**原因**：
- 正常扫描过程持续约12秒
- 可能未正确调用stopBluetoothDiscovery

**解决方法**：
- 扫描12秒后会自动停止
- 如需提前停止，主动调用stopBluetoothDiscovery
- 使用isBluetoothDiscovering()检查扫描状态
- 确保扫描到目标设备后立即停止扫描

### Q4：无法设置扫描模式
**原因**：
- 非系统应用一般不关注扫描模式
- 系统设置应用统一管理扫描模式
- 权限不足或参数错误

**解决方法**：
- 系统应用在蓝牙设置界面前台时自动设置为可发现可连接
- 系统应用在后台时自动设置为可连接
- 检查权限和参数是否正确
- 一般应用无需手动设置扫描模式

### Q5：discoveryResult和bluetoothDeviceFind的区别
**原因**：
- 两个API用于不同版本

**解决方法**：
- discoveryResult (API version 18+): 返回设备地址、名称、信号强度、类型
- bluetoothDeviceFind (API version 10-17): 仅返回设备地址
- 推荐使用discoveryResult获取更丰富信息
- 根据项目API version选择合适的API

### Q6：如何判断设备是否已配对
**原因**：
- 扫描前想确认设备配对状态

**解决方法**：
- 使用getPairedDevices()获取已配对设备列表
- 使用getPairState(deviceId)查询特定设备配对状态
- BondState枚举：0-未配对，1-配对中，2-已配对
- 已配对设备可以直接发起连接，无需重新配对

### Q7：扫描过程中应用崩溃
**原因**：
- 未正确处理错误
- 内存或资源不足
- 蓝牙服务异常

**解决方法**：
- 所有API调用添加try-catch错误处理
- 扫描消耗资源，及时停止扫描释放资源
- 检查蓝牙服务状态，必要时重启蓝牙
- 避免扫描过程中执行其他高消耗操作

### Q8：虚拟MAC地址无法持久化保存
**原因**：
- 虚拟地址可能变更，需要特殊方法持久化

**解决方法**：
- 使用access.addPersistentDeviceId方法持久化地址
- 参考js-apis-bluetooth-access文档
- 已配对设备的虚拟地址不会变更，可直接保存
- 未配对设备建议先配对再保存地址

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "discoveredDevices": [
    {
      "deviceId": "XX:XX:XX:XX:XX:XX",
      "deviceName": "DeviceName",
      "rssi": -50,
      "deviceClass": {
        "majorClass": 0,
        "majorMinorClass": 0,
        "classOfDevice": 0
      }
    }
  ],
  "pairedDevices": ["XX:XX:XX:XX:XX:XX"],
  "scanMode": 4,
  "isDiscovering": false,
  "apiUsed": [
    "connection.on('discoveryResult')",
    "connection.startBluetoothDiscovery()",
    "connection.isBluetoothDiscovering()",
    "connection.stopBluetoothDiscovery()",
    "connection.off('discoveryResult')",
    "connection.getBluetoothScanMode()",
    "connection.setBluetoothScanMode()",
    "connection.getPairedDevices()",
    "connection.getPairState()"
  ]
}
```

**输出字段说明**：
- status: 执行状态（success/failed）
- discoveredDevices: 扫描到的设备列表
- pairedDevices: 已配对设备地址列表
- scanMode: 当前扫描模式
- isDiscovering: 是否正在扫描
- apiUsed: 使用的API列表

## 参考文档

- [API开发指南](references/br-discovery-development-guide.md)
- [API参考说明](references/js-apis-bluetooth-connection.md)

## 完整示例代码

- [ArkTS示例](assets/DiscoveryDeviceManager.ets)

## 测试用例

### 正向测试用例
- [扫描周边设备](tests/test_scan_devices.py)：测试正常扫描流程
- [设置扫描模式](tests/test_set_scan_mode.py)：测试扫描模式设置
- [获取已配对设备](tests/test_get_paired_devices.py)：测试获取已配对设备列表

### 边界测试用例
- [扫描状态检查](tests/test_scan_status.py)：测试扫描状态检查逻辑
- [重复扫描防护](tests/test_duplicate_scan.py)：测试重复调用防护机制
- [扫描模式边界值](tests/test_scan_mode_boundary.py)：测试扫描模式边界值

### 异常测试用例
- [权限不足](tests/test_permission_denied.py)：测试权限不足场景
- [蓝牙未开启](tests/test_bluetooth_disabled.py)：测试蓝牙未开启场景
- [扫描失败降级](tests/test_scan_fallback.py)：测试扫描失败降级方案