---
name: hmos-connectivity-kit-bluetooth-pair-connect
description: 主动配对蓝牙设备并连接设备支持的Profile能力(A2DP/HFP/HID),需要ACCESS_BLUETOOTH权限,适用于蓝牙音频设备、键盘鼠标等外设连接场景
---

# 蓝牙设备配对与连接技能

## 功能描述

本技能提供传统蓝牙设备的主动配对和Profile连接能力。支持主动发起配对流程,并在配对完成后连接设备支持的Profile协议能力(包括A2DP、HFP、HID)。蓝牙配对过程中系统会弹出对话框请求用户确认,配对成功后可获取设备的Profile能力信息并发起连接。适用于蓝牙耳机、音箱、键盘、鼠标等外设的配对和连接场景。

## 使用场景

### 触发词
- "配对蓝牙设备"
- "连接蓝牙设备"
- "蓝牙配对"
- "连接蓝牙耳机"
- "连接蓝牙音箱"
- "连接蓝牙键盘"
- "连接蓝牙鼠标"

### 能做
- 主动发起与传统蓝牙设备的配对流程
- 订阅和监听蓝牙配对状态变化事件
- 查询已配对设备的Profile协议能力(UUID)
- 连接已配对设备支持的Profile(A2DP、HFP、HID)
- 监听Profile连接状态变化事件
- 支持使用虚拟MAC地址或实际MAC地址发起配对(API version 21+)

### 绝不做
- 不处理低功耗蓝牙(BLE)设备的配对和连接
- 不处理SPP(串行端口Profile)的连接(需使用专门的SPP技能)
- 不主动断开已连接的Profile
- 不取消已建立的配对关系
- 不处理蓝牙设备的发现和扫描流程

### 补充
- 配对过程中系统会弹出对话框请求用户确认,需要用户手动同意才能完成配对
- 蓝牙子系统会给每个外设分配虚拟MAC地址,配对时可使用虚拟或实际MAC地址
- 配对完成后建议在30秒内发起Profile连接
- 需要申请ohos.permission.ACCESS_BLUETOOTH权限
- 若不知道目标设备地址类型,推荐使用API version 20及以前的配对方式
- 若已知目标设备地址类型,推荐使用API version 21支持的配对方式(需指定地址类型)

## 调用规范和规则

### 输入约束
- 设备地址格式: 必须符合MAC地址格式"XX:XX:XX:XX:XX:XX"(如"11:22:33:44:55:66")
- 地址类型: 使用API version 21+配对方式时,必须指定正确的地址类型(REAL或VIRTUAL)
- 配对超时: 系统对话框等待用户确认时间有限,建议在发现设备后尽快发起配对
- Profile连接时间窗口: 配对完成后30秒内为最佳连接时机

### 执行约束
- 权限检查: 必须已申请并获得ohos.permission.ACCESS_BLUETOOTH权限
- 配对状态: 发起配对前应检查目标设备配对状态(建议为BOND_STATE_INVALID)
- Profile能力检查: 连接前应先查询设备支持的Profile UUID,避免连接不支持的Profile
- 事件订阅: 必须先订阅bondStateChange事件才能获取配对结果
- 最大配对等待时间: 建议不超过60秒(用户确认对话框超时)
- 最大Profile连接等待时间: 建议不超过30秒

### 内容约束
- 禁止生成: 不生成扫描设备的代码(需使用专门的设备发现技能)
- 禁止生成: 不生成SPP连接代码(需使用专门的SPP技能)
- 禁止生成: 不生成取消配对或断开连接的代码
- 禁止使用高危函数: 不使用eval、exec等高危函数
- 参数验证: 必须对设备地址格式进行验证

### 降级约束
- 配对失败: 提示用户检查蓝牙开关状态、设备距离、设备是否可被发现
- Profile不支持: 提示用户该设备不支持所需Profile,建议使用其他设备
- 连接失败: 建议重新配对或检查设备状态
- 权限缺失: 提示用户申请必要权限并引导到权限申请流程
- 用户拒绝配对: 提示用户手动在系统蓝牙设置中配对设备

## 调用流程和步骤

### 步骤1: 申请蓝牙权限

**前置校验**:
1. 检查是否已申请ohos.permission.ACCESS_BLUETOOTH权限
2. 检查蓝牙开关是否已开启

**参数准备**:
```typescript
// 在module.json5中配置权限
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

**权限申请代码**:
```typescript
import { abilityAccessCtrl, common, Permissions } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function requestBluetoothPermission(context: common.UIAbilityContext): Promise<boolean> {
  const permission: Permissions = 'ohos.permission.ACCESS_BLUETOOTH';
  const atManager = abilityAccessCtrl.createAtManager();
  
  try {
    const grantStatus = await atManager.checkAccessToken(context.applicationInfo.accessTokenId, permission);
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      console.info('Bluetooth permission already granted');
      return true;
    }
    
    // 申请权限
    const result = await atManager.requestPermissionsFromUser(context, [permission]);
    if (result.authResults[0] === 0) {
      console.info('Bluetooth permission granted by user');
      return true;
    } else {
      console.error('Bluetooth permission denied by user');
      return false;
    }
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Permission check failed: code=${error.code}, message=${error.message}`);
    return false;
  }
}
```

### 步骤2: 导入所需API模块

```typescript
import { connection, a2dp, hfp, hid, baseProfile, constant, common } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤3: 订阅配对状态变化事件

**事件订阅代码**:
```typescript
// 定义配对状态变化回调函数
function onBondStateChange(data: connection.BondStateParam): void {
  console.info(`Bond state changed: device=${data.deviceId}, state=${data.state}`);
  
  switch (data.state) {
    case connection.BondState.BOND_STATE_BONDING:
      console.info('Device is bonding');
      break;
    case connection.BondState.BOND_STATE_BONDED:
      console.info('Device bonded successfully');
      // 配对成功后可以发起Profile连接
      break;
    case connection.BondState.BOND_STATE_INVALID:
      console.info('Device bond state is invalid or bond failed');
      break;
  }
}

try {
  connection.on('bondStateChange', onBondStateChange);
  console.info('Subscribed to bond state change event');
} catch (err) {
  const error = err as BusinessError;
  console.error(`Subscribe failed: code=${error.code}, message=${error.message}`);
}
```

### 步骤4: 发起蓝牙配对

**方式1: 使用虚拟MAC地址配对(API version 20及以前)**

适用于不知道目标设备地址类型的情况:

```typescript
// 通过设备发现流程获取目标设备地址
const targetDevice = '11:22:33:44:55:66';

async function pairDeviceUsingVirtualAddress(deviceId: string): Promise<void> {
  try {
    await connection.pairDevice(deviceId);
    console.info(`Pairing initiated for device: ${deviceId}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Pair failed: code=${error.code}, message=${error.message}`);
    
    // 错误处理
    switch (error.code) {
      case 2900003:
        console.error('Bluetooth is disabled, please enable Bluetooth first');
        break;
      case 2900099:
        console.error('Operation failed, please check device distance and availability');
        break;
      default:
        console.error('Unknown error occurred');
    }
  }
}

// 发起配对
pairDeviceUsingVirtualAddress(targetDevice);
```

**方式2: 使用实际MAC地址配对(API version 21+)**

适用于已知目标设备地址类型的情况:

```typescript
const targetDevice = '11:22:33:44:55:66';

async function pairDeviceWithAddressType(deviceId: string, addressType: common.BluetoothAddressType): Promise<void> {
  try {
    const btAddr: common.BluetoothAddress = {
      address: deviceId,
      addressType: addressType // REAL或VIRTUAL
    };
    
    await connection.pairDevice(btAddr);
    console.info(`Pairing initiated for device: ${deviceId} with address type: ${addressType}`);
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Pair failed: code=${error.code}, message=${error.message}`);
  }
}

// 使用实际MAC地址发起配对
pairDeviceWithAddressType(targetDevice, common.BluetoothAddressType.REAL);
```

### 步骤5: 连接已配对设备的Profile

**查询设备Profile能力**:
```typescript
async function queryDeviceProfiles(deviceId: string): Promise<Array<connection.ProfileUuids>> {
  try {
    const uuids = await connection.getRemoteProfileUuids(deviceId);
    console.info(`Device ${deviceId} supports profiles: ${JSON.stringify(uuids)}`);
    return uuids;
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Query profiles failed: code=${error.code}, message=${error.message}`);
    return [];
  }
}
```

**订阅Profile连接状态**:
```typescript
// 创建Profile实例
const a2dpSrcProfile = a2dp.createA2dpSrcProfile();
const hfpAgProfile = hfp.createHfpAgProfile();
const hidHostProfile = hid.createHidHostProfile();

// 定义连接状态回调函数
function onA2dpConnectionStateChange(data: baseProfile.StateChangeParam): void {
  console.info(`A2DP connection state: device=${data.deviceId}, state=${data.state}`);
}

function onHfpConnectionStateChange(data: baseProfile.StateChangeParam): void {
  console.info(`HFP connection state: device=${data.deviceId}, state=${data.state}`);
}

function onHidConnectionStateChange(data: baseProfile.StateChangeParam): void {
  console.info(`HID connection state: device=${data.deviceId}, state=${data.state}`);
}

// 订阅连接状态变化事件
try {
  a2dpSrcProfile.on('connectionStateChange', onA2dpConnectionStateChange);
  hfpAgProfile.on('connectionStateChange', onHfpConnectionStateChange);
  hidHostProfile.on('connectionStateChange', onHidConnectionStateChange);
} catch (err) {
  const error = err as BusinessError;
  console.error(`Subscribe profile state failed: code=${error.code}, message=${error.message}`);
}
```

**发起Profile连接**:
```typescript
async function connectDeviceProfiles(deviceId: string): Promise<void> {
  try {
    // 查询设备支持的Profile
    const uuids = await queryDeviceProfiles(deviceId);
    
    let supportedProfiles = 0;
    
    // 检查是否支持A2DP
    if (uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_A2DP_SINK.toLowerCase())) {
      console.info('Device supports A2DP Sink profile');
      supportedProfiles++;
    }
    
    // 检查是否支持HFP
    if (uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HFP_HF.toLowerCase())) {
      console.info('Device supports HFP HF profile');
      supportedProfiles++;
    }
    
    // 检查是否支持HID
    if (uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HID.toLowerCase()) ||
        uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HOGP.toLowerCase())) {
      console.info('Device supports HID profile');
      supportedProfiles++;
    }
    
    if (supportedProfiles > 0) {
      // 发起连接所有支持的Profile
      await connection.connectAllowedProfiles(deviceId);
      console.info(`Connecting profiles for device: ${deviceId}`);
    } else {
      console.warn(`Device does not support A2DP/HFP/HID profiles`);
    }
  } catch (err) {
    const error = err as BusinessError;
    console.error(`Connect profiles failed: code=${error.code}, message=${error.message}`);
  }
}
```

### 步骤6: 错误处理和降级方案

**完整错误处理代码**:
```typescript
function handleBluetoothError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please request ACCESS_BLUETOOTH permission');
      // 降级方案: 引导用户到权限设置页面
      break;
    case 401:
      console.error('Invalid parameter. Please check device address format');
      // 降级方案: 提示用户检查设备地址
      break;
    case 801:
      console.error('Capability not supported on this device');
      // 降级方案: 提示用户设备不支持蓝牙功能
      break;
    case 2900001:
      console.error('Bluetooth service stopped');
      // 降级方案: 建议重启设备或重新开启蓝牙
      break;
    case 2900003:
      console.error('Bluetooth is disabled');
      // 降级方案: 引导用户开启蓝牙开关
      break;
    case 2900099:
      console.error('Operation failed');
      // 降级方案: 建议重新配对或检查设备状态
      break;
    default:
      console.error(`Unknown error: code=${error.code}, message=${error.message}`);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied | 申请ohos.permission.ACCESS_BLUETOOTH权限 |
| 401 | Invalid parameter | 检查设备地址格式是否正确(XX:XX:XX:XX:XX:XX) |
| 801 | Capability not supported | 检查设备是否支持蓝牙功能 |
| 2900001 | Service stopped | 重启设备或重新开启蓝牙服务 |
| 2900003 | Bluetooth disabled | 开启蓝牙开关 |
| 2900099 | Operation failed | 检查设备距离、设备是否可被发现、重新配对 |

## 编译和修复问题

### 依赖声明

**module.json5权限配置**:
```json
{
  "module": {
    "name": "entry",
    "type": "entry",
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BLUETOOTH",
        "reason": "$string:bluetooth_permission_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**包导入**:
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "latest",
    "@kit.BasicServicesKit": "latest",
    "@kit.AbilityKit": "latest"
  }
}
```

### 环境要求
- HarmonyOS API version: 10+ (基础功能), API version 21+ (地址类型配对)
- 设备要求: 支持传统蓝牙的HarmonyOS设备
- 蓝牙状态: 蓝牙开关必须已开启

### 常见编译问题

**问题1: 权限未声明**
```
Error: Permission 'ohos.permission.ACCESS_BLUETOOTH' not declared in module.json5
```
**解决方法**: 在module.json5的requestPermissions数组中添加ACCESS_BLUETOOTH权限声明

**问题2: 导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**: 确保项目依赖配置正确,运行`npm install`或`ohpm install`安装依赖

**问题3: API版本不匹配**
```
Error: API 'connection.pairDevice(BluetoothAddress)' requires API version 21+
```
**解决方法**: 检查项目targetSdkVersion配置,确保>=21,或使用API version 20及以前的配对方式

**问题4: 设备地址格式错误**
```
Error: Invalid device address format
```
**解决方法**: 确保设备地址格式为"XX:XX:XX:XX:XX:XX",使用冒号分隔的六组十六进制数

## 常见问题与解决方法

### Q1: 配对失败,系统未弹出确认对话框
**原因**: 蓝牙开关未开启、设备距离过远、设备未处于可被发现状态
**解决方法**:
- 检查并开启蓝牙开关
- 确保设备距离在有效范围内(建议<10米)
- 确保目标设备已开启可被发现模式
- 检查目标设备是否已被其他设备配对占用

### Q2: 配对成功但无法连接Profile
**原因**: 设备不支持所需Profile、连接时机不当、设备状态异常
**解决方法**:
- 使用getRemoteProfileUuids查询设备支持的Profile UUID
- 确保在配对完成后30秒内发起Profile连接
- 检查设备是否处于可连接状态
- 重新配对设备后再尝试连接

### Q3: 无法获取设备Profile能力信息
**原因**: 设备未完成配对、查询时机不当
**解决方法**:
- 确保设备配对状态为BOND_STATE_BONDED
- 在配对完成后等待蓝牙子系统完成能力信息保存(建议等待1-2秒)
- 使用BondState.BOND_STATE_BONDED状态触发查询

### Q4: Profile连接状态监听失败
**原因**: Profile实例未创建、事件订阅失败
**解决方法**:
- 使用createA2dpSrcProfile/createHfpAgProfile/createHidHostProfile创建Profile实例
- 确保在发起连接前订阅connectionStateChange事件
- 检查订阅回调函数是否正确实现

### Q5: 使用API version 21配对方式失败
**原因**: 地址类型指定错误、目标SDK版本不足
**解决方法**:
- 确保targetSdkVersion>=21
- 正确指定地址类型(虚拟MAC使用VIRTUAL,实际MAC使用REAL)
- 若不确定地址类型,建议使用API version 20及以前的配对方式

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "operation": "bluetooth_pair_and_connect",
  "device": "11:22:33:44:55:66",
  "pairState": "BOND_STATE_BONDED",
  "supportedProfiles": ["A2DP_SINK", "HFP_HF"],
  "connectedProfiles": ["A2DP", "HFP"],
  "apiUsed": [
    "connection.on('bondStateChange')",
    "connection.pairDevice",
    "connection.getRemoteProfileUuids",
    "connection.connectAllowedProfiles",
    "a2dp.createA2dpSrcProfile",
    "hfp.createHfpAgProfile",
    "a2dpSrc.on('connectionStateChange')",
    "hfpAg.on('connectionStateChange')"
  ],
  "timestamp": "2026-07-03T10:30:00Z"
}
```

## 参考文档

- [配对与连接设备开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-pair-device-development-guide)
- [蓝牙connection模块API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-connection)
- [蓝牙common模块API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-common)
- [蓝牙constant模块API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-constant)
- [声明权限开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
- [传统蓝牙查找设备开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-discovery-development-guide)
- [连接和传输数据开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/spp-development-guide)

## 完整示例代码

- [完整ArkTS示例代码](assets/BluetoothPairConnectDemo.ets) - 包含配对、查询Profile能力、连接Profile的完整流程
- [权限申请示例](assets/PermissionRequest.ets) - 蓝牙权限申请流程
- [Profile连接管理示例](assets/ProfileConnectionManager.ets) - Profile连接状态管理

## 测试用例

### 正向测试用例
- [配对已知设备并连接A2DP Profile](tests/test_pair_connect_a2dp.ets) - 测试配对和A2DP连接成功场景
- [配对已知设备并连接多个Profile](tests/test_pair_connect_multiple_profiles.ets) - 测试配对和A2DP+HFP+HID连接成功场景
- [查询已配对设备Profile能力](tests/test_query_profile_uuids.ets) - 测试Profile UUID查询成功场景

### 边界测试用例
- [配对超时场景](tests/test_pair_timeout.ets) - 测试用户拒绝配对或配对超时场景
- [连接不支持的Profile](tests/test_connect_unsupported_profile.ets) - 测试设备不支持所需Profile的降级处理
- [配对完成后延迟连接](tests/test_delayed_connect.ets) - 测试配对30秒后再发起连接的场景

### 异常测试用例
- [权限缺失场景](tests/test_permission_denied.ets) - 测试未申请权限时的错误处理
- [蓝牙开关关闭场景](tests/test_bluetooth_disabled.ets) - 测试蓝牙关闭时的错误处理
- [设备地址格式错误](tests/test_invalid_device_address.ets) - 测试设备地址格式错误的参数校验
- [配对失败场景](tests/test_pair_failed.ets) - 测试配对失败时的错误处理和降级方案