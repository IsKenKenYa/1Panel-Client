---
name: hmos-wear-engine-kit-device-info-query
description: 查询穿戴设备信息，支持WearEngine能力集查询、Device能力集查询、设备SN查询，需要设备基础信息权限或设备标识符权限，适用于设备能力判断、设备识别场景
---

# 穿戴设备信息查询技能

## 功能描述

本技能提供查询华为穿戴设备信息的完整能力，包括三个核心功能：
1. 查询穿戴设备是否支持某种WearEngine能力集
2. 查询穿戴设备是否支持某种Device能力集
3. 查询设备序列号(SN)

通过Wear Engine Kit提供的API接口，应用可以在手机侧查询已连接穿戴设备的能力支持情况和设备标识信息，为后续功能开发提供基础数据支持。

**核心能力**：
- WearEngine能力集查询：判断设备是否支持P2P通信、Monitor、Notification、Sensor等能力
- Device能力集查询：判断设备是否支持应用安装、CBTI数字疗法等能力
- 设备SN查询：获取设备的唯一序列号标识

**适用场景**：
- 设备能力判断：在调用特定功能前先验证设备是否支持
- 设备识别：通过SN唯一标识设备
- 功能适配：根据设备能力动态调整应用功能

## 使用场景

### 触发词
- "查询穿戴设备信息"
- "查询设备能力"
- "获取设备SN"
- "判断设备是否支持某能力"
- "WearEngine能力查询"
- "Device能力查询"
- "设备信息查询"

### 能做
- 查询已连接穿戴设备的WearEngine能力集支持情况
- 查询已连接穿戴设备的Device能力集支持情况
- 查询已连接穿戴设备的序列号(SN)
- 获取已连接设备列表
- 判断设备是否支持特定能力后再进行后续操作

### 绝不做
- 不查询未连接设备的信息
- 不查询超出权限范围的信息(如无设备标识符权限时查询SN)
- 不修改设备信息或配置
- 不进行设备绑定或解绑操作
- 不处理与设备信息查询无关的请求

### 补充
- 查询WearEngine能力和Device能力需要申请设备基础信息权限
- 查询设备SN需要申请设备标识符权限(受限开放)并获得用户授权
- 所有查询操作需要在设备已连接状态下进行
- 需要在开发者联盟申请接入Wear Engine服务并配置相关权限
- 仅支持Stage模型，可在Phone、Tablet设备上调用

## 调用规范和规则

### 输入约束
- 设备状态：设备必须已连接并配对
- 权限要求：
  - WearEngine/Device能力查询：需申请设备基础信息权限
  - SN查询：需申请设备标识符权限(受限)并获得用户授权
- 网络状态：需要网络连接正常
- 账号状态：用户需已登录华为账号
- 服务申请：应用需已在开发者联盟申请Wear Engine服务

### 执行约束
- 最大查询耗时：10秒/次
- 最大并发查询：建议不超过5个并发查询请求
- 查询频次：避免频繁重复查询，建议缓存查询结果
- 设备数量：单次getConnectedDevices最多返回当前所有已连接设备

### 内容约束
- 禁止查询未授权的设备信息
- 禁止绕过权限检查直接查询
- 禁止在未申请服务的情况下调用API
- 禁止使用硬编码的设备ID
- 禁止在未验证设备连接状态下查询

### 降级约束
- 设备未连接：提示用户先连接设备，返回空设备列表
- 权限不足：提示用户申请相应权限，终止查询操作
- 网络异常：返回错误码1008500001，建议稍后重试
- 未申请服务：返回错误码1008500004，提示开发者先申请服务
- 未登录账号：返回错误码1008500008，提示用户登录华为账号

## 调用流程和步骤

### 步骤1：准备阶段

**前置校验**：
1. 验证应用是否已申请Wear Engine服务
2. 验证是否已配置相应权限(设备基础信息权限或设备标识符权限)
3. 验证用户是否已登录华为账号
4. 验证用户是否已同意隐私协议
5. 验证当前设备是否为Phone或Tablet(其他设备返回801错误)

**参数准备**：
```typescript
// 导入必要模块
import { wearEngine } from '@kit.WearEngine';
import { BusinessError } from '@kit.BasicServicesKit';
import { common } from '@kit.AbilityKit';

// 准备Context上下文
let context: common.UIAbilityContext = this.getUIContext().getHostContext();
```

### 步骤2：获取DeviceClient和设备列表

**获取DeviceClient**：
```typescript
// 获取DeviceClient对象
let deviceClient: wearEngine.DeviceClient = wearEngine.getDeviceClient(context);
console.info('Succeeded in getting device client.');
```

**获取已连接设备列表**：
```typescript
// 获取已连接设备列表
let deviceList: wearEngine.Device[] = [];
try {
  deviceList = await deviceClient.getConnectedDevices();
  console.info(`Succeeded in getting deviceList, devices number is ${deviceList.length}`);
  
  // 校验设备列表是否为空
  if (deviceList.length === 0) {
    console.warn('No connected devices found.');
    return;
  }
} catch (error) {
  let err: BusinessError = error as BusinessError;
  console.error(`Failed to get deviceList. Code is ${err.code}, message is ${err.message}`);
  // 根据错误码进行降级处理
  handleGetDevicesError(err);
}
```

### 步骤3：选择目标设备

**设备选择逻辑**：
```typescript
// 从设备列表中选取需要操作的设备
// 可根据设备名称、型号、类型等属性选择
if (deviceList.length > 0) {
  // 示例：选择第一个设备作为目标设备
  let targetDevice: wearEngine.Device = deviceList[0];
  
  // 可选：打印设备信息
  console.info(`Target device info:`);
  console.info(`  Name: ${targetDevice.name}`);
  console.info(`  Model: ${targetDevice.model}`);
  console.info(`  Category: ${targetDevice.category}`);
  console.info(`  IsSmartWatch: ${targetDevice.isSmartWatch}`);
  console.info(`  SoftwareVersion: ${targetDevice.softwareVersion}`);
}
```

### 步骤4：查询WearEngine能力集

**查询示例(P2P能力)**：
```typescript
// 查询设备是否支持P2P通信能力
if (targetDevice) {
  try {
    let isSupportP2P: boolean = await targetDevice.isWearEngineCapabilitySupported(
      wearEngine.WearEngineCapability.P2P_COMMUNICATION
    );
    console.info(`P2P capability support status: ${isSupportP2P}`);
    
    if (isSupportP2P) {
      console.info('Device supports P2P communication.');
      // 可以进行后续的P2P通信操作
    } else {
      console.warn('Device does not support P2P communication.');
      // 提示用户或降级处理
    }
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Failed to check P2P capability. Code is ${err.code}, message is ${err.message}`);
    handleCapabilityQueryError(err);
  }
}
```

**支持的WearEngine能力类型**：
```typescript
// WearEngineCapability枚举值
enum WearEngineCapability {
  P2P_COMMUNICATION = 1,  // P2P(peer-to-peer)能力
  MONITOR = 2,            // Monitor能力(设备状态监控)
  NOTIFICATION = 3,       // Notify能力(通知发送)
  SENSOR = 4              // Sensor能力(传感器数据获取)
}
```

### 步骤5：查询Device能力集

**查询示例(应用安装能力)**：
```typescript
// 查询设备是否支持应用安装能力
if (targetDevice) {
  try {
    let isSupportInstall: boolean = await targetDevice.isDeviceCapabilitySupported(
      wearEngine.DeviceCapability.APP_INSTALLATION
    );
    console.info(`App installation capability support status: ${isSupportInstall}`);
    
    if (isSupportInstall) {
      console.info('Device supports app installation.');
      // 可以进行应用安装操作
    } else {
      console.warn('Device does not support app installation.');
    }
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Failed to check install capability. Code is ${err.code}, message is ${err.message}`);
    handleCapabilityQueryError(err);
  }
}
```

**支持的Device能力类型**：
```typescript
// DeviceCapability枚举值
enum DeviceCapability {
  APP_INSTALLATION = 14,  // 支持应用安装能力
  CBT_I = 128             // CBTI数字疗法能力
}
```

### 步骤6：查询设备SN

**查询设备序列号**：
```typescript
// 查询设备SN(需要设备标识符权限)
if (targetDevice) {
  try {
    let sn: string = await targetDevice.getSerialNumber();
    console.info(`Device SN: ${sn}`);
    
    // SN可用于设备唯一标识
    // 注意：SN属于敏感信息，请妥善处理
    
  } catch (error) {
    let err: BusinessError = error as BusinessError;
    console.error(`Failed to get device SN. Code is ${err.code}, message is ${err.message}`);
    
    // SN查询常见错误：
    // 1008500005: 华为账号未授权
    // 需提示用户在华为健康应用中授权
    handleSNQueryError(err);
  }
}
```

### 步骤7：错误处理

**错误处理函数**：
```typescript
// 处理getConnectedDevices错误
function handleGetDevicesError(error: BusinessError): void {
  switch (error.code) {
    case 1008500001:
      console.error('Network error. Please check network connection.');
      break;
    case 1008500004:
      console.error('App has not applied for Wear Engine service. Please apply first.');
      break;
    case 1008500006:
      console.error('User privacy is not agreed. Please guide user to agree.');
      break;
    case 1008500008:
      console.error('User has not logged in with HUAWEI ID. Please login first.');
      break;
    case 1008500009:
      console.error('Failed to obtain account information. Please try again.');
      break;
    case 1008509999:
      console.error('Internal error. Please contact support.');
      break;
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}

// 处理能力查询错误
function handleCapabilityQueryError(error: BusinessError): void {
  switch (error.code) {
    case 401:
      console.error('Parameter error. Please check capability parameter.');
      break;
    case 801:
      console.error('Capability not supported on current device.');
      break;
    case 1008500002:
      console.error('No device is bound. Please bind device first.');
      break;
    case 1008500003:
      console.error('Device disconnected. Please reconnect device.');
      break;
    case 1008500004:
      console.error('App has not applied for Wear Engine service.');
      break;
    case 1008500006:
      console.error('User privacy is not agreed.');
      break;
    case 1008500008:
      console.error('User has not logged in with HUAWEI ID.');
      break;
    case 1008500009:
      console.error('Failed to obtain account information.');
      break;
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}

// 处理SN查询错误
function handleSNQueryError(error: BusinessError): void {
  switch (error.code) {
    case 801:
      console.error('Capability not supported on current device.');
      break;
    case 1008500001:
      console.error('Network error.');
      break;
    case 1008500002:
      console.error('No device is bound.');
      break;
    case 1008500003:
      console.error('Device disconnected.');
      break;
    case 1008500004:
      console.error('App has not applied for Wear Engine service.');
      break;
    case 1008500005:
      console.error('HUAWEI ID is not authorized. Please authorize in Huawei Health app.');
      break;
    case 1008500006:
      console.error('User privacy is not agreed.');
      break;
    case 1008500008:
      console.error('User has not logged in with HUAWEI ID.');
      break;
    case 1008500009:
      console.error('Failed to obtain account information.');
      break;
    default:
      console.error(`Unknown error: ${error.code}, ${error.message}`);
  }
}
```

### 步骤8：降级处理

**降级方案示例**：
```typescript
// 降级处理：设备未连接时的处理
async function handleNoConnectedDevice(): Promise<void> {
  console.warn('No connected device found.');
  // 方案1：提示用户连接设备
  // 方案2：提供设备连接引导
  // 方案3：使用本地缓存的历史设备信息(如果有)
}

// 降级处理：权限不足时的处理
async function handlePermissionDenied(permissionType: string): Promise<void> {
  console.warn(`Permission denied: ${permissionType}`);
  
  if (permissionType === 'DEVICE_IDENTIFIER') {
    // SN查询权限不足
    // 方案1：提示用户在华为健康应用中授权
    // 方案2：使用其他设备标识方式(如randomId)
    console.warn('Please authorize device identifier permission in Huawei Health app.');
  } else if (permissionType === 'DEVICE_BASIC_INFO') {
    // 设备基础信息权限不足
    // 方案：提示用户申请权限
    console.warn('Please apply for device basic info permission.');
  }
}

// 降级处理：能力不支持时的处理
async function handleCapabilityNotSupported(capability: string): Promise<void> {
  console.warn(`Device does not support capability: ${capability}`);
  // 方案1：提示用户设备不支持该功能
  // 方案2：使用替代方案或简化功能
  // 方案3：跳过该功能继续其他操作
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 401 | 参数错误。可能原因：1. 必填参数未指定 2. 参数类型错误 3. 参数校验失败 | 检查传入的capability参数是否为有效的枚举值 |
| 801 | 能力不支持。当前设备不支持此系统能力 | 仅在Phone、Tablet设备上调用，或检查设备是否支持该能力 |
| 1008500001 | 网络错误。网络不可用 | 检查网络连接状态，稍后重试 |
| 1008500002 | 未绑定设备。没有绑定的设备 | 先在华为健康应用中绑定设备 |
| 1008500003 | 设备断开连接 | 重新连接设备 |
| 1008500004 | 应用未申请Wear Engine服务 | 在开发者联盟申请接入Wear Engine服务 |
| 1008500005 | 华为账号未授权 | 在华为健康应用中授权设备标识符权限 |
| 1008500006 | 用户隐私未同意 | 引导用户同意隐私协议 |
| 1008500007 | 设备能力不支持 | 查询设备能力后再调用相应功能 |
| 1008500008 | 账号错误。用户未登录华为账号 | 提示用户登录华为账号 |
| 1008500009 | 账号错误。获取账号信息失败 | 稍后重试或重新登录 |
| 1008500010 | 设备ID无效 | 使用正确的设备randomId |
| 1008509999 | 内部错误 | 联系技术支持或稍后重试 |

## 编译和修复问题

### 依赖声明
```json
{
  "dependencies": {
    "@kit.WearEngine": "5.0.0(12)",
    "@kit.BasicServicesKit": "5.0.0(12)",
    "@kit.AbilityKit": "5.0.0(12)"
  }
}
```

### 环境要求
- HarmonyOS版本：5.0.0(12)及以上
- DevEco Studio版本：5.0及以上
- 目标设备：Phone、Tablet
- 系统能力：SystemCapability.Health.WearEngine

### 常见编译问题

**问题1：导入wearEngine模块失败**
```
Error: Cannot find module '@kit.WearEngine'
```
**解决方法**：
- 确保HarmonyOS SDK版本为5.0.0(12)及以上
- 在DevEco Studio中更新SDK
- 检查module.json5中的依赖配置

**问题2：getUIContext()方法不存在**
```
Error: Property 'getUIContext' does not exist
```
**解决方法**：
- 确保在UIAbility或UI组件中调用
- 使用正确的Context获取方式：`this.context`或`getContext(this)`
- 确保使用Stage模型

**问题3：权限未配置导致运行时错误**
```
Error: Permission denied
```
**解决方法**：
- 在module.json5中配置所需权限
- 在开发者联盟申请相应权限
- 引导用户授权

**问题4：设备类型不支持**
```
Error code: 801
```
**解决方法**：
- 仅在Phone、Tablet设备上运行
- 使用canIUse()接口检查设备支持情况
- 在其他设备类型上禁用相关功能

## 常见问题与解决方法

### Q1：查询设备列表返回空数组
**原因**：
- 设备未连接或未配对
- 用户未登录华为账号
- 用户未同意隐私协议
- 应用未申请Wear Engine服务

**解决方法**：
- 检查设备连接状态，确保设备已配对并连接
- 提示用户登录华为账号
- 引导用户同意隐私协议
- 在开发者联盟申请Wear Engine服务

### Q2：查询设备能力时返回false
**原因**：
- 设备确实不支持该能力
- 设备断开连接
- 设备型号较旧不支持新能力

**解决方法**：
- 根据返回结果调整应用功能
- 查询前先检查设备连接状态
- 使用设备型号和软件版本判断能力支持情况
- 提供降级方案或替代功能

### Q3：查询设备SN时返回错误1008500005
**原因**：
- 用户未在华为健康应用中授权设备标识符权限
- 华为账号权限不足

**解决方法**：
- 提示用户打开华为健康应用
- 在设备详情页授权设备标识符权限
- 提供详细的授权引导流程
- 使用randomId作为临时替代标识

### Q4：网络错误导致查询失败
**原因**：
- 网络连接不稳定
- Wear Engine服务暂时不可用

**解决方法**：
- 检查网络连接状态
- 实现重试机制(最多3次)
- 使用本地缓存的历史数据
- 提示用户检查网络后重试

### Q5：用户未同意隐私协议
**原因**：
- 首次使用Wear Engine功能
- 用户拒绝了隐私协议

**解决方法**：
- 使用AuthClient.requestAuthorization申请权限
- 清晰说明隐私政策内容
- 引导用户重新同意隐私协议
- 提供隐私政策详细说明页面

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "deviceCount": 1,
  "deviceInfo": {
    "name": "华为手表",
    "model": "WATCH-XXX",
    "randomId": "xxxx-xxxx-xxxx",
    "isSmartWatch": true,
    "category": "WATCH",
    "softwareVersion": "5.0.0"
  },
  "capabilitySupport": {
    "wearEngineCapabilities": {
      "P2P_COMMUNICATION": true,
      "MONITOR": true,
      "NOTIFICATION": true,
      "SENSOR": true
    },
    "deviceCapabilities": {
      "APP_INSTALLATION": true,
      "CBT_I": false
    }
  },
  "deviceSN": "XXXXXXXXXXX",
  "apiUsed": [
    "wearEngine.getDeviceClient",
    "deviceClient.getConnectedDevices",
    "device.isWearEngineCapabilitySupported",
    "device.isDeviceCapabilitySupported",
    "device.getSerialNumber"
  ],
  "errors": []
}
```

## 参考文档

- [申请接入Wear Engine服务](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/wearengine_apply)
- [wearEngine API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/wearengine_api)

## 完整示例代码

- [ArkTS完整示例](assets/query_device_info_example.ets)
- [错误处理示例](assets/error_handling_example.ets)
- [完整查询流程示例](assets/full_query_flow_example.ets)

## 测试用例

### 正向测试用例
- [查询已连接设备的WearEngine能力](tests/test_positive_wear_engine_capability.ets)：测试正常设备能力查询
- [查询已连接设备的Device能力](tests/test_positive_device_capability.ets)：测试正常Device能力查询
- [查询已连接设备的SN](tests/test_positive_device_sn.ets)：测试正常SN查询(需权限)

### 边界测试用例
- [查询空设备列表时的处理](tests/test_boundary_empty_device_list.ets)：测试无设备连接时的处理
- [查询所有WearEngine能力类型](tests/test_boundary_all_wear_engine_capabilities.ets)：测试所有能力类型的查询
- [查询所有Device能力类型](tests/test_boundary_all_device_capabilities.ets)：测试所有Device能力查询

### 异常测试用例
- [设备未连接时的查询](tests/test_exception_device_disconnected.ets)：测试设备断开时的错误处理
- [无权限时的SN查询](tests/test_exception_no_permission.ets)：测试权限不足时的错误处理
- [网络异常时的查询](tests/test_exception_network_error.ets)：测试网络错误时的降级处理
- [无效capability参数查询](tests/test_exception_invalid_capability.ets)：测试参数错误时的处理