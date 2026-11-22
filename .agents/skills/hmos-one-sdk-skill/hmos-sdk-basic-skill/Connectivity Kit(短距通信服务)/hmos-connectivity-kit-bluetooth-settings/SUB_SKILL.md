---
name: hmos-connectivity-kit-bluetooth-settings
description: 开启/关闭蓝牙、获取蓝牙状态、订阅状态变化,需要ACCESS_BLUETOOTH权限,适用于蓝牙设备管理、蓝牙功能初始化场景
---

# 蓝牙设置技能

## 功能描述

本技能提供蓝牙开关状态管理能力,包括开启蓝牙、关闭蓝牙、获取蓝牙开关状态以及订阅蓝牙状态变化事件。在使用蓝牙其他功能前,必须确保蓝牙子系统已正常开启。

**核心功能**:
- 开启蓝牙(enableBluetooth/enableBluetoothAsync)
- 关闭蓝牙(disableBluetooth/disableBluetoothAsync)
- 获取蓝牙开关状态(getState)
- 订阅蓝牙状态变化(on/off 'stateChange')

**适用范围**:
- 需要在使用蓝牙功能前检查和设置蓝牙状态
- 需要监控蓝牙开关状态的实时变化
- 需要在应用启动时初始化蓝牙环境

**限制条件**:
- 需要申请ohos.permission.ACCESS_BLUETOOTH权限
- 开启/关闭蓝牙时会弹出系统对话框,需要用户确认
- 必须在蓝牙处于STATE_OFF状态时才能开启,STATE_ON状态时才能关闭

**典型场景**:
- 蓝牙设备连接前的环境准备
- 应用启动时自动检查并开启蓝牙
- 用户手动控制蓝牙开关
- 监控蓝牙状态变化进行业务逻辑处理

## 使用场景

### 触发词
- "开启蓝牙" - 主动开启蓝牙设备
- "关闭蓝牙" - 主动关闭蓝牙设备
- "获取蓝牙状态" - 查询当前蓝牙开关状态
- "蓝牙开关状态" - 查询或订阅蓝牙状态变化
- "初始化蓝牙" - 在应用启动时检查并设置蓝牙状态
- "蓝牙设置" - 泛指蓝牙开关状态管理相关操作

### 能做
- 开启本端蓝牙设备(同步或异步方式)
- 关闭本端蓝牙设备(同步或异步方式)
- 获取当前蓝牙开关状态
- 订阅蓝牙状态变化事件并实时感知状态跃迁
- 取消订阅蓝牙状态变化事件
- 判断蓝牙是否处于可用状态(STATE_ON)
- 在应用初始化时自动检查并开启蓝牙

### 绝不做
- 不处理蓝牙设备连接、扫描等其他蓝牙功能(这些属于其他技能)
- 不绕过用户确认直接开启/关闭蓝牙(系统会弹出对话框)
- 不在蓝牙已开启状态下重复开启蓝牙
- 不在蓝牙已关闭状态下重复关闭蓝牙
- 不处理超出Connectivity Kit范围的网络请求

### 补充
- 蓝牙状态包含7种状态:STATE_OFF、STATE_TURNING_ON、STATE_ON、STATE_TURNING_OFF、STATE_BLE_TURNING_ON、STATE_BLE_ON、STATE_BLE_TURNING_OFF
- 只有STATE_ON状态下才能使用蓝牙的其他功能(扫描、连接、传输等)
- 建议在使用其他蓝牙功能前,先调用getState检查状态
- 开启/关闭蓝牙是异步过程,建议订阅stateChange事件来获取最终结果
- enableBluetoothAsync和disableBluetoothAsync(API 20+)可以感知用户操作对话框的行为

## 调用规范和规则

### 输入约束
- 无特殊输入参数要求
- 权限配置:必须在module.json5中声明ohos.permission.ACCESS_BLUETOOTH权限
- 用户确认:开启/关闭蓝牙时系统会弹出对话框,需要用户同意

### 执行约束
- 最大耗时:开启/关闭蓝牙是异步过程,耗时由用户响应时间决定,通常不超过30秒
- 最大迭代次数:建议在状态检查后只调用一次开启/关闭接口
- API调用频次:建议避免频繁开启/关闭蓝牙,尊重用户选择
- 状态检查:建议在调用enableBluetooth前检查状态是否为STATE_OFF,在调用disableBluetooth前检查状态是否为STATE_ON

### 内容约束
- 禁止生成:禁止绕过用户确认的强制开启/关闭代码
- 禁止使用高危函数:禁止使用系统级别的强制权限修改
- 禁止操作:禁止在蓝牙服务停止(2900001错误)时重复调用

### 降级约束
- 网络失败:蓝牙为本地硬件功能,不涉及网络请求
- 权限不足:提示用户申请ACCESS_BLUETOOTH权限,引导用户到权限设置页面
- 服务停止(2900001):提示用户重启设备或等待蓝牙服务恢复
- 用户拒绝操作(2900014):尊重用户选择,不强制重试
- 设备不支持(801):提示用户当前设备不支持蓝牙功能

## 调用流程和步骤

### 步骤1:准备阶段

**权限申请**:
1. 在module.json5中声明权限:
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

2. 动态申请权限(如果需要):
```typescript
import { abilityAccessCtrl, common } from '@kit.AbilityKit';

async function requestBluetoothPermission(context: common.UIAbilityContext): Promise<boolean> {
  const atManager = abilityAccessCtrl.createAtManager();
  try {
    const grantStatus = await atManager.checkAccessToken(
      context.applicationInfo.accessTokenId,
      'ohos.permission.ACCESS_BLUETOOTH'
    );
    
    if (grantStatus === abilityAccessCtrl.GrantStatus.PERMISSION_GRANTED) {
      return true;
    }
    
    // 申请权限
    const result = await atManager.requestPermissionsFromUser(context, ['ohos.permission.ACCESS_BLUETOOTH']);
    return result.authResults[0] === 0;
  } catch (error) {
    console.error('Permission request failed:', error);
    return false;
  }
}
```

**模块导入**:
```typescript
import { access } from '@kit.ConnectivityKit';
import { BusinessError } from '@kit.BasicServicesKit';
```

### 步骤2:订阅蓝牙状态变化

**订阅状态变化事件**:
```typescript
// 定义蓝牙状态变化回调函数
function onBluetoothStateChange(data: access.BluetoothState): void {
  let stateMessage = '';
  switch (data) {
    case access.BluetoothState.STATE_OFF:
      stateMessage = 'STATE_OFF - 蓝牙已关闭';
      break;
    case access.BluetoothState.STATE_TURNING_ON:
      stateMessage = 'STATE_TURNING_ON - 蓝牙正在开启';
      break;
    case access.BluetoothState.STATE_ON:
      stateMessage = 'STATE_ON - 蓝牙已开启(可使用其他蓝牙功能)';
      break;
    case access.BluetoothState.STATE_TURNING_OFF:
      stateMessage = 'STATE_TURNING_OFF - 蓝牙正在关闭';
      break;
    case access.BluetoothState.STATE_BLE_TURNING_ON:
      stateMessage = 'STATE_BLE_TURNING_ON - 蓝牙正在开启LE-only模式';
      break;
    case access.BluetoothState.STATE_BLE_ON:
      stateMessage = 'STATE_BLE_ON - 蓝牙处于LE-only模式';
      break;
    case access.BluetoothState.STATE_BLE_TURNING_OFF:
      stateMessage = 'STATE_BLE_TURNING_OFF - 蓝牙正在关闭LE-only模式';
      break;
    default:
      stateMessage = 'Unknown state';
      break;
  }
  console.info('Bluetooth state changed: ' + stateMessage);
  
  // 根据状态执行业务逻辑
  if (data === access.BluetoothState.STATE_ON) {
    // 蓝牙已开启,可以执行后续蓝牙操作
    console.info('Bluetooth is ready for use');
  }
}

// 订阅状态变化事件
try {
  access.on('stateChange', onBluetoothStateChange);
  console.info('Bluetooth state change subscription succeeded');
} catch (error) {
  const err = error as BusinessError;
  console.error('Subscription failed, errCode: ' + err.code + ', errMessage: ' + err.message);
}
```

### 步骤3:获取当前蓝牙状态

**查询蓝牙状态**:
```typescript
try {
  const currentState = access.getState();
  console.info('Current Bluetooth state: ' + currentState);
  
  // 判断蓝牙是否可用
  if (currentState === access.BluetoothState.STATE_ON) {
    console.info('Bluetooth is enabled, ready for use');
  } else if (currentState === access.BluetoothState.STATE_OFF) {
    console.info('Bluetooth is disabled, need to enable');
  } else {
    console.info('Bluetooth is in transition state: ' + currentState);
  }
} catch (error) {
  const err = error as BusinessError;
  console.error('Get state failed, errCode: ' + err.code + ', errMessage: ' + err.message);
}
```

### 步骤4:开启蓝牙

**同步方式开启蓝牙**:
```typescript
try {
  // 先检查当前状态
  const state = access.getState();
  
  if (state === access.BluetoothState.STATE_OFF) {
    // 蓝牙已关闭,可以开启
    console.info('Bluetooth is OFF, attempting to enable');
    access.enableBluetooth();
    console.info('EnableBluetooth called, waiting for user confirmation');
    // 实际状态变化通过stateChange回调获取
  } else if (state === access.BluetoothState.STATE_ON) {
    console.info('Bluetooth is already ON, no need to enable');
  } else {
    console.warn('Bluetooth is in transition state: ' + state + ', wait for completion');
  }
} catch (error) {
  const err = error as BusinessError;
  console.error('EnableBluetooth failed, errCode: ' + err.code + ', errMessage: ' + err.message);
  
  // 错误处理
  if (err.code === 201) {
    console.error('Permission denied, please request ACCESS_BLUETOOTH permission');
  } else if (err.code === 2900001) {
    console.error('Bluetooth service stopped, please restart device');
  }
}
```

**异步方式开启蓝牙(API 20+)**:
```typescript
try {
  const state = access.getState();
  
  if (state === access.BluetoothState.STATE_OFF) {
    console.info('Attempting to enable Bluetooth asynchronously');
    
    access.enableBluetoothAsync().then(() => {
      console.info('EnableBluetoothAsync succeeded, user accepted');
      // 实际状态变化通过stateChange回调获取
    }).catch((error: BusinessError) => {
      console.error('EnableBluetoothAsync failed, errCode: ' + error.code + ', errMessage: ' + error.message);
      
      // 错误处理
      if (error.code === 2900013) {
        console.warn('User did not respond to the dialog');
      } else if (error.code === 2900014) {
        console.warn('User refused to enable Bluetooth');
      } else if (error.code === 201) {
        console.error('Permission denied');
      }
    });
  }
} catch (error) {
  const err = error as BusinessError;
  console.error('EnableBluetoothAsync failed, errCode: ' + err.code + ', errMessage: ' + err.message);
}
```

### 步骤5:关闭蓝牙

**同步方式关闭蓝牙**:
```typescript
try {
  // 先检查当前状态
  const state = access.getState();
  
  if (state === access.BluetoothState.STATE_ON) {
    // 蓝牙已开启,可以关闭
    console.info('Bluetooth is ON, attempting to disable');
    access.disableBluetooth();
    console.info('DisableBluetooth called, waiting for user confirmation');
    // 实际状态变化通过stateChange回调获取
  } else if (state === access.BluetoothState.STATE_OFF) {
    console.info('Bluetooth is already OFF, no need to disable');
  } else {
    console.warn('Bluetooth is in transition state: ' + state + ', wait for completion');
  }
} catch (error) {
  const err = error as BusinessError;
  console.error('DisableBluetooth failed, errCode: ' + err.code + ', errMessage: ' + err.message);
  
  // 错误处理
  if (err.code === 201) {
    console.error('Permission denied');
  } else if (err.code === 2900001) {
    console.error('Bluetooth service stopped');
  }
}
```

**异步方式关闭蓝牙(API 20+)**:
```typescript
try {
  const state = access.getState();
  
  if (state === access.BluetoothState.STATE_ON) {
    console.info('Attempting to disable Bluetooth asynchronously');
    
    access.disableBluetoothAsync().then(() => {
      console.info('DisableBluetoothAsync succeeded, user accepted');
      // 实际状态变化通过stateChange回调获取
    }).catch((error: BusinessError) => {
      console.error('DisableBluetoothAsync failed, errCode: ' + error.code + ', errMessage: ' + error.message);
      
      if (error.code === 2900013) {
        console.warn('User did not respond to the dialog');
      } else if (error.code === 2900014) {
        console.warn('User refused to disable Bluetooth');
      } else if (error.code === 201) {
        console.error('Permission denied');
      }
    });
  }
} catch (error) {
  const err = error as BusinessError;
  console.error('DisableBluetoothAsync failed, errCode: ' + err.code + ', errMessage: ' + err.message);
}
```

### 步骤6:取消订阅

**取消状态订阅**:
```typescript
// 取消订阅特定回调
try {
  access.off('stateChange', onBluetoothStateChange);
  console.info('Bluetooth state change subscription cancelled');
} catch (error) {
  const err = error as BusinessError;
  console.error('Cancel subscription failed, errCode: ' + err.code + ', errMessage: ' + err.message);
}

// 或者取消所有stateChange订阅
try {
  access.off('stateChange');
  console.info('All Bluetooth state change subscriptions cancelled');
} catch (error) {
  const err = error as BusinessError;
  console.error('Cancel all subscriptions failed, errCode: ' + err.code + ', errMessage: ' + err.message);
}
```

### 步骤7:错误处理和降级

**完整的错误处理示例**:
```typescript
function handleBluetoothError(error: BusinessError): void {
  switch (error.code) {
    case 201:
      console.error('Permission denied. Solution: Request ohos.permission.ACCESS_BLUETOOTH permission');
      // 降级方案:引导用户到权限设置
      break;
    case 401:
      console.error('Invalid parameter. Solution: Check callback function validity');
      break;
    case 801:
      console.error('Capability not supported. Solution: Device does not support Bluetooth');
      // 降级方案:提示用户设备不支持,使用其他连接方式
      break;
    case 2900001:
      console.error('Bluetooth service stopped. Solution: Restart device or wait for service recovery');
      // 降级方案:延迟重试或使用其他连接方式
      break;
    case 2900003:
      console.error('Bluetooth disabled. Solution: Enable Bluetooth first');
      break;
    case 2900013:
      console.warn('User did not respond. Solution: Wait for user action or timeout');
      // 降级方案:延迟重试
      break;
    case 2900014:
      console.warn('User refused the action. Solution: Respect user choice, do not retry');
      // 降级方案:不重试,记录用户偏好
      break;
    case 2900099:
      console.error('Operation failed. Solution: Check system status and retry');
      break;
    default:
      console.error('Unknown error: ' + error.code + ', ' + error.message);
      break;
  }
}
```

## 错误码说明

| 错误码 | 说明 | 解决方法 |
|-------|------|---------|
| 201 | Permission denied - 权限被拒绝 | 在module.json5中声明ohos.permission.ACCESS_BLUETOOTH权限,必要时动态申请 |
| 401 | Invalid parameter - 参数无效 | 检查回调函数是否有效,确保参数类型正确 |
| 801 | Capability not supported - 能力不支持 | 当前设备不支持蓝牙功能,提示用户使用其他连接方式 |
| 2900001 | Service stopped - 服务停止 | 重启设备或等待蓝牙服务恢复,避免在服务停止时调用 |
| 2900003 | Bluetooth disabled - 蓝牙已禁用 | 先调用enableBluetooth开启蓝牙 |
| 2900013 | The user does not respond - 用户未响应 | 等待用户操作对话框,可设置超时机制 |
| 2900014 | User refuse the action - 用户拒绝操作 | 尊重用户选择,不要强制重试,可记录用户偏好 |
| 2900099 | Operation failed - 操作失败 | 检查系统状态,清理蓝牙缓存后重试 |

## 编译和修复问题

### 依赖声明

**module.json5配置**:
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

**package依赖**:
```json
{
  "dependencies": {
    "@kit.ConnectivityKit": "^1.0.0",
    "@kit.BasicServicesKit": "^1.0.0",
    "@kit.AbilityKit": "^1.0.0"
  }
}
```

### 环境要求
- HarmonyOS API version: 10+ (基础接口),20+ (异步接口)
- 设备要求:支持蓝牙硬件
- 系统能力:SystemCapability.Communication.Bluetooth.Core

### 常见编译问题

**问题1:权限未声明**
```
Error: Permission denied (201)
```
**解决方法**:在module.json5中添加ohos.permission.ACCESS_BLUETOOTH权限声明

**问题2:导入模块失败**
```
Error: Cannot find module '@kit.ConnectivityKit'
```
**解决方法**:检查项目配置,确保使用HarmonyOS Next SDK,更新ohpm依赖

**问题3:API不存在**
```
Error: Property 'enableBluetoothAsync' does not exist
```
**解决方法**:enableBluetoothAsync需要API version 20+,检查设备API版本或使用enableBluetooth替代

**问题4:类型错误**
```
Error: Type 'BluetoothState' is not assignable to type 'number'
```
**解决方法**:使用正确的枚举类型access.BluetoothState,不要使用数字值

## 常见问题与解决方法

### Q1:调用enableBluetooth后蓝牙没有开启
**原因**:开启蓝牙需要用户确认,系统会弹出对话框
**解决方法**:
- 等待用户在对话框中点击"允许"
- 通过订阅stateChange事件获取最终状态(STATE_ON表示开启成功)
- 使用enableBluetoothAsync可以感知用户是否拒绝操作

### Q2:权限已申请但仍报201错误
**原因**:权限可能未生效或应用签名问题
**解决方法**:
- 检查module.json5中的权限声明格式是否正确
- 确保应用已重新编译和安装
- 检查应用签名是否包含权限声明
- 使用动态权限申请接口requestPermissionsFromUser

### Q3:蓝牙状态一直是STATE_TURNING_ON
**原因**:蓝牙开启过程卡住或用户未响应
**解决方法**:
- 检查是否用户拒绝了开启请求
- 设置超时机制,超过一定时间后提示用户
- 检查蓝牙硬件是否正常工作
- 重启设备恢复蓝牙服务

### Q4:如何判断蓝牙可以使用其他功能
**原因**:只有STATE_ON状态下才能使用其他蓝牙功能
**解决方法**:
- 在stateChange回调中判断state === access.BluetoothState.STATE_ON
- 在调用其他蓝牙API前先调用getState检查状态
- 如果状态不是STATE_ON,先调用enableBluetooth开启

### Q5:能否绕过用户确认直接开启蓝牙
**原因**:系统安全机制要求用户确认
**解决方法**:
- 不能绕过用户确认,这是HarmonyOS的安全机制
- 应用只能请求开启,最终由用户决定
- 可以引导用户理解为什么需要开启蓝牙,提高用户同意率
- 如果用户拒绝,可以记录偏好,下次不重复询问

### Q6:多个应用同时订阅stateChange会冲突吗
**原因**:订阅机制支持多个回调函数
**解决方法**:
- 不会冲突,每个应用的订阅独立处理
- 取消订阅时需要传入相同的回调函数引用
- 可以取消所有订阅:access.off('stateChange')
- 建议在应用退出时取消订阅,避免内存泄漏

## 输出结果报告

执行完成后输出以下信息:

```json
{
  "status": "success",
  "bluetoothState": "STATE_ON",
  "action": "enableBluetooth",
  "userConfirmed": true,
  "timestamp": "2024-01-01T10:00:00Z",
  "apiUsed": [
    "access.enableBluetooth",
    "access.getState",
    "access.on('stateChange')"
  ],
  "nextActions": [
    "可以使用其他蓝牙功能(扫描、连接、传输等)",
    "建议订阅状态变化以监控蓝牙状态"
  ]
}
```

## 参考文档

- [蓝牙设置开发指南](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/br-development-guide)
- [蓝牙access模块API参考](https://developer.huawei.com/consumer/cn/doc/harmonyos-references/js-apis-bluetooth-access)
- [声明权限](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/declare-permissions)
- [向用户申请授权](https://developer.huawei.com/consumer/cn/doc/harmonyos-guides/request-user-authorization)

## 完整示例代码

- [ArkTS完整示例](assets/bluetooth_manager.ets) - 蓝牙管理类完整实现
- [权限申请示例](assets/request_permission.ets) - 动态权限申请代码
- [配置文件示例](assets/module.json5) - module.json5权限配置

## 测试用例

### 正向测试用例
- [开启蓝牙成功](tests/test_enable_bluetooth.ets) - 正常开启蓝牙流程
- [关闭蓝牙成功](tests/test_disable_bluetooth.ets) - 正常关闭蓝牙流程
- [状态订阅成功](tests/test_subscribe_state.ets) - 成功订阅状态变化
- [状态查询成功](tests/test_get_state.ets) - 正常查询蓝牙状态

### 边界测试用例
- [蓝牙已开启时重复开启](tests/test_enable_when_on.ets) - 测试在STATE_ON状态时调用enableBluetooth
- [蓝牙已关闭时重复关闭](tests/test_disable_when_off.ets) - 测试在STATE_OFF状态时调用disableBluetooth
- [状态转换中调用API](tests/test_transition_state.ets) - 测试在过渡状态时的处理

### 异常测试用例
- [权限未申请](tests/test_permission_denied.ets) - 测试无权限时的错误处理
- [用户拒绝操作](tests/test_user_refuse.ets) - 测试用户拒绝开启/关闭的处理
- [服务停止](tests/test_service_stopped.ets) - 测试蓝牙服务停止时的降级处理
- [设备不支持](tests/test_capability_not_supported.ets) - 测试在不支持蓝牙设备上的处理