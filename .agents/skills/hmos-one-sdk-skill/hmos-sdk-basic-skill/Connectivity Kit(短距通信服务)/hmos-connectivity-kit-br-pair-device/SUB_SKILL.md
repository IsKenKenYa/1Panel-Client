---
name: hmos-connectivity-kit-br-pair-device
description: 主动配对传统蓝牙设备并连接设备支持的Profile能力(A2DP/HFP/HID)，需申请ohos.permission.ACCESS_BLUETOOTH权限，配对过程中系统弹出授权对话框，适用于蓝牙音频、通话、外设连接场景
---

# 传统蓝牙配对与连接设备技能

## 功能描述

本技能提供传统蓝牙(Basic Rate/Enhanced Data Rate)设备的主动配对和连接Profile能力。通过本技能，应用可以：

1. **主动发起配对**：向目标蓝牙设备发起配对请求，支持两种配对方式（API version 10-20使用字符串地址，API version 21+使用BluetoothAddress结构）
2. **订阅配对状态**：实时监听配对状态变化，获取配对成功/失败结果
3. **连接Profile**：配对成功后，主动连接设备支持的Profile能力（包括A2DP音频传输、HFP免提通话、HID人机接口设备）
4. **查询Profile能力**：获取目标设备支持的所有Profile UUID列表

**技术特点**：
- 配对过程中系统会弹出授权对话框，需要用户手动确认
- 蓝牙子系统为每个外设分配虚拟MAC地址，保护用户隐私
- 配对完成后30秒内可主动连接Profile
- 支持多种配对类型（确认配对密钥、输入PIN码等）

## 使用场景

### 触发词
- "配对蓝牙设备"
- "连接蓝牙耳机"
- "连接蓝牙音箱"
- "配对传统蓝牙"
- "连接蓝牙外设"
- "蓝牙配对与连接"
- "配对BR设备"
- "连接A2DP/HFP/HID"

### 能做
- 主动发起蓝牙配对流程（适用于设备地址已知的场景）
- 监听配对状态变化（配对成功、配对失败、配对取消等）
- 配对成功后连接设备支持的Profile（A2DP音频传输、HFP免提通话、HID设备）
- 查询设备支持的Profile能力列表
- 处理配对过程中的用户授权对话框
- 支持API version 10-20的字符串地址配对方式
- 支持API version 21+的BluetoothAddress结构配对方式（需指定地址类型）

### 绝不做
- 不自动处理配对授权对话框（需要用户手动确认）
- 不执行低功耗蓝牙(BLE)的配对与连接（需使用BLE专用技能）
- 不执行SPP(Serial Port Profile)连接（需使用SPP专用技能）
- 不在配对失败时自动重试（需要开发者实现重试逻辑）
- 不处理设备发现流程（需先通过设备发现技能获取设备地址）
- 不支持未配对设备的Profile连接（必须先配对成功）

### 补充
- **权限要求**：必须申请ohos.permission.ACCESS_BLUETOOTH权限，否则配对API调用会返回201错误码
- **地址类型说明**：
  - API version 10-20：使用字符串格式的设备地址（虚拟MAC或实际MAC），无需指定地址类型
  - API version 21+：推荐使用BluetoothAddress结构，需同时指定地址类型（VIRTUAL或REAL）
- **配对时间窗口**：配对完成后30秒内可发起Profile连接
- **Profile限制**：connectAllowedProfiles仅支持A2DP、HFP、HID三种Profile
- **用户交互**：配对过程中系统会弹出授权对话框，不同配对类型对话框样式不同
- **隐私保护**：蓝牙子系统为每个外设分配虚拟MAC地址，保护实际MAC地址隐私

## 调用规范和规则

### 输入约束
- **设备地址格式**：
  - 字符串格式："XX:XX:XX:XX:XX:XX"（API version 10-20）
  - BluetoothAddress结构：包含address和addressType字段（API version 21+）
- **地址类型选择**（API version 21+）：
  - VIRTUAL(1)：虚拟MAC地址（推荐用于发现设备流程获取的地址）
  - REAL(2)：实际MAC地址（已知设备实际MAC地址时使用）
- **设备地址来源**：必须通过设备发现流程获取，不能使用伪造地址
- **Profile UUID格式**：使用constant.ProfileUuids枚举或小写字符串格式

### 执行约束
- **最大配对耗时**：配对流程可能需要用户交互，不设固定超时限制
- **配对状态订阅**：必须在发起配对前订阅bondStateChange事件
- **Profile连接时间窗口**：配对成功后30秒内必须发起Profile连接
- **Profile连接订阅**：必须在发起connectAllowedProfiles前订阅对应Profile的connectionStateChange事件
- **并发限制**：同一设备同时只能发起一次配对请求
- **重试次数**：建议最多重试3次，避免频繁配对失败

### 内容约束
- **禁止生成的内容**：
  - 不生成伪造的设备MAC地址
  - 不生成绕过用户授权对话框的代码
  - 不生成自动处理配对密钥的代码（密钥必须由用户手动确认）
- **禁止使用高危函数**：
  - 禁止使用eval、exec执行动态代码
  - 禁止直接操作蓝牙底层协议栈
- **禁止操作**：
  - 禁止在未订阅状态变化事件时直接调用配对/连接API
  - 禁止在配对失败后立即重试（需等待至少1秒）
  - 禁止同时配对多个设备

### 降级约束
- **配对失败降级方案**：
  1. 检查错误码，判断失败原因（权限不足、蓝牙已关闭、设备不可达等）
  2. 提示用户检查蓝牙是否开启、设备是否在范围内
  3. 提供手动重试按钮，最多重试3次
  4. 超过重试次数后提示用户手动配对（系统蓝牙设置）
- **Profile连接失败降级方案**：
  1. 先查询设备支持的Profile列表（getRemoteProfileUuids）
  2. 仅连接应用需要的Profile（避免连接不支持的Profile）
  3. 如果Profile连接失败，提示用户该功能不可用
  4. 提供部分功能可用提示（例如：音频连接失败但通话可用）
- **权限不足降级方案**：
  1. 提示用户授予ACCESS_BLUETOOTH权限
  2. 引导用户到应用设置页面手动授权
  3. 权限授予后自动重试配对流程
- **蓝牙已关闭降级方案**：
  1. 提示用户开启蓝牙
  2. 监听蓝牙开启状态变化（connection.on('stateChange')）
  3. 蓝牙开启后自动重试配对流程

## 调用流程和步骤

### 步骤1：申请权限

**前置校验**：
1. 检查是否已申请ohos.permission.ACCESS_BLUETOOTH权限
2. 如果权限未授予，引导用户授权

**权限配置示例**：
```json
// module.json5
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.ACCESS_BLUETOOTH",
        "reason": "$string:bluetooth_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      }
    ]
  }
}
```

**动态权限申请示例**：
```typescript
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { BusinessError } from '@kit.BasicServicesKit';

async function requestBluetoothPermission(context: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  try {
    const grantResult = await atManager.requestPermissionsFromUser(
      context,
      ['ohos.permission.ACCESS_BLUETOOTH']
    );
    return grantResult.authResults[0] === 0; // 0表示授权成功
  } catch (err) {
    console.error('request permission failed: ' + JSON.stringify(err));
    return false;
  }
}
```

### 步骤2：导入必要模块

**导入模块示例**：
```typescript
import { connection, a2dp, hfp, hid, baseProfile, constant, common } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤3：订阅配对状态变化事件

**订阅事件示例**：
```typescript
// 定义配对状态变化回调函数
function onBondStateChange(data: connection.BondStateParam) {
  console.info('Bond state changed: ' + JSON.stringify(data));
  // data.state可能的值：
  // - BOND_STATE_INVALID (0): 未配对
  // - BOND_STATE_BONDING (1): 配对中
  // - BOND_STATE_BONDED (2): 已配对
}

try {
  // 发起订阅，必须在pairDevice之前订阅
  connection.on('bondStateChange', onBondStateChange);
} catch (err) {
  const error = err as BusinessError;
  console.error('Subscribe bondStateChange failed: code=' + error.code + ', message=' + error.message);
}
```

### 步骤4：发起配对

**分支A：API version 10-20配对方式（推荐用于未知地址类型）**

```typescript
// 适用于不知道目标设备地址类型的场景
// 设备地址可以通过发现设备流程获取
let deviceAddress = '11:22:33:44:55:66'; // 虚拟MAC或实际MAC

try {
  connection.pairDevice(deviceAddress).then(() => {
    console.info('PairDevice request sent successfully');
    // 注意：配对成功与否需要通过bondStateChange事件判断
  }).catch((error: BusinessError) => {
    console.error('PairDevice failed: code=' + error.code + ', message=' + error.message);
    // 错误处理参考错误码说明章节
  });
} catch (err) {
  const error = err as BusinessError;
  console.error('PairDevice exception: code=' + error.code + ', message=' + error.message);
}
```

**分支B：API version 21+配对方式（推荐用于已知地址类型）**

```typescript
// 适用于已知目标设备MAC地址和地址类型的场景
import { common } from '@kit.ConnectivityKit';

let btAddr: common.BluetoothAddress = {
  "address": '11:22:33:44:55:66', // 目标设备的实际MAC地址或虚拟MAC地址
  "addressType": common.BluetoothAddressType.REAL, // 地址类型：VIRTUAL(1)或REAL(2)
};

try {
  connection.pairDevice(btAddr).then(() => {
    console.info('PairDevice request sent successfully');
    // 注意：配对成功与否需要通过bondStateChange事件判断
  }).catch((error: BusinessError) => {
    console.error('PairDevice failed: code=' + error.code + ', message=' + error.message);
  });
} catch (err) {
  const error = err as BusinessError;
  console.error('PairDevice exception: code=' + error.code + ', message=' + error.message);
}
```

**判定条件**：
- 如果不知道目标设备的地址类型，使用分支A（字符串地址）
- 如果已知目标设备的地址类型，使用分支B（BluetoothAddress结构）
- 如果通过发现设备流程获取的地址，通常是虚拟MAC地址，使用VIRTUAL类型

### 步骤5：处理配对结果

**配对成功处理**：
```typescript
function onBondStateChange(data: connection.BondStateParam) {
  if (data.state === connection.BondState.BOND_STATE_BONDED) {
    console.info('Device paired successfully: ' + data.deviceId);
    // 配对成功后，可以发起Profile连接（步骤6）
    // 注意：必须在30秒内发起连接
    connectProfiles(data.deviceId);
  } else if (data.state === connection.BondState.BOND_STATE_INVALID) {
    console.error('Device pairing failed or cancelled: ' + data.deviceId);
    // 配对失败处理
    handlePairingFailure(data.deviceId);
  }
}
```

**配对失败降级处理**：
```typescript
function handlePairingFailure(deviceId: string) {
  // 提示用户配对失败，提供重试选项
  console.warn('Pairing failed. Please check: 1) Bluetooth is enabled, 2) Device is in range, 3) User confirmed pairing');
  // 提供手动重试按钮，最多重试3次
  // 超过重试次数后引导用户到系统蓝牙设置手动配对
}
```

### 步骤6：查询设备支持的Profile

**查询Profile示例**：
```typescript
async function getSupportedProfiles(deviceId: string): Promise<Array<string>> {
  try {
    const uuids = await connection.getRemoteProfileUuids(deviceId);
    console.info('Device supported profiles: ' + JSON.stringify(uuids));
    return uuids;
  } catch (err) {
    const error = err as BusinessError;
    console.error('GetRemoteProfileUuids failed: code=' + error.code + ', message=' + error.message);
    return [];
  }
}
```

### 步骤7：订阅Profile连接状态变化

**订阅Profile状态示例**：
```typescript
// 创建Profile实例
let a2dpSrc = a2dp.createA2dpSrcProfile();
let hfpAg = hfp.createHfpAgProfile();
let hidHost = hid.createHidHostProfile();

// 定义Profile连接状态变化回调函数
function onA2dpConnectStateChange(data: baseProfile.StateChangeParam) {
  console.info('A2DP connection state: ' + JSON.stringify(data));
  // data.state可能的值：
  // - PROFILE_STATE_DISCONNECTED (0): 已断开
  // - PROFILE_STATE_CONNECTING (1): 连接中
  // - PROFILE_STATE_CONNECTED (2): 已连接
  // - PROFILE_STATE_DISCONNECTING (3): 断开中
}

function onHfpConnectStateChange(data: baseProfile.StateChangeParam) {
  console.info('HFP connection state: ' + JSON.stringify(data));
}

function onHidConnectStateChange(data: baseProfile.StateChangeParam) {
  console.info('HID connection state: ' + JSON.stringify(data));
}

// 订阅状态变化事件（必须在connectAllowedProfiles之前订阅）
try {
  a2dpSrc.on('connectionStateChange', onA2dpConnectStateChange);
  hfpAg.on('connectionStateChange', onHfpConnectStateChange);
  hidHost.on('connectionStateChange', onHidConnectStateChange);
} catch (err) {
  const error = err as BusinessError;
  console.error('Subscribe profile state failed: code=' + error.code + ', message=' + error.message);
}
```

### 步骤8：发起Profile连接

**连接Profile示例**：
```typescript
async function connectProfiles(deviceId: string) {
  try {
    // 先查询设备支持的Profile
    const uuids = await connection.getRemoteProfileUuids(deviceId);
    
    // 检查是否支持应用需要的Profile
    let hasA2dp = uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_A2DP_SINK.toLowerCase());
    let hasHfp = uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_HFP_HF.toLowerCase());
    let hasHid = uuids.some(uuid => 
      uuid === constant.ProfileUuids.PROFILE_UUID_HID.toLowerCase() ||
      uuid === constant.ProfileUuids.PROFILE_UUID_HOGP.toLowerCase()
    );
    
    if (!hasA2dp && !hasHfp && !hasHid) {
      console.warn('Device does not support A2DP/HFP/HID profiles');
      return;
    }
    
    // 发起连接（必须在配对成功后30秒内）
    connection.connectAllowedProfiles(deviceId).then(() => {
      console.info('ConnectAllowedProfiles request sent successfully');
      // 注意：连接成功与否需要通过Profile的connectionStateChange事件判断
    }).catch((error: BusinessError) => {
      console.error('ConnectAllowedProfiles failed: code=' + error.code + ', message=' + error.message);
    });
    
  } catch (err) {
    const error = err as BusinessError;
    console.error('Connect profiles failed: code=' + error.code + ', message=' + error.message);
  }
}
```

### 步骤9：处理Profile连接结果

**连接成功处理**：
```typescript
function onA2dpConnectStateChange(data: baseProfile.StateChangeParam) {
  if (data.state === constant.ProfileConnectionState.PROFILE_STATE_CONNECTED) {
    console.info('A2DP connected successfully: ' + data.deviceId);
    // A2DP连接成功，可以开始音频传输
    // 提示用户音频功能可用
  } else if (data.state === constant.ProfileConnectionState.PROFILE_STATE_DISCONNECTED) {
    console.warn('A2DP disconnected: ' + data.deviceId);
    // A2DP断开连接，提示用户音频功能不可用
  }
}
```

### 步骤10：错误处理

**通用错误处理示例**：
```typescript
function handleBluetoothError(error: BusinessError) {
  switch (error.code) {
    case 201:
      console.error('Permission denied. Please grant ACCESS_BLUETOOTH permission');
      // 引导用户授权
      break;
    case 401:
      console.error('Invalid parameter. Please check device address format');
      // 检查设备地址格式
      break;
    case 801:
      console.error('Capability not supported. This device does not support Bluetooth');
      // 提示设备不支持蓝牙
      break;
    case 2900001:
      console.error('Service stopped. Bluetooth service is not running');
      // 提示用户重启蓝牙或重启设备
      break;
    case 2900003:
      console.error('Bluetooth disabled. Please enable Bluetooth');
      // 提示用户开启蓝牙
      break;
    case 2900099:
      console.error('Operation failed. Unknown error');
      // 提示用户重试或手动配对
      break;
    default:
      console.error('Unknown error: code=' + error.code + ', message=' + error.message);
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | 权限不足，未授予ohos.permission.ACCESS_BLUETOOTH权限 | 1. 在module.json5中声明权限<br>2. 动态申请用户授权<br>3. 引导用户到设置页面手动授权 |
| 401 | 参数错误，设备地址格式不正确或参数缺失 | 1. 检查设备地址格式是否为"XX:XX:XX:XX:XX:XX"<br>2. API version 21+检查BluetoothAddress结构是否包含address和addressType<br>3. 确保地址不为空字符串 |
| 801 | 设备不支持蓝牙能力 | 1. 提示用户当前设备不支持蓝牙功能<br>2. 提供替代方案（例如：使用有线连接） |
| 2900001 | 蓝牙服务已停止 | 1. 提示用户重启蓝牙服务<br>2. 监听蓝牙状态变化，自动重试<br>3. 如果持续失败，提示用户重启设备 |
| 2900003 | 蓝牙已关闭 | 1. 提示用户开启蓝牙<br>2. 监听蓝牙开启状态，自动重试配对<br>3. 提供蓝牙设置跳转按钮 |
| 2900099 | 操作失败（通用错误） | 1. 检查设备是否在蓝牙范围内<br>2. 提示用户手动重试<br>3. 提供手动配对入口（系统蓝牙设置） |

**错误处理优先级**：
1. **P0级错误**：201(权限不足)、2900003(蓝牙已关闭) - 需立即处理并提示用户
2. **P1级错误**：401(参数错误)、2900001(服务停止) - 检查配置并重试
3. **P2级错误**：801(不支持)、2900099(操作失败) - 提供降级方案

## 编译和修复问题

### 依赖声明

**oh-package.json5配置**：
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0",
    "@kit.AbilityKit": "^1.0.0"
  }
}
```

**module.json5权限配置**：
```json
{
  "module": {
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

### 环境要求

- **HarmonyOS SDK版本**：API version 10及以上
- **开发工具**：DevEco Studio 3.1及以上
- **设备要求**：支持蓝牙功能的HarmonyOS设备
- **Kit依赖**：ConnectivityKit、BasicServicesKit、AbilityKit

### 常见编译问题

**问题1：导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**：
1. 检查oh-package.json5是否正确配置ConnectivityKit依赖
2. 执行ohpm install命令安装依赖
3. 检查SDK版本是否支持API version 10及以上

**问题2：权限未声明**
```
Error: Permission denied (201)
```
**解决方法**：
1. 在module.json5中添加ohos.permission.ACCESS_BLUETOOTH权限声明
2. 添加权限申请理由（reason字段）
3. 配置权限使用场景（usedScene字段）

**问题3：API不存在**
```
Error: Property 'pairDevice' does not exist on type 'connection'
```
**解决方法**：
1. 检查导入语句是否正确：`import { connection } from '@kit.ConnectivityKit'`
2. 检查SDK版本是否支持该API（pairDevice从API version 10开始支持）
3. 检查编译目标API版本配置

**问题4：类型定义错误**
```
Error: Type 'BluetoothAddress' is not defined
```
**解决方法**：
1. API version 21+才支持BluetoothAddress类型
2. 添加导入语句：`import { common } from '@kit.ConnectivityKit'`
3. 使用common.BluetoothAddress引用类型

**问题5：Profile实例创建失败**
```
Error: Cannot create A2dpSrcProfile instance
```
**解决方法**：
1. 检查导入语句是否包含a2dp模块：`import { a2dp } from '@kit.ConnectivityKit'`
2. 检查设备是否支持A2DP Profile（通过getRemoteProfileUuids查询）
3. 确保在设备配对成功后才创建Profile实例

## 常见问题与解决方法

### Q1：配对过程中用户取消了授权对话框，如何处理？

**原因**：配对过程中系统弹出授权对话框，用户可能点击"取消"按钮拒绝配对。

**解决方法**：
1. 在bondStateChange回调中检查状态是否为BOND_STATE_INVALID
2. 提示用户配对已取消，提供重新配对按钮
3. 记录配对取消次数，超过3次后引导用户到系统蓝牙设置手动配对
4. 示例代码：
```typescript
function onBondStateChange(data: connection.BondStateParam) {
  if (data.state === connection.BondState.BOND_STATE_INVALID) {
    console.warn('User cancelled pairing or pairing failed');
    // 提供重新配对按钮
  }
}
```

### Q2：设备地址应该使用虚拟MAC还是实际MAC？

**原因**：蓝牙子系统为保护用户隐私，为每个外设分配虚拟MAC地址。

**解决方法**：
- **API version 10-20**：使用字符串地址，无需区分虚拟/实际MAC
- **API version 21+**：
  - 通过设备发现流程获取的地址，通常是虚拟MAC，使用addressType: VIRTUAL
  - 如果已知设备的实际MAC地址（例如：设备说明书提供），使用addressType: REAL
  - 推荐使用虚拟MAC地址，保护隐私
- 示例代码：
```typescript
// 使用虚拟MAC（推荐）
let btAddr: common.BluetoothAddress = {
  "address": '11:22:33:44:55:66', // 设备发现流程获取的地址
  "addressType": common.BluetoothAddressType.VIRTUAL,
};
```

### Q3：Profile连接失败，提示设备不支持该Profile？

**原因**：目标设备可能不支持A2DP/HFP/HID Profile，或者Profile UUID不匹配。

**解决方法**：
1. 在发起connectAllowedProfiles之前，先调用getRemoteProfileUuids查询设备支持的Profile列表
2. 检查查询结果是否包含应用需要的Profile UUID
3. 仅连接设备支持的Profile，避免连接不支持的Profile
4. 示例代码：
```typescript
const uuids = await connection.getRemoteProfileUuids(deviceId);
let hasA2dp = uuids.some(uuid => uuid === constant.ProfileUuids.PROFILE_UUID_A2DP_SINK.toLowerCase());
if (!hasA2dp) {
  console.warn('Device does not support A2DP');
  return; // 不发起A2DP连接
}
```

### Q4：配对成功后多久可以发起Profile连接？

**原因**：蓝牙子系统在配对成功后有30秒的时间窗口允许发起Profile连接。

**解决方法**：
1. 在bondStateChange回调中检测到BOND_STATE_BONDED状态后，立即发起Profile连接
2. 计算时间间隔，确保在30秒内发起连接
3. 如果超过30秒，提示用户重新配对或手动连接（系统蓝牙设置）
4. 示例代码：
```typescript
function onBondStateChange(data: connection.BondStateParam) {
  if (data.state === connection.BondState.BOND_STATE_BONDED) {
    // 立即发起连接（30秒时间窗口）
    setTimeout(() => {
      connectProfiles(data.deviceId);
    }, 100); // 延迟100ms，避免配对流程还未完全结束
  }
}
```

### Q5：如何区分不同类型的配对对话框？

**原因**：不同蓝牙设备的配对类型不同，系统弹出的对话框样式也不同（确认密钥、输入PIN码等）。

**解决方法**：
- **确认配对密钥（Confirm Passkey）**：对话框显示配对密钥，用户点击"确认"按钮
- **输入PIN码**：对话框提示用户输入PIN码（通常是0000或1234）
- **无需用户交互**：部分设备自动配对，无需用户确认
- 开发者无法控制对话框类型，由蓝牙子系统根据设备特性决定
- 建议在应用中提示用户："配对过程中会弹出授权对话框，请根据对话框提示操作"

## 输出结果报告

执行完成后输出以下信息：

```json
{
  "status": "success",
  "operation": "传统蓝牙配对与连接",
  "deviceId": "XX:XX:XX:XX:XX:XX",
  "pairState": "BOND_STATE_BONDED",
  "connectedProfiles": [
    {
      "profile": "A2DP",
      "state": "PROFILE_STATE_CONNECTED"
    },
    {
      "profile": "HFP",
      "state": "PROFILE_STATE_CONNECTED"
    }
  ],
  "supportedProfiles": [
    "PROFILE_UUID_A2DP_SINK",
    "PROFILE_UUID_HFP_HF",
    "PROFILE_UUID_HID"
  ],
  "timestamp": "2026-07-03T10:30:00Z",
  "apiUsed": [
    "connection.pairDevice",
    "connection.on('bondStateChange')",
    "connection.getRemoteProfileUuids",
    "connection.connectAllowedProfiles",
    "a2dp.createA2dpSrcProfile",
    "hfp.createHfpAgProfile",
    "hid.createHidHostProfile"
  ]
}
```

## 参考文档

- [API开发指南：配对与连接设备](references/br-pair-device-development-guide.md)
- [API参考说明：蓝牙connection模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-connection)
- [API参考说明：蓝牙common模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-common)
- [API参考说明：蓝牙a2dp模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-a2dp)
- [API参考说明：蓝牙hfp模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-hfp)
- [API参考说明：蓝牙hid模块](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-hid)
- [开发指南：声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [开发指南：向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)
- [开发指南：传统蓝牙查找设备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-discovery-development-guide)
- [开发指南：低功耗蓝牙查找设备](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/ble-development-guide)
- [开发指南：连接和传输数据(SPP)](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/spp-development-guide)

## 完整示例代码

- [ArkTS完整示例代码](assets/pair-device-example.ets) - 包含完整的配对与连接流程实现
- [权限配置示例](assets/module.json5) - module.json5权限配置示例
- [依赖配置示例](assets/oh-package.json5) - oh-package.json5依赖配置示例

## 测试用例

### 正向测试用例
- [test_pair_success.ets](tests/test_pair_success.ets) - 测试正常配对流程，配对成功后连接Profile
- [test_connect_a2dp.ets](tests/test_connect_a2dp.ets) - 测试A2DP Profile连接成功
- [test_connect_hfp.ets](tests/test_connect_hfp.ets) - 测试HFP Profile连接成功
- [test_connect_hid.ets](tests/test_connect_hid.ets) - 测试HID Profile连接成功

### 边界测试用例
- [test_api_version_10.ets](tests/test_api_version_10.ets) - 测试API version 10-20配对方式（字符串地址）
- [test_api_version_21.ets](tests/test_api_version_21.ets) - 测试API version 21+配对方式（BluetoothAddress结构）
- [test_virtual_address.ets](tests/test_virtual_address.ets) - 测试使用虚拟MAC地址配对
- [test_real_address.ets](tests/test_real_address.ets) - 测试使用实际MAC地址配对

### 异常测试用例
- [test_permission_denied.ets](tests/test_permission_denied.ets) - 测试权限不足场景（错误码201）
- [test_invalid_address.ets](tests/test_invalid_address.ets) - 测试设备地址格式错误场景（错误码401）
- [test_bluetooth_disabled.ets](tests/test_bluetooth_disabled.ets) - 测试蓝牙已关闭场景（错误码2900003）
- [test_service_stopped.ets](tests/test_service_stopped.ets) - 测试蓝牙服务停止场景（错误码2900001）
- [test_pair_cancelled.ets](tests/test_pair_cancelled.ets) - 测试用户取消配对场景
- [test_profile_not_supported.ets](tests/test_profile_not_supported.ets) - 测试设备不支持Profile场景
- [test_connect_timeout.ets](tests/test_connect_timeout.ets) - 测试超过30秒时间窗口连接失败场景